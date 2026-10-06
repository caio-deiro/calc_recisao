import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('TaxTablesService', () {
    late TaxTablesService taxService;
    final DateTime date2025 = DateTime(2025, 6, 15);
    final DateTime date2026 = DateTime(2026, 6, 15);

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      taxService = TaxTablesService.instance;
      await taxService.loadTaxTables();
    });

    group('INSS 2025 progressivo', () {
      test('deve calcular INSS corretamente para salário até R\$ 1.518,00', () {
        final result = taxService.calculateInss(1500.0, date2025);
        expect(result, 112.50);
      });

      test('deve calcular INSS progressivo para salário de R\$ 2.000,00', () {
        final result = taxService.calculateInss(2000.0, date2025);
        expect(result, closeTo(157.23, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 3.000,00', () {
        final result = taxService.calculateInss(3000.0, date2025);
        expect(result, closeTo(253.41, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 5.000,00', () {
        final result = taxService.calculateInss(5000.0, date2025);
        expect(result, closeTo(509.60, 0.01));
      });

      test('deve limitar INSS ao teto de R\$ 8.157,41', () {
        final result = taxService.calculateInss(10000.0, date2025);
        expect(result, closeTo(951.64, 0.01));
      });
    });

    group('INSS 2026 progressivo', () {
      test('deve calcular INSS corretamente para salário até R\$ 1.621,00', () {
        final result = taxService.calculateInss(1600.0, date2026);
        expect(result, 120.0);
      });

      test('deve calcular INSS progressivo para salário de R\$ 2.000,00', () {
        final result = taxService.calculateInss(2000.0, date2026);
        expect(result, closeTo(155.69, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 3.000,00', () {
        final result = taxService.calculateInss(3000.0, date2026);
        expect(result, closeTo(248.60, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 5.000,00', () {
        final result = taxService.calculateInss(5000.0, date2026);
        expect(result, closeTo(501.51, 0.01));
      });

      test('deve limitar INSS ao teto de R\$ 8.475,55', () {
        final result = taxService.calculateInss(10000.0, date2026);
        expect(result, closeTo(988.09, 0.01));
      });
    });

    group('IRRF 2025 (Jan-Abr)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.259,20', () {
        final result = taxService.calculateIrrf(2000.0, DateTime(2025, 3, 15));
        expect(result, 0.0);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(2500.0, DateTime(2025, 3, 15));
        expect(result, closeTo(18.06, 0.01));
      });

      test('deve calcular IRRF de 15% para salário de R\$ 3.500,00', () {
        final result = taxService.calculateIrrf(3500.0, DateTime(2025, 3, 15));
        expect(result, closeTo(143.56, 0.01));
      });
    });

    group('IRRF 2025 (Mai-Dez)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.428,80', () {
        final result = taxService.calculateIrrf(2400.0, date2025);
        expect(result, 0.0);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(2500.0, date2025);
        expect(result, closeTo(44.70, 0.01));
      });

      test('deve usar tabela correta baseada na data', () {
        final janResult = taxService.calculateIrrf(2500.0, DateTime(2025, 1, 15));
        final mayResult = taxService.calculateIrrf(2500.0, date2025);
        expect(janResult, closeTo(18.06, 0.01));
        expect(mayResult, closeTo(44.70, 0.01));
      });
    });

    group('IRRF 2026 com redutor Lei 15.270/2025', () {
      test('deve isentar rendimentos tributáveis até R\$ 5.000,00', () {
        final result = taxService.calculateIrrf(4000.0, date2026);
        expect(result, 0.0);
      });

      test('deve aplicar redutor gradual entre R\$ 5.000,01 e R\$ 7.350,00', () {
        final result = taxService.calculateIrrf(6000.0, date2026);
        expect(result, closeTo(561.52, 0.5));
      });

      test('deve aplicar dedução por dependente', () {
        final withoutDependents = taxService.calculateIrrf(6000.0, date2026);
        final withDependents = taxService.calculateIrrf(6000.0, date2026, dependents: 1);
        expect(withDependents, lessThan(withoutDependents));
      });

      // Valores à mão: Lei 15.270/2025 (redução sobre o rendimento bruto) e tabela mensal 2026.
      test('sem redução quando o bruto é 7.500 e a base deduzida é menor que 7.350', () {
        // 7.000 x 27,5% - 908,73 = 1.016,27; bruto > 7.350 => redução 0
        final result = taxService.calculateIrrf(7000.0, date2026, grossIncome: 7500.0);
        expect(result, closeTo(1016.27, 0.01));
      });

      test('redução gradual usa o bruto 6.000: 978,62 - 0,133145 x 6.000 = 179,75', () {
        // base 5.000: 5.000 x 27,5% - 908,73 = 466,27; 466,27 - 179,75 = 286,52
        final result = taxService.calculateIrrf(5000.0, date2026, grossIncome: 6000.0);
        expect(result, closeTo(286.52, 0.001));
      });

      test('bruto até 5.000 zera o imposto quando ele é menor que 312,89', () {
        // base 4.000: 4.000 x 22,5% - 675,49 = 224,51 < 312,89 => IRRF 0
        final result = taxService.calculateIrrf(4000.0, date2026, grossIncome: 5000.0);
        expect(result, 0.0);
      });

      test('bruto até 5.000 limita a redução em 312,89 e nunca fica negativo', () {
        // base 4.500: 4.500 x 22,5% - 675,49 = 337,01; 337,01 - 312,89 = 24,12
        final result = taxService.calculateIrrf(4500.0, date2026, grossIncome: 5000.0);
        expect(result, closeTo(24.12, 0.01));
      });
    });

    group('Impostos na rescisão', () {
      test('C5: INSS do saldo e do 13º apurados em separado, somados', () {
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: 2000.0,
          thirteenthSalary: 2000.0,
          terminationDate: date2026,
        );
        final double each = taxService.calculateInss(2000.0, date2026);
        expect(taxes.inssSalary, closeTo(each, 0.001));
        expect(taxes.inssThirteenth, closeTo(each, 0.001));
        expect(taxes.inss, closeTo(each * 2, 0.001));
      });

      test('C5: duas bases acima do teto dão duas vezes o INSS do teto', () {
        final double atCeiling = taxService.calculateInss(1000000.0, date2026);
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: 10000.0,
          thirteenthSalary: 10000.0,
          terminationDate: date2026,
        );
        expect(taxes.inss, closeTo(atCeiling * 2, 0.001));
      });

      test('C5: tabela escolhida pela data da rescisão (2025 e 2026)', () {
        final TerminationTaxResult t2025 = taxService.calculateTerminationTaxes(
          salaryBalance: 3000.0,
          thirteenthSalary: 3000.0,
          terminationDate: DateTime(2025, 6, 10),
        );
        final TerminationTaxResult t2026 = taxService.calculateTerminationTaxes(
          salaryBalance: 3000.0,
          thirteenthSalary: 3000.0,
          terminationDate: date2026,
        );
        expect(t2025.inssSalary, closeTo(taxService.calculateInss(3000.0, DateTime(2025, 6, 10)), 0.001));
        expect(t2026.inssSalary, closeTo(taxService.calculateInss(3000.0, date2026), 0.001));
      });

      test('IRRF do 13º usa a tabela mensal (Lei 7.713/88 art. 26): 9.000, 1 dependente', () {
        // INSS 13º 988,09; base 9.000 - 988,09 - 189,59 = 7.822,32;
        // 7.822,32 x 27,5% - 908,73 = 1.242,41; bruto 9.000 > 7.350 => sem redução
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: 0.0,
          thirteenthSalary: 9000.0,
          terminationDate: DateTime(2026, 9, 5),
          dependents: 1,
        );
        expect(taxes.inssThirteenth, closeTo(988.09, 0.01));
        expect(taxes.irrf, closeTo(1242.41, 0.01));
      });
    });

    group('FGTS', () {
      test('deve retornar alíquota correta do FGTS', () {
        expect(taxService.getFgtsAliquota(), 0.08);
      });

      test('deve retornar alíquota correta da multa FGTS', () {
        expect(taxService.getFgtsPenaltyAliquota(), 0.4);
      });
    });

    group('Aviso Prévio', () {
      test('deve retornar dias base corretos', () {
        expect(taxService.getAvisoPrevioBaseDays(), 30);
      });

      test('deve retornar dias por ano corretos', () {
        expect(taxService.getAvisoPrevioDaysPerYear(), 3);
      });

      test('deve retornar máximo de dias correto', () {
        expect(taxService.getAvisoPrevioMaxDays(), 90);
      });
    });

    group('Casos extremos', () {
      test('deve lidar com salário zero', () {
        expect(taxService.calculateInss(0.0, date2025), 0.0);
        expect(taxService.calculateIrrf(0.0, date2025), 0.0);
      });

      test('deve retornar zero para salário negativo', () {
        expect(taxService.calculateInss(-100.0, date2025), 0.0);
        expect(taxService.calculateIrrf(-100.0, date2025), 0.0);
      });
    });
  });
}
