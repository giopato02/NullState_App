import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
// Variables
  double selectedMinutes = 25;
  bool isRunning = false;

  int remainingSeconds = 0;
  Timer? timer;
  int totalSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Access the box opened in main.dart
    final settingsBox = Hive.box('settings_box');
    
    // Get the saved value (Default: 25)
    double savedDuration = settingsBox.get('focusDuration', defaultValue: 25.0);
    
    // Update the variable that controls the slider and text
    setState(() {
      selectedMinutes = savedDuration;
    });
  }

// Functions for the Timer Logic
void startTimer() {
    setState(() {
      isRunning = true;
      // Convert minutes to seconds
      remainingSeconds = (selectedMinutes * 60).toInt();
      totalSeconds = remainingSeconds;
    });

    // Start the Ticker (Run this code every 1 second)
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          stopTimer(); 
          // (play a sound here later)
          }
        }
      );
    }
  );
}

  void stopTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
      // don't reset 'selectedMinutes' so the user remembers their last choice
    }
  );
}
  
  // Helper to format "65 seconds" into "01:05"
  String getFormattedTime() {
    // If not running, just show the slider value
    if (!isRunning) {
      return "${selectedMinutes.toInt()}:00";
    }
    
    // If running, do the math
    int minutes = remainingSeconds ~/ 60; // Integer division
    int seconds = remainingSeconds % 60;  // Remainder
    
    // .padLeft(2, '0') adds a zero if needed (e.g., "5" becomes "05")
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

//UI
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Layer 1: Draining Circle
              SizedBox(
                width: 300,
                height: 300,
                child: CircularProgressIndicator(
                  // remaining/total = percentage (0.0 to 1.0)
                  value: isRunning ? (remainingSeconds / totalSeconds) : 1.0,
                  strokeWidth: 15,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.3,),
                ),
              ),

              // Layer 2: Text
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

          // 3. Duration Adjusting (Only visible when NOT running)
          if (!isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const Text(
                    "Adjust Duration",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes > 1) {
                              selectedMinutes--;
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      // Spacing
                      const SizedBox(width: 1),

                      // Plus Button
                      IconButton(
                        onPressed: () {
                          setState(() {
                            if (selectedMinutes < 120) {
                              selectedMinutes++;
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),

                  Slider(
                    value: selectedMinutes,
                    min: 1,
                    max: 120,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                    onChanged: (newValue) {
                      setState(() {
                        selectedMinutes = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // 4. The Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
            onPressed: () {
              if (isRunning) {
                stopTimer();
              } else {
                startTimer();
              }
            },
            child: Text(
              isRunning ? "STOP" : "START FOCUS",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
