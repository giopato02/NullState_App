import 'package:flutter/material.dart';
import 'package:nullstate/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullstate/models/note.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes_box');
  
  runApp(const NullStateApp());
}

class NullStateApp extends StatelessWidget {
  const NullStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.blue[200],
      ),
      home: HomePage(),
    );
  }
}
