import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullstate/pages/focus_page.dart';
import 'package:nullstate/pages/journal_page.dart';
import 'package:nullstate/pages/settings_page.dart';
import 'package:nullstate/pages/stats_page.dart';

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
    const StatsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, widget) {
        
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        // 1. POLISH: Gradient Backgrounds
        // Light Mode: Soft Blue -> White (Calm, Airy)
        // Dark Mode: Deep Navy -> Black (Night mode, Focus)
        final Gradient backgroundGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
              ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)] // "Moonlit Asteroid"
              : [Colors.blue[200]!, Colors.blue[50]!], // Soft Cloud
        );

        return Container(
          decoration: BoxDecoration(gradient: backgroundGradient),
          child: Scaffold(
            backgroundColor: Colors.transparent, // Let gradient show through
            extendBodyBehindAppBar: true,
            extendBody: true, // Navigation bar floats over content

            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              // 2. POLISH: Only show Settings on the Focus Page (Index 0)
              // This prevents it from cluttering the Stats/Journal headers
              actions: currentPage == 0 
                ? [
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
                  ]
                : [], // Hide on other pages
            ),

            body: IndexedStack(
              index: currentPage,
              children: pages,
            ),

            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  return TextStyle(
                    color: states.contains(WidgetState.selected)
                        ? Colors.blue
                        : (isDarkMode ? Colors.white70 : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                }),
              ),
              child: NavigationBar(
                height: 70, // Slightly shorter for a sleeker look
                backgroundColor: isDarkMode 
                    ? const Color(0xFF1E1E1E).withValues(alpha: 0.85) // Slight transparency
                    : Colors.white.withValues(alpha: 0.85),
                elevation: 0,
                indicatorColor: isDarkMode 
                    ? Colors.blue.withValues(alpha: 0.2) // Subtle glow in dark mode
                    : Colors.blue[100],
                
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer, color: Colors.blue),
                    label: 'Focus',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book, color: Colors.blue),
                    label: 'Journal',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_rounded),
                    selectedIcon: Icon(Icons.bar_chart, color: Colors.blue),
                    label: 'Stats',
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
          ),
        );
      },
    );
  }
}