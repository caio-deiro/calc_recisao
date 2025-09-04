import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/data/repositories/history_repository.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('History Functionality Tests', () {
    late HistoryRepository repository;

    setUp(() {
      repository = HistoryRepository();
    });

    tearDown(() async {
      // Limpar histórico após cada teste
      await repository.clearHistory();
    });

    test('should save and retrieve calculation history', () async {
      // Criar um input de teste
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 12, 31),
        baseSalary: 3000.0,
        averageAdditions: 500.0,
        hasAccruedVacation: true,
        workedDaysInMonth: 22,
        noticeWorked: false,
        hasExistingFgts: false,
        existingFgtsAmount: 0.0,
        dependents: 2,
        otherDiscounts: 100.0,
        calculateTaxes: true,
      );

      // Calcular resultado
      const useCase = CalculateTerminationUseCase();
      final result = useCase.execute(input, TerminationType.withoutJustCause);

      // Criar histórico
      final calculationHistory = CalculationHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        input: input,
        result: result,
        terminationType: TerminationType.withoutJustCause,
        timestamp: DateTime.now(),
      );

      // Salvar no histórico
      await repository.saveCalculation(calculationHistory);

      // Recuperar histórico
      final history = await repository.getHistory();

      // Verificar se foi salvo corretamente
      expect(history.length, 1);
      expect(history.first.id, calculationHistory.id);
      expect(history.first.input.baseSalary, 3000.0);
      expect(history.first.terminationType, TerminationType.withoutJustCause);
      expect(history.first.result.netAmount, result.netAmount);
    });

    test('should maintain history order (newest first)', () async {
      // Criar múltiplos cálculos
      final inputs = [
        TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 2000.0,
        ),
        TerminationInput(
          admissionDate: DateTime(2023, 6, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 3000.0,
        ),
        TerminationInput(
          admissionDate: DateTime(2024, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 4000.0,
        ),
      ];

      const useCase = CalculateTerminationUseCase();

      // Salvar múltiplos cálculos com delay para garantir ordem
      for (int i = 0; i < inputs.length; i++) {
        final result = useCase.execute(inputs[i], TerminationType.withoutJustCause);

        final calculationHistory = CalculationHistory(
          id: 'test_$i',
          input: inputs[i],
          result: result,
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now().add(Duration(seconds: i)),
        );

        await repository.saveCalculation(calculationHistory);
      }

      // Recuperar histórico
      final history = await repository.getHistory();

      // Verificar ordem (mais recente primeiro)
      expect(history.length, 3);
      expect(history[0].input.baseSalary, 4000.0); // Mais recente
      expect(history[1].input.baseSalary, 3000.0);
      expect(history[2].input.baseSalary, 2000.0); // Mais antigo
    });

    test('should limit history to maximum size', () async {
      const useCase = CalculateTerminationUseCase();

      // Criar mais cálculos que o limite máximo (50)
      for (int i = 0; i < 60; i++) {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 1000.0 + i,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        final calculationHistory = CalculationHistory(
          id: 'test_$i',
          input: input,
          result: result,
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now().add(Duration(seconds: i)),
        );

        await repository.saveCalculation(calculationHistory);
      }

      // Recuperar histórico
      final history = await repository.getHistory();

      // Verificar se respeitou o limite de 50
      expect(history.length, 50);

      // Verificar se manteve os mais recentes
      expect(history.first.input.baseSalary, 1059.0); // Último adicionado
      expect(history.last.input.baseSalary, 1010.0); // 50º mais recente
    });

    test('should clear history completely', () async {
      // Adicionar alguns cálculos
      const useCase = CalculateTerminationUseCase();

      for (int i = 0; i < 5; i++) {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 2000.0 + i * 500,
        );

        final result = useCase.execute(input, TerminationType.withoutJustCause);

        final calculationHistory = CalculationHistory(
          id: 'test_$i',
          input: input,
          result: result,
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now(),
        );

        await repository.saveCalculation(calculationHistory);
      }

      // Verificar que existem cálculos
      var history = await repository.getHistory();
      expect(history.length, 5);

      // Limpar histórico
      await repository.clearHistory();

      // Verificar que está vazio
      history = await repository.getHistory();
      expect(history.length, 0);
    });

    test('should handle different termination types', () async {
      const useCase = CalculateTerminationUseCase();
      final types = [TerminationType.withoutJustCause, TerminationType.resignation, TerminationType.fixedTerm];

      // Criar um cálculo para cada tipo
      for (int i = 0; i < types.length; i++) {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 12, 31),
          baseSalary: 3000.0,
        );

        final result = useCase.execute(input, types[i]);

        final calculationHistory = CalculationHistory(
          id: 'test_${types[i].name}',
          input: input,
          result: result,
          terminationType: types[i],
          timestamp: DateTime.now().add(Duration(seconds: i)),
        );

        await repository.saveCalculation(calculationHistory);
      }

      // Recuperar histórico
      final history = await repository.getHistory();

      // Verificar se todos os tipos foram salvos
      expect(history.length, 3);
      expect(history.map((h) => h.terminationType).toSet(), types.toSet());
    });
  });
}
