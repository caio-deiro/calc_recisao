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

  static Future<Uint8List> _generatePdf(
    TerminationInput input,
    TerminationResult result,
    TerminationType terminationType,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(terminationType),
              pw.SizedBox(height: 20),
              _buildEmployeeInfo(input),
              pw.SizedBox(height: 20),
              _buildAdditions(result),
              pw.SizedBox(height: 20),
              _buildDeductions(result),
              pw.SizedBox(height: 20),
              _buildSummary(result),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ],
          );
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
            'RESULTADO DA RESCISÃO CLT',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          ),
          pw.SizedBox(height: 8),
          pw.Text(terminationType.label, style: pw.TextStyle(fontSize: 16, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildEmployeeInfo(TerminationInput input) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('DADOS DO FUNCIONÁRIO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          _buildInfoRow('Data de Admissão:', Formatters.formatDate(input.admissionDate)),
          _buildInfoRow('Data de Desligamento:', Formatters.formatDate(input.terminationDate)),
          _buildInfoRow('Salário Base:', Formatters.formatCurrency(input.baseSalary)),
          _buildInfoRow('Média de Adicionais:', Formatters.formatCurrency(input.averageAdditions)),
          _buildInfoRow('Dependentes:', input.dependents.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildAdditions(TerminationResult result) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VERBAS A RECEBER',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
          ),
          pw.SizedBox(height: 12),
          ...result.additions.map(
            (addition) =>
                _buildItemRow(addition.description, Formatters.formatCurrency(addition.value), addition.details),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDeductions(TerminationResult result) {
    if (result.deductions.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DESCONTOS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
          ),
          pw.SizedBox(height: 12),
          ...result.deductions.map(
            (deduction) =>
                _buildItemRow(deduction.description, Formatters.formatCurrency(deduction.value), deduction.details),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummary(TerminationResult result) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('RESUMO FINANCEIRO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          _buildInfoRow('Total a Receber:', Formatters.formatCurrency(result.totalToReceive)),
          _buildInfoRow('Total Descontos:', Formatters.formatCurrency(result.totalDeductions)),
          pw.Divider(),
          _buildInfoRow('VALOR LÍQUIDO:', Formatters.formatCurrency(result.netAmount), isBold: true),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Data do Cálculo: ${Formatters.formatDate(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Calculado com Calculadora de Rescisão CLT',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'IMPORTANTE: Este é um cálculo estimativo. Consulte um profissional qualificado antes de tomar decisões.',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.red600, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemRow(String description, String value, String? details) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(description, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          if (details != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(details, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ],
      ),
    );
  }
}
