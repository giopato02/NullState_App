import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsBox = Hive.box('settings_box');

  late double _focusDuration;
  late bool _isStrictMode;
  late bool _autoFlow;
  late bool _isDarkMode;
  late bool _isSoundEnabled;

  @override
  void initState() {
    super.initState();
    // Load data from Hive, with defaults if it's the first time running
    _focusDuration = _settingsBox.get('focusDuration', defaultValue: 25.0);
    _isStrictMode = _settingsBox.get('isStrictMode', defaultValue: false);
    _autoFlow = _settingsBox.get('autoFlow', defaultValue: false);
    _isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
    _isSoundEnabled = _settingsBox.get('isSoundEnabled', defaultValue: true);
  }

  // Function to open Email
  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@nullstate.app', // Change this to the actual email later
      query: 'subject=NullState Feedback', 
    );

    try {
      await launchUrl(emailLaunchUri);
    } catch (e) {
      debugPrint("Could not launch email: $e");
    }
  }
// Function to show the info for Default Duration
void _showDurationInfo() {
    // Check for dark mode
    bool isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
    Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Focus Tips", style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Note: If the timer doesn't update immediately after changing, please restart the app.",
              style: TextStyle(fontStyle: FontStyle.normal, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text("Recommended Intervals:", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 10),
            Text("• 25 min: Pomodoro Technique", style: TextStyle(color: textColor)),
            const SizedBox(height: 5),
            Text("• 60 min: Standard Session", style: TextStyle(color: textColor)),
            const SizedBox(height: 5),
            Text("• 90 min: Ultradian Rhythm", style: TextStyle(color: textColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }
// Function to show the info for Strict Mode
  void _showStrictModeInfo() {
    bool isDarkMode = _settingsBox.get('isDarkMode', defaultValue: false);
    Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Strict Mode", style: TextStyle(color: textColor)),
        content: Text(
          "This mode detects if you leave the app and resets your timer to keep you accountable.\n\n"
          "❗️DISCLAIMER❗️: Do not shut the phone off during this mode, since the app detects it as a leave and automatically resets your timer.",
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  // Function to open Browser
  Future<void> _launchSupportUrl() async {
    // Replace with your actual link (Ko-fi, Patreon, etc.)
    final Uri url = Uri.parse('https://www.buymeacoffee.com'); 
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch url: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Settings Box for Dark Mode updates
    return ValueListenableBuilder(
      valueListenable: _settingsBox.listenable(),
      builder: (context, Box box, _) {
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);
        
        // Dynamic Colors based on Dark Mode
        Color bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
        Color textColor = isDarkMode ? Colors.white : Colors.black;
        Color headerColor = isDarkMode ? Colors.blueAccent : Colors.blue;
        Color iconColor = isDarkMode ? Colors.white70 : Colors.black54;
        Color dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text(
              "Settings", 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.blue[200],
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 80.0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // SECTION 1: FOCUS
              Text(
                "Focus",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: headerColor),
              ),
              const SizedBox(height: 10),

              // Setting 1: Default Duration
              ListTile(
                // CHANGED: Title is now a Row with Text + Info Icon
                title: Row(
                  children: [
                    Text("Default Duration", style: TextStyle(color: textColor)),
                    const SizedBox(width: 8), // Small gap
                    InkWell(
                      onTap: _showDurationInfo, // Call our new function
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0), // Hitbox padding
                        child: Icon(
                          Icons.info_outline, 
                          size: 20, 
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text("${_focusDuration.toInt()} minutes", style: const TextStyle(color: Colors.grey)),
                trailing: Icon(Icons.timer, color: iconColor),
              ),
              Slider(
                value: _focusDuration,
                min: 5,
                max: 120,
                divisions: 23,
                activeColor: Colors.blue,
                inactiveColor: Colors.blue[100],
                label: "${_focusDuration.toInt()} min",
                onChanged: (val) {
                  setState(() {
                    _focusDuration = val;
                    // Save to Database immediately
                    _settingsBox.put('focusDuration', val);
                  });
                },
              ),

              // Setting 2: Strict Mode
              SwitchListTile(
                title: Row(
                  children: [
                    Text("Strict Mode", style: TextStyle(color: textColor)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showStrictModeInfo,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.info_outline, 
                          size: 20, 
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text("Keep me accountable", style: TextStyle(color: Colors.grey)),
                secondary: Icon(Icons.lock_outline, color: iconColor),
                activeThumbColor: Colors.blue, 
                value: _isStrictMode,
                onChanged: (val) {
                  setState(() {
                    _isStrictMode = val;
                    _settingsBox.put('isStrictMode', val);
                  });
                },
              ),

              // Setting 3. Frictionless Flow (Auto Switch)
              SwitchListTile(
                title: Text("Frictionless Flow", style: TextStyle(color: textColor)),
                subtitle: const Text("Auto-switch to Break when Focus ends", style: TextStyle(color: Colors.grey)),
                secondary: Icon(Icons.autorenew, color: iconColor),
                activeThumbColor: Colors.blue,
                value: _autoFlow,
                onChanged: (val) {
                  setState(() {
                    _autoFlow = val;
                    _settingsBox.put('autoFlow', val);
                  });
                },
              ),

              Divider(height: 40, color: dividerColor),

              // SECTION 2: APP
              Text(
                "App",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: headerColor),
              ),
              const SizedBox(height: 10),

              // Setting 4: Dark Mode
              SwitchListTile(
                title: Text("Dark Mode", style: TextStyle(color: textColor)),
                secondary: Icon(Icons.dark_mode_outlined, color: iconColor),
                activeThumbColor: Colors.blue,
                value: _isDarkMode,
                onChanged: (val) {
                  setState(() {
                    _isDarkMode = val;
                    _settingsBox.put('isDarkMode', val);
                  });
                },
              ),

              // Setting 5: Sound & Haptics
              SwitchListTile(
                title: Text("Sound & Haptics", style: TextStyle(color: textColor)),
                secondary: Icon(Icons.volume_up_outlined, color: iconColor),
                activeThumbColor: Colors.blue,
                value: _isSoundEnabled,
                onChanged: (val) {
                  setState(() {
                    _isSoundEnabled = val;
                    _settingsBox.put('isSoundEnabled', val);
                  });
                },
              ),

              Divider(height: 40, color: dividerColor),

              // SECTION 3: SUPPORT
              Text(
                "Support",
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: headerColor),
              ),
              const SizedBox(height: 10),

              // Setting 6: Feedback
              ListTile(
                leading: Icon(Icons.mail_outline, color: iconColor),
                title: Text("Get in Touch", style: TextStyle(color: textColor)),
                subtitle: const Text("Send feedback or report bugs", style: TextStyle(color: Colors.grey)),
                onTap: _launchEmail,
              ),

              // Setting 7: Donation
              ListTile(
                leading: Icon(Icons.coffee_outlined, color: iconColor),
                title: Text("Support Development", style: TextStyle(color: textColor)),
                subtitle: const Text("Buy me a coffee", style: TextStyle(color: Colors.grey)),
                onTap: _launchSupportUrl,
              ),
            ],
          ),
        );
      }
    );
  }
}