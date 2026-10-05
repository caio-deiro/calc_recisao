import 'package:calc_recisao/domain/entities/termination_result.dart';

import 'golden_case.dart';
import 'tolerance.dart';

class GoldenOutcome {
  GoldenOutcome(this.failures);
  final List<String> failures;
  bool get passed => failures.isEmpty;
}

bool withinTolerance(double a, double b) =>
    (a - b).abs() <= goldenTolerance + 1e-9;

/// Compara [result] com o esperado do caso: verbas por `code` (inclui os itens de
/// `fgtsDeposit`) e os totais `totalAdditions`, `totalDeductions`, `paidAtTermination`
/// e `fgtsDeposit`.
GoldenOutcome compareGolden(GoldenCase c, TerminationResult result) {
  final failures = <String>[];

  final produced = <String, double>{};
  for (final item in [...result.additions, ...result.fgtsDeposit.items, ...result.deductions]) {
    final code = item.code.name;
    produced[code] = (produced[code] ?? 0) + item.value;
  }

  for (final e in c.verbas.entries) {
    final got = produced[e.key] ?? 0;
    if (!withinTolerance(got, e.value)) {
      failures.add('${e.key}: esperado ${e.value}, obtido $got');
    }
  }
  for (final e in produced.entries) {
    if (!c.verbas.containsKey(e.key) && !withinTolerance(e.value, 0)) {
      failures.add('${e.key}: verba extra ${e.value} não consta no esperado');
    }
  }

  final totals = {
    'totalAdditions': result.totalAdditions,
    'totalDeductions': result.totalDeductions,
    'paidAtTermination': result.paidAtTermination,
    'fgtsDeposit': result.fgtsDeposit.total,
  };
  for (final e in c.totais.entries) {
    if (!withinTolerance(totals[e.key]!, e.value)) {
      failures.add('${e.key}: esperado ${e.value}, obtido ${totals[e.key]}');
    }
  }
  return GoldenOutcome(failures);
}
