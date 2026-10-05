import 'package:calc_recisao/core/analytics/analytics_service.dart';
import 'package:calc_recisao/core/analytics/analytics_sink.dart';
import 'package:calc_recisao/core/analytics/consent_service.dart';
import 'package:calc_recisao/presentation/screens/home/home_screen.dart';
import 'package:calc_recisao/presentation/widgets/consent_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopSink implements AnalyticsSink {
  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

void main() {
  setUp(() {
    umpStep = () async {};
    AnalyticsService.sink = _NoopSink();
  });

  Future<BuildContext> pumpHost(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    return tester.element(find.byType(HomeScreen));
  }

  group('Aviso de consentimento (B1-11)', () {
    testWidgets('não deve aparecer antes do primeiro resultado', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final context = await pumpHost(tester);

      showConsentPromptIfNeeded(context);
      await tester.pumpAndSettle();

      expect(find.text('Ajude a melhorar o app'), findsNothing);
    });

    testWidgets(
      'deve aparecer após o primeiro resultado e persistir o aceite',
      (tester) async {
        SharedPreferences.setMockInitialValues({'first_result_done': true});
        final context = await pumpHost(tester);

        showConsentPromptIfNeeded(context);
        await tester.pumpAndSettle();
        expect(find.text('Ajude a melhorar o app'), findsOneWidget);

        await tester.tap(find.text('Aceitar'));
        await tester.pumpAndSettle();

        expect(find.text('Ajude a melhorar o app'), findsNothing);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('consent_decided'), isTrue);
        expect(prefs.getBool('analytics_enabled'), isTrue);
      },
    );

    testWidgets('deve persistir a recusa e não repetir o aviso', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'first_result_done': true});
      final context = await pumpHost(tester);

      showConsentPromptIfNeeded(context);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('consent_decided'), isTrue);
      expect(prefs.getBool('analytics_enabled'), isFalse);

      showConsentPromptIfNeeded(context);
      await tester.pumpAndSettle();
      expect(find.text('Ajude a melhorar o app'), findsNothing);
      expect(await ConsentService.shouldPrompt(), isFalse);
    });
  });
}
