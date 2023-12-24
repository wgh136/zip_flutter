import 'package:flutter/material.dart';
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: const Center(
          child: FilledButton(
            onPressed: test,
            child: Text("Test"),
          ),
        ),
      ),
    );
  }
}

void test(){
  // create a zip file.
  var zip = ZipFile.open("test.zip");
  /// add a file.
  zip.addFile("test/test.txt", "test.txt");
  // close zip file.
  zip.close();
  // extract zip file to a folder.
  ZipFile.openAndExtract("test.zip", "test");
}