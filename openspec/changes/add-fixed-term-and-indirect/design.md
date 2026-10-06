## Context
`TerminationRules.of(type)` (B2-02) já é a tabela única por tipo e já tem `hasIndemnity479` e `hasDiscount480` falsos. `BreakdownCode` e `validationPendingRules` (`art479`, `art480`) existem; `_validationPending` em `calculate_termination.dart` só tem texto para `doubleVacation` e cai num texto de acordo mútuo para qualquer outra regra (MUST ganhar os textos de `art479` e `art480`). O use case ainda tem um `if (type == TerminationType.mutualAgreement)` (linha ~140) que contraria o critério de aceite de B4 ("busca por `type ==` no use case retorna vazio"). Fontes de regra: PRD §6.1 e §6.6, decisões Q23, Q26, Q27 (sem rediscussão).

## Decisions
1. **Enum e alias.** `fixedTerm` sai do enum; entra uma tabela de aliases de leitura (`fixedTerm` para `fixedTermEnd`) no ponto já previsto em `calculation_history.dart`. A `HomeScreen` itera `TerminationType.values`, então os cards novos aparecem sem ramificação. Descartado: manter `fixedTerm` no enum com flag "oculto" (dois lugares para saber o que a UI oferece).
2. **Matriz (PRD §6.1).**

   | Tipo | aviso | multa | 13º | prop. | vencidas | saque FGTS | 479 | 480 |
   |---|---|---|---|---|---|---|---|---|
   | `indirectTermination` | 100 | 1,0 | sim | sim | sim | 100 | não | não |
   | `fixedTermEnd` | 0 | 0 | sim | sim | sim | 100 | não | não |
   | `fixedTermEarlyByEmployer` | 0 | 1,0 | sim | sim | sim | 100 | sim | não |
   | `fixedTermEarlyByEmployee` | 0 | 0 | sim | sim | sim | nulo | não | sim |

   `noticeDeductible = false` nos três tipos a prazo (sem cláusula não há aviso nem desconto de aviso). O percentual de saque 100 para `fixedTermEnd` e `fixedTermEarlyByEmployer` decorre de "saque do FGTS" (PRD §6.1/§6.6) e de a antecipação pelo empregador ser dispensa sem justa causa; o PRD não traz o número; ver Decisões com fonte (3).
3. **Cláusula assecuratória na tabela.** `TerminationRules.resolve(type, hasRecipientClause)` consulta um mapa de dados `_recipientClauseEquivalent` (`fixedTermEarlyByEmployer` para `withoutJustCause`, `fixedTermEarlyByEmployee` para `resignation`). O use case troca `of` por `resolve` e continua sem condicional por tipo. Descartado: `if (hasRecipientClause)` no use case.
4. **Aviso da projeção do acordo mútuo na tabela.** Para zerar `type ==` no use case, o campo novo `noticeProjectionPendingRule` (`String?`, `'noticeProjectionMutualAgreement'` só em `mutualAgreement`) substitui o `if` da linha ~140. Sem mudança de comportamento.
5. **Art. 479.** `(salário + média) / 30 × dias restantes × 50 %` com `Decimal`, multiplicando antes de dividir uma só vez, arredondando a 2 casas (convenção B2-13). `dias restantes` vem de uma única função `remainingDays(end, termination)` isolada, para a convenção ser trocada num ponto. Item de provento fora de `taxableBase` do INSS e do IRRF (como as férias indenizadas, C4); a multa de 40 % segue o FGTS normal.
6. **Art. 480.** `min(art479 equivalente, salário + média)`; o "art. 479 equivalente" usa a mesma função e os mesmos dados. Item de desconto, somado só em `totalDeductions`/`paidAtTermination`, nunca na base de impostos. O aviso "valor máximo; depende de comprovação do prejuízo" é uma `Assumption` (novo `AssumptionCode.indemnity480Cap`, origem `estimated`) para aparecer em tela, texto compartilhado e PDF pela mesma estrutura de B5. Não há multa de 40 %.
7. **Validação.** `TerminationInputValidator.validate(input, {type})` ganha o tipo opcional; as regras de B4-03 só rodam quando o tipo é a prazo. O aviso do "término normal" é uma lista separada (`warnings`) lida pelo formulário, sem bloquear. `fixedTermEndDate` não passa pela regra "data no futuro". Definição de "≈ fim previsto" (B4-03): **qualquer diferença** entre rescisão e fim previsto gera o aviso (ver Decisões com fonte, 4).
8. **Histórico.** `TerminationInput.fromJson` tolera a ausência dos campos novos. Registro salvo não recalcula (B2-11), então um registro antigo `fixedTerm` mapeado para `fixedTermEnd` sem `fixedTermEndDate` abre normalmente.
9. **Golden.** O `golden_prazo_determinado_termino` passa a `tipo: fixedTermEnd` (resultado inalterado: sem aviso, sem multa). Cada tipo novo ganha caso `calculo_legal` com valor esperado calculado por script independente do app. O loader aceita `fimPrevisto` e `clausula` na entrada. Os casos NÃO tiram `art479`/`art480` de `pendingValidationRules`: isso exige `exemplo_contador`/fonte (B6).

## Risks / Trade-offs
- Art. 479/480 são ⚖️ sem validação: saem com "cálculo em validação" (plano B do PRD, B6-04).
- O app pode apresentar `paidAtTermination` pequeno ou negativo com o desconto do art. 480; segue o tratamento já usado para `noticeDiscount` (nenhuma regra nova nesta change); reportar se o golden mostrar caso real.
- Formulário mais longo: os campos novos só aparecem nos tipos a prazo.
- Fontes legais: sem acesso à web nesta sessão; as fontes abaixo foram fornecidas pelo responsável, que as aceitou como base (sem contador; confia em lei e internet; tipo `calculo_legal`). Interpretação do art. 479/480 é fonte secundária (prática de folha); sem `exemplo_contador`, por isso a marca "cálculo em validação" (B6-04) permanece.

## Decisões com fonte
Nenhuma questão ⚖️ bloqueante em aberto. Fontes aceitas pelo responsável (tipo `calculo_legal`); a marca "cálculo em validação" (B6-04) permanece para art. 479/480 por não haver `exemplo_contador`.
1. **Art. 479, dias restantes e base.** Base = salário + média de variáveis. Dias = `fixedTermEndDate − terminationDate` (diferença literal: o dia da rescisão não conta, o dia do fim conta). Fontes: CLT art. 479 ("remuneração a que teria direito até o termo do contrato"); prática de folha em COAD e Empresário Online ("salário mais média de variáveis"). Fonte secundária, interpretação majoritária. A função isolada `remainingDays` permanece.
2. **Art. 480, teto.** "1 remuneração mensal" = salário + média (CLT art. 457 e art. 477 §5º, que limita a compensação a 1 remuneração mensal). Desconto = `min(valor do art. 479, 1 remuneração mensal)`. CLT art. 480 §1º: a indenização do empregado não excede a devida pelo art. 479.
3. **Saque do FGTS.** `fixedTermEnd`: saque de 100 % sem multa de 40 % (Lei 8.036/90 art. 20, IX). `fixedTermEarlyByEmployer`: dispensa sem justa causa, saque de 100 % e multa de 40 % (TST, 7ª Turma, multa de 40 % em rompimento antecipado de contrato de experiência). `fixedTermEarlyByEmployee`: pedido de demissão, sem multa e sem saque. Cláusula assecuratória (CLT art. 481): segue as regras do prazo indeterminado (PRD §6.1 nota 1 e §6.6 item 4).
4. **"Rescisão ≈ fim previsto" (B4-03).** Aviso para qualquer diferença, sem bloquear (decisão do plano, aceita).
5. **Já decidido no PRD:** 479/480 como metade do restante (Q27); indenização sem IRRF e INSS (PRD §6.6).
