import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
          'focus_channel_v2',
          'Focus Timer',
          channelDescription: 'Notifications for Focus Timer',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }

  Future<void> init() async {
    // 1. Initialize Timezone (Needed for scheduled notifications)
    tz.initializeTimeZones();

    // 2. Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

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

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // SCHEDULER: Triggers when the timer SHOULD end
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int seconds,
  }) async {
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      // Calculate the exact time in the future
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_channel_v2', // Channel ID
          'Focus Timer', // Channel Name
          channelDescription: 'Notifications for Focus Timer',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          // add a custom sound here
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // CANCEL: If user presses "Stop" or "Pause"
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // CANCEL ALL
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
