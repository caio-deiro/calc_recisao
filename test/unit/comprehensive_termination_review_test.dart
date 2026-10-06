import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('Revisão Completa - Todas as Modalidades de Rescisão', () {
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

    group('1. SEM JUSTA CAUSA (Demissão pelo Empregador)', () {
      test('deve calcular rescisão sem justa causa - 1 ano', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        // Teste de rescisão sem justa causa - 1 ano
        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para sem justa causa
        // FGTS não é pago na rescisão, apenas a multa
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isTrue,
        );
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isTrue,
        );
      });

      test('deve calcular rescisão sem justa causa - 3 anos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2021, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 5000.0,
          averageAdditions: 1000.0,
          vacationPeriodsTaken: 3,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para sem justa causa
        // FGTS não é pago na rescisão, apenas a multa
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isTrue,
        );
      });
    });

    group('2. PEDIDO DE DEMISSÃO (Demissão pelo Funcionário)', () {
      test('deve calcular rescisão por pedido de demissão - 1 ano', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.resignation);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para pedido de demissão
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isFalse,
        );
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isFalse,
        );
        expect(
          result.deductions.any(
            (item) => item.code == BreakdownCode.noticeDiscount,
          ),
          isTrue,
        );
      });
    });

    group('3. CONTRATO POR PRAZO DETERMINADO', () {
      test('deve calcular rescisão por prazo determinado - 6 meses', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 7, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 4000.0,
          averageAdditions: 0.0,
          vacationPeriodsTaken: 0,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.fixedTermEnd);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para prazo determinado
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isFalse,
        );
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isFalse,
        );
        // Rescisão em 01/01/2024: o dia 1 não completa 15 dias, então 13º = 0 (Lei 4.090/62 art. 1º §2º).
        expect(
          result.additions.any((item) => item.code == BreakdownCode.thirteenth),
          isFalse,
        );
        // C3: 01/07/2023 a 01/01/2024 = 6 avos de férias: 4000 x 6/12 x 4/3 = 2666,67 (CLT art. 146 parágrafo único).
        final vacation = result.additions.firstWhere(
          (item) => item.code == BreakdownCode.proportionalVacation,
        );
        expect(vacation.value, closeTo(2666.67, 0.01));
      });
    });

    group('4. COM JUSTA CAUSA (Demissão por Falta Grave)', () {
      test('deve calcular rescisão com justa causa - 2 anos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3500.0,
          averageAdditions: 300.0,
          vacationPeriodsTaken: 2,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para com justa causa
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isFalse,
        );
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isFalse,
        );
        // Com justa causa pode ter valor negativo devido aos descontos
        expect(
          (result.paidAtTermination + result.fgtsDeposit.total),
          lessThan(1000),
        );
      });
    });

    group('5. ACORDO MÚTUO', () {
      test('deve calcular rescisão por acordo mútuo - 1 ano', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.mutualAgreement);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para acordo mútuo
        // FGTS não é pago na rescisão, apenas a multa
        expect(
          result.additions.any((item) => item.code == BreakdownCode.fgtsFine),
          isFalse,
        );
        expect(
          result.fgtsDeposit.items.any(
            (item) => item.code == BreakdownCode.fgtsFine,
          ),
          isTrue,
        );
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isTrue,
        );
      });
    });

    group('6. COMPARAÇÃO ENTRE MODALIDADES', () {
      test('deve comparar valores entre diferentes modalidades', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final withoutJustCause = useCase.execute(
          input,
          TerminationType.withoutJustCause,
        );
        final resignationInput = TerminationInput(
          admissionDate: input.admissionDate,
          terminationDate: input.terminationDate,
          baseSalary: input.baseSalary,
          averageAdditions: input.averageAdditions,
          vacationPeriodsTaken: input.vacationPeriodsTaken,
          noticeWorked: true,
          calculateTaxes: input.calculateTaxes,
        );
        final resignation = useCase.execute(
          resignationInput,
          TerminationType.resignation,
        );
        final fixedTerm = useCase.execute(input, TerminationType.fixedTermEnd);
        final withJustCause = useCase.execute(
          input,
          TerminationType.withJustCause,
        );
        final mutualAgreement = useCase.execute(
          input,
          TerminationType.mutualAgreement,
        );

        // Verificações de hierarquia esperada
        expect(
          (withoutJustCause.paidAtTermination +
              withoutJustCause.fgtsDeposit.total),
          greaterThan(
            (resignation.paidAtTermination + resignation.fgtsDeposit.total),
          ),
        );
        expect(
          (withoutJustCause.paidAtTermination +
              withoutJustCause.fgtsDeposit.total),
          greaterThan(
            (fixedTerm.paidAtTermination + fixedTerm.fgtsDeposit.total),
          ),
        );
        expect(
          (withoutJustCause.paidAtTermination +
              withoutJustCause.fgtsDeposit.total),
          greaterThan(
            (withJustCause.paidAtTermination + withJustCause.fgtsDeposit.total),
          ),
        );
        expect(
          (withoutJustCause.paidAtTermination +
              withoutJustCause.fgtsDeposit.total),
          greaterThan(
            (mutualAgreement.paidAtTermination +
                mutualAgreement.fgtsDeposit.total),
          ),
        );

        // Em 01/01/2024 o 13º e as férias do período novo valem zero (menos de 15 dias), então empatam.
        expect(
          (resignation.paidAtTermination + resignation.fgtsDeposit.total),
          greaterThanOrEqualTo(
            (withJustCause.paidAtTermination + withJustCause.fgtsDeposit.total),
          ),
        );
        expect(
          (fixedTerm.paidAtTermination + fixedTerm.fgtsDeposit.total),
          greaterThanOrEqualTo(
            (withJustCause.paidAtTermination + withJustCause.fgtsDeposit.total),
          ),
        );
        expect(
          (mutualAgreement.paidAtTermination +
              mutualAgreement.fgtsDeposit.total),
          greaterThan(
            (withJustCause.paidAtTermination + withJustCause.fgtsDeposit.total),
          ),
        );

        // Verificar que com justa causa e prazo determinado têm valores baixos/negativos
        expect(
          (withJustCause.paidAtTermination + withJustCause.fgtsDeposit.total),
          lessThan(1000),
        );
        expect(
          (fixedTerm.paidAtTermination + fixedTerm.fgtsDeposit.total),
          lessThan(1000),
        );
      });
    });

    group('7. CASOS ESPECIAIS', () {
      test('deve calcular com férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 0,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        // Verificações específicas para férias vencidas e proporcionais
        expect(
          result.additions.any(
            (item) => item.code == BreakdownCode.accruedVacationSimple,
          ),
          isTrue,
        );
        expect(
          result.additions.any(
            (item) => item.code == BreakdownCode.proportionalVacation,
          ),
          isTrue,
        );
      });

      test('deve calcular com aviso prévio trabalhado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: true, // Aviso prévio trabalhado
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        // Verificações específicas para aviso prévio trabalhado
        expect(
          result.additions.any((item) => item.code == BreakdownCode.notice),
          isFalse,
        );
      });
    });
  });
}
