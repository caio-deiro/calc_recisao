## ADDED Requirements

### Requirement: Vacation periods input field
`TerminationInput` MUST substituir `hasAccruedVacation` por `vacationPeriodsTaken` (`int` ≥ 0, padrão 0 no construtor). `toJson` MUST gravar `vacationPeriodsTaken`. `fromJson` MUST aceitar registros sem o campo (assume 0) e MUST preservar o legado `hasAccruedVacation: true` em um campo somente de exibição (`legacyHasAccruedVacation`), regravado por `toJson` enquanto verdadeiro; o legado MUST NOT entrar em nenhum cálculo nem disparar recálculo. (B3-01)

#### Scenario: Old record without the new field
- **WHEN** `fromJson` recebe um JSON com `hasAccruedVacation: false` e sem `vacationPeriodsTaken`
- **THEN** `vacationPeriodsTaken` é 0 e `legacyHasAccruedVacation` é falso

#### Scenario: Legacy flag preserved, not recalculated
- **WHEN** `fromJson` recebe `hasAccruedVacation: true` e o registro faz `toJson` e `fromJson` de novo
- **THEN** `legacyHasAccruedVacation` continua verdadeiro e o resultado salvo do registro não muda

#### Scenario: New record round trip
- **WHEN** um input com `vacationPeriodsTaken: 2` faz `toJson` e `fromJson`
- **THEN** o valor 2 é preservado

### Requirement: Pure derivation of vacation periods
`VacationPeriods.derive(admission, termination, taken)` MUST ser função pura em `lib/domain/` (sem I/O, sem relógio) e MUST devolver `n` (anos completos entre admissão e rescisão) e uma lista de períodos com `index`, `acquisitiveStart`, `acquisitiveEnd`, `concessiveEnd` e `status ∈ {taken, simple, double, proportional}`. Com `A` a admissão e `a` = 1 ano: o período `i` (1…n) tem aquisitivo `[A+(i−1)a, A+i·a)` e concessivo até `A+(i+1)a`. Se `i ≤ taken`, `status = taken`; se `i > taken` e a rescisão é **posterior** a `A+(i+1)a`, `double`; senão `simple`. O período em curso (a partir de `A+n·a`) MUST ser `proportional`. As datas `A+k·a` MUST usar a mesma âncora de `avos.dart` (soma de meses com o dia ajustado ao último dia do mês de destino, ex.: 29/02 vira 28/02 em ano não bissexto). `taken` acima de `n` MUST ser limitado a `n` pela função. (B3-02, B3-03)

#### Scenario: Less than one year
- **WHEN** admissão 10/03/2025 e rescisão 15/06/2025 (`n = 0`)
- **THEN** só há o período `proportional` e nenhum `simple` ou `double`

#### Scenario: Termination exactly on the anniversary
- **WHEN** admissão 15/06/2023, rescisão 15/06/2025 e `taken = 0`
- **THEN** `n = 2`, os períodos 1 e 2 são `simple` (o concessivo do período 1 termina em 15/06/2025, e a rescisão não é posterior) e o `proportional` começa em 15/06/2025

#### Scenario: Concessive expires
- **WHEN** admissão 15/06/2022, rescisão 16/06/2025 e `taken = 0` (`n = 3`)
- **THEN** os períodos 1 (concessivo até 15/06/2024) e 2 (concessivo até 15/06/2025) são `double` e o período 3 é `simple`

#### Scenario: Concessive ends on the termination day
- **WHEN** a rescisão cai exatamente em `A+(i+1)a` do período `i` não gozado
- **THEN** o período `i` é `simple`, e na rescisão do dia seguinte é `double`

#### Scenario: Taken equals n
- **WHEN** `taken = n`
- **THEN** todos os períodos 1…n são `taken` e só resta o `proportional`

#### Scenario: Taken above n is clamped
- **WHEN** `taken` é maior que `n`
- **THEN** o resultado é igual ao de `taken = n`

#### Scenario: Admission on 29 February
- **WHEN** admissão 29/02/2020 e rescisão 28/02/2025
- **THEN** o aniversário de 2025 é 28/02/2025 (âncora de fim de mês), `n = 5` e o período 5 termina o aquisitivo em 28/02/2025

#### Scenario: Result does not depend on today
- **WHEN** os testes de `derive` rodam em qualquer data do sistema
- **THEN** o resultado é o mesmo, pois só usa as datas recebidas

### Requirement: Accrued vacation values and result lines
O use case MUST pagar, para **todos** os tipos de rescisão, com `base = baseSalary + averageAdditions`: férias simples = `base × 4/3` por período `simple` e férias em dobro = `2 × base × 4/3` por período `double` (1/3 sobre o total dobrado, Súmula 328 TST), cada valor arredondado a 2 casas. O resultado MUST ter no máximo um item `BreakdownCode.accruedVacationSimple` e um `BreakdownCode.accruedVacationDouble` (valor somado dos períodos, `details` com a quantidade), em linhas separadas; a descrição do item do dobro MUST identificá-lo como indenização. Esses itens MUST NOT compor a base de INSS nem de IRRF. O dobro MUST NOT aparecer quando nenhum concessivo expirou. As férias proporcionais MUST continuar calculadas por `proportionalVacationMonths` com a projeção do aviso e 1/3. (B3-04, B3-05)

#### Scenario: One simple period
- **WHEN** salário 3.000,00, média 0, `n = 1`, `taken = 0` e rescisão antes do fim do concessivo
- **THEN** há `accruedVacationSimple` de 4.000,00 e nenhum `accruedVacationDouble`

#### Scenario: One double period
- **WHEN** salário 3.000,00, média 0 e um período com concessivo expirado
- **THEN** há `accruedVacationDouble` de 8.000,00 (`2 × 3.000 × 4/3`), descrito como indenização, e nenhum `accruedVacationSimple` para esse período

#### Scenario: Mixed periods
- **WHEN** há um período `double` e um `simple` com salário 3.000,00 e média 600,00
- **THEN** `accruedVacationDouble` = 9.600,00 e `accruedVacationSimple` = 4.800,00

#### Scenario: Just-cause termination still pays
- **WHEN** o tipo é justa causa e há um período `simple`
- **THEN** o item `accruedVacationSimple` é pago (C1) e não há `proportionalVacation`

#### Scenario: Vacation items stay out of taxes
- **WHEN** há férias simples e em dobro e `calculateTaxes` é verdadeiro
- **THEN** INSS e IRRF são iguais aos do mesmo caso sem férias vencidas

#### Scenario: Legacy flag does not change the calculation
- **WHEN** o input tem `legacyHasAccruedVacation = true` e `vacationPeriodsTaken` igual a `n`
- **THEN** o resultado não tem item de férias vencidas

### Requirement: Periods table and validation mark in assumptions
O resultado MUST incluir uma `Assumption` com `code = vacationPeriods`, origem `estimated`, cujo `text` lista, uma linha por período derivado, o índice, as datas do aquisitivo, o fim do concessivo e o status (gozado, simples, **dobro**, proporcional); a linha do dobro MUST conter a palavra "dobro". A premissa MUST existir mesmo com `n = 0` (só a linha proporcional) quando o tipo paga férias proporcionais ou há período vencido. Quando houver período `double` no resultado, MUST existir a `Assumption` `validationPending` com `ruleId = doubleVacation` (regra já registrada em `validationPendingRules`, B6-04); sem período `double`, MUST NOT existir. O texto da marca MUST ser específico da regra (não reutilizar o da projeção do aviso). (B3-07)

#### Scenario: Table lists every period
- **WHEN** `n = 3`, `taken = 1` e o período 2 expirou
- **THEN** a premissa `vacationPeriods` tem 4 linhas: gozado, dobro, simples e proporcional

#### Scenario: Validation mark only with double
- **WHEN** nenhum período é `double`
- **THEN** não há `validationPending` com `ruleId = doubleVacation`

#### Scenario: Validation mark with double
- **WHEN** há um período `double`
- **THEN** há `validationPending` com `ruleId = doubleVacation` e texto citando férias em dobro

#### Scenario: Table reaches share and PDF
- **WHEN** o texto completo é gerado por `buildResultSections`
- **THEN** a seção de premissas contém a tabela de períodos, incluindo a linha "dobro"

### Requirement: Vacation periods form field
O formulário MUST substituir o checkbox "Férias vencidas?" por um *stepper* "Períodos de férias já gozados" com `Semantics.identifier` `form_vacation_taken` (valor), `form_vacation_taken_decrement` e `form_vacation_taken_increment`, limitado a `[0, n]`, com `n` calculado das datas de admissão e rescisão sem relógio. Ao mudar as datas, o limite MUST ser recalculado e o valor MUST ser reduzido a `n` se o exceder. Enquanto o usuário não tocar o stepper, o valor MUST acompanhar `n` (padrão: nenhum período vencido, igual ao padrão atual do checkbox). O formulário MUST mostrar o aviso de que férias fracionadas, abono pecuniário e férias parcialmente gozadas não são tratados. Sem as duas datas válidas, o stepper MUST ficar em 0 e desabilitado. (B3-06)

#### Scenario: Limit follows the dates
- **WHEN** admissão 15/06/2022 e rescisão 15/06/2025 (`n = 3`)
- **THEN** o incremento para em 3 e o decremento em 0

#### Scenario: Dates change lowers the value
- **WHEN** o valor é 3 e a rescisão muda para 15/06/2024 (`n = 2`)
- **THEN** o valor passa a 2

#### Scenario: Untouched value follows n
- **WHEN** o usuário informa as datas e não toca o stepper
- **THEN** o valor é `n` e nenhuma verba de férias vencidas aparece no resultado

#### Scenario: Warning visible
- **WHEN** o formulário é aberto
- **THEN** o aviso sobre férias fracionadas, abono e parcialmente gozadas está visível junto ao campo

### Requirement: Vacation periods validation
`TerminationInputValidator` MUST rejeitar `vacationPeriodsTaken < 0` e `vacationPeriodsTaken > n`, com erro de campo `vacationPeriodsTaken`. Datas inconsistentes MUST seguir as regras já existentes, sem erro adicional de férias. (B3-08)

#### Scenario: Taken above the ceiling
- **WHEN** `n = 2` e `vacationPeriodsTaken = 3`
- **THEN** a validação falha com erro em `vacationPeriodsTaken`

#### Scenario: Taken within the ceiling
- **WHEN** `n = 2` e `vacationPeriodsTaken = 2`
- **THEN** não há erro de férias

#### Scenario: Inconsistent dates only report date errors
- **WHEN** a rescisão é anterior à admissão
- **THEN** só os erros de data existentes são reportados, sem erro de `vacationPeriodsTaken`

### Requirement: User journey covered by a Maestro flow
MUST existir fluxo Maestro em `.maestro/tests/` com tags e `Semantics.identifier`, sem `point:`: informar admissão que gera períodos vencidos, ajustar o stepper, calcular, ver a linha de férias em dobro e abrir Premissas com a tabela. (B3-06, B3-07)

#### Scenario: Double vacation journey
- **WHEN** o fluxo informa admissão com concessivo expirado e deixa `taken = 0`
- **THEN** o resultado mostra a linha de férias em dobro, o aviso "cálculo em validação" e, em Premissas, a tabela com a linha "dobro"
