import 'package:calc_recisao/domain/rules/avos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('data efetiva (D7): DateTime(y, m, d + n) sem horário', () {
    test('deve virar o ano: 31/12 + 1 dia é 01/01 à meia-noite', () {
      final e = DateTime(2026, 12, 31 + 1);
      expect(e, DateTime(2027, 1, 1));
      expect(e.hour, 0);
    });
  });

  group('projeção do aviso por data (C2, CLT art. 487 §1º; OJ 82 SDI-1)', () {
    // Contas à mão (design.md, notice-projection-by-date).
    test('45 dias de 05/09/2026: E = 20/10/2026, 13º 10 e férias 7', () {
      // 13º: jan-set = 9, outubro com 20 dias conta = 10.
      // Férias: 10/03 a 10/10 = 7 meses, resto 11 dias não conta = 7.
      final adm = DateTime(2021, 3, 10);
      final term = DateTime(2026, 9, 5);
      final e = DateTime(2026, 10, 20);
      expect(thirteenthMonths(adm, term, noticeEnd: e), 10);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 7);
      // sem projeção: 8 e 6 (extras reais +2 e +1)
      expect(thirteenthMonths(adm, term), 8);
      expect(proportionalVacationMonths(adm, term), 6);
    });

    test('60 dias de 15/08/2026: E = 14/10/2026, 13º 9 e férias 9', () {
      // Prova "menos avos que +1 por 30 dias": o método antigo (dias ~/ 30)
      // daria 13º 8 + 2 = 10 e férias 7 + 2 = 9.
      // 13º: jan-set = 9; outubro com 14 dias não conta.
      // Férias: 15/01 a 15/09 = 8 meses, resto 29 dias conta = 9.
      final adm = DateTime(2016, 1, 15);
      final term = DateTime(2026, 8, 15);
      final e = DateTime(2026, 8, 15 + 60);
      expect(e, DateTime(2026, 10, 14));
      expect(thirteenthMonths(adm, term, noticeEnd: e), 9);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 9);
    });

    test('acordo mútuo, 24 dias pagos de 31/07/2026: 13º 8 e férias 7', () {
      // E = 24/08/2026. 13º: jan-jul = 7, agosto com 24 dias conta = 8.
      // Férias: 15/01 a 15/08 = 7 meses, resto 10 dias não conta = 7.
      final adm = DateTime(2020, 1, 15);
      final term = DateTime(2026, 7, 31);
      final e = DateTime(2026, 8, 24);
      expect(thirteenthMonths(adm, term, noticeEnd: e), 8);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 7);
    });

    test('virada de ano: 13º soma 12 de 2026 e 1 de 2027; férias 10', () {
      // E = 19/01/2027. Férias: 10/03/2026 a 10/01/2027 = 10 meses, resto 10 dias.
      final adm = DateTime(2020, 3, 10);
      final term = DateTime(2026, 12, 20);
      final e = DateTime(2027, 1, 19);
      expect(thirteenthMonths(adm, term, noticeEnd: e), 13);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 10);
    });

    test('aniversário dentro do aviso: férias limitadas a 12, 13º 4', () {
      // E = 19/04/2026; início 10/03/2025; 13 meses -> 12. 13º: jan-mar + abril = 4.
      final adm = DateTime(2021, 3, 10);
      final term = DateTime(2026, 3, 5);
      final e = DateTime(2026, 4, 19);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 12);
      expect(thirteenthMonths(adm, term, noticeEnd: e), 4);
    });

    test('teto de 12 em férias com 48 dias de 26/02/2026 (E = 15/04/2026)', () {
      final adm = DateTime(2020, 3, 10);
      final term = DateTime(2026, 2, 26);
      final e = DateTime(2026, 4, 15);
      expect(proportionalVacationMonths(adm, term, noticeEnd: e), 12);
      expect(thirteenthMonths(adm, term, noticeEnd: e), 4);
    });

    test('33, 60 e 90 dias', () {
      // 33 dias: E = 22/06/2026; 13º 5+1 = 6; férias 10/03 a 10/06 = 3, resto 13.
      expect(
        thirteenthMonths(
          DateTime(2025, 3, 10),
          DateTime(2026, 5, 20),
          noticeEnd: DateTime(2026, 6, 22),
        ),
        6,
      );
      expect(
        proportionalVacationMonths(
          DateTime(2025, 3, 10),
          DateTime(2026, 5, 20),
          noticeEnd: DateTime(2026, 6, 22),
        ),
        3,
      );
      // 60 dias: E = 25/10/2025; 13º 9+1 = 10; férias 7 meses + 16 dias = 8.
      expect(
        thirteenthMonths(
          DateTime(2015, 3, 10),
          DateTime(2025, 8, 26),
          noticeEnd: DateTime(2025, 10, 25),
        ),
        10,
      );
      expect(
        proportionalVacationMonths(
          DateTime(2015, 3, 10),
          DateTime(2025, 8, 26),
          noticeEnd: DateTime(2025, 10, 25),
        ),
        8,
      );
      // 90 dias: E = 24/11/2025; 13º 10+1 = 11; férias 8 meses + 15 dias = 9.
      expect(
        thirteenthMonths(
          DateTime(2005, 3, 10),
          DateTime(2025, 8, 26),
          noticeEnd: DateTime(2025, 11, 24),
        ),
        11,
      );
      expect(
        proportionalVacationMonths(
          DateTime(2005, 3, 10),
          DateTime(2025, 8, 26),
          noticeEnd: DateTime(2025, 11, 24),
        ),
        9,
      );
    });

    test('sem aviso (E = rescisão): avos iguais às sem projeção', () {
      final adm = DateTime(2020, 3, 10);
      final term = DateTime(2025, 8, 26);
      expect(thirteenthMonths(adm, term, noticeEnd: term), 8);
      expect(proportionalVacationMonths(adm, term, noticeEnd: term), 6);
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

    test(
      'deve contar desde a admissão no mesmo ano, com a regra de 15 dias',
      () {
        // fev: 24 dias (conta), mar, abr, mai, jun até dia 20 (conta) = 5
        expect(
          thirteenthMonths(DateTime(2025, 2, 5), DateTime(2025, 6, 20)),
          5,
        );
        // fev: 9 dias (não conta) -> 4
        expect(
          thirteenthMonths(DateTime(2025, 2, 20), DateTime(2025, 6, 20)),
          4,
        );
      },
    );
  });

  group('proportionalVacationMonths (C3, CLT art. 146)', () {
    test('deve contar desde o último aniversário da admissão', () {
      // aniversário 10/03/2025; 5 meses completos + 17 dias (conta) = 6
      expect(
        proportionalVacationMonths(
          DateTime(2020, 3, 10),
          DateTime(2025, 8, 26),
        ),
        6,
      );
    });

    test('deve contar desde a admissão com menos de 1 ano', () {
      expect(
        proportionalVacationMonths(DateTime(2025, 2, 5), DateTime(2025, 6, 20)),
        5,
      );
    });

    test('deve desconsiderar fração menor que 15 dias', () {
      // 10/03 -> 10/08 = 5 meses; sobram 14 dias (10 a 23/08 inclusive) -> 0
      expect(
        proportionalVacationMonths(
          DateTime(2020, 3, 10),
          DateTime(2025, 8, 23),
        ),
        5,
      );
      expect(
        proportionalVacationMonths(
          DateTime(2020, 3, 10),
          DateTime(2025, 8, 24),
        ),
        6,
      );
    });
  });
}
