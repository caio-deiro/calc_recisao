## 1. Pré-condições (B2-15, B6-06) — bloqueiam o início da change

- [x] 1.1 B2-15 Confirmar que `fix-calculation-rules` está arquivada e que existem 5 casos golden `calculo_legal` (um por tipo ativo, C1–C5) em `test/golden/cases/`; sem eles, parar e reportar ao orquestrador. Os casos de hoje são `calculo_legal`, calculados sem contador; TRCT real/contador (B6-06) não é pré-condição e as pendências ⚖️ de B6-06 bloqueiam a publicação, não o código.
- [x] 1.2 B2-15 Rodar `flutter test test/golden` com tolerância 0,01 (verde obrigatório). Rodar `flutter test --tags release-gate --run-skipped` só para REGISTRAR o baseline: deve acusar exatamente as 4 regras ⚖️ que exigem `exemplo_contador` (art479, art480, doubleVacation, noticeProjectionMutualAgreement) e nenhuma outra; esse resultado não bloqueia a migração (B6-06).

## 2. Migração para `Decimal` (B2-13, B2-14)

- [x] 2.1 B2-13 Testes unitários antes da troca: arredondamento half-up (10,005 → 10,01) e artefato de ponto flutuante (salário 1.100,10), nos pontos atuais.
- [x] 2.2 B2-13 Migrar `calculate_termination.dart` para `Decimal`/`Rational` (escala explícita, half-up por item, mesmos pontos de arredondamento).
- [x] 2.3 B2-13 Migrar `TaxTablesService.calculateTerminationTaxes` e o INSS/IRRF; ler alíquotas e faixas como texto para `Decimal`.
- [x] 2.4 B2-14 Converter `TerminationInput` (continua `double`) na entrada do use case e os resultados para `double` na saída; teste de que o JSON do histórico e a abertura de registro antigo não mudam.

## 3. Tolerância e critério de migração (B2-13, B2-15)

- [x] 3.1 B2-13 Baixar `goldenTolerance` de 0,01 para 0,00 em `test/golden/support/tolerance.dart` (handoff de B6-02) e atualizar o teste do comparador (100,00 vs 100,01 difere).
- [x] 3.2 B2-15 Rodar a suíte golden e o gate após a troca; sem alterar nenhum JSON de `cases/`. Explicar por escrito qualquer divergência de centavos (o documento oficial prevalece).
- [x] 3.3 B0-01 `flutter analyze` sem novos avisos e `flutter test` verde.

## 4. Docs e versão (B0-05, B0-08)

- [x] 4.1 B0-05 Atualizar `docs/ARCHITECTURE.md` (D1 resolvida) e `docs/PROJECT.md` (C6 ✅) no mesmo commit.
- [x] 4.2 B0-08 Bump de versão em `pubspec.yaml` quando esta change for publicada. (transferida para a publicação; decisão do responsável)
