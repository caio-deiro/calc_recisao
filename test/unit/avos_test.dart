import 'package:calc_recisao/domain/rules/avos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('noticeProjectionMonths (C2, CLT art. 487 §1º)', () {
    test('deve projetar 1 mês por 30 dias completos de aviso', () {
      expect(noticeProjectionMonths(30), 1);
      expect(noticeProjectionMonths(33), 1);
      expect(noticeProjectionMonths(59), 1);
      expect(noticeProjectionMonths(60), 2);
      expect(noticeProjectionMonths(90), 3);
    });

    test('deve ser zero abaixo de 30 dias', () {
      expect(noticeProjectionMonths(29), 0);
      expect(noticeProjectionMonths(0), 0);
    });
  });

  group('regra de 15 dias (Lei 4.090/62 art. 1º §2º)', () {
    test('deve contar zero com 14 dias e mês integral com 15', () {
      expect(countsAsMonth(14), isFalse);
      expect(countsAsMonth(15), isTrue);
    });

    test('13º: rescisão no dia 14 não soma o mês, no dia 15 soma', () {
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 14)), 7);
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 15)), 8);
    });

    test('13º: janeiro com 14 dias vale zero', () {
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 1, 14)), 0);
    });
  });

  group('thirteenthMonths (ano-calendário)', () {
    test('deve contar de janeiro até a rescisão', () {
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 26)), 8);
    });

    test('deve contar desde a admissão no mesmo ano, com a regra de 15 dias', () {
      // fev: 24 dias (conta), mar, abr, mai, jun até dia 20 (conta) = 5
      expect(thirteenthMonths(DateTime(2025, 2, 5), DateTime(2025, 6, 20)), 5);
      // fev: 9 dias (não conta) -> 4
      expect(thirteenthMonths(DateTime(2025, 2, 20), DateTime(2025, 6, 20)), 4);
    });

    test('deve somar a projeção e limitar a 12 avos', () {
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 26), projection: 2), 10);
      expect(thirteenthMonths(DateTime(2020, 3, 10), DateTime(2025, 11, 20), projection: 3), 12);
    });
  });

  group('proportionalVacationMonths (C3, CLT art. 146)', () {
    test('deve contar desde o último aniversário da admissão', () {
      // aniversário 10/03/2025; 5 meses completos + 17 dias (conta) = 6
      expect(proportionalVacationMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 26)), 6);
    });

    test('deve contar desde a admissão com menos de 1 ano', () {
      expect(proportionalVacationMonths(DateTime(2025, 2, 5), DateTime(2025, 6, 20)), 5);
    });

    test('deve desconsiderar fração menor que 15 dias', () {
      // 10/03 -> 10/08 = 5 meses; sobram 14 dias (10 a 23/08 inclusive) -> 0
      expect(proportionalVacationMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 23)), 5);
      expect(proportionalVacationMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 24)), 6);
    });

    test('deve somar a projeção e limitar a 12 avos', () {
      expect(proportionalVacationMonths(DateTime(2020, 3, 10), DateTime(2025, 8, 26), projection: 1), 7);
      expect(proportionalVacationMonths(DateTime(2020, 3, 10), DateTime(2026, 2, 26), projection: 6), 12);
    });
  });
}
