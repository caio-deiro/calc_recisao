---
name: openspec-planning
description: Transforma um bloco do docs/SPECS.md (ou um pedido de feature/correção) em uma change de OpenSpec completa e validada (proposal, specs, design, tasks) antes de qualquer código. Use sempre que for planejar, especificar ou "criar a change" de um bloco B1..B7, de um épico do docs/EPICS.md ou de uma mudança de regra; quando o usuário disser "planeje", "especifique", "monte a spec", "crie a change"; e como etapa de planner do laço de orquestração. Não escreve código do app.
---

# Planejamento com OpenSpec

Objetivo: ao final, existe `openspec/changes/<nome>/` completa, validada, sem ambiguidades, para o executor implementar **sem precisar adivinhar**. Planejar bem é onde se barateia o resto: erro na spec se multiplica em código, testes e revisão.

Nenhuma linha de código do app é escrita aqui.

## Passo a passo

### 1. Entender a intenção
Leia só o necessário:
- O **bloco** em `docs/SPECS.md` (IDs `B<n>-<nn>`) e as seções do PRD (`docs/PROJECT.md`) que ele cita.
- `docs/ARCHITECTURE.md` nas partes que o bloco toca (e a tabela de dívidas).
- `openspec/specs/` e `openspec/changes/` para não duplicar nem contradizer. `openspec list` e `openspec list --specs` mostram o que existe.
- `docs/PROJECT.md §16` (decisões Q1–Q28): o que já está decidido **não se rediscute**.

Se faltar uma decisão de produto, pare e devolva a pergunta ao usuário com uma recomendação. Não invente escopo. Regra trabalhista sem fonte (⚖️) é pergunta, nunca premissa.

### 2. Criar a change
Não existe `openspec new`; crie a estrutura:
```
openspec/changes/<nome-em-kebab-case>/
├── .openspec.yaml        # schema: spec-driven  /  created: AAAA-MM-DD
├── proposal.md
├── design.md
├── tasks.md
└── specs/<capability>/spec.md
```
O nome descreve o resultado (ex.: `remove-pro-ads-only`), não a tarefa. Uma change = um bloco ou subbloco que cabe em uma versão publicável.

### 3. Escrever os artefatos, na ordem
Antes de cada artefato, peça as instruções ao OpenSpec; elas listam dependências e o formato esperado:
```bash
openspec instructions <proposal|specs|design|tasks> --change <nome>
openspec status --change <nome>
```
- **proposal.md**: `## Why`, `## What Changes`, `## Capabilities` (novas e modificadas), `## Impact`, fora de escopo. Cite o bloco do SPECS e as decisões Q.
- **specs/<capability>/spec.md** (delta): seções `## ADDED|MODIFIED|REMOVED Requirements`; cada `### Requirement:` usa **MUST/SHALL**; cada `#### Scenario:` tem `WHEN`/`THEN`. Os cenários devem ser **verificáveis**: algo que um teste ou um fluxo E2E consegue provar. Se não dá para testar, reescreva.
- **design.md**: decisões técnicas e alternativas descartadas; módulos afetados; modelo de dados e compatibilidade (ex.: histórico antigo); riscos; **Open Questions**. Resolva com o usuário as questões que mudariam o que é construído.
- **tasks.md**: grupos `## 1.`, `## 2.` com `- [ ] 1.1 ...`. Regras:
  - tarefa pequena e verificável (um comando ou comportamento prova que acabou);
  - **testes viram tarefas**: unitário, widget e, quando houver fluxo de usuário, o fluxo Maestro correspondente;
  - tarefa de **atualização de docs** quando mudar camada, dependência ou regra (regra do `CLAUDE.md`);
  - tarefas de regra de cálculo começam pelo **caso golden** (skill `calc-rules`);
  - **toda task cita o ID do SPECS (`B2-04`)** que cumpre, na própria linha ou no título `##` do grupo (intervalos como `B2-01…03` valem). É isso que alimenta o `docs/PROGRESS.md`: requisito sem task citando-o aparece como "sem plano". **Cubra todos os IDs do bloco** da change, ou diga no relatório quais ficaram de fora e por quê. Cuide da digitação: o relatório acusa ID inexistente.

Idioma: português, mantendo `MUST/WHEN/THEN` e os cabeçalhos em inglês, como nas changes existentes.

### 4. Validar
```bash
openspec validate <nome> --strict
openspec status --change <nome>      # 4/4 artefatos
```
Corrija até passar. Uma change inválida não vai ao executor.

### 5. Entregar
Devolva ao orquestrador (máx. ~15 linhas): nome da change, resumo em 3 linhas, nº de tasks, **questões em aberto**, itens ⚖️ e qualquer divergência encontrada entre PRD, SPECS e código. Não repita o conteúdo dos arquivos.

## Cuidados
- Não altere `docs/` nem código; se o SPECS estiver errado ou desatualizado, **reporte** a divergência.
- Uma change grande demais (mais de ~25 tasks ou mais de um bloco) deve ser dividida; avise antes de dividir.
- Archive (`openspec archive`) só depois de implementada e aprovada, e com confirmação humana.
