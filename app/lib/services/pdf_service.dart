import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/mock_data.dart';

class PdfService {
  PdfService._();
  static final instance = PdfService._();

  /// Generates a carbon credit certificate and returns it as bytes.
  Future<Uint8List> generateCertificate({
    required String farmerName,
    required String farmName,
    required String location,
    required double carbonCredits,
    required double co2eReduced,
    required String transactionId,
    required DateTime issuedDate,
  }) async {
    final pdf = pw.Document();
    final font      = await PdfGoogleFonts.nunitoSansBold();
    final fontReg   = await PdfGoogleFonts.nunitoSansRegular();

    final kGreen = PdfColor.fromHex('1B6B3A');
    final kGreenL = PdfColor.fromHex('E8F5ED');
    final kGold  = PdfColor.fromHex('F59E0B');
    final kGrey  = PdfColor.fromHex('616161');
    final expiry = issuedDate.add(const Duration(days: 365 * 5));

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (ctx) => pw.Stack(children: [
        // Background
        pw.Container(
          color: PdfColors.white,
          child: pw.Column(children: [
            // Header band
            pw.Container(
              width: double.infinity,
              color: kGreen,
              padding: const pw.EdgeInsets.symmetric(vertical: 32, horizontal: 40),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('CROP+', style: pw.TextStyle(font: font, fontSize: 28, color: PdfColors.white)),
                    pw.Text('Carbon+ Nutrition Intelligence Platform',
                        style: pw.TextStyle(font: fontReg, fontSize: 11, color: PdfColor.fromHex('FFFFFFB3'))),
                  ]),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('FFFFFF8A')),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text('VERIFIED CERTIFICATE',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.white)),
                  ),
                ]),
              ]),
            ),

            // Body
            pw.Expanded(child: pw.Container(
              padding: const pw.EdgeInsets.all(40),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Certificate of Carbon Credit Achievement',
                    style: pw.TextStyle(font: font, fontSize: 20, color: kGreen)),
                pw.SizedBox(height: 4),
                pw.Text('This certifies that the following farmer has achieved verified carbon sequestration.',
                    style: pw.TextStyle(font: fontReg, fontSize: 11, color: kGrey)),
                pw.SizedBox(height: 28),

                // Farmer details grid
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: kGreenL,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(children: [
                    _pdfRow(font, fontReg, kGrey, 'Farmer Name', farmerName),
                    pw.Divider(color: PdfColor.fromHex('E8E8E8'), height: 16),
                    _pdfRow(font, fontReg, kGrey, 'Farm', '$farmName · $location'),
                    pw.Divider(color: PdfColor.fromHex('E8E8E8'), height: 16),
                    _pdfRow(font, fontReg, kGrey, 'Carbon Credits Earned',
                        '${carbonCredits.toStringAsFixed(3)} tons CO₂e'),
                    pw.Divider(color: PdfColor.fromHex('E8E8E8'), height: 16),
                    _pdfRow(font, fontReg, kGrey, 'CO₂e Reduced',
                        '${co2eReduced.toStringAsFixed(2)} tons'),
                    pw.Divider(color: PdfColor.fromHex('E8E8E8'), height: 16),
                    _pdfRow(font, fontReg, kGrey, 'Transaction ID', transactionId),
                  ]),
                ),
                pw.SizedBox(height: 24),

                // Credit metrics row
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly, children: [
                  _metricBox(font, fontReg, kGreen, kGreenL, '${MockData.currentCarbon}', 'tons C/ha'),
                  _metricBox(font, fontReg, kGreen, kGreenL, '${MockData.carbonStability.round()}%', 'Stability'),
                  _metricBox(font, fontReg, kGold, PdfColor.fromHex('FFFBEB'),
                      '₹${(carbonCredits * 3600).toStringAsFixed(0)}', 'Market Value'),
                ]),
                pw.SizedBox(height: 24),

                // Dates
                pw.Row(children: [
                  pw.Expanded(child: _pdfRow(font, fontReg, kGrey, 'Issue Date',
                      '${issuedDate.day}/${issuedDate.month}/${issuedDate.year}')),
                  pw.Expanded(child: _pdfRow(font, fontReg, kGrey, 'Valid Until',
                      '${expiry.day}/${expiry.month}/${expiry.year}')),
                ]),
              ]),
            )),

            // Footer
            pw.Container(
              width: double.infinity,
              color: PdfColor.fromHex('F5F6F9'),
              padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 40),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Verify at: cropplus.carbon/verify/$transactionId',
                    style: pw.TextStyle(font: fontReg, fontSize: 9, color: kGrey)),
                pw.Text('Firebase: carbon-tech-67a3d',
                    style: pw.TextStyle(font: fontReg, fontSize: 9, color: kGrey)),
              ]),
            ),
          ]),
        ),
      ]),
    ));

    return pdf.save();
  }

  pw.Widget _pdfRow(pw.Font bold, pw.Font reg, PdfColor grey, String label, String value) =>
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(font: reg, fontSize: 11, color: grey)),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 11)),
      ]);

  pw.Widget _metricBox(pw.Font bold, pw.Font reg, PdfColor color, PdfColor bg,
      String value, String label) =>
      pw.Container(
        width: 110,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 18, color: color)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(font: reg, fontSize: 10, color: PdfColor.fromHex('9E9E9E'))),
        ]),
      );
}
