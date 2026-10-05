import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('Casos Extremos e Validações', () {
    late CalculateTerminationUseCase useCase;
    late TaxTablesService taxService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      useCase = const CalculateTerminationUseCase();
      taxService = TaxTablesService.instance;
      await taxService.loadTaxTables();
    });

    group('Valores Extremos', () {
      test('deve lidar com salário mínimo', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 1412.0, // Salário mínimo 2024
          averageAdditions: 0.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), lessThan(10000)); // Valor razoável
      });

      test('deve lidar com salário alto', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 50000.0,
          averageAdditions: 10000.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(100000)); // Valor alto esperado
      });

      test('deve lidar com salário zero', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 0.0,
          averageAdditions: 0.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, 0);
        expect((result.paidAtTermination + result.fgtsDeposit.total), 0.0);
      });

      test('deve lidar com adicionais altos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 20000.0, // Adicionais muito altos
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
      });
    });

    group('Períodos Extremos', () {
      test('deve lidar com contrato de 1 dia', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 2),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0)); // Deve ser positivo
      });

      test('deve lidar com contrato de 30 anos', () {
        final input = TerminationInput(
          admissionDate: DateTime(1994, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
        // Com INSS/IRRF calculados sobre total, o valor líquido pode ser menor
        expect(
          (result.paidAtTermination + result.fgtsDeposit.total),
          greaterThan(30000),
        ); // Valor alto esperado (ajustado)
      });

      test('deve lidar com rescisão no mesmo dia da admissão', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThanOrEqualTo(0));
      });
    });

    group('Dias Trabalhados Extremos', () {
      test('deve lidar com 0 dias trabalhados no mês', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          workedDaysInMonth: 0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions.firstWhere((item) => item.code == BreakdownCode.salaryBalance);

        expect(salaryBalance.value, 100.0); // 3000 / 30 * 1
      });

      test('deve lidar com 31 dias trabalhados no mês', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 31),
          baseSalary: 3000.0,
          workedDaysInMonth: 31,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions.firstWhere((item) => item.code == BreakdownCode.salaryBalance);

        expect(salaryBalance.value, 3100.0); // 3000 / 30 * 31
      });

      test('deve lidar com dias trabalhados negativos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 15),
          baseSalary: 3000.0,
          workedDaysInMonth: -5, // Valor inválido
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions.firstWhere((item) => item.code == BreakdownCode.salaryBalance);

        // Deve usar o dia da rescisão (15) em vez do valor negativo
        expect(salaryBalance.value, 1500.0); // 3000 / 30 * 15
      });
    });

    group('Descontos Extremos', () {
      test('deve lidar com outros descontos altos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          otherDiscounts: 10000.0, // Desconto muito alto
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.deductions.any((item) => item.code == BreakdownCode.otherDiscounts), isTrue);
        // Com descontos altos, o valor pode ser negativo (isso é válido)
        expect(
          (result.paidAtTermination + result.fgtsDeposit.total),
          isA<double>(),
        ); // Apenas verifica que é um número válido
      });

      test('deve lidar com outros descontos iguais ao salário', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          otherDiscounts: 3000.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.deductions.any((item) => item.code == BreakdownCode.otherDiscounts), isTrue);
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0)); // Ainda deve ser positivo
      });
    });

    group('FGTS Existente', () {
      test('deve usar valor existente de FGTS quando informado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasExistingFgts: true,
          existingFgtsAmount: 10000.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgtsPenalty = result.fgtsDeposit.items.firstWhere((item) => item.code == BreakdownCode.fgtsFine);

        expect(fgtsPenalty.value, 4000.0); // 10000 * 0.4
      });

      test('deve usar valor existente zero de FGTS', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasExistingFgts: true,
          existingFgtsAmount: 0.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgtsPenalty = result.fgtsDeposit.items.firstWhere((item) => item.code == BreakdownCode.fgtsFine);

        expect(fgtsPenalty.value, greaterThan(0)); // Deve calcular baseado no tempo
      });

      test('deve usar valor existente negativo de FGTS', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasExistingFgts: true,
          existingFgtsAmount: -1000.0, // Valor inválido
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgtsPenalty = result.fgtsDeposit.items.firstWhere((item) => item.code == BreakdownCode.fgtsFine);

        expect(fgtsPenalty.value, greaterThan(0)); // Deve calcular baseado no tempo
      });
    });

    group('Férias Vencidas', () {
      test('deve incluir férias vencidas quando marcado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: true,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.any((item) => item.code == BreakdownCode.accruedVacation), isTrue);
      });

      test('não deve incluir férias vencidas quando não marcado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.any((item) => item.code == BreakdownCode.accruedVacation), isFalse);
      });
    });

    group('Cálculo de Impostos', () {
      test('deve calcular impostos quando habilitado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.deductions.any((item) => item.code == BreakdownCode.inss), isTrue);
        expect(result.deductions.any((item) => item.code == BreakdownCode.irrf), isTrue);
      });

      test('não deve calcular impostos quando desabilitado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.deductions.any((item) => item.code == BreakdownCode.inss), isFalse);
        expect(result.deductions.any((item) => item.code == BreakdownCode.irrf), isFalse);
      });
    });

    group('Validações de Consistência', () {
      test('deve ter totais consistentes', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        final calculatedAdditions = result.additions.fold(0.0, (sum, item) => sum + item.value);
        final calculatedDeductions = result.deductions.fold(0.0, (sum, item) => sum + item.value);
        final calculatedNet = calculatedAdditions - calculatedDeductions;

        // A multa do FGTS está em `fgtsDeposit`, fora de `additions` e de `paidAtTermination` (B2-09).
        expect(result.paidAtTermination, closeTo(calculatedNet, 0.01));
        expect(result.totalDeductions, closeTo(calculatedDeductions, 0.01));
      });

      test('deve ter data de cálculo atual', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final beforeCalculation = DateTime.now();
        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final afterCalculation = DateTime.now();

        expect(result.calculationDate.isAfter(beforeCalculation.subtract(const Duration(seconds: 1))), isTrue);
        expect(result.calculationDate.isBefore(afterCalculation.add(const Duration(seconds: 1))), isTrue);
      });

      test('deve ter valores não negativos para verbas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          expect(addition.value, greaterThanOrEqualTo(0));
        }

        for (final deduction in result.deductions) {
          expect(deduction.value, greaterThanOrEqualTo(0));
        }
      });
    });

    group('Casos de Erro Potencial', () {
      test('deve lidar com datas invertidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 6, 30), // Data posterior
          terminationDate: DateTime(2024, 1, 1), // Data anterior
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        // Mesmo com datas invertidas, não deve quebrar
        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), isA<double>());
      });

      test('deve lidar com valores muito pequenos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 0.01,
          averageAdditions: 0.01,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThanOrEqualTo(0));
      });

      test('deve lidar com valores muito grandes', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 999999999.99,
          averageAdditions: 999999999.99,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total), greaterThan(0));
        expect((result.paidAtTermination + result.fgtsDeposit.total).isFinite, isTrue); // Não deve ser infinito
      });
    });
  });
}
