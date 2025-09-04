import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('should render without overflow on small screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480)); // Small screen

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify main elements are visible
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('should render without overflow on medium screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800)); // Medium screen

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify main elements are visible
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('should render without overflow on large screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900)); // Large screen

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify main elements are visible
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);
    });

    testWidgets('should navigate to next page when next button is tapped', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify first page is visible
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);

      // Tap next button
      await tester.tap(find.text('Próximo'));
      await tester.pumpAndSettle();

      // Verify second page is visible
      expect(find.text('Estimativas e Privacidade'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
    });

    testWidgets('should show scroll when content overflows', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 400)); // Very small screen

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify scroll view is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should render without overflow on very small screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 400)); // Very small screen

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      await tester.pumpAndSettle();

      // Verify no overflow errors
      expect(tester.takeException(), isNull);

      // Verify scroll view is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify main elements are visible
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Próximo'), findsOneWidget);
    });
  });
}
