## Why

O núcleo de cálculo hoje identifica verba pelo texto de `description` (D8), espalha regras de tipo em `if`/`removeWhere`, mistura a multa do FGTS no total "a receber" (D10) e erra em cinco pontos já decididos no PRD (C1–C5). O resultado não informa o que foi estimado. B2.1 a B2.3 do `docs/SPECS.md` (B2-01..12) corrigem isso, depois que a infra golden (B6, arquivada) existe como oráculo. Decisões: Q1, Q2, Q3, Q7, Q9, Q11 (`docs/PROJECT.md §16`).

## What Changes

- `BreakdownCode` e `BreakdownItem.code`; fim das comparações por texto; remoção de `test/golden/support/provisional_code_map.dart` (B2-01).
- `TerminationRules` imutável por `TerminationType`; o use case decide antes de adicionar, sem `removeWhere` (B2-02, B2-03).
- Correções ⚖️ C1 a C5 (B2-04 a B2-08).
- Mês com menos de 15 dias trabalhados passa a contar zero nas avos (decidido pelo usuário em 2026-10-05; Lei 4.090 art. 1º §2º) (B2-06, B2-10).
- `TerminationResult` com `paidAtTermination`, `fgtsDeposit` e `assumptions` (B2-09, B2-10), incluindo a premissa "cálculo em validação" (B6-04).
- Histórico com `schemaVersion`, leitura de registros legados e mapeamento de nomes antigos do enum (B2-11, B2-12).
- **B2-13..15 (`Decimal`, tolerância 0,00) NÃO estão aqui**: ficam na change `migrate-money-to-decimal`, que depende desta e só começa com casos golden reais (B6-06).

## Pré-requisitos de release

- **B5** (premissas na UI, PDF e compartilhamento) deve entrar antes de qualquer publicação; senão acordo mútuo e C1–C5 saem sem aviso.
- **Release-gate** (`flutter test --tags release-gate --run-skipped`) verde, o que depende de B6-06. C1–C5 e a regra de 15 dias são ⚖️ mas não estão em `pendingValidationRules`; o gate é a mitigação.

## Capabilities

### New Capabilities
- `calculation-core`: identidade de verba, regras por tipo, correções C1–C5, avos, dois totais, premissas e histórico compatível.

### Modified Capabilities
- `golden-tests`: remove o mapa provisório de verbas, identifica verba por `code` e suporta os dois totais (a tolerância continua 0,01; vai a 0,00 em `migrate-money-to-decimal`).

## Impact

- `lib/domain/{usecases/calculate_termination,entities/*}.dart`, `lib/core/services/tax_tables_service.dart`, `lib/data/repositories/history_repository.dart`.
- Consumidores de `netAmount`/`totalToReceive`: `result_screen`, `history_screen`, `pdf_utils`, `share_utils` (ajuste mínimo; a reestruturação é B5).
- `test/golden/**`, testes unitários existentes que usam `description` ou `dia/30`.
- Docs no mesmo commit: `docs/PROJECT.md §6`, `docs/ARCHITECTURE.md` (dívidas D8, D10). O ajuste do SPECS (duas changes para B2) fica com o orquestrador.
- `assets/config/tax_tables.json`: sem mudança de dados.

## Fora de escopo

- `Decimal` e tolerância 0,00 (B2-13..15): change `migrate-money-to-decimal`.
- Períodos de férias e dobro (B3), tipos de prazo, art. 479/480 e indireta (B4; as flags de B2-02 existem, sempre falsas), nova UI de resultado/PDF (B5).
- Casos golden reais: dependem de TRCTs e contador (B6-06). Bloqueiam a **publicação**, não o código.
- Mudança de tabelas fiscais.
