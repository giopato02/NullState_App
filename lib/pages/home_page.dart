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
          backgroundColor: isDarkMode ? const Color.fromARGB(255, 5, 29, 70) : Colors.blue[200],
          
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

          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                // If selected, use Blue. If not, use White (Dark Mode) or Black (Light Mode)
                return TextStyle(
                  color: states.contains(WidgetState.selected)
                      ? Colors.blue
                      : (isDarkMode ? Colors.white70 : Colors.black54),
                  fontWeight: FontWeight.bold,
                );
              }),
            ),
            child: NavigationBar(
              backgroundColor: isDarkMode 
                  ? const Color(0xFF1E1E1E).withValues(alpha: 0.9) 
                  : Colors.white.withValues(alpha: 0.5),
              elevation: 0,
              indicatorColor: isDarkMode 
                  ? Colors.grey[800] 
                  : Colors.white,
              
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer, color: Colors.blue),
                  label: 'Focus',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_outlined, color: Colors.blue),
                  label: 'Journal',
                ),
              ],
              onDestinationSelected: (int index) {
                setState(() {
                  currentPage = index;
                });
              },
              selectedIndex: currentPage,
            ),
          ),
        );
      },
    );
  }
}