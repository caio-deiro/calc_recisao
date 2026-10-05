/// Cálculo de avos (1/12) de 13º e férias proporcionais.
///
/// Dart puro e determinístico. Teto de 12 avos em todo total.
library;

const int _maxAvos = 12;

/// Regra de 15 dias, ponto único para 13º e férias: fração igual ou superior a
/// 15 dias vale mês integral (Lei 4.090/62 art. 1º §2º; CLT art. 146 parágrafo
/// único). ⚖️ A leitura "menos de 15 dias conta zero" aguarda validação em B6.
bool countsAsMonth(int daysWorked) => daysWorked >= 15;

/// Projeção do aviso indenizado: 1 mês por 30 dias completos (CLT art. 487 §1º;
/// OJ 82 SDI-1 TST). ⚖️ Interpretação em avos de 13º e férias a validar.
int noticeProjectionMonths(int noticeDays) => noticeDays ~/ 30;

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Avos do 13º no ano-calendário da rescisão (Lei 4.090/62 art. 1º), com a
/// regra de 15 dias, mais [projection], limitado a 12.
int thirteenthMonths(
  DateTime admission,
  DateTime termination, {
  int projection = 0,
}) {
  final startsThisYear = admission.year == termination.year;
  final firstMonth = startsThisYear ? admission.month : 1;
  var months = 0;
  for (var m = firstMonth; m <= termination.month; m++) {
    final firstDay = (startsThisYear && m == admission.month)
        ? admission.day
        : 1;
    final lastDay = m == termination.month
        ? termination.day
        : _daysInMonth(termination.year, m);
    if (countsAsMonth(lastDay - firstDay + 1)) {
      months++;
    }
  }
  return (months + projection).clamp(0, _maxAvos);
}

/// Soma [months] meses a [date], ajustando o dia ao último do mês de destino.
DateTime _addMonths(DateTime date, int months) {
  final total = date.year * 12 + (date.month - 1) + months;
  final year = total ~/ 12;
  final month = total % 12 + 1;
  final day = date.day > _daysInMonth(year, month)
      ? _daysInMonth(year, month)
      : date.day;
  return DateTime(year, month, day);
}

/// Avos de férias proporcionais, contados desde o último aniversário da admissão
/// (ou desde a admissão, com menos de 1 ano), com a regra de 15 dias, mais
/// [projection], limitado a 12 (CLT art. 146 parágrafo único e art. 130). ⚖️ C3.
int proportionalVacationMonths(
  DateTime admission,
  DateTime termination, {
  int projection = 0,
}) {
  var years = termination.year - admission.year;
  if (_addMonths(admission, years * 12).isAfter(termination)) {
    years--;
  }
  final periodStart = _addMonths(admission, years * 12);

  var months =
      (termination.year - periodStart.year) * 12 +
      termination.month -
      periodStart.month;
  if (_addMonths(periodStart, months).isAfter(termination)) {
    months--;
  }
  final restDays =
      termination.difference(_addMonths(periodStart, months)).inDays + 1;
  if (countsAsMonth(restDays)) {
    months++;
  }
  return (months + projection).clamp(0, _maxAvos);
}
