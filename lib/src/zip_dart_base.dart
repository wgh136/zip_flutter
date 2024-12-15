import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:zip_flutter/src/isolates.dart';
import 'generated_bindings.dart';
import 'package:path/path.dart' as path;

typedef _ZipFilePtr = ffi.Pointer<zip_t>;

const String _libName = 'zip_flutter';

final NativeLibrary _lib = NativeLibrary(() {
  if (Platform.isMacOS || Platform.isIOS) {
    return ffi.DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return ffi.DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return ffi.DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}());

int _onExtractEntry(ffi.Pointer<ffi.Char> filename, ffi.Pointer<ffi.Void> arg) {
  return 0;
}

enum ZipOpenMode {
  readonly(114),
  write(119),
  append(97);

  final int value;

  const ZipOpenMode(this.value);
}

class ZipFile {
  final _ZipFilePtr _zip;

  /// Opens zip archive with compression level using the given mode.
  ///
  /// To read a zip archive, use [ZipOpenMode.readonly].
  factory ZipFile.open(String path,
      {int level = 6, ZipOpenMode mode = ZipOpenMode.write}) {
    var res = _lib.zip_open(path.toNativeUtf8().cast(), level, mode.value);
    if (res == ffi.nullptr) {
      throw const ZipException("Failed to open file.");
    }
    var zip = ZipFile._create(res);
    return zip;
  }

  /// Open zip archive in readonly mode.
  factory ZipFile.openRead(String path) {
    return ZipFile.open(path, mode: ZipOpenMode.readonly);
  }

  ZipFile._create(this._zip);

  /// Opens an entry by [name] in the zip archive.
  /// Then compresses [sourceFile] file for the current zip entry.
  ///
  /// example:
  ///
  /// ```dart
  /// var zip = ZipFile.open("/home/test.zip");
  /// zip.addFile("1.txt", "/home/1.txt");
  /// zip.addFile("folder/2.txt", "/home/2.txt");
  /// zip.close();
  /// ```
  void addFile(String name, String sourceFile) {
    var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
    if (res < 0) {
      throw const ZipException("Failed to open entry.");
    }
    res = _lib.zip_entry_fwrite(_zip, sourceFile.toNativeUtf8().cast());
    if (res < 0) {
      throw ZipException("Failed to write content.\n"
          "Input: $sourceFile\n"
          "Trying write to $name\n"
          "Error Code $res\n");
    }
    res = _lib.zip_entry_close(_zip);
    if (res < 0) {
      throw const ZipException("Failed to close entry.");
    }
  }

  /// Adds a file to the zip archive from bytes.
  ///
  /// This method has lower performance than the [addFile] method
  /// because it copies the bytes into native memory.
  void addFileFromBytes(String name, Uint8List bytes) {
    var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
    if (res < 0) {
      throw const ZipException("Failed to open entry.");
    }
    var data = malloc.allocate<ffi.Uint8>(bytes.length);
    try {
      for (int i = 0; i < bytes.length; i++) {
        data[i] = bytes[i];
      }
      res = _lib.zip_entry_write(_zip, data.cast(), bytes.length);
      if (res < 0) {
        throw ZipException("Failed to write content.\n"
            "Trying write to $name\n"
            "Error Code $res\n");
      }
      res = _lib.zip_entry_close(_zip);
      if (res < 0) {
        throw const ZipException("Failed to close entry.");
      }
    } finally {
      malloc.free(data);
    }
  }

  /// Adds a empty directory to the zip archive.
  void addDirectory(String name) {
    if (name.endsWith("\\") || name.endsWith("/")) {
      name = name.substring(0, name.length - 1);
    }
    // A entry which is a directory must end with a slash '/', '\' is not allowed.
    name = "$name/";
    var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
    if (res < 0) {
      throw const ZipException("Failed to open entry.");
    }
    res = _lib.zip_entry_close(_zip);
    if (res < 0) {
      throw const ZipException("Failed to close entry.");
    }
  }

  /// close zip file.
  void close() {
    _lib.zip_close(_zip);
  }

  /// Get the number of entries in the zip archive.
  int get entriesCount => _lib.zip_entries_total(_zip);

  /// Open a new entry by index in the zip archive.
  /// This function is only valid if zip archive was opened in readonly mode.
  ZipEntry getEntryByIndex(int index) {
    try {
      var res = _lib.zip_entry_openbyindex(_zip, index);
      if (res < 0) {
        throw const ZipException("Failed to open entry.");
      }
      return ZipEntry(
        _lib.zip_entry_name(_zip).cast<Utf8>().toDartString(),
        index,
        _lib.zip_entry_isdir(_zip) != 0,
        _lib.zip_entry_size(_zip),
        _lib.zip_entry_crc32(_zip),
        this,
      );
    } finally {
      _lib.zip_entry_close(_zip);
    }
  }

  /// Open an entry by name in the zip archive.
  ///
  /// For zip archive opened in write or append mode the function will append
  /// a new entry. In readonly mode the function tries to locate the entry
  /// in global dictionary.
  ZipEntry getEntryByName(String name) {
    try {
      var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
      if (res < 0) {
        throw const ZipException("Failed to open entry.");
      }
      return ZipEntry(
        name,
        _lib.zip_entry_index(_zip),
        _lib.zip_entry_isdir(_zip) != 0,
        _lib.zip_entry_size(_zip),
        _lib.zip_entry_crc32(_zip),
        this,
      );
    } finally {
      _lib.zip_entry_close(_zip);
    }
  }

  /// Get all entries in the zip archive.
  List<ZipEntry> getAllEntries() {
    var entries = <ZipEntry>[];
    for (int i = 0; i < entriesCount; i++) {
      entries.add(getEntryByIndex(i));
    }
    return entries;
  }

  /// Delete a zip archive entry.
  void deleteEntry(String name) {
    var res = _lib.zip_entries_delete(_zip, name.toNativeUtf8().cast(), 1);
    if (res < 0) {
      throw const ZipException("Failed to delete entry.");
    }
  }

  /// Extracts a zip archive file into directory.
  static void openAndExtract(String zipFile, String extractTo) {
    ffi.Pointer<ffi.Int32> arg = malloc.allocate(4);

    ffi.Pointer<
        ffi.NativeFunction<
            ffi.Int Function(
                ffi.Pointer<ffi.Char> filename, ffi.Pointer<ffi.Void> arg)>>
    func = ffi.Pointer.fromFunction(_onExtractEntry, 0);

    _lib.zip_extract(zipFile.toNativeUtf8().cast(),
        extractTo.toNativeUtf8().cast(), func, arg.cast());

    malloc.free(arg);
  }

  /// Extracts a zip archive file into directory.
  ///
  /// Set [isolates] to the number of isolates to use for extraction.
  static Future<void> openAndExtractAsync(String zipFile, String extractTo,
      [int isolates = 1]) {
    return isolatesExtract(zipFile, extractTo, isolates);
  }

  /// Compresses a folder into a zip archive.
  static void compressFolder(String sourceFolder, String zipFileName) {
    sourceFolder = path.absolute(sourceFolder);
    var zip = ZipFile.open(zipFileName);
    void walk(String path) {
      for (var entry in Directory(path).listSync()) {
        if (entry is Directory) {
          walk(entry.path);
        } else {
          var filePathInZip = entry.path.replaceFirst(sourceFolder, "");
          if (filePathInZip.startsWith('/') || filePathInZip.startsWith('\\')) {
            filePathInZip = filePathInZip.substring(1);
          }
          zip.addFile(filePathInZip, entry.path);
        }
      }
    }

    walk(sourceFolder);
    zip.close();
  }
}

class ZipEntry {
  final String name;
  final int index;
  final bool isDir;
  final int size;
  final int crc32;
  final ZipFile _file;

  const ZipEntry(
      this.name, this.index, this.isDir, this.size, this.crc32, ZipFile file)
      : _file = file;

  /// Deletes zip archive entry
  void delete() {
    var res = _lib.zip_entries_delete(_file._zip, name.toNativeUtf8().cast(), 1);
    if (res < 0) {
      throw const ZipException("Failed to delete an entry");
    }
  }

  /// Extracts zip archive entry as Uint8List
  Uint8List read() {
    if (isDir) {
      throw const ZipException("Entry is Directory");
    }
    var res = _lib.zip_entry_openbyindex(_file._zip, index);
    if (res < 0) {
      throw const ZipException("Failed to open entry");
    }
    try {
      int size = _lib.zip_entry_size(_file._zip);
      var buf = malloc.allocate<ffi.Uint8>(size);
      res = _lib.zip_entry_noallocread(_file._zip, buf.cast(), size);
      if (res < 0) {
        throw const ZipException("Failed to read data");
      }
      return buf.asTypedList(size, finalizer: malloc.nativeFree);
    }
    finally {
      _lib.zip_entry_close(_file._zip);
    }
  }

  void writeToFile(String path) {
    if (isDir) {
      throw const ZipException("Entry is Directory");
    }
    var file = File(path);
    file.createSync(recursive: true);
    var res = _lib.zip_entry_openbyindex(_file._zip, index);
    if (res < 0) {
      throw const ZipException("Failed to open entry");
    }
    res = _lib.zip_entry_fread(_file._zip, path.toNativeUtf8().cast());
    if (res < 0) {
      throw const ZipException("Failed to write data");
    }
    res = _lib.zip_entry_close(_file._zip);
    if (res < 0) {
      throw const ZipException("Failed to close entry");
    }
  }

  @override
  String toString() {
    return 'ZipEntry{name: $name, index: $index, isDir: $isDir, size: $size, crc32: $crc32}';
  }
}

class ZipException implements Exception {
  const ZipException(this.message);

  final String message;

  @override
  String toString() => "ZipException: $message";
}
