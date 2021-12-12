import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({required this.title, Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const String assetsFilename = 'assets.zip';

  late List<File> files;
  late FirebaseStorage storage;

  @override
  void initState() {
    files = [];
    storage = FirebaseStorage.instance;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: FutureBuilder<List<File>>(
              future: loadData(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<File>> snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: snapshot.data!.map((f) => Image.file(f)).toList(),
                  );
                } else {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: const [CircularProgressIndicator()],
                  );
                }
              }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onButtonPressed,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void onButtonPressed() async {
    Directory documentsDir = (await getApplicationDocumentsDirectory());
    File zipFile = File('${documentsDir.path}/assets.zip');

    // Download zip file
    // await storage.ref('assets.zip').writeToFile(zipFile);
    debugPrint('local zip MD5: ${await _calculateMD5(zipFile)}');

    var metadata = await storage.ref('assets.zip').getMetadata();
    debugPrint('remote zip MD5 ${metadata.md5Hash}');

    // Unzip
    Directory assetsDir = Directory('${documentsDir.path}/assets');
    await assetsDir.delete(recursive: true);
    await assetsDir.create();
    await ZipFile.extractToDirectory(
        zipFile: zipFile, destinationDir: assetsDir);

    setState(() {
      var myFiles = assetsDir.listSync();
      files = myFiles.whereType<File>().toList();
      debugPrint('complete');
    });
  }

  Future<List<File>> loadData() async {
    Directory documentsDir = await getApplicationDocumentsDirectory();
    File zipFile = File('${documentsDir.path}/$assetsFilename');

    if (!await zipFile.exists() || await checkForNewAssets(zipFile)) {
      debugPrint('New assets available downloading now...');
      await downloadAssets(zipFile);
    } else {
      debugPrint('Already have latest assets, skipping download!');
    }

    Directory assetsDirectory = Directory('${documentsDir.path}/assets');
    return assetsDirectory.listSync().whereType<File>().toList();
  }

  Future<bool> checkForNewAssets(File zipFile) async {
    // Compare md5 hashes of local and remote files
    // If they are different, new assets are available since last download
    var localHash = await _calculateMD5(zipFile);
    var metadata = await storage.ref(assetsFilename).getMetadata();

    debugPrint('local zip MD5: $localHash');
    debugPrint('remote zip MD5 ${metadata.md5Hash}');

    return localHash != metadata.md5Hash;
  }

  Future downloadAssets(File destination) async {
    await storage.ref(assetsFilename).writeToFile(destination);

    Directory assetsDirectory = Directory('${destination.parent.path}/assets');

    await assetsDirectory.delete(recursive: true);

    await ZipFile.extractToDirectory(
        zipFile: destination,
        destinationDir: assetsDirectory,
        onExtracting: (zipEntry, progress) => ZipFileOperation.includeItem);
  }

  Future<String> _calculateMD5(File file) async {
    if (!await file.exists()) {
      throw Exception(
          'File at ${file.path} does not exist. Cannot calculate MD5!');
    }

    var hash = await md5.bind(file.openRead()).first;
    return base64.encode(hash.bytes);
  }
}
