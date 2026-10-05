/// Identidade estável de cada verba do resultado (nunca use `description` como chave).
enum BreakdownCode {
  salaryBalance,
  notice,
  noticeDiscount,
  thirteenth,
  accruedVacationSimple,
  accruedVacationDouble,

  /// Só para leitura de histórico gravado antes de B3 (um único item de férias vencidas).
  accruedVacation,
  proportionalVacation,
  fgtsFine,
  inss,
  irrf,
  otherDiscounts,

  /// Só para leitura de histórico gravado antes do `schemaVersion` 2 (sem `code`).
  legacy,
}
