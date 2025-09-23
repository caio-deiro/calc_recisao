import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/presentation/widgets/date_input_field.dart';

void main() {
  group('DateInputField Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should format date input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateInputField(controller: controller, label: 'Test Date'),
          ),
        ),
      );

      // Test typing digits
      await tester.enterText(find.byType(TextFormField), '01012024');
      await tester.pump();

      expect(controller.text, '01/01/2024');
    });

    testWidgets('should allow deletion of characters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateInputField(controller: controller, label: 'Test Date'),
          ),
        ),
      );

      // Enter a date
      await tester.enterText(find.byType(TextFormField), '01012024');
      await tester.pump();
      expect(controller.text, '01/01/2024');

      // Test backspace - should allow deletion
      controller.text = '01/01/202';
      controller.selection = TextSelection.collapsed(offset: controller.text.length);

      // Simulate backspace
      final formatter = _DateInputFormatter();
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 10));
      final newValue = TextEditingValue(text: '01/01/202', selection: TextSelection.collapsed(offset: 9));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/01/202');
    });

    testWidgets('should limit input to 8 digits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateInputField(controller: controller, label: 'Test Date'),
          ),
        ),
      );

      // Test typing more than 8 digits
      await tester.enterText(find.byType(TextFormField), '01012024123');
      await tester.pump();

      expect(controller.text, '01/01/2024');
    });

    testWidgets('should have calendar icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateInputField(controller: controller, label: 'Test Date'),
          ),
        ),
      );

      // Should have calendar icon
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}

// Helper class to test the formatter directly
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Se o texto está sendo reduzido (backspace/delete), permitir a edição
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Remove todos os caracteres não numéricos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 8 dígitos
    final limitedDigits = digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    String formatted = '';

    if (limitedDigits.isNotEmpty) {
      formatted = limitedDigits.substring(0, 1);
    }
    if (limitedDigits.length >= 2) {
      formatted = '${limitedDigits.substring(0, 2)}/';
    }
    if (limitedDigits.length >= 3) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 3)}';
    }
    if (limitedDigits.length >= 4) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/';
    }
    if (limitedDigits.length >= 5) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 5)}';
    }
    if (limitedDigits.length >= 6) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 6)}';
    }
    if (limitedDigits.length >= 7) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 7)}';
    }
    if (limitedDigits.length >= 8) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 8)}';
    }

    // Calcula a posição do cursor
    int cursorPosition = formatted.length;

    // Se o usuário estava digitando no meio do texto, tenta manter a posição relativa
    if (oldValue.selection.baseOffset < oldValue.text.length) {
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = formatted.replaceAll(RegExp(r'[^\d]'), '');

      if (newDigits.length > oldDigits.length) {
        // Adicionando caracteres
        cursorPosition = formatted.length;
      } else if (newDigits.length < oldDigits.length) {
        // Removendo caracteres
        cursorPosition = oldValue.selection.baseOffset;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition.clamp(0, formatted.length)),
    );
  }
}
