import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/mcq.dart';
import '../models/quiz_attempt.dart';
import '../models/quiz.dart';
import '../models/study_task.dart';

class HiveService {
  static const String notesBoxName = 'notes_box';
  static const String quizzesBoxName = 'quizzes_box';
  static const String studyTasksBoxName = 'study_tasks_box';
  static const String settingsBoxName = 'settings_box';
  static const String _apiKeyField = 'gemini_api_key';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(McqQuestionAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(QuizAdapter());
    Hive.registerAdapter(StudyTaskAdapter());

    try {
      await Hive.openBox<Note>(notesBoxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(notesBoxName);
      await Hive.openBox<Note>(notesBoxName);
    }

    try {
      await Hive.openBox<Quiz>(quizzesBoxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(quizzesBoxName);
      await Hive.openBox<Quiz>(quizzesBoxName);
    }

    await Hive.openBox<String>(settingsBoxName);

    try {
      await Hive.openBox<StudyTask>(studyTasksBoxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(studyTasksBoxName);
      await Hive.openBox<StudyTask>(studyTasksBoxName);
    }
  }

  // ── Notes ──────────────────────────────────────────────────────────────────

  static Box<Note> getNotesBox() {
    return Hive.box<Note>(notesBoxName);
  }

  static Future<void> addNote(Note note) async {
    final box = getNotesBox();
    await box.put(note.id, note);
  }

  static List<Note> getAllNotes() {
    final box = getNotesBox();
    return box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> updateNote(Note note) async {
    final box = getNotesBox();
    await box.put(note.id, note);
  }

  static Future<void> deleteNote(String id) async {
    final box = getNotesBox();
    await box.delete(id);
  }

  // ── Quizzes ────────────────────────────────────────────────────────────────

  static Box<Quiz> getQuizzesBox() {
    return Hive.box<Quiz>(quizzesBoxName);
  }

  static Future<void> addQuiz(Quiz quiz) async {
    final box = getQuizzesBox();
    await box.put(quiz.id, quiz);
  }

  static List<Quiz> getAllQuizzes() {
    final box = getQuizzesBox();
    return box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> deleteQuiz(String id) async {
    final box = getQuizzesBox();
    await box.delete(id);
  }

  // ── Study Tasks ────────────────────────────────────────────────────────────

  static Box<StudyTask> getStudyTasksBox() {
    return Hive.box<StudyTask>(studyTasksBoxName);
  }

  static Future<void> addStudyTask(StudyTask task) async {
    final box = getStudyTasksBox();
    await box.put(task.id, task);
  }

  static List<StudyTask> getAllStudyTasks() {
    final box = getStudyTasksBox();
    return box.values.toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  static Future<void> updateStudyTask(StudyTask task) async {
    final box = getStudyTasksBox();
    await box.put(task.id, task);
  }

  static Future<void> deleteStudyTask(String id) async {
    final box = getStudyTasksBox();
    await box.delete(id);
  }

  // ── Settings / API Key ─────────────────────────────────────────────────────

  static Box<String> _settingsBox() => Hive.box<String>(settingsBoxName);

  static String? getApiKey() => _settingsBox().get(_apiKeyField);

  static Future<void> saveApiKey(String key) async {
    await _settingsBox().put(_apiKeyField, key);
  }
}
