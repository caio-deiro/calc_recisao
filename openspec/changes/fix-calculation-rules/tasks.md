## 1. Identidade de verba e regras por tipo (B2-01…03)

- [x] 1.1 B2-02 Teste unitário da matriz `TerminationRules` para os 5 tipos atuais (valores do PRD §6.1 com C1), escrito antes da implementação (B0-02).
- [x] 1.2 B2-01 Criar `BreakdownCode` e `BreakdownItem.code` (obrigatório); ajustar construtores e os testes existentes que dependem de `description` (`calculate_termination_test`, `calculation_breakdown_test`, `comprehensive_termination_review_test`, `edge_cases_test`, `calculation_integration_test`, pdf/share/history).
- [x] 1.3 B2-02 Criar `TerminationRules` (tabela imutável) e remover ou derivar os booleanos de `TerminationType`.
- [x] 1.4 B2-03 Refatorar `calculate_termination.dart`: decidir pelas regras antes de adicionar; fração de 50 % antes do arredondamento; sem `removeWhere`.
- [x] 1.5 B2-01 Remover `test/golden/support/provisional_code_map.dart` e o teste de `codeOf`; `golden_comparator` usa `item.code.name` (hand-off de B6).
- [x] 1.6 B2-01 Teste/busca: nenhuma ocorrência de `description ==`, `.contains` ou `removeWhere` em `lib/domain/usecases/`; teste de rótulo alterado sem mudar valores.

## 2. Resultado: dois totais e premissas (B2-09, B2-10, B6-04)

- [x] 2.1 B2-09 Testes unitários: `paidAtTermination` sem multa, `fgtsDeposit`, `paidAtTermination + fgtsDeposit.total == netAmount` nos casos sem mudança de regra.
- [x] 2.2 B2-09 Implementar `FgtsDeposit`, `paidAtTermination` e `@Deprecated netAmount/totalToReceive` (semântica antiga); `fgtsFine` sai de `additions`.
- [x] 2.3 B2-09 Ajuste mínimo em `result_screen`, `history_screen`, `pdf_utils`, `share_utils` para a multa continuar visível via `fgtsDeposit.items` (sem mudar layout); atualizar seus testes de widget/PDF.
- [x] 2.4 B2-10 Testes: premissas de FGTS informado/estimado, projeção do aviso, avos, mês de 30 dias, regra de 15 dias.
- [x] 2.5 B2-10 Criar `Assumption`, `AssumptionCode`, `AssumptionOrigin` e `TerminationResult.assumptions`; preencher no use case.
- [x] 2.6 B2-10 / B6-04 Constante `validationPendingRules` em `lib/domain/` + `Assumption` "cálculo em validação" para regras listadas; teste que compara com `test/golden/validation_status.dart`.
- [x] 2.7 B6-02 Runner golden: comparar `fgtsDeposit.items` e suportar os totais `paidAtTermination` e `fgtsDeposit` (remove o skip desses campos).

## 3. Correções de regra ⚖️ (B2-04…08)

- [x] 3.1 B2-04 Teste unitário (valor calculado à mão) de C1; implementar via `paysAccruedVacation`. ⚖️ validar em B6.
- [x] 3.2 B2-06 Testes de `proportionalVacationMonths` (admissão fora de janeiro, menos de 1 ano, regra de 15 dias); extrair a função própria com a regra correta. ⚖️
- [x] 3.3 B2-05 Testes de `noticeProjectionMonths` (33, 60, 90 dias, aviso trabalhado, pedido de demissão, teto de 12 avos); implementar a projeção em 13º e férias e a premissa. Acordo mútuo projeta pelo aviso pago (50 %), com "cálculo em validação". ⚖️
- [x] 3.4 B2-07 Teste de `calculateTerminationTaxes` com `vacationAmount` alto e de use case com/sem `hasAccruedVacation`; remover férias da base. ⚖️
- [x] 3.5 B2-08 Testes de INSS separado (ambos acima do teto; ambos pequenos; 2025 e 2026 pela data da rescisão); implementar `inssSalary`/`inssThirteenth`. ⚖️
- [x] 3.6 B2-06 B2-10 Teste antes: dia 14 não conta e dia 15 conta; implementar o ponto único da regra "menos de 15 dias = zero" nas avos de 13º e férias e registrar em `assumptions`. ⚖️ (Lei 4.090 art. 1º §2º)
- [x] 3.7 B2-04…08 Atualizar `termination_2026_test.dart` e demais testes que fixavam o comportamento antigo, sem alterar valores sem justificativa por escrito.

## 4. Histórico compatível (B2-11, B2-12)

- [x] 4.1 B2-11 Testes: round trip novo, JSON legado 1.0.x (sem `schemaVersion`, sem `code`), registro corrompido preservado e contado.
- [x] 4.2 B2-11 Implementar `schemaVersion`, `BreakdownCode.legacy`, `isLegacy`, novos campos no `toJson`/`fromJson`.
- [x] 4.3 B2-11 `HistoryRepository`: manter entradas brutas ilegíveis e expor `unreadableCount`, sem dado pessoal em log (B0-03).
- [x] 4.4 B2-11 `history_screen`: marca "calculado em versão anterior" e aviso de registros ilegíveis; teste de widget.
- [x] 4.5 B2-12 Teste e implementação de `orElse` + tabela única de aliases de tipos; nome desconhecido segue o fluxo de ilegível.

## 5. Docs e verificação (B0-01, B0-04, B0-05, B0-08)

- [x] 5.1 B0-05 Atualizar `docs/PROJECT.md §6` (C1–C5 e totais de ✅/🎯) e `docs/ARCHITECTURE.md` (dívidas D8, D10; `TerminationRules`; histórico v2) no mesmo commit; citar a base legal conforme a tabela de verificação do `design.md` (B0-04).
- [x] 5.2 B0-01 `flutter analyze` sem novos avisos e `flutter test` verde.
- [x] 5.3 B6-05 Rodar `flutter test --tags release-gate --run-skipped`. **Bloqueia a publicação** enquanto B6-06 (TRCTs, contador, calculadora de referência) estiver pendente; registrar o resultado no relatório.
- [ ] 5.4 B0-08 Bump de versão em `pubspec.yaml` quando esta change for publicada.

- [x] 5.5 B2-01…12 Reportar ao orquestrador que `migrate-money-to-decimal` só pode iniciar após esta change arquivada e com casos golden reais (B6-06).
