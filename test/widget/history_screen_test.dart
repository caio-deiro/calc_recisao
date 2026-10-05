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
}
