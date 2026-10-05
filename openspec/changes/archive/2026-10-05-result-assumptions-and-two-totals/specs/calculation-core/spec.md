## ADDED Requirements

### Requirement: FGTS withdrawal percent in the rules table
`TerminationRules` MUST expor `fgtsWithdrawalPercent` (`int?`): 100 para `withoutJustCause`, 80 para `mutualAgreement` e nulo para os demais tipos atuais (informativo, sem valor calculado). A UI MUST ler esse campo; nenhuma condicional por tipo para a linha de saque MUST existir fora da tabela. O tipo `fixedTerm` atual fica nulo até B4. (B5-01)

#### Scenario: Percent by type
- **WHEN** se consulta `TerminationRules` dos 5 tipos atuais
- **THEN** `withoutJustCause` = 100, `mutualAgreement` = 80 e `resignation`, `fixedTerm`, `withJustCause` = nulo

## MODIFIED Requirements

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
