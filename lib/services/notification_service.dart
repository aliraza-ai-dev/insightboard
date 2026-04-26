import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flnp.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    _initialized = true;
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap — navigate to relevant screen
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate
    }
  }

  // ==========================================
  // Anomaly Alert Notification
  // ==========================================
  Future<void> showAnomalyAlert({
    required String title,
    required String body,
    required String severity,
    String? payload,
  }) async {
    final importance = severity == 'critical'
        ? Importance.max
        : severity == 'high'
            ? Importance.high
            : Importance.defaultImportance;

    final androidDetails = AndroidNotificationDetails(
      'anomaly_alerts',
      'Anomaly Alerts',
      channelDescription: 'AI-detected data anomaly notifications',
      importance: importance,
      priority: severity == 'critical' ? Priority.max : Priority.high,
      color: const Color(0xFF6366F1),
      enableLights: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⚠️ $title',
      body,
      details,
      payload: payload,
    );
  }

  // ==========================================
  // Report Ready Notification
  // ==========================================
  Future<void> showReportReady({
    required String reportTitle,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reports',
      'Report Notifications',
      channelDescription: 'Notifications when reports are generated',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📊 Report Ready',
      '$reportTitle has been generated and is ready for download.',
      details,
      payload: payload,
    );
  }

  // ==========================================
  // Team Notification
  // ==========================================
  Future<void> showTeamNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'team',
      'Team Notifications',
      channelDescription: 'Team collaboration notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: Color(0xFF3B82F6),
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
    );

    await _flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // ==========================================
  // Scheduled Report Reminder
  // ==========================================
  Future<void> scheduleReportReminder({
    required int id,
    required String reportTitle,
    required DateTime scheduledTime,
  }) async {
    // For production, use timezone-aware scheduling
    // This is a simplified version
    const androidDetails = AndroidNotificationDetails(
      'scheduled_reports',
      'Scheduled Reports',
      channelDescription: 'Reminders for scheduled report generation',
      importance: Importance.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentAlert: true),
    );

    // In production, use zonedSchedule for timezone-aware scheduling
    await _flnp.show(
      id,
      '📅 Scheduled Report',
      '$reportTitle is being generated as scheduled.',
      details,
    );
  }

  // ==========================================
  // Cancel
  // ==========================================
  Future<void> cancelNotification(int id) async {
    await _flnp.cancel(id);
  }

  Future<void> cancelAll() async {
    await _flnp.cancelAll();
  }
}

// Note: Uses dart:ui Color via Flutter import above
