import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loader_test.dart' show fixtureJson, parseFixture;
import 'support/golden_comparator.dart';

BreakdownItem item(BreakdownCode code, double value) => BreakdownItem(
  code: code,
  description: 'qualquer rótulo',
  value: value,
  type: BreakdownType.addition,
);

TerminationResult resultWith(
  List<BreakdownItem> additions, {
  List<BreakdownItem> fgts = const [],
}) {
  final total = additions.fold(0.0, (a, b) => a + b.value);
  final fine = fgts.fold(0.0, (a, b) => a + b.value);
  return TerminationResult(
    additions: additions,
    deductions: const [],
    totalToReceive: total + fine,
    totalDeductions: 0,
    netAmount: total + fine,
    calculationDate: DateTime(2025, 3, 20),
    paidAtTermination: total,
    fgtsDeposit: FgtsDeposit(items: fgts),
  );
}

void main() {
  group('compareGolden', () {
    final golden = parseFixture(fixtureJson());

    test('deve aceitar 100,01 contra 100,00 e rejeitar 100,02', () {
      expect(withinTolerance(100.01, 100.00), isTrue);
      expect(withinTolerance(100.02, 100.00), isFalse);
    });

    test('deve passar quando a verba bate', () {
      final o = compareGolden(
        golden,
        resultWith([item(BreakdownCode.salaryBalance, 2000.00)]),
      );
      expect(o.failures, isEmpty);
    });

    test('deve identificar a verba pelo code, não pelo texto', () {
      final o = compareGolden(
        golden,
        resultWith([item(BreakdownCode.thirteenth, 2000.00)]),
      );
      expect(o.passed, isFalse);
    });

    test('deve falhar apontando verba extra não zero em fgtsDeposit', () {
      final o = compareGolden(
        golden,
        resultWith(
          [item(BreakdownCode.salaryBalance, 2000.00)],
          fgts: [item(BreakdownCode.fgtsFine, 50.00)],
        ),
      );
      expect(o.passed, isFalse);
      expect(o.failures.any((f) => f.contains('fgtsFine')), isTrue);
    });

    test('deve comparar os totais paidAtTermination e fgtsDeposit', () {
      final json = fixtureJson();
      (json['esperado'] as Map)['totais'] = <String, dynamic>{
        'paidAtTermination': 2000.00,
        'fgtsDeposit': 0.0,
      };
      final c = parseFixture(json);
      expect(
        compareGolden(
          c,
          resultWith([item(BreakdownCode.salaryBalance, 2000.00)]),
        ).failures,
        isEmpty,
      );
      expect(
        compareGolden(
          c,
          resultWith([item(BreakdownCode.salaryBalance, 1500.00)]),
        ).passed,
        isFalse,
      );
    });
  });
}
