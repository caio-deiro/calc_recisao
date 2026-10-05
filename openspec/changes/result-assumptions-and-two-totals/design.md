## Context

Estado atual (verificado no código em 2026-10-05): `TerminationResult` já tem `paidAtTermination`, `fgtsDeposit`, `assumptions` e `netAmount`/`totalToReceive` `@Deprecated`. `result_screen.dart` mostra "Total a Receber", "Total Descontos" e "Valor Líquido" a partir do alias e junta a multa às "Adicionais". `share_utils.dart` e `pdf_utils.dart` fazem o mesmo, sem premissas. `history_screen.dart` mostra `netAmount` no card e `_viewCalculation` abre `ResultScreen(input, type)`, que **recalcula, grava um novo registro no histórico, chama `ConsentService.markFirstResult` e emite `calc_completed`**. O histórico já tem `schemaVersion`, `isLegacy`, `unreadableCount` e os identifiers `history_unreadable_notice` e `history_limit_notice`. O único fluxo Maestro (`first_run/consent_after_first_result.yaml`) usa coordenadas (`point:`) e o texto "Valor Líquido". Esta change herda o D5 de `fix-calculation-rules` (arquivada): "Resultado de registro legado mostra o valor salvo + a marca".

## Decisions

### D1. Layout do Resultado (B5-01, B5-02, B6-04)
Ordem: aviso de validação (se houver) → cartão de totais (dois totais, com a linha de saque sob "Depositado no FGTS") → "Premissas desta estimativa" (`ExpansionTile`, `initiallyExpanded: false`) → detalhamento (verbas pagas; descontos; bloco "Depositado no FGTS" com os itens de `fgtsDeposit`) → aviso legal. "Total Descontos" sai do cartão de totais (continua somado na seção Descontos). O marcador "estimado" aparece **só** onde o valor é aproximação por premissa: multa do FGTS e total do FGTS quando `fgtsBalance.origin == estimated`. Avos de 13º/férias são regra, não aproximação, e ficam apenas em Premissas. O aviso "cálculo em validação" fica **fora** da seção recolhível porque B6-04 pede visibilidade na tela e a seção abre fechada.
Descartado: marcar "estimado" em todo valor com premissa (poluiria a tela e diluiria o sinal do FGTS).

### D2. Linha de saque em `TerminationRules` (B5-01)
`fgtsWithdrawalPercent` (`int?`) na tabela existente: 100 sem justa causa, 80 acordo mútuo, nulo nos demais. Fonte única (DRY); a UI não ramifica por tipo. Rescisão indireta (100 %) entra com B4-01 na mesma tabela. Descartado: `switch` por tipo na UI (contradiz B2-02).

### D3. Resultado salvo no histórico (B5-06, B2-11)
`ResultScreen` ganha um segundo construtor `ResultScreen.fromHistory(CalculationHistory)`. Nesse modo: não chama o use case, não grava histórico, não chama `ConsentService.markFirstResult`, não emite `calc_completed` (B0-03: evento só no cálculo novo). Vale para registro atual **e** legado, para que card e Resultado nunca divirjam (limite conhecido do D5). Registro atual mostra os dois totais e as premissas **salvos**; um registro antigo não muda se a regra mudar depois (o que o usuário viu é o que reabre).
Registro legado: `CalculationHistory.legacyNetAmount` (lido de `netAmount` quando `schemaVersion` < 2) é o único valor; mostra "Calculado em versão anterior" e **não** infere `paidAtTermination` (D5). Sem os dois totais, sem premissas e sem aviso de validação (não existem no registro).
Descartado: recalcular o legado (muda o valor sem aviso e viola o D5) e inferir `paidAtTermination = netAmount − multa` (palpite sobre dado antigo).

### D4. Remoção do alias (B2-09)
`netAmount`/`totalToReceive` saem de `TerminationResult`. O JSON novo deixa de gravá-los; o legado continua legível por `legacyNetAmount`. As chaves l10n `totalToReceive` e `netAmount` saem se não houver outro uso. ~60 usos em `test/` migram: `x.netAmount` vira `x.paidAtTermination + x.fgtsDeposit.total` onde o teste verificava o total antigo, ou `x.paidAtTermination` onde bastava "positivo". Ordem no `tasks.md`: o alias é removido **por último**, depois de UI, share e PDF já não o usarem, para o repositório compilar em cada passo.

### D5. Compartilhamento e PDF (B5-03, B5-05, Q3)
Uma única ordem de seções para texto completo, PDF e tela (totais, verbas, descontos, premissas). O conteúdo do PDF vem de uma função pura (`List`/`String`) testável sem renderizar o arquivo; `_generatePdf` apenas a desenha. O resumo leva os dois totais e a linha de validação (quando houver); sem lista de premissas. Texto novo sem promessa de precisão (ressalva: estimativa, TRCT oficial prevalece). Dados do texto: só os do cálculo (tipo, datas, salário, verbas), como hoje; nenhuma marca PRO (já inexistente; teste guarda).

### D6. Strings e premissas (B0-07)
Rótulos novos da UI entram em `lib/l10n/app_localizations.dart` (+ `_pt.dart`) como chaves novas; as strings antigas não migram (D5 parcial). O texto de cada premissa vem do campo `text` do domínio (já em português, gravado no histórico); o `code` serve de chave de UI e de `Semantics.identifier` (`result_assumption_<code>`), nunca o texto.

### D7. Identificadores para Maestro (skill `maestro-e2e`)
`Semantics.identifier` no padrão `<tela>_<elemento>`: `result_paid_total`, `result_fgts_total`, `result_fgts_withdrawal_info`, `result_assumptions_toggle`, `result_assumption_<code>`, `result_estimated_marker`, `result_validation_notice`, `result_legacy_mark`, `result_share_button`, `result_back_button`, `share_export_pdf`, `share_save_pdf`, `history_item_<índice>`, `history_legacy_mark`; os do formulário (`form_calculate_button`, campos, cartão de tipo) onde faltarem. Os fluxos deixam de usar `point:`.

### D8. Aviso legal (B5-04)
Só o texto do `DisclaimerWidget` muda (já está nas 4 telas). Rascunho para aprovação (Open Question 1): "Esta calculadora faz uma estimativa com base em regras gerais da CLT; o TRCT oficial prevalece. Sem o saldo do FGTS informado, a multa é uma aproximação (usa o salário atual e ignora reajustes, saques e depósitos). Feriados, faltas, licenças e adicionais além da média informada não entram no cálculo. Consulte um contador ou advogado antes de decidir."

## Risks / Trade-offs
- **Release-gate e ⚖️:** esta change só mostra premissas; C1–C5 e a regra de 15 dias continuam ⚖️ e **não** geram a marca "cálculo em validação" (não estão em `validationPendingRules`). A publicação continua exigindo o gate verde (B6-05/B6-06, pendência do responsável).
- **Migração de testes:** ~60 usos de `netAmount`/`totalToReceive`; asserções como `edge_cases_test` L363-365 dependem da semântica antiga e exigem leitura caso a caso, sem alterar valor esperado sem justificativa.
- **E2E de legado e ilegível:** o Maestro não grava `SharedPreferences`. Plano: script em `.maestro/utils/` que usa `adb shell run-as com.caiodeiro.calcclt` no APK **debug** para escrever o XML do `shared_preferences` (chave `flutter.calculation_history`) antes do fluxo. Frágil (formato interno do plugin). Fallback: cobrir legado e ilegível só em teste de widget e deixar o E2E marcado como manual (Open Question 6).
- **Reabrir salvo:** registros antigos passam a refletir a regra da época do cálculo, não a atual. É o comportamento desejado (D3), mas deve constar nas docs.
- Tamanho: 24 tasks e 2 deltas, dentro do limite; se a migração de testes (6.1) crescer, dividir (Open Question 5).

## Open Questions
1. **Texto do aviso legal (⚖️/jurídico)** — rascunho em D8. Recomendação: aprovar o rascunho; o usuário (ou contador) revisa antes da publicação, pois o PRD §6.8 dá os 4 pontos, mas não o texto final.
2. **Linha de validação no resumo compartilhado.** SPECS B5-03 diz "no resumo, apenas os dois totais", mas B6-04 exige o aviso visível. Recomendação: incluir **uma linha** "cálculo em validação" no resumo (não é premissa; é aviso de segurança). A spec já assume isso.
3. **Legado sem compartilhar/PDF.** Sem os dois totais e premissas, compartilhar um legado exigiria um formato à parte. Recomendação: ocultar as ações no legado (YAGNI), como na spec.
4. **Linha de saque para tipos sem percentual.** Pedido de demissão e justa causa: sem linha. `fixedTerm` atual: sem linha até B4 (PRD §6.6 prevê saque no término normal). Recomendação: manter assim; B4 completa a tabela. ⚖️ o 80 % do acordo mútuo vem do PRD §6.5 e do SPECS (CLT art. 484-A §1º); não foi reverificado em fonte oficial nesta change.
5. **Divisão.** 24 tasks e 2 deltas: cabe. Recomendação: **não** dividir; se a migração de testes (6.1) estourar, extrair o grupo 6 (remoção do alias) para uma change própria, mantendo o alias deprecado.
6. **E2E de legado/ilegível via `run-as`.** Recomendação: tentar o script no APK debug; se instável, aceitar cobertura por widget test e registrar o fluxo como pendente.
7. **Nome da change** `result-assumptions-and-two-totals`: o orquestrador ajusta a linha "Change:" de B5 em `docs/SPECS.md` (hoje "distribuída: B1 e B2").

## Divergências PRD / SPECS / código
- SPECS B5 diz "change distribuída (B1 e B2)", mas a UI de B5 não foi feita em nenhuma delas (código ainda usa o alias); passa a existir esta change.
- SPECS B5-03 ("no resumo, apenas os dois totais") × B6-04 (aviso visível): resolvido na Open Question 2.
- SPECS B2-09 permitia manter o alias "até B5 migrar a UI": removido aqui.
- `docs/PROJECT.md §6.5` ainda marca a UI como 🎯: atualizar na task 8.1.
