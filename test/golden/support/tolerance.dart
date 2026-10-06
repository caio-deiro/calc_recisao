/// Tolerância única dos testes golden, em reais.
///
/// 0,00 desde a migração do dinheiro para `Decimal` (B2-13): o comparador só
/// aceita o épsilon de 1e-9 da conversão para `double`. Diferença de centavo é
/// achado: investigar antes de mexer aqui.
const double goldenTolerance = 0.00;
