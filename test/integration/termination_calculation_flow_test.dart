import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/presentation/screens/form/form_screen.dart';
import 'package:calc_recisao/presentation/screens/result/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Termination Calculation Flow Integration Tests', () {
    group('Sem Justa Causa - Fluxo Completo', () {
      testWidgets('should complete full flow without FGTS penalty', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.withoutJustCause)));

        await tester.pumpAndSettle();

        // Preencher dados básicos
        await _fillBasicInfo(tester);

        // Preencher remuneração
        await _fillSalaryInfo(tester, '3000,00', '500,00', '22');

        // Configurar opções
        await _configureOptions(
          tester,
          hasAccruedVacation: true,
          noticeWorked: false,
          hasExistingFgts: false,
          dependents: 2,
          otherDiscounts: '100,00',
          calculateTaxes: true,
        );

        // Clicar em calcular
        await tester.tap(find.text('Calcular Rescisão'));
        await tester.pumpAndSettle();

        // Verificar se chegou na tela de resultado
        expect(find.byType(ResultScreen), findsOneWidget);
        expect(find.text('Resultado da Rescisão'), findsOneWidget);

        // Verificar se não há erros
        expect(tester.takeException(), isNull);
      });

      testWidgets('should complete flow with FGTS penalty', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.withoutJustCause)));

        await tester.pumpAndSettle();

        // Preencher dados básicos
        await _fillBasicInfo(tester);

        // Preencher remuneração
        await _fillSalaryInfo(tester, '5000,00', '800,00', '20');

        // Configurar opções com FGTS existente
        await _configureOptions(
          tester,
          hasAccruedVacation: true,
          noticeWorked: true,
          hasExistingFgts: true,
          existingFgtsAmount: '15000,00',
          dependents: 1,
          otherDiscounts: '0,00',
          calculateTaxes: true,
        );

        // Clicar em calcular
        await tester.tap(find.text('Calcular Rescisão'));
        await tester.pumpAndSettle();

        // Verificar se chegou na tela de resultado
        expect(find.byType(ResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Pedido de Demissão - Fluxo Completo', () {
      testWidgets('should complete resignation flow', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.resignation)));

        await tester.pumpAndSettle();

        // Preencher dados básicos
        await _fillBasicInfo(tester);

        // Preencher remuneração
        await _fillSalaryInfo(tester, '2500,00', '300,00', '15');

        // Configurar opções
        await _configureOptions(
          tester,
          hasAccruedVacation: false,
          noticeWorked: true,
          hasExistingFgts: false,
          dependents: 0,
          otherDiscounts: '50,00',
          calculateTaxes: false,
        );

        // Clicar em calcular
        await tester.tap(find.text('Calcular Rescisão'));
        await tester.pumpAndSettle();

        // Verificar se chegou na tela de resultado
        expect(find.byType(ResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('Validações e Tratamento de Erros', () {
      testWidgets('should handle empty required fields', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.withoutJustCause)));

        await tester.pumpAndSettle();

        // Tentar calcular sem preencher campos obrigatórios
        await tester.tap(find.text('Calcular Rescisão'));
        await tester.pumpAndSettle();

        // Verificar se validação funcionou (não deve navegar)
        expect(find.byType(ResultScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle invalid salary format', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.withoutJustCause)));

        await tester.pumpAndSettle();

        // Preencher dados básicos
        await _fillBasicInfo(tester);

        // Preencher salário com formato inválido
        await tester.enterText(find.text('Salário Base Mensal').first, 'abc');

        // Clicar em calcular
        await tester.tap(find.text('Calcular Rescisão'));
        await tester.pumpAndSettle();

        // Verificar se erro foi tratado
        expect(tester.takeException(), isNull);
      });
    });

    group('Navegação e UI', () {
      testWidgets('should navigate back from form screen', (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: FormScreen(terminationType: TerminationType.withoutJustCause)));

        await tester.pumpAndSettle();

        // Clicar no botão voltar
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Verificar se voltou
        expect(find.byType(FormScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should show correct title for each termination type', (WidgetTester tester) async {
        for (final type in TerminationType.values) {
          await tester.pumpWidget(MaterialApp(home: FormScreen(terminationType: type)));

          await tester.pumpAndSettle();

          // Verificar se título está correto
          expect(find.text('Dados da Rescisão - ${type.label}'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    });
  });
}

// Funções auxiliares para preencher formulário
Future<void> _fillBasicInfo(WidgetTester tester) async {
  // Simular seleção de data de admissão
  await tester.tap(find.text('Data de Admissão').first);
  await tester.pumpAndSettle();

  // Simular seleção de data de desligamento
  await tester.tap(find.text('Data de Desligamento').first);
  await tester.pumpAndSettle();
}

Future<void> _fillSalaryInfo(WidgetTester tester, String baseSalary, String additions, String workedDays) async {
  // Preencher salário base
  await tester.enterText(find.text('Salário Base Mensal').first, baseSalary);

  // Preencher adicionais
  await tester.enterText(find.text('Média de Adicionais Fixos (opcional)').first, additions);

  // Preencher dias trabalhados
  await tester.enterText(find.text('Dias Trabalhados no Mês (opcional)').first, workedDays);
}

Future<void> _configureOptions(
  WidgetTester tester, {
  required bool hasAccruedVacation,
  required bool noticeWorked,
  required bool hasExistingFgts,
  String existingFgtsAmount = '0,00',
  int dependents = 0,
  String otherDiscounts = '0,00',
  required bool calculateTaxes,
}) async {
  // Configurar férias vencidas
  if (hasAccruedVacation) {
    await tester.tap(find.text('Férias vencidas?'));
    await tester.pumpAndSettle();
  }

  // Configurar aviso prévio
  if (noticeWorked) {
    await tester.tap(find.text('Aviso prévio trabalhado'));
    await tester.pumpAndSettle();
  }

  // Configurar FGTS existente
  if (hasExistingFgts) {
    await tester.tap(find.text('Possui depósitos FGTS existentes'));
    await tester.pumpAndSettle();

    if (existingFgtsAmount != '0,00') {
      await tester.enterText(find.text('Valor total do FGTS no vínculo').first, existingFgtsAmount);
    }
  }

  // Preencher dependentes
  if (dependents > 0) {
    await tester.enterText(find.text('Número de Dependentes').first, dependents.toString());
  }

  // Preencher outros descontos
  if (otherDiscounts != '0,00') {
    await tester.enterText(find.text('Outros Descontos (opcional)').first, otherDiscounts);
  }

  // Configurar cálculo de impostos
  if (!calculateTaxes) {
    await tester.tap(find.text('Calcular descontos (INSS/IRRF)'));
    await tester.pumpAndSettle();
  }
}
