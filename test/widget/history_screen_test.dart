import 'package:calc_recisao/data/repositories/history_repository.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/history/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> seed(int count) async {
    SharedPreferences.setMockInitialValues({});
    final repository = HistoryRepository();
    final input = TerminationInput(
      admissionDate: DateTime(2023, 1, 1),
      terminationDate: DateTime(2024, 6, 30),
      baseSalary: 3000,
    );
    final result = TerminationResult(
      additions: const <BreakdownItem>[],
      deductions: const <BreakdownItem>[],
      totalToReceive: 1000,
      totalDeductions: 0,
      netAmount: 1000,
      calculationDate: DateTime(2024, 6, 30),
    );
    for (int i = 0; i < count; i++) {
      await repository.saveCalculation(
        CalculationHistory(
          id: 'calc_$i',
          input: input,
          result: result,
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime(2024, 1, 1).add(Duration(minutes: i)),
        ),
      );
    }
  }

  Future<void> pumpHistory(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('Aviso de histórico quase cheio (B1-09)', () {
    testWidgets('deve aparecer com 90 itens', (tester) async {
      await tester.runAsync(() => seed(90));
      await pumpHistory(tester);

      expect(find.textContaining('Histórico quase cheio'), findsOneWidget);
    });

    testWidgets('não deve aparecer com 89 itens', (tester) async {
      await tester.runAsync(() => seed(89));
      await pumpHistory(tester);

      expect(find.textContaining('Histórico quase cheio'), findsNothing);
    });

    testWidgets('não deve exibir card de upgrade PRO', (tester) async {
      await tester.runAsync(() => seed(3));
      await pumpHistory(tester);

      expect(find.textContaining('PRO'), findsNothing);
      expect(find.text('Upgrade'), findsNothing);
    });
  });

  group('Histórico compatível (B2-11)', () {
    testWidgets('deve marcar registro legado como calculado em versão anterior', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({
          'calculation_history': [
            '{"id":"l1","input":{"admissionDate":"2023-01-01T00:00:00.000","terminationDate":"2024-06-30T00:00:00.000","baseSalary":3000.0},'
                '"result":{"additions":[],"deductions":[],"totalToReceive":1000.0,"totalDeductions":0.0,"netAmount":1000.0,"calculationDate":"2024-06-30T00:00:00.000"},'
                '"terminationType":"withoutJustCause","timestamp":"2024-06-30T00:00:00.000","note":null}',
          ],
        });
      });
      await pumpHistory(tester);

      expect(find.text('Calculado em versão anterior'), findsOneWidget);
    });

    testWidgets('não deve marcar registro novo como versão anterior', (tester) async {
      await tester.runAsync(() => seed(1));
      await pumpHistory(tester);

      expect(find.text('Calculado em versão anterior'), findsNothing);
    });

    testWidgets('deve avisar quantos registros ilegíveis foram mantidos', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({
          'calculation_history': ['{lixo'],
        });
      });
      await pumpHistory(tester);

      expect(find.textContaining('1 registro não pôde ser lido'), findsOneWidget);
    });
  });
}
