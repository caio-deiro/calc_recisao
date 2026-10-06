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

  /// Indenização do art. 479 CLT (provento) e desconto do art. 480 CLT (B4).
  indemnity479,
  indemnity480,

  /// Só para leitura de histórico gravado antes do `schemaVersion` 2 (sem `code`).
  legacy,
}
