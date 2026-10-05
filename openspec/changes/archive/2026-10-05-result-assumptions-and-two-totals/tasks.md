## 1. Regra de saque do FGTS (B5-01)

- [x] 1.1 B5-01 Teste unitário de `TerminationRules.fgtsWithdrawalPercent` (100 sem justa causa, 80 acordo mútuo, nulo nos demais), escrito antes da implementação (B0-02).
- [x] 1.2 B5-01 Adicionar `fgtsWithdrawalPercent` à tabela `TerminationRules` (fonte única; sem `switch` por tipo na UI).

## 2. Resultado: dois totais, premissas e validação (B5-01, B5-02, B6-04)

- [x] 2.1 B5-01 B5-02 B6-04 Testes de widget do Resultado: dois totais e linha de saque (100 %, 80 %, ausente), rótulos antigos inexistentes, premissas fechadas por padrão e abertas ao tocar, marcador "estimado" só com FGTS estimado, `result_validation_notice` visível com premissas fechadas no acordo mútuo e ausente sem regra pendente.
- [x] 2.2 B5-01 B0-07 Chaves l10n novas (`app_localizations.dart` + `_pt.dart`) e `ResultScreen`: cartão com "Pago na rescisão" e "Depositado no FGTS" (itens de `fgtsDeposit` e linha de saque), multa fora das verbas pagas, `Semantics.identifier` (`result_paid_total`, `result_fgts_total`, `result_fgts_withdrawal_info`, `result_share_button`, `result_back_button`, `share_export_pdf`, `share_save_pdf`).
- [x] 2.3 B5-02 B6-04 Seção "Premissas desta estimativa" (`ExpansionTile` fechado, `result_assumptions_toggle`, `result_assumption_<code>`), marcador `result_estimated_marker` e aviso `result_validation_notice` fora da seção recolhível.

## 3. Histórico abre o resultado salvo (B5-06, B2-11, B0-03)

- [x] 3.1 B5-06 B2-11 Testes unitários: `legacyNetAmount` preenchido a partir do `netAmount` de JSON legado, nulo em registro atual; `toJson` novo sem `netAmount`/`totalToReceive`; round trip dos totais e premissas.
- [x] 3.2 B5-06 B0-03 Testes de widget: registro atual abre com totais salvos sem chamar o use case; abrir não grava registro, não chama `markFirstResult` nem emite `calc_completed`; legado mostra o valor salvo + `result_legacy_mark`, sem dois totais nem ação de compartilhar; card e Resultado mostram o mesmo valor.
- [x] 3.3 B5-06 B2-11 Implementar `legacyNetAmount` em `CalculationHistory` e `ResultScreen.fromHistory` (sem cálculo, sem gravação, sem consentimento, sem evento); `_viewCalculation` passa o registro; ações de compartilhar e PDF ocultas no legado.
- [x] 3.4 B5-06 B2-11 `history_screen`: card exibe `paidAtTermination` (atual) ou `legacyNetAmount` (legado), `history_legacy_mark`, `history_item_<índice>`; manter `history_unreadable_notice`.

## 4. Compartilhamento e PDF (B5-03, B5-05)

- [x] 4.1 B5-03 B5-05 Testes de texto de `generateShareText` e `generateSimpleShareText`: dois totais, premissas só no completo, linha "cálculo em validação" nos dois quando houver, sem "Valor Líquido"/"Total a Receber"/"PRO"/"exato"/"garant", ressalva de estimativa presente.
- [x] 4.2 B5-03 B5-05 Reescrever `ShareUtils` com a estrutura do Resultado (totais, verbas, descontos, premissas), usando só `paidAtTermination` e `fgtsDeposit`.
- [x] 4.3 B5-03 B5-05 Testes do conteúdo do PDF (função pura, sem renderizar): dois totais, premissas, linha de validação, ausência dos rótulos antigos e de PRO; estender `pdf_export_test.dart`.
- [x] 4.4 B5-03 Extrair o conteúdo textual do PDF em função testável e fazer `PdfUtils._generatePdf` desenhá-la com a mesma estrutura.

## 5. Aviso legal (B5-04)

- [x] 5.1 B5-04 Teste de widget: `DisclaimerWidget` presente em Home, Formulário, Resultado e Histórico, e texto cita estimativa, TRCT oficial, FGTS aproximado e feriados/faltas/licenças.
- [x] 5.2 B5-04 B0-07 Atualizar o texto do `DisclaimerWidget` conforme o PRD §6.8, usando o texto aprovado na Open Question 1.

## 6. Remoção do alias `netAmount`/`totalToReceive` (B2-09)

- [x] 6.1 B2-09 Migrar os testes que usam `netAmount`/`totalToReceive` (unit, integration, widget, golden `comparator_test`) para `paidAtTermination` e `fgtsDeposit.total`, sem alterar valores esperados sem justificativa por escrito.
- [x] 6.2 B2-09 Remover o alias de `TerminationResult` e do `toJson`, as chaves l10n `totalToReceive`/`netAmount` sem uso e os `ignore_for_file` de depreciação; verificar por busca que `netAmount` e `totalToReceive` só restam em `legacyNetAmount` e na chave de JSON legada.

## 7. Fluxos E2E Maestro (B5-01, B5-02, B5-06, B2-11)

- [x] 7.1 B5-01 Migrar `first_run/consent_after_first_result.yaml` e os subfluxos para `id` (sem `point:`) e para "Pago na rescisão"; dar `Semantics.identifier` aos elementos do formulário e de navegação que faltarem (`flutter-conventions`).
- [x] 7.2 B5-01 B5-02 Fluxo `returning/result_two_totals_and_assumptions.yaml` (tags `smoke`, `calculation`): sem justa causa, confere `result_paid_total`, `result_fgts_total`, linha de saque, premissas fechadas, abre e vê `result_assumption_*` e `result_estimated_marker`.
- [x] 7.3 B6-04 Fluxo `returning/result_validation_pending.yaml` (tag `calculation`): acordo mútuo com aviso indenizado mostra `result_validation_notice` sem abrir as premissas.
- [x] 7.4 B5-06 Fluxo `returning/history_open_saved_calculation.yaml` (tag `history`): calcula, abre o Histórico, toca `history_item_0` e confere os mesmos totais do cálculo.
- [x] 7.5 B5-06 B2-11 Script `.maestro/utils/` que semeia o histórico no APK debug (`adb shell run-as`) e fluxo `returning/history_legacy_and_unreadable.yaml`: confere `history_legacy_mark`, `result_legacy_mark` com o valor salvo e `history_unreadable_notice`; se o seed for instável, registrar o fluxo como pendente (Open Question 6).

## 8. Docs e verificação (B0-01, B0-03, B0-05, B0-07, B0-08)

- [x] 8.1 B0-05 Atualizar `docs/PROJECT.md §6.5` (UI de 🎯 para ✅), `docs/ARCHITECTURE.md` (resultado, `ResultScreen.fromHistory`, remoção do alias, dívida D10 resolvida) e `.maestro` na seção de testes, no mesmo commit.
- [x] 8.2 B0-01 B0-03 B0-08 `flutter analyze` sem avisos novos, `flutter test` verde, `maestro test .maestro` no emulador, busca confirmando que nenhum log/evento novo leva dados pessoais, e bump de versão em `pubspec.yaml`.
