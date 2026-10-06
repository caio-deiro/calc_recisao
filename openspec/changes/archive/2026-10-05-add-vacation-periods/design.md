## Context

Estado verificado no código em 2026-10-05: `TerminationInput.hasAccruedVacation` (bool) alimenta o item 4 de `calculate_termination.dart`, que paga **um** `BreakdownCode.accruedVacation` de `base × 4/3` se o bool for verdadeiro e `rules.paysAccruedVacation` (verdadeiro em todos os tipos, C1). As avos proporcionais já são desde o último aniversário (`proportionalVacationMonths`, `avos.dart`, com `_addMonths` que ajusta o dia ao fim do mês). `Assumption` tem `code` enum, `text`, `origin`, `value?`, `ruleId?`; `doubleVacation` já está em `validationPendingRules` (e no espelho de `test/golden/validation_status.dart`). A UI de premissas (`AssumptionsSection`), o compartilhamento e o PDF (`buildResultSections`) renderizam `assumption.text` e usam o identifier `result_assumption_<code>`. O histórico salva `input` e `result` e reabre o **salvo** (B5), sem recalcular. `golden_case.dart` lê `entrada.feriasVencidas`; `test/golden/cases/` está vazio.

## Decisions

### D1. Entrada e compatibilidade (B3-01)
`vacationPeriodsTaken` (int) substitui o bool. `fromJson` lê `vacationPeriodsTaken ?? 0` e, separadamente, `hasAccruedVacation == true` para `legacyHasAccruedVacation` (campo somente leitura, fora de qualquer cálculo). `toJson` grava `vacationPeriodsTaken` e regrava `hasAccruedVacation: true` só enquanto o legado for verdadeiro (não perde dado ao salvar nota no histórico, `history_repository`). Não há bump de `schemaVersion`: o resultado salvo continua válido e `accruedVacation` permanece no enum para ler itens antigos. Descartado: recalcular o legado como "1 período" (muda o valor sem aviso; contraria B5-06 e o ⚖️ de B3-01). Não há consumidor de UI para o campo legado hoje (Open Question 4).

### D2. `VacationPeriods.derive` pura (B3-02, B3-03)
Arquivo novo `lib/domain/rules/vacation_periods.dart`, ao lado de `avos.dart`. Entrada: três parâmetros (admissão, rescisão, `taken`); saída: `n` e lista imutável de `VacationPeriod`. Sem relógio, sem I/O. A âncora `A+k·a` reusa a soma de meses de `avos.dart` (exposta como função pública do mesmo arquivo ou movida para um helper compartilhado, uma única definição: DRY, regra de negócio única). Dia do fim do concessivo: `A+(i+1)a` é a data exata; **dobro só se a rescisão for estritamente posterior** (SPECS B3-03 literal; no dia, ainda simples). Esse ponto e a âncora de 29/02 são ⚖️ (Open Question 1).

### D3. Valores no use case (B3-04, B3-05)
O item 4 do use case é trocado por `_accruedVacationItems(base, periods)`: conta `simple` e `double` e cria no máximo um item por código (`accruedVacationSimple`, `accruedVacationDouble`), `value = _roundCurrency(count × fator × base × 4/3)`, `details` "k período(s)". Agregar por código mantém a identidade por `code` (B2-01) e linhas separadas; o detalhe por período fica na tabela de premissas. O item do dobro leva "(indenização)" na descrição. Gate: `rules.paysAccruedVacation`. Impostos: nenhuma mudança (`calculateTerminationTaxes` já exclui férias, C4). A **projeção do aviso não cria nem converte** períodos vencidos: afeta só as avos do proporcional (já limitadas a 12); ⚖️ (Open Question 2). Escrito em `double` com o padrão atual para a migração de `migrate-money-to-decimal` ser mecânica.
Descartado: uma linha por período (quebra a identidade por `code`, polui o resultado com n linhas); calcular o dobro dentro de `avos.dart` (mistura avos com valores).

### D4. Premissas (B3-07, B6-04)
Novo `AssumptionCode.vacationPeriods`: **uma** premissa cujo `text` tem uma linha por período (formato `1) 15/06/2022–14/06/2023, concessivo até 15/06/2024: dobro`). Uma só premissa preserva `result_assumption_<code>` único, cabe no histórico (reabre salvo) e chega ao texto compartilhado e ao PDF sem mudar `buildResultSections`. Com período `double`, o use case acrescenta `validationPending` com `ruleId: doubleVacation`; a função `_validationPending` hoje tem o texto fixo do acordo mútuo e passa a receber o texto por regra (mapa `ruleId → texto`, no mesmo lugar). Descartado: um `Assumption` por período (identifier duplicado; `ValidationNotice` listaria todos).

### D5. Formulário e validação (B3-06, B3-08)
`form_screen.dart` troca o `CheckboxListTile` por um stepper (botões `-`/`+` com `Semantics.identifier`, valor entre eles). `n` vem de uma função pura chamada pela tela (`VacationPeriods.derive(...).n` ou `fullYears` auxiliar), sem relógio. Estado: `_vacationTaken` e `_vacationTouched`; enquanto não tocado, `_vacationTaken = n`; ao mudar datas, `_vacationTaken = min(_vacationTaken, n)`. **Padrão = n** preserva o comportamento atual (checkbox desmarcado = nada vencido a pagar) e evita que o app pague dobro por padrão (Open Question 3). `TerminationInputValidator._validateBusinessRules` ganha `taken < 0 || taken > n` (calcula `n` com a mesma função). Aviso fixo abaixo do stepper (texto em `l10n`). Seguindo D4 do SPECS, extrair o campo para um widget próprio ao tocar o formulário.

### D6. Golden e testes (B6)
`golden_case.dart` troca `feriasVencidas` por `feriasGozadas` (int; ausente vale 0, como no construtor). Como `cases/` está vazio, é troca sem migração de arquivos. Os ~25 usos de `hasAccruedVacation` em `test/` migram: `true` vira `vacationPeriodsTaken: 0` com datas que gerem 1 período vencido; `false` vira o `n` do caso (ou 0 quando `n = 0`). Os valores esperados dos testes existentes não mudam. Casos de borda de `derive` com datas fixas (nenhum teste usa `DateTime.now`).

### D7. Identificadores Maestro
`form_vacation_taken`, `form_vacation_taken_increment`, `form_vacation_taken_decrement`, `result_assumption_vacationPeriods`. O fluxo novo fica em `.maestro/tests/first_run/` ou `returning/` conforme a convenção da skill `maestro-e2e` (o executor decide pelo estado do app); reusa `fill_basic_form` com admissão parametrizada se o subfluxo permitir `ADMISSION` (já permite).

## Risks / Trade-offs
- **Regra ⚖️ do dobro:** o fim do concessivo, a âncora de 29/02 e a ausência de caso golden real mantêm a regra em `validationPendingRules`; a marca "cálculo em validação" aparece sempre que houver dobro (B6-04). Publicação depende de B6-05/B6-06 (pendência do responsável, contador).
- **Conflito com `migrate-money-to-decimal`:** ambas mexem em `calculate_termination.dart`. Mitigação: função `_accruedVacationItems` isolada e em `double`; a migração a converte junto com o resto.
- **Mudança de semântica da entrada:** antes "tem vencidas?"; agora "quantos gozou?". Default = n mantém o resultado de quem não mexe; quem marcava o checkbox precisa reduzir o stepper.
- **Formulário mais longo (PRD):** um único campo, só habilitado com datas válidas.

## Open Questions
1. ⚖️ **Dia exato do fim do concessivo e âncora de 29/02/fim de mês** (B3-03). Recomendação: dobro só depois de `A+(i+1)a` (no dia, simples) e âncora no último dia do mês de destino (igual a `avos.dart`); manter `doubleVacation` pendente até haver caso com fonte.
2. ⚖️ **Projeção do aviso cria período vencido?** (OJ 82 SDI-1 conta o aviso como tempo de serviço). Recomendação: não; só avos do proporcional, como B3-04 e B2-05.
3. **Valor padrão do stepper.** Recomendação: padrão `n` (nada vencido) até o usuário tocar. Alternativa: 0 (assume nada gozado), que pode gerar dobro sem o usuário perceber.
4. **Exibir `legacyHasAccruedVacation` no histórico** (SPECS B3-01 "apenas para exibição"): hoje nenhuma tela mostra o input de férias. Recomendação: só preservar o dado e não criar UI (YAGNI); exibir "1 período vencido" quando surgir uma tela que mostre o input.
5. **Padrão do SPECS B3-01** diz "legado assume 0" no `fromJson`; combinado com a Q3, registros antigos reabrem pelo resultado salvo e nunca usam esse 0 para calcular.
