import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sklepboard/repositories/assets_repository.dart';

part 'files_state.dart';

class FilesCubit extends Cubit<FilesState> {
  FilesCubit({required this.repository}) : super(InitialState());

  final AssetsRepository repository;

  Future loadFiles() async {
    try {
      emit(LoadingState());

      await Future.delayed(const Duration(seconds: 2));

      final files = await repository.loadAssets();

      emit(LoadedState(files));
    } catch (e) {
      debugPrint('An error occurred loading files: $e');
      emit(ErrorState());
    }
  }

  Future clearCachedFiles() async {
    await repository.clearDownloadedAssets();
  }
}
