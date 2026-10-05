import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/form/form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/result_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpForm(
    WidgetTester tester, {
    Size size = const Size(800, 2400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: FormScreen(terminationType: TerminationType.withoutJustCause),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  Future<void> typeDate(WidgetTester tester, String id, String digits) async {
    final field = find.descendant(
      of: byId(id),
      matching: find.byType(TextFormField),
    );
    // Limpa antes (como o backspace): o formatador só mascara texto que cresce.
    await tester.enterText(field, '');
    await tester.pumpAndSettle();
    await tester.enterText(field, digits);
    await tester.pumpAndSettle();
  }

  Finder button(String id) =>
      find.descendant(of: byId(id), matching: find.byType(IconButton));
  Finder value(String text) => find.descendant(
    of: byId('form_vacation_taken'),
    matching: find.text(text),
  );

  Future<void> tapIncrement(WidgetTester tester) async {
    await tester.tap(button('form_vacation_taken_increment'));
    await tester.pumpAndSettle();
  }

  Future<void> tapDecrement(WidgetTester tester) async {
    await tester.tap(button('form_vacation_taken_decrement'));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String id) =>
      tester.widget<IconButton>(button(id)).onPressed != null;

  group('Formulário: períodos de férias gozados', () {
    testWidgets(
      'deve mostrar o aviso e o stepper desabilitado em 0 sem datas',
      (tester) async {
        await pumpForm(tester);

        expect(byId('form_vacation_warning'), findsOneWidget);
        expect(find.textContaining('abono pecuniário'), findsOneWidget);
        expect(value('0'), findsOneWidget);
        expect(enabled(tester, 'form_vacation_taken_increment'), isFalse);
        expect(enabled(tester, 'form_vacation_taken_decrement'), isFalse);
      },
    );

    testWidgets('deve acompanhar n até o toque e respeitar o limite [0, n]', (
      tester,
    ) async {
      await pumpForm(tester);
      await typeDate(tester, 'form_admission_date', '15062022');
      await typeDate(tester, 'form_termination_date', '15062025'); // n = 3

      expect(value('3'), findsOneWidget);
      expect(enabled(tester, 'form_vacation_taken_increment'), isFalse);

      await tapDecrement(tester);
      await tapDecrement(tester);
      await tapDecrement(tester);
      expect(value('0'), findsOneWidget);
      expect(enabled(tester, 'form_vacation_taken_decrement'), isFalse);

      await tapIncrement(tester);
      expect(value('1'), findsOneWidget);
    });

    testWidgets('deve reduzir o valor ao mudar a rescisão para n menor', (
      tester,
    ) async {
      await pumpForm(tester);
      await typeDate(tester, 'form_admission_date', '15062022');
      await typeDate(tester, 'form_termination_date', '15062025');
      expect(value('3'), findsOneWidget);

      await typeDate(tester, 'form_termination_date', '15062024'); // n = 2
      expect(value('2'), findsOneWidget);
    });

    testWidgets('deve manter o valor tocado enquanto couber em n', (
      tester,
    ) async {
      await pumpForm(tester);
      await typeDate(tester, 'form_admission_date', '15062022');
      await typeDate(tester, 'form_termination_date', '15062025');
      await tapDecrement(tester); // 2, tocado

      await typeDate(tester, 'form_termination_date', '15062026'); // n = 4
      expect(value('2'), findsOneWidget);
      await typeDate(tester, 'form_termination_date', '15062023'); // n = 1
      expect(value('1'), findsOneWidget);
    });

    testWidgets('deve voltar a 0 e desabilitar com data incompleta', (
      tester,
    ) async {
      await pumpForm(tester);
      await typeDate(tester, 'form_admission_date', '15062022');
      await typeDate(tester, 'form_termination_date', '15062025');
      await typeDate(tester, 'form_termination_date', '1506');

      expect(value('0'), findsOneWidget);
      expect(enabled(tester, 'form_vacation_taken_increment'), isFalse);
    });

    testWidgets('deve caber em tela pequena sem exceção', (tester) async {
      await pumpForm(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
    });
  });
}
