import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
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

int _onExtractEntry(ffi.Pointer<ffi.Char> filename, ffi.Pointer<ffi.Void> arg){
  return 0;
}

enum ZipOpenMode{
  readonly(114),
  write(119),
  append(97);

  final int value;

  const ZipOpenMode(this.value);
}

class ZipFile{
  final _ZipFilePtr _zip;

  /// Opens zip archive with compression level using the given mode.
  factory ZipFile.open(String path, {int level = 6, ZipOpenMode mode = ZipOpenMode.write}){
    var res = _lib.zip_open(path.toNativeUtf8().cast(), level, mode.value);
    if(res == ffi.nullptr){
      throw const ZipException("Failed to open file.");
    }
    var zip = ZipFile._create(res);
    return zip;
  }

  ZipFile._create(this._zip);

  /// Opens an entry by [name] in the zip archive.
  /// Then compresses [source] file for the current zip entry.
  ///
  /// example:
  ///
  /// ```dart
  /// var zip = ZipFile.open("/home/test.zip");
  /// zip.addFile("1.txt", "/home/1.txt");
  /// zip.addFile("folder/2.txt", "/home/2.txt");
  /// zip.close();
  /// ```
  void addFile(String name, String source){
    var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
    if(res < 0){
      throw const ZipException("Failed to open entry.");
    }
    res = _lib.zip_entry_fwrite(_zip, source.toNativeUtf8().cast());
    if(res < 0){
      throw ZipException("Failed to write content.\n"
          "Input: $source\n"
          "Trying write to $name\n"
          "Error Code $res\n");
    }
    res = _lib.zip_entry_close(_zip);
    if(res < 0){
      throw const ZipException("Failed to close entry.");
    }
  }

  /// close zip file.
  void close() {
    _lib.zip_close(_zip);
  }

  int get entryCount => _lib.zip_entries_total(_zip);

  /// Open a new entry by index in the zip archive.
  /// This function is only valid if zip archive was opened in readonly mode.
  ZipEntry getEntryByIndex(int index){
    var res = _lib.zip_entry_openbyindex(_zip, index);
    if(res < 0){
      throw const ZipException("Failed to open entry.");
    }
    return ZipEntry(
        _lib.zip_entry_name(_zip).cast<Utf8>().toDartString(),
        _lib.zip_entry_isdir(_zip) != 0,
        _lib.zip_entry_size(_zip),
        _lib.zip_entry_crc32(_zip)
    );
  }

  /// Open an entry by name in the zip archive.
  ///
  /// For zip archive opened in write or append mode the function will append
  /// a new entry. In readonly mode the function tries to locate the entry
  /// in global dictionary.
  ZipEntry getEntryByName(String name){
    var res = _lib.zip_entry_open(_zip, name.toNativeUtf8().cast());
    if(res < 0){
      throw const ZipException("Failed to open entry.");
    }
    return ZipEntry(
        name,
        _lib.zip_entry_isdir(_zip) != 0,
        _lib.zip_entry_size(_zip),
        _lib.zip_entry_crc32(_zip)
    );
  }

  /// Delete a zip archive entry.
  void deleteEntry(String name){
    var res = _lib.zip_entries_delete(_zip, name.toNativeUtf8().cast(), 1);
    if(res < 0){
      throw const ZipException("Failed to delete entry.");
    }
  }

  /// Extracts a zip archive file into directory.
  static void openAndExtract(String zipFile, String extractTo){
    ffi.Pointer<ffi.Int32> arg = malloc.allocate(4);

    ffi.Pointer<ffi.NativeFunction<ffi.Int Function(
        ffi.Pointer<ffi.Char> filename, ffi.Pointer<ffi.Void> arg)>> func
      = ffi.Pointer.fromFunction(_onExtractEntry, 0);

    _lib.zip_extract(
        zipFile.toNativeUtf8().cast(),
        extractTo.toNativeUtf8().cast(), func, arg.cast());

    malloc.free(arg);
  }

  static void compressFolder(String sourceFolder, String zipFileName){
    sourceFolder = path.absolute(sourceFolder);
    var zip = ZipFile.open(zipFileName);
    void walk(String path){
      for(var entry in Directory(path).listSync()){
        if(entry is Directory){
          walk(entry.path);
        } else {
          var filePathInZip = entry.path.replaceFirst(sourceFolder, "");
          if(filePathInZip.startsWith('/') || filePathInZip.startsWith('\\')){
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

class ZipEntry{
  final String name;
  final bool isDir;
  final int size;
  final int crc32;

  const ZipEntry(this.name, this.isDir, this.size, this.crc32);
}

class ZipException implements Exception {
  const ZipException(this.message);

  final String message;

  @override
  String toString() => "ZipException: $message";
}
