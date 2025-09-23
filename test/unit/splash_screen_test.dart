import 'package:calc_recisao/presentation/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SplashScreen Tests', () {
    setUp(() {
      // Limpar SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should show splash screen with app name and loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: const SplashScreen()));

      // Verificar se os elementos estão presentes
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Carregando...'), findsOneWidget);
      expect(find.byIcon(Icons.calculate), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Aguardar o timer e a navegação
      await tester.pumpAndSettle();
    });

    testWidgets('should navigate to onboarding screen on first run', (WidgetTester tester) async {
      // Garantir que o onboarding não foi completado
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(MaterialApp(home: const SplashScreen()));

      // Aguardar a navegação
      await tester.pumpAndSettle();

      // Verificar se navegou para a tela de onboarding
      expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
      expect(find.text('Calcule suas verbas rescisórias de forma simples e rápida'), findsOneWidget);
    });

    testWidgets('should navigate to home screen after onboarding completed', (WidgetTester tester) async {
      // Simular que o onboarding foi completado
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});

      await tester.pumpWidget(MaterialApp(home: const SplashScreen()));

      // Aguardar a navegação
      await tester.pumpAndSettle();

      // Verificar se navegou para a tela home
      // (assumindo que a home screen tem um texto específico)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
