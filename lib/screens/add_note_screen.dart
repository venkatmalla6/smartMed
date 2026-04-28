import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/note_provider.dart';
import '../utils/quiz_launcher.dart';

class AddNoteScreen extends StatefulWidget {
  final String? initialContent;
  const AddNoteScreen({super.key, this.initialContent});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController(text: widget.initialContent);
    _tagsController = TextEditingController();
  }

  Future<void> _saveNote() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final title = _titleController.text.trim().isEmpty 
        ? 'Untitled Note' 
        : _titleController.text.trim();

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await context.read<NoteProvider>().addNote(
      title,
      _contentController.text.trim(),
      tags: tags,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Note'),
        actions: [
          IconButton(
            tooltip: 'Generate Quiz',
            onPressed: () => launchQuizGeneration(
              context: context,
              text: _contentController.text,
              sourceTitle: _titleController.text.trim().isEmpty 
                  ? 'Untitled Note' 
                  : _titleController.text,
            ),
            icon: const Icon(Icons.quiz_rounded),
          ),
          IconButton(
            tooltip: 'Save Note',
            onPressed: _isLoading ? null : _saveNote,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Note Title (Optional)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                hintText: 'Tags (comma separated, e.g. physics, exam)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                prefixIcon: Icon(Icons.tag_rounded, size: 20),
              ),
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Paste or type your study notes here...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveNote,
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Note'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
