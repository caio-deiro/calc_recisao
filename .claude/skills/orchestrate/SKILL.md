---
name: orchestrate
description: Decide, para cada pedido, se a sessão principal resolve sozinha ou se delega ao laço planner → executor → reviewer, e conduz esse laço (no máximo 3 rodadas, com confirmação humana antes de push/PR). Use no início de qualquer tarefa de desenvolvimento neste projeto: implementar uma feature ou um bloco do docs/SPECS.md, mudar regra de cálculo, corrigir bug, rodar E2E, preparar commit/PR, ou quando o usuário disser "orquestre", "delegue", "rode o laço", "execute esta change", mesmo sem citar agentes; e para o modo autônomo ("rode o loop", executar os blocos do SPECS sem intervenção humana). Não use para perguntas, explicações ou edições triviais de documentação.
---

# Orquestração

A sessão principal é o orquestrador. Ela decide **quem faz** cada tarefa, passa o trabalho por arquivos e controla o laço. Os agentes (`planner`, `executor`, `reviewer`, em `.claude/agents/`) **não recebem a ferramenta `Agent`**: o Claude Code permitiria aninhar sub-agents, mas por decisão de projeto (custo e controle do teto de rodadas) toda a coordenação fica aqui.

Delegar tem custo: cada agente começa sem memória, recarrega contexto e devolve um relatório. Só vale quando o trabalho é grande ou arriscado o bastante para compensar. Por isso a primeira decisão é sempre "preciso mesmo delegar?".

## 1. Decidir: direto ou delegar

| Situação | Quem faz |
|---|---|
| Pergunta, explicação, leitura de código, ajuste de documentação, mudança em **1 arquivo sem regra de cálculo** | Sessão principal, direto |
| Toca **regra de cálculo**, tabelas fiscais, **vários arquivos**, ou implementa um **bloco do `docs/SPECS.md`** | Laço completo: planner → executor → reviewer |
| A implementação já existe e falta só validar (E2E, revisão, commit/PR) | `reviewer` direto |
| Falta só o plano (spec/change) | `planner` direto |
| Dúvida entre os dois primeiros | Trate como o segundo: o risco de errar uma regra trabalhista pesa mais que o custo do laço |

Decida pelo **conteúdo da tarefa**, não pelo tamanho do prompt. Um pedido de uma linha como "inclua o art. 479" é laço completo.

Se a decisão não for óbvia, diga em uma frase qual caminho escolheu e por quê, e siga. Não peça permissão para delegar.

## 2. O laço

```
planner  →  [checkpoint humano: plano]  →  executor  →  reviewer
                                              ↑              |
                                              └── reprovou ──┘   (máx. 3 rodadas)
                                                  aprovou → commit/PR (humano confirma)
```

No **modo autônomo** (§8) o checkpoint do plano e as confirmações de commit, push, PR e merge não se aplicam.

1. **Planner** transforma o bloco do `docs/SPECS.md` em uma change de OpenSpec pronta (skill `openspec-planning`). Entrega: nome da change, resumo, questões em aberto.
2. **Checkpoint:** mostre ao usuário o resumo da change e peça "ok" antes de executar. A spec define tudo o que vem depois; corrigir aqui é barato, depois é caro. Se as questões em aberto envolverem regra trabalhista (⚖️), elas voltam ao usuário, nunca se resolvem por palpite.
3. **Executor** implementa a change (skills `flutter-conventions` e `calc-rules`), roda `flutter analyze` e os testes unitários e de widget, e marca as tasks. Entrega: relatório curto.
4. **Reviewer** valida (skills `review-checklist` e `maestro-e2e`): critérios de aceite, testes, E2E, documentação. Veredito: **APROVADO** ou **REPROVADO** com feedback numerado.
5. **Reprovado:** devolva o feedback do reviewer ao executor, **inalterado** (não reinterprete). Conte a rodada. Retire a linha "Regra que faltou" de cada item antes de repassar (é para você, não para o executor) e guarde-as para o passo 7. O executor não edita `proposal.md`, `design.md` nem `specs/**`: item que peça mudar a documentação da change (spec ou design divergem do código) vai ao `planner`, os demais ao executor, na mesma rodada.
6. **Aprovado:** o reviewer **prepara** commit e PR (staging local, mensagem e corpo do PR; skill `pr-and-commit`), mas **não tem permissão** de commitar nem publicar. Você apresenta a proposta ao usuário e, **só com o "sim" explícito dele, a cada ação**, executa `git commit`, `git push` e `gh pr create` na sessão principal.

7. **Melhoria do harness** (ao aprovar ou ao parar no teto): reúna as "Regra que faltou" de todas as rodadas, junte as repetidas e mostre ao usuário só as que propõem regra nova ou reforço. Com o "sim" dele, edite o destino (`.claude/rules/`, skill ou agente) e commite à parte: `chore(harness): <regra>`. Sem documento de registro: o `git log` de `.claude/` é o histórico. Não edite o harness sem aprovação.

### Teto de 3 rodadas
Rodada = um ciclo executor → reviewer. Se a 3ª terminar reprovada, **pare**. Entregue ao usuário: o que foi tentado, o que continua falhando e sua hipótese da causa. Não tente uma 4ª rodada por conta própria; falhas repetidas costumam ser spec ambígua ou premissa errada, e isso é decisão humana.

## 3. Passagem de trabalho

Cada agente começa do zero. Escreva o que ele precisa, em arquivos e no prompt:

- **Passe caminhos, não conteúdo.** "Leia `openspec/changes/<nome>/` e `docs/SPECS.md` bloco B2", não o texto colado.
- **Prompt de delegação** com: objetivo em 1 frase, a change/bloco, restrições que valem aqui (ex.: "não alterar `docs/`"), e o formato de relatório esperado.
- **Relatório de volta**, no máximo ~25 linhas:
  ```
  Status: concluído | parcial | bloqueado
  Feito: <itens>
  Arquivos: <lista>
  Verificação: <comandos rodados e resultado>
  Pendências / dúvidas: <itens>
  ```
- O estado do trabalho vive na change (`tasks.md` com checkboxes), não na conversa.

## 4. Esforço e modelo por agente

Cada agente tem modelo e esforço próprios, definidos no arquivo dele em `.claude/agents/`. Padrão atual: Sonnet 5.5, esforço médio. Suba o esforço do `planner` quando a spec tocar regra de cálculo; do `executor`, quando a task for refatoração grande. Registre a mudança no arquivo do agente, não só nesta conversa.

## 5. O que nunca se delega nem se automatiza

- Decisões de produto e interpretação de regra trabalhista sem fonte (⚖️).
- **Push, PR, merge, arquivar change em branch principal**: sempre confirmação humana, **exceto no modo autônomo (§8)**, quando o usuário o pediu para aquela execução.
- Ações destrutivas (apagar branches, `reset --hard`, `push --force`).
- Qualquer coisa que os hooks do projeto bloquearem (segredos, etc.): não contorne; peça ao usuário.

## 6. Acompanhamento do progresso

`docs/PROGRESS.md` mostra quanto do `docs/SPECS.md` foi realmente feito. Ele é **gerado**, nunca editado à mão, pelo script `scripts/specs_progress.py`, que cruza os IDs do SPECS com as tasks das changes (ativas e arquivadas). Os agentes não rodam o script (nem têm `python` na lista de ferramentas): **você roda, em três marcos**:

| Marco | O que verificar no relatório |
|---|---|
| **1. Planner terminou** | Aparecem "buracos no plano" (requisitos do bloco sem task) ou "IDs inexistentes"? Devolva ao planner para corrigir antes do checkpoint com o usuário |
| **2. Reviewer aprovou** | Todas as tasks da change estão marcadas (✔ implementado)? O estado reflete o que foi aprovado? |
| **3. Change arquivada** | Os requisitos da change viram 🚀 entregue |

```bash
python scripts/specs_progress.py          # regenera docs/PROGRESS.md
python scripts/specs_progress.py --check  # exit 1 se estiver desatualizado ou com alertas de erro
```
Inclua `docs/PROGRESS.md` no commit da change (a skill `pr-and-commit` o prevê): o histórico do arquivo no git é a linha do tempo do progresso.

Regra que sustenta tudo: **toda task cita o ID do requisito (`B2-04`)** que ela cumpre, na linha ou no título (`##`) acima dela. Sem a citação, o requisito aparece como "sem plano" mesmo estando feito. "Entregue" só existe depois do arquivamento (que exige confirmação humana); aprovar a change não basta.

## 7. Fechamento


Ao terminar (ou ao parar no teto de rodadas), responda em poucas linhas: caminho escolhido (direto/laço), rodadas usadas, veredito, o que ficou pendente. Sem repetir o conteúdo dos relatórios.

## 8. Modo autônomo (loop)

Executa os blocos do SPECS em sequência, sem humano, com cada alvo rodando em um `claude -p` headless (`scripts/loop_worker.sh`) até o merge. **Só com pedido explícito do usuário** ("rode o loop", "modo autônomo"); a autorização vale só para aquela execução. Sem o pedido, valem as confirmações das seções anteriores.

Procedimento, state, regras do worker, condição de merge e proibições: `references/loop.md`. Prompt do worker: `references/worker-prompt.md`. Dúvida ⚖️ ou de produto nunca é resolvida por palpite: o alvo vira `blocked` e o loop segue para o próximo.
