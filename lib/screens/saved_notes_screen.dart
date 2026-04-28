import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/note_provider.dart';
import 'note_detail_screen.dart';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search notes or tags...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: Consumer<NoteProvider>(
        builder: (context, provider, child) {
          final filteredNotes = provider.notes.where((note) {
            final title = note.title.toLowerCase();
            final content = note.content.toLowerCase();
            final tags = (note.tags ?? []).join(' ').toLowerCase();
            return title.contains(_query) || content.contains(_query) || tags.contains(_query);
          }).toList();

          if (filteredNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _query.isEmpty ? Icons.notes_rounded : Icons.search_off_rounded,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty ? 'No notes yet' : 'No matches found',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: filteredNotes.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = filteredNotes[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        note.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (note.tags != null && note.tags!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: note.tags!
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '#$tag',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(note.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteDetailScreen(note: note),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, provider, note.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, NoteProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteNote(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
