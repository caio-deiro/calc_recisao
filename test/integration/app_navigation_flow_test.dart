import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Navigation Flow Integration Tests', () {
    group('Home Screen Navigation', () {
      testWidgets('should navigate to termination types', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pumpAndSettle();

        // Verificar se todos os tipos de rescisão estão presentes
        expect(find.text('Sem Justa Causa'), findsOneWidget);
        expect(find.text('Pedido de Demissão'), findsOneWidget);
        expect(find.text('Prazo Determinado'), findsOneWidget);

        // Navegar para um tipo de rescisão
        await tester.tap(find.text('Sem Justa Causa'));
        await tester.pumpAndSettle();

        // Verificar se chegou na tela de formulário
        expect(find.text('Dados da Rescisão - Sem Justa Causa'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show correct app title', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pumpAndSettle();

        // Verificar elementos da home
        expect(find.text('Calculadora de Rescisão CLT'), findsOneWidget);
        expect(find.text('Escolha o tipo de rescisão:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Navigation and UI', () {
      testWidgets('should navigate back from form screen', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

        await tester.pumpAndSettle();

        // Navegar para formulário
        await tester.tap(find.text('Sem Justa Causa'));
        await tester.pumpAndSettle();

        // Clicar no botão voltar
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verificar se voltou para home
        expect(find.text('Escolha o tipo de rescisão:'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show correct title for each termination type', (WidgetTester tester) async {
        final testTypes = [TerminationType.withoutJustCause, TerminationType.resignation, TerminationType.fixedTerm];

        for (final type in testTypes) {
          await tester.pumpWidget(MaterialApp(home: HomeScreen()));

          await tester.pumpAndSettle();

          // Navegar para o tipo
          await tester.tap(find.text(type.label));
          await tester.pumpAndSettle();

          // Verificar se título está correto
          expect(find.text('Dados da Rescisão - ${type.label}'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Voltar para home
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }
      });
    });
  });
}
