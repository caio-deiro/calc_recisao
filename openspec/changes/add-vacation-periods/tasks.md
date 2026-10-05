## 1. Modelo de entrada (B3-01)

- [x] 1.1 B3-01 Testes unitários de `TerminationInput`: `fromJson` sem o campo assume 0; `hasAccruedVacation: true` vira `legacyHasAccruedVacation` e é regravado por `toJson`; round trip de `vacationPeriodsTaken: 2`.
- [x] 1.2 B3-01 Trocar `hasAccruedVacation` por `vacationPeriodsTaken` (+ `legacyHasAccruedVacation` somente leitura) em `termination_input.dart`; teste de que um registro de histórico antigo abre e reabre o resultado salvo sem recalcular.
- [x] 1.3 B3-01 Migrar os ~25 usos de `hasAccruedVacation` em `test/` (e `golden_case.dart`: `feriasVencidas` vira `feriasGozadas`, int, ausente = 0) sem alterar valores esperados; `flutter test` verde.

## 2. Derivação dos períodos (B3-02, B3-03)

- [x] 2.1 B3-03 Casos de borda primeiro, datas fixas: `n = 0`; rescisão exatamente no aniversário; concessivo terminando no dia da rescisão (simples) e no dia seguinte (dobro); `taken = n`; `taken > n` limitado; admissão em 29/02; admissão em 31/01 e rescisão em fevereiro.
- [x] 2.2 B3-02 Criar `lib/domain/rules/vacation_periods.dart` com `VacationPeriods.derive` e `VacationPeriod` (sem I/O nem relógio), reusando a âncora de `avos.dart` (uma só definição de soma de meses).
- [x] 2.3 B3-03 Teste de que `derive` não depende da data do sistema (mesma saída com relógio diferente) e que o proporcional coincide com `proportionalVacationMonths`.

## 3. Valores e itens do resultado (B3-04, B3-05)

- [x] 3.1 B3-04 Testes do use case antes da troca: simples 3.000,00 → 4.000,00; dobro → 8.000,00; misto com média 600,00 → 9.600,00 e 4.800,00; justa causa paga simples e não paga proporcional; INSS/IRRF iguais ao caso sem férias vencidas; sem dobro quando nenhum concessivo expirou.
- [x] 3.2 B3-05 Em `breakdown_code.dart`, adicionar `accruedVacationSimple` e `accruedVacationDouble`, manter `accruedVacation` só como leitura de histórico; teste de que `fromJson` ainda lê `code: accruedVacation`.
- [x] 3.3 B3-04 Em `calculate_termination.dart`, trocar o item 4 por `_accruedVacationItems` (um item por código, `double` + `_roundCurrency`, dobro com "(indenização)" na descrição, gate `paysAccruedVacation`).
- [x] 3.4 B3-05 Teste de que o use case nunca gera `BreakdownCode.accruedVacation` e que `totalDeductions`/`paidAtTermination` somam as novas linhas.

## 4. Premissas e marca de validação (B3-07)

- [x] 4.1 B3-07 Testes: premissa `vacationPeriods` com uma linha por período (gozado, dobro, simples, proporcional) e palavra "dobro"; `validationPending` com `ruleId: doubleVacation` só com período `double`; a marca do acordo mútuo não muda.
- [x] 4.2 B3-07 Adicionar `AssumptionCode.vacationPeriods`, gerar a premissa no use case e parametrizar o texto de `_validationPending` por `ruleId`; confirmar que o teste que compara `validationPendingRules` com `pendingValidationRules` segue verde.
- [x] 4.3 B3-07 Teste de `buildResultSections` (completo) com a tabela de períodos e a linha "dobro" nas premissas; teste de widget do Resultado com `result_assumption_vacationPeriods` e `result_validation_notice` visíveis.

## 5. Validação (B3-08)

- [x] 5.1 B3-08 Testes do `TerminationInputValidator`: `taken > n` e `taken < 0` falham com erro em `vacationPeriodsTaken`; `taken = n` passa; data de rescisão anterior à admissão só reporta erros de data.
- [x] 5.2 B3-08 Implementar a regra em `_validateBusinessRules`, usando o mesmo cálculo de `n` de `derive`.

## 6. Formulário (B3-06)

- [x] 6.1 B3-06 Testes de widget do formulário: limite `[0, n]` (identifiers `form_vacation_taken*`), valor reduzido ao mudar a data de rescisão, valor acompanha `n` até o toque, desabilitado sem datas válidas, aviso visível.
- [x] 6.2 B3-06 Trocar o `CheckboxListTile` por stepper em `form_screen.dart` (estado `_vacationTaken`/`_vacationTouched`), extraindo o campo para widget próprio (D4); strings novas em `lib/l10n/`.
- [x] 6.3 B3-06 Aviso de que férias fracionadas, abono pecuniário e férias parcialmente gozadas não são tratadas, junto ao campo.

## 7. Fluxo Maestro (B3-06, B3-07)

- [x] 7.1 B3-06 Criar o fluxo `.maestro/tests/` (admissão com concessivo expirado, `taken = 0`, calcular, ver linha de férias em dobro, aviso "cálculo em validação", abrir Premissas e ver a tabela com "dobro"), com `Semantics.identifier` e sem `point:`; rodar com a skill `maestro-e2e` e anexar o relatório.

## 8. Docs e fechamento (B0-01, B0-05, B0-08)

- [x] 8.1 B0-05 Atualizar `docs/ARCHITECTURE.md` (D11 resolvida: modelo de períodos) e `docs/PROJECT.md §6.4` (🎯 vira ✅) no mesmo commit.
- [ ] 8.2 B0-01 `flutter analyze` sem novos avisos, `flutter test` verde e `flutter test test/golden` verde.
- [ ] 8.3 B0-08 Bump de versão em `pubspec.yaml` quando esta change for publicada.
