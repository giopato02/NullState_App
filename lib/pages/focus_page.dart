import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math'; // For random quotes
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  // -- State --
  double selectedMinutes = 25;
  bool isRunning = false;
  bool isPaused = false;
  bool isBreakMode = false;

  // -- Timer --
  DateTime? _endTime;
  int remainingSeconds = 0;
  Timer? timer;
  int totalSeconds = 0;

  // -- Strict Mode --
  bool _wasStrictlyInterrupted = false;

  // -- Quotes Logic --
  Timer? _quoteTimer;
  String _currentQuote = "Relax & Recharge";
  int _lastQuoteIndex = -1; 

  final List<String> _breakQuotes = [
    "Breathe in... Breathe out...",
    "Look at something 20 feet away",
    "Stretch your shoulders",
    "Drink some water",
    "Close your eyes for a moment",
    "You did great, enjoy the rest",
    "Clear your mind",
    "Release the tension in your muscles",
    "Calm your brain",
    "Stand up, look around, feel present...",
    
    "Close your eyes, relax yourself",
    "Unclench your jaw",
    "Drop your shoulders down",
    "Roll your neck gently",
    "Shake out your hands",
    "Wiggle your toes",
    "Stand up and stretch your back",
    "Massage your temples",
    "Relax your forehead",
    "Step away from the screen",
    
    "Rest your eyes, look at something outside",
    "Inhale peace, exhale stress",
    "Let your thoughts float away",
    "Listen to the sounds around you",
    "Ground yourself, be present",
    "Silence is recharging",
    "Feel the ground beneath your feet",
    "Let go of the rush",
    "Slow down your breathing",
    "Notice the light in the room",

    "Rest is most productive, if used wisely",
    "You are making progress",
    "Recharge for the next wave",
    "This break powers your focus",
    "Be kind to yourself",
    "You've earned this moment",
    "Trust the process",
    "Think of something that makes you smile",
    "Reset... Refocus... Restart...",
    "Your mind needs this space"
  ];

@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();

    // Listen for changes in Settings
    // If user changes 'Default Duration' in settings, update the slider immediately
    // only if the timer is NOT running.
    final settingsBox = Hive.box('settings_box');
    settingsBox.listenable(keys: ['focusDuration']).addListener(() {
      if (!mounted) return;
      if (!isRunning && !isPaused && !isBreakMode) {
        _loadSettings();
      }
    });
  }

  void _loadSettings() {
    final settingsBox = Hive.box('settings_box');
    double savedDuration = settingsBox.get('focusDuration', defaultValue: 25.0);
    setState(() {
      selectedMinutes = savedDuration;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    timer?.cancel();
    _quoteTimer?.cancel();
    super.dispose();
  }

  // -- FUNCTIONS --

  void _toggleMode(bool toBreak) {
    if (isRunning) return; // Lock toggle while timer runs

    setState(() {
      isBreakMode = toBreak;
      // Set defaults for the mode
      if (isBreakMode) {
        selectedMinutes = 5; // Default break
      } else {
        _loadSettings(); // Revert to user's default focus time
      }
    });
  }

  // LOGIC TO PREVENT REPEATS
  void _updateQuote() {
    if (_breakQuotes.isEmpty) return;
    
    int newIndex;
    do {
      newIndex = Random().nextInt(_breakQuotes.length);
    } while (newIndex == _lastQuoteIndex && _breakQuotes.length > 1);

    _lastQuoteIndex = newIndex; 

    setState(() {
      _currentQuote = _breakQuotes[newIndex];
    });
  }

  void _startQuoteCycle() {
    _updateQuote(); // Show one immediately
    
    _quoteTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      _updateQuote();
    });
  }

  void startTimer() {
    final settingsBox = Hive.box('settings_box');
    bool isStrict = settingsBox.get('isStrictMode', defaultValue: false);

    setState(() {
      isRunning = true;
      isPaused = false;
    });

    if (_endTime == null) {
      totalSeconds = (selectedMinutes * 60).toInt();
      remainingSeconds = totalSeconds;
      _endTime = DateTime.now().add(Duration(seconds: totalSeconds));
    } else {
      _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    }

    // STRICT MODE & WAKELOCK LOGIC
    if (!isBreakMode && isStrict) {
      WakelockPlus.enable();
    }
    
    // If it's Break Mode, start the quotes!
    if (isBreakMode) {
      _startQuoteCycle();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        remainingSeconds = (_endTime!.difference(now).inMilliseconds / 1000).ceil();

        if (remainingSeconds <= 0) {
          _finishTimer();
        }
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    _quoteTimer?.cancel(); 
    WakelockPlus.disable();
    setState(() {
      isRunning = false;
      isPaused = true;
    });
  }

  void stopTimer() {
    timer?.cancel();
    _quoteTimer?.cancel();
    WakelockPlus.disable();
    setState(() {
      isRunning = false;
      isPaused = false;
      remainingSeconds = 0;
      _endTime = null;
    });
  }
  
  // Called when timer hits 0 naturally
  void _finishTimer() {
    stopTimer();
    // TODO: Play Sound Here

    // CHECK FRICTIONLESS FLOW
    final settingsBox = Hive.box('settings_box');
    bool autoFlow = settingsBox.get('autoFlow', defaultValue: false);

    if (autoFlow) {
      // 1. Determine the target mode (If currently Focus, go Break. If Break, go Focus)
      bool targetModeIsBreak = !isBreakMode;
      
      // 2. Switch UI and Duration
      _toggleMode(targetModeIsBreak);

      // 3. AUTO-START THE NEXT TIMER
      startTimer();
    }
  }

  // LIFECYCLE OBSERVER
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final settingsBox = Hive.box('settings_box');
    bool isStrict = settingsBox.get('isStrictMode', defaultValue: false);

    if (state == AppLifecycleState.paused) {
      // ONLY punish if: Strict is ON, Timer is RUNNING, and we are NOT in Break Mode
      if (isStrict && isRunning && !isBreakMode) {
        stopTimer();
        _wasStrictlyInterrupted = true;
      }
    }

    if (state == AppLifecycleState.resumed && _wasStrictlyInterrupted) {
      _wasStrictlyInterrupted = false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Focus Broken 😔"),
          content: const Text("Strict Mode is active. You left the app, so the timer was reset."),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("I understand"))],
        ),
      );
    } else if (state == AppLifecycleState.resumed && isRunning && _endTime != null) {
       // Visual update for Resume
       setState(() {
          remainingSeconds = _endTime!.difference(DateTime.now()).inSeconds;
       });
    }
  }

  String getFormattedTime() {
    if (!isRunning && !isPaused) return "${selectedMinutes.toInt()}:00";
    if (remainingSeconds < 0) return "00:00";
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings_box').listenable(),
      builder: (context, Box box, widget) {
        
        bool isDarkMode = box.get('isDarkMode', defaultValue: false);

        // Determine Background Color
        Color? bgColor;
        if (isBreakMode) {
          // Break Mode: Light Green (Normal) vs Dark Green (Dark Mode)
          bgColor = isDarkMode ? Colors.green[900] : Colors.green[200];
        } else {
          // Focus Mode: Transparent (Normal) vs Transparent (Dark Mode handles Scaffold)
          // Since HomePage scaffold handles the Black BG, we keep this transparent.
          bgColor = Colors.transparent; 
        }

        // Determine Button Color
        Color btnColor = isDarkMode ? Colors.grey[800]! : Colors.white;
        Color btnTextColor = isDarkMode ? Colors.white : Colors.blue;
        if (isBreakMode && !isDarkMode) btnTextColor = Colors.green; // Keep green text for light mode break

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          color: bgColor,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. MODE TOGGLE
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeBtn("Focus", false, isDarkMode),
                      _buildModeBtn("Break", true, isDarkMode),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // 2. TIMER CIRCLE
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: CircularProgressIndicator(
                        value: (isRunning || isPaused) 
                          ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) 
                          : 1.0,
                        strokeWidth: 15,
                        color: isPaused ? Colors.orangeAccent : Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    Text(
                      getFormattedTime(),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                // 3. QUOTES
                if (isBreakMode && (isRunning || isPaused))
                  SizedBox(
                    height: 50,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      child: Padding(
                        key: ValueKey<String>(_currentQuote),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          _currentQuote,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 18, 
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                else 
                  const SizedBox(height: 50),

                // 4. SLIDER
                if (!isRunning && !isPaused)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          isBreakMode ? "Rest Duration" : "Focus Duration", 
                          style: const TextStyle(color: Colors.white, fontSize: 20)
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() { if (selectedMinutes > 1) selectedMinutes--; });
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 1),
                            IconButton(
                              onPressed: () {
                                setState(() { 
                                  double maxVal = isBreakMode ? 30 : 120;
                                  if (selectedMinutes < maxVal) selectedMinutes++; 
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
                            ),
                          ],
                        ),
                        Slider(
                          value: selectedMinutes,
                          min: 1,
                          max: isBreakMode ? 30 : 120,
                          divisions: isBreakMode ? 29 : 119,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white.withValues(alpha: 0.3),
                          onChanged: (newValue) {
                            setState(() { selectedMinutes = newValue.roundToDouble(); });
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // 5. BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor, // Changes to Grey in Dark Mode
                        foregroundColor: isPaused 
                           ? Colors.orange 
                           : btnTextColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      ),
                      onPressed: () {
                        if (isRunning) { pauseTimer(); } else { startTimer(); }
                      },
                      child: Text(
                        isRunning ? "PAUSE" : (isPaused ? "RESUME" : (isBreakMode ? "START BREAK" : "START FOCUS")),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isRunning || isPaused) ...[
                      const SizedBox(width: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        ),
                        onPressed: stopTimer,
                        child: const Text("STOP", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // Updated Helper for Mode Buttons
  Widget _buildModeBtn(String title, bool isBreak, bool isDarkMode) {
    bool isActive = (isBreakMode == isBreak);
    // Active Text Color: Green for break, Blue for Focus (or White in DarkMode?)
    // Let's keep the branding colors even in Dark Mode for the active state
    Color activeTextColor = isBreak ? Colors.green : Colors.blue;

    return GestureDetector(
      onTap: () => _toggleMode(isBreak),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Active button gets White (Normal) or Dark Grey (Dark Mode)
          color: isActive 
             ? (isDarkMode ? Colors.black : Colors.white) 
             : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive 
              ? activeTextColor 
              : (isDarkMode ? Colors.grey : Colors.white),
          ),
        ),
      ),
    );
  }
}