import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> baseJson() => {
    'admissionDate': DateTime(2022, 1, 1).toIso8601String(),
    'terminationDate': DateTime(2024, 6, 1).toIso8601String(),
    'baseSalary': 3000.0,
  };

  group('TerminationInput: férias', () {
    test('deve assumir 0 sem o campo novo e sem legado', () {
      final input = TerminationInput.fromJson({
        ...baseJson(),
        'hasAccruedVacation': false,
      });
      expect(input.vacationPeriodsTaken, 0);
      expect(input.legacyHasAccruedVacation, isFalse);
    });

    test('deve preservar o legado verdadeiro após toJson e fromJson', () {
      final input = TerminationInput.fromJson({
        ...baseJson(),
        'hasAccruedVacation': true,
      });
      expect(input.legacyHasAccruedVacation, isTrue);
      expect(input.vacationPeriodsTaken, 0);
      final again = TerminationInput.fromJson(input.toJson());
      expect(again.legacyHasAccruedVacation, isTrue);
    });

    test('deve fazer round trip de vacationPeriodsTaken', () {
      final input = TerminationInput.fromJson({
        ...baseJson(),
        'vacationPeriodsTaken': 2,
      });
      expect(TerminationInput.fromJson(input.toJson()).vacationPeriodsTaken, 2);
      expect(input.toJson().containsKey('hasAccruedVacation'), isFalse);
    });
  });

  group('Histórico com férias vencidas legadas', () {
    setUp(() async {
      await TaxTablesService.instance.loadTaxTables();
    });

    test(
      'deve ler o item com code accruedVacation e o legado, sem recalcular',
      () {
        final json = {
          'schemaVersion': 2,
          'id': 'old_1',
          'input': {...baseJson(), 'hasAccruedVacation': true},
          'result': {
            'additions': [
              {
                'code': 'accruedVacation',
                'description': 'Férias Vencidas + 1/3',
                'value': 4000.0,
                'type': 'addition',
                'details': 'Salário + 1/3 constitucional',
              },
            ],
            'deductions': [],
            'totalDeductions': 0.0,
            'calculationDate': DateTime(2024, 6, 1).toIso8601String(),
            'paidAtTermination': 4000.0,
            'fgtsDeposit': {'items': []},
            'assumptions': [],
          },
          'terminationType': 'withoutJustCause',
          'timestamp': DateTime(2024, 6, 1).toIso8601String(),
        };
        final record = CalculationHistory.fromJson(json);
        expect(
          record.result.additions.single.code,
          BreakdownCode.accruedVacation,
        );
        expect(record.result.additions.single.value, 4000.0);
        expect(record.input.legacyHasAccruedVacation, isTrue);
        expect(
          CalculationHistory.fromJson(
            record.toJson(),
          ).input.legacyHasAccruedVacation,
          isTrue,
        );
      },
    );

    test('deve ignorar o legado no cálculo', () {
      final input = TerminationInput(
        admissionDate: DateTime(2022, 1, 1),
        terminationDate: DateTime(2024, 6, 1),
        baseSalary: 3000,
        vacationPeriodsTaken: 2,
        legacyHasAccruedVacation: true,
        calculateTaxes: false,
      );
      final result = const CalculateTerminationUseCase().execute(
        input,
        TerminationType.withoutJustCause,
      );
      expect(
        result.additions.where(
          (i) =>
              i.code == BreakdownCode.accruedVacation ||
              i.code == BreakdownCode.accruedVacationSimple ||
              i.code == BreakdownCode.accruedVacationDouble,
        ),
        isEmpty,
      );
    });
  });
}
