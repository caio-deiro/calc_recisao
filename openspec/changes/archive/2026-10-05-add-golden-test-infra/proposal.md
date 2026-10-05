## Why

Os testes atuais verificam o que o código faz, não o que é correto (PRD §11, Q10, Q28a). Antes de B2 mudar qualquer regra, o projeto precisa de um oráculo externo e do mecanismo que o consome; sem isso a correção de C1–C5 é opinião. A ordem de execução do SPECS é `B0 → B6 → B1 → B2`: esta change é a **infra** do B6.

## What Changes

- Diretório `test/golden/cases/*.json` com schema fixo de caso (fonte, tipo, entrada, esperado por `code` de verba e totais) — B6-01.
- Runner único `test/golden/golden_test.dart`, com tolerância centralizada (0,01 antes de B2-13; 0,00 depois) — B6-02.
- Regras de integridade: esperado nunca vem da saída do app; caso sem fonte é rejeitado pelo loader — B6-03.
- Política do Plano B ("cálculo em validação") definida como contrato e checada por registro de regras pendentes; a `Assumption` em si vem em B2-10 — B6-04.
- Gate de cobertura mínima (`release-gate`, pulado via `skip` em `dart_test.yaml`; roda com `flutter test --tags release-gate --run-skipped`), executado antes de publicar B2/B3/B4 — B6-05.
- Lista de pendências do responsável (TRCTs, contador) registrada como Open Questions — B6-06.
- Esta change **não entrega nenhum caso golden real** e **não** adiciona caso em `test/golden/cases/`. Os autotestes do loader e do comparador usam fixtures inline marcadas como não-oráculo, que nunca rodam contra o app.

## Capabilities

### New Capabilities
- `golden-tests`: infraestrutura e regras de integridade dos testes golden de cálculo de rescisão.

### Modified Capabilities
- Nenhuma.

## Impact

- Só `test/golden/**` e um `dart_test.yaml` na raiz (tag `release-gate` com `skip`). Nenhum código em `lib/`, nenhuma dependência nova.
- Docs a atualizar no mesmo commit da implementação: `docs/ARCHITECTURE.md §8` (nova pasta de testes).

## Fora de escopo

- Casos golden reais (dependem de TRCTs/contador, B6-06).
- `BreakdownCode` (B2-01), `Assumption` (B2-10), `Decimal` (B2-13), troca de tolerância para 0,00 (feita em B2-13/B2-15).
- Qualquer mudança de regra de cálculo.
