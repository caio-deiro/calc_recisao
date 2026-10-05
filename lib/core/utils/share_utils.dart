import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/termination_input.dart';
import '../../domain/entities/termination_result.dart';
import '../../domain/entities/termination_type.dart';
import 'result_content.dart';
import 'pdf_utils.dart';

class ShareUtils {
  /// Texto completo: mesma estrutura do Resultado (veja `buildResultSections`).
  static String generateShareText({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) {
    return renderSectionsAsText(buildResultSections(input: input, result: result, terminationType: terminationType));
  }

  /// Resumo: só os dois totais e, se houver, o aviso de "cálculo em validação".
  static String generateSimpleShareText({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) {
    return renderSectionsAsText(
      buildResultSections(input: input, result: result, terminationType: terminationType, full: false),
    );
  }

  static Future<void> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject ?? 'Resultado da Rescisão CLT'));
    } catch (e) {
      // Fallback: copiar para área de transferência
      await _copyToClipboard(text);
      throw Exception('Compartilhamento não disponível. Texto copiado para área de transferência.');
    }
  }

  static Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e) {
      throw Exception('Não foi possível copiar para área de transferência');
    }
  }

  static Future<void> shareResult({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
    bool simple = false,
  }) async {
    final shareText = simple
        ? generateSimpleShareText(input: input, result: result, terminationType: terminationType)
        : generateShareText(input: input, result: result, terminationType: terminationType);

    await ShareUtils.shareText(shareText);
  }

  static Future<void> copyResultToClipboard({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
    bool simple = false,
  }) async {
    final shareText = simple
        ? generateSimpleShareText(input: input, result: result, terminationType: terminationType)
        : generateShareText(input: input, result: result, terminationType: terminationType);

    await _copyToClipboard(shareText);
  }

  static Future<void> exportToPdf({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) async {
    await PdfUtils.generateAndSharePdf(input: input, result: result, terminationType: terminationType);
  }

  static Future<void> savePdfToFile({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) async {
    await PdfUtils.savePdfToFile(input: input, result: result, terminationType: terminationType);
  }
}
