## ADDED Requirements

### Requirement: Fixed-term input fields
`TerminationInput` MUST ter `fixedTermEndDate` (`DateTime?`) e `hasRecipientClause` (`bool`, padrão falso), gravados em `toJson` e lidos por `fromJson` com ausência tolerada (nulo e falso). Nos tipos `fixedTermEnd`, `fixedTermEarlyByEmployer` e `fixedTermEarlyByEmployee` a data de fim prevista MUST ser obrigatória. Os campos MUST NOT ser exigidos nem exibidos nos demais tipos. (B4-03)

#### Scenario: Round trip
- **WHEN** um input com `fixedTermEndDate` e `hasRecipientClause = true` faz `toJson` e `fromJson`
- **THEN** os dois campos são preservados

#### Scenario: Missing end date in a fixed-term type
- **WHEN** o tipo é a prazo e `fixedTermEndDate` é nulo
- **THEN** a validação falha com erro no campo `fixedTermEndDate`

### Requirement: Fixed-term validations
`TerminationInputValidator` MUST receber o tipo e aplicar, só nos tipos a prazo: (a) `fixedTermEndDate` posterior à admissão, bloqueante; (b) nos tipos "antecipada", rescisão menor ou igual ao fim previsto, bloqueante; (c) no tipo "término normal", se a rescisão for diferente do fim previsto, um **aviso não bloqueante** exibido no formulário (não impede o cálculo). Datas inconsistentes de admissão e rescisão seguem as regras existentes. A validação de "data no futuro" MUST NOT se aplicar a `fixedTermEndDate`. (B4-03)

#### Scenario: End before admission
- **WHEN** fim previsto igual ou anterior à admissão em tipo a prazo
- **THEN** há erro bloqueante em `fixedTermEndDate`

#### Scenario: Early termination after the end
- **WHEN** tipo `fixedTermEarlyByEmployer` e rescisão posterior ao fim previsto
- **THEN** há erro bloqueante e nenhum cálculo é feito

#### Scenario: Normal end away from the end date
- **WHEN** tipo `fixedTermEnd` e rescisão diferente do fim previsto
- **THEN** a validação é bem-sucedida e existe um aviso não bloqueante

### Requirement: Form fields only in fixed-term types
O `FormScreen` MUST exibir o campo de data de fim previsto nos três tipos a prazo e a opção de cláusula assecuratória só nos dois tipos "antecipada"; nos demais tipos nenhum dos dois MUST aparecer. O formulário MUST exibir o aviso não bloqueante de B4-03(c). Os campos MUST ter `Key`/`Semantics` estáveis para o Maestro. (B4-09)

#### Scenario: Fields by type
- **WHEN** o formulário abre para `fixedTermEarlyByEmployee`
- **THEN** há o campo de fim previsto e a opção de cláusula assecuratória

#### Scenario: Fields hidden
- **WHEN** o formulário abre para `withoutJustCause`
- **THEN** não há campo de fim previsto nem opção de cláusula assecuratória

### Requirement: Termination type cards
A tela inicial MUST listar via `TerminationTypeCard` os 8 tipos, sem `fixedTerm`, cada um com descrição em linguagem simples, sem juridiquês e sem número de artigo no texto principal. (B4-09)

#### Scenario: Cards listed
- **WHEN** a `HomeScreen` é construída
- **THEN** há um card por tipo do enum e nenhum com o texto "Prazo Determinado" antigo

### Requirement: Fixed-term E2E journey
MUST existir fluxo Maestro em `.maestro/tests/` que escolhe um tipo de rescisão antecipada, preenche fim previsto e chega ao resultado, verificando o item da indenização e a premissa "cálculo em validação". (B4-05, B4-09)

#### Scenario: Journey passes
- **WHEN** o fluxo roda no emulador
- **THEN** o resultado mostra a indenização do art. 479 e a marca "cálculo em validação"
