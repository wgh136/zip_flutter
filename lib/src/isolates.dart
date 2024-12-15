import 'dart:io';
import 'dart:isolate';

import 'package:zip_flutter/zip_flutter.dart';

Future<void> isolatesExtract(String zipFile, String extractTo, int isolates) {
  var zip = ZipFile.openRead(zipFile);
  var entries = zip.getAllEntries();
  var futures = <Future>[];
  var entriesPerIsolate = (entries.length / isolates).ceil();
  for (var i = 0; i < isolates; i++) {
    if (i * entriesPerIsolate >= entries.length) {
      break;
    }
    var tasks = entries.sublist(
      i * entriesPerIsolate,
      (i + 1) * entriesPerIsolate > entries.length
          ? entries.length
          : (i + 1) * entriesPerIsolate,
    );
    futures.add(
      extractEntries(zipFile, extractTo, tasks.map((e) => e.name).toList()),
    );
  }
  return Future.wait(futures);
}

Future<void> extractEntries(
    String zipFile, String extractTo, List<String> entries) {
  return Isolate.run(() {
    var zip = ZipFile.openRead(zipFile);
    for (var entryName in entries) {
      var resultFilePath = extractTo + Platform.pathSeparator + entryName;
      var entry = zip.getEntryByName(entryName);
      if (entry.isDir) {
        Directory(resultFilePath).createSync(recursive: true);
      } else {
        entry.writeToFile(resultFilePath);
      }
    }
  });
}
