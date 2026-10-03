---
name: epics
description: Gera ou atualiza docs/EPICS.md, dividindo o PRD (docs/PROJECT.md) em épicos, isto é, blocos grandes de features com escopo, dependências, ordem e rastreabilidade. Use sempre que o usuário pedir épicos, "epics", quebrar o PRD em blocos/frentes/features grandes, roadmap de entrega, planejar a ordem de implementação, ou atualizar o status dos épicos depois de uma mudança no PRD, mesmo que ele não diga a palavra "épico". Não use para tarefas pequenas, user stories ou checklists de implementação.
---

# Épicos a partir do PRD

Transforma `docs/PROJECT.md` em `docs/EPICS.md`: uma lista curta de **blocos grandes de features**, cada um entregável sozinho e rastreável até o PRD. O épico responde "o que entregamos e por quê, em que ordem". O "como, passo a passo" fica para o OpenSpec (`openspec/changes/`), depois.

Por que isso importa: o PRD mistura contexto, regras e decisões. Quem implementa precisa de unidades de trabalho com fronteira clara. Se o épico virar lista de tarefas, vira um segundo PRD que envelhece; se ficar vago, ninguém sabe quando terminou.

## Antes de escrever

Leia só o necessário, sem carregar tudo:

1. `docs/PROJECT.md`: escopo (§5), regras de negócio (§6), plano de execução (§15), registro de decisões (§16), riscos (§12) e pendências.
2. `docs/ARCHITECTURE.md`: apenas a tabela de dívidas técnicas e as marcas 🎯, para ligar dívida a épico.
3. `openspec/changes/` e `openspec/specs/`: veja o que já existe para não duplicar nem contradizer.
4. `docs/EPICS.md`, se existir: o modo é **atualizar** (ver abaixo).

Respeite as marcas dos docs: ✅ é o que o código faz hoje; 🎯 está decidido e não implementado; ⚖️ exige validação humana. Nunca descreva 🎯 como se existisse.

## Como identificar épicos

Agrupe por **capacidade entregue ao usuário ou ao projeto**, não por camada técnica ("refatorar repositório" não é épico; "remover o plano PRO" é). Um bom épico:

- tem um resultado verificável de ponta a ponta;
- cabe em uma versão publicável (ou em poucas);
- depende de poucos outros épicos;
- reúne decisões do PRD que andam juntas.

Meta: **5 a 9 épicos**. Menos de 5 costuma esconder fronteiras; mais de 9 costuma ser tarefa disfarçada. Se o PRD já define changes ou fases (ex.: §15), use-as como esqueleto e some o que ficou sem dono: conformidade e privacidade, qualidade e validação, manutenção anual de tabelas, documentação.

Não invente escopo. Se algo parece necessário mas não está no PRD, registre em "Lacunas e perguntas", sem criar épico para isso.

## Formato do EPICS.md

Use este esqueleto, em português, sem enfeite:

```markdown
# EPICS

> Derivado de docs/PROJECT.md em <data>. Épico = bloco grande de features.
> Detalhamento de implementação vive em openspec/changes/.

## Visão geral

| ID | Épico | Tamanho | Status | Depende de | Change OpenSpec |
|---|---|:-:|---|---|---|
| E1 | ... | M | 🎯 | — | `nome-da-change` |

## Ordem sugerida
<1 a 3 linhas: sequência e o motivo (dependências, risco, valor).>

---

## E1 — <título curto>
**Objetivo:** <resultado para o usuário/projeto, uma frase>
**Persona:** A | B | ambas | projeto
**Status:** ✅ pronto | 🟡 parcial | 🎯 não iniciado
**Tamanho:** S | M | L

**Escopo (dentro)**
- <capacidade, em linguagem de produto>

**Fora do escopo**
- <o que fica de fora de propósito>

**Origem no PRD:** §x.y, Qn (decisões)
**Dependências:** E_ ...
**Dívidas técnicas ligadas:** Dn
**Riscos / ⚖️ validação:** <o que precisa de confirmação humana ou tem risco>
**Pronto quando:** <2 a 4 critérios verificáveis, de alto nível>

---

## Rastreabilidade
| Decisão do PRD | Épico |
|---|---|
| Q1 ... | E2 |

## Lacunas e perguntas
- <o que o PRD não resolve e bloqueia ou afeta algum épico>
```

## Regras de qualidade

- **Cada épico cabe em ~20 linhas.** Se passou disso, falta síntese ou é mais de um épico.
- **Linguagem de produto**, não de código. Cite arquivos só em "Dívidas técnicas ligadas".
- **"Pronto quando" é verificável**: algo que alguém consegue conferir (um comportamento, um teste golden aprovado, um item removido), nunca "melhorar" ou "otimizar".
- **Sem user stories e sem tarefas.** Se sentir vontade de listar passos, pare: isso é o `tasks.md` da change.
- **Tamanho é estimativa relativa** (S, M, L), não horas. Ao classificar, considere incerteza e validação externa, não só volume de código.
- **Ordem justificada**: dependências reais primeiro; depois, o que reduz risco ou entrega confiança antes do que adiciona escopo.
- **Rastreabilidade completa**: toda decisão do PRD que mude produto deve aparecer em algum épico. Se não aparecer, é lacuna: liste-a.
- **Regras com ⚖️** nunca entram como "pronto" sem a validação prevista no PRD ser citada em "Riscos / ⚖️ validação".

## Modo atualizar (quando docs/EPICS.md já existe)

Preserve IDs, títulos e ordem. Os IDs são referenciados por changes, commits e conversas; renumerar quebra isso. Atualize apenas:

- **Status**, comparando o PRD e o código atual (✅/🟡/🎯), e confirme olhando os arquivos, não só o texto dos docs;
- **Escopo, decisões e dependências** que o PRD alterou, e a rastreabilidade;
- **Lacunas** resolvidas (remova) ou novas (acrescente).

Se for preciso criar um épico novo, use o próximo ID livre. Se um épico deixou de fazer sentido, marque como `⛔ cancelado` com o motivo em uma linha, sem apagá-lo.

## Ao terminar

Responda em poucas linhas: quantos épicos, a ordem sugerida e as lacunas encontradas. Não repita o conteúdo do arquivo. Se o PRD e o código divergirem de forma relevante, diga qual divergência e onde ela afeta os épicos.
