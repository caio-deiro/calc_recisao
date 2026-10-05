Modo autônomo do loop. Entregue o alvo {{ALVO}} (docs/SPECS.md) de ponta a ponta, sem humano: planejamento, implementação, revisão, commit, PR, merge e arquivamento, retomando da etapa em que o repositório estiver.

Leia e siga a skill `orchestrate` e, no que ela divergir, a seção "Worker" de `.claude/skills/orchestrate/references/loop.md`: ela dá a autorização desta execução, define a etapa pelo estado do repositório e substitui os checkpoints humanos. A skill `pr-and-commit` vale, exceto o passo de pedir "sim".

Não pergunte nada ao usuário (não há ninguém). Dúvida de regra trabalhista (⚖️) ou de produto sem fonte: termine com `status: blocked`, sem palpitar. Comando negado pelas permissões: não contorne; reporte.

Sua última linha de saída deve ser exatamente uma linha `LOOP_RESULT {json}` no formato definido em loop.md.
