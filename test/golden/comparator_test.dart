import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loader_test.dart' show fixtureJson, parseFixture;
import 'support/golden_comparator.dart';
import 'support/provisional_code_map.dart';

TerminationResult resultWith(Map<String, double> byDescription) {
  final items = [
    for (final e in byDescription.entries)
      BreakdownItem(
        description: e.key,
        value: e.value,
        type: BreakdownType.addition,
      ),
  ];
  final total = byDescription.values.fold(0.0, (a, b) => a + b);
  return TerminationResult(
    additions: items,
    deductions: const [],
    totalToReceive: total,
    totalDeductions: 0,
    netAmount: total,
    calculationDate: DateTime(2025, 3, 20),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('codeOf', () {
    setUp(() async {
      await TaxTablesService.instance.loadTaxTables();
    });

    test('deve mapear toda descrição que o use case produz hoje', () {
      final input = TerminationInput(
        admissionDate: DateTime(2020, 1, 10),
        terminationDate: DateTime(2025, 3, 20),
        baseSalary: 5000,
        hasAccruedVacation: true,
        otherDiscounts: 10,
      );
      for (final type in TerminationType.values) {
        final r = const CalculateTerminationUseCase().execute(input, type);
        for (final item in [...r.additions, ...r.deductions]) {
          expect(() => codeOf(item), returnsNormally, reason: item.description);
        }
      }
    });

    test('deve lançar erro com a descrição desconhecida', () {
      const item = BreakdownItem(
        description: 'Verba Nova',
        value: 1,
        type: BreakdownType.addition,
      );
      expect(
        () => codeOf(item),
        throwsA(predicate((e) => e.toString().contains('Verba Nova'))),
      );
    });
  });

  group('compareGolden', () {
    final golden = parseFixture(fixtureJson());

    test('deve aceitar 100,01 contra 100,00 e rejeitar 100,02', () {
      expect(withinTolerance(100.01, 100.00), isTrue);
      expect(withinTolerance(100.02, 100.00), isFalse);
    });

    test('deve passar quando a verba bate', () {
      final o = compareGolden(
        golden,
        resultWith({'Saldo de Salário': 2000.00}),
      );
      expect(o.failures, isEmpty);
    });

    test('deve falhar apontando verba extra não zero', () {
      final o = compareGolden(
        golden,
        resultWith({'Saldo de Salário': 2000.00, 'Multa FGTS (40%)': 50.00}),
      );
      expect(o.passed, isFalse);
      expect(o.failures.any((f) => f.contains('fgtsFine')), isTrue);
    });

    test('deve pular total não suportado com motivo', () {
      final json = fixtureJson();
      (json['esperado'] as Map)['totais'] = {'paidAtTermination': 2000.00};
      final o = compareGolden(
        parseFixture(json),
        resultWith({'Saldo de Salário': 2000.00}),
      );
      expect(o.failures, isEmpty);
      expect(o.skips.single, contains('paidAtTermination'));
    });
  });
}
