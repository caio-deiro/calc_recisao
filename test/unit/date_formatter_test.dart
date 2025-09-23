import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Date Input Formatter Tests', () {
    late _DateInputFormatter formatter;

    setUp(() {
      formatter = _DateInputFormatter();
    });

    test('should format date input correctly', () {
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(text: '01012024');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/01/2024');
    });

    test('should allow deletion of characters', () {
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 10));
      final newValue = TextEditingValue(text: '01/01/202', selection: TextSelection.collapsed(offset: 9));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/01/202');
    });

    test('should allow deletion of slashes', () {
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 5));
      final newValue = TextEditingValue(text: '01/012024', selection: TextSelection.collapsed(offset: 4));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/012024');
    });

    test('should limit input to 8 digits', () {
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(text: '01012024123');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/01/2024');
    });

    test('should handle partial input', () {
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(text: '01');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/');
    });

    test('should handle month input', () {
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(text: '0112');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/12/');
    });

    test('should handle year input', () {
      final oldValue = TextEditingValue.empty;
      final newValue = TextEditingValue(text: '01122024');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/12/2024');
    });

    test('should handle backspace at the end', () {
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 10));
      final newValue = TextEditingValue(text: '01/01/202', selection: TextSelection.collapsed(offset: 9));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/01/202');
    });

    test('should handle backspace in the middle', () {
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 5));
      final newValue = TextEditingValue(text: '01/012024', selection: TextSelection.collapsed(offset: 4));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '01/012024');
    });

    test('should handle complete deletion', () {
      final oldValue = TextEditingValue(text: '01/01/2024', selection: TextSelection.collapsed(offset: 10));
      final newValue = TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, '');
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
