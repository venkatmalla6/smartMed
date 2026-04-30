import 'package:flutter/material.dart';
import '../models/study_task.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/study_plan_service.dart';

class StudyPlanProvider extends ChangeNotifier {
  List<StudyTask> _tasks = [];
  bool isGenerating = false;
  String? generatingError;

  List<StudyTask> get tasks => _tasks;

  List<StudyTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  List<StudyTask> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  List<StudyTask> get overdueTasks => _tasks.where((t) =>
      !t.isCompleted && t.scheduledTime.isBefore(DateTime.now())).toList();

  // ── Today-specific ────────────────────────────────────────────────────────

  List<StudyTask> get todaysTasks {
    final now = DateTime.now();
    return _tasks.where((t) =>
        t.scheduledTime.year == now.year &&
        t.scheduledTime.month == now.month &&
        t.scheduledTime.day == now.day).toList();
  }

  List<StudyTask> get todaysCompleted =>
      todaysTasks.where((t) => t.isCompleted).toList();

  // ── Streak: consecutive days (back from today) with ≥1 completed task ─────

  int get streakDays {
    if (_tasks.isEmpty) return 0;
    final completedDays = _tasks
        .where((t) => t.isCompleted)
        .map((t) => DateTime(
            t.scheduledTime.year, t.scheduledTime.month, t.scheduledTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // descending
    if (completedDays.isEmpty) return 0;

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int streak = 0;
    DateTime check = today;
    for (final day in completedDays) {
      if (day == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else if (day.isBefore(check)) {
        break; // gap found
      }
    }
    return streak;
  }

  List<StudyTask> tasksForDate(DateTime date) {
    return _tasks.where((t) {
      return t.scheduledTime.year == date.year &&
          t.scheduledTime.month == date.month &&
          t.scheduledTime.day == date.day;
    }).toList();
  }

  void loadTasks() {
    _tasks = HiveService.getAllStudyTasks();
    notifyListeners();
    // Push overdue real-time notification on every load
    NotificationService().notifyOverdueTasks(_tasks);
  }

  Future<void> addTask(StudyTask task) async {
    await HiveService.addStudyTask(task);

    // 1. Immediate push notification confirming the task was added
    await NotificationService().notifyTaskAdded(task);

    // 2. Schedule reminder at task time
    await NotificationService().scheduleStudyReminder(task);

    // 3. Schedule follow-up if incomplete after 1 hour
    await NotificationService().scheduleIncompleteReminder(task);

    loadTasks();
  }

  Future<void> toggleComplete(StudyTask task) async {
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    await HiveService.updateStudyTask(task);

    if (task.isCompleted) {
      // Cancel pending reminders
      await NotificationService().cancelTaskNotifications(task.id);
      // Push real-time congratulatory notification
      await NotificationService().notifyTaskCompleted(task);
    } else {
      // Re-schedule if unmarked
      await NotificationService().scheduleStudyReminder(task);
      await NotificationService().scheduleIncompleteReminder(task);
    }

    loadTasks();
  }

  Future<void> deleteTask(StudyTask task) async {
    await NotificationService().cancelTaskNotifications(task.id);
    await HiveService.deleteStudyTask(task.id);
    loadTasks();
  }

  Future<void> generatePlanFromAI({
    required String topic,
    int days = 7,
  }) async {
    isGenerating = true;
    generatingError = null;
    notifyListeners();

    try {
      final suggestions = await StudyPlanService().generateStudyPlan(
        topic: topic,
        days: days,
      );

      for (final suggestion in suggestions) {
        await Future.delayed(const Duration(milliseconds: 2));
        final task = suggestion.toStudyTask();
        await HiveService.addStudyTask(task);
        await NotificationService().scheduleStudyReminder(task);
        await NotificationService().scheduleIncompleteReminder(task);
      }

      // Push a single real-time notification summarising the generated plan
      await NotificationService().notifyPlanGenerated(suggestions.length, topic);

      loadTasks();
    } catch (e) {
      generatingError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> clearAllTasks() async {
    await NotificationService().cancelAll();
    for (final task in _tasks) {
      await HiveService.deleteStudyTask(task.id);
    }
    loadTasks();
  }
}
