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
  late bool _isDarkMode;
  late bool _isSoundEnabled;

  @override
  void initState() {
    super.initState();
    // Load data from Hive, with defaults if it's the first time running
    _focusDuration = _settingsBox.get('focusDuration', defaultValue: 25.0);
    _isStrictMode = _settingsBox.get('isStrictMode', defaultValue: false);
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
// Function to show the info dialog
  void _showDurationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Focus Tips"),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Note: If the timer doesn't update immediately after changing, please restart the app.",
              style: TextStyle(fontStyle: FontStyle.normal, color: Colors.grey),
            ),
            SizedBox(height: 20),
            Text("Recommended Intervals:", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("• 25 min: Pomodoro Technique"),
            SizedBox(height: 5),
            Text("• 60 min: Standard Session"),
            SizedBox(height: 5),
            Text("• 90 min: Ultradian Rhythm"),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Settings", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.blue[200],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // SECTION 1: FOCUS
          const Text(
            "Focus",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),

          // Setting 1: Default Duration
          // Setting 1: Default Duration
          ListTile(
            // CHANGED: Title is now a Row with Text + Info Icon
            title: Row(
              children: [
                const Text("Default Duration"),
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
            subtitle: Text("${_focusDuration.toInt()} minutes"),
            trailing: const Icon(Icons.timer),
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
            title: const Text("Strict Mode"),
            subtitle: const Text("Keep me accountable"),
            secondary: const Icon(Icons.lock_outline),
            activeThumbColor: Colors.blue, // 'activeColor' works better for iOS/Android consistency
            value: _isStrictMode,
            onChanged: (val) {
              setState(() {
                _isStrictMode = val;
                _settingsBox.put('isStrictMode', val);
              });
            },
          ),

          const Divider(height: 40),

          // SECTION 2: APP
          const Text(
            "App",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),

          // Setting 3: Dark Mode
          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode_outlined),
            activeThumbColor: Colors.blue,
            value: _isDarkMode,
            onChanged: (val) {
              setState(() {
                _isDarkMode = val;
                _settingsBox.put('isDarkMode', val);
                // Note: Actual Dark Mode theme switching requires a restart or Listenables.
                // We will implement the visual change in a later session.
              });
            },
          ),

          // Setting 4: Sound & Haptics
          SwitchListTile(
            title: const Text("Sound & Haptics"),
            secondary: const Icon(Icons.volume_up_outlined),
            activeThumbColor: Colors.blue,
            value: _isSoundEnabled,
            onChanged: (val) {
              setState(() {
                _isSoundEnabled = val;
                _settingsBox.put('isSoundEnabled', val);
              });
            },
          ),

          const Divider(height: 40),

          // SECTION 3: SUPPORT
          const Text(
            "Support",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),

          // Setting 5: Feedback
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text("Get in Touch"),
            subtitle: const Text("Send feedback or report bugs"),
            onTap: _launchEmail, // Calls our function
          ),

          // Setting 6: Donation
          ListTile(
            leading: const Icon(Icons.coffee_outlined),
            title: const Text("Support Development"),
            subtitle: const Text("Buy me a coffee"),
            onTap: _launchSupportUrl, // Calls our function
          ),
        ],
      ),
    );
  }
}