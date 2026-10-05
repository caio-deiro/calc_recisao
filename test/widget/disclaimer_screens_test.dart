import 'dart:convert';

import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/form/form_screen.dart';
import 'package:calc_recisao/presentation/screens/history/history_screen.dart';
import 'package:calc_recisao/presentation/screens/home/home_screen.dart';
import 'package:calc_recisao/presentation/screens/result/result_screen.dart';
import 'package:calc_recisao/presentation/widgets/disclaimer_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/result_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
  }

  group('Aviso legal (B5-04)', () {
    testWidgets('deve cobrir estimativa, TRCT, FGTS aproximado e feriados, faltas e licenças', (tester) async {
      await pump(tester, const Scaffold(body: DisclaimerWidget()));

      final text = (tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ')).toLowerCase();
      expect(text, contains('estimativa'));
      expect(text, contains('trct oficial'));
      expect(text, contains('aproximação'));
      expect(text, contains('feriados'));
      expect(text, contains('faltas'));
      expect(text, contains('licenças'));
      expect(text, isNot(contains('exat')));
      expect(text, isNot(contains('garant')));
    });

    testWidgets('deve estar na Home', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pump(tester, const HomeScreen());
      expect(find.byType(DisclaimerWidget), findsOneWidget);
    });

    testWidgets('deve estar no Formulário', (tester) async {
      await pump(tester, const FormScreen(terminationType: TerminationType.withoutJustCause));
      expect(find.byType(DisclaimerWidget), findsOneWidget);
    });

    testWidgets('deve estar no Resultado', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pump(tester, ResultScreen.fromHistory(savedRecord(TerminationType.withoutJustCause, fgts: 10000)));
      expect(find.byType(DisclaimerWidget), findsOneWidget);
    });

    testWidgets('deve estar no Histórico com ao menos um item', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.runAsync(() async {
        // um registro atual gravado no formato novo
        final record = savedRecord(TerminationType.withoutJustCause, fgts: 10000);
        SharedPreferences.setMockInitialValues({
          'calculation_history': [_encode(record.toJson())],
        });
      });
      await pump(tester, const HistoryScreen());
      expect(find.byType(DisclaimerWidget), findsOneWidget);
    });
  });
}

String _encode(Map<String, dynamic> json) => jsonEncode(json);
