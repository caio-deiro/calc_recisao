import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/form/form_screen.dart';
import 'package:calc_recisao/presentation/screens/home/home_screen.dart';
import 'package:calc_recisao/presentation/widgets/termination_type_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/result_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(800, 2400),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('Campos do formulário por tipo (B4-03, B4-09)', () {
    testWidgets(
      'deve mostrar fim previsto e cláusula na antecipada pelo empregado',
      (tester) async {
        await pump(
          tester,
          const FormScreen(
            terminationType: TerminationType.fixedTermEarlyByEmployee,
          ),
        );
        expect(byId('form_fixed_term_end'), findsOneWidget);
        expect(byId('form_recipient_clause_checkbox'), findsOneWidget);
      },
    );

    testWidgets(
      'deve mostrar fim previsto e cláusula na antecipada pelo empregador',
      (tester) async {
        await pump(
          tester,
          const FormScreen(
            terminationType: TerminationType.fixedTermEarlyByEmployer,
          ),
        );
        expect(byId('form_fixed_term_end'), findsOneWidget);
        expect(byId('form_recipient_clause_checkbox'), findsOneWidget);
      },
    );

    testWidgets('deve mostrar só o fim previsto no término normal', (
      tester,
    ) async {
      await pump(
        tester,
        const FormScreen(terminationType: TerminationType.fixedTermEnd),
      );
      expect(byId('form_fixed_term_end'), findsOneWidget);
      expect(byId('form_recipient_clause_checkbox'), findsNothing);
    });

    for (final type in [
      TerminationType.withoutJustCause,
      TerminationType.indirectTermination,
      TerminationType.resignation,
      TerminationType.withJustCause,
      TerminationType.mutualAgreement,
    ]) {
      testWidgets('deve esconder fim previsto e cláusula em ${type.name}', (
        tester,
      ) async {
        await pump(tester, FormScreen(terminationType: type));
        expect(byId('form_fixed_term_end'), findsNothing);
        expect(byId('form_recipient_clause_checkbox'), findsNothing);
      });
    }

    testWidgets('deve funcionar em tela pequena e grande', (tester) async {
      for (final size in [const Size(360, 640), const Size(1024, 1400)]) {
        await pump(
          tester,
          const FormScreen(
            terminationType: TerminationType.fixedTermEarlyByEmployer,
          ),
          size: size,
        );
        expect(byId('form_fixed_term_end'), findsOneWidget);
      }
    });

    testWidgets(
      'deve exibir o aviso do término normal sem bloquear, quando as datas diferem',
      (tester) async {
        await pump(
          tester,
          const FormScreen(terminationType: TerminationType.fixedTermEnd),
        );
        Future<void> type(String id, String digits) async {
          final field = find.descendant(
            of: byId(id),
            matching: find.byType(TextFormField),
          );
          // Limpa antes: o formatador só mascara texto que cresce.
          await tester.enterText(field, '');
          await tester.pumpAndSettle();
          await tester.enterText(field, digits);
          await tester.pumpAndSettle();
        }

        await type('form_termination_date', '10062024');
        await type('form_fixed_term_end', '10062024');
        expect(byId('form_fixed_term_warning'), findsNothing);
        await type('form_fixed_term_end', '30062024');
        expect(byId('form_fixed_term_warning'), findsOneWidget);
      },
    );

    testWidgets('deve alternar a cláusula assecuratória', (tester) async {
      await pump(
        tester,
        const FormScreen(
          terminationType: TerminationType.fixedTermEarlyByEmployer,
        ),
      );
      final box = find.descendant(
        of: byId('form_recipient_clause_checkbox'),
        matching: find.byType(CheckboxListTile),
      );
      expect(tester.widget<CheckboxListTile>(box).value, isFalse);
      await tester.tap(box);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(box).value, isTrue);
    });
  });

  group('Cards da tela inicial (B4-09)', () {
    testWidgets(
      'deve listar um card por tipo, sem o Prazo Determinado antigo',
      (tester) async {
        await pump(tester, const HomeScreen(), size: const Size(800, 4000));
        expect(
          find.byType(TerminationTypeCard),
          findsNWidgets(TerminationType.values.length),
        );
        expect(TerminationType.values, hasLength(8));
        for (final t in TerminationType.values) {
          expect(byId('home_type_${t.name}'), findsOneWidget, reason: t.name);
        }
        expect(find.text('Prazo Determinado'), findsNothing);
        expect(byId('home_type_fixedTerm'), findsNothing);
      },
    );

    test('deve ter descrição simples, sem número de artigo', () {
      for (final t in TerminationType.values) {
        expect(t.description, isNotEmpty);
        expect(
          RegExp(
            r'art\.?\s*\d',
            caseSensitive: false,
          ).hasMatch('${t.label} ${t.description}'),
          isFalse,
        );
      }
    });
  });
}
