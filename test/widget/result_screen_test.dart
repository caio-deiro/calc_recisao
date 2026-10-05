import 'package:calc_recisao/core/analytics/analytics_service.dart';
import 'package:calc_recisao/core/analytics/analytics_sink.dart';
import 'package:calc_recisao/core/analytics/consent_service.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/core/utils/formatters.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:calc_recisao/presentation/screens/result/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/result_fixtures.dart';

class _FakeSink implements AnalyticsSink {
  final List<String> events = [];

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async => events.add(name);

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSaved(WidgetTester tester, CalculationHistory record) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: ResultScreen.fromHistory(record)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('Resultado: dois totais (B5-01)', () {
    testWidgets('sem justa causa: dois totais, saque de 100 % e multa fora das verbas pagas', (tester) async {
      final record = savedRecord(TerminationType.withoutJustCause, fgts: 10000);
      await pumpSaved(tester, record);

      expect(byId('result_paid_total'), findsOneWidget);
      expect(byId('result_fgts_total'), findsOneWidget);
      expect(find.text('Pago na rescisão'), findsOneWidget);
      expect(find.text('Depositado no FGTS'), findsWidgets);
      expect(find.text(Formatters.formatCurrency(record.result.paidAtTermination)), findsWidgets);
      // multa de 40 % sobre 10.000 = 4.000,00
      expect(find.text(Formatters.formatCurrency(4000)), findsWidgets);
      expect(find.textContaining('100 %'), findsOneWidget);
      expect(byId('result_fgts_withdrawal_info'), findsOneWidget);
      expect(find.text('Verbas pagas na rescisão'), findsOneWidget);
    });

    testWidgets('acordo mútuo: saque de 80 %', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.mutualAgreement, fgts: 10000));
      expect(find.textContaining('80 %'), findsOneWidget);
    });

    testWidgets('pedido de demissão: sem linha de saque e FGTS em R\$ 0,00', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.resignation));
      expect(byId('result_fgts_withdrawal_info'), findsNothing);
      expect(
        find.descendant(of: byId('result_fgts_total'), matching: find.text(Formatters.formatCurrency(0))),
        findsOneWidget,
      );
    });

    testWidgets('justa causa: sem linha de saque', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withJustCause));
      expect(byId('result_fgts_withdrawal_info'), findsNothing);
    });

    testWidgets('não deve existir "Total a Receber" nem "Valor Líquido"', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));
      expect(find.textContaining('Total a Receber'), findsNothing);
      expect(find.textContaining('Valor Líquido'), findsNothing);
    });
  });

  group('Resultado: premissas e validação (B5-02, B6-04)', () {
    testWidgets('premissas fechadas por padrão e abertas ao tocar', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));

      expect(find.text('Premissas desta estimativa'), findsOneWidget);
      expect(byId('result_assumption_fgtsBalance'), findsNothing);

      await tester.tap(find.text('Premissas desta estimativa'));
      await tester.pumpAndSettle();

      expect(byId('result_assumption_fgtsBalance'), findsOneWidget);
      expect(byId('result_assumption_thirteenthMonths'), findsOneWidget);
      expect(find.textContaining('informado'), findsWidgets);
    });

    testWidgets('marcador "estimado" só com FGTS estimado', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause));
      expect(byId('result_estimated_marker'), findsWidgets);
    });

    testWidgets('FGTS informado não tem marcador "estimado"', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));
      expect(byId('result_estimated_marker'), findsNothing);
    });

    testWidgets('acordo mútuo mostra o aviso de validação com as premissas fechadas', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.mutualAgreement, fgts: 10000));
      expect(byId('result_validation_notice'), findsOneWidget);
      expect(byId('result_assumption_validationPending'), findsNothing);
    });

    testWidgets('férias em dobro: aviso visível e tabela de períodos nas premissas', (tester) async {
      final result = const CalculateTerminationUseCase().execute(
        TerminationInput(
          admissionDate: DateTime(2022, 6, 15),
          terminationDate: DateTime(2024, 6, 16),
          baseSalary: 3000,
          calculateTaxes: false,
        ),
        TerminationType.withoutJustCause,
      );
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, result: result));

      expect(byId('result_validation_notice'), findsOneWidget);
      expect(find.textContaining('Cálculo em validação: férias em dobro'), findsOneWidget);
      expect(find.textContaining('Férias em Dobro'), findsWidgets);
      expect(byId('result_assumption_vacationPeriods'), findsNothing);

      await tester.tap(find.text('Premissas desta estimativa'));
      await tester.pumpAndSettle();
      expect(byId('result_assumption_vacationPeriods'), findsOneWidget);
      expect(find.textContaining(': dobro'), findsWidgets);
    });

    testWidgets('sem regra pendente não há aviso de validação', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));
      expect(byId('result_validation_notice'), findsNothing);
    });
  });

  group('Resultado salvo do histórico (B5-06, B2-11)', () {
    testWidgets('deve mostrar os totais salvos, sem recalcular', (tester) async {
      // O use case nunca produziria 123,45 para esta entrada.
      final saved = TerminationResult(
        additions: const [],
        deductions: const [],
        totalDeductions: 0,
        calculationDate: DateTime(2025, 8, 26),
        paidAtTermination: 123.45,
      );
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, result: saved));

      expect(find.text(Formatters.formatCurrency(123.45)), findsOneWidget);
    });

    testWidgets('abrir não grava histórico, não marca primeiro resultado e não emite evento', (tester) async {
      final sink = _FakeSink();
      AnalyticsService.sink = sink;
      SharedPreferences.setMockInitialValues({
        ConsentService.decidedKey: true,
        ConsentService.analyticsEnabledKey: true,
      });

      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));
      await tester.pump(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('calculation_history'), isNull);
      expect(prefs.getBool(ConsentService.firstResultKey), isNull);
      expect(sink.events, isEmpty);
    });

    testWidgets('registro legado: valor salvo, marca, sem dois totais e sem compartilhar', (tester) async {
      final legacy = CalculationHistory.fromJson({
        'id': 'l1',
        'input': {
          'admissionDate': '2023-01-01T00:00:00.000',
          'terminationDate': '2024-06-30T00:00:00.000',
          'baseSalary': 3000.0,
        },
        'result': {
          'additions': [],
          'deductions': [],
          'totalToReceive': 3500.0,
          'totalDeductions': 0.0,
          'netAmount': 3500.0,
          'calculationDate': '2024-06-30T00:00:00.000',
        },
        'terminationType': 'withoutJustCause',
        'timestamp': '2024-06-30T00:00:00.000',
      });
      await pumpSaved(tester, legacy);

      expect(find.text(Formatters.formatCurrency(3500)), findsOneWidget);
      expect(byId('result_legacy_mark'), findsOneWidget);
      expect(find.text('Calculado em versão anterior'), findsOneWidget);
      expect(find.text('Pago na rescisão'), findsNothing);
      expect(find.text('Depositado no FGTS'), findsNothing);
      expect(find.text('Premissas desta estimativa'), findsNothing);
      expect(byId('result_validation_notice'), findsNothing);
      expect(byId('result_share_button'), findsNothing);
    });

    testWidgets('resultado atual mostra a ação de compartilhar', (tester) async {
      await pumpSaved(tester, savedRecord(TerminationType.withoutJustCause, fgts: 10000));
      expect(byId('result_share_button'), findsOneWidget);
      expect(byId('result_back_button'), findsOneWidget);
    });
  });

  group('Cálculo novo', () {
    testWidgets('deve calcular, mostrar os dois totais e gravar um registro', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: ResultScreen(input: sampleInput(fgts: 10000), terminationType: TerminationType.withoutJustCause),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(byId('result_paid_total'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('calculation_history'), hasLength(1));
    });
  });
}
