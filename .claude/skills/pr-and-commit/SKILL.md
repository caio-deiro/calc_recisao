---
name: pr-and-commit
description: Prepara commit e pull request estruturados para uma change aprovada neste projeto (branch, staging seletivo, mensagem, corpo do PR com testes e riscos) e só publica com confirmação explícita do usuário. Cobre também o tratamento de comentários de review depois do PR. Use sempre que o usuário pedir "commite", "faça o commit", "abra o PR", "suba isso", ao fechar o laço de revisão com veredito APROVADO, ou ao tratar comentários de review num PR. Nunca faz push, PR ou merge sem confirmação humana.
---

# Commit e PR

Commit e PR são o ponto onde o trabalho **sai da máquina e fica registrado**. Por isso preparar é automático, mas **publicar exige "sim" do usuário, todas as vezes**: aprovação anterior não vale para a ação seguinte.

Pré-requisito: o `reviewer` emitiu **APROVADO** para a change. Sem isso, não prepare nada.

**Modo autônomo.** Quando o worker roda sob `orchestrate` §8 (loop pedido pelo usuário), o passo 4 (pedir "sim") não se aplica: o worker faz commit, push, PR e squash-merge conforme `orchestrate/references/loop.md`. Os passos 1 a 3 e 5 valem iguais. Fora do loop, tudo abaixo continua exigindo o "sim".

**Quem faz o quê.** Quando esta skill roda dentro do agente `reviewer`, ele só **prepara** (branch local, `git add` seletivo, mensagem de commit e corpo do PR) e devolve a proposta: o agente não tem `git commit`, `git push` nem `gh`. Os passos 3 (commit) e 4 (push e PR) abaixo são executados pelo **orquestrador** na sessão principal, depois da confirmação do usuário.

## 1. Branch
Trabalhe em `change/<nome-da-change>`, não direto na `main`. Se estiver na `main`, crie a branch antes de commitar.
```bash
git switch -c change/<nome>
```

## 2. Staging seletivo
O working tree costuma ter alterações **alheias** à change (ex.: `android/`, `pubspec.lock`, logs de build). Nunca use `git add -A` ou `git add .`.
```bash
git status --short
git add <caminho1> <caminho2> ...   # só os arquivos da change
git diff --cached --stat
```
Se a change mexeu em tasks ou foi arquivada, inclua `docs/PROGRESS.md` (regenerado pelo orquestrador com `python scripts/specs_progress.py`) no staging.
Confira que nada de segredo entrou (`key.properties`, keystore, `.env`; os hooks bloqueiam o acesso, mas confira o staging).

## 3. Mensagem de commit
Formato `<tipo>: <resumo imperativo em português>`, tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.
```
feat: remove plano PRO e reposiciona anúncios

Change: remove-pro-ads-only (SPECS B1-01..B1-14)
- remove PurchaseService, ProUtils e ProScreen
- intersticial passa a aparecer só ao sair do Resultado
Testes: flutter test 142/142; E2E 3/3
```
- Corpo: o **porquê** e o que importa para quem lê o histórico; cite a change e os IDs do SPECS.
- Regra trabalhista alterada: cite a **base legal** (artigo, súmula, portaria).
- Termine com a linha de coautoria definida pelo ambiente, se houver.
- Prefira um commit por change coerente; separe só se houver partes realmente independentes (ex.: docs).

## 4. Pedir confirmação ANTES de publicar
Mostre ao usuário, e espere o "sim":
- a mensagem do commit e a lista de arquivos;
- a branch, e o que será enviado (`git log origin/main..HEAD --oneline`);
- o título e o corpo do PR.

Só então: `git commit`, `git push -u origin <branch>` e `gh pr create`. São três ações; se o usuário confirmou só o commit, **pare no commit**.

## 5. Corpo do PR
```markdown
## Resumo
<2 a 3 linhas: o que muda e por quê>

## Change e requisitos
- OpenSpec: `<nome-da-change>`
- SPECS: B<n>-<nn>, ...
- Decisões do PRD: Q<n>, ...

## Testes
- `flutter analyze`: <resultado>
- `flutter test`: <n/n> (unitário + widget)
- E2E (Maestro): <n/n ou n/a>
- Casos golden: <adicionados/alterados>

## Pontos de atenção
- Itens ⚖️ e premissas "em validação": <lista ou nenhum>
- Dívidas resolvidas: D<n>
- Fora do escopo: <o que ficou para depois>

## Docs atualizados
<lista>
```
Use `gh pr create --title "..." --body-file <arquivo>` (escreva o corpo em arquivo para preservar a formatação). Não habilite auto-merge, a menos que o usuário peça.

## 6. Depois do PR
Se o ambiente tiver ferramentas de PR (`ccd_pr`), use `get_status` e, se o PR não estiver vinculado, `bind_pr`. **Não faça polling de CI** nem agende verificações.

### Comentários de review no PR
A revisão externa do PR é **assíncrona**, depois que ele existe; não faz parte do mesmo laço. Quando o usuário trouxer o retorno ou pedir para tratá-lo:
```bash
gh pr view <n> --comments
gh api repos/{owner}/{repo}/pulls/<n>/comments
```
1. Classifique cada achado: **procede** (corrigir), **não procede** (responder com o motivo) ou **dúvida** (perguntar ao usuário).
2. Correções viram uma **nova tarefa** para o executor (com teto de 3 rodadas próprio) e novo commit na mesma branch; novo push também precisa de confirmação.
3. Não resolva threads nem faça merge sem o usuário.

## 7. Depois do merge
Arquivar a change (`openspec archive <nome> -y`, que atualiza `openspec/specs/`) é um passo separado, **com confirmação**, feito na branch principal após o merge.

## Nunca
`push --force`, apagar branch, merge ou `git reset --hard` sem pedido explícito. Em caso de conflito ou rejeição, pare e reporte.
