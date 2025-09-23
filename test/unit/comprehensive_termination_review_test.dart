import 'package:flutter_test/flutter_test.dart';
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
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        // Teste de rescisão sem justa causa - 1 ano
        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para sem justa causa
        expect(result.additions.any((item) => item.description == 'FGTS'), isTrue);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isTrue);
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isTrue);
      });

      test('deve calcular rescisão sem justa causa - 3 anos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2021, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 5000.0,
          averageAdditions: 1000.0,
          hasAccruedVacation: false,
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
        expect(result.additions.any((item) => item.description == 'FGTS'), isTrue);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isTrue);
      });
    });

    group('2. PEDIDO DE DEMISSÃO (Demissão pelo Funcionário)', () {
      test('deve calcular rescisão por pedido de demissão - 1 ano', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
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
        expect(result.additions.any((item) => item.description == 'FGTS'), isFalse);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isFalse);
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isTrue);
      });
    });

    group('3. CONTRATO POR PRAZO DETERMINADO', () {
      test('deve calcular rescisão por prazo determinado - 6 meses', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 7, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 4000.0,
          averageAdditions: 0.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.fixedTerm);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        for (final deduction in result.deductions) {
          if (deduction.details != null) {}
        }

        // Verificações específicas para prazo determinado
        expect(result.additions.any((item) => item.description == 'FGTS'), isFalse);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isFalse);
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isFalse);
        // Prazo determinado pode ter valor negativo devido aos descontos
        expect(result.netAmount, lessThan(1000));
      });
    });

    group('4. COM JUSTA CAUSA (Demissão por Falta Grave)', () {
      test('deve calcular rescisão com justa causa - 2 anos', () {
        final input = TerminationInput(
          admissionDate: DateTime(2022, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3500.0,
          averageAdditions: 300.0,
          hasAccruedVacation: false,
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
        expect(result.additions.any((item) => item.description == 'FGTS'), isFalse);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isFalse);
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isFalse);
        // Com justa causa pode ter valor negativo devido aos descontos
        expect(result.netAmount, lessThan(1000));
      });
    });

    group('5. ACORDO MÚTUO', () {
      test('deve calcular rescisão por acordo mútuo - 1 ano', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
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
        expect(result.additions.any((item) => item.description == 'FGTS'), isTrue);
        expect(result.additions.any((item) => item.description == 'Multa FGTS (20%)'), isTrue);
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado (50%)'), isTrue);
      });
    });

    group('6. COMPARAÇÃO ENTRE MODALIDADES', () {
      test('deve comparar valores entre diferentes modalidades', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final withoutJustCause = useCase.execute(input, TerminationType.withoutJustCause);
        final resignation = useCase.execute(input, TerminationType.resignation);
        final fixedTerm = useCase.execute(input, TerminationType.fixedTerm);
        final withJustCause = useCase.execute(input, TerminationType.withJustCause);
        final mutualAgreement = useCase.execute(input, TerminationType.mutualAgreement);

        // Verificações de hierarquia esperada
        expect(withoutJustCause.netAmount, greaterThan(resignation.netAmount));
        expect(withoutJustCause.netAmount, greaterThan(fixedTerm.netAmount));
        expect(withoutJustCause.netAmount, greaterThan(withJustCause.netAmount));
        expect(withoutJustCause.netAmount, greaterThan(mutualAgreement.netAmount));

        expect(resignation.netAmount, greaterThan(withJustCause.netAmount));
        expect(fixedTerm.netAmount, greaterThanOrEqualTo(withJustCause.netAmount));
        expect(mutualAgreement.netAmount, greaterThan(withJustCause.netAmount));

        // Verificar que com justa causa e prazo determinado têm valores baixos/negativos
        expect(withJustCause.netAmount, lessThan(1000));
        expect(fixedTerm.netAmount, lessThan(1000));
      });
    });

    group('7. CASOS ESPECIAIS', () {
      test('deve calcular com férias vencidas', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: true, // Férias vencidas
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        // Verificações específicas para férias vencidas
        expect(result.additions.any((item) => item.description == 'Férias Vencidas + 1/3'), isTrue);
        expect(result.additions.any((item) => item.description == 'Férias Proporcionais + 1/3'), isFalse);
      });

      test('deve calcular com aviso prévio trabalhado', () {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 1, 1),
          baseSalary: 3000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          noticeWorked: true, // Aviso prévio trabalhado
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        for (final addition in result.additions) {
          if (addition.details != null) {}
        }

        // Verificações específicas para aviso prévio trabalhado
        expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isFalse);
      });
    });
  });
}
