import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/translation_service.dart';
import '../providers/note_provider.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  final TranslationService _translationService = TranslationService();
  
  String _sourceLanguage = 'auto'; // 'auto', 'ru', 'kk'
  bool _isTranslating = false;

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
      setState(() {
        _outputController.text = translation;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Translation error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
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

  void _saveAsNote() {
    if (_outputController.text.isEmpty) return;
    
    context.read<NoteProvider>().addNote(
      'Translation from ${_sourceLanguage.toUpperCase()}',
      _outputController.text,
      tags: ['translation', _sourceLanguage],
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved as note')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Translator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _inputController.clear();
              _outputController.clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selection
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 20),
                  const SizedBox(width: 12),
                  const Text('Source:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _sourceLanguage,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
                        DropdownMenuItem(value: 'ru', child: Text('Russian (Русский)')),
                        DropdownMenuItem(value: 'kk', child: Text('Kazakh (Қазақ)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sourceLanguage = val);
                      },
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                  const SizedBox(width: 8),
                  const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Input Area
            const Text(
              'Text to Translate',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _inputController,
              maxLines: 8,
              minLines: 4,
              decoration: InputDecoration(
                hintText: 'Paste Russian or Kazakh text here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            
            // Translate Button
            ElevatedButton.icon(
              onPressed: _isTranslating ? null : _handleTranslate,
              icon: _isTranslating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.translate_rounded),
              label: Text(_isTranslating ? 'Translating...' : 'Translate to English'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 32),
            
            // Output Area
            if (_outputController.text.isNotEmpty || _isTranslating) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Translation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: _copyToClipboard,
                        tooltip: 'Copy',
                      ),
                      IconButton(
                        icon: const Icon(Icons.note_add_rounded, size: 20),
                        onPressed: _saveAsNote,
                        tooltip: 'Save as Note',
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
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  filled: true,
                  fillColor: Colors.blue.shade50.withValues(alpha: 0.3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}
