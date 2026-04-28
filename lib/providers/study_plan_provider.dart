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
