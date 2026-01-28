import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullstate/pages/home_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullstate/models/note.dart';
import 'package:nullstate/services/notification_service.dart';
import 'package:nullstate/models/session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  await NotificationService().init();

  // Register Adapters
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(SessionAdapter());

  await Hive.openBox<Note>('notes_box'); // for notes
  await Hive.openBox<Session>('session_box'); // for stats
  await Hive.openBox('settings_box'); // for settings

  runApp(const NullStateApp());
}

class NullStateApp extends StatelessWidget {
  const NullStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, widget) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // Swap the theme automatically
          theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: const HomePage(),
        );
      },
    );
  }
}
