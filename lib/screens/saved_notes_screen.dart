import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';
import '../core/app_theme.dart';
import 'note_detail_screen.dart';

/// Marker prefix stored in Note.content for Material (PDF) entries.
/// Format: "pdf_path::/absolute/path/to/file.pdf"
const String kPdfPathPrefix = 'pdf_path::';

class SavedNotesScreen extends StatefulWidget {
  const SavedNotesScreen({super.key});

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _query = val.toLowerCase()),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search notes, materials or tags…',
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
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.notes_rounded), text: 'Notes'),
                  Tab(
                      icon: Icon(Icons.folder_rounded),
                      text: 'Materials'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NotesTab(query: _query),
          _MaterialsTab(query: _query),
        ],
      ),
    );
  }
}

// ── Notes Tab ─────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final String query;
  const _NotesTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        // Regular notes = NOT tagged 'material'
        final notes = provider.notes.where((n) {
          final isMaterial = (n.tags ?? []).contains('material');
          if (isMaterial) return false;
          if (query.isEmpty) return true;
          return n.title.toLowerCase().contains(query) ||
              n.content.toLowerCase().contains(query) ||
              (n.tags ?? []).join(' ').toLowerCase().contains(query);
        }).toList();

        if (notes.isEmpty) {
          return _EmptyState(
            icon: query.isEmpty
                ? Icons.notes_rounded
                : Icons.search_off_rounded,
            label: query.isEmpty ? 'No notes yet' : 'No notes match "$query"',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _NoteCard(note: notes[i]),
        );
      },
    );
  }
}

// ── Materials Tab ─────────────────────────────────────────────────────────────

class _MaterialsTab extends StatelessWidget {
  final String query;
  const _MaterialsTab({required this.query});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, provider, _) {
        // Materials = tagged 'material'
        final materials = provider.notes.where((n) {
          final isMaterial = (n.tags ?? []).contains('material');
          if (!isMaterial) return false;
          if (query.isEmpty) return true;
          return n.title.toLowerCase().contains(query);
        }).toList();

        if (materials.isEmpty) {
          return _EmptyState(
            icon: query.isEmpty
                ? Icons.folder_open_rounded
                : Icons.search_off_rounded,
            label: query.isEmpty
                ? 'No materials yet\nTranslate a PDF to add one'
                : 'No materials match "$query"',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: materials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _MaterialCard(note: materials[i]),
        );
      },
    );
  }
}

// ── Note Card ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notes_rounded,
                        color: AppTheme.accentBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    onPressed: () =>
                        _confirmDelete(context, note.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              if ((note.tags ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: (note.tags ?? [])
                      .map((tag) => _TagChip(tag: tag))
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a')
                    .format(note.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<NoteProvider>().deleteNote(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Material Card ─────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final Note note;
  const _MaterialCard({required this.note});

  String? get _pdfPath {
    if (note.content.startsWith(kPdfPathPrefix)) {
      return note.content.substring(kPdfPathPrefix.length);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pdfPath = _pdfPath;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openPdf(context, pdfPath),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Color(0xFFEA580C), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Translated PDF',
                          style: TextStyle(
                              color: Color(0xFFEA580C), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                    onPressed: () => _confirmDelete(context, note.id),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPdf(context, pdfPath),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA580C),
                        side: const BorderSide(color: Color(0xFFEA580C)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a')
                    .format(note.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, String? pdfPath) async {
    if (pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF path not found')),
      );
      return;
    }
    final result = await OpenFile.open(pdfPath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Could not open PDF: ${result.message}')),
      );
    }
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material'),
        content:
            const Text('This will remove the material from the app. The PDF file will remain on your device.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<NoteProvider>().deleteNote(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
            fontSize: 10,
            color: AppTheme.accentBlue,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Public helper — save a translated PDF as a Material ───────────────────────

/// Call this from any screen to save a translated PDF as a Material in the
/// Notes screen. Prompts the user for a material name first.
Future<void> saveMaterialDialog({
  required BuildContext context,
  required String pdfPath,
}) async {
  final ctrl = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Save as Material'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter a name for this translated PDF material:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Anatomy Chapter 3 (EN)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await context.read<NoteProvider>().addNote(
      ctrl.text.trim(),
      '$kPdfPathPrefix$pdfPath',
      tags: ['material', 'translation'],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Saved to Materials!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }
}

// ── Public helper — save translated text as a Note ────────────────────────────

/// Call this from any screen to save translated text as a regular Note.
/// Prompts the user for a note name first.
Future<void> saveNoteDialog({
  required BuildContext context,
  required String translatedText,
  String defaultTitle = '',
}) async {
  final ctrl = TextEditingController(text: defaultTitle);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Save as Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter a name for this note:',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Pharmacology Translation',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) Navigator.pop(ctx, true);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await context.read<NoteProvider>().addNote(
      ctrl.text.trim(),
      translatedText,
      tags: ['translation'],
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Saved to Notes!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }
}
