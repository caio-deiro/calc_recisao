import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/about/about_screen.dart';
import 'package:calc_recisao/presentation/screens/form/form_screen.dart';
import 'package:calc_recisao/presentation/screens/history/history_screen.dart';
import 'package:calc_recisao/presentation/screens/home/home_screen.dart';
import 'package:calc_recisao/presentation/screens/result/result_screen.dart';
import 'package:calc_recisao/presentation/screens/splash/splash_screen.dart';
import 'package:calc_recisao/presentation/screens/support/support_screen.dart';
import 'package:calc_recisao/presentation/widgets/ad_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await TaxTablesService.instance.loadTaxTables();
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('Banner adaptativo (B1-10a)', () {
    testWidgets('deve estar presente na Home', (tester) async {
      await pumpScreen(tester, const HomeScreen());
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('deve estar presente no Resultado', (tester) async {
      final input = TerminationInput(
        admissionDate: DateTime(2023, 1, 1),
        terminationDate: DateTime(2024, 6, 30),
        baseSalary: 3000,
      );
      await pumpScreen(
        tester,
        ResultScreen(
          input: input,
          terminationType: TerminationType.withoutJustCause,
        ),
      );
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('deve estar presente no Histórico', (tester) async {
      await pumpScreen(tester, const HistoryScreen());
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('deve estar presente no Suporte', (tester) async {
      await pumpScreen(tester, const SupportScreen());
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('deve estar presente no Sobre', (tester) async {
      await pumpScreen(tester, const AboutScreen());
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('deve estar ausente no Formulário', (tester) async {
      await pumpScreen(
        tester,
        const FormScreen(terminationType: TerminationType.withoutJustCause),
      );
      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('deve estar ausente na Splash', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      expect(find.byType(AdBanner), findsNothing);
      await tester.pumpAndSettle();
    });
  });
}
