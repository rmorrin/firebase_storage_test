import 'dart:io';

abstract class AssetsRepository {
  Future<List<File>> loadAssets();
  Future clearDownloadedAssets();
}
