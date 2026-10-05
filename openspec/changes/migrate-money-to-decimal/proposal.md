## Why

Dinheiro em `double` (D1) pode mover centavos silenciosamente. O PRD (Q22, C6) decide `Decimal` no domínio **depois** dos testes golden, para que haja oráculo externo que prove que a troca não mudou nenhum valor. Esta é a parte B2.4 do `docs/SPECS.md` (B2-13..15), separada de `fix-calculation-rules` por decisão do usuário em 2026-10-05.

## Pré-condições (bloqueiam o início, não só a publicação)

- `fix-calculation-rules` implementada e arquivada (esta change usa `BreakdownCode`, `fgtsDeposit`, `TerminationRules` e o runner golden por `code`).
- **Casos golden reais** em `test/golden/cases/` (TRCTs anonimizados, um por tipo ativo, cobrindo C1–C5; B6-06, responsabilidade do usuário) e `flutter test --tags release-gate --run-skipped` verde. Sem isso, B2-15 não pode ser provado e a change **não começa**.

## What Changes

- Cálculo em `lib/domain/` e em `TaxTablesService.calculateTerminationTaxes` passa a `Decimal`/`Rational`, half-up a 2 casas por item nos mesmos pontos de hoje (B2-13).
- Fronteiras convertem para `double`; `TerminationInput` e o JSON do histórico não mudam (B2-14).
- `goldenTolerance` de 0,01 para 0,00 (handoff de B6-02 em B2-13) e critério de migração: golden passa antes e depois, divergência de centavos é explicada (B2-15).

## Capabilities

### New Capabilities
- `decimal-money`: aritmética decimal no domínio, fronteiras em `double` e critério de migração.

### Modified Capabilities
- `golden-tests`: `goldenTolerance` passa a 0,00. O bloco MODIFIED parte do texto resultante de `fix-calculation-rules`, que deve ser arquivada antes.

## Impact

- `lib/domain/usecases/calculate_termination.dart`, `lib/domain/entities/*`, `lib/core/services/tax_tables_service.dart`, `test/golden/support/{tolerance,golden_comparator}.dart`.
- Docs no mesmo commit: `docs/ARCHITECTURE.md` (D1 resolvida), `docs/PROJECT.md` (C6 ✅).
- Nenhuma dependência nova (`decimal` já está no `pubspec`); sem mudança de regra de negócio.

## Fora de escopo

- Qualquer mudança de regra, tabela ou UI.
- Trocar `double` em `TerminationInput` ou no JSON do histórico.
