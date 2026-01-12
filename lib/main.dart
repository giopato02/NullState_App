import 'package:flutter/material.dart';
import 'package:nullstate/pages/home_page.dart';

void main() {
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
      scaffoldBackgroundColor: Colors.blue[200]
      ),
      home: HomePage(),
    );
  }
}