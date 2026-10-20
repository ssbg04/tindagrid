import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/database/app_database.dart';

enum RateCardFormat {
  a4Sheet,
  a5HalfSheet,
  posThermal80mm,
  posThermal58mm,
}

class RateCardPdfService {
  /// Generate printable rate card PDF bytes
  static Future<Uint8List> generateRateCardPdf({
    required String storeName,
    required List<GcashFeeBracket> brackets,
    RateCardFormat format = RateCardFormat.a4Sheet,
    String? gcashNumber,
  }) async {
    final pdf = pw.Document();

    final PdfPageFormat pageFormat;
    switch (format) {
      case RateCardFormat.a4Sheet:
        pageFormat = PdfPageFormat.a4;
        break;
      case RateCardFormat.a5HalfSheet:
        pageFormat = PdfPageFormat.a5;
        break;
      case RateCardFormat.posThermal80mm:
        pageFormat = const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 4 * PdfPageFormat.mm,
        );
        break;
      case RateCardFormat.posThermal58mm:
        pageFormat = const PdfPageFormat(
          58 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 3 * PdfPageFormat.mm,
        );
        break;
    }

    final isThermal = format == RateCardFormat.posThermal80mm ||
        format == RateCardFormat.posThermal58mm;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          if (isThermal) {
            return _buildThermalLayout(
              storeName: storeName,
              brackets: brackets,
              gcashNumber: gcashNumber,
              is58mm: format == RateCardFormat.posThermal58mm,
            );
          }
          return _buildStandardSheetLayout(
            storeName: storeName,
            brackets: brackets,
            gcashNumber: gcashNumber,
            isA5: format == RateCardFormat.a5HalfSheet,
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or share rate card using OS printing dialog
  static Future<void> printOrShareRateCard({
    required String storeName,
    required List<GcashFeeBracket> brackets,
    RateCardFormat format = RateCardFormat.a4Sheet,
    String? gcashNumber,
  }) async {
    final bytes = await generateRateCardPdf(
      storeName: storeName,
      brackets: brackets,
      format: format,
      gcashNumber: gcashNumber,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat _) async => bytes,
      name: 'TindaGrid_${storeName}_GCash_Rate_Card',
    );
  }

  /// High-contrast layout for A4/A5 store posters
  static pw.Widget _buildStandardSheetLayout({
    required String storeName,
    required List<GcashFeeBracket> brackets,
    String? gcashNumber,
    required bool isA5,
  }) {
    final titleSize = isA5 ? 18.0 : 24.0;
    final subtitleSize = isA5 ? 12.0 : 14.0;
    final rowFontSize = isA5 ? 11.0 : 13.0;

    return pw.Container(
      padding: pw.EdgeInsets.all(isA5 ? 12 : 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue900, width: 3),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue800,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'GCASH CASH-IN & CASH-OUT',
                  style: pw.TextStyle(
                    fontSize: titleSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  storeName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: subtitleSize,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber300,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                if (gcashNumber != null && gcashNumber.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'GCash No: $gcashNumber',
                    style: pw.TextStyle(
                      fontSize: subtitleSize,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Rates Table
          pw.TableHelper.fromTextArray(
            headers: ['TRANSACTION AMOUNT (HALAGA)', 'SERVICE FEE (PATONG)'],
            headerStyle: pw.TextStyle(
              fontSize: rowFontSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            cellStyle: pw.TextStyle(fontSize: rowFontSize),
            data: brackets.map((b) {
              final rangeStr = 'P ${b.minAmount.toStringAsFixed(0)} - P ${b.maxAmount.toStringAsFixed(0)}';
              final feeStr = b.percentageFee > 0
                  ? '${b.percentageFee.toStringAsFixed(1)}%'
                  : 'P ${b.fixedFee.toStringAsFixed(2)}';
              return [rangeStr, feeStr];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            headerPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          ),
          pw.SizedBox(height: 16),

          // Security & Instructions Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PAALALA SA MGA SUKI:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: isA5 ? 9.0 : 10.0,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '* I-double check ang numero bago mag-confirm ng send.',
                  style: pw.TextStyle(fontSize: isA5 ? 8.5 : 9.5),
                ),
                pw.Text(
                  '* Ipakita ang Reference Number o SMS resibo sa tindera bago kunin ang pera.',
                  style: pw.TextStyle(fontSize: isA5 ? 8.5 : 9.5),
                ),
                pw.Text(
                  '* Bawal ang reused screenshot. Automatic na nade-detect ang duplicate reference numbers.',
                  style: pw.TextStyle(fontSize: isA5 ? 8.5 : 9.5),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // Powered by TindaGrid footer
          pw.Center(
            child: pw.Text(
              'Generated with TindaGrid - Offline-First Sari-Sari OS',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// POS Thermal Receipt layout (58mm / 80mm)
  static pw.Widget _buildThermalLayout({
    required String storeName,
    required List<GcashFeeBracket> brackets,
    String? gcashNumber,
    required bool is58mm,
  }) {
    final baseFont = is58mm ? 8.0 : 10.0;
    final headerFont = is58mm ? 10.0 : 12.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Center(
          child: pw.Text(
            storeName.toUpperCase(),
            style: pw.TextStyle(fontSize: headerFont, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'GCASH RATES',
            style: pw.TextStyle(fontSize: baseFont, fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (gcashNumber != null && gcashNumber.isNotEmpty)
          pw.Center(
            child: pw.Text(
              'No: $gcashNumber',
              style: pw.TextStyle(fontSize: baseFont),
            ),
          ),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
        ...brackets.map((b) {
          final rangeStr = '${b.minAmount.toStringAsFixed(0)}-${b.maxAmount.toStringAsFixed(0)}';
          final feeStr = b.percentageFee > 0
              ? '${b.percentageFee.toStringAsFixed(1)}%'
              : 'P${b.fixedFee.toStringAsFixed(0)}';

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(rangeStr, style: pw.TextStyle(fontSize: baseFont)),
                pw.Text(
                  feeStr,
                  style: pw.TextStyle(fontSize: baseFont, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        }),
        pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
        pw.Center(
          child: pw.Text(
            'Salamat sa Tiwala!',
            style: pw.TextStyle(fontSize: baseFont, fontStyle: pw.FontStyle.italic),
          ),
        ),
      ],
    );
  }
}
