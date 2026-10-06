## 1. Testes primeiro, valores à mão (B2-05, B6-03)
- [x] 1.1 Reescrever o grupo de projeção de `test/unit/avos_test.dart`: remover os testes de `noticeProjectionMonths`; adicionar testes de `thirteenthMonths` e `proportionalVacationMonths` com `noticeEnd` para os casos A, D2, D4, D5, D6 e D7 do `design.md` (45 dias → 13º 10 e férias 7; 60 dias de 15/08/2026 com adm 15/01/2016 (`E` 14/10/2026) → 13º 9 e férias 9, contra 10 e 9 do método antigo; virada de ano 13 e 10; aniversário no aviso 12 e 4; sem aviso igual ao atual; 31/12 + 1 = 01/01). Devem falhar antes da implementação (B2-05)
- [x] 1.2 Em `test/unit/calculation_core_test.dart`, reescrever o grupo "C2" pela lei: aviso 45 dias, acordo mútuo (24 pagos, 13º 8, férias 7, marca de validação), aviso trabalhado e pedido de demissão sem projeção, e a Assumption com data de fim e avos extras reais (+2 no 13º, +1 nas férias para 05/09/2026). Não ajustar esperado à saída do app (B2-05, B2-10, B6-03)
- [x] 1.3 Revisar `test/unit/termination_2026_test.dart`, `test/unit/accrued_vacation_test.dart`, `test/widget/result_screen_test.dart` e qualquer teste que assuma "+N mês" por 30 dias: recalcular o esperado pela lei (design.md) e registrar a conta em comentário (B2-05)

## 2. Implementação (B2-05, B2-10)
- [x] 2.1 `lib/domain/rules/avos.dart`: remover `noticeProjectionMonths`; trocar o parâmetro `projection` de `thirteenthMonths` e `proportionalVacationMonths` por `DateTime? noticeEnd` (data efetiva), com virada de ano no 13º e limite 12 conforme o delta de spec; atualizar o comentário ⚖️ (B2-05)
- [x] 2.2 `lib/domain/usecases/calculate_termination.dart`: calcular `noticeEnd = DateTime(y, m, d + paidNoticeDays)`; passá-la às duas funções; extras reais = avos com projeção menos avos sem projeção (B2-05)
- [x] 2.3 Mesmo arquivo: Assumption `noticeProjection` com data de fim e avos extras de cada verba, `value` = dias pagos, emitida quando `paidNoticeDays > 0`; manter a marca `noticeProjectionMutualAgreement` para o acordo; `details` do 13º com decomposição só na virada de ano (B2-10)

## 3. Casos golden (B6-03, B6-04)
- [x] 3.1 Atualizar `test/golden/cases/golden_sem_justa_causa_c2_c5.json` e `golden_rescisao_indireta.json` com os valores do `design.md` A (thirteenth 10000.0, irrf 1517.41, totalAdditions 55333.33, totalDeductions 2661.19, paidAtTermination 52672.14); `fonte.tipo` segue `calculo_legal`; descrição cita a projeção por data (B6-03)
- [x] 3.2 `golden_prazo_antecipada_empregador_clausula.json`: valores iguais (design.md C); reescrever só a descrição ("projetado em 1 avo" vira "projetado até 19/11/2026: 13º 6 avos, férias 5 avos") (B6-03)
- [x] 3.3 Conferir os demais casos de `test/golden/cases/` com aviso indenizado ou acordo; os de aviso trabalhado, pedido de demissão, justa causa e prazo determinado não mudam (B6-03)
- [x] 3.4 Promover `docs/golden-dossie/rascunho/golden_acordo_mutuo.json` para `test/golden/cases/golden_acordo_mutuo.json` com valores do `design.md` B (thirteenth 2333.33, proportionalVacation 2722.22, totalAdditions 11355.55, paidAtTermination 10861.27), `fonte.tipo = calculo_legal`, sem a chave `validacao`, `cobre: ["noticeProjectionMutualAgreement"]`; remover o rascunho (`git rm`) e a pasta `rascunho/` se ficar vazia (B6-03)
- [x] 3.5 NÃO remover `noticeProjectionMutualAgreement` de `test/golden/validation_status.dart`: o gate exige `exemplo_contador` e a regra segue ⚖️ com a marca visível (B6-04)
- [x] 3.6 Rodar `flutter test test/golden`: divergência além de 0,01 é achado a reportar, nunca motivo para mudar o esperado (B6-03)

## 4. Verificação
- [x] 4.1 `flutter analyze` sem erros e `flutter test` verde (B2-05)

## 5. Docs (B2-05, B6-03)
- [x] 5.1 `docs/PROJECT.md` §6.2 (linhas de 13º, férias proporcionais e acordo mútuo) e §6.3 (C2): projeção por data (`terminationDate + dias de aviso pagos`), virada de ano, nota "revisa a Q7a a pedido do responsável em 2026-10-06", ⚖️ mantido (B2-05)
- [x] 5.2 `docs/SPECS.md` B2-05: trocar "+1 mês por 30 dias" pela projeção por data, mantendo o ⚖️ do acordo (B2-05)
- [x] 5.3 `docs/golden-dossie/README.md`: linha "Projeção do aviso (C2)" da tabela de premissas; pergunta ⚖️ 1 (acordo: agora 13º 8 e férias 7, aviso pago 24 dias, data efetiva 24/08/2026); diagnóstico do acordo; mover `golden_acordo_mutuo` de "Pendente" para "Promovidos"; seção de casos com os valores novos de `golden_sem_justa_causa_c2_c5` e `golden_acordo_mutuo`; corrigir a observação de que a rascunho foi removida (B6-03)
- [x] 5.4 `docs/ARCHITECTURE.md`, linha de `avos.dart` ("projeção"): ajustar para "projeção por data do aviso" se a descrição ficar desatualizada (B2-05)
