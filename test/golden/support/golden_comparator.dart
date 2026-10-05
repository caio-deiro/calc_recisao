import 'package:calc_recisao/domain/entities/termination_result.dart';

import 'golden_case.dart';
import 'provisional_code_map.dart';
import 'tolerance.dart';

class GoldenOutcome {
  GoldenOutcome(this.failures, this.skips);
  final List<String> failures;
  final List<String> skips;
  bool get passed => failures.isEmpty;
}

bool withinTolerance(double a, double b) =>
    (a - b).abs() <= goldenTolerance + 1e-9;

/// Compara [result] com o esperado do caso. Nunca ignora nada em silêncio:
/// o que não é suportado volta em `skips` com o motivo.
GoldenOutcome compareGolden(GoldenCase c, TerminationResult result) {
  final failures = <String>[];
  final skips = <String>[];

  final produced = <String, double>{};
  for (final item in [...result.additions, ...result.deductions]) {
    final code = codeOf(item);
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
  };
  for (final e in c.totais.entries) {
    if (unsupportedTotalKeys.contains(e.key)) {
      skips.add('total ${e.key} ainda não suportado pelo app');
    } else if (!withinTolerance(totals[e.key]!, e.value)) {
      failures.add('${e.key}: esperado ${e.value}, obtido ${totals[e.key]}');
    }
  }
  return GoldenOutcome(failures, skips);
}
