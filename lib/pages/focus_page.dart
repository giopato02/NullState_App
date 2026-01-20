import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> with WidgetsBindingObserver {
  // --Variables--
  double selectedMinutes = 25;
  
  // State Flags
  bool isRunning = false;
  bool isPaused = false;

  DateTime? _endTime; 
  int remainingSeconds = 0;
  Timer? timer;
  int totalSeconds = 0;

  bool _wasStrictlyInterrupted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    super.dispose();
  }

  // --Functions--
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
    } 
    else {
        _endTime = DateTime.now().add(Duration(seconds: remainingSeconds));
    }

    if (isStrict) {
      WakelockPlus.enable();
    }

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now();
        
        // FIX OF BUG: Use ceil() to prevent the "2 second jump"
        // Before this the timer used to decrement by 2 on the UI when started
        // This was Because code takes a few milliseconds to run, 
        // and the tick actually happens at 1.01 seconds.
        // So 30.00 - 1.01 = 28.99 seconds left. This gets rounded down to 28
        remainingSeconds = (_endTime!.difference(now).inMilliseconds / 1000).ceil();

        if (remainingSeconds <= 0) {
          stopTimer(); 
        }
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    WakelockPlus.disable(); // Save battery while paused

    setState(() {
      isRunning = false;
      isPaused = true;
      // do NOT clear _endTime here, because we need it to know we are "mid-session"
      // But we DO need to make sure remainingSeconds is accurate for the UI
    });
  }

  void stopTimer() {
    timer?.cancel();
    WakelockPlus.disable();
    
    setState(() {
      isRunning = false;
      isPaused = false;
      remainingSeconds = 0;
      _endTime = null; // Nuke _endTime so next start is fresh
    });
  }

  // LIFECYCLE OBSERVER
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final settingsBox = Hive.box('settings_box');
    bool isStrict = settingsBox.get('isStrictMode', defaultValue: false);

    if (state == AppLifecycleState.paused) {
      // Punish if Strict Mode is ON and session is actively RUNNING
      // (don't punish if they are already paused)
      if (isStrict && isRunning) {
        stopTimer();
        _wasStrictlyInterrupted = true;
      }
    }

    if (state == AppLifecycleState.resumed) {
      if (_wasStrictlyInterrupted) {
        _wasStrictlyInterrupted = false;
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Text("Focus Broken 😔"),
            content: const Text("Strict Mode is active. You left the app, so the timer was reset."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text("I understand")
              )
            ],
          )
        );
      }
      // If we come back and it's running, update UI
      else if (isRunning && _endTime != null) {
        setState(() {
           remainingSeconds = _endTime!.difference(DateTime.now()).inSeconds;
        });
      }
    }
  }

  String getFormattedTime() {
    // If stopped, show slider value
    if (!isRunning && !isPaused) {
      return "${selectedMinutes.toInt()}:00";
    }
    
    // If running OR paused, show remainingSeconds
    if (remainingSeconds < 0) return "00:00";

    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TIMER CIRCLE
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
                  color: isPaused ? Colors.orangeAccent : Colors.white, // Orange when paused!
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
          
          const SizedBox(height: 40),

          // SLIDER (Only visible when completely STOPPED)
          if (!isRunning && !isPaused)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text("Adjust Duration", style: TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes > 1) selectedMinutes--;
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 1),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes < 120) selectedMinutes++;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                  Slider(
                    value: selectedMinutes,
                    min: 1,
                    max: 120,
                    // FIX OF BUG: Force the slider to snap to 119 steps (1 to 120)
                    // So the user can ONLY pick minutes instead of seconds
                    divisions: 119, 
                    
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                    onChanged: (newValue) {
                      setState(() {
                        // Extra safety: round it to nearest whole number
                        selectedMinutes = newValue.roundToDouble(); 
                      });
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // BUTTONS ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // MAIN ACTION BUTTON (Start / Pause / Resume)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isPaused ? Colors.orange : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
                onPressed: () {
                  if (isRunning) {
                    pauseTimer();
                  } else {
                    startTimer(); // Works for both Start and Resume
                  }
                },
                child: Text(
                  isRunning ? "PAUSE" : (isPaused ? "RESUME" : "START FOCUS"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              // STOP BUTTON (Only visible when Active)
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
    );
  }
}