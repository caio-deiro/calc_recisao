## Why

O app trata férias vencidas como um booleano (`hasAccruedVacation`): paga **um** período simples ou nada, nunca dobra e não sabe quantos períodos existem (D11). O PRD §6.4 decide derivar os períodos da admissão, perguntando só "quantos períodos você já gozou?", e pagar o período cujo concessivo expirou **em dobro** (Súmula 328 TST), como indenização. Bloco B3 de `docs/SPECS.md`; decisões Q8, Q24, Q25 (`docs/PROJECT.md §16`), PRD §6.4. Depende do modelo de B2 (identidade de verba por `code`, dois totais, premissas), já arquivado e entregue.

## What Changes

- `TerminationInput.hasAccruedVacation` vira `vacationPeriodsTaken` (int ≥ 0); `fromJson` tolerante; o legado `hasAccruedVacation = true` é preservado só para exibição, sem recalcular (B3-01).
- Nova função pura `VacationPeriods.derive` em `lib/domain/` com início/fim aquisitivo, fim do concessivo e `status` simples/dobro/proporcional (B3-02, B3-03).
- O use case paga `accruedVacationSimple` e `accruedVacationDouble` em linhas separadas (dobro rotulado como indenização), sem INSS/IRRF, para todos os tipos; `proportionalVacation` segue como hoje (B3-04, B3-05).
- Formulário: stepper "Períodos de férias já gozados" limitado a `n`, recalculado ao mudar as datas, com aviso do que não é tratado (B3-06). Validação `taken ≤ n` (B3-08).
- Premissas ganham a tabela de períodos derivados, com o "dobro" marcado, e a marca "cálculo em validação" para `doubleVacation` (B3-07, B6-04).
- O runner golden passa a ler `feriasGozadas` no lugar de `feriasVencidas`.

## Capabilities

### New Capabilities
- `vacation-periods`: derivação dos períodos, valores simples/dobro, campo do formulário, validação e tabela nas premissas.

### Modified Capabilities
- `calculation-core`: o enum `BreakdownCode` troca `accruedVacation` por `accruedVacationSimple` e `accruedVacationDouble`.

## Impact

- Código: `lib/domain/{entities/termination_input,entities/breakdown_code,entities/assumption,rules/vacation_periods (novo),usecases/calculate_termination}.dart`, `lib/core/validators/termination_input_validator.dart`, `lib/presentation/screens/form/form_screen.dart`, `lib/l10n/`, `test/golden/support/golden_case.dart`.
- Testes: ~25 usos de `hasAccruedVacation` em `test/` migram; novos testes unitários de `derive`, do use case, do validador, de widget do formulário e fluxo Maestro.
- Docs no mesmo commit: `docs/ARCHITECTURE.md` (D11 resolvida), `docs/PROJECT.md §6.4` (🎯 vira ✅); a linha de B3 em `docs/SPECS.md` é do orquestrador. `pubspec.yaml`: bump de versão no merge (B0-08).

## Coordenação com changes em andamento

- `migrate-money-to-decimal` (0/11 tasks, bloqueada por casos golden reais) também edita `calculate_termination.dart`. Esta change escreve o novo cálculo com o padrão atual (`double` + `_roundCurrency`), em funções pequenas, para que a migração a `Decimal` seja mecânica; quem entrar depois resolve o rebase. Esta change **não** edita os artefatos daquela.
- `result-assumptions-and-two-totals` (completa, ainda não arquivada) é a base: usa o `AssumptionsSection` e `buildResultSections` existentes; esta change **não** altera a capability `result-presentation` (sem requisito em comum, os deltas aplicam em qualquer ordem).

## Fora de escopo

- Férias fracionadas, abono pecuniário e férias parcialmente gozadas (PRD §5.3).
- Tipos a prazo e rescisão indireta (B4); `Decimal` (B2-13..15); validar a regra ⚖️ do dobro (a change só **mostra** a marca).
- UI de histórico para o campo legado `hasAccruedVacation` (ver Open Questions do design).
