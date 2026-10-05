## MODIFIED Requirements

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
