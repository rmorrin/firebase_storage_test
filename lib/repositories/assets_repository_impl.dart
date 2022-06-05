import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sklepboard/repositories/assets_repository.dart';

class AssetsRepositoryImpl implements AssetsRepository {
  const AssetsRepositoryImpl({required this.storage});

  static const String assetsArchiveFilename = 'assets.zip';

  final FirebaseStorage storage;

  @override
  Future<List<File>> loadAssets() async {
    Directory cacheDir = await getTemporaryDirectory();
    String path = cacheDir.path;

    if (await _checkForNewAssets(path)) {
      debugPrint('Latest assets not not found, downloading now...');
      await _downloadAssets(path);
    } else {
      debugPrint('Already have latest assets, skipping download!');
    }

    return await _listAssets(path);
  }

  @override
  Future clearDownloadedAssets() async {
    Directory cacheDir = await getTemporaryDirectory();

    if (await cacheDir.exists()) {
      debugPrint('Deleting cache directory at ${cacheDir.path}...');
      await cacheDir.delete(recursive: true);
    }
  }

  Future<bool> _checkForNewAssets(String path) async {
    File archiveFile = File('$path/$assetsArchiveFilename');

    if (!await archiveFile.exists()) {
      // No assets archive exists, so need to download
      return true;
    }

    // Compare md5 hashes of local and remote files
    // If they are different, new assets are available since last download
    var localHash = await _calculateMD5(archiveFile);
    var metadata = await storage.ref(assetsArchiveFilename).getMetadata();

    debugPrint('local zip MD5: $localHash');
    debugPrint('remote zip MD5 ${metadata.md5Hash}');

    return localHash != metadata.md5Hash;
  }

  Future<String> _calculateMD5(File file) async {
    if (!await file.exists()) {
      throw Exception(
          'File at ${file.path} does not exist. Cannot calculate MD5!');
    }

    var hash = await md5.bind(file.openRead()).first;
    return base64.encode(hash.bytes);
  }

  Future _downloadAssets(String path) async {
    Directory assetsDirectory = Directory('$path/assets');
    File assetsArchive = File('$path/$assetsArchiveFilename');

    // Download latest assets from firebase
    await storage.ref(assetsArchiveFilename).writeToFile(assetsArchive);

    // Delete existing assets directory ahead of extracting new archive
    if (await assetsDirectory.exists()) {
      await assetsDirectory.delete(recursive: true);
    }

    debugPrint('Assets downloaded, extracting to ${assetsDirectory.path}');

    await ZipFile.extractToDirectory(
        zipFile: assetsArchive,
        destinationDir: assetsDirectory,
        onExtracting: (zipEntry, progress) => ZipFileOperation.includeItem);
  }

  Future _listAssets(String path) async {
    Directory assetsDirectory = Directory('$path/assets');

    return assetsDirectory.listSync().whereType<File>().toList();
  }
}
