## MODIFIED Requirements

### Requirement: C5 independent INSS on thirteenth
O INSS MUST ser apurado em duas bases independentes, saldo de salário e 13º, cada uma com a tabela progressiva e o teto próprios, e `inss = inssSalário + inss13º`. O IRRF MUST ser apurado em duas bases independentes, ambas pela tabela progressiva MENSAL vigente na data da rescisão: o do saldo deduz `inssSalário` e o do 13º deduz `inss13º`; `irrf = irrfSaldo + irrf13º`. O IRRF do 13º MUST NOT usar tabela nem redução anuais. Base confirmada: Decreto 3.048/99 art. 214 §6º e §7º (INSS, tabela em separado); Lei 7.713/88 art. 26 (13º tributado exclusivamente na fonte, em separado dos demais rendimentos); SEFAZ-SP, "Rendimentos sujeitos a tributação exclusiva na fonte"; Lei 15.270/2025, art. 3º-A §3º da Lei 9.250/95 (a redução vale também para o 13º). ⚖️ sem validação profissional (caso golden `calculo_legal`). (B2-08)

#### Scenario: Both bases above the ceiling
- **WHEN** saldo e 13º são, cada um, maiores que o teto da tabela do ano da rescisão
- **THEN** `inss` é igual a duas vezes o INSS no teto

#### Scenario: Sum is not recomputed
- **WHEN** saldo e 13º são pequenos
- **THEN** `inss` é igual a `calculateInss(saldo) + calculateInss(13º)`

#### Scenario: Thirteenth IRRF uses the monthly table
- **WHEN** `calculateTerminationTaxes` recebe 13º = 9.000,00, saldo = 0, 1 dependente, rescisão em 2026-09-05
- **THEN** `inssThirteenth` é 988,09 e `irrf` é 1.242,41 (base 9.000 - 988,09 - 189,59 = 7.822,32; faixa 27,5% com dedução 908,73; sem redução porque o rendimento bruto 9.000 é maior que 7.350)

#### Scenario: Golden case sem justa causa C2/C5
- **WHEN** o runner golden executa `golden_sem_justa_causa_c2_c5` (`fonte.tipo = calculo_legal`)
- **THEN** `irrf` é 1.242,41, `inss` 1.143,78 e `paidAtTermination` 51.947,14, com tolerância 0,01

## ADDED Requirements

### Requirement: IRRF reducer on gross taxable income
A redução da Lei 15.270/2025 (art. 3º-A da Lei 9.250/95) MUST ser calculada sobre o rendimento tributável BRUTO do respectivo pagamento (saldo de salário ou 13º, antes de INSS e dependentes; férias indenizadas fora, conforme C4), e não sobre a base já deduzida. Faixas: rendimento até 5.000,00 reduz até 312,89 (limitada ao imposto, que fica zero); de 5.000,01 a 7.350,00 reduz `978,62 - 0,133145 x rendimento`; acima de 7.350,00 não reduz. O imposto bruto (tabela mensal sobre a base deduzida) MUST continuar calculado sobre a base deduzida, e a redução nunca torna o imposto negativo. Os valores MUST vir de `tax_tables.json`. Fonte: Lei 15.270/2025; exemplo oficial da Receita Federal (978,62 - 0,133145 x 6.000). ⚖️ (B2-07, B2-08)

#### Scenario: Gross above the limit while deducted base is below
- **WHEN** o rendimento bruto é 7.500,00 e a base após INSS e dependentes é menor que 7.350,00 (tabela mensal 2026)
- **THEN** a redução MUST ser 0 e o IRRF é o imposto bruto da tabela

#### Scenario: Gross inside the gradual range
- **WHEN** o rendimento bruto é 6.000,00 e o imposto bruto é maior que a redução
- **THEN** a redução MUST ser 978,62 - 0,133145 x 6.000 = 179,752

#### Scenario: Gross up to 5.000
- **WHEN** o rendimento bruto é até 5.000,00
- **THEN** a redução MUST ser `min(imposto bruto, 312,89)` e o IRRF resultante não é negativo

#### Scenario: Annual path removed
- **WHEN** o código é compilado após a change
- **THEN** não MUST existir `calculateIrrfAnnual` nem `_applyAnnualReducer`, e `flutter analyze` MUST passar sem avisos
