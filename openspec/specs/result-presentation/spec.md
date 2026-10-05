# result-presentation Specification

## Purpose
TBD - created by archiving change result-assumptions-and-two-totals. Update Purpose after archive.

## Requirements

### Requirement: Two totals on the Result screen
`ResultScreen` MUST exibir dois totais: **"Pago na rescisão"** (`paidAtTermination`) e **"Depositado no FGTS"** (`fgtsDeposit.total`), cada um com `Semantics.identifier` (`result_paid_total`, `result_fgts_total`). A tela MUST NOT exibir os rótulos "Total a Receber" nem "Valor Líquido". A multa do FGTS MUST aparecer no bloco do "Depositado no FGTS" (itens de `fgtsDeposit.items`), não na lista de verbas pagas. Quando `TerminationRules.fgtsWithdrawalPercent` não for nulo, a tela MUST exibir uma linha informativa de saque com esse percentual (`result_fgts_withdrawal_info`), sem valor calculado. Quando `fgtsDeposit` for vazio, o total MUST ser exibido como R$ 0,00 e a linha de saque MUST seguir a regra do tipo. (B5-01)

#### Scenario: Without just cause
- **WHEN** o Resultado de um cálculo `withoutJustCause` com multa é exibido
- **THEN** `result_paid_total` e `result_fgts_total` estão visíveis com `paidAtTermination` e `fgtsDeposit.total`, a linha de saque cita "100 %" e a multa não está entre as verbas pagas

#### Scenario: Mutual agreement
- **WHEN** o Resultado de um cálculo `mutualAgreement` é exibido
- **THEN** a linha de saque cita "80 %" e não mostra valor em reais

#### Scenario: Type without withdrawal info
- **WHEN** o Resultado de um cálculo `resignation` ou `withJustCause` é exibido
- **THEN** não há linha de saque e "Depositado no FGTS" mostra R$ 0,00

#### Scenario: Old labels gone
- **WHEN** qualquer Resultado é exibido
- **THEN** os textos "Total a Receber" e "Valor Líquido" não existem na árvore de widgets

### Requirement: Collapsible assumptions section
O Resultado MUST exibir a seção **"Premissas desta estimativa"** (`result_assumptions_toggle`), **fechada por padrão**, que ao abrir lista cada `Assumption` do resultado com seu `text` e a origem (informado ou estimado), cada item com identifier derivado do `code` (`result_assumption_<code>`). Ao lado de valores aproximados MUST aparecer o marcador **"estimado"** (`result_estimated_marker`): na multa do FGTS e no total "Depositado no FGTS" quando a premissa `fgtsBalance` tiver origem `estimated`; com origem `informed`, o marcador MUST NOT aparecer. (B5-02)

#### Scenario: Closed by default
- **WHEN** o Resultado abre
- **THEN** o título da seção está visível e os itens de premissa não estão visíveis

#### Scenario: Opening shows assumptions
- **WHEN** o usuário toca em `result_assumptions_toggle`
- **THEN** cada premissa do resultado é exibida com texto e origem

#### Scenario: Estimated FGTS marker
- **WHEN** o cálculo não tem FGTS informado e o tipo paga multa
- **THEN** `result_estimated_marker` aparece junto da multa e do total do FGTS

#### Scenario: Informed FGTS has no marker
- **WHEN** o cálculo tem FGTS informado
- **THEN** `result_estimated_marker` não aparece

### Requirement: Validation-pending notice visible without expanding
Se o resultado tiver `Assumption` com `code` `validationPending`, o Resultado MUST exibir um aviso "cálculo em validação" (`result_validation_notice`) **fora** da seção recolhível, acima dos totais, citando a regra pendente. Sem essa premissa, o aviso MUST NOT existir. (B6-04, B2-10)

#### Scenario: Pending rule shows notice
- **WHEN** o Resultado de `mutualAgreement` com aviso indenizado (regra `noticeProjectionMutualAgreement`) é exibido com as premissas fechadas
- **THEN** `result_validation_notice` está visível

#### Scenario: No pending rule
- **WHEN** o Resultado de `withoutJustCause` é exibido
- **THEN** `result_validation_notice` não existe

### Requirement: Share text mirrors the Result structure
`ShareUtils.generateShareText` MUST conter os dois totais ("Pago na rescisão" e "Depositado no FGTS"), as verbas, os descontos e a lista de premissas, na mesma ordem do Resultado; quando houver `validationPending`, MUST conter a linha "cálculo em validação". `ShareUtils.generateSimpleShareText` MUST conter os dois totais e, quando houver `validationPending`, a linha "cálculo em validação", sem a lista de premissas. Nenhum dos dois MUST conter "Valor Líquido", "Total a Receber" nem marca de versão PRO; MUST conter a ressalva de que o cálculo é uma estimativa e que o TRCT oficial prevalece, sem frases que prometam exatidão. Além dos dados do próprio cálculo (tipo, datas, salário, verbas), o texto MUST NOT incluir nenhum outro dado do usuário ou do aparelho. (B5-03, B5-05, Q3)

#### Scenario: Full text has structure
- **WHEN** `generateShareText` recebe um resultado com multa e premissas
- **THEN** o texto contém "Pago na rescisão", "Depositado no FGTS" e cada `text` de premissa

#### Scenario: Summary has only totals
- **WHEN** `generateSimpleShareText` recebe o mesmo resultado
- **THEN** o texto contém os dois totais e não contém os `text` das premissas

#### Scenario: Pending rule in both texts
- **WHEN** o resultado tem `validationPending`
- **THEN** os textos completo e resumido contêm "cálculo em validação"

#### Scenario: No PRO mark and no accuracy promise
- **WHEN** qualquer texto de compartilhamento é gerado
- **THEN** ele não contém "PRO", "Valor Líquido", "Total a Receber", "exato" nem "garant"

### Requirement: PDF mirrors the Result structure
`PdfUtils` MUST gerar o conteúdo do PDF com a mesma estrutura do compartilhamento completo: dois totais, verbas, descontos, premissas e, quando houver `validationPending`, a linha "cálculo em validação". O PDF MUST NOT conter "Valor Líquido", "Total a Receber" nem marca PRO, e MUST manter a ressalva de estimativa. O conteúdo textual MUST ser obtido de uma função testável sem renderizar o arquivo. (B5-03, B5-05, Q3)

#### Scenario: PDF content has two totals and assumptions
- **WHEN** o conteúdo do PDF é gerado para um resultado com multa e premissas
- **THEN** ele contém "Pago na rescisão", "Depositado no FGTS" e cada `text` de premissa

#### Scenario: PDF still generated without gate
- **WHEN** o usuário exporta o PDF
- **THEN** o arquivo é gerado e compartilhado sem bloqueio (fluxo Maestro)

### Requirement: Legal notice on current screens
O `DisclaimerWidget` MUST permanecer em Home, Formulário, Resultado e Histórico, com texto que cubra as limitações do PRD §6.8: o resultado é estimativa e o TRCT oficial prevalece; sem FGTS informado a multa é aproximação; feriados, faltas, licenças e adicionais além da média informada não são tratados; consultar um profissional. O texto MUST NOT prometer precisão. (B5-04)

#### Scenario: Notice present on all four screens
- **WHEN** Home, Formulário, Resultado e Histórico (com ao menos um item) são exibidos
- **THEN** cada um contém o `DisclaimerWidget`

#### Scenario: Notice covers PRD 6.8
- **WHEN** o `DisclaimerWidget` é exibido
- **THEN** seu texto cita estimativa, TRCT oficial, FGTS aproximado e limitações de feriados, faltas e licenças

### Requirement: History opens the saved result in the same screen
Ao tocar em um item do histórico, o app MUST abrir a **mesma `ResultScreen`** exibindo o **resultado salvo** (`CalculationHistory.result`), sem chamar o use case de cálculo, sem gravar novo registro no histórico, sem `ConsentService.markFirstResult` e sem emitir `calc_completed`. Registro com `schemaVersion` atual MUST exibir os dois totais e as premissas salvos. Registro legado (`isLegacy`) MUST exibir **um único valor**, o `legacyNetAmount` salvo, com a marca "Calculado em versão anterior" (`result_legacy_mark`), e MUST NOT exibir "Pago na rescisão", "Depositado no FGTS", premissas nem aviso de validação. Em registro legado, as ações de compartilhar e PDF MUST estar ocultas. O card do histórico MUST mostrar o mesmo valor principal que o Resultado do registro (`paidAtTermination` no atual, `legacyNetAmount` no legado), com a marca `history_legacy_mark` no legado. (B5-06, B2-11, B0-03)

#### Scenario: Current record opens saved totals
- **WHEN** o usuário abre no histórico um registro atual cujo input hoje geraria outro valor
- **THEN** o Resultado mostra os totais salvos e o use case não é chamado

#### Scenario: No side effects on open
- **WHEN** um registro é aberto a partir do histórico
- **THEN** a contagem de registros do histórico não muda e nenhum evento `calc_completed` é emitido

#### Scenario: Legacy record shows saved value and mark
- **WHEN** o usuário abre um registro legado (sem `schemaVersion`) com `netAmount` 3500,00
- **THEN** o Resultado mostra R$ 3.500,00, `result_legacy_mark` está visível, não há "Pago na rescisão" nem ação de compartilhar

#### Scenario: Card and Result agree
- **WHEN** um registro legado é listado e depois aberto
- **THEN** o valor principal do card é igual ao valor do Resultado

#### Scenario: Unreadable record notice
- **WHEN** o histórico tem uma entrada ilegível
- **THEN** `history_unreadable_notice` mostra a contagem e a entrada continua armazenada

### Requirement: User journeys covered by Maestro flows
`.maestro/tests/` MUST conter fluxos para: Resultado com dois totais e premissas recolhidas; aviso "cálculo em validação" no acordo mútuo; histórico abrindo um cálculo salvo; marca de registro legado; aviso de registro ilegível. Os fluxos MUST localizar elementos por `id` (`Semantics.identifier`) e MUST NOT usar coordenadas (`point:`). O fluxo existente de primeiro resultado e consentimento MUST ser migrado para `id` e para os novos rótulos. (B5-01, B5-02, B5-06, B2-11)

#### Scenario: No coordinate selectors
- **WHEN** se busca `point:` em `.maestro/tests/` e `.maestro/subflows/`
- **THEN** a busca retorna vazio

#### Scenario: Suite passes
- **WHEN** `maestro test .maestro` roda no emulador com o APK debug atual
- **THEN** todos os fluxos passam, com os valores conferidos por `id`
