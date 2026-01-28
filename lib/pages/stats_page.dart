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
        final totalFocus = _calculateTotalMinutes(box, isBreak: false, referenceDate: _selectedDate);
        final totalBreak = _calculateTotalMinutes(box, isBreak: true, referenceDate: _selectedDate);
        final weekRange = _getWeekRange(_selectedDate); // Gets for example: Jan 1 - Jan 7

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

            // 1. ℹ️ INFO ICON IN TITLE
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Statistics", style: TextStyle(fontSize: 30, color: Colors.white)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showInfoDialog,
                  child: Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.6), size: 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Performance",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    // ARROWS AND DATE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            weekRange,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 14, // Smaller font to fit arrows
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // Don't allow going into future weeks ADD HERE.
                              setState(() {
                                _selectedDate = _selectedDate.add(const Duration(days: 7));
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

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
                              reservedSize:
                                  55, // Increased slightly to fit "1h 20m"
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Tracking Rules", style: TextStyle(color: Colors.white)),
        content: const Text(
          "1. Only FULLY COMPLETED sessions are recorded.\n"
          "2. If you stop a timer early, it will NOT count towards your stats.\n"
          "3. Strict Mode failures are not recorded.",
          style: TextStyle(color: Colors.white70),
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

  int _calculateTotalMinutes(Box<Session> box, {required bool isBreak, required DateTime referenceDate}) {
    // 1. Determine start/end of the requested week
    final startOfWeek = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    // Normalize to midnight to avoid hour mismatches
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
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

  List<Map<String, int>> _processWeeklyData(Box<Session> box, DateTime referenceDate) {
    List<Map<String, int>> weekData = List.generate(7, (_) => {'focus': 0, 'break': 0});
    
    final startOfWeek = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    // Normalize
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day);

    for (var session in box.values) {
      if (session.date.isAfter(start) && session.date.isBefore(end)) {
        int dayIndex = session.date.weekday - 1;
        if (session.isBreak) {
          weekData[dayIndex]['break'] = weekData[dayIndex]['break']! + session.durationMinutes;
        } else {
          weekData[dayIndex]['focus'] = weekData[dayIndex]['focus']! + session.durationMinutes;
        }
      }
    }
    return weekData;
  }

  // ---------------- MOCK DATA ---------------- //
  void _generateMockData(Box<Session> box) async {
    // Clear old data first
    await box.clear();

    final r = Random();
    
    // 1. Calculate the start of the CURRENTLY VIEWED week
    final startOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

    // 2. Generate sessions relative to that start date
    for (int i = 0; i < 15; i++) {
      // Add random days (0-6) to the start of the week
      final date = startOfWeek.add(Duration(days: r.nextInt(7), hours: r.nextInt(20)));
      
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
