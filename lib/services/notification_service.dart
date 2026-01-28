import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezone (Needed for scheduled notifications)
    tz.initializeTimeZones();

    try {
      // This line grabs the phone's actual timezone (e.g. "Asia/Tbilisi")
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if something fails, but print the error
      print("Could not set local timezone: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 2. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Settings (Fixes the "Invalid Argument" error)
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    // 4. General Settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    // 5. Initialize Plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle what happens when user taps the notification
      },
    );

    // This forces the "Focus Timer" category to appear in Android Settings immediately.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'focus_channel_v6', // New ID
      'Focus Timer',
      description: 'Notifications for Focus Timer',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ding'),
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Create the channel in the system
      await androidImplementation.createNotificationChannel(channel);
      
      // Request Permissions
      await androidImplementation.requestNotificationsPermission();
    }
  }
// // SCHEDULER
//   Future<void> scheduleNotification({
//     required int id,
//     required String title,
//     required String body,
//     required int seconds,
//   }) async {
//     final scheduledTime = tz.TZDateTime.now(
//       tz.local,
//     ).add(Duration(seconds: seconds));

//     try {
//       await flutterLocalNotificationsPlugin.zonedSchedule(
//         id,
//         title,
//         body,
//         scheduledTime,
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'focus_channel_v6', // Must match the ID above
//             'Focus Timer',
//             channelDescription: 'Notifications for Focus Timer',
//             importance: Importance.max,
//             priority: Priority.high,
//             playSound: true,
//             sound: RawResourceAndroidNotificationSound('ding'),
//           ),
//         ),
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       );
//     } catch (e) {
//       print("⚠️ Notification Error: $e");
//     }
//   }

// SCHEDULER
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    // 1. Get NOW in Local Time
    final now = tz.TZDateTime.now(tz.local);
    
    // 2. Add duration to get Future Time
    final scheduledTime = now.add(Duration(seconds: seconds));

    print("🕒 Scheduling Alarm for Local Time: $scheduledTime"); // Debug Print

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'focus_channel_v6', // Must match the init channel
            'Focus Timer',
            channelDescription: 'Notifications for Focus Timer',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('ding'),
            // CRITICAL: Alarm Clock Mode to bypass battery restrictions
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
      );
      print("✅ Notification Scheduled Successfully");
    } catch (e) {
      print("⚠️ Notification Error: $e");
    }
  }

  // INSTANT
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_channel_v6', // Must match the ID above
          'Focus Timer', 
          channelDescription: 'Notifications for Focus Timer',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('ding'),
        ),
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

