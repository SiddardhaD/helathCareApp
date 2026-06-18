import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications.
///
/// This lives in core/services rather than inside the reminders feature
/// because notifications are a cross-cutting platform capability — both
/// medication doses and appointment reminders schedule through it, and
/// keeping it feature-agnostic avoids a circular dependency between
/// features.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(_guessLocalTimezone()));
    } catch (_) {
      // Fall back to UTC if the platform timezone name can't be resolved;
      // scheduling still works, just without locale-perfect DST handling.
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    _initialized = true;
  }

  String _guessLocalTimezone() {
    // flutter_local_notifications + timezone don't auto-detect the device
    // timezone name out of the box without an extra plugin; a common
    // pragmatic approach is to default to UTC and let DateTime conversions
    // happen relative to device-local DateTime.now(), since we always build
    // tz.TZDateTime.from(DateTime, tz.local).
    return 'UTC';
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a single notification at a specific [dateTime]. [id] must be
  /// a stable, unique 32-bit int — callers derive this deterministically
  /// (see [stableIdFromString]) so re-scheduling the same logical reminder
  /// overwrites rather than duplicates it.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication & Health Reminders',
          channelDescription: 'Reminders for medications, refills, and appointments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: payload,
    );
  }

  /// Schedules a notification that repeats daily at the same time of day —
  /// used for recurring medication doses so we don't need to re-schedule
  /// every single day manually.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = DateTime.now();
    var first = DateTime(now.year, now.month, now.day, hour, minute);
    if (first.isBefore(now)) {
      first = first.add(const Duration(days: 1));
    }
    final scheduledDate = tz.TZDateTime.from(first, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication & Health Reminders',
          channelDescription: 'Reminders for medications, refills, and appointments',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Derives a stable 31-bit positive int id from an arbitrary string key
  /// (e.g. "medicationId_hour_minute"), since the plugin requires int ids
  /// but our domain ids are UUID strings.
  static int stableIdFromString(String key) {
    final hash = key.hashCode & 0x7FFFFFFF;
    return hash == 0 ? 1 : hash;
  }

  @visibleForTesting
  bool get isInitialized => _initialized;
}
