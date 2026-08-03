import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService with WidgetsBindingObserver {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  AndroidFlutterLocalNotificationsPlugin? _android;
  Future<void>? _scheduleTask;
  bool _initialized = false;

  static const _diagnosticLogKey = 'notification_diagnostic_log';
  static const _lastInitErrorKey = 'notification_last_init_error';
  static const _scheduleDetailsKey = 'notification_schedule_details';

  static const _channel = AndroidNotificationDetails(
    'twilight_hearts',
    'Twilight hearts',
    channelDescription: '11:11, 23:11, and monthly together reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _channelDefinition = AndroidNotificationChannel(
    'twilight_hearts',
    'Twilight hearts',
    description: '11:11, 23:11, and monthly together reminders',
    importance: Importance.high,
  );

  static const _elevenElevenMessage = "11:11.\nMake a wish.";
  static const _nightMessage = "11:11 :))\n Thinking of you.";
  static const _monthlyMessage = 'another month togetherrrrr';

  Future<void> showMissYouFromPartner() async {
    if (!_initialized) return;
    await _plugin.show(
      9001,
      'Us',
      'Someone is missing you right now. ♥',
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showHugRequestFromPartner() async {
    if (!_initialized) return;
    await _plugin.show(
      9002,
      'Us',
      'needs a hug',
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showRemoteMessage({required String type}) async {
    if (!_initialized) return;
    final isHug = type == 'needs_hug';
    await _plugin.show(
      isHug ? 9002 : 9001,
      'Us',
      isHug ? 'needs a hug' : 'Someone is missing you right now. ♥',
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      payload: type,
    );
  }

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
    await _android?.createNotificationChannel(_channelDefinition);
    await _android?.requestNotificationsPermission();

    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await _scheduleReminders();
    await _appendDiagnostic('Notification service initialized successfully.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_initialized && state == AppLifecycleState.resumed) {
      unawaited(_scheduleReminders().catchError((Object error, StackTrace stack) {
        return _recordSchedulingFailure('Reschedule on resume failed', error, stack);
      }));
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
    // Replace only recurring reminders so a delivered "I miss you" alert is
    // not cleared when the app resumes.
    await Future.wait([_plugin.cancel(1111), _plugin.cancel(2311), _plugin.cancel(400)]);

    final exact = await _android?.canScheduleExactNotifications() ?? true;
    await _appendDiagnostic('Scheduling recurring reminders; exact alarms available: $exact.');
    await _scheduleDaily(id: 1111, hour: 11, minute: 11, message: _elevenElevenMessage, exact: exact);
    await _scheduleDaily(id: 2311, hour: 23, minute: 11, message: _nightMessage, exact: exact);
    await _scheduleMonthly(id: 400, day: 4, hour: 0, minute: 0, message: _monthlyMessage, exact: exact);
    await _verifyReminderSchedules();
  }

  Future<void> _verifyReminderSchedules() async {
    const expected = {1111, 2311, 400};
    Set<int> missing = expected;
    for (var attempt = 1; attempt <= 3; attempt++) {
      final ids = (await _plugin.pendingNotificationRequests())
          .map((request) => request.id)
          .toSet();
      missing = expected.difference(ids);
      await _appendDiagnostic(
        'Schedule verification attempt $attempt/3: pending IDs=${ids.toList()..sort()}, missing=${missing.toList()..sort()}.',
      );
      if (missing.isEmpty) return;
      if (attempt < 3) await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    final missingIds = missing.toList()..sort();
    await _appendDiagnostic('Schedule verification failed; missing IDs: $missingIds.');
    throw StateError('Recurring reminder schedule verification failed; missing IDs: $missingIds.');
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String message,
    required bool exact,
  }) async {
    final selectedMode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _scheduleDailyWithMode(
        id: id,
        hour: hour,
        minute: minute,
        message: message,
        mode: selectedMode,
      );
      await _recordSchedule(id, _nextInstanceOf(hour, minute), selectedMode);
    } on PlatformException catch (error) {
      await _appendDiagnostic('Daily ID $id could not use ${selectedMode.name}: $error; retrying inexact.');
      await _scheduleDailyWithMode(
        id: id,
        hour: hour,
        minute: minute,
        message: message,
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      await _recordSchedule(id, _nextInstanceOf(hour, minute), AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _scheduleDailyWithMode({
    required int id,
    required int hour,
    required int minute,
    required String message,
    required AndroidScheduleMode mode,
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
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleMonthly({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String message,
    required bool exact,
  }) async {
    final selectedMode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _scheduleMonthlyWithMode(
        id: id,
        day: day,
        hour: hour,
        minute: minute,
        message: message,
        mode: selectedMode,
      );
      await _recordSchedule(id, _nextMonthlyInstance(day, hour, minute), selectedMode);
    } on PlatformException catch (error) {
      await _appendDiagnostic('Monthly ID $id could not use ${selectedMode.name}: $error; retrying inexact.');
      await _scheduleMonthlyWithMode(
        id: id,
        day: day,
        hour: hour,
        minute: minute,
        message: message,
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      await _recordSchedule(id, _nextMonthlyInstance(day, hour, minute), AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  Future<void> _scheduleMonthlyWithMode({
    required int id,
    required int day,
    required int hour,
    required int minute,
    required String message,
    required AndroidScheduleMode mode,
  }) {
    return _plugin.zonedSchedule(
      id,
      'Us',
      message,
      _nextMonthlyInstance(day, hour, minute),
      const NotificationDetails(
        android: _channel,
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: mode,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
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

  tz.TZDateTime _nextMonthlyInstance(int day, int hour, int minute) {
    return nextMonthlyInstanceAt(tz.TZDateTime.now(tz.local), day, hour, minute);
  }

  @visibleForTesting
  static tz.TZDateTime nextMonthlyInstanceAt(
    tz.TZDateTime now,
    int day,
    int hour,
    int minute,
  ) {
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }
    return scheduled;
  }

  Future<void> showDebugTestNotification() async {
    if (!_initialized) throw StateError('Notification service has not initialized.');
    await _plugin.show(
      99001,
      'Us notification test',
      'This appeared immediately, so the notification channel pipeline works.',
      const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
    );
    await _appendDiagnostic('Displayed immediate notification test (ID 99001).');
  }

  Future<NotificationDebugSnapshot> debugSnapshot() async {
    List<PendingNotificationRequest> pending = const [];
    String? pluginError;
    try {
      pending = await _plugin.pendingNotificationRequests();
    } catch (error) {
      pluginError = error.toString();
    }
    final preferences = await SharedPreferences.getInstance();
    final scheduleDetails = preferences.getStringList(_scheduleDetailsKey) ?? const [];
    return NotificationDebugSnapshot(
      initialized: _initialized,
      pending: pending,
      scheduleDetails: scheduleDetails,
      lastInitError: preferences.getString(_lastInitErrorKey),
      log: preferences.getStringList(_diagnosticLogKey) ?? const [],
      pluginError: pluginError,
    );
  }

  Future<void> _recordSchedule(int id, tz.TZDateTime scheduledFor, AndroidScheduleMode mode) async {
    final preferences = await SharedPreferences.getInstance();
    final details = preferences.getStringList(_scheduleDetailsKey) ?? <String>[];
    final record = jsonEncode({
      'id': id,
      'scheduledFor': scheduledFor.toIso8601String(),
      'mode': mode.name,
    });
    details.removeWhere((entry) => entry.contains('"id":$id,'));
    details.add(record);
    await preferences.setStringList(_scheduleDetailsKey, details);
    await _appendDiagnostic('Scheduled ID $id for $scheduledFor using ${mode.name}.');
  }

  Future<void> _recordSchedulingFailure(String context, Object error, StackTrace stack) async {
    await _appendDiagnostic('$context: $error\n$stack');
  }

  static Future<void> recordInitializationError(Object error, StackTrace stack) async {
    final value = '${DateTime.now().toIso8601String()} Notification initialization failed: $error\n$stack';
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastInitErrorKey, value);
    await _appendDiagnostic(value);
  }

  static Future<void> _appendDiagnostic(String message) async {
    final preferences = await SharedPreferences.getInstance();
    final log = preferences.getStringList(_diagnosticLogKey) ?? <String>[];
    log.add('${DateTime.now().toIso8601String()} $message');
    if (log.length > 100) log.removeRange(0, log.length - 100);
    await preferences.setStringList(_diagnosticLogKey, log);
  }
}

class NotificationDebugSnapshot {
  const NotificationDebugSnapshot({
    required this.initialized,
    required this.pending,
    required this.scheduleDetails,
    required this.lastInitError,
    required this.log,
    required this.pluginError,
  });

  final bool initialized;
  final List<PendingNotificationRequest> pending;
  final List<String> scheduleDetails;
  final String? lastInitError;
  final List<String> log;
  final String? pluginError;
}
