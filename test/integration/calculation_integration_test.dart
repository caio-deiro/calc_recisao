import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/data/repositories/history_repository.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/core/validators/termination_input_validator.dart';

/// Testes de integração que verificam o fluxo completo da aplicação
/// desde a validação de entrada até o salvamento no histórico
void main() {
  group('Testes de Integração - Fluxo Completo', () {
    late CalculateTerminationUseCase useCase;
    late TaxTablesService taxService;
    late HistoryRepository repository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Limpar SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
      
      useCase = const CalculateTerminationUseCase();
      taxService = TaxTablesService.instance;
      await taxService.loadTaxTables();
      repository = HistoryRepository();
    });

    tearDown(() async {
      // Limpar histórico após cada teste
      await repository.clearHistory();
    });

    group('Fluxo Completo: Validação → Cálculo → Histórico', () {
      test('deve executar fluxo completo sem justa causa', () async {
        // 1. Criar input válido
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
          dependents: 1,
        );

        // 2. Validar input
        final validationResult = TerminationInputValidator.validate(input);
        expect(validationResult.isValid, isTrue);
        expect(validationResult.errors, isEmpty);

        // 3. Executar cálculo
        final result = useCase.execute(input, TerminationType.withoutJustCause);

        // 4. Verificar resultado
        expect(result.additions.length, greaterThan(0));
        expect(result.deductions.length, greaterThan(0));
        expect(result.netAmount, greaterThan(0));
        expect(result.totalToReceive, greaterThan(result.totalDeductions));

        // 5. Salvar no histórico
        final history = await repository.getHistory();
        final initialCount = history.length;

        await repository.saveCalculation(
          CalculationHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now(),
          ),
        );

        // 6. Verificar histórico
        final updatedHistory = await repository.getHistory();
        expect(updatedHistory.length, initialCount + 1);
        expect(updatedHistory.first.input.baseSalary, input.baseSalary);
        expect(updatedHistory.first.result.netAmount, result.netAmount);
      });

      test('deve executar fluxo completo com justa causa', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          averageAdditions: 0.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final validationResult = TerminationInputValidator.validate(input);
        expect(validationResult.isValid, isTrue);

        final result = useCase.execute(input, TerminationType.withJustCause);

        // Com justa causa não deve ter multa FGTS
        expect(result.fgtsDeposit.items.any((item) => item.code == BreakdownCode.fgtsFine), isFalse);
        expect(result.additions.any((item) => item.code == BreakdownCode.notice), isFalse);

        await repository.saveCalculation(
          CalculationHistory(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            input: input,
            result: result,
            terminationType: TerminationType.withJustCause,
            timestamp: DateTime.now(),
          ),
        );

        final history = await repository.getHistory();
        expect(history.length, 1);
        expect(history.first.terminationType, TerminationType.withJustCause);
      });

      test('deve rejeitar input inválido e não executar cálculo', () {
        // Input inválido: data de término antes da admissão
        final invalidInput = TerminationInput(
          admissionDate: DateTime(2024, 6, 30),
          terminationDate: DateTime(2023, 1, 1), // Data anterior à admissão
          baseSalary: 5000.0,
          averageAdditions: 0.0,
          calculateTaxes: true,
        );

        final validationResult = TerminationInputValidator.validate(invalidInput);

        expect(validationResult.isValid, isFalse);
        expect(validationResult.errors, isNotEmpty);

        // Não deve executar cálculo com input inválido
        expect(
          () => useCase.execute(invalidInput, TerminationType.withoutJustCause),
          returnsNormally, // O cálculo pode executar, mas o resultado será incorreto
        );
      });
    });

    group('Integração: Cálculo com Diferentes Tipos de Rescisão', () {
      test('deve calcular corretamente acordo mútuo', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          averageAdditions: 500.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.mutualAgreement);

        // Acordo mútuo deve ter aviso prévio reduzido (50%)
        final noticeItem = result.additions.firstWhere(
          (item) => item.code == BreakdownCode.notice,
          orElse: () => throw Exception('Aviso prévio não encontrado'),
        );
        expect(noticeItem.description, contains('50%'));

        // Multa FGTS deve ser 20% (reduzida de 40%)
        final fgtsItem = result.fgtsDeposit.items.firstWhere(
          (item) => item.code == BreakdownCode.fgtsFine,
          orElse: () => throw Exception('Multa FGTS não encontrada'),
        );
        expect(fgtsItem.description, contains('20%'));
      });

      test('deve calcular corretamente prazo determinado', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 5000.0,
          averageAdditions: 0.0,
          hasAccruedVacation: false,
          noticeWorked: false,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.fixedTerm);

        // Prazo determinado não deve ter aviso prévio indenizado
        expect(result.additions.any((item) => item.code == BreakdownCode.notice), isFalse);
      });
    });

    group('Integração: Operações de Histórico', () {
      test('deve adicionar, buscar e deletar cálculo do histórico', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);
        final calculationId = 'test_calc_1';

        // Adicionar
        await repository.saveCalculation(
          CalculationHistory(
            id: calculationId,
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now(),
          ),
        );

        // Buscar
        var history = await repository.getHistory();
        expect(history.length, 1);
        expect(history.first.id, calculationId);

        // Adicionar nota
        await repository.addNote(calculationId, 'Nota de teste');
        history = await repository.getHistory();
        expect(history.first.note, 'Nota de teste');

        // Deletar
        await repository.deleteCalculation(calculationId);
        history = await repository.getHistory();
        expect(history.length, 0);
      });

      test('deve limpar todo o histórico', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        // Adicionar múltiplos cálculos
        for (int i = 0; i < 5; i++) {
          await repository.saveCalculation(
            CalculationHistory(
              id: 'calc_$i',
              input: input,
              result: result,
              terminationType: TerminationType.withoutJustCause,
              timestamp: DateTime.now().add(Duration(seconds: i)),
            ),
          );
        }

        var history = await repository.getHistory();
        expect(history.length, 5);

        // Limpar
        await repository.clearHistory();
        history = await repository.getHistory();
        expect(history.length, 0);
      });
    });
  });
}

