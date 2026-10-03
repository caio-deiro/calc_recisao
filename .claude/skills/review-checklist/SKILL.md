---
name: review-checklist
description: Critérios e procedimento para revisar uma change implementada neste projeto e emitir veredito APROVADO ou REPROVADO com feedback acionável ao executor. Cobre critérios de aceite do docs/SPECS.md, testes, regras de cálculo (⚖️), documentação, privacidade, escopo do diff e E2E. Use sempre que for revisar, validar ou "aprovar" uma implementação, fechar uma rodada do laço, ou checar um diff antes de commit/PR, mesmo que o usuário diga apenas "revise isso" ou "está pronto?".
---

# Revisão de uma change

O reviewer é a **última barreira antes de algo sair da máquina**. Reprova quando há falha real, aprova quando não há, e **nunca conserta** (consertar esconde o que o executor deveria aprender e quebra a rastreabilidade). A única escrita permitida é em `.maestro/`.

## Entradas
Nome da change (`openspec/changes/<nome>/`), o diff (`git diff` e `git status`) e o número da rodada (1 a 3).

## Procedimento

### 1. Escopo
- `git status` e `git diff --stat`: só os arquivos da change devem ter mudado. Alterações fora do escopo (ex.: `android/`, `pubspec.lock` de outras mudanças) **não podem ir junto**; aponte.
- Todas as `tasks.md` da change estão marcadas e correspondem ao que foi feito?

### 2. Critérios de aceite
Para cada requisito/cenário do delta de spec e cada ID de `docs/SPECS.md` (`B<n>-<nn>`) da change, aponte a **evidência**: um teste, um fluxo E2E ou um trecho de código. Requisito sem evidência é falha.
```
openspec validate <nome> --strict
```

### 3. Testes
```bash
flutter analyze
flutter test
```
- Zero erros e warnings novos no `analyze`; suíte verde.
- Há teste novo para cada comportamento novo? O teste prova comportamento, ou só repete a implementação?
- Regra de cálculo: existe **caso golden** com fonte externa (skill `calc-rules`)? Regra ⚖️ sem fonte deve sair com a premissa "cálculo em validação"; sem isso, **reprove**.

### 4. Qualidade e regras do projeto (skill `flutter-conventions`)
- Lógica de negócio fora do `State`; `mounted` após `await`; `dispose` de controllers.
- **Simplicidade** (`.claude/rules/principios.md`): o diff introduz abstração, parâmetro, camada, dependência ou padrão que a spec não pediu? Há lógica de negócio ou constante duplicada em mais de um lugar? Há código morto deixado para trás? Trate o excesso como **sugestão**, e como **bloqueador** só se adiciona dependência/padrão novo sem aprovação ou duplica uma regra de negócio.
- Sem dado pessoal em log, evento ou crash; sem `print` com dado do usuário.
- Sem segredo no diff (chaves, keystore, `.env`).
- Anúncios: nenhum antes do resultado; intersticial só ao sair do Resultado, com limites (PRD §8).
- Totais separados ("Pago na rescisão" × "Depositado no FGTS") e premissas, quando aplicável.

### 5. Documentação
Mudou camada, dependência, fluxo ou regra? `docs/ARCHITECTURE.md`, `docs/PROJECT.md` e `docs/SPECS.md` foram atualizados **no mesmo diff**? Base legal citada para mudança de regra trabalhista?

### 6. E2E
Se a change toca tela ou fluxo de usuário, rode os fluxos Maestro (skill `maestro-e2e`). Falha reproduzida duas vezes reprova.

## Veredito

**Só bloqueadores reprovam.** Separe sempre:
- **Bloqueador:** requisito sem evidência, teste falhando, regra ⚖️ sem validação ou aviso, dado pessoal vazando, segredo no diff, escopo fora do combinado, E2E falhando duas vezes, doc obrigatória sem atualizar.
- **Sugestão:** melhoria de estilo ou refatoração opcional. Não reprova; registre separado.

Formato (máx. ~30 linhas):
```
Veredito: APROVADO | REPROVADO   (rodada N/3)
Verificação: analyze <ok|n erros> | testes <n/n> | E2E <n/n ou n/a> | openspec validate <ok|falhou>

Bloqueadores (só se reprovado):
1. <arquivo:linha> — <o que está errado> — <por quê importa> — <como verificar que foi corrigido>
   Regra que faltou: <regra existente ignorada (arquivo + trecho) | texto proposto para regra nova + onde entra>
2. ...

Sugestões:
- ...

Pendências para o usuário (⚖️, dúvidas de produto):
- ...
```
O feedback é **numerado, específico e verificável**: o executor deve conseguir agir sem perguntar. Não reabra o que já foi aprovado em rodada anterior, a menos que uma correção o tenha quebrado.

### Regra que faltou (melhoria contínua do harness)
Todo bloqueador diz **por que o executor errou**: a regra existia e foi ignorada, estava ambígua, ou não existia. Destino da regra: `.claude/rules/`, uma skill, ou `.claude/agents/executor.md`. Cite o trecho exato (se existe) ou escreva o texto proposto (se não existe). Erro de execução isolado, sem falha de regra (ex.: typo), diga "nenhuma: erro pontual". O reviewer **não edita** o harness; só propõe. O orquestrador aplica (ver `orchestrate`, seção 2).

## Depois do veredito
- **Reprovado:** entregue o feedback ao orquestrador, que o repassa ao executor sem alterações.
- **Aprovado:** siga para a skill `pr-and-commit`. Se esta foi a 3ª rodada e continua reprovado, o orquestrador interrompe o laço e devolve o caso ao usuário.
