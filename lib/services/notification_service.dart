import 'dart:convert';
import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/study_task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _tasksPayloadKey = 'study_task';

  // ── Motivational messages ─────────────────────────────────────────────────

  static const List<String> _motivationalMessages = [
    '💪 Champions are made in the hours when everyone else is resting. Time to study!',
    '🧠 Every page you read is a step closer to becoming a great doctor.',
    '🔥 Your future patients are counting on your dedication today!',
    '⭐ Success in medicine starts with consistency. Don\'t skip this session!',
    '🚀 You\'re one study session away from understanding something new.',
    '🌟 Great doctors are made one study hour at a time. Start now!',
    '💡 Knowledge is the best medicine. Your scheduled session is ready!',
    '🏆 The difference between ordinary and extraordinary is a little extra study.',
    '❤️ Heal the world — study hard, stay focused, never give up!',
    '🎯 Today\'s effort = tomorrow\'s skill. Don\'t miss your session!',
    '📚 Medical excellence demands daily dedication. You\'ve got this!',
    '✨ Every question you master is a life you\'re better prepared to save.',
    '⚕️ Hippocrates said: "Healing is a matter of time, but it is sometimes also a matter of opportunity." Seize yours now!',
    '🌱 Small daily improvements lead to stunning long-term results. Study up!',
    '🦋 The best investment you can make is in yourself. Start your session!',
    '🔬 Science waits for no one. Your scheduled study time is here!',
    '💫 Future Dr. — your dedication today shapes your legacy tomorrow.',
    '🌍 Medicine is a calling. Answer it with today\'s study session!',
    '🧬 Every concept you learn today could save a life tomorrow.',
    '🏅 Discipline is the bridge between goals and accomplishment. Study now!',
  ];

  static String _randomMotivation() {
    return _motivationalMessages[
        Random().nextInt(_motivationalMessages.length)];
  }

  // ── Notification channel details ──────────────────────────────────────────

  static const String _channelId = 'study_plan_channel';
  static const String _channelName = 'Study Plan Reminders';
  static const String _channelDesc =
      'Reminders for your scheduled study tasks.';

  static AndroidNotificationDetails _buildAndroidDetails({
    String? bigText,
    List<AndroidNotificationAction>? actions,
  }) {
    return AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation:
          bigText != null ? BigTextStyleInformation(bigText) : null,
      actions: actions,
      // Ensure visibility even on lock screen
      visibility: NotificationVisibility.public,
      fullScreenIntent: false,
    );
  }

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();
    final String currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Request Android 13+ notification permissions
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Request exact alarm permission (Android 12+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ── Notification tap handlers ──────────────────────────────────────────────

  static void _onNotificationTap(NotificationResponse response) {
    // App was in foreground/background — payload available
    // Navigation can be handled here if needed
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTap(NotificationResponse response) {
    // App was terminated — this runs in a separate isolate
  }

  // ── Immediate Notifications ────────────────────────────────────────────────

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: _buildAndroidDetails(bigText: body),
        iOS: const DarwinNotificationDetails(categoryIdentifier: 'study_task'),
      ),
      payload: payload,
    );
  }

  Future<void> notifyTaskAdded(StudyTask task) async {
    await showNow(
      id: 'added_${task.id}'.hashCode,
      title: '✅ Study Task Scheduled',
      body: '"${task.title}" is set for ${_formatTime(task.scheduledTime)}. '
          'We\'ll remind you when it\'s time!',
      payload: jsonEncode({'type': _tasksPayloadKey, 'id': task.id}),
    );
  }

  Future<void> notifyPlanGenerated(int count, String topic) async {
    await showNow(
      id: 'plan_generated'.hashCode,
      title: '🎓 Study Plan Ready!',
      body: 'AI generated $count study sessions for "$topic". '
          'Open SmartMed to review your personalised schedule!',
    );
  }

  Future<void> notifyTaskCompleted(StudyTask task) async {
    await showNow(
      id: 'complete_${task.id}'.hashCode,
      title: '🌟 Well done!',
      body:
          'You completed "${task.title}". ${_randomMotivation()}',
    );
  }

  Future<void> notifyOverdueTasks(List<StudyTask> tasks) async {
    final overdue = tasks
        .where((t) => !t.isCompleted && t.scheduledTime.isBefore(DateTime.now()))
        .toList();
    if (overdue.isEmpty) return;

    final body = overdue.length == 1
        ? '"${overdue.first.title}" was due at '
            '${_formatTime(overdue.first.scheduledTime)}. ${_randomMotivation()}'
        : 'You have ${overdue.length} incomplete study sessions. ${_randomMotivation()}';

    await showNow(
      id: 'overdue_summary'.hashCode,
      title: '⏰ Study Reminder',
      body: body,
    );
  }

  // ── Scheduled Notifications (fire even when app is killed) ─────────────────

  Future<void> scheduleStudyReminder(StudyTask task) async {
    final scheduledDate = tz.TZDateTime.from(task.scheduledTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final motivation = _randomMotivation();
    final body =
        '📚 "${task.title}" is starting now!\n\n$motivation';

    await _plugin.zonedSchedule(
      task.id.hashCode,
      '⏰ Study Time: ${task.title}',
      body,
      scheduledDate,
      NotificationDetails(
        android: _buildAndroidDetails(
          bigText: body,
          actions: [
            AndroidNotificationAction(
              'mark_complete_${task.id}',
              '✅ Mark Complete',
              cancelNotification: true,
            ),
          ],
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'study_task',
          subtitle: motivation,
        ),
      ),
      payload: jsonEncode({'type': _tasksPayloadKey, 'id': task.id}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleIncompleteReminder(StudyTask task) async {
    final followUp = tz.TZDateTime.from(
      task.scheduledTime.add(const Duration(hours: 1)),
      tz.local,
    );
    if (followUp.isBefore(tz.TZDateTime.now(tz.local))) return;

    final motivation = _randomMotivation();
    final body =
        'You haven\'t completed "${task.title}" yet.\n\n$motivation';

    await _plugin.zonedSchedule(
      '${task.id}_followup'.hashCode,
      '🔔 Incomplete: ${task.title}',
      body,
      followUp,
      NotificationDetails(
        android: _buildAndroidDetails(bigText: body),
        iOS: const DarwinNotificationDetails(categoryIdentifier: 'study_task'),
      ),
      payload: jsonEncode({'type': _tasksPayloadKey, 'id': task.id}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Pending notifications list (for in-app notification centre) ────────────

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // ── Cancellation ───────────────────────────────────────────────────────────

  Future<void> cancelTaskNotifications(String taskId) async {
    await _plugin.cancel(taskId.hashCode);
    await _plugin.cancel('${taskId}_followup'.hashCode);
    await _plugin.cancel('added_$taskId'.hashCode);
    await _plugin.cancel('complete_$taskId'.hashCode);
  }

  Future<void> cancelAll() async => _plugin.cancelAll();

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$hour:$min on $day/$month';
  }
}
