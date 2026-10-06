import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

Decimal d(String value) => Decimal.parse(value);

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
        final result = taxService.calculateInss(d('1500.0'), date2025);
        expect(result, d('112.50'));
      });

      test('deve calcular INSS progressivo para salário de R\$ 2.000,00', () {
        final result = taxService.calculateInss(d('2000.0'), date2025);
        expect(result.toDouble(), closeTo(157.23, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 3.000,00', () {
        final result = taxService.calculateInss(d('3000.0'), date2025);
        expect(result.toDouble(), closeTo(253.41, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 5.000,00', () {
        final result = taxService.calculateInss(d('5000.0'), date2025);
        expect(result.toDouble(), closeTo(509.60, 0.01));
      });

      test('deve limitar INSS ao teto de R\$ 8.157,41', () {
        final result = taxService.calculateInss(d('10000.0'), date2025);
        expect(result.toDouble(), closeTo(951.64, 0.01));
      });
    });

    group('INSS 2026 progressivo', () {
      test('deve calcular INSS corretamente para salário até R\$ 1.621,00', () {
        final result = taxService.calculateInss(d('1600.0'), date2026);
        expect(result, d('120.0'));
      });

      test('deve calcular INSS progressivo para salário de R\$ 2.000,00', () {
        final result = taxService.calculateInss(d('2000.0'), date2026);
        expect(result.toDouble(), closeTo(155.69, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 3.000,00', () {
        final result = taxService.calculateInss(d('3000.0'), date2026);
        expect(result.toDouble(), closeTo(248.60, 0.01));
      });

      test('deve calcular INSS progressivo para salário de R\$ 5.000,00', () {
        final result = taxService.calculateInss(d('5000.0'), date2026);
        expect(result.toDouble(), closeTo(501.51, 0.01));
      });

      test('deve limitar INSS ao teto de R\$ 8.475,55', () {
        final result = taxService.calculateInss(d('10000.0'), date2026);
        expect(result.toDouble(), closeTo(988.09, 0.01));
      });
    });

    group('IRRF 2025 (Jan-Abr)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.259,20', () {
        final result = taxService.calculateIrrf(
          d('2000.0'),
          DateTime(2025, 3, 15),
        );
        expect(result, Decimal.zero);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(
          d('2500.0'),
          DateTime(2025, 3, 15),
        );
        expect(result.toDouble(), closeTo(18.06, 0.01));
      });

      test('deve calcular IRRF de 15% para salário de R\$ 3.500,00', () {
        final result = taxService.calculateIrrf(
          d('3500.0'),
          DateTime(2025, 3, 15),
        );
        expect(result.toDouble(), closeTo(143.56, 0.01));
      });
    });

    group('IRRF 2025 (Mai-Dez)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.428,80', () {
        final result = taxService.calculateIrrf(d('2400.0'), date2025);
        expect(result, Decimal.zero);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(d('2500.0'), date2025);
        expect(result.toDouble(), closeTo(44.70, 0.01));
      });

      test('deve usar tabela correta baseada na data', () {
        final janResult = taxService.calculateIrrf(
          d('2500.0'),
          DateTime(2025, 1, 15),
        );
        final mayResult = taxService.calculateIrrf(d('2500.0'), date2025);
        expect(janResult.toDouble(), closeTo(18.06, 0.01));
        expect(mayResult.toDouble(), closeTo(44.70, 0.01));
      });
    });

    group('IRRF 2026 com redutor Lei 15.270/2025', () {
      test('deve isentar rendimentos tributáveis até R\$ 5.000,00', () {
        final result = taxService.calculateIrrf(d('4000.0'), date2026);
        expect(result, Decimal.zero);
      });

      test(
        'deve aplicar redutor gradual entre R\$ 5.000,01 e R\$ 7.350,00',
        () {
          final result = taxService.calculateIrrf(d('6000.0'), date2026);
          expect(result.toDouble(), closeTo(561.52, 0.5));
        },
      );

      test('deve aplicar dedução por dependente', () {
        final withoutDependents = taxService.calculateIrrf(
          d('6000.0'),
          date2026,
        );
        final withDependents = taxService.calculateIrrf(
          d('6000.0'),
          date2026,
          dependents: 1,
        );
        expect(withDependents < withoutDependents, isTrue);
      });

      // Valores à mão: Lei 15.270/2025 (redução sobre o rendimento bruto) e tabela mensal 2026.
      test(
        'sem redução quando o bruto é 7.500 e a base deduzida é menor que 7.350',
        () {
          // 7.000 x 27,5% - 908,73 = 1.016,27; bruto > 7.350 => redução 0
          final result = taxService.calculateIrrf(
            d('7000.0'),
            date2026,
            grossIncome: d('7500.0'),
          );
          expect(result.toDouble(), closeTo(1016.27, 0.01));
        },
      );

      test(
        'redução gradual usa o bruto 6.000: 978,62 - 0,133145 x 6.000 = 179,75',
        () {
          // base 5.000: 5.000 x 27,5% - 908,73 = 466,27; 466,27 - 179,75 = 286,52
          final result = taxService.calculateIrrf(
            d('5000.0'),
            date2026,
            grossIncome: d('6000.0'),
          );
          expect(result.toDouble(), closeTo(286.52, 0.001));
        },
      );

      test('bruto até 5.000 zera o imposto quando ele é menor que 312,89', () {
        // base 4.000: 4.000 x 22,5% - 675,49 = 224,51 < 312,89 => IRRF 0
        final result = taxService.calculateIrrf(
          d('4000.0'),
          date2026,
          grossIncome: d('5000.0'),
        );
        expect(result, Decimal.zero);
      });

      test(
        'bruto até 5.000 limita a redução em 312,89 e nunca fica negativo',
        () {
          // base 4.500: 4.500 x 22,5% - 675,49 = 337,01; 337,01 - 312,89 = 24,12
          final result = taxService.calculateIrrf(
            d('4500.0'),
            date2026,
            grossIncome: d('5000.0'),
          );
          expect(result.toDouble(), closeTo(24.12, 0.01));
        },
      );
    });

    group('Impostos na rescisão', () {
      test('C5: INSS do saldo e do 13º apurados em separado, somados', () {
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: d('2000.0'),
          thirteenthSalary: d('2000.0'),
          terminationDate: date2026,
        );
        // 121,575 + 379 x 9% = 155,685 -> 155,69 (half-up)
        final Decimal each = d('155.69');
        expect(taxes.inssSalary, each);
        expect(taxes.inssThirteenth, each);
        expect(taxes.inss, each + each);
      });

      test('C5: duas bases acima do teto dão duas vezes o INSS do teto', () {
        final Decimal atCeiling = taxService
            .calculateInss(d('1000000.0'), date2026)
            .round(scale: 2);
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: d('10000.0'),
          thirteenthSalary: d('10000.0'),
          terminationDate: date2026,
        );
        expect(taxes.inss, atCeiling + atCeiling);
      });

      test('C5: cada INSS é arredondado half-up antes de somar (2.000 + 2.500)', () {
        // Saldo 2.000: 121,575 + 379 x 9% = 155,685 -> 155,69.
        // 13º 2.500: 121,575 + 879 x 9% = 200,685 -> 200,69. Soma 356,38
        // (a soma crua 356,370 daria 356,37). IRRF: bases 1.844,31 e 2.299,31, isentas.
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: d('2000.0'),
          thirteenthSalary: d('2500.0'),
          terminationDate: DateTime(2026, 9, 5),
        );
        expect(taxes.inssSalary, d('155.69'));
        expect(taxes.inssThirteenth, d('200.69'));
        expect(taxes.inss, d('356.38'));
        expect(taxes.irrf, Decimal.zero);
      });

      test('C5: ambos no teto, cada INSS com 2 casas', () {
        final Decimal ceilingInss = taxService
            .calculateInss(d('1000000.0'), date2026)
            .round(scale: 2);
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: d('10000.0'),
          thirteenthSalary: d('10000.0'),
          terminationDate: date2026,
        );
        expect(taxes.inssSalary, ceilingInss);
        expect(taxes.inssThirteenth, ceilingInss);
        expect(taxes.inss, ceilingInss + ceilingInss);
      });

      test('IRRF: base usa o INSS arredondado da parcela', () {
        // INSS de 2.500: 200,685 -> 200,69; a base do IRRF é 2.500 - 200,69.
        final TerminationTaxResult taxes = taxService.calculateTerminationTaxes(
          salaryBalance: d('2500.0'),
          thirteenthSalary: Decimal.zero,
          terminationDate: DateTime(2026, 9, 5),
          dependents: 1,
        );
        expect(
          taxes.irrf,
          taxService.calculateIrrf(
            d('2500.0') - d('200.69'),
            DateTime(2026, 9, 5),
            dependents: 1,
            grossIncome: d('2500.0'),
          ),
        );
      });

      test('C5: tabela escolhida pela data da rescisão (2025 e 2026)', () {
        final TerminationTaxResult t2025 = taxService.calculateTerminationTaxes(
          salaryBalance: d('3000.0'),
          thirteenthSalary: d('3000.0'),
          terminationDate: DateTime(2025, 6, 10),
        );
        final TerminationTaxResult t2026 = taxService.calculateTerminationTaxes(
          salaryBalance: d('3000.0'),
          thirteenthSalary: d('3000.0'),
          terminationDate: date2026,
        );
        expect(
          t2025.inssSalary,
          taxService
              .calculateInss(d('3000.0'), DateTime(2025, 6, 10))
              .round(scale: 2),
        );
        expect(
          t2026.inssSalary,
          taxService.calculateInss(d('3000.0'), date2026).round(scale: 2),
        );
      });

      test(
        'IRRF do 13º usa a tabela mensal (Lei 7.713/88 art. 26): 9.000, 1 dependente',
        () {
          // INSS 13º 988,09; base 9.000 - 988,09 - 189,59 = 7.822,32;
          // 7.822,32 x 27,5% - 908,73 = 1.242,41; bruto 9.000 > 7.350 => sem redução
          final TerminationTaxResult taxes = taxService
              .calculateTerminationTaxes(
                salaryBalance: Decimal.zero,
                thirteenthSalary: d('9000.0'),
                terminationDate: DateTime(2026, 9, 5),
                dependents: 1,
              );
          expect(taxes.inssThirteenth.toDouble(), closeTo(988.09, 0.01));
          expect(taxes.irrf.toDouble(), closeTo(1242.41, 0.01));
        },
      );
    });

    group('FGTS', () {
      test('deve retornar alíquota correta do FGTS', () {
        expect(taxService.getFgtsAliquota(), d('0.08'));
      });

      test('deve retornar alíquota correta da multa FGTS', () {
        expect(taxService.getFgtsPenaltyAliquota(), d('0.4'));
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
        expect(taxService.calculateInss(Decimal.zero, date2025), Decimal.zero);
        expect(taxService.calculateIrrf(Decimal.zero, date2025), Decimal.zero);
      });

      test('deve retornar zero para salário negativo', () {
        expect(taxService.calculateInss(d('-100.0'), date2025), Decimal.zero);
        expect(taxService.calculateIrrf(d('-100.0'), date2025), Decimal.zero);
      });
    });
  });
}
