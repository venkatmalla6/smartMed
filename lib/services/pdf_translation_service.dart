import 'dart:io';
import 'dart:math';
import 'dart:ui' show Rect, Offset;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'extraction_service.dart';
import 'translation_service.dart';

/// Translates a PDF file (Kazakh/Russian) into an English PDF.
///
/// Pipeline:
///   1. Extract text from source PDF (digital or OCR fallback).
///   2. Split into translation-safe chunks (~2 000 chars each).
///   3. Translate each chunk via Groq AI (with progress callback).
///   4. Lay out translated text into a new A4 PDF using Syncfusion.
///   5. Save file to app documents directory and return the path.
class PdfTranslationService {
  final ExtractionService _extractor = ExtractionService();
  final TranslationService _translator = TranslationService();

  static const int _chunkSize = 2000; // chars per translation request

  /// [onProgress] is called with (completedChunks, totalChunks) as work proceeds.
  Future<String> translatePdf({
    required String sourcePdfPath,
    required String sourceLanguage, // 'auto' | 'ru' | 'kk'
    required String originalFileName,
    void Function(int done, int total)? onProgress,
  }) async {
    // ── Step 1: Extract text ──────────────────────────────────────────────────
    final rawText = await _extractor.extractTextFromPdf(sourcePdfPath);

    if (rawText.trim().isEmpty) {
      throw Exception('Could not extract any text from the PDF.');
    }

    // ── Step 2: Split into chunks ─────────────────────────────────────────────
    final chunks = _splitIntoChunks(rawText, _chunkSize);
    final total = chunks.length;
    final translatedParts = <String>[];

    // ── Step 3: Translate each chunk ──────────────────────────────────────────
    for (int i = 0; i < chunks.length; i++) {
      final translated = await _translator.translate(
        chunks[i],
        sourceLanguage: sourceLanguage,
      );
      translatedParts.add(translated);
      onProgress?.call(i + 1, total);

      // Respectful delay between chunks to avoid rate-limiting
      if (i < chunks.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final translatedText = translatedParts.join('\n\n');

    // ── Step 4: Build PDF ─────────────────────────────────────────────────────
    final pdfBytes = await _buildPdf(
      translatedText: translatedText,
      originalFileName: originalFileName,
      sourceLanguage: sourceLanguage,
    );

    // ── Step 5: Save to documents directory ──────────────────────────────────
    final dir = await getApplicationDocumentsDirectory();
    final baseName = originalFileName
        .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\w\s\-]'), '_');
    final outputPath = '${dir.path}/${baseName}_translated_EN.pdf';

    final outFile = File(outputPath);
    await outFile.writeAsBytes(pdfBytes, flush: true);

    return outputPath;
  }

  // ── PDF builder ─────────────────────────────────────────────────────────────

  Future<List<int>> _buildPdf({
    required String translatedText,
    required String originalFileName,
    required String sourceLanguage,
  }) async {
    final sf.PdfDocument document = sf.PdfDocument();

    // Page layout constants
    const double marginLeft = 40.0;
    const double marginTop = 40.0;
    const double marginRight = 40.0;
    const double marginBottom = 50.0;
    const double pageWidth = 595.0; // A4 width in points
    const double pageHeight = 842.0; // A4 height in points
    const double contentWidth = pageWidth - marginLeft - marginRight;

    // Fonts
    final titleFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 9);
    final bodyFont = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 11);
    final headerFont =
        sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 9, style: sf.PdfFontStyle.italic);

    // Colour palette
    final headerColor = sf.PdfColor(99, 102, 241); // indigo-500
    final bodyColor = sf.PdfColor(30, 41, 59); // slate-800
    final dividerColor = sf.PdfColor(203, 213, 225); // slate-300

    final langLabel = sourceLanguage == 'ru'
        ? 'Russian'
        : sourceLanguage == 'kk'
            ? 'Kazakh'
            : 'Russian/Kazakh';

    // Split translated text into paragraphs
    final paragraphs =
        translatedText.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();

    sf.PdfPage page = document.pages.add();
    double y = marginTop;

    // ── Draw header on first page ─────────────────────────────────────────────
    page.graphics.drawString(
      'SmartMed — Translated from $langLabel to English',
      titleFont,
      brush: sf.PdfSolidBrush(headerColor),
      bounds: Rect.fromLTWH(marginLeft, y, contentWidth, 16),
    );
    y += 14;

    page.graphics.drawString(
      'Source: $originalFileName',
      headerFont,
      brush: sf.PdfSolidBrush(sf.PdfColor(100, 116, 139)),
      bounds: Rect.fromLTWH(marginLeft, y, contentWidth, 14),
    );
    y += 12;

    // Divider line
    page.graphics.drawLine(
      sf.PdfPen(dividerColor),
      Offset(marginLeft, y),
      Offset(pageWidth - marginRight, y),
    );
    y += 14;

    // ── Draw body paragraphs ──────────────────────────────────────────────────
    for (final paragraph in paragraphs) {
      final text = paragraph.trim();
      if (text.isEmpty) continue;

      // Estimate height: ~16pt per line, ~60 chars per line at contentWidth
      final charsPerLine = (contentWidth / 6.5).floor();
      final lineCount = (text.length / charsPerLine).ceil().clamp(1, 9999);
      final textHeight = (lineCount * 16.0) + 10; // 16pt per line + paragraph gap

      // If it won't fit on the current page, add a new page
      if (y + textHeight > pageHeight - marginBottom) {
        page = document.pages.add();
        y = marginTop;
      }

      page.graphics.drawString(
        text,
        bodyFont,
        brush: sf.PdfSolidBrush(bodyColor),
        bounds: Rect.fromLTWH(marginLeft, y, contentWidth, textHeight),
        format: sf.PdfStringFormat(
          lineAlignment: sf.PdfVerticalAlignment.top,
          wordWrap: sf.PdfWordWrapType.word,
        ),
      );

      y += textHeight;
    }

    // ── Page numbers ──────────────────────────────────────────────────────────
    final pageCount = document.pages.count;
    for (int i = 0; i < pageCount; i++) {
      final pg = document.pages[i];
      pg.graphics.drawString(
        'Page ${i + 1} of $pageCount',
        titleFont,
        brush: sf.PdfSolidBrush(sf.PdfColor(148, 163, 184)),
        bounds: Rect.fromLTWH(
          marginLeft,
          pageHeight - marginBottom + 10,
          contentWidth,
          20,
        ),
        format: sf.PdfStringFormat(alignment: sf.PdfTextAlignment.right),
      );
    }

    final bytes = await document.save();
    document.dispose();
    return bytes;
  }

  // ── Text chunking ────────────────────────────────────────────────────────────

  List<String> _splitIntoChunks(String text, int size) {
    final chunks = <String>[];
    int start = 0;
    while (start < text.length) {
      int end = min(start + size, text.length);
      // Try to break at paragraph or sentence boundary
      if (end < text.length) {
        final paraBreak = text.lastIndexOf('\n\n', end);
        final sentBreak = text.lastIndexOf('. ', end);
        final bestBreak = (paraBreak > start + size ~/ 2)
            ? paraBreak
            : (sentBreak > start + size ~/ 2)
                ? sentBreak
                : end;
        end = bestBreak;
      }
      chunks.add(text.substring(start, end).trim());
      start = end;
    }
    return chunks.where((c) => c.isNotEmpty).toList();
  }

  void dispose() {
    _extractor.dispose();
  }
}
