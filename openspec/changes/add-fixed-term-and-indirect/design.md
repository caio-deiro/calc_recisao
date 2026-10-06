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

   `noticeDeductible = false` nos três tipos a prazo (sem cláusula não há aviso nem desconto de aviso). O percentual de saque 100 para `fixedTermEnd` e `fixedTermEarlyByEmployer` decorre de "saque do FGTS" (PRD §6.1/§6.6) e de a antecipação pelo empregador ser dispensa sem justa causa; o PRD não traz o número, ver Open Questions.
3. **Cláusula assecuratória na tabela.** `TerminationRules.resolve(type, hasRecipientClause)` consulta um mapa de dados `_recipientClauseEquivalent` (`fixedTermEarlyByEmployer` para `withoutJustCause`, `fixedTermEarlyByEmployee` para `resignation`). O use case troca `of` por `resolve` e continua sem condicional por tipo. Descartado: `if (hasRecipientClause)` no use case.
4. **Aviso da projeção do acordo mútuo na tabela.** Para zerar `type ==` no use case, o campo novo `noticeProjectionPendingRule` (`String?`, `'noticeProjectionMutualAgreement'` só em `mutualAgreement`) substitui o `if` da linha ~140. Sem mudança de comportamento.
5. **Art. 479.** `(salário + média) / 30 × dias restantes × 50 %` com `Decimal`, multiplicando antes de dividir uma só vez, arredondando a 2 casas (convenção B2-13). `dias restantes` vem de uma única função `remainingDays(end, termination)` isolada, para a convenção ser trocada num ponto. Item de provento fora de `taxableBase` do INSS e do IRRF (como as férias indenizadas, C4); a multa de 40 % segue o FGTS normal.
6. **Art. 480.** `min(art479 equivalente, salário + média)`; o "art. 479 equivalente" usa a mesma função e os mesmos dados. Item de desconto, somado só em `totalDeductions`/`paidAtTermination`, nunca na base de impostos. O aviso "valor máximo; depende de comprovação do prejuízo" é uma `Assumption` (novo `AssumptionCode.indemnity480Cap`, origem `estimated`) para aparecer em tela, texto compartilhado e PDF pela mesma estrutura de B5. Não há multa de 40 %.
7. **Validação.** `TerminationInputValidator.validate(input, {type})` ganha o tipo opcional; as regras de B4-03 só rodam quando o tipo é a prazo. O aviso do "término normal" é uma lista separada (`warnings`) lida pelo formulário, sem bloquear. `fixedTermEndDate` não passa pela regra "data no futuro". Definição de "≈ fim previsto" (B4-03): **qualquer diferença** entre rescisão e fim previsto gera o aviso (ver Open Questions).
8. **Histórico.** `TerminationInput.fromJson` tolera a ausência dos campos novos. Registro salvo não recalcula (B2-11), então um registro antigo `fixedTerm` mapeado para `fixedTermEnd` sem `fixedTermEndDate` abre normalmente.
9. **Golden.** O `golden_prazo_determinado_termino` passa a `tipo: fixedTermEnd` (resultado inalterado: sem aviso, sem multa). Cada tipo novo ganha caso `calculo_legal` com valor esperado calculado por script independente do app. O loader aceita `fimPrevisto` e `clausula` na entrada. Os casos NÃO tiram `art479`/`art480` de `pendingValidationRules`: isso exige `exemplo_contador`/fonte (B6).

## Risks / Trade-offs
- Art. 479/480 são ⚖️ sem validação: saem com "cálculo em validação" (plano B do PRD, B6-04).
- O app pode apresentar `paidAtTermination` pequeno ou negativo com o desconto do art. 480; segue o tratamento já usado para `noticeDiscount` (nenhuma regra nova nesta change); reportar se o golden mostrar caso real.
- Formulário mais longo: os campos novos só aparecem nos tipos a prazo.
- Fontes legais: a pesquisa na web não pôde ser feita nesta sessão (ferramenta de pesquisa indisponível); o texto dos artigos desta change vem do PRD (§6.6, §16) e continua ⚖️ até validação do usuário.

## Open Questions
Sem fonte, precisa do usuário (⚖️):
1. **Contagem dos dias restantes do art. 479.** O texto do art. 479 diz "a remuneração a que teria direito até o termo do contrato" e não define a contagem. SPECS B4-05 fixa `fixedTermEndDate − terminationDate` mas a questão aberta do SPECS §4 pergunta se o dia da rescisão entra. Esta change implementa a diferença literal (sem o dia da rescisão) em função isolada e com a marca de validação. Recomendação: manter até o contador confirmar; se contar inclusive, somar 1 na função.
2. **Interpretação de "1 remuneração mensal" no art. 480 / art. 477 §5º**: `salário + média` (usado aqui, coerente com o art. 479) ou só `salário base`. Recomendação: `salário + média`.
3. **Interpretação 479/480** como pura metade do restante (Q27) sem outras parcelas: já decidido pelo PRD; fica só a validação por contador (B6).

Decisão de produto, não legal (resolvido por padrão simples, usuário pode trocar):
4. **"Rescisão ≈ fim previsto"** (B4-03): aviso para qualquer diferença. Recomendação: manter; se o usuário preferir tolerância (ex.: 7 dias), é uma constante.
5. **Saque do FGTS em `fixedTermEnd` e `fixedTermEarlyByEmployer`:** 100 % (saque integral). Fonte do número: PRD diz só "saque do FGTS"; a leitura 100 % precisa de confirmação (Lei 8.036/90 art. 20; não consultada nesta sessão).

Resolvido com fonte do repositório: a antecipação com cláusula segue o prazo indeterminado equivalente (PRD §6.1 nota 1 e §6.6 item 4; CLT art. 481); art. 480 limitado ao art. 479 e a 1 remuneração (PRD §6.6, Q27); indenização sem IRRF e INSS (PRD §6.6).
