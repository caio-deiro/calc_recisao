import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calc_recisao/data/repositories/history_repository.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';

void main() {
  group('HistoryRepository Tests', () {
    late HistoryRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = HistoryRepository();
    });

    tearDown(() async {
      await repository.clearHistory();
    });

    group('getHistory', () {
      test('deve retornar lista vazia quando não há histórico', () async {
        final history = await repository.getHistory();
        expect(history, isEmpty);
      });

      test('deve retornar histórico ordenado por timestamp (mais recente primeiro)', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 200.0,
          netAmount: 800.0,
          calculationDate: DateTime.now(),
        );

        // Adicionar cálculos com timestamps diferentes
        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_1',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime(2024, 1, 1),
          ),
        );

        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_2',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime(2024, 2, 1),
          ),
        );

        final history = await repository.getHistory();
        expect(history.length, 2);
        expect(history[0].id, 'calc_2'); // Mais recente primeiro
        expect(history[1].id, 'calc_1');
      });

      test('deve ignorar itens inválidos no histórico', () async {
        // Simular histórico com JSON inválido
        SharedPreferences.setMockInitialValues({
          'calculation_history': ['{"invalid": "json"}', '{"id": null}'],
        });

        final history = await repository.getHistory();
        // Deve retornar lista vazia ou apenas itens válidos
        expect(history, isA<List<CalculationHistory>>());
      });
    });

    group('saveCalculation', () {
      test('deve salvar cálculo no histórico', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [
            BreakdownItem(
              description: 'Saldo de Salário',
              value: 1000.0,
              type: BreakdownType.addition,
            ),
          ],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

        final calculation = CalculationHistory(
          id: 'test_calc',
          input: input,
          result: result,
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now(),
        );

        await repository.saveCalculation(calculation);

        final history = await repository.getHistory();
        expect(history.length, 1);
        expect(history.first.id, 'test_calc');
        expect(history.first.input.baseSalary, 5000.0);
      });

      test('deve adicionar novo cálculo no início da lista', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

        // Adicionar primeiro cálculo
        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_1',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime(2024, 1, 1),
          ),
        );

        // Adicionar segundo cálculo (mais recente)
        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_2',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime(2024, 2, 1),
          ),
        );

        final history = await repository.getHistory();
        expect(history.length, 2);
        expect(history.first.id, 'calc_2'); // Mais recente primeiro
      });
    });

    group('deleteCalculation', () {
      test('deve deletar cálculo específico do histórico', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

        // Adicionar dois cálculos
        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_1',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now(),
          ),
        );

        await repository.saveCalculation(
          CalculationHistory(
            id: 'calc_2',
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now().add(Duration(seconds: 1)),
          ),
        );

        // Deletar um
        await repository.deleteCalculation('calc_1');

        final history = await repository.getHistory();
        expect(history.length, 1);
        expect(history.first.id, 'calc_2');
      });

      test('deve não fazer nada se cálculo não existe', () async {
        await repository.deleteCalculation('non_existent');

        final history = await repository.getHistory();
        expect(history, isEmpty);
      });
    });

    group('clearHistory', () {
      test('deve limpar todo o histórico', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

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
        expect(history, isEmpty);
      });
    });

    group('addNote', () {
      test('deve adicionar nota a cálculo existente', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

        final calculationId = 'test_calc';

        await repository.saveCalculation(
          CalculationHistory(
            id: calculationId,
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now(),
          ),
        );

        // Adicionar nota
        await repository.addNote(calculationId, 'Nota de teste');

        final history = await repository.getHistory();
        expect(history.first.note, 'Nota de teste');
      });

      test('deve atualizar nota existente', () async {
        final input = TerminationInput(
          admissionDate: DateTime(2023, 1, 1),
          terminationDate: DateTime(2024, 6, 30),
          baseSalary: 5000.0,
          calculateTaxes: true,
        );

        final result = TerminationResult(
          additions: [],
          deductions: [],
          totalToReceive: 1000.0,
          totalDeductions: 0.0,
          netAmount: 1000.0,
          calculationDate: DateTime.now(),
        );

        final calculationId = 'test_calc';

        await repository.saveCalculation(
          CalculationHistory(
            id: calculationId,
            input: input,
            result: result,
            terminationType: TerminationType.withoutJustCause,
            timestamp: DateTime.now(),
            note: 'Nota original',
          ),
        );

        // Atualizar nota
        await repository.addNote(calculationId, 'Nota atualizada');

        final history = await repository.getHistory();
        expect(history.first.note, 'Nota atualizada');
      });

      test('deve não fazer nada se cálculo não existe', () async {
        await repository.addNote('non_existent', 'Nota');

        final history = await repository.getHistory();
        expect(history, isEmpty);
      });
    });
  });
}

