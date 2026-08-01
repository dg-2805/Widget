import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _android;
  Future<void>? _scheduleTask;
  bool _initialized = false;

  static const _channel = AndroidNotificationDetails(
    'twilight_hearts',
    'Twilight hearts',
    channelDescription: 'Morning, 11:11, and midnight reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _morningMessage = 'Good morning ❤️';
  static const _elevenElevenMessage = "It's 11:11.\nMake a wish.";
  static const _midnightMessage = 'Another twilight together.';

  Future<void> init() async {
    if (_initialized) {
      await _scheduleReminders();
      return;
    }

    tzdata.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _plugin.initialize(settings);

    _android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
    await _android?.requestNotificationsPermission();
    final canScheduleExactly =
        await _android?.canScheduleExactNotifications() ?? true;
    if (!canScheduleExactly) {
      await _android?.requestExactAlarmsPermission();
    }

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _scheduleReminders();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_initialized && state == AppLifecycleState.resumed) {
      unawaited(_scheduleReminders());
    }
  }

  Future<void> _scheduleReminders() {
    final activeTask = _scheduleTask;
    if (activeTask != null) return activeTask;

    final task = _replaceSchedules();
    _scheduleTask = task;
    return task.whenComplete(() {
      _scheduleTask = null;
    });
  }

  Future<void> _replaceSchedules() async {
    // This clears every legacy schedule before adding the requested reminders,
    // reminders, preventing duplicates after an app update or app resume.
    await _plugin.cancelAll();

    final exact = await _android?.canScheduleExactNotifications() ?? true;
    await _scheduleDaily(id: 700, hour: 8, minute: 0, message: _morningMessage, exact: exact);
    await _scheduleDaily(id: 1111, hour: 11, minute: 11, message: _elevenElevenMessage, exact: exact);
    await _scheduleDaily(id: 0, hour: 0, minute: 0, message: _midnightMessage, exact: exact);
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String message,
    required bool exact,
  }) {
    return _plugin.zonedSchedule(
      id,
      'Us',
      message,
      _nextInstanceOf(hour, minute),
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
