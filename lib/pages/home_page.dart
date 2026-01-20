import 'package:flutter/material.dart';
import 'package:nullstate/pages/focus_page.dart';
import 'package:nullstate/pages/journal_page.dart';
import 'package:nullstate/pages/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;
  List<Widget> pages = const [
    FocusPage(),
    JournalPage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],

      extendBodyBehindAppBar: true, // Allows the sky color to go behind the app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0), // Pushes it away from the edge
            child: IconButton(
              icon: const Icon(
                Icons.settings, 
                color: Colors.white, 
                size: 30, // Makes the gear bigger
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),

      extendBody: true,
      body: pages[currentPage],
      
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white.withValues(alpha: 0.5), 
        elevation: 0,
        indicatorColor: Colors.white.withValues(alpha: 0.5),

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer), 
            label: 'Focus',
            selectedIcon: Icon(
              Icons.timer, 
              color: Colors.blue),
          ),
          NavigationDestination(
            icon: Icon(Icons.my_library_books), 
            label: 'Journal',
            selectedIcon: Icon(
              Icons.my_library_books, 
              color: Colors.blue),
          ),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            currentPage = index;
          }
          );
        },
        selectedIndex: currentPage,
      ),
    );
  }
}