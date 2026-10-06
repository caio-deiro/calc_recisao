/// Cálculo de avos (1/12) de 13º e férias proporcionais.
///
/// Dart puro e determinístico. Teto de 12 avos em todo total.
library;

const int _maxAvos = 12;

/// Regra de 15 dias, ponto único para 13º e férias: fração igual ou superior a
/// 15 dias vale mês integral (Lei 4.090/62 art. 1º §2º; CLT art. 146 parágrafo
/// único). ⚖️ A leitura "menos de 15 dias conta zero" aguarda validação em B6.
bool countsAsMonth(int daysWorked) => daysWorked >= 15;

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Meses do 13º de [end].year, de janeiro (ou da admissão, no ano dela) até
/// [end], pela regra de 15 dias.
int _thirteenthInYear(DateTime admission, DateTime end) {
  final startsThisYear = admission.year == end.year;
  final firstMonth = startsThisYear ? admission.month : 1;
  var months = 0;
  for (var m = firstMonth; m <= end.month; m++) {
    final firstDay = (startsThisYear && m == admission.month)
        ? admission.day
        : 1;
    final lastDay = m == end.month ? end.day : _daysInMonth(end.year, m);
    if (countsAsMonth(lastDay - firstDay + 1)) {
      months++;
    }
  }
  return months.clamp(0, _maxAvos);
}

/// Avos do 13º (Lei 4.090/62 art. 1º) até [noticeEnd] (data efetiva do aviso
/// indenizado, ou a rescisão se nula), com a regra de 15 dias. Se [noticeEnd]
/// cai em ano posterior ao da rescisão, soma o ano da rescisão até 31/12 e o
/// novo ano até [noticeEnd], cada um com teto 12.
///
/// ⚖️ Projeção por data (CLT art. 487 §1º; OJ 82 SDI-1 TST; Súmula 371 TST):
/// leitura do responsável, sem validação profissional (change
/// notice-projection-by-date; revisa a Q7a do PRD).
int thirteenthMonths(
  DateTime admission,
  DateTime termination, {
  DateTime? noticeEnd,
}) {
  final end = noticeEnd ?? termination;
  if (end.year > termination.year) {
    return _thirteenthInYear(admission, DateTime(termination.year, 12, 31)) +
        _thirteenthInYear(admission, end);
  }
  return _thirteenthInYear(admission, end);
}

/// Soma [months] meses a [date], ajustando o dia ao último do mês de destino
/// (ex.: 29/02 vira 28/02 em ano não bissexto). Âncora única de avos e férias.
DateTime addMonths(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final day = date.day > _daysInMonth(year, month)
      ? _daysInMonth(year, month)
      : date.day;
  return DateTime(year, month, day);
}

/// Avos de férias proporcionais, contados desde o último aniversário da admissão
/// (ou desde a admissão, com menos de 1 ano) na data da rescisão, até
/// [noticeEnd] (data efetiva do aviso; a rescisão se nula), com a regra de 15
/// dias, limitado a 12 (CLT art. 146 parágrafo único e art. 130). A projeção não
/// cria período vencido. ⚖️ C3 e C2.
int proportionalVacationMonths(
  DateTime admission,
  DateTime termination, {
  DateTime? noticeEnd,
}) {
  final end = noticeEnd ?? termination;
  var years = termination.year - admission.year;
  if (addMonths(admission, years * 12).isAfter(termination)) {
    years--;
  }
  final periodStart = addMonths(admission, years * 12);

  var months =
      (end.year - periodStart.year) * 12 + end.month - periodStart.month;
  if (addMonths(periodStart, months).isAfter(end)) {
    months--;
  }
  final restDays = end.difference(addMonths(periodStart, months)).inDays + 1;
  if (countsAsMonth(restDays)) {
    months++;
  }
  return months.clamp(0, _maxAvos);
}
