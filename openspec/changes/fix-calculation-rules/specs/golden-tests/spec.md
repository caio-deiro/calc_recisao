## MODIFIED Requirements

### Requirement: Single golden runner
Um único `test/golden/golden_test.dart` MUST carregar todos os casos de `test/golden/cases/` e comparar cada verba e cada total suportado, identificando a verba por `item.code.name`, usando a constante única `goldenTolerance`, igual a 0,01 até a change `migrate-money-to-decimal` (B2-13) e 0,00 depois. Verba produzida pelo app e ausente do esperado MUST falhar o caso se o valor for diferente de zero. Itens de `fgtsDeposit` MUST ser comparados como verbas e os totais `paidAtTermination` e `fgtsDeposit` MUST ser suportados. Campo de entrada ainda não suportado pelo app MUST ser pulado com motivo explícito, nunca em silêncio.

#### Scenario: Value within tolerance passes
- **WHEN** o comparador recebe 100,00 e 100,01 com tolerância 0,01
- **THEN** considera igual, e com 100,02 MUST considerar diferente

#### Scenario: Extra verba fails
- **WHEN** o app produz uma verba de valor 50,00 que o esperado não lista
- **THEN** o caso MUST falhar apontando o code da verba

#### Scenario: Totals of two kinds are compared
- **WHEN** um caso traz `paidAtTermination` e `fgtsDeposit` em `totais`
- **THEN** o runner MUST compará-los em vez de pulá-los

#### Scenario: Unsupported input is skipped visibly
- **WHEN** um caso traz `periodosFeriasGozados` e o app ainda não suporta o campo
- **THEN** o caso MUST ser pulado com o motivo impresso, e não contado como aprovado

#### Scenario: Empty cases directory
- **WHEN** `test/golden/cases/` não tem nenhum caso
- **THEN** `flutter test test/golden` MUST passar e imprimir que não há casos

## REMOVED Requirements

### Requirement: Provisional verba mapping isolated
**Reason**: `BreakdownCode` passa a existir em `lib/` (B2-01); o mapa por `description` deixa de ter função.
**Migration**: apagar `test/golden/support/provisional_code_map.dart` e seu teste; o runner usa `item.code.name`.
