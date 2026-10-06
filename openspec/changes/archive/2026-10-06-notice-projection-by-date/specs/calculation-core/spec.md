## MODIFIED Requirements

### Requirement: C2 notice projection in vacation and thirteenth
Quando houver aviso indenizado (percentual do aviso maior que 0 e aviso não trabalhado), o app MUST projetar o aviso **por data**: a data efetiva é `terminationDate + diasDeAvisoPagos` dias de calendário (sem horário) e as avos de 13º e de férias proporcionais MUST ser contadas até essa data, com a regra de 15 dias e teto de 12 avos por ano-calendário (13º) ou por período aquisitivo (férias). MUST NOT existir soma de "1 mês por 30 dias". Sem aviso indenizado (trabalhado, pedido de demissão, justa causa) a data efetiva MUST ser a da rescisão. No acordo mútuo `diasDeAvisoPagos` MUST ser a metade do aviso (50 %, inteiro para baixo) e a marca "cálculo em validação" MUST acompanhar a projeção até um contador confirmar. **13º com virada de ano:** se a data efetiva cai em ano posterior ao da rescisão, as avos MUST ser a soma das avos do ano da rescisão contadas até 31/12 e das avos de 1º de janeiro até a data efetiva (cada parcela com teto 12). **Férias:** o início do período aquisitivo MUST ser o último aniversário da admissão na data da rescisão; se a contagem até a data efetiva passar de 12, o total MUST ser 12, e a projeção MUST NOT criar período de férias vencido. A projeção MUST aparecer em `assumptions` (B2-10) com a data de fim do aviso e os avos extras reais de cada verba (avos com projeção menos avos sem projeção). Esta revisão da decisão Q7a do PRD foi pedida pelo responsável em 2026-10-06. ⚖️ Base: CLT art. 487 §1º, Súmula 371 TST e OJ 82 SDI-1 TST (texto primário da OJ não lido; citação em acórdão do TST); a leitura em avos por data, a virada de ano e o acordo mútuo (CLT art. 484-A I "a"; fontes secundárias) seguem ⚖️ sem validação profissional (caso golden `calculo_legal`). (B2-05, B6-03)

#### Scenario: Notice of 33 days
- **WHEN** tipo `withoutJustCause`, admissão 10/03/2025, rescisão 20/05/2026 (1 ano completo, aviso de 33 dias), aviso indenizado
- **THEN** a data efetiva é 22/06/2026, `thirteenth` usa 6 avos e `proportionalVacation` usa 3 avos, e há uma premissa com a projeção

#### Scenario: Notice of 60 and 90 days
- **WHEN** rescisão em 26/08/2025 com aviso indenizado de 60 dias (admissão 10/03/2015) e depois de 90 dias (admissão 10/03/2005)
- **THEN** com 60 dias a data efetiva é 25/10/2025, `thirteenth` usa 10 avos e `proportionalVacation` 8 avos; com 90 dias a data efetiva é 24/11/2025, `thirteenth` usa 11 avos e `proportionalVacation` 9 avos

#### Scenario: Projection capped at 12 avos
- **WHEN** admissão 10/03/2020, rescisão 26/02/2026, aviso indenizado de 48 dias (data efetiva 15/04/2026), cuja contagem de férias chega a 13 avos
- **THEN** `proportionalVacation` usa 12 avos, `thirteenth` usa 4 avos e não surge período de férias vencido novo

#### Scenario: Notice of 45 days ends in another month
- **WHEN** tipo `withoutJustCause`, admissão 10/03/2021, rescisão 05/09/2026, aviso indenizado de 45 dias
- **THEN** a data efetiva é 20/10/2026, `thirteenth` usa 10 avos e `proportionalVacation` usa 7 avos (não 8+1 nem 6+1 por 30 dias)

#### Scenario: Date rule can give fewer avos than plus one
- **WHEN** admissão 15/01/2016, rescisão 15/08/2026, aviso indenizado de 60 dias (data efetiva 14/10/2026)
- **THEN** `thirteenth` usa 9 avos (janeiro a setembro; outubro com 14 dias não conta), um a menos que os 10 do método antigo (8 + 60 ÷ 30 = 10), e `proportionalVacation` usa 9 avos

#### Scenario: Mutual agreement projects by the paid half
- **WHEN** tipo `mutualAgreement`, admissão 15/01/2020, rescisão 31/07/2026, aviso integral de 48 dias (24 pagos)
- **THEN** a data efetiva é 24/08/2026, `thirteenth` usa 8 avos, `proportionalVacation` usa 7 avos e há a premissa "cálculo em validação" (`noticeProjectionMutualAgreement`)

#### Scenario: Thirteenth across the year boundary
- **WHEN** admissão 10/03/2020, rescisão 20/12/2026, aviso indenizado de 30 dias (data efetiva 19/01/2027)
- **THEN** `thirteenth` usa 13 avos (12 de 2026 e 1 de 2027) e `proportionalVacation` usa 10 avos

#### Scenario: Assumption shows the real extra avos
- **WHEN** o cenário de 45 dias acima é calculado
- **THEN** `assumptions` contém `noticeProjection` com a data 20/10/2026, "+2 avo(s) no 13º" (8 sem projeção, 10 com) e "+1 avo(s) nas férias proporcionais" (6 sem, 7 com)

#### Scenario: Worked notice does not project
- **WHEN** `noticeWorked = true`
- **THEN** a data efetiva é a da rescisão e não há premissa de projeção

#### Scenario: Golden cases by date
- **WHEN** o runner golden executa `golden_acordo_mutuo` (acordo, `calculo_legal`) e `golden_sem_justa_causa_c2_c5`
- **THEN** o acordo dá `thirteenth` 2.333,33, `proportionalVacation` 2.722,22 e `paidAtTermination` 10.861,27; o sem justa causa dá `thirteenth` 10.000,00 e `paidAtTermination` 52.672,14, com tolerância 0,01

### Requirement: C3 proportional vacation by acquisitive period
As avos de `proportionalVacation` MUST ser contadas desde o último aniversário da admissão (ou desde a admissão, se houver menos de 1 ano) até a data efetiva da rescisão, com a regra de mês de 15 dias; a data efetiva é a da rescisão acrescida dos dias de aviso indenizado pagos (C2). As avos do 13º MUST continuar por ano-calendário. O cálculo de avos de férias MUST estar em função própria e testável isolada. ⚖️ Base: CLT art. 146 parágrafo único (1/12 por mês ou fração superior a 14 dias, confirmado no texto) e art. 130; Lei 4.090/62 art. 1º (13º). A leitura "período aquisitivo desde o aniversário" (C3) segue ⚖️. (B2-06)

#### Scenario: Admission not in January
- **WHEN** admissão em 10/03/2020, rescisão em 26/08/2025, sem aviso projetado
- **THEN** `proportionalVacation` usa 6 avos e `thirteenth` usa 8 avos

#### Scenario: Less than one year of service
- **WHEN** admissão em 05/02/2025 e rescisão em 20/06/2025
- **THEN** as avos de férias contam desde a admissão

### Requirement: C5 independent INSS on thirteenth
O INSS MUST ser apurado em duas bases independentes, saldo de salário e 13º, cada uma com a tabela progressiva e o teto próprios. Cada INSS MUST ser arredondado half-up a 2 casas ANTES de somar: `inss = round(inssSalário) + round(inss13º)`; a soma MUST NOT ser arredondada de novo sobre valores crus. A base do IRRF de cada parcela MUST usar o INSS já arredondado dessa parcela. O IRRF MUST ser apurado em duas bases independentes, ambas pela tabela progressiva MENSAL vigente na data da rescisão: o do saldo deduz `inssSalário` e o do 13º deduz `inss13º`; `irrf = irrfSaldo + irrf13º`. O IRRF do 13º MUST NOT usar tabela nem redução anuais. Base confirmada: Decreto 3.048/99 art. 214 §6º e §7º (INSS, tabela em separado; recolhimentos distintos, daí o arredondamento por parcela); Lei 7.713/88 art. 26 (13º tributado exclusivamente na fonte, em separado dos demais rendimentos); SEFAZ-SP, "Rendimentos sujeitos a tributação exclusiva na fonte"; Lei 15.270/2025, art. 3º-A §3º da Lei 9.250/95 (a redução vale também para o 13º). ⚖️ sem validação profissional (caso golden `calculo_legal`). (B2-08, B6-03)

#### Scenario: Both bases above the ceiling
- **WHEN** saldo e 13º são, cada um, maiores que o teto da tabela do ano da rescisão
- **THEN** `inss` é igual a duas vezes o INSS no teto, cada um arredondado a 2 casas

#### Scenario: Sum is not recomputed
- **WHEN** saldo e 13º são pequenos
- **THEN** `inss` é igual a `round(calculateInss(saldo)) + round(calculateInss(13º))`, sem novo arredondamento da soma

#### Scenario: Each INSS rounded before the sum
- **WHEN** `calculateTerminationTaxes` recebe saldo = 2.000,00, 13º = 2.500,00, rescisão em 2026-09-05, sem dependentes
- **THEN** `inssSalary` é 155,69 (155,685), `inssThirteenth` é 200,69 (200,685), `inss` é 356,38 (não 356,37) e `irrf` é 0,00

#### Scenario: IRRF base uses rounded INSS
- **WHEN** o INSS cru de uma parcela tem 3 casas (ex.: saldo 2.000,00 → 155,685)
- **THEN** a base do IRRF dessa parcela é `bruto − 155,69`

#### Scenario: Result line is the rounded sum
- **WHEN** `CalculateTermination` roda com saldo 2.000,00 e 13º 2.500,00 no mesmo cenário
- **THEN** o item `BreakdownCode.inss` vale 356,38

#### Scenario: Thirteenth IRRF uses the monthly table
- **WHEN** `calculateTerminationTaxes` recebe 13º = 9.000,00, saldo = 0, 1 dependente, rescisão em 2026-09-05
- **THEN** `inssThirteenth` é 988,09 e `irrf` é 1.242,41 (base 9.000 - 988,09 - 189,59 = 7.822,32; faixa 27,5% com dedução 908,73; sem redução porque o rendimento bruto 9.000 é maior que 7.350)

#### Scenario: Golden case sem justa causa C2/C5
- **WHEN** o runner golden executa `golden_sem_justa_causa_c2_c5` (`fonte.tipo = calculo_legal`)
- **THEN** `irrf` é 1.517,41, `inss` 1.143,78 e `paidAtTermination` 52.672,14, com tolerância 0,01 (13º de 10 avos = 10.000,00 pela projeção por data, change `notice-projection-by-date`)

#### Scenario: Golden case exercising the half-cent
- **WHEN** o runner golden executa um caso `calculo_legal` com saldo 2.000,00 e 13º 2.500,00 cujo `inss` esperado (356,38) foi calculado à mão
- **THEN** o app produz 356,38 com tolerância 0,01 e o esperado NÃO foi derivado da saída do app
