import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    group('formatDate', () {
      test('should format date correctly', () {
        final date = DateTime(2024, 1, 15);
        final result = Formatters.formatDate(date);
        expect(result, '15/01/2024');
      });

      test('should pad single digits with zeros', () {
        final date = DateTime(2024, 3, 5);
        final result = Formatters.formatDate(date);
        expect(result, '05/03/2024');
      });
    });

    group('parseDate', () {
      test('should parse valid date format dd/mm/aaaa', () {
        final result = Formatters.parseDate('15/01/2024');
        expect(result.year, 2024);
        expect(result.month, 1);
        expect(result.day, 15);
      });

      test('should parse date with single digits', () {
        final result = Formatters.parseDate('05/03/2024');
        expect(result.year, 2024);
        expect(result.month, 3);
        expect(result.day, 5);
      });

      test('should throw FormatException for invalid format', () {
        expect(() => Formatters.parseDate('2024-01-15'), throwsFormatException);
        expect(() => Formatters.parseDate('15-01-2024'), throwsFormatException);
        expect(() => Formatters.parseDate('15/01'), throwsFormatException);
        expect(() => Formatters.parseDate('invalid'), throwsFormatException);
      });

      test('should throw FormatException for empty string', () {
        expect(() => Formatters.parseDate(''), throwsFormatException);
      });
    });

    group('formatCurrency', () {
      test('should format currency correctly', () {
        final result = Formatters.formatCurrency(1234.56);
        expect(result, 'R\$ 1234,56');
      });

      test('should handle zero', () {
        final result = Formatters.formatCurrency(0.0);
        expect(result, 'R\$ 0,00');
      });
    });

    group('formatMonthYear', () {
      test('should format month year correctly', () {
        final date = DateTime(2024, 1, 15);
        final result = Formatters.formatMonthYear(date);
        expect(result, 'Jan/2024');
      });
    });

    group('formatPercentage', () {
      test('should format percentage correctly', () {
        final result = Formatters.formatPercentage(0.15);
        expect(result, '15.0%');
      });
    });
  });
}
