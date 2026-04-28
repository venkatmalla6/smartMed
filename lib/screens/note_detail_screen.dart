import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import '../utils/quiz_launcher.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  bool _isEditing = false;
  bool _isSaving = false;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _tagsController = TextEditingController(
      text: (widget.note.tags ?? []).join(', '),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updated = widget.note.copyWith(
      title: _titleController.text.trim().isEmpty
          ? 'Untitled Note'
          : _titleController.text.trim(),
      content: _contentController.text.trim(),
      tags: tags,
    );

    await context.read<NoteProvider>().updateNote(updated);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note updated successfully')),
      );
    }
  }

  void _discardChanges() {
    _titleController.text = widget.note.title;
    _contentController.text = widget.note.content;
    _tagsController.text = (widget.note.tags ?? []).join(', ');
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isEditing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isEditing) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Note' : 'View Note'),
          actions: [
            if (!_isEditing) ...[
              IconButton(
                tooltip: 'Generate Quiz',
                onPressed: () => launchQuizGeneration(
                  context: context,
                  text: _contentController.text,
                  sourceTitle: _titleController.text,
                ),
                icon: const Icon(Icons.quiz_rounded),
              ),
              IconButton(
                tooltip: 'Copy content',
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: _contentController.text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  }
                },
                icon: const Icon(Icons.copy_rounded),
              ),
              IconButton(
                tooltip: 'Edit note',
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded),
              ),
            ] else ...[
              IconButton(
                tooltip: 'Discard changes',
                onPressed: _showDiscardDialog,
                icon: const Icon(Icons.close_rounded),
              ),
              IconButton(
                tooltip: 'Save',
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _isEditing
                  ? TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Note Title',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: theme.textTheme.headlineMedium,
                    )
                  : Text(
                      _titleController.text,
                      style: theme.textTheme.headlineMedium,
                    ),

              const SizedBox(height: 8),

              // Date
              Text(
                DateFormat('MMMM dd, yyyy • hh:mm a')
                    .format(widget.note.createdAt),
                style: TextStyle(color: Colors.grey.shade500),
              ),

              const SizedBox(height: 12),

              // Tags
              _isEditing
                  ? TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        hintText: 'Tags (comma separated)',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14),
                    )
                  : _buildTagChips(theme),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Content
              _isEditing
                  ? TextField(
                      controller: _contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText: 'Note content...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    )
                  : Text(
                      _contentController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
            ],
          ),
        ),

        // Edit FAB when viewing
        floatingActionButton: _isEditing
            ? null
            : FloatingActionButton.extended(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
      ),
    );
  }

  Widget _buildTagChips(ThemeData theme) {
    final tags = widget.note.tags ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags
          .map((tag) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('Your unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _discardChanges();
            },
            child:
                const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
