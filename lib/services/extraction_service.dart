import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf_pdf;

class ExtractionService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // ── Image OCR ─────────────────────────────────────────────────────────────

  /// Extracts text from an image file using Google ML Kit OCR.
  Future<String> extractTextFromImage(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    final String text = recognizedText.text;
    if (text.trim().isEmpty) {
      throw Exception(
          'No readable text found in the image.\n'
          'Make sure the image is clear, well-lit, and contains printed text.');
    }
    return text;
  }

  // ── PDF Extraction ─────────────────────────────────────────────────────────

  /// Main entry point for PDF text extraction.
  /// 1. Tries native digital-text extraction (fast, for non-scanned PDFs).
  /// 2. If empty, automatically falls back to page-by-page OCR (scanned PDFs).
  Future<String> extractTextFromPdf(String filePath) async {
    final File file = File(filePath);

    if (!file.existsSync()) {
      throw Exception('File not found: $filePath');
    }

    final int fileSize = await file.length();
    if (fileSize > 104857600) {
      // 100 MB limit
      throw Exception(
          'File is too large (${(fileSize / 1048576).toStringAsFixed(1)} MB). '
          'Please try a smaller PDF under 100 MB.');
    }

    // Step 1: Try digital text extraction
    final String digitalText = await _extractDigitalText(filePath);

    if (digitalText.isNotEmpty) {
      return digitalText;
    }

    // Step 2: Fallback — render pages as images and OCR
    return await _extractTextFromScannedPdf(filePath);
  }

  // ── Digital Text Extraction ────────────────────────────────────────────────

  Future<String> _extractDigitalText(String filePath) async {
    final List<int> bytes = await File(filePath).readAsBytes();
    sf_pdf.PdfDocument? document;

    try {
      document = sf_pdf.PdfDocument(inputBytes: bytes);
      final int pageCount = document.pages.count;

      if (pageCount == 0) return '';

      final StringBuffer buffer = StringBuffer();
      final sf_pdf.PdfTextExtractor extractor =
          sf_pdf.PdfTextExtractor(document);

      for (int i = 0; i < pageCount; i++) {
        try {
          final String pageText =
              extractor.extractText(startPageIndex: i, endPageIndex: i);
          if (pageText.trim().isNotEmpty) {
            buffer.write(pageText);
            buffer.write('\n');
          }
        } catch (_) {
          continue; // Skip problematic pages
        }
      }

      return buffer.toString().trim();
    } catch (_) {
      return ''; // Return empty — will trigger OCR fallback
    } finally {
      document?.dispose();
    }
  }

  // ── Scanned PDF OCR Fallback ───────────────────────────────────────────────

  /// Renders each PDF page as a PNG image and runs ML Kit OCR on it.
  Future<String> _extractTextFromScannedPdf(String filePath) async {
    final Directory cacheDir = await getTemporaryDirectory();
    final StringBuffer buffer = StringBuffer();
    PdfDocument? pdfDoc;

    try {
      pdfDoc = await PdfDocument.openFile(filePath);
      final int pageCount = pdfDoc.pagesCount;

      if (pageCount == 0) {
        throw Exception('The PDF file appears to be empty or corrupted.');
      }

      for (int pageNum = 1; pageNum <= pageCount; pageNum++) {
        PdfPage? page;
        File? tempFile;

        try {
          page = await pdfDoc.getPage(pageNum);

          // Render at 2× resolution for better OCR accuracy
          final PdfPageImage? pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          if (pageImage == null) continue;

          // Save rendered image to a temp file
          tempFile = File(
              '${cacheDir.path}/smartmed_ocr_page_$pageNum.png');
          await tempFile.writeAsBytes(pageImage.bytes);

          // Run OCR on the temp file
          final InputImage inputImage =
              InputImage.fromFilePath(tempFile.path);
          final RecognizedText recognized =
              await _textRecognizer.processImage(inputImage);

          if (recognized.text.trim().isNotEmpty) {
            buffer.writeln(recognized.text);
          }
        } catch (_) {
          continue; // Skip any page that fails
        } finally {
          await page?.close();
          // Clean up temp file
          try { await tempFile?.delete(); } catch (_) {}
        }
      }
    } finally {
      await pdfDoc?.close();
    }

    final String result = buffer.toString().trim();

    if (result.isEmpty) {
      throw Exception(
          'Could not extract text from this PDF.\n\n'
          'Possible reasons:\n'
          '• The document uses a non-standard font\n'
          '• The scan quality is too low\n'
          '• The text is in a language other than English\n\n'
          'Try improving the scan quality and try again.');
    }

    return result;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void dispose() {
    _textRecognizer.close();
  }
}
