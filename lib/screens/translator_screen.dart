import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../services/translation_service.dart';
import '../services/pdf_translation_service.dart';
import '../core/app_theme.dart';
import 'saved_notes_screen.dart' show saveMaterialDialog, saveNoteDialog;

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Translator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_fields_rounded), text: 'Text'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded), text: 'PDF'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Clear',
            onPressed: () {
              // Handled inside each tab
              _tabController.index == 0
                  ? _textTabKey.currentState?.clear()
                  : _pdfTabKey.currentState?.clear();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TextTranslatorTab(key: _textTabKey),
          _PdfTranslatorTab(key: _pdfTabKey),
        ],
      ),
    );
  }

  final GlobalKey<_TextTranslatorTabState> _textTabKey =
      GlobalKey<_TextTranslatorTabState>();
  final GlobalKey<_PdfTranslatorTabState> _pdfTabKey =
      GlobalKey<_PdfTranslatorTabState>();
}

// ── Tab 1: Text translator ────────────────────────────────────────────────────

class _TextTranslatorTab extends StatefulWidget {
  const _TextTranslatorTab({super.key});

  @override
  State<_TextTranslatorTab> createState() => _TextTranslatorTabState();
}

class _TextTranslatorTabState extends State<_TextTranslatorTab> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TranslationService _translationService = TranslationService();

  String _sourceLanguage = 'auto';
  bool _isTranslating = false;

  void clear() {
    _inputController.clear();
    _outputController.clear();
  }

  Future<void> _handleTranslate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to translate')),
      );
      return;
    }

    setState(() => _isTranslating = true);
    try {
      final translation = await _translationService.translate(
        text,
        sourceLanguage: _sourceLanguage,
      );
      setState(() => _outputController.text = translation);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  void _copyToClipboard() {
    if (_outputController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _outputController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Translation copied to clipboard')),
      );
    }
  }


  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LanguageSelector(
            value: _sourceLanguage,
            onChanged: (val) => setState(() => _sourceLanguage = val),
          ),
          const SizedBox(height: 20),
          const Text('Text to Translate',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            maxLines: 8,
            minLines: 4,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Paste Russian or Kazakh text here…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isTranslating ? null : _handleTranslate,
            icon: _isTranslating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.translate_rounded),
            label:
                Text(_isTranslating ? 'Translating…' : 'Translate to English'),
          ),
          const SizedBox(height: 28),
          if (_outputController.text.isNotEmpty || _isTranslating) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Translation',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      onPressed: _copyToClipboard,
                      tooltip: 'Copy',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _outputController,
              maxLines: 8,
              minLines: 4,
              readOnly: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 14),
            // Save to Notes button
            ElevatedButton.icon(
              onPressed: _outputController.text.isEmpty
                  ? null
                  : () => saveNoteDialog(
                        context: context,
                        translatedText: _outputController.text,
                        defaultTitle:
                            'Translation (${_sourceLanguage == 'ru' ? 'RU' : _sourceLanguage == 'kk' ? 'KK' : 'Auto'} → EN)',
                      ),
              icon: const Icon(Icons.note_add_rounded),
              label: const Text('Save to Notes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab 2: PDF translator ─────────────────────────────────────────────────────

class _PdfTranslatorTab extends StatefulWidget {
  const _PdfTranslatorTab({super.key});

  @override
  State<_PdfTranslatorTab> createState() => _PdfTranslatorTabState();
}

class _PdfTranslatorTabState extends State<_PdfTranslatorTab> {
  final PdfTranslationService _service = PdfTranslationService();

  String _sourceLanguage = 'auto';
  String? _pickedFilePath;
  String? _pickedFileName;
  String? _outputFilePath;

  bool _isTranslating = false;
  int _progressDone = 0;
  int _progressTotal = 0;

  void clear() {
    setState(() {
      _pickedFilePath = null;
      _pickedFileName = null;
      _outputFilePath = null;
      _isTranslating = false;
      _progressDone = 0;
      _progressTotal = 0;
    });
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _pickedFilePath = result.files.single.path!;
        _pickedFileName = result.files.single.name;
        _outputFilePath = null;
        _progressDone = 0;
        _progressTotal = 0;
      });
    }
  }

  Future<void> _translatePdf() async {
    if (_pickedFilePath == null) return;

    setState(() {
      _isTranslating = true;
      _outputFilePath = null;
      _progressDone = 0;
      _progressTotal = 0;
    });

    try {
      final outputPath = await _service.translatePdf(
        sourcePdfPath: _pickedFilePath!,
        sourceLanguage: _sourceLanguage,
        originalFileName: _pickedFileName ?? 'document',
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _progressDone = done;
              _progressTotal = total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _outputFilePath = outputPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF translated successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Future<void> _openPdf() async {
    if (_outputFilePath == null) return;
    final result = await OpenFile.open(_outputFilePath!);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: ${result.message}')),
      );
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language selector
          _LanguageSelector(
            value: _sourceLanguage,
            onChanged: (val) => setState(() => _sourceLanguage = val),
          ),
          const SizedBox(height: 24),

          // Pick PDF card
          _SectionCard(
            title: 'Source PDF',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_pickedFileName != null) ...[
                  _FileChip(name: _pickedFileName!),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: _isTranslating ? null : _pickPdf,
                  icon: const Icon(Icons.upload_file_rounded),
                  label: Text(
                      _pickedFileName == null ? 'Pick PDF File' : 'Change File'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    foregroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Translate button
          ElevatedButton.icon(
            onPressed:
                (_pickedFilePath == null || _isTranslating) ? null : _translatePdf,
            icon: _isTranslating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.translate_rounded),
            label: Text(
              _isTranslating ? 'Translating…' : 'Translate to English PDF',
            ),
          ),

          // Progress indicator
          if (_isTranslating && _progressTotal > 0) ...[
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Progress',
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progressTotal > 0
                          ? _progressDone / _progressTotal
                          : null,
                      minHeight: 8,
                      backgroundColor: AppTheme.bgInput,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Translating chunk $_progressDone of $_progressTotal…',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],

          // Output + Save as Material
          if (_outputFilePath != null) ...[            
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Translated PDF',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _outputFilePath!.split('/').last,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openPdf,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => saveMaterialDialog(
                      context: context,
                      pdfPath: _outputFilePath!,
                    ),
                    icon: const Icon(Icons.folder_rounded),
                    label: const Text('Save as Material'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Info note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: Color(0xFF6366F1)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The output PDF contains the translated English text in clean A4 format. '
                    'Original images and layout are not preserved — only the text is translated.',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.language_rounded,
              size: 20, color: Color(0xFF6366F1)),
          const SizedBox(width: 10),
          const Text('From:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.bgCard,
                style: const TextStyle(color: AppTheme.textPrimary),
                items: const [
                  DropdownMenuItem(
                      value: 'auto', child: Text('Auto-detect')),
                  DropdownMenuItem(
                      value: 'ru', child: Text('Russian (Русский)')),
                  DropdownMenuItem(
                      value: 'kk', child: Text('Kazakh (Қазақ)')),
                ],
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_rounded,
              size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          const Text('English',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final String name;

  const _FileChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgInput,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded,
              color: Color(0xFFEA580C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
