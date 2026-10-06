## Context

Esta change é B2.4 do SPECS (B2-13..15), separada de `fix-calculation-rules` por decisão do usuário em 2026-10-05. Depende dela (usa `BreakdownCode`, `fgtsDeposit`, runner por `code`) e só começa com os casos golden `calculo_legal` (C1–C5), sem os quais o critério B2-15 não é demonstrável. Hoje o domínio usa `double` e `_roundCurrency` via `toStringAsFixed`.

## Decisions

### D1. Ordem
1. Pré-condição: casos golden `calculo_legal` presentes e `flutter test test/golden` verde com 0,01; o gate `release-gate` é rodado só para registrar baseline (4 regras ⚖️ esperadas), sem bloquear.
2. Teste unitário de arredondamento e de artefato de ponto flutuante antes da troca (B0-02).
3. Migrar use case e `calculateTerminationTaxes`.
4. Baixar `goldenTolerance` para 0,00 e rodar a suíte golden. Qualquer divergência de centavos é explicada por escrito; o documento oficial decide quem está certo.

### D2. Modelo numérico (B2-13)
`Decimal` para valores; `Rational` para divisões, convertidas com escala explícita; `roundHalfUp` a 2 casas por item nos **mesmos pontos** de `_roundCurrency` (nenhum ponto de arredondamento novo ou removido). Alíquotas e faixas lidas de `tax_tables.json` como texto para `Decimal` (sem passar por `double`). Descartado: manter `double` com `toStringAsFixed` (causa do problema); inteiros em centavos (muda as fórmulas de todas as regras e dificulta a revisão).

### D3. Fronteiras (B2-14)
`TerminationInput` continua `double`; conversão `Decimal.parse(value.toString())` na entrada do use case. `BreakdownItem.value` e totais continuam expostos como `double` (convertidos na saída do use case) para não tocar UI, PDF e JSON. O comparador golden mantém o épsilon de 1e-9 para a conversão.

### D4. Tolerância (B2-13, handoff de B6-02)
`goldenTolerance` vai de 0,01 para 0,00 neste passo. O SPECS B2-15 diz "sem alterar tolerância"; a leitura adotada: a suíte passa com 0,01 **antes** e com 0,00 **depois**, sem alterar valores esperados. Sugerir ajuste de redação do B2-15 no SPECS (orquestrador).

### Ordem de arquivamento
O bloco MODIFIED de `golden-tests` assume o texto produzido por `fix-calculation-rules`; arquivar aquela primeiro.

## Risks / Trade-offs
- A troca pode mover centavos silenciosamente; mitigada por D1 e pelo gate golden.
- Sem golden real, a change não deve iniciar (risco de declarar "sem diferença" sem oráculo).

## Open Questions
1. B6-06 (usuário): TRCT real/contador (`exemplo_contador`) para as 4 regras ⚖️ pendentes. Não bloqueia esta change; bloqueia a publicação.
