# zip_flutter

zip_flutter is a Dart package that enables you to extract or create zip archives using the dart:ffi library.

c code is modified from [zip](https://github.com/kuba--/zip)

## Getting started

Add the following dependency to your pubspec.yaml file:

```yaml
dependencies:
  zip_flutter: ^0.0.3
```

## Usage

### Create a Zip File

Use the ZipFile.open method.

```dart
import 'package:zip_flutter/zip_flutter.dart';

void testAddFilesWithFileNames() {
  // Create a zip file
  var zip = ZipFile.open('test.zip');
  // Add file with file path
  zip.addFile('1.txt', 'test/1.txt');
  // Add file with file bytes
  zip.addFileFromBytes('2.txt', utf8.encode('Hello, World!'));
  // To add a file in a folder, use the '/' separator
  zip.addFile('folder/3.txt', 'test/folder/3.txt');
  // Add empty directory
  zip.addDirectory('empty');
  // Close the zip file
  zip.close();
}
```

### Read a Zip File

Read file list
```dart
void testListFiles() {
  // Open a zip file, mode must be ZipOpenMode.readonly
  var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
  var entries = zip.getAllEntries();
  for (var entry in entries) {
    print(entry);
  }
  zip.close();
}
```

Read file by name
```dart
void testReadFile() {
  var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
  var entry = zip.getEntryByName('1.txt');
  print(utf8.decode(entry.read()));
  zip.close();
}
```

Read file by index in file list
```dart
void testReadFileByIndex() {
  var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
  var entry = zip.getEntryByIndex(0);
  print(utf8.decode(entry.read()));
  zip.close();
}
```

Extract zip manually
```dart
void testUnzipManually() {
  if (Directory('extracted').existsSync()) {
    Directory('extracted').deleteSync(recursive: true);
  }
  Directory('extracted').createSync();
  var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
  var entries = zip.getAllEntries();
  for (var entry in entries) {
    if (entry.isDir) {
      Directory('extracted/${entry.name}').createSync(recursive: true);
      continue;
    }
    var file = File('extracted/${entry.name}');
    file.createSync(recursive: true);
    file.writeAsBytesSync(entry.read());
  }
  zip.close();
}
```

### Utils for quick use

Compress a folder to a zip file
```dart
void testCompressFolder() {
  var toBeCompressed = Directory('test');
  var resultZip = File('test.zip');
  ZipFile.compressFolder(toBeCompressed.path, resultZip.path);
}
```

Compress a folder with multiple threads
```dart
void testCompressWithThreads() async {
  var toBeCompressed = Directory('test');
  var resultZip = File('test.zip');
  await ZipFile.compressFolderAsync(toBeCompressed.path, resultZip.path, 4); // 4 threads
  print('Compression completed');
}
```
> Note: 
> Current implementation is not efficient for compressing large files (> 20MB).
> If a thread is compressing a large file, other threads will be blocked.

Extract a zip file to a folder
```dart
void testExtractZip() {
  var toBeExtracted = File('test.zip');
  var resultFolder = Directory('extracted');
  ZipFile.openAndExtract(toBeExtracted.path, resultFolder.path);
}
```

Extract a zip file with multiple isolates
```dart
void testExtractZipWithIsolates() async {
  var toBeExtracted = File('test.zip');
  var resultFolder = Directory('extracted');
  await ZipFile.openAndExtractAsync(toBeExtracted.path, resultFolder.path, 4); // 4 isolates
}
```