import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/termination_input.dart';
import '../../domain/entities/termination_result.dart';
import '../../domain/entities/termination_type.dart';
import 'formatters.dart';

class ShareUtils {
  static String generateShareText({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('📊 RESULTADO DA RESCISÃO CLT');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');
    buffer.writeln('🔹 Tipo de Rescisão: ${terminationType.label}');
    buffer.writeln('🔹 Data de Admissão: ${Formatters.formatDate(input.admissionDate)}');
    buffer.writeln('🔹 Data de Desligamento: ${Formatters.formatDate(input.terminationDate)}');
    buffer.writeln('🔹 Salário Base: ${Formatters.formatCurrency(input.baseSalary)}');
    buffer.writeln('');
    buffer.writeln('💰 VERBAS A RECEBER:');

    for (final addition in result.additions) {
      buffer.writeln('   ✅ ${addition.description}: ${Formatters.formatCurrency(addition.value)}');
      if (addition.details != null) {
        buffer.writeln('      📝 ${addition.details}');
      }
    }

    if (result.deductions.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('💸 DESCONTOS:');
      for (final deduction in result.deductions) {
        buffer.writeln('   ❌ ${deduction.description}: ${Formatters.formatCurrency(deduction.value)}');
        if (deduction.details != null) {
          buffer.writeln('      📝 ${deduction.details}');
        }
      }
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📈 RESUMO:');
    buffer.writeln('   Total a Receber: ${Formatters.formatCurrency(result.totalToReceive)}');
    buffer.writeln('   Total Descontos: ${Formatters.formatCurrency(result.totalDeductions)}');
    buffer.writeln('   💰 VALOR LÍQUIDO: ${Formatters.formatCurrency(result.netAmount)}');
    buffer.writeln('');
    buffer.writeln('📅 Data do Cálculo: ${Formatters.formatDate(result.calculationDate)}');
    buffer.writeln('');
    buffer.writeln('📱 Calculado com Calculadora de Rescisão CLT');
    buffer.writeln('');
    buffer.writeln('⚠️  IMPORTANTE: Este é um cálculo estimativo. ');
    buffer.writeln('   Consulte um profissional qualificado antes de tomar decisões.');

    return buffer.toString();
  }

  static String generateSimpleShareText({required TerminationResult result, required TerminationType terminationType}) {
    return '''
📊 Rescisão CLT - ${terminationType.label}

💰 Total a Receber: ${Formatters.formatCurrency(result.totalToReceive)}
💸 Total Descontos: ${Formatters.formatCurrency(result.totalDeductions)}
💎 Valor Líquido: ${Formatters.formatCurrency(result.netAmount)}

📱 Calculadora de Rescisão CLT
⚠️  Cálculo estimativo - Consulte um profissional
''';
  }

  static Future<void> shareText(String text, {String? subject}) async {
    final uri = Uri.parse(
      'mailto:?subject=${subject ?? 'Resultado da Rescisão CLT'}&body=${Uri.encodeComponent(text)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: copiar para área de transferência
      // TODO: Implementar clipboard
      throw Exception('Não foi possível compartilhar o resultado');
    }
  }

  static Future<void> shareResult({
    required TerminationInput input,
    required TerminationResult result,
    required TerminationType terminationType,
    bool simple = false,
  }) async {
    final shareText = simple
        ? generateSimpleShareText(result: result, terminationType: terminationType)
        : generateShareText(input: input, result: result, terminationType: terminationType);

    await ShareUtils.shareText(shareText);
  }
}
