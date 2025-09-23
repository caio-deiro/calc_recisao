import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('TaxTablesService', () {
    late TaxTablesService taxService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      taxService = TaxTablesService.instance;
      await taxService.loadTaxTables();
    });

    group('INSS 2025', () {
      test('deve calcular INSS corretamente para salário até R\$ 1.518,00', () {
        final result = taxService.calculateInss(1500.0);
        expect(result, 112.50); // 1500 * 0.075
      });

      test('deve calcular INSS corretamente para salário de R\$ 2.000,00', () {
        final result = taxService.calculateInss(2000.0);
        expect(result, 180.00); // 2000 * 0.09
      });

      test('deve calcular INSS corretamente para salário de R\$ 3.000,00', () {
        final result = taxService.calculateInss(3000.0);
        expect(result, 360.00); // 3000 * 0.12
      });

      test('deve calcular INSS corretamente para salário de R\$ 5.000,00', () {
        final result = taxService.calculateInss(5000.0);
        expect(result, closeTo(700.00, 0.01)); // 5000 * 0.14
      });

      test('deve calcular INSS corretamente para salário acima do teto', () {
        final result = taxService.calculateInss(10000.0);
        expect(result, closeTo(1142.04, 0.01)); // 8157.41 * 0.14
      });
    });

    group('IRRF 2025 (Jan-Abr)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.259,20', () {
        final result = taxService.calculateIrrf(2000.0, DateTime(2025, 3, 15));
        expect(result, 0.0);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(2500.0, DateTime(2025, 3, 15));
        expect(result, closeTo(18.06, 0.01)); // (2500 * 0.075) - 169.44
      });

      test('deve calcular IRRF de 15% para salário de R\$ 3.500,00', () {
        final result = taxService.calculateIrrf(3500.0, DateTime(2025, 3, 15));
        expect(result, closeTo(143.56, 0.01)); // (3500 * 0.15) - 381.44
      });

      test('deve calcular IRRF de 22,5% para salário de R\$ 4.000,00', () {
        final result = taxService.calculateIrrf(4000.0, DateTime(2025, 3, 15));
        expect(result, closeTo(237.23, 0.01)); // (4000 * 0.225) - 662.77
      });

      test('deve calcular IRRF de 27,5% para salário alto', () {
        final result = taxService.calculateIrrf(6000.0, DateTime(2025, 3, 15));
        expect(result, closeTo(754.0, 0.01)); // (6000 * 0.275) - 896.0
      });
    });

    group('IRRF 2025 (Mai-Dez)', () {
      test('deve calcular IRRF isento para salário até R\$ 2.428,80', () {
        final result = taxService.calculateIrrf(2400.0, DateTime(2025, 6, 15));
        expect(result, 0.0);
      });

      test('deve calcular IRRF de 7,5% para salário de R\$ 2.500,00', () {
        final result = taxService.calculateIrrf(2500.0, DateTime(2025, 6, 15));
        expect(result, closeTo(44.70, 0.01)); // (2500 * 0.075) - 142.80
      });

      test('deve calcular IRRF de 15% para salário de R\$ 3.500,00', () {
        final result = taxService.calculateIrrf(3500.0, DateTime(2025, 6, 15));
        expect(result, closeTo(170.20, 0.01)); // (3500 * 0.15) - 354.80
      });

      test('deve calcular IRRF de 22,5% para salário de R\$ 4.000,00', () {
        final result = taxService.calculateIrrf(4000.0, DateTime(2025, 6, 15));
        expect(result, closeTo(263.87, 0.01)); // (4000 * 0.225) - 636.13
      });

      test('deve calcular IRRF de 27,5% para salário alto', () {
        final result = taxService.calculateIrrf(6000.0, DateTime(2025, 6, 15));
        expect(result, closeTo(780.64, 0.01)); // (6000 * 0.275) - 869.36
      });
    });

    group('FGTS', () {
      test('deve retornar alíquota correta do FGTS', () {
        final aliquota = taxService.getFgtsAliquota();
        expect(aliquota, 0.08); // 8%
      });

      test('deve retornar alíquota correta da multa FGTS', () {
        final penaltyAliquota = taxService.getFgtsPenaltyAliquota();
        expect(penaltyAliquota, 0.4); // 40%
      });
    });

    group('Aviso Prévio', () {
      test('deve retornar dias base corretos', () {
        final baseDays = taxService.getAvisoPrevioBaseDays();
        expect(baseDays, 30);
      });

      test('deve retornar dias por ano corretos', () {
        final daysPerYear = taxService.getAvisoPrevioDaysPerYear();
        expect(daysPerYear, 3);
      });

      test('deve retornar máximo de dias correto', () {
        final maxDays = taxService.getAvisoPrevioMaxDays();
        expect(maxDays, 90);
      });
    });

    group('Casos extremos', () {
      test('deve lidar com salário zero', () {
        final inssResult = taxService.calculateInss(0.0);
        final irrfResult = taxService.calculateIrrf(0.0, DateTime(2025, 3, 15));

        expect(inssResult, 0.0);
        expect(irrfResult, 0.0);
      });

      test('deve lidar com salário negativo', () {
        final inssResult = taxService.calculateInss(-100.0);
        final irrfResult = taxService.calculateIrrf(-100.0, DateTime(2025, 3, 15));

        expect(inssResult, -7.50); // -100 * 0.075
        expect(irrfResult, 0.0); // Negativo fica isento
      });

      test('deve usar tabela correta baseada na data', () {
        final janResult = taxService.calculateIrrf(2500.0, DateTime(2025, 1, 15));
        final mayResult = taxService.calculateIrrf(2500.0, DateTime(2025, 5, 15));

        // Jan: (2500 * 0.075) - 169.44 = 18.06
        // May: (2500 * 0.075) - 142.80 = 44.70
        expect(janResult, closeTo(18.06, 0.01));
        expect(mayResult, closeTo(44.70, 0.01));
      });
    });
  });
}
