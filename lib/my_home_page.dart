import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sklepboard/cubit/files_cubit.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: BlocBuilder<FilesCubit, FilesState>(
            builder: (context, state) {
              if (state is LoadingState) {
                return const CircularProgressIndicator();
              } else if (state is ErrorState) {
                return const Text('Something went wrong!');
              } else if (state is LoadedState) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: state.files.map((f) => Image.file(f)).toList(),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onDeleteCache(context),
        tooltip: 'Increment',
        child: const Icon(Icons.delete),
      ),
    );
  }

  Future onDeleteCache(BuildContext context) async {
    final filesCubit = context.read<FilesCubit>();

    await filesCubit.clearCachedFiles();
    await filesCubit.loadFiles();
  }
}
