/// Dias restantes do contrato a prazo para o art. 479/480 CLT: fim previsto menos a
/// rescisão, em dias de calendário (o dia da rescisão não conta; o dia do fim conta).
/// ⚖️ Convenção de contagem de fonte secundária (design B4); ponto único para trocá-la.
/// Nunca negativo.
int remainingDays(DateTime fixedTermEnd, DateTime termination) {
  final end = DateTime.utc(
    fixedTermEnd.year,
    fixedTermEnd.month,
    fixedTermEnd.day,
  );
  final start = DateTime.utc(
    termination.year,
    termination.month,
    termination.day,
  );
  final days = end.difference(start).inDays;
  return days < 0 ? 0 : days;
}
