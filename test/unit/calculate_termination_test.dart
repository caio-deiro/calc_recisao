import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';

void main() {
  group('CalculateTerminationUseCase', () {
    late CalculateTerminationUseCase useCase;

    setUp(() {
      useCase = const CalculateTerminationUseCase();
    });

    group('Sem Justa Causa', () {
      test('deve calcular rescisão sem justa causa com férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 3, 1),
          terminationDate: DateTime(2024, 9, 15),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          hasAccruedVacation: true,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect(result.totalToReceive, greaterThan(0));
        expect(result.netAmount, greaterThan(0));

        // Verificar se tem multa FGTS
        final fgtsPenalty = result.additions.where((item) => item.description.contains('Multa FGTS'));
        expect(fgtsPenalty.length, 1);
      });

      test('deve calcular rescisão sem justa causa sem férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 3, 1),
          terminationDate: DateTime(2024, 9, 15),
          baseSalary: 3500.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem férias vencidas
        final accruedVacation = result.additions.where((item) => item.description.contains('Férias Vencidas'));
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
          hasAccruedVacation: true,
          noticeWorked: true,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.resignation);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem multa FGTS
        final fgtsPenalty = result.additions.where((item) => item.description.contains('Multa FGTS'));
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
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.fixedTerm);

        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));

        // Verificar se não tem multa FGTS
        final fgtsPenalty = result.additions.where((item) => item.description.contains('Multa FGTS'));
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
        final salaryBalance = result.additions.where((item) => item.description.contains('Saldo de Salário')).first;

        expect(salaryBalance.value, 1500.0); // 3000 / 30 * 15
      });

      test('deve calcular 13º salário proporcional', () {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final thirteenthSalary = result.additions.where((item) => item.description.contains('13º Salário')).first;

        // 5 meses trabalhados: (3000 + 500) * 5/12 = 1458.33
        expect(thirteenthSalary.value, closeTo(1458.33, 0.01));
      });
    });
  });
}
