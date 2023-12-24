# zip_flutter

zip_flutter is a Dart package that enables you to extract or create zip archives using the dart:ffi library.

c code is modified from [zip](https://github.com/kuba--/zip)

## Getting started

To get started, add the following dependency to your pubspec.yaml file:

```yaml
dependencies:
  zip_flutter: ^0.0.1
```

Now, you can use the package in your Dart code:

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main(){
  // create a zip file.
  var zip = ZipFile.open("test.zip");
  /// add a file.
  zip.addFile("test/test.txt", "test.txt");
  // close zip file.
  zip.close();
  // extract zip file to a folder.
  ZipFile.openAndExtract("test.zip", "test");
}
```

## Usage

### Create a Zip File
To create a zip file, you can use the ZipFile.open method. Here's an example:

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  // Create a zip file
  var file = File("test.txt");
  file.writeAsStringSync("test");

  var zip = ZipFile.open("test.zip");
  zip.addFile("test/test.txt", "test.txt");
  zip.close();

  file.deleteSync();
}
```

### Extract a Zip File

To extract a zip file, you can use the ZipFile.openAndExtract method. Here's an example:

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  // Extract a zip file to a folder
  ZipFile.openAndExtract("test.zip", "test");
  
  // Check if the extracted file exists
  expect(File("test/test/test.txt").existsSync(), true);
  
  // Clean up: delete the extracted folder and zip file
  Directory("test/test").deleteSync(recursive: true);
  File("test.zip").deleteSync();
}

```

### Compress a Folder

To compress a folder into a zip file, you can use the ZipFile.compressFolder method. Here's an example:

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  // Create a test folder with a file
  Directory("testFolder").createSync();
  Directory("testFolder/test").createSync();
  File("testFolder/test/test.txt").writeAsStringSync("test");
  
  // Compress the folder into a zip file
  ZipFile.compressFolder("testFolder", "testFolder.zip");
  
  // Clean up: delete the test folder and zip file
  Directory("testFolder").deleteSync(recursive: true);
  File("testFolder.zip").deleteSync();
}
```

### Retrieving Information about Entries

You can retrieve information about entries in the zip archive using various methods:

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  var zip = ZipFile.open("test.zip");
  // get the total number of entries:
  var entryCount = zip.entryCount;

  //  get an entry by index:
  var entry = zip.getEntryByIndex(0);

  // get an entry by name:
  var entry = zip.getEntryByName("folder/2.txt");
}
```

### Deleting an Entry

```dart
import 'package:zip_flutter/zip_flutter.dart';

void main() {
  var zip = ZipFile.open("test.zip");
  zip.deleteEntry("1.txt");
}
```