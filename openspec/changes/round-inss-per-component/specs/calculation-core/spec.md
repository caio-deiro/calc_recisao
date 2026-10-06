## MODIFIED Requirements

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
- **THEN** `irrf` é 1.242,41, `inss` 1.143,78 e `paidAtTermination` 51.947,14, com tolerância 0,01

#### Scenario: Golden case exercising the half-cent
- **WHEN** o runner golden executa um caso `calculo_legal` com saldo 2.000,00 e 13º 2.500,00 cujo `inss` esperado (356,38) foi calculado à mão
- **THEN** o app produz 356,38 com tolerância 0,01 e o esperado NÃO foi derivado da saída do app
