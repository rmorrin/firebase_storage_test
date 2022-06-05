import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sklepboard/cubit/files_cubit.dart';
import 'package:sklepboard/my_home_page.dart';
import 'package:sklepboard/repositories/assets_repository_impl.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BlocProvider<FilesCubit>(
        create: (context) => FilesCubit(
          repository: AssetsRepositoryImpl(
            storage: FirebaseStorage.instance,
          ),
        )..loadFiles(),
        child: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}
