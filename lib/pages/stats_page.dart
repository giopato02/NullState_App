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
  
  // To handle the "Week" vs "Month" view later (defaulting to Week for now)
  String currentView = 'Week';

  @override
  Widget build(BuildContext context) {
    // Listen to the session_box. Anytime a session is added, the chart updates!
    return ValueListenableBuilder(
      valueListenable: Hive.box<Session>('session_box').listenable(),
      builder: (context, Box<Session> box, _) {
        
        // 1. Calculate the Data
        final weeklyData = _processWeeklyData(box);
        final totalFocus = _calculateTotalMinutes(box, isBreak: false);
        final totalBreak = _calculateTotalMinutes(box, isBreak: true);
        final weekRange = _getWeekRange(); // Gets Jan 1 - Jan 7

        return Scaffold(
          backgroundColor: Colors.transparent, // Uses the gradient from HomePage
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Statistics", style: TextStyle(color: Colors.white)),
            centerTitle: true,
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
                    _buildSummaryCard("Total Focus Time", totalFocus, focusColor),
                    const SizedBox(width: 12),
                    _buildSummaryCard("Total Break Time", totalBreak, breakColor),
                  ],
                ),
                const SizedBox(height: 30),

                // 3. Chart Header
                const Text(
                  "This Week",
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 20),

                // 4. The Bar Chart
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3), // Semi-transparent background
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
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const SizedBox();
                                // Show hours every 60 mins
                                if (value % 60 == 0) {
                                  return Text(
                                    "${(value / 60).toInt()}h",
                                    style: const TextStyle(color: Colors.white54, fontSize: 10),
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
                                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= 0 && value.toInt() < days.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      days[value.toInt()],
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  );
                                }
                                return const SizedBox();
                              },
                              reservedSize: 30,
                            ),
                          ),
                          // Hide other axis labels for a clean look
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 60, // Grid line every hour
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white10,
                            strokeWidth: 1,
                          ),
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
            toY: total == 0 ? 1 : total, // Min height of 1 so you can see empty days
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

  // 1. Calculate Total Minutes (for the summary cards)
  int _calculateTotalMinutes(Box<Session> box, {required bool isBreak}) {
    int total = 0;
    for (var session in box.values) {
      if (session.isBreak == isBreak) {
        total += session.durationMinutes;
      }
    }
    return total;
  }

  // 2. Group Data by Day of Week (Monday=0, Sunday=6)
  List<Map<String, int>> _processWeeklyData(Box<Session> box) {
    // Create empty list for 7 days
    List<Map<String, int>> weekData = List.generate(7, (_) => {'focus': 0, 'break': 0});
    
    final now = DateTime.now();
    // Find the Monday of this week
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    // Find next Monday
    final startOfNextWeek = startOfWeek.add(const Duration(days: 7));

    for (var session in box.values) {
      // Is this session inside the current week window?
      if (session.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
          session.date.isBefore(startOfNextWeek)) {
        
        // Convert weekday (1=Mon ... 7=Sun) to list index (0...6)
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
    // Clear old data first so we don't just keep piling up
    await box.clear();

    final r = Random();
    final now = DateTime.now();
    
    // Create 15 fake sessions
    for (int i = 0; i < 15; i++) {
      // Random day in the last 7 days
      final date = now.subtract(Duration(days: r.nextInt(7)));
      final isBreak = r.nextBool(); // 50/50 chance of break vs focus
      final duration = isBreak ? r.nextInt(15) + 5 : r.nextInt(45) + 15;
      
      await box.add(Session(
        date: date,
        durationMinutes: duration,
        isBreak: isBreak,
      ));
    }
  }
}