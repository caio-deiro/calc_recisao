import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('Cálculos de Rescisão - Detalhados', () {
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

    group('Saldo de Salário', () {
      test('deve calcular saldo com dias trabalhados especificados', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 15),
          baseSalary: 3000.0,
          workedDaysInMonth: 15,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions.firstWhere((item) => item.description == 'Saldo de Salário');

        expect(salaryBalance.value, 1500.0); // 3000 / 30 * 15
        expect(salaryBalance.details, '15 dias × R\$ 100.00');
      });

      test('deve calcular saldo baseado no dia da rescisão quando não especificado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 20),
          baseSalary: 3000.0,
          workedDaysInMonth: 0, // Não especificado
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions.firstWhere((item) => item.description == 'Saldo de Salário');

        expect(salaryBalance.value, 2000.0); // 3000 / 30 * 20
        expect(salaryBalance.details, '20 dias × R\$ 100.00');
      });

      test('deve calcular saldo para diferentes salários', () {
        final testCases = [
          {'salary': 1500.0, 'days': 10, 'expected': 500.0},
          {'salary': 5000.0, 'days': 25, 'expected': 4166.67},
          {'salary': 10000.0, 'days': 5, 'expected': 1666.67},
        ];

        for (final testCase in testCases) {
          final input = TerminationInput(
            admissionDate: DateTime(2024, 1, 1),
            terminationDate: DateTime(2024, 1, 15),
            baseSalary: testCase['salary'] as double,
            workedDaysInMonth: testCase['days'] as int,
          );

          final result = useCase.execute(input, TerminationType.withoutJustCause);
          final salaryBalance = result.additions.firstWhere((item) => item.description == 'Saldo de Salário');

          expect(salaryBalance.value, closeTo(testCase['expected'] as double, 0.01));
        }
      });
    });

    group('Aviso Prévio Indenizado', () {
      test('deve calcular aviso prévio para funcionário novo (30 dias)', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          noticeWorked: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final notice = result.additions.firstWhere((item) => item.description == 'Aviso Prévio Indenizado');

        expect(notice.value, 3500.0); // (3000 + 500) / 30 * 30
        expect(notice.details, '30 dias + adicional por tempo de serviço');
      });

      test('deve calcular aviso prévio com adicional por tempo de serviço', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          noticeWorked: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final notice = result.additions.firstWhere((item) => item.description == 'Aviso Prévio Indenizado');

        // 2 anos = 30 + (2 * 3) = 36 dias
        expect(notice.value, 4200.0); // (3000 + 500) / 30 * 36
      });

      test('deve respeitar limite máximo de 90 dias', () {
        final input = TerminationInput(
          admissionDate: DateTime(1990, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          noticeWorked: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final notice = result.additions.firstWhere((item) => item.description == 'Aviso Prévio Indenizado');

        // 34 anos = 30 + (34 * 3) = 132, limitado a 90 dias
        expect(notice.value, 10500.0); // (3000 + 500) / 30 * 90
      });

      test('não deve incluir aviso prévio quando trabalhado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          noticeWorked: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final notice = result.additions.where((item) => item.description == 'Aviso Prévio Indenizado');

        expect(notice.length, 0);
      });
    });

    group('13º Salário Proporcional', () {
      test('deve calcular 13º para 6 meses de trabalho', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final thirteenthSalary = result.additions.firstWhere((item) => item.description == '13º Salário Proporcional');

        expect(thirteenthSalary.value, closeTo(1458.33, 0.01)); // (3000 + 500) * 5/12
      });

      test('deve calcular 13º para 3 meses de trabalho', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 3, 31),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final thirteenthSalary = result.additions.firstWhere((item) => item.description == '13º Salário Proporcional');

        expect(thirteenthSalary.value, closeTo(583.33, 0.01)); // (3000 + 500) * 2/12
      });

      test('deve calcular 13º para 1 ano completo', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2023, 12, 31),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final thirteenthSalary = result.additions.firstWhere((item) => item.description == '13º Salário Proporcional');

        expect(thirteenthSalary.value, closeTo(3208.33, 0.01)); // (3000 + 500) * 11/12
      });
    });

    group('Férias Vencidas', () {
      test('deve calcular férias vencidas com 1/3 constitucional', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          hasAccruedVacation: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final vacation = result.additions.firstWhere((item) => item.description == 'Férias Vencidas + 1/3');

        expect(vacation.value, 4000.0); // 3000 + (3000 / 3)
        expect(vacation.details, 'Salário + 1/3 constitucional');
      });

      test('não deve incluir férias vencidas quando não há', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 6, 1),
          baseSalary: 3000.0,
          hasAccruedVacation: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final vacation = result.additions.where((item) => item.description == 'Férias Vencidas + 1/3');

        expect(vacation.length, 0);
      });
    });

    group('Férias Proporcionais', () {
      test('deve calcular férias proporcionais com 1/3 constitucional', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final vacation = result.additions.firstWhere((item) => item.description == 'Férias Proporcionais + 1/3');

        // 5 meses: (3000 + 500) * 5/12 = 1458.33 + 1/3 = 1944.44
        expect(vacation.value, closeTo(1944.44, 0.01));
      });

      test('deve calcular férias proporcionais para 3 meses', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 3, 31),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final vacation = result.additions.firstWhere((item) => item.description == 'Férias Proporcionais + 1/3');

        // 2 meses: (3000 + 500) * 2/12 = 583.33 + 1/3 = 777.78
        expect(vacation.value, closeTo(777.78, 0.01));
      });
    });

    group('FGTS', () {
      test('deve calcular FGTS para 6 meses de trabalho', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgts = result.additions.firstWhere((item) => item.description == 'FGTS');

        // 5 meses: (3000 + 500) * 0.08 * 5 = 1400.0
        expect(fgts.value, 1400.0);
      });

      test('deve calcular FGTS para 1 ano de trabalho', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgts = result.additions.firstWhere((item) => item.description == 'FGTS');

        // 12 meses: (3000 + 500) * 0.08 * 12 = 3360.0
        expect(fgts.value, 3360.0);
      });
    });

    group('Multa FGTS', () {
      test('deve calcular multa FGTS de 40% para rescisão sem justa causa', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgtsPenalty = result.additions.firstWhere((item) => item.description == 'Multa FGTS (40%)');

        // FGTS: (3000 + 500) * 0.08 * 12 = 3360
        // Multa: 3360 * 0.4 = 1344
        expect(fgtsPenalty.value, 1344.0);
      });

      test('deve usar valor existente de FGTS quando informado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasExistingFgts: true,
          existingFgtsAmount: 5000.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final fgtsPenalty = result.additions.firstWhere((item) => item.description == 'Multa FGTS (40%)');

        // Multa: 5000 * 0.4 = 2000
        expect(fgtsPenalty.value, 2000.0);
      });

      test('não deve incluir multa FGTS para pedido de demissão', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.resignation);
        final fgtsPenalty = result.additions.where((item) => item.description.contains('Multa FGTS'));

        expect(fgtsPenalty.length, 0);
      });
    });

    group('Descontos INSS e IRRF', () {
      test('deve calcular descontos corretamente', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        final inss = result.deductions.firstWhere((item) => item.description == 'INSS');
        final irrf = result.deductions.firstWhere((item) => item.description == 'IRRF');

        // INSS: 3500 * 0.12 = 420
        expect(inss.value, 420.0);

        // IRRF: (3500 - 420) * 0.075 - 169.44 = 80.56
        expect(irrf.value, closeTo(80.56, 0.01));
      });

      test('não deve calcular impostos quando desabilitado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          calculateTaxes: false,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        final inss = result.deductions.where((item) => item.description == 'INSS');
        final irrf = result.deductions.where((item) => item.description == 'IRRF');

        expect(inss.length, 0);
        expect(irrf.length, 0);
      });
    });

    group('Outros Descontos', () {
      test('deve incluir outros descontos quando informados', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          otherDiscounts: 200.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final otherDiscounts = result.deductions.firstWhere((item) => item.description == 'Outros Descontos');

        expect(otherDiscounts.value, 200.0);
        expect(otherDiscounts.details, 'Descontos diversos');
      });

      test('não deve incluir outros descontos quando zero', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          otherDiscounts: 0.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final otherDiscounts = result.deductions.where((item) => item.description == 'Outros Descontos');

        expect(otherDiscounts.length, 0);
      });
    });
  });
}
