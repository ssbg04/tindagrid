import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class GcashOcrResult {
  final String? referenceNumber;
  final double? amount;
  final String rawText;
  final bool isSuccess;

  const GcashOcrResult({
    this.referenceNumber,
    this.amount,
    required this.rawText,
    required this.isSuccess,
  });
}

class GcashReceiptOcrService {
  /// Primary regex for extracting 13-digit GCash reference number
  /// Handles spaced formats: '1002 481 029412', '0021 482 910245', or solid '1002481029412'
  static final RegExp refRegex = RegExp(
    r'(?:Ref(?:\.|erence)?(?:\s*No\.?)?[:\s]*|Reference\s*ID[:\s]*)?([0-9]{4}[\s\-]?[0-9]{3,4}[\s\-]?[0-9]{5,6}|[0-9]{13})',
    caseSensitive: false,
  );

  /// Secondary regex for extracting Peso amounts: 'PHP 500.00', 'P 1,000.00', 'Php500'
  static final RegExp amountRegex = RegExp(
    r'(?:PHP|Php|P|₱)\s*([0-9]{1,3}(?:,[0-9]{3})*(?:\.[0-9]{2})?)',
    caseSensitive: false,
  );

  /// Parse text directly using regex slotting
  static GcashOcrResult parseRawText(String text) {
    String? foundRef;
    double? foundAmount;

    // Search for 13-digit reference number
    final refMatches = refRegex.allMatches(text);
    for (final match in refMatches) {
      final rawMatch = match.group(1) ?? match.group(0);
      if (rawMatch != null) {
        final digitsOnly = rawMatch.replaceAll(RegExp(r'[^0-9]'), '');
        if (digitsOnly.length == 13) {
          foundRef = digitsOnly;
          break;
        }
      }
    }

    // Search for Amount
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      final amtStr = amountMatch.group(1)?.replaceAll(',', '');
      if (amtStr != null) {
        foundAmount = double.tryParse(amtStr);
      }
    }

    return GcashOcrResult(
      referenceNumber: foundRef,
      amount: foundAmount,
      rawText: text,
      isSuccess: foundRef != null,
    );
  }

  /// Process an image file from camera / gallery using Google ML Kit
  static Future<GcashOcrResult> processReceiptImage(String imagePath) async {
    // Fallback on platforms without Google ML Kit support (e.g. desktop/web during tests)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const GcashOcrResult(
        rawText: 'MLKit OCR not supported on desktop/web platform. Use manual entry or mobile device.',
        isSuccess: false,
      );
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      return parseRawText(recognizedText.text);
    } catch (e) {
      return GcashOcrResult(
        rawText: 'Error performing OCR: $e',
        isSuccess: false,
      );
    }
  }
}
