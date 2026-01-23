import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  List<Widget> pages = [
    const FocusPage(),
    const JournalPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // Wrap the Scaffold in ValueListenableBuilder for dark mode
    // This makes the whole app background react to the switch instantly.
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, widget) {
        
        // Read the setting
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        return Scaffold(
          // BACKGROUND LOGIC
          backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.blue[200],
          
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ),
            ],
          ),

          extendBody: true,

          body: IndexedStack(
            index: currentPage,
            children: pages,
          ),

          bottomNavigationBar: NavigationBar(
            // Dark Mode: Darker Nav Bar, Light Mode: White-ish
            backgroundColor: isDarkMode 
                ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.5),
            elevation: 0,
            indicatorColor: isDarkMode 
                ? Colors.grey[700] 
                : Colors.white.withValues(alpha: 0.5),
            
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.timer),
                label: 'Focus',
                selectedIcon: Icon(Icons.timer, color: Colors.blue),
              ),
              NavigationDestination(
                icon: Icon(Icons.my_library_books),
                label: 'Journal',
                selectedIcon: Icon(Icons.my_library_books, color: Colors.blue),
              ),
            ],
            onDestinationSelected: (int index) {
              setState(() {
                currentPage = index;
              });
            },
            selectedIndex: currentPage,
          ),
        );
      },
    );
  }
}