part of 'files_cubit.dart';

@immutable
abstract class FilesState extends Equatable {}

class InitialState extends FilesState {
  @override
  List<Object?> get props => [];
}

class LoadingState extends FilesState {
  @override
  List<Object?> get props => [];
}

class LoadedState extends FilesState {
  final List<File> files;

  LoadedState(this.files);

  @override
  List<Object?> get props => [];
}

class ErrorState extends FilesState {
  @override
  List<Object?> get props => [];
}
