import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';

void main() {
  group('CalculateTerminationUseCase', () {
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

    group('Sem Justa Causa', () {
      test('deve calcular rescisão sem justa causa com férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 3, 1),
          terminationDate: DateTime(2024, 9, 15),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect(
          (result.totalAdditions + result.fgtsDeposit.total),
          greaterThan(0),
        );
        expect(
          (result.paidAtTermination + result.fgtsDeposit.total),
          greaterThan(0),
        );

        // Verificar se tem multa FGTS
        final fgtsPenalty = result.fgtsDeposit.items.where(
          (item) => item.code == BreakdownCode.fgtsFine,
        );
        expect(fgtsPenalty.length, 1);
      });

      test('deve calcular rescisão sem justa causa sem férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 3, 1),
          terminationDate: DateTime(2024, 9, 15),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 2,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem férias vencidas
        final accruedVacation = result.additions.where(
          (item) => item.code == BreakdownCode.accruedVacationSimple,
        );
        expect(accruedVacation.length, 0);
      });
    });

    group('Pedido de Demissão', () {
      test('deve calcular rescisão por pedido de demissão', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 3, 1),
          terminationDate: DateTime(2024, 9, 15),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 1,
          noticeWorked: true,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.resignation);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem multa FGTS
        final fgtsPenalty = result.fgtsDeposit.items.where(
          (item) => item.code == BreakdownCode.fgtsFine,
        );
        expect(fgtsPenalty.length, 0);
      });
    });

    group('Prazo Determinado', () {
      test('deve calcular rescisão por prazo determinado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          vacationPeriodsTaken: 0,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.fixedTermEnd);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem multa FGTS
        final fgtsPenalty = result.fgtsDeposit.items.where(
          (item) => item.code == BreakdownCode.fgtsFine,
        );
        expect(fgtsPenalty.length, 0);
      });
    });

    group('Cálculos específicos', () {
      test('deve calcular saldo de salário corretamente', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 1, 15),
          baseSalary: 3000.0,
          workedDaysInMonth: 15,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final salaryBalance = result.additions
            .where((item) => item.code == BreakdownCode.salaryBalance)
            .first;

        expect(salaryBalance.value, 1500.0); // 3000 / 30 * 15
      });

      test('deve calcular 13º salário proporcional', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          noticeWorked:
              true, // sem projeção do aviso (C2), isola as avos do ano
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final thirteenthSalary = result.additions
            .where((item) => item.code == BreakdownCode.thirteenth)
            .first;

        // 6 meses trabalhados (jan-jun, junho conta porque >= 15 dias): (3000 + 500) * 6/12 = 1750.0
        expect(thirteenthSalary.value, closeTo(1750.0, 0.01));
      });
    });
  });
}
