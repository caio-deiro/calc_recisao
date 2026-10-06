## MODIFIED Requirements

### Requirement: Rules table by termination type
Deve existir um `TerminationRules` imutável por `TerminationType` com: percentual do aviso (100/50/0), fração da multa do FGTS sobre a alíquota de `tax_tables.json` (1,0/0,5/0), paga 13º, paga férias proporcionais, paga férias vencidas, aviso descontável, indenização art. 479 e desconto art. 480. A tabela MUST ter uma entrada para cada um dos 8 tipos (`withoutJustCause`, `indirectTermination`, `resignation`, `withJustCause`, `mutualAgreement`, `fixedTermEnd`, `fixedTermEarlyByEmployer`, `fixedTermEarlyByEmployee`), espelhando a matriz do PRD §6.1; `hasIndemnity479` MUST ser verdadeiro só em `fixedTermEarlyByEmployer` e `hasDiscount480` só em `fixedTermEarlyByEmployee`. `indirectTermination` MUST ter os mesmos valores de `withoutJustCause`. Os booleanos soltos de `TerminationType` (`hasFgtsPenalty`, `hasReducedFgtsPenalty`, `hasReducedNotice`, `allowsFgtsWithdrawal`) MUST ser removidos ou derivados da tabela. O use case MUST decidir quais itens entram **antes** de adicioná-los, MUST NOT remover itens depois e MUST NOT conter condicional por `TerminationType` fora da tabela de regras. (B2-02, B2-03, B4-01, B4-08)

#### Scenario: Matrix mirrors PRD 6.1
- **WHEN** se consulta `TerminationRules` para cada um dos 8 tipos
- **THEN** os valores coincidem com a coluna correspondente da matriz do PRD §6.1 (com C1 aplicado)

#### Scenario: Indirect equals without just cause
- **WHEN** se compara `TerminationRules.of(indirectTermination)` com `TerminationRules.of(withoutJustCause)`
- **THEN** todos os campos são iguais

#### Scenario: Mutual agreement
- **WHEN** o tipo é `mutualAgreement` e o aviso é indenizado
- **THEN** o item `notice` vale 50 % do aviso integral e `fgtsFine` usa 20 % (0,5 sobre a alíquota de 40 %)

#### Scenario: Resignation without worked notice
- **WHEN** o tipo é `resignation` e o aviso não foi trabalhado
- **THEN** existe `noticeDiscount` e não existe `notice`

#### Scenario: No type branching in the use case
- **WHEN** se busca `type ==` e `TerminationType.` em `calculate_termination.dart`
- **THEN** não há comparação de tipo para decidir verba (a única exceção atual, o texto do aviso do acordo mútuo, MUST passar a ser derivada da tabela)

### Requirement: Termination type name mapping
`CalculationHistory.fromJson` MUST resolver `terminationType` com `orElse` e MUST mapear nomes antigos em uma tabela única de aliases, que MUST conter `fixedTerm` para `fixedTermEnd`. `fixedTerm` MUST NOT existir no enum `TerminationType` (a UI não o oferece). Nome desconhecido MUST NOT lançar exceção não tratada nem sumir em silêncio: o registro MUST seguir o fluxo de registro ilegível de B2-11. Um registro antigo com `fixedTerm` MUST abrir exibindo o valor salvo, sem recalcular, mesmo sem `fixedTermEndDate` no input. (B2-12, B4-02)

#### Scenario: Old name mapped
- **WHEN** o JSON traz `terminationType: fixedTerm`
- **THEN** `fromJson` devolve `TerminationType.fixedTermEnd` e o registro abre com os valores salvos

#### Scenario: Old input without new fields
- **WHEN** `TerminationInput.fromJson` recebe JSON sem `fixedTermEndDate` e sem `hasRecipientClause`
- **THEN** `fixedTermEndDate` é nulo e `hasRecipientClause` é falso, sem exceção

#### Scenario: Unknown name
- **WHEN** o JSON traz um nome fora do enum e dos aliases
- **THEN** o registro é tratado como ilegível, sem exceção vazar para a UI

### Requirement: FGTS withdrawal percent in the rules table
`TerminationRules` MUST expor `fgtsWithdrawalPercent` (`int?`): 100 para `withoutJustCause`, `indirectTermination`, `fixedTermEnd` e `fixedTermEarlyByEmployer`; 80 para `mutualAgreement`; nulo para `resignation`, `withJustCause` e `fixedTermEarlyByEmployee` (informativo, sem valor calculado). A UI MUST ler esse campo; nenhuma condicional por tipo para a linha de saque MUST existir fora da tabela. (B5-01, B4-01, B4-07)

#### Scenario: Percent by type
- **WHEN** se consulta `TerminationRules` dos 8 tipos
- **THEN** `withoutJustCause`, `indirectTermination`, `fixedTermEnd` e `fixedTermEarlyByEmployer` = 100, `mutualAgreement` = 80 e `resignation`, `withJustCause`, `fixedTermEarlyByEmployee` = nulo

## ADDED Requirements

### Requirement: Recipient clause resolved by the rules table
A tabela `TerminationRules` MUST expor uma resolução `TerminationRules.resolve(type, hasRecipientClause)`, usada pelo use case no lugar de `of`. Com `hasRecipientClause = true`, `fixedTermEarlyByEmployer` MUST resolver para as regras de `withoutJustCause` e `fixedTermEarlyByEmployee` para as de `resignation`; nesse caso MUST NOT haver art. 479 nem art. 480, e o aviso prévio MUST seguir as regras do tipo equivalente (incluindo `noticeWorked`). Com `false`, ou em qualquer outro tipo, MUST resolver para a entrada do próprio tipo. O mapeamento MUST ficar em dados da tabela, não em `if` no use case. (CLT art. 481; B4-04)

#### Scenario: Employer early termination with clause
- **WHEN** tipo `fixedTermEarlyByEmployer`, `hasRecipientClause = true`, aviso indenizado
- **THEN** o resultado tem `notice` (100 %) e `fgtsFine` (40 %), e não tem `indemnity479`

#### Scenario: Employee early termination with clause
- **WHEN** tipo `fixedTermEarlyByEmployee`, `hasRecipientClause = true`, aviso não trabalhado
- **THEN** o resultado tem `noticeDiscount` e não tem `indemnity480` nem `fgtsFine`

#### Scenario: Clause is ignored in other types
- **WHEN** tipo `fixedTermEnd` com `hasRecipientClause = true`
- **THEN** o resultado é idêntico ao de `hasRecipientClause = false`

### Requirement: Art. 479 indemnity
Em `fixedTermEarlyByEmployer` sem cláusula assecuratória, o resultado MUST incluir um item `BreakdownCode.indemnity479`, em provento, igual a `(salário + média) / 30 × dias restantes × 50 %`, com `dias restantes = fixedTermEndDate − terminationDate` em dias de calendário (diferença de datas, sem contar o dia da rescisão), arredondado a 2 casas (half-up). O item MUST NOT entrar na base de INSS nem de IRRF, e a multa de 40 % do FGTS MUST continuar devida. A regra `art479` MUST permanecer em `validationPendingRules`, gerando a premissa "cálculo em validação". A convenção de contagem de dias é ⚖️ (ver `design.md`) e MUST ser trocável por uma única constante/função. (CLT art. 479; PRD §6.6, Q27; B4-05)

#### Scenario: Indemnity value
- **WHEN** salário 3.000, média 0, rescisão 2026-03-10, fim previsto 2026-04-09 (30 dias restantes)
- **THEN** `indemnity479` vale 1.500,00 e é provento

#### Scenario: Outside tax bases
- **WHEN** o mesmo cálculo roda com e sem `indemnity479`
- **THEN** `inss` e `irrf` são iguais nos dois casos

#### Scenario: Validation pending mark
- **WHEN** existe `indemnity479` no resultado
- **THEN** há uma premissa `validationPending` com `ruleId` igual a `art479`

### Requirement: Art. 480 discount
Em `fixedTermEarlyByEmployee` sem cláusula assecuratória, o resultado MUST incluir um item `BreakdownCode.indemnity480`, em desconto, igual a `min(valor do art. 479 calculado com os mesmos dados, 1 remuneração mensal)`, com `1 remuneração mensal = salário + média`. O item MUST NOT alterar a base de INSS nem de IRRF, MUST NOT haver multa de 40 % e o resultado MUST exibir o aviso "valor máximo; depende de comprovação do prejuízo" (como premissa). A regra `art480` MUST permanecer em `validationPendingRules`. O desconto MUST NOT exceder 1 remuneração mensal. (CLT art. 480 §1º e art. 477 §5º; PRD §6.6, Q27; B4-06)

#### Scenario: Cap at one monthly remuneration
- **WHEN** salário 3.000, média 0 e 120 dias restantes (art. 479 equivalente = 6.000)
- **THEN** `indemnity480` vale 3.000,00

#### Scenario: Below the cap
- **WHEN** salário 3.000, média 0 e 30 dias restantes (art. 479 equivalente = 1.500)
- **THEN** `indemnity480` vale 1.500,00

#### Scenario: Not in tax base
- **WHEN** o cálculo roda com e sem `indemnity480`
- **THEN** `inss` e `irrf` são iguais e `totalDeductions` difere exatamente do valor do item

#### Scenario: Notice shown
- **WHEN** existe `indemnity480` no resultado
- **THEN** há premissa com o texto "valor máximo; depende de comprovação do prejuízo" e premissa `validationPending` com `ruleId` igual a `art480`

### Requirement: Fixed-term normal end
Em `fixedTermEnd` o resultado MUST NOT ter `notice`, `noticeDiscount` nem `fgtsFine`, e MUST ter saldo de salário, 13º proporcional e férias (vencidas e proporcionais, conforme B3), com linha informativa de saque do FGTS. (PRD §6.6; B4-07)

#### Scenario: End of term
- **WHEN** tipo `fixedTermEnd` com rescisão igual ao fim previsto
- **THEN** não há `notice`, `noticeDiscount` nem `fgtsFine`; há `thirteenth` e `proportionalVacation`; `fgtsDeposit` é 0

### Requirement: Indirect termination equals without just cause
O resultado de `indirectTermination` MUST ser igual ao de `withoutJustCause` para a mesma entrada, produzido pela tabela de regras, sem ramificação nova no use case. (PRD §6.1; B4-08)

#### Scenario: Same result
- **WHEN** a mesma entrada é calculada nos dois tipos
- **THEN** itens, valores e totais são iguais
