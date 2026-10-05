import '../../domain/entities/assumption.dart';
import '../../domain/entities/breakdown_item.dart';
import '../../domain/entities/termination_input.dart';
import '../../domain/entities/termination_result.dart';
import '../../domain/entities/termination_type.dart';
import '../../domain/rules/termination_rules.dart';
import '../../l10n/app_localizations_pt.dart';
import 'formatters.dart';

class ContentRow {
  const ContentRow(this.label, {this.value, this.details});

  final String label;
  final String? value;
  final String? details;
}

class ContentSection {
  const ContentSection(this.title, this.rows);

  final String? title;
  final List<ContentRow> rows;
}

/// Conteúdo textual do resultado, na mesma ordem da tela: aviso de validação, totais,
/// verbas pagas, descontos, depositado no FGTS e premissas. Compartilhamento e PDF
/// usam esta função (única fonte da estrutura); só desenham de formas diferentes.
///
/// [full] = false gera o resumo: só os dois totais e o aviso de validação (sem premissas).
/// Usa apenas dados do próprio cálculo (tipo, datas, salário, verbas), nada do aparelho.
List<ContentSection> buildResultSections({
  required TerminationInput input,
  required TerminationResult result,
  required TerminationType terminationType,
  bool full = true,
}) {
  final l10n = AppLocalizationsPt();
  final withdrawal = TerminationRules.of(terminationType).fgtsWithdrawalPercent;
  final validation = result.assumptions.where((a) => a.code == AssumptionCode.validationPending);

  ContentRow itemRow(BreakdownItem i) =>
      ContentRow(i.description, value: Formatters.formatCurrency(i.value), details: i.details);

  return [
    ContentSection(null, [
      ContentRow('Tipo de rescisão', value: terminationType.label),
      if (full) ...[
        ContentRow('Data de admissão', value: Formatters.formatDate(input.admissionDate)),
        ContentRow('Data de desligamento', value: Formatters.formatDate(input.terminationDate)),
        ContentRow('Salário base', value: Formatters.formatCurrency(input.baseSalary)),
      ],
    ]),
    if (validation.isNotEmpty) ContentSection(l10n.validationNotice, [for (final a in validation) ContentRow(a.text)]),
    ContentSection('Totais', [
      ContentRow(l10n.paidAtTermination, value: Formatters.formatCurrency(result.paidAtTermination)),
      ContentRow(l10n.fgtsDeposit, value: Formatters.formatCurrency(result.fgtsDeposit.total)),
      if (withdrawal != null) ContentRow(l10n.fgtsWithdrawalInfo(withdrawal)),
    ]),
    if (full) ...[
      ContentSection('Verbas pagas', [for (final i in result.additions) itemRow(i)]),
      if (result.deductions.isNotEmpty) ContentSection('Descontos', [for (final i in result.deductions) itemRow(i)]),
      if (result.fgtsDeposit.items.isNotEmpty)
        ContentSection(l10n.fgtsDeposit, [for (final i in result.fgtsDeposit.items) itemRow(i)]),
      if (result.assumptions.isNotEmpty)
        ContentSection(l10n.assumptionsTitle, [
          for (final a in result.assumptions)
            ContentRow(
              a.text,
              value: a.origin == AssumptionOrigin.informed ? l10n.assumptionInformed : l10n.assumptionEstimated,
            ),
        ]),
    ],
    const ContentSection(null, [ContentRow(resultCaveat)]),
  ];
}

/// Ressalva presente em todo texto exportado: estimativa, sem promessa de precisão.
const String resultCaveat =
    'Estimativa com base em regras gerais da CLT. O TRCT oficial prevalece. '
    'Consulte um contador ou advogado antes de decidir.';

/// Renderiza as seções como texto simples (compartilhamento).
String renderSectionsAsText(List<ContentSection> sections) {
  final buffer = StringBuffer();
  for (final section in sections) {
    if (section.title != null) {
      buffer.writeln('${section.title}');
    }
    for (final row in section.rows) {
      buffer.writeln(row.value == null ? row.label : '${row.label}: ${row.value}');
      if (row.details != null) {
        buffer.writeln('   ${row.details}');
      }
    }
    buffer.writeln();
  }
  return buffer.toString().trimRight();
}
