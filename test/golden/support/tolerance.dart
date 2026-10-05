/// Tolerância única dos testes golden, em reais.
///
/// 0,01 enquanto o dinheiro é `double`. Trocar para 0,00 em B2-13 (migração
/// para `Decimal`). Diferença de centavo é achado: investigar antes de mexer aqui.
const double goldenTolerance = 0.01;
