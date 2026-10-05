import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/termination_input.dart';
import '../../domain/entities/termination_result.dart';
import '../../domain/entities/termination_type.dart';
import 'formatters.dart';
import 'result_content.dart';

class PdfUtils {
  static Future<void> generateAndSharePdf({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) async {
    final pdf = await _generatePdf(input, result, terminationType);

    await Printing.sharePdf(bytes: pdf, filename: 'rescisao_clt_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> savePdfToFile({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) async {
    final pdf = await _generatePdf(input, result, terminationType);

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/rescisao_clt_${DateTime.now().millisecondsSinceEpoch}.pdf');

    await file.writeAsBytes(pdf);
  }

  /// Conteúdo do PDF: mesma estrutura do compartilhamento completo (função pura, testável
  /// sem renderizar o arquivo).
  static List<ContentSection> buildContent({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) {
    return buildResultSections(input: input, result: result, terminationType: terminationType);
  }

  static Future<Uint8List> _generatePdf(
    TerminationInput input,
    TerminationResult result,
    TerminationType terminationType,
  ) async {
    final pdf = pw.Document();
    final sections = buildContent(input: input, result: result, terminationType: terminationType);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(terminationType),
            pw.SizedBox(height: 16),
            for (final section in sections) ...[_buildSection(section), pw.SizedBox(height: 12)],
            pw.Text(
              'Data do cálculo: ${Formatters.formatDate(result.calculationDate)}. '
              'Calculado com Calculadora de Rescisão CLT.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(TerminationType terminationType) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(color: PdfColors.blue800, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resultado da Rescisão CLT',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.SizedBox(height: 8),
          pw.Text(terminationType.label, style: pw.TextStyle(fontSize: 16, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(ContentSection section) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (section.title != null) ...[
            pw.Text(section.title!, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
          ],
          for (final row in section.rows) _buildRow(row),
        ],
      ),
    );
  }

  static pw.Widget _buildRow(ContentRow row) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: pw.Text(row.label, style: const pw.TextStyle(fontSize: 12))),
              if (row.value != null)
                pw.Text(row.value!, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (row.details != null) pw.Text(row.details!, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ),
    );
  }
}
