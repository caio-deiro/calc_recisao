#!/usr/bin/env bash
# Roda UM alvo do loop (ver .claude/skills/orchestrate/references/loop.md) num claude headless.
# Uso: scripts/loop_worker.sh <alvo>     ex.: scripts/loop_worker.sh B3/add-vacation-periods
# Variáveis: LOOP_TIMEOUT (padrão 110m), LOOP_EFFORT (padrão low), LOOP_MODEL, LOOP_BUDGET_USD (opcional; sem ele não há teto, o plano é assinatura).
# Saída: .claude/loop/<alvo com / trocado por _>.json (resultado) e .err (stderr).
# O fim do processo é o sinal de término; a verificação real é no git/gh (feita pelo orquestrador).
# Permissões: .claude/loop-worker.settings.json (dontAsk + allowlist fechada + deny).
set -u

ALVO="${1:?uso: loop_worker.sh <alvo>}"
NOME="${ALVO//\//_}"
DIR=".claude/loop"
mkdir -p "$DIR"

# Menor que o timeout do Bash em background (2h) para o script sempre terminar primeiro.
LIMITE="${LOOP_TIMEOUT:-110m}"

PROMPT="$(sed "s|{{ALVO}}|$ALVO|g" .claude/skills/orchestrate/references/worker-prompt.md)"

EXTRA=(--effort "${LOOP_EFFORT:-low}")
[ -n "${LOOP_MODEL:-}" ] && EXTRA+=(--model "$LOOP_MODEL")
[ -n "${LOOP_BUDGET_USD:-}" ] && EXTRA+=(--max-budget-usd "$LOOP_BUDGET_USD")

timeout "$LIMITE" claude -p "$PROMPT" \
  --settings .claude/loop-worker.settings.json \
  --permission-mode dontAsk \
  --output-format json \
  --name "loop-$NOME" \
  "${EXTRA[@]}" \
  > "$DIR/$NOME.json" 2> "$DIR/$NOME.err"
CODE=$?
[ "$CODE" -eq 124 ] && echo "worker $ALVO estourou o limite de $LIMITE"
echo "worker $ALVO terminou com exit=$CODE"
exit $CODE
