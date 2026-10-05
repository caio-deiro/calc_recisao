import 'dart:io';

import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_case.dart';
import 'support/golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final cases = loadGoldenCases(Directory('test/golden/cases'));

  setUp(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  if (cases.isEmpty) {
    test('sem casos golden (infra apenas)', () {
      // ignore: avoid_print
      print('0 casos golden (infra apenas)');
    });
  }

  for (final c in cases) {
    final skipReason = c.unsupportedInputs.isEmpty
        ? null
        : 'entrada ainda não suportada pelo app: ${c.unsupportedInputs.join(', ')}';
    test('deve bater com o oráculo: ${c.id}', () {
      final outcome = compareGolden(
        c,
        const CalculateTerminationUseCase().execute(c.input, c.type),
      );
      expect(outcome.failures, isEmpty, reason: c.id);
    }, skip: skipReason);
  }
}
