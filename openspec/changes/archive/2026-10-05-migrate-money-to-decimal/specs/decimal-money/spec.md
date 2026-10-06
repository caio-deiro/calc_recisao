## ADDED Requirements

### Requirement: Decimal arithmetic in the domain
O cálculo em `lib/domain/` e em `TaxTablesService.calculateTerminationTaxes` MUST usar `Decimal` (`package:decimal`), com escala explícita em toda divisão e arredondamento half-up a 2 casas por item, aplicado nos mesmos pontos de hoje (`_roundCurrency`). Nenhum valor monetário intermediário MUST ser `double` dentro do domínio. (B2-13)

#### Scenario: Float artifact avoided
- **WHEN** o salário é 1.100,10 e o cálculo envolve divisão por 30 e multiplicação por 3
- **THEN** o valor do item MUST ser o half-up exato a 2 casas, sem resíduo de ponto flutuante

#### Scenario: Half-up at the same points
- **WHEN** um valor intermediário termina em 5 na terceira casa (ex.: 10,005)
- **THEN** o item MUST arredondar para 10,01

#### Scenario: Division has explicit scale
- **WHEN** se inspeciona o domínio por divisões de dinheiro
- **THEN** toda divisão usa `Rational` ou escala explícita

### Requirement: Double at the boundaries
As fronteiras (UI, `toJson`, PDF, compartilhamento) MUST converter para `double`. `TerminationInput` MUST manter `double` e ser convertido na entrada do use case (via texto, sem herdar imprecisão binária). O JSON do histórico MUST continuar com números, legível por versões anteriores do formato (`schemaVersion` inalterado). (B2-14)

#### Scenario: History JSON unchanged
- **WHEN** um resultado é serializado antes e depois da migração para a mesma entrada
- **THEN** o JSON é igual e contém números

#### Scenario: Old record still opens
- **WHEN** `fromJson` recebe um registro gravado antes da migração
- **THEN** o registro abre com os mesmos valores

### Requirement: Migration criterion
Os casos golden (`calculo_legal`, C1–C5) MUST passar antes e depois da troca para `Decimal`, sem alterar valores esperados nem arquivos de `cases/`; antes com tolerância 0,01 e depois com 0,00. Divergência de centavos entre as duas versões MUST ser explicada por escrito e o documento oficial prevalece. A change MUST NOT iniciar sem casos golden em `cases/` e sem `fix-calculation-rules` arquivada. (B2-15)

#### Scenario: Golden suite green on both sides
- **WHEN** `flutter test test/golden` roda antes da troca (0,01) e depois (0,00)
- **THEN** nenhum caso falha e nenhum JSON de `cases/` foi alterado

#### Scenario: Cent divergence
- **WHEN** a troca muda algum valor em 0,01
- **THEN** a causa MUST ser registrada antes da aprovação

#### Scenario: Precondition missing
- **WHEN** `test/golden/cases/` está vazio
- **THEN** a implementação MUST NOT começar e a ausência é reportada ao orquestrador (pendências ⚖️ de B6-06 não bloqueiam)
