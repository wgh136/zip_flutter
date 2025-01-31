import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zip_flutter/zip_flutter.dart';

void main() async {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    var cacheDir = await getApplicationCacheDirectory();
    Directory.current = cacheDir.path;
    print("Current platform does not support file system operations. Using cache directory: ${cacheDir.path}");
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: ListView(
          children: [
            ListTile(
              title: const Text('Create Test Files'),
              onTap: createTestFiles,
            ),
            ListTile(
              title: const Text('Create zip With File Names'),
              onTap: testAddFilesWithFileNames,
            ),
            ListTile(
              title: const Text('Create zip With File Bytes'),
              onTap: testAddFilesWithBytes,
            ),
            ListTile(
              title: const Text('Create zip With Multiple Threads'),
              onTap: testCompressWithThreads,
            ),
            ListTile(
              title: const Text('List Files'),
              onTap: testListFiles,
            ),
            ListTile(
              title: const Text('Read File'),
              onTap: testReadFile,
            ),
            ListTile(
              title: const Text('Unzip Manually'),
              onTap: testUnzipManually,
            ),
            ListTile(
              title: const Text('Unzip Sync'),
              onTap: testUnzipSync,
            ),
            ListTile(
              title: const Text('Unzip With Isolates'),
              onTap: testUnzipWithIsolates,
            ),
          ],
        ),
      ),
    );
  }

  void createTestFiles() {
    if(Directory('test').existsSync()) {
      Directory('test').deleteSync(recursive: true);
    }
    Directory('test').createSync();
    File('test/1.txt').writeAsStringSync('Hello World');
    File('test/2.txt').writeAsStringSync('Hello World 2');
    Directory('test/folder').createSync();
    File('test/folder/3.txt').writeAsStringSync('Hello World 3');
    Directory('test/empty').createSync();
  }

  void testAddFilesWithFileNames() {
    if (File('test.zip').existsSync()) {
      File('test.zip').deleteSync();
    }
    var zip = ZipFile.open('test.zip');
    zip.addFile('1.txt', 'test/1.txt');
    zip.addFile('2.txt', 'test/2.txt');
    zip.addFile('folder/3.txt', 'test/folder/3.txt');
    zip.addDirectory('empty');
    zip.close();
  }

  void testAddFilesWithBytes() {
    if (File('test.zip').existsSync()) {
      File('test.zip').deleteSync();
    }
    var zip = ZipFile.open('test.zip');
    zip.addFileFromBytes('1.txt', File('test/1.txt').readAsBytesSync());
    zip.addFileFromBytes('2.txt', File('test/2.txt').readAsBytesSync());
    zip.addFileFromBytes('folder/3.txt', File('test/folder/3.txt').readAsBytesSync());
    zip.addDirectory('empty');
    zip.close();
  }

  void testCompressWithThreads() async {
    if (File('test.zip').existsSync()) {
      File('test.zip').deleteSync();
    }
    await ZipFile.compressFolderAsync(r"test", 'test.zip', 4);
    print('Compression completed');
  }

  void testListFiles() {
    var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
    var entries = zip.getAllEntries();
    for (var entry in entries) {
      print(entry);
    }
    zip.close();
  }

  void testReadFile() {
    var zip = ZipFile.open('test.zip', mode: ZipOpenMode.readonly);
    var entry = zip.getEntryByName('1.txt');
    print(utf8.decode(entry.read()));
    zip.close();
  }

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
    print('Unzip completed');
  }

  void testUnzipSync() {
    if (Directory('extracted').existsSync()) {
      Directory('extracted').deleteSync(recursive: true);
    }
    Directory('extracted').createSync();
    ZipFile.openAndExtract('test.zip', 'extracted');
    print('Unzip completed');
  }

  void testUnzipWithIsolates() async {
    if (Directory('extracted').existsSync()) {
      Directory('extracted').deleteSync(recursive: true);
    }
    Directory('extracted').createSync();
    await ZipFile.openAndExtractAsync('test.zip', 'extracted', 4);
    print('Unzip completed');
  }
}