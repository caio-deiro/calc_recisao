import 'package:calc_recisao/domain/rules/avos.dart';
import 'package:calc_recisao/domain/rules/vacation_periods.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<VacationPeriodStatus> statuses(VacationPeriodsResult r) =>
      r.periods.map((p) => p.status).toList();

  group('VacationPeriods.derive', () {
    test('deve ter só o período proporcional com menos de um ano (n = 0)', () {
      final r = VacationPeriods.derive(
        DateTime(2025, 3, 10),
        DateTime(2025, 6, 15),
        0,
      );
      expect(r.n, 0);
      expect(statuses(r), [VacationPeriodStatus.proportional]);
      expect(r.periods.single.acquisitiveStart, DateTime(2025, 3, 10));
    });

    test('deve manter simples na rescisão exatamente no aniversário', () {
      final r = VacationPeriods.derive(
        DateTime(2023, 6, 15),
        DateTime(2025, 6, 15),
        0,
      );
      expect(r.n, 2);
      // O concessivo do período 1 termina em 15/06/2025: a rescisão não é posterior.
      expect(r.periods[0].concessiveEnd, DateTime(2025, 6, 15));
      expect(statuses(r), [
        VacationPeriodStatus.simple,
        VacationPeriodStatus.simple,
        VacationPeriodStatus.proportional,
      ]);
      expect(r.periods[2].acquisitiveStart, DateTime(2025, 6, 15));
    });

    test('deve virar dobro quando o concessivo expirou', () {
      final r = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        0,
      );
      expect(r.n, 3);
      expect(statuses(r), [
        VacationPeriodStatus.double,
        VacationPeriodStatus.double,
        VacationPeriodStatus.simple,
        VacationPeriodStatus.proportional,
      ]);
      expect(r.periods[0].concessiveEnd, DateTime(2024, 6, 15));
      expect(r.periods[1].concessiveEnd, DateTime(2025, 6, 15));
    });

    test(
      'deve manter simples no dia do fim do concessivo e dobrar no dia seguinte',
      () {
        final noDia = VacationPeriods.derive(
          DateTime(2022, 6, 15),
          DateTime(2024, 6, 15),
          0,
        );
        expect(noDia.periods[0].status, VacationPeriodStatus.simple);
        final depois = VacationPeriods.derive(
          DateTime(2022, 6, 15),
          DateTime(2024, 6, 16),
          0,
        );
        expect(depois.periods[0].status, VacationPeriodStatus.double);
      },
    );

    test('deve marcar todos como gozados quando taken = n', () {
      final r = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        3,
      );
      expect(statuses(r), [
        VacationPeriodStatus.taken,
        VacationPeriodStatus.taken,
        VacationPeriodStatus.taken,
        VacationPeriodStatus.proportional,
      ]);
    });

    test('deve limitar taken acima de n a n', () {
      final a = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        9,
      );
      final b = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        3,
      );
      expect(statuses(a), statuses(b));
    });

    test('deve considerar taken negativo como zero', () {
      final a = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        -2,
      );
      final b = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        0,
      );
      expect(statuses(a), statuses(b));
    });

    test('deve usar 28/02 como aniversário de quem entrou em 29/02', () {
      final r = VacationPeriods.derive(
        DateTime(2020, 2, 29),
        DateTime(2025, 2, 28),
        0,
      );
      expect(r.n, 5);
      expect(r.periods[4].acquisitiveEnd, DateTime(2025, 2, 28));
    });

    test('deve ajustar admissão em 31/01 ao fim de fevereiro', () {
      final r = VacationPeriods.derive(
        DateTime(2022, 1, 31),
        DateTime(2024, 2, 28),
        0,
      );
      expect(r.n, 2);
      expect(r.periods[0].acquisitiveEnd, DateTime(2023, 1, 31));
      final antes = VacationPeriods.derive(
        DateTime(2022, 1, 31),
        DateTime(2024, 1, 30),
        0,
      );
      expect(antes.n, 1);
    });

    test('deve dar o mesmo resultado em chamadas repetidas (sem relógio)', () {
      final a = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        1,
      );
      final b = VacationPeriods.derive(
        DateTime(2022, 6, 15),
        DateTime(2025, 6, 16),
        1,
      );
      expect(statuses(a), statuses(b));
      expect(
        a.periods.map((p) => p.concessiveEnd),
        b.periods.map((p) => p.concessiveEnd),
      );
    });

    test('deve começar o proporcional onde os avos de férias começam', () {
      final admission = DateTime(2022, 6, 15);
      final termination = DateTime(2025, 9, 20);
      final r = VacationPeriods.derive(admission, termination, 3);
      final start = r.periods.last.acquisitiveStart;
      expect(start, DateTime(2025, 6, 15));
      // 3 meses cheios + 6 dias (< 15): mesmos 3 avos da âncora usada por derive.
      expect(proportionalVacationMonths(admission, termination), 3);
    });
  });

  group('fullServiceYears', () {
    test('deve ser 0 com rescisão antes da admissão', () {
      expect(fullServiceYears(DateTime(2025, 6, 1), DateTime(2024, 1, 1)), 0);
    });
  });
}
