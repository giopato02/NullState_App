import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nullstate/services/notification_service.dart';
import 'package:nullstate/models/session.dart';
import 'package:flutter_background/flutter_background.dart';

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
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
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
    "Your mind needs this space",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true, // CRITICAL: Keeps timer ticking on Android
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory
              .playback, // Plays in silent mode/background
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
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
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
    super.dispose();
  }

  // -- FUNCTIONS --

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

  // Haptics Helper
  void _triggerHaptic({bool heavy = false, bool success = false}) {
    final settingsBox = Hive.box('settings_box');
    bool isSoundEnabled = settingsBox.get('isSoundEnabled', defaultValue: true);

    if (isSoundEnabled) {
      if (success) {
        // Long vibration for finishing
        HapticFeedback.vibrate();
      } else if (heavy) {
        // Thud for Stop/Delete
        HapticFeedback.heavyImpact();
      } else {
        // Crisp click for buttons
        HapticFeedback.mediumImpact();
      }
    }
  }

  // Play Completion Sound
  void _playCompletionSound() async {
    final settingsBox = Hive.box('settings_box');
    if (settingsBox.get('isSoundEnabled', defaultValue: true)) {
      await _sfxPlayer.play(AssetSource('sounds/ding.mp3'));
    }
  }

  // Manage White Noise
  void _manageWhiteNoise({required bool play}) async {
    final settingsBox = Hive.box('settings_box');
    bool whiteNoiseEnabled = settingsBox.get('whiteNoise', defaultValue: false);

    // If we are asked to play, AND settings allow it, AND we are actually running
    if (play && whiteNoiseEnabled && isRunning) {
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      // Only play if not already playing to avoid stutter
      if (_bgmPlayer.state != PlayerState.playing) {
        await _bgmPlayer.play(AssetSource('sounds/white_noise.mp3'));
      }
    } else {
      await _bgmPlayer.stop();
    }
  }

  void _toggleMode(bool toBreak) {
    if (isRunning || isPaused) return;

    _triggerHaptic();

    setState(() {
      isBreakMode = toBreak;
      if (isBreakMode) {
        selectedMinutes = 5;
      } else {
        _loadSettings();
      }
    });
  }

  void startTimer() async {
    _triggerHaptic();
    if (Platform.isAndroid && !isBreakMode) {
      try {
        final androidConfig = FlutterBackgroundAndroidConfig(
          notificationTitle: "NullState Focus",
          notificationText: "Timer is running in the background",
          notificationImportance: AndroidNotificationImportance.normal,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'), 
        );
        
        // Initialize & Enable (Wait for it!)
        bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
        if (success) {
          await FlutterBackground.enableBackgroundExecution();
          // added emojis for better visibility in the logs
          print("✅ Android Background Service Started");
        }
      } catch (e) {
        print("⚠️ Background Service Error: $e");
      }
    }
    final settingsBox = Hive.box('settings_box');
    bool isStrict = settingsBox.get('isStrictMode', defaultValue: false);

    setState(() {
      isRunning = true;
      isPaused = false;
    });

    _manageWhiteNoise(play: true);

    final now = DateTime.now();
    DateTime targetTime;

    if (_endTime == null) {
      totalSeconds = (selectedMinutes * 60).toInt();
      remainingSeconds = totalSeconds;
      targetTime = now.add(Duration(seconds: totalSeconds));
      _endTime = targetTime;
    } else {
      // If resuming, schedule for remaining seconds
      targetTime = now.add(Duration(seconds: remainingSeconds));
      _endTime = targetTime;
    }

    //String formattedTime = "${targetTime.hour}:${targetTime.minute.toString().padLeft(2, '0')}";

    // Schedule the finish notification
    NotificationService().scheduleNotification(
      id: 0,
      title: isBreakMode ? "Break Over!" : "Focus Complete!",
      body: isBreakMode
          ? "Ready to focus again?"
          : "Focus Session Over! Take a Break!",
      seconds: remainingSeconds,
    );

    // STRICT MODE & WAKELOCK LOGIC
    if (!isBreakMode && isStrict) {
      WakelockPlus.enable();
    }

    // If it's Break Mode, start the quotes
    if (isBreakMode) {
      _startQuoteCycle();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now();
        remainingSeconds = (_endTime!.difference(now).inMilliseconds / 1000)
            .ceil();

        if (remainingSeconds <= 0) {
          _finishTimer();
        }
      });
    });
  }

  void pauseTimer() async{
    _triggerHaptic();
    timer?.cancel();
    _quoteTimer?.cancel();
    // Disable wakelock
    WakelockPlus.disable();
    // Cancel notification
    NotificationService().cancelNotification(888);
    if (Platform.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (e) { print(e); }
    }
    setState(() {
      isRunning = false;
      isPaused = true;
    });
    _manageWhiteNoise(play: false);
  }

  void stopTimer({bool cancelNotify = true}) async{
    _triggerHaptic(heavy: true);
    if (Platform.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (e) { print(e); }
    }
    timer?.cancel();
    _quoteTimer?.cancel();
    // Disable wakelock
    WakelockPlus.disable();
    // Cancel notification
    if (cancelNotify) {
      NotificationService().cancelNotification(888);
    }
    setState(() {
      isRunning = false;
      isPaused = false;
      remainingSeconds = 0;
      _endTime = null;
    });
    _manageWhiteNoise(play: false);
  }

  // SAVES DATA TO HIVE
  void _saveSessionToDatabase() {
    final sessionBox = Hive.box<Session>('session_box');

    // Calculate minutes from the TOTAL duration set at the start
    int minutesSaved = (totalSeconds / 60).round();

    // Safety check
    if (minutesSaved <= 0) return;

    sessionBox.add(
      Session(
        date: DateTime.now(),
        durationMinutes: minutesSaved,
        isBreak: isBreakMode,
      ),
    );

    print(
      "✅ Session Saved: $minutesSaved min (${isBreakMode ? 'Break' : 'Focus'})",
    );
  }

  // Called when timer hits 0 naturally
  void _finishTimer() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBackground.disableBackgroundExecution();
      } catch (e) { print(e); }
    }

    _saveSessionToDatabase();
    _triggerHaptic(success: true);
    _playCompletionSound();
    _manageWhiteNoise(play: false);
    stopTimer(cancelNotify: false);

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

    print("📲 LIFECYCLE CHANGED: $state"); // DEBUG PRINT

    // PAUSED Logic
    if (state == AppLifecycleState.paused) {
      if (isRunning && !isBreakMode) {
        if (isStrict) {
          // Send Instant Warning
          NotificationService().showInstantNotification(
            id: 1, // Different ID so it doesn't override the timer
            title: "⚠️ FOCUS SESSION FAILED",
            body:
                "You left the app. Session was cancelled and will not be counted towards your Stats.",
          );

          // Fail the session
          stopTimer(cancelNotify: true);
          _wasStrictlyInterrupted = true;
        }
      }
    }

    // RESUMED Logic
    if (state == AppLifecycleState.resumed && _wasStrictlyInterrupted) {
      NotificationService().cancelNotification(888);
      if (_wasStrictlyInterrupted) {
        _wasStrictlyInterrupted = false;
        bool isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
        Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
        Color textColor = isDarkMode ? Colors.white : Colors.black;

        showDialog(
          // dialog code
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: bgColor,
            title: Text("Focus Broken 😔", style: TextStyle(color: textColor)),
            content: Text(
              "Strict Mode is active. You left the app, so the timer was reset to keep you accountable.",
              style: TextStyle(color: textColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("I understand"),
              ),
            ],
          ),
        );
      } else if (isRunning && _endTime != null) {
        final now = DateTime.now();
        // Did the timer finish while we were sleeping?
        if (now.isAfter(_endTime!)) {
          // if yes, Trigger the finish logic immediately.
          // This will Stop the Noise, Play the Ding, and Save Data.
          _finishTimer();
        } else {
          // if no, still time left. Sync the UI.
          setState(() {
            remainingSeconds = _endTime!.difference(now).inSeconds;
          });
        }
      }
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

        // 1. Define the Green Gradient (Break Mode)
        final Gradient breakGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode 
              ? [const Color(0xFF145A32), const Color(0xFF0B1E15)] // Dark Forest
              : [Colors.green[400]!, Colors.green[50]!], // Soft Mint
        );

        // 2. Define the Transparent Gradient (Focus Mode)
        // We must use a Gradient here too, or AnimatedContainer won't fade smoothly!
        const Gradient focusGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
        );

        // 3. Select the decoration based on mode
        final BoxDecoration bgDecoration = BoxDecoration(
          gradient: isBreakMode ? breakGradient : focusGradient,
        );

        // Palette Logic (Kept exactly the same)
        Color foregroundColor = isDarkMode ? Colors.blue[100]! : Colors.white;
        Color timerRingColor = isDarkMode ? Colors.blue[200]! : Colors.white;
        Color timerTrackColor = isDarkMode
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.3);

        Color btnColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white; 
        Color btnTextColor = isDarkMode ? Colors.blue[100]! : Colors.blue;

        if (isBreakMode && !isDarkMode) btnTextColor = Colors.green;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          decoration: bgDecoration, // Now smooths between two gradients
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 60, bottom: 150),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.white.withValues(alpha: 0.3),
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
                              ? (remainingSeconds / totalSeconds).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 1.0,
                          strokeWidth: 15,
                          // Dynamic Colors applied here
                          color: isPaused
                              ? Colors.orangeAccent
                              : timerRingColor,
                          backgroundColor: timerTrackColor,
                        ),
                      ),
                      Text(
                        getFormattedTime(),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor, // Soft Blue in Dark Mode
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
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),

                  // 4. SLIDER & CONTROLS
                  if (!isRunning && !isPaused)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Text(
                            isBreakMode ? "Rest Duration" : "Focus Duration",
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (selectedMinutes > 1) selectedMinutes--;
                                  });
                                },
                                icon: Icon(
                                  Icons.remove_circle_outline,
                                  color: foregroundColor,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 1),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    double maxVal = isBreakMode ? 30 : 120;
                                    if (selectedMinutes < maxVal) {
                                      selectedMinutes++;
                                    }
                                  });
                                },
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: foregroundColor,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: selectedMinutes,
                            min: 1,
                            max: isBreakMode ? 30 : 120,
                            divisions: isBreakMode ? 29 : 119,
                            // Slider colors adapted to the theme
                            activeColor: foregroundColor,
                            inactiveColor: foregroundColor.withValues(
                              alpha: 0.3,
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                selectedMinutes = newValue.roundToDouble();
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 5. ACTION BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          foregroundColor: isPaused
                              ? Colors.orange
                              : btnTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                        ),
                        onPressed: () {
                          if (isRunning) {
                            pauseTimer();
                          } else {
                            startTimer();
                          }
                        },
                        child: Text(
                          isRunning
                              ? "PAUSE"
                              : (isPaused
                                    ? "RESUME"
                                    : (isBreakMode
                                          ? "START BREAK"
                                          : "START FOCUS")),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isRunning || isPaused) ...[
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                          ),
                          onPressed: stopTimer,
                          child: const Text(
                            "STOP",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated Helper for Mode Buttons to use the new colors
  Widget _buildModeBtn(String title, bool isBreak, bool isDarkMode) {
    bool isActive = (isBreakMode == isBreak);
    bool isDisabled = isRunning || isPaused;
    // Active Text: Green (Break) or Blue (Focus)
    Color activeTextColor = isBreak ? Colors.green : Colors.blue;
    // Inactive Text: Grey (Dark Mode) or White (Light Mode)
    Color inactiveTextColor = isDarkMode ? Colors.grey : Colors.white;

    return GestureDetector(
      onTap: () => _toggleMode(isBreak),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDarkMode ? const Color(0xFF1E1E1E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? activeTextColor : inactiveTextColor,
            ),
          ),
        ),
      ),
    );
  }
}
