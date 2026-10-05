/// Derivação dos períodos de férias a partir da admissão (PRD §6.4, B3).
///
/// Dart puro e determinístico: só usa as datas recebidas, sem relógio nem I/O.
library;

import 'avos.dart';

enum VacationPeriodStatus { taken, simple, double, proportional }

class VacationPeriod {
  const VacationPeriod({
    required this.index,
    required this.acquisitiveStart,
    required this.acquisitiveEnd,
    required this.concessiveEnd,
    required this.status,
  });

  /// 1…n para períodos completos; n+1 para o proporcional.
  final int index;
  final DateTime acquisitiveStart;

  /// Fim (exclusivo) do aquisitivo: `A + index·1 ano`.
  final DateTime acquisitiveEnd;

  /// Último dia do concessivo: `A + (index+1)·1 ano`.
  final DateTime concessiveEnd;
  final VacationPeriodStatus status;
}

class VacationPeriodsResult {
  const VacationPeriodsResult({required this.n, required this.periods});

  /// Anos completos entre admissão e rescisão.
  final int n;

  /// Períodos 1…n seguidos do proporcional (sempre o último).
  final List<VacationPeriod> periods;
}

/// Anos completos de serviço (âncora de [addMonths], igual à dos avos). ⚖️
int fullServiceYears(DateTime admission, DateTime termination) {
  if (termination.isBefore(admission)) return 0;
  var years = termination.year - admission.year;
  if (addMonths(admission, years * 12).isAfter(termination)) {
    years--;
  }
  return years;
}

class VacationPeriods {
  const VacationPeriods._();

  /// Deriva os períodos. `taken` é limitado a `[0, n]`. O período `i` é `double`
  /// só se a rescisão for estritamente posterior ao fim do concessivo
  /// (`A + (i+1)·1 ano`); no próprio dia ainda é `simple`. ⚖️ Súmula 328 TST.
  static VacationPeriodsResult derive(
    DateTime admission,
    DateTime termination,
    int taken,
  ) {
    final n = fullServiceYears(admission, termination);
    final gozados = taken.clamp(0, n);
    final periods = <VacationPeriod>[];
    for (var i = 1; i <= n + 1; i++) {
      final concessiveEnd = addMonths(admission, 12 * (i + 1));
      final VacationPeriodStatus status;
      if (i == n + 1) {
        status = VacationPeriodStatus.proportional;
      } else if (i <= gozados) {
        status = VacationPeriodStatus.taken;
      } else if (termination.isAfter(concessiveEnd)) {
        status = VacationPeriodStatus.double;
      } else {
        status = VacationPeriodStatus.simple;
      }
      periods.add(
        VacationPeriod(
          index: i,
          acquisitiveStart: addMonths(admission, 12 * (i - 1)),
          acquisitiveEnd: addMonths(admission, 12 * i),
          concessiveEnd: concessiveEnd,
          status: status,
        ),
      );
    }
    return VacationPeriodsResult(n: n, periods: List.unmodifiable(periods));
  }
}
