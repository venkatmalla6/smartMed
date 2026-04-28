import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/hive_service.dart';

class NoteProvider extends ChangeNotifier {
  List<Note> _notes = [];

  List<Note> get notes => _notes;

  void loadNotes() {
    _notes = HiveService.getAllNotes();
    notifyListeners();
  }

  Future<void> addNote(String title, String content, {List<String> tags = const []}) async {
    final note = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      tags: tags,
    );
    await HiveService.addNote(note);
    loadNotes();
  }

  Future<void> updateNote(Note updated) async {
    await HiveService.updateNote(updated);
    loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await HiveService.deleteNote(id);
    loadNotes();
  }
}
