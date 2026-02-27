import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;


class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId   = 'af_screen_reminders';
  static const _channelName = 'Measurement Reminders';
  static const _notifId     = 1;
  static bool _initialised  = false;

  // Initialise once at app startup
  static Future<void> init() async {
    if (_initialised) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission:  false,
      requestBadgePermission:  false,
      requestSoundPermission:  false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _initialised = true;
  }

  // Request permission (call before scheduling) 
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true; // other platforms assume granted
  }

  // Schedule a daily reminder at the given time 
  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await cancelReminder(); // cancel existing before rescheduling

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily reminders to take your AF measurement',
      importance: Importance.high,
      priority:   Priority.high,
      icon:       '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      _notifId,
      'Time for your AF measurement',
      'Take a quick reading to keep track of your heart rhythm.',
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  // Cancel the scheduled reminder
  static Future<void> cancelReminder() async {
    await _plugin.cancel(_notifId);
  }

  // Check if a reminder is currently scheduled
  static Future<bool> isScheduled() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((n) => n.id == _notifId);
  }
}