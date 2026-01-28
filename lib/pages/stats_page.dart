import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nullstate/models/session.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // Chart Colors
  final Color focusColor = const Color.fromARGB(255, 0, 84, 228);
  final Color breakColor = const Color.fromARGB(255, 60, 220, 68);

  // Tracks which week the user is currently viewing
  DateTime _selectedDate = DateTime.now();

  // To handle the "Week" vs "Month" view later (defaulting to Week for now)
  String currentView = 'Week';

  @override
  Widget build(BuildContext context) {
    // Listen to the session_box. Anytime a session is added, the chart updates!
    return ValueListenableBuilder(
      valueListenable: Hive.box<Session>('session_box').listenable(),
      builder: (context, Box<Session> box, _) {
        // 1. Calculate the Data
        // Pass _selectedDate to all functions so they calculate for the correct week
        final weeklyData = _processWeeklyData(box, _selectedDate);
        final totalFocus = _calculateTotalMinutes(
          box,
          isBreak: false,
          referenceDate: _selectedDate,
        );
        final totalBreak = _calculateTotalMinutes(
          box,
          isBreak: true,
          referenceDate: _selectedDate,
        );
        final weekRange = _getWeekRange(
          _selectedDate,
        ); // Gets for example: Jan 1 - Jan 7

        return Scaffold(
          backgroundColor:
              Colors.transparent, // Uses the gradient from HomePage
          appBar: AppBar(
            elevation: 0,
            centerTitle: true,
            // Bug FIX: white background on the AppBar
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            forceMaterialTransparency: true,

            // 1. INFO ICON IN TITLE
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Statistics",
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showInfoDialog,
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
            actions: [
              // DEBUG BUTTON: when clicked, fills chart with fake data
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white54),
                onPressed: () => _generateMockData(box),
                tooltip: "Generate Fake Data",
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Summary Cards (Total Time)
                Row(
                  children: [
                    _buildSummaryCard(
                      "Total Focus Time",
                      totalFocus,
                      focusColor,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      "Total Break Time",
                      totalBreak,
                      breakColor,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 3. DATE NAVIGATION HEADER
                Text(
                  "Performance • ${_selectedDate.year}", // Updates with the year
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 2), // Small gap between label and date
                // Date & Arrows Container
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // The Date Text
                    Text(
                      weekRange,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Back Arrow
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 30,
                      ),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(), // Removes default padding
                      visualDensity:
                          VisualDensity.compact, // Reduces extra whitespace
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.subtract(
                            const Duration(days: 7),
                          );
                        });
                      },
                    ),

                    const SizedBox(width: 1),

                    // Forward Arrow
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 30,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 7),
                          );
                        });
                      },
                    ),
                    // pushes streak icon to the right
                    const Spacer(),

                    // calculates the streak inside the build
                    FlickeringFire(streak: _calculateStreak(box)),
                  ],
                ),

                // Spacer to prevent collision with Chart
                const SizedBox(height: 15),

                // 4. The Bar Chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.only(
                      right: 16,
                      top: 24,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(
                        alpha: 0.3,
                      ), // Semi-transparent background
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getMaxY(weeklyData), // Dynamic height
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBorderRadius: BorderRadius.circular(8),
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.round()} min',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          // Y-AXIS (Left)
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 55, 
                              interval: 30,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();

                                // Only show labels for multiples of 20
                                if (value % 30 == 0) {
                                  int totalMins = value.toInt();
                                  int hours = totalMins ~/ 60;
                                  int minutes = totalMins % 60;

                                  String text = "";
                                  if (hours > 0 && minutes > 0) {
                                    text = "${hours}h ${minutes}m"; // "1h 20m"
                                  } else if (hours > 0) {
                                    text = "${hours}h"; // "1h"
                                  } else {
                                    text = "${minutes}m"; // "20m"
                                  }

                                  return Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.right,
                                  );
                                }
                                return const SizedBox();
                              },
                            ),
                          ),
                          // X-AXIS (Bottom)
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                                if (value.toInt() >= 0 &&
                                    value.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      days[value.toInt()],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              reservedSize: 30,
                            ),
                          ),
                          // Hide other axis labels for a clean look
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 30, // Grid line every hour
                          getDrawingHorizontalLine: (value) =>
                              FlLine(color: Colors.white10, strokeWidth: 2),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: _buildBarGroups(weeklyData),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. DAILY AVERAGE (Footer)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.show_chart,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Daily Average:  ${(totalFocus / 7).round()}m",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Push everything slightly up from the very bottom edge
                const SizedBox(height: 40),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI HELPERS---------------- //

  void _showInfoDialog() {
    bool isDarkMode = Hive.box(
      'settings_box',
    ).get('isDarkMode', defaultValue: false);

    // Define colors based on theme
    Color bgColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    Color textColor = isDarkMode ? Colors.white : Colors.black87;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text(
          "Tracking Rules",
          style: TextStyle(color: textColor),
        ),
        content: Text(
          "1. Only FULLY COMPLETED sessions are recorded.\n"
          "2. If you stop a timer early, it will NOT count towards your stats.\n"
          "3. Strict Mode failures are not recorded.",
          style: TextStyle(color: textColor.withValues(alpha: 0.8)),
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

  String _getWeekRange(DateTime date) {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));

    final dateFormat = DateFormat('MMM dd');
    return "${dateFormat.format(start)} - ${dateFormat.format(end)}";
  }

  // Builds the small cards at the top
  Widget _buildSummaryCard(String title, int totalMinutes, Color color) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final timeString = hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              timeString,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Constructs the bars for the chart
  List<BarChartGroupData> _buildBarGroups(List<Map<String, int>> data) {
    return List.generate(7, (index) {
      final focus = data[index]['focus']!.toDouble();
      final breakTime = data[index]['break']!.toDouble();
      final total = focus + breakTime;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: total == 0
                ? 1
                : total, // Min height of 1 so you can see empty days
            width: 16,
            color: Colors.transparent, // The background of the bar is invisible
            rodStackItems: [
              // The Blue Part (Focus)
              BarChartRodStackItem(0, focus, focusColor),
              // The Green Part (Break) - stacks on top of Focus
              BarChartRodStackItem(focus, focus + breakTime, breakColor),
            ],
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  // Calculates the max height of the chart dynamically
  double _getMaxY(List<Map<String, int>> data) {
    double maxVal = 0;
    for (var day in data) {
      double total = (day['focus']! + day['break']!).toDouble();
      if (total > maxVal) maxVal = total;
    }
    return maxVal == 0 ? 60 : maxVal * 1.2; // Add 20% headroom
  }

  // ---------------- DATA LOGIC ---------------- //

  int _calculateTotalMinutes(
    Box<Session> box, {
    required bool isBreak,
    required DateTime referenceDate,
  }) {
    // 1. Determine start/end of the requested week
    final startOfWeek = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    // Normalize to midnight to avoid hour mismatches
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    int total = 0;
    for (var session in box.values) {
      if (session.date.isAfter(start) && session.date.isBefore(end)) {
        if (session.isBreak == isBreak) {
          total += session.durationMinutes;
        }
      }
    }
    return total;
  }

  List<Map<String, int>> _processWeeklyData(
    Box<Session> box,
    DateTime referenceDate,
  ) {
    List<Map<String, int>> weekData = List.generate(
      7,
      (_) => {'focus': 0, 'break': 0},
    );

    final startOfWeek = referenceDate.subtract(
      Duration(days: referenceDate.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    // Normalize
    final start = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    for (var session in box.values) {
      if (session.date.isAfter(start) && session.date.isBefore(end)) {
        int dayIndex = session.date.weekday - 1;
        if (session.isBreak) {
          weekData[dayIndex]['break'] =
              weekData[dayIndex]['break']! + session.durationMinutes;
        } else {
          weekData[dayIndex]['focus'] =
              weekData[dayIndex]['focus']! + session.durationMinutes;
        }
      }
    }
    return weekData;
  }

  // STREAK LOGIC
  int _calculateStreak(Box<Session> box) {
    // 1. Get all unique dates where user FOCUSED
    final focusDates = <String>{};
    for (var session in box.values) {
      if (!session.isBreak && session.durationMinutes > 0) {
        // Format as yyyy-MM-dd to ignore time
        focusDates.add(DateFormat('yyyy-MM-dd').format(session.date));
      }
    }

    // 2. Count backwards from Today
    int streak = 0;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(today.subtract(const Duration(days: 1)));

    // If we focused today, start counting from today.
    // If not, check if we focused yesterday (streak is still alive).
    DateTime currentCheck;

    if (focusDates.contains(todayStr)) {
      streak++;
      currentCheck = today.subtract(const Duration(days: 1));
    } else if (focusDates.contains(yesterdayStr)) {
      // Streak is alive based on yesterday, but we haven't done today yet
      currentCheck = today.subtract(const Duration(days: 1));
    } else {
      // No focus today OR yesterday? Streak is dead. :(
      return 0;
    }

    // 3. Loop backwards
    while (true) {
      final checkStr = DateFormat('yyyy-MM-dd').format(currentCheck);
      if (focusDates.contains(checkStr)) {
        streak++;
        currentCheck = currentCheck.subtract(const Duration(days: 1));
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  // ---------------- MOCK DATA ---------------- //
  void _generateMockData(Box<Session> box) async {
    // Clear old data first
    await box.clear();

    final r = Random();

    // 1. Calculate the start of the CURRENTLY VIEWED week
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    // 2. Generate sessions relative to that start date
    for (int i = 0; i < 15; i++) {
      // Add random days (0-6) to the start of the week
      final date = startOfWeek.add(
        Duration(days: r.nextInt(7), hours: r.nextInt(20)),
      );

      final isBreak = r.nextBool();
      final duration = isBreak ? r.nextInt(15) + 5 : r.nextInt(45) + 15;

      await box.add(
        Session(date: date, durationMinutes: duration, isBreak: isBreak),
      );
    }

    // 3. Force the UI to refresh to show the new bars
    setState(() {});
  }
}

// ---------------- ANIMATED STREAK ICON ---------------- //
class FlickeringFire extends StatefulWidget {
  final int streak;
  const FlickeringFire({super.key, required this.streak});

  @override
  State<FlickeringFire> createState() => _FlickeringFireState();
}

class _FlickeringFireState extends State<FlickeringFire>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // Pulse effect

    _opacityAnim = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If streak is 0, show Cold static icon
    if (widget.streak == 0) {
      return Row(
        children: [
          Icon(
            Icons.local_fire_department_sharp,
            color: Colors.grey.withValues(alpha: 0.3),
            size: 28,
          ),
          const SizedBox(width: 4),
          Text(
            "0",
            style: TextStyle(
              color: Colors.grey.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      );
    }

    // If streak > 0, show Animated Fire
    return Row(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Icon(
                Icons.local_fire_department,
                color: Colors.orangeAccent, // Fire color
                size: 30 + (_controller.value * 2), // Subtle size pulse
                shadows: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.6),
                    blurRadius: 10 + (_controller.value * 10), // Glow effect
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 6),
        Text(
          "${widget.streak}",
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
