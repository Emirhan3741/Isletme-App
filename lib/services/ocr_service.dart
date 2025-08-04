import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
// import 'package:pdf_render/pdf_render.dart';  // Geçici olarak devre dışı - Registrar API uyumsuzluğu

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// OCR servisini başlat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      _isInitialized = true;
      if (kDebugMode) if (kDebugMode) debugPrint('✅ OCR Service başlatıldı');
    } catch (e) {
      if (kDebugMode) if (kDebugMode)
        debugPrint('❌ OCR Service başlatma hatası: $e');
      rethrow;
    }
  }

  /// Servisi kapat ve kaynakları temizle
  Future<void> dispose() async {
    if (_isInitialized) {
      await _textRecognizer.close();
      _isInitialized = false;
      if (kDebugMode) if (kDebugMode) debugPrint('🔄 OCR Service kapatıldı');
    }
  }

  /// Ana metin tanıma metodu
  Future<OCRResult> extractTextFromFile(
      String filePath, String mimeType) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      if (kDebugMode) {
        if (kDebugMode) debugPrint('📄 OCR işlemi başlıyor: $filePath');
        if (kDebugMode) debugPrint('📋 Dosya türü: $mimeType');
      }

      // Dosya türüne göre işleme
      if (_isImageFile(mimeType)) {
        return await _extractTextFromImage(filePath);
      } else if (_isPdfFile(mimeType)) {
        return await _extractTextFromPdf(filePath);
      } else {
        return OCRResult(
          text: '',
          confidence: 0.0,
          success: false,
          message: 'Desteklenmeyen dosya türü: $mimeType',
          language: 'unknown',
          wordCount: 0,
          processingTime: 0,
        );
      }
    } catch (e) {
      if (kDebugMode) if (kDebugMode) debugPrint('❌ OCR hatası: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'OCR işlemi hatası: $e',
        language: 'unknown',
        wordCount: 0,
        processingTime: 0,
      );
    }
  }

  /// Resim dosyasından metin çıkarma
  Future<OCRResult> _extractTextFromImage(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Dosyayı InputImage olarak yükle
      final inputImage = InputImage.fromFilePath(imagePath);

      // OCR işlemini gerçekleştir
      final recognizedText = await _textRecognizer.processImage(inputImage);

      stopwatch.stop();

      final extractedText = recognizedText.text;
      final wordCount = extractedText
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .length;
      final confidence = _calculateConfidence(recognizedText);
      final language = _detectLanguage(extractedText);

      if (kDebugMode) {
        if (kDebugMode) debugPrint('✅ Resim OCR tamamlandı');
        if (kDebugMode)
          debugPrint(
              '📝 Çıkarılan metin uzunluğu: ${extractedText.length} karakter');
        if (kDebugMode) debugPrint('🔤 Kelime sayısı: $wordCount');
        if (kDebugMode)
          debugPrint(
              '🎯 Güven oranı: ${(confidence * 100).toStringAsFixed(1)}%');
        if (kDebugMode) debugPrint('🌍 Dil: $language');
        if (kDebugMode)
          debugPrint('⏱️ İşlem süresi: ${stopwatch.elapsedMilliseconds}ms');
      }

      return OCRResult(
        text: extractedText,
        confidence: confidence,
        success: extractedText.isNotEmpty,
        message: extractedText.isNotEmpty
            ? 'Metin başarıyla çıkarıldı'
            : 'Metne rastlanmadı',
        language: language,
        wordCount: wordCount,
        processingTime: stopwatch.elapsedMilliseconds,
        blocks: recognizedText.blocks
            .map((block) => _convertTextBlock(block))
            .toList(),
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) if (kDebugMode) debugPrint('❌ Resim OCR hatası: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'Resim OCR hatası: $e',
        language: 'unknown',
        wordCount: 0,
        processingTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// PDF dosyasından metin çıkarma - Tam implementasyon
  Future<OCRResult> _extractTextFromPdf(String pdfPath) async {
    final stopwatch = Stopwatch()..start();

    try {
      if (kDebugMode) if (kDebugMode)
        debugPrint('📄 PDF OCR işlemi başlıyor...');

      // Platform kontrolü
      if (kIsWeb) {
        return await _extractTextFromPdfWeb(pdfPath, stopwatch);
      } else {
        return await _extractTextFromPdfNative(pdfPath, stopwatch);
      }
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) if (kDebugMode) debugPrint('❌ PDF OCR hatası: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'PDF OCR hatası: $e',
        language: 'unknown',
        wordCount: 0,
        processingTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Native platform PDF OCR
  Future<OCRResult> _extractTextFromPdfNative(
      String pdfPath, Stopwatch stopwatch) async {
    try {
      // PDF dokümanını aç
      final document = await PdfDocument.openFile(pdfPath);

      String combinedText = '';
      List<OCRTextBlock> combinedBlocks = [];
      double totalConfidence = 0.0;
      int totalWordCount = 0;
      int processedPages = 0;

      if (kDebugMode) if (kDebugMode)
        debugPrint('📋 PDF sayfa sayısı: ${document.pageCount}');

      // Her sayfayı işle
      for (int pageNumber = 1; pageNumber <= document.pageCount; pageNumber++) {
        try {
          if (kDebugMode) if (kDebugMode)
            debugPrint('📄 Sayfa $pageNumber işleniyor...');

          // Sayfayı al
          final page = await document.getPage(pageNumber);

          // Sayfayı yüksek çözünürlükte render et
          const scale = 2.0; // 2x çözünürlük
          final pageImage = await page.render(
            width: (page.width * scale).toInt(),
            height: (page.height * scale).toInt(),
            fullWidth: page.width * scale,
            fullHeight: page.height * scale,
          );

          // Render edilen görüntüyü geçici dosya olarak kaydet
          final tempFile = await _saveImageToTempFile(
              pageImage.pixels, pageImage.width, pageImage.height);

          // OCR uygula
          final inputImage = InputImage.fromFilePath(tempFile.path);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          // Sonuçları birleştir
          if (recognizedText.text.isNotEmpty) {
            combinedText += '--- Sayfa $pageNumber ---\n';
            combinedText += recognizedText.text;
            combinedText += '\n\n';

            // Blokları ekle
            for (final block in recognizedText.blocks) {
              combinedBlocks.add(_convertTextBlock(block));
            }

            // İstatistikleri güncelle
            final pageWordCount = recognizedText.text
                .split(RegExp(r'\s+'))
                .where((word) => word.isNotEmpty)
                .length;
            totalWordCount += pageWordCount;
            totalConfidence += _calculateConfidence(recognizedText);
            processedPages++;

            if (kDebugMode) if (kDebugMode)
              debugPrint(
                  '✅ Sayfa $pageNumber tamamlandı - ${pageWordCount} kelime');
          }

          // Temizlik - PDF sayfası otomatik olarak temizlenir
          await tempFile.delete();
        } catch (e) {
          if (kDebugMode) if (kDebugMode)
            debugPrint('⚠️ Sayfa $pageNumber işlenirken hata: $e');
          continue;
        }
      }

      // Dokümanı kapat
      await document.dispose();
      stopwatch.stop();

      // Ortalama confidence hesapla
      final averageConfidence =
          processedPages > 0 ? (totalConfidence / processedPages) : 0.0;
      final language = _detectLanguage(combinedText);

      if (kDebugMode) {
        if (kDebugMode) debugPrint('✅ PDF OCR tamamlandı');
        if (kDebugMode)
          debugPrint(
              '📄 İşlenen sayfa sayısı: $processedPages/${document.pageCount}');
        if (kDebugMode)
          debugPrint(
              '📝 Toplam metin uzunluğu: ${combinedText.length} karakter');
        if (kDebugMode) debugPrint('🔤 Toplam kelime sayısı: $totalWordCount');
        if (kDebugMode)
          debugPrint(
              '🎯 Ortalama güven oranı: ${(averageConfidence * 100).toStringAsFixed(1)}%');
        if (kDebugMode) debugPrint('🌍 Tespit edilen dil: $language');
        if (kDebugMode)
          debugPrint('⏱️ İşlem süresi: ${stopwatch.elapsedMilliseconds}ms');
      }

      return OCRResult(
        text: combinedText.trim(),
        confidence: averageConfidence,
        success: combinedText.isNotEmpty,
        message: combinedText.isNotEmpty
            ? 'PDF\'den $processedPages sayfa işlendi ve metin çıkarıldı'
            : 'PDF\'de metin bulunamadı',
        language: language,
        wordCount: totalWordCount,
        processingTime: stopwatch.elapsedMilliseconds,
        blocks: combinedBlocks,
      );
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) if (kDebugMode) debugPrint('❌ Native PDF OCR hatası: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'Native PDF OCR hatası: $e',
        language: 'unknown',
        wordCount: 0,
        processingTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Web platform PDF OCR
  Future<OCRResult> _extractTextFromPdfWeb(
      String pdfPath, Stopwatch stopwatch) async {
    try {
      // Web'de PDF OCR sınırlı - pdf_render web desteği var ama daha karmaşık
      if (kDebugMode) if (kDebugMode)
        debugPrint('⚠️ Web platformunda PDF OCR sınırlı destek');

      stopwatch.stop();

      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'Web platformunda PDF OCR şu anda desteklenmemektedir',
        language: 'unknown',
        wordCount: 0,
        processingTime: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return OCRResult(
        text: '',
        confidence: 0.0,
        success: false,
        message: 'Web PDF OCR hatası: $e',
        language: 'unknown',
        wordCount: 0,
        processingTime: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// TextBlock'u daha basit formata çevir
  OCRTextBlock _convertTextBlock(TextBlock block) {
    return OCRTextBlock(
      text: block.text,
      boundingBox: OCRBoundingBox(
        left: block.boundingBox.left,
        top: block.boundingBox.top,
        right: block.boundingBox.right,
        bottom: block.boundingBox.bottom,
      ),
      lines: block.lines
          .map((line) => OCRTextLine(
                text: line.text,
                elements: line.elements.map((element) => element.text).toList(),
              ))
          .toList(),
    );
  }

  /// Güven oranını hesapla
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    // Blokların ve elementlerin kalitesine göre confidence hesapla
    double totalConfidence = 0.0;
    int elementCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // Element'in text uzunluğu ve özelliklerine göre confidence tahmini
          final length = element.text.length;
          final hasNumbers = RegExp(r'\d').hasMatch(element.text);
          final hasLetters =
              RegExp(r'[a-zA-ZçğıöşüÇĞIİÖŞÜ]').hasMatch(element.text);

          double elementConfidence = 0.5; // Base confidence

          if (length > 3) elementConfidence += 0.2;
          if (hasLetters && hasNumbers) elementConfidence += 0.1;
          if (hasLetters) elementConfidence += 0.2;

          totalConfidence += elementConfidence;
          elementCount++;
        }
      }
    }

    return elementCount > 0
        ? (totalConfidence / elementCount).clamp(0.0, 1.0)
        : 0.0;
  }

  /// Dil tespiti (basit)
  String _detectLanguage(String text) {
    if (text.isEmpty) return 'unknown';

    // Türkçe karakterler
    final turkishChars = RegExp(r'[çğıöşüÇĞIİÖŞÜ]');
    if (turkishChars.hasMatch(text)) return 'tr';

    // İngilizce (varsayılan)
    return 'en';
  }

  /// Dosya türü kontrolleri
  bool _isImageFile(String mimeType) {
    return mimeType.startsWith('image/') &&
        (mimeType.contains('jpeg') ||
            mimeType.contains('jpg') ||
            mimeType.contains('png') ||
            mimeType.contains('bmp') ||
            mimeType.contains('tiff') ||
            mimeType.contains('webp'));
  }

  bool _isPdfFile(String mimeType) {
    return mimeType.contains('pdf');
  }

  /// Metin kalitesi analizi
  static TextQuality analyzeTextQuality(String text) {
    if (text.isEmpty) {
      return TextQuality.empty;
    }

    final wordCount =
        text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final charCount = text.length;
    final lineCount = text.split('\n').length;

    // Kalite kriterleri
    final hasStructure = lineCount > 3;
    final hasContent = wordCount > 10;
    final hasProperLength = charCount > 50;

    if (hasStructure && hasContent && hasProperLength) return TextQuality.high;
    if (hasContent && hasProperLength) return TextQuality.medium;
    if (wordCount > 3) return TextQuality.low;

    return TextQuality.poor;
  }

  /// Metin özetleme (basit)
  static String summarizeText(String text, {int maxLength = 150}) {
    if (text.length <= maxLength) return text;

    // İlk cümleleri al
    final sentences = text.split(RegExp(r'[.!?]+'));
    String summary = '';

    for (final sentence in sentences) {
      if (summary.length + sentence.length <= maxLength) {
        summary += sentence.trim() + '. ';
      } else {
        break;
      }
    }

    return summary.trim();
  }

  /// Görüntüyü geçici dosya olarak kaydet
  Future<File> _saveImageToTempFile(
      Uint8List pixels, int width, int height) async {
    // RGBA verilerini PNG formatına çevir
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.buffer,
      format: img.Format.uint8,
      numChannels: 4,
    );

    final pngBytes = img.encodePng(image);

    // Geçici dosya oluştur
    final tempDir = Directory.systemTemp;
    final tempFile = File(
        '${tempDir.path}/ocr_temp_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    return tempFile;
  }
}

/// OCR sonucu model sınıfı
class OCRResult {
  final String text;
  final double confidence;
  final bool success;
  final String message;
  final String language;
  final int wordCount;
  final int processingTime;
  final List<OCRTextBlock>? blocks;

  OCRResult({
    required this.text,
    required this.confidence,
    required this.success,
    required this.message,
    required this.language,
    required this.wordCount,
    required this.processingTime,
    this.blocks,
  });

  /// Güven oranı yüzdesi
  String get confidencePercentage =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// İşlem süresi formatı
  String get processingTimeFormatted => '${processingTime}ms';

  /// Metin kalitesi
  TextQuality get quality => OCRService.analyzeTextQuality(text);

  /// Kısa özet
  String get summary => OCRService.summarizeText(text);

  /// Anahtar kelimeler (basit)
  List<String> get keywords {
    if (text.isEmpty) return [];

    final words = text
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3)
        .map((word) => word.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))
        .where((word) => word.isNotEmpty)
        .toList();

    // Tekrar edenleri say ve en çok tekrar edenleri al
    final wordCounts = <String, int>{};
    for (final word in words) {
      wordCounts[word] = (wordCounts[word] ?? 0) + 1;
    }

    final sortedWords = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedWords.take(5).map((e) => e.key).toList();
  }

  @override
  String toString() {
    return 'OCRResult(success: $success, '
        'confidence: $confidencePercentage, '
        'wordCount: $wordCount, '
        'language: $language, '
        'processingTime: $processingTimeFormatted)';
  }
}

/// OCR metin bloğu
class OCRTextBlock {
  final String text;
  final OCRBoundingBox boundingBox;
  final List<OCRTextLine> lines;

  OCRTextBlock({
    required this.text,
    required this.boundingBox,
    required this.lines,
  });
}

/// OCR metin satırı
class OCRTextLine {
  final String text;
  final List<String> elements;

  OCRTextLine({
    required this.text,
    required this.elements,
  });
}

/// OCR sınırlayıcı kutu
class OCRBoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  OCRBoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

/// Metin kalitesi enum'u
enum TextQuality {
  empty,
  poor,
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TextQuality.empty:
        return 'Boş';
      case TextQuality.poor:
        return 'Zayıf';
      case TextQuality.low:
        return 'Düşük';
      case TextQuality.medium:
        return 'Orta';
      case TextQuality.high:
        return 'Yüksek';
    }
  }

  Color get color {
    switch (this) {
      case TextQuality.empty:
        return const Color(0xFF9E9E9E);
      case TextQuality.poor:
        return const Color(0xFFF44336);
      case TextQuality.low:
        return const Color(0xFFFF9800);
      case TextQuality.medium:
        return const Color(0xFF2196F3);
      case TextQuality.high:
        return const Color(0xFF4CAF50);
    }
  }
}
