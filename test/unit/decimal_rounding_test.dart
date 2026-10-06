import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';

/// B2-13/B2-14: arredondamento half-up a 2 casas por item, sem resíduo de ponto
/// flutuante, e fronteira em `double` (JSON do histórico) inalterada pela migração
/// para `Decimal`. Valores calculados à mão.
void main() {
  const useCase = CalculateTerminationUseCase();

  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());
  setUp(() async => TaxTablesService.instance.loadTaxTables());

  TerminationInput input({required double salary, required int days}) {
    return TerminationInput(
      admissionDate: DateTime(2026, 2, 1),
      terminationDate: DateTime(2026, 3, 20),
      baseSalary: salary,
      workedDaysInMonth: days,
      calculateTaxes: false,
    );
  }

  double salaryBalance(TerminationInput i) {
    final result = useCase.execute(i, TerminationType.resignation);
    return result.additions
        .firstWhere((BreakdownItem e) => e.code == BreakdownCode.salaryBalance)
        .value;
  }

  group('Arredondamento half-up por item', () {
    test('deve arredondar 10,005 para 10,01', () {
      // 300,15 / 30 x 1 dia = 10,005 exato
      expect(salaryBalance(input(salary: 300.15, days: 1)), 10.01);
    });

    test('deve arredondar 20,015 para 20,02', () {
      // 600,45 / 30 x 1 dia = 20,015 exato
      expect(salaryBalance(input(salary: 600.45, days: 1)), 20.02);
    });
  });

  group('Artefato de ponto flutuante', () {
    test('salário 1.100,10 por 3 dias deve dar exatamente 110,01', () {
      // 1.100,10 / 30 = 36,67; x 3 = 110,01
      expect(salaryBalance(input(salary: 1100.10, days: 3)), 110.01);
    });

    test('salário 1.100,10 por 7 dias deve dar exatamente 256,69', () {
      // 36,67 x 7 = 256,69
      expect(salaryBalance(input(salary: 1100.10, days: 7)), 256.69);
    });
  });

  group('Fronteira double (B2-14)', () {
    test('deve manter o JSON do histórico com números e o mesmo valor', () {
      final i = input(salary: 1100.10, days: 7);
      final result = useCase.execute(i, TerminationType.resignation);
      final history = CalculationHistory(
        id: 'h1',
        input: i,
        result: result,
        terminationType: TerminationType.resignation,
        timestamp: DateTime(2026, 3, 20),
      );

      final json = history.toJson();
      final items = (json['result']['additions'] as List).cast<Map>();
      final saldo = items.firstWhere((e) => e['code'] == 'salaryBalance');
      expect(saldo['value'], isA<double>());
      expect(saldo['value'], 256.69);
      expect(json['result']['paidAtTermination'], isA<double>());
      expect(json['schemaVersion'], 2);

      final reopened = CalculationHistory.fromJson(json);
      expect(reopened.toJson(), json);
    });

    test('deve abrir registro antigo com os mesmos valores', () {
      final legacy = {
        'id': 'old',
        'input': {
          'admissionDate': '2020-01-10T00:00:00.000',
          'terminationDate': '2025-06-10T00:00:00.000',
          'baseSalary': 3000.0,
        },
        'result': {
          'additions': [
            {
              'description': 'Saldo de Salário',
              'value': 1000.0,
              'type': 'addition',
              'details': null,
            },
          ],
          'deductions': <Map<String, dynamic>>[],
          'totalDeductions': 0.0,
          'netAmount': 1000.0,
          'calculationDate': '2025-06-10T00:00:00.000',
        },
        'terminationType': 'resignation',
        'timestamp': '2025-06-10T00:00:00.000',
      };

      final opened = CalculationHistory.fromJson(legacy);

      expect(opened.result.additions.single.value, 1000.0);
      expect(opened.legacyNetAmount, 1000.0);
      expect(opened.input.baseSalary, 3000.0);
    });
  });
}
