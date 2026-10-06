# calculation-core Specification

## Purpose
TBD - created by archiving change fix-calculation-rules. Update Purpose after archive.

## Requirements

### Requirement: Verba identity by code
Todo `BreakdownItem` MUST ter `code` do enum `BreakdownCode` (`salaryBalance`, `notice`, `noticeDiscount`, `thirteenth`, `accruedVacationSimple`, `accruedVacationDouble`, `proportionalVacation`, `fgtsFine`, `inss`, `irrf`, `otherDiscounts`). O valor `accruedVacation` MUST permanecer no enum apenas para leitura de histórico gravado antes desta mudança e MUST NOT ser gerado pelo use case. Nenhuma lógica em `lib/` MUST depender do texto de `description`; o use case MUST NOT conter `removeWhere` nem `.contains` sobre `description`. (B2-01, B3-05)

#### Scenario: Every item has a code
- **WHEN** o use case calcula um caso que gera todas as verbas
- **THEN** cada item do resultado tem `code` não nulo e distinto por verba

#### Scenario: No description-based logic
- **WHEN** se busca `description ==`, `description.contains` e `removeWhere` em `lib/domain/usecases/`
- **THEN** a busca MUST retornar vazio

#### Scenario: Changing the label does not change the result
- **WHEN** o texto de `description` de uma verba é alterado
- **THEN** os valores e totais calculados MUST permanecer iguais

#### Scenario: Saved record with the old accrued vacation code still opens
- **WHEN** `CalculationHistory.fromJson` recebe um item com `code: accruedVacation`
- **THEN** o registro abre e exibe o valor salvo, sem recalcular

### Requirement: Rules table by termination type
Deve existir um `TerminationRules` imutável por `TerminationType` com: percentual do aviso (100/50/0), fração da multa do FGTS sobre a alíquota de `tax_tables.json` (1,0/0,5/0), paga 13º, paga férias proporcionais, paga férias vencidas, aviso descontável, indenização art. 479 e desconto art. 480 (as duas últimas sempre falsas nesta change). Os booleanos soltos de `TerminationType` (`hasFgtsPenalty`, `hasReducedFgtsPenalty`, `hasReducedNotice`, `allowsFgtsWithdrawal`) MUST ser removidos ou derivados da tabela. O use case MUST decidir quais itens entram **antes** de adicioná-los e MUST NOT remover itens depois. (B2-02, B2-03)

#### Scenario: Matrix mirrors PRD 6.1
- **WHEN** se consulta `TerminationRules` para cada um dos 5 tipos atuais
- **THEN** os valores coincidem com a coluna correspondente da matriz do PRD §6.1 (com C1 aplicado)

#### Scenario: Mutual agreement
- **WHEN** o tipo é `mutualAgreement` e o aviso é indenizado
- **THEN** o item `notice` vale 50 % do aviso integral e `fgtsFine` usa 20 % (0,5 sobre a alíquota de 40 %)

#### Scenario: Resignation without worked notice
- **WHEN** o tipo é `resignation` e o aviso não foi trabalhado
- **THEN** existe `noticeDiscount` e não existe `notice`

### Requirement: C1 accrued vacation on just-cause
Na justa causa, quando o usuário informa férias vencidas, o resultado MUST incluir `accruedVacation` igual a `(salário + média) × 4/3`; 13º, férias proporcionais, aviso e multa MUST continuar ausentes. ⚖️ Base confirmada no texto: CLT art. 146 caput (férias adquiridas são devidas "qualquer que seja a causa") e parágrafo único (proporcionais não são devidas na justa causa). A leitura de produto (C1) segue ⚖️ até validação em B6. (B2-04)

#### Scenario: Just cause with accrued vacation
- **WHEN** tipo `withJustCause` e `hasAccruedVacation = true`
- **THEN** há `accruedVacation` e não há `proportionalVacation`, `thirteenth`, `notice` nem `fgtsFine`

### Requirement: C2 notice projection in vacation and thirteenth
Quando houver aviso indenizado (percentual do aviso maior que 0 e aviso não trabalhado), o app MUST somar às avos de 13º e de férias proporcionais 1 mês por 30 dias completos do aviso: aviso de 30 a 59 dias = +1; 60 a 89 = +2; 90 = +3. O total de avos MUST ser limitado a 12. Sem aviso indenizado (trabalhado, pedido de demissão, justa causa) a projeção MUST ser 0. No acordo mútuo a projeção MUST seguir a duração do aviso efetivamente pago (50 %), arredondada para baixo pela mesma regra de 30 dias, e MUST carregar a premissa "cálculo em validação" até um contador confirmar (decidido pelo usuário em 2026-10-05). A projeção MUST aparecer em `assumptions` (B2-10). ⚖️ Base confirmada: CLT art. 487 §1º (integração do período do aviso ao tempo de serviço) e OJ 82 SDI-1 TST (a data de saída anotada na CTPS é a do término do aviso, ainda que indenizado). A projeção em avos de 13º e férias, o teto de 12 e o acordo mútuo (CLT art. 484-A I "a" e II) seguem interpretação ⚖️. (B2-05)

#### Scenario: Notice of 33 days
- **WHEN** a admissão tem 1 ano completo (aviso de 33 dias), tipo `withoutJustCause`, aviso indenizado
- **THEN** a projeção é de +1 avo em `thirteenth` e `proportionalVacation`, e há uma premissa com a projeção

#### Scenario: Notice of 60 and 90 days
- **WHEN** o aviso tem 60 dias e depois 90 dias
- **THEN** a projeção é +2 e +3 avos, respectivamente (respeitado o teto de 12 avos)

#### Scenario: Mutual agreement projects by the paid half
- **WHEN** tipo `mutualAgreement`, aviso integral de 60 dias, aviso indenizado
- **THEN** a projeção usa 30 dias (aviso pago) = +1 avo e há a premissa "cálculo em validação"

#### Scenario: Projection capped at 12 avos
- **WHEN** as avos calculadas somadas à projeção passam de 12
- **THEN** o total usado é 12

#### Scenario: Worked notice does not project
- **WHEN** `noticeWorked = true`
- **THEN** a projeção é 0 e não há premissa de projeção

### Requirement: C3 proportional vacation by acquisitive period
As avos de `proportionalVacation` MUST ser contadas desde o último aniversário da admissão (ou desde a admissão, se houver menos de 1 ano) até a rescisão, com a regra de mês de 15 dias, mais a projeção de C2. As avos do 13º MUST continuar por ano-calendário. O cálculo de avos de férias MUST estar em função própria e testável isolada. ⚖️ Base: CLT art. 146 parágrafo único (1/12 por mês ou fração superior a 14 dias, confirmado no texto) e art. 130; Lei 4.090/62 art. 1º (13º). A leitura "período aquisitivo desde o aniversário" (C3) segue ⚖️. (B2-06)

#### Scenario: Admission not in January
- **WHEN** admissão em 10/03/2020, rescisão em 26/08/2025, sem projeção
- **THEN** `proportionalVacation` usa 6 avos e `thirteenth` usa 8 avos

#### Scenario: Less than one year of service
- **WHEN** admissão em 05/02/2025 e rescisão em 20/06/2025
- **THEN** as avos de férias contam desde a admissão

### Requirement: Months under 15 days count zero
Para 13º e férias proporcionais, o mês da rescisão com menos de 15 dias trabalhados MUST contar zero (fração igual ou superior a 15 dias conta mês integral); o app MUST NOT contar fração `dia/30` de mês. A regra MUST valer em um único ponto compartilhado pelas avos de 13º e de férias e MUST constar em `assumptions`. Decidido pelo usuário em 2026-10-05. ⚖️ Base confirmada no texto: Lei 4.090/62 art. 1º §2º ("fração igual ou superior a 15 dias de trabalho será havida como mês integral") e CLT art. 146 parágrafo único (fração superior a 14 dias, férias); a leitura de que a fração menor é desconsiderada segue ⚖️ até validação em B6. (B2-06, B2-10)

#### Scenario: Day 14 does not count
- **WHEN** a rescisão ocorre no dia 14 do mês
- **THEN** o mês da rescisão não soma avos (0)

#### Scenario: Day 15 counts as a full month
- **WHEN** a rescisão ocorre no dia 15 do mês
- **THEN** o mês da rescisão soma 1 avo

### Requirement: C4 indemnified vacation outside IRRF and INSS
Nenhum valor de férias (vencidas ou proporcionais) MUST compor a base de IRRF nem de INSS. Base INSS confirmada: Decreto 3.048/99 art. 214 §9º IV (férias indenizadas, o adicional de 1/3 e a dobra do art. 137 CLT não integram o salário de contribuição). Base IRRF: Súmulas 125 e 386 STJ e Ato Declaratório PGFN 14/2008 (dobro), conforme página oficial da PGFN; a Lei 7.713/88 art. 6º V trata de indenização e aviso prévio por despedida e MUST NOT ser citada como base de férias. A leitura de produto (C4) segue ⚖️. (B2-07)

#### Scenario: Vacation does not change IRRF
- **WHEN** dois cálculos idênticos diferem apenas por `hasAccruedVacation`
- **THEN** `irrf` e `inss` MUST ser iguais nos dois e a diferença em `paidAtTermination` é o valor das férias

#### Scenario: Service level
- **WHEN** `calculateTerminationTaxes` recebe `vacationAmount` alto
- **THEN** o resultado MUST ser igual ao de `vacationAmount = 0`

### Requirement: C5 independent INSS on thirteenth
O INSS MUST ser apurado em duas bases independentes, saldo de salário e 13º, cada uma com a tabela progressiva e o teto próprios, e `inss = inssSalário + inss13º`. O IRRF mensal MUST deduzir `inssSalário` e o anual MUST deduzir `inss13º`. A tabela é escolhida pela data da rescisão. Base confirmada: Decreto 3.048/99 art. 214 §6º (contribuição do 13º devida no pagamento ou na rescisão) e §7º (incidência sobre o valor bruto "mediante aplicação, em separado, da tabela"); Lei 8.212/91 art. 28 §7º só estabelece que o 13º integra o salário de contribuição. A leitura do teto próprio e do IRRF anual segue ⚖️. (B2-08)

#### Scenario: Both bases above the ceiling
- **WHEN** saldo e 13º são, cada um, maiores que o teto da tabela do ano da rescisão
- **THEN** `inss` é igual a duas vezes o INSS no teto

#### Scenario: Sum is not recomputed
- **WHEN** saldo e 13º são pequenos
- **THEN** `inss` é igual a `calculateInss(saldo) + calculateInss(13º)`

### Requirement: Two totals
`TerminationResult` MUST expor `paidAtTermination` (proventos pagos menos descontos, **sem** a multa) e `fgtsDeposit` (itens e total; hoje só `fgtsFine`). `fgtsFine` MUST NOT constar em `additions`. `netAmount` e `totalToReceive` MUST NOT existir em `TerminationResult` nem em `lib/` (alias deprecado removido); o antigo total com a multa equivale a `paidAtTermination + fgtsDeposit.total`. Σ itens MUST igualar os totais. (B2-09)

#### Scenario: Fine outside paid total
- **WHEN** tipo `withoutJustCause` com FGTS informado
- **THEN** `fgtsDeposit.total` é a multa e `paidAtTermination` não a inclui

#### Scenario: Types without fine
- **WHEN** tipo `resignation`
- **THEN** `fgtsDeposit` é vazio e seu total é 0

#### Scenario: Consumers still show the fine
- **WHEN** tela de resultado, histórico, PDF ou compartilhamento recebem um resultado com multa
- **THEN** a multa vem de `fgtsDeposit` e nenhum deles lê `netAmount` nem `totalToReceive`

#### Scenario: Deprecated alias gone
- **WHEN** se busca `netAmount` e `totalToReceive` em `lib/domain/entities/termination_result.dart` e nos consumidores em `lib/`
- **THEN** a busca retorna vazio (exceto o campo `legacyNetAmount` do histórico e a chave de JSON legada)

### Requirement: Assumptions and validation-pending mark
`TerminationResult.assumptions` MUST ser `List<Assumption>` com `code`, `text`, `origin` (`informed` | `estimated`) e `value?`. O resultado MUST conter, quando aplicável: FGTS estimado vs informado, projeção do aviso, avos de 13º e de férias, mês de 30 dias e regra de 15 dias. Para toda regra de `test/golden/validation_status.dart` que chegue ao resultado, MUST existir a `Assumption` com `code` "cálculo em validação", origem `estimated`, até existir caso golden com fonte (B6-04). (B2-10)

#### Scenario: Estimated FGTS
- **WHEN** não há FGTS informado e o tipo paga multa
- **THEN** há premissa de FGTS com origem `estimated`; com FGTS informado, origem `informed`

#### Scenario: Pending rule shows validation mark
- **WHEN** o cálculo usa uma regra listada em `pendingValidationRules` (ex.: projeção do aviso no acordo mútuo)
- **THEN** há uma `Assumption` "cálculo em validação" citando a regra

#### Scenario: Validated rule has no mark
- **WHEN** a regra não está em `pendingValidationRules`
- **THEN** não há marca de validação para ela

### Requirement: Compatible history schema
`CalculationHistory.toJson` MUST gravar `schemaVersion` inteiro e os novos campos (`code` dos itens, `paidAtTermination`, `fgtsDeposit`, `assumptions`) e MUST NOT gravar `netAmount` nem `totalToReceive`. `fromJson` MUST aceitar registros sem `schemaVersion` (legado) e sem os novos campos, preenchendo com vazios, MUST marcar o registro como legado e MUST preservar o `netAmount` gravado em `CalculationHistory.legacyNetAmount` (`double?`, nulo em registro atual); `paidAtTermination` do legado MUST NOT ser inferido. A UI MUST exibir "calculado em versão anterior" no registro legado. O `HistoryRepository` MUST NOT descartar silenciosamente um registro que falhe ao decodificar: o dado bruto MUST permanecer armazenado e a tela de histórico MUST informar a contagem de registros ilegíveis, sem dados pessoais em log. (B2-11)

#### Scenario: Legacy 1.0.x record opens
- **WHEN** `fromJson` recebe um JSON sem `schemaVersion`, itens sem `code` e sem `assumptions`
- **THEN** o registro é criado, marcado como legado, com listas novas vazias e `legacyNetAmount` igual ao `netAmount` gravado

#### Scenario: New record round trip
- **WHEN** um registro novo faz `toJson` e `fromJson`
- **THEN** `schemaVersion`, itens, totais (`paidAtTermination`, `fgtsDeposit`) e premissas são preservados, `legacyNetAmount` é nulo e o JSON não contém `netAmount`

#### Scenario: Corrupt record is kept and reported
- **WHEN** uma entrada do histórico é um JSON inválido
- **THEN** ela continua em `SharedPreferences` após novas gravações e a UI mostra 1 registro ilegível

### Requirement: Termination type name mapping
`CalculationHistory.fromJson` MUST resolver `terminationType` com `orElse` e MUST mapear nomes antigos (`fixedTerm` para `fixedTermEnd` quando existir, ver B4-02) em uma tabela única. Nome desconhecido MUST NOT lançar exceção não tratada nem sumir em silêncio: o registro MUST seguir o fluxo de registro ilegível de B2-11. (B2-12)

#### Scenario: Old name mapped
- **WHEN** o JSON traz um nome presente na tabela de aliases
- **THEN** `fromJson` devolve o tipo atual correspondente

#### Scenario: Unknown name
- **WHEN** o JSON traz um nome fora do enum e dos aliases
- **THEN** o registro é tratado como ilegível, sem exceção vazar para a UI

### Requirement: FGTS withdrawal percent in the rules table
`TerminationRules` MUST expor `fgtsWithdrawalPercent` (`int?`): 100 para `withoutJustCause`, 80 para `mutualAgreement` e nulo para os demais tipos atuais (informativo, sem valor calculado). A UI MUST ler esse campo; nenhuma condicional por tipo para a linha de saque MUST existir fora da tabela. O tipo `fixedTerm` atual fica nulo até B4. (B5-01)

#### Scenario: Percent by type
- **WHEN** se consulta `TerminationRules` dos 5 tipos atuais
- **THEN** `withoutJustCause` = 100, `mutualAgreement` = 80 e `resignation`, `fixedTerm`, `withJustCause` = nulo
