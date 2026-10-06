## Contexto (confirmado no código)
- `TaxTablesService.calculateInss` devolve o valor progressivo sem arredondar (ex.: 155,685).
- `calculateTerminationTaxes` guarda `inssSalary`/`inssThirteenth` crus e o getter `TerminationTaxResult.inss` soma os dois. O IRRF de cada parcela é `calculateIrrf(bruto - inssCru, ...)`: a base do IRRF hoje usa INSS **não** arredondado.
- `CalculateTermination` (~linha 340) faz `_roundCurrency(taxes.inss)`: arredonda a soma. 155,685 + 200,685 = 356,370 → 356,37; por parcela 155,69 + 200,69 = 356,38.

## Decisões
1. **Ponto de arredondamento:** em `calculateTerminationTaxes`, `inssSalary = round(calculateInss(saldo))` e `inssThirteenth = round(calculateInss(13º))`, half-up, `AppConstants.decimalPlaces`. `calculateInss` continua cru (testes de tabela e outros chamadores intactos). O `_roundCurrency` da soma no use case vira no-op e pode ser removido.
2. **Base do IRRF:** usa o INSS já arredondado de cada parcela (bruto − INSS arredondado), coerente com o valor descontado e exibido. Muda o comportamento atual (cru) em até 0,005 na base; o IRRF final só muda se cruzar um limite de arredondamento.
3. Sem nova abstração; a regra fica em um único lugar (o serviço).

## Alternativas descartadas
- Manter a soma arredondada: contraria a decisão (recolhimentos distintos).
- Arredondar dentro de `calculateInss`: altera todos os chamadores e testes de tabela sem necessidade.

## Cálculo à mão (oráculo, tabela 2026, Portaria MPS/MF 13/2026)
Faixas: 7,5% até 1.621,00; 9% até 2.902,84.
- Saldo 2.000,00: 1.621 × 0,075 = 121,575; (2.000 − 1.621) × 0,09 = 34,11; total 155,685 → **155,69**.
- 13º 2.500,00: 121,575 + (2.500 − 1.621) × 0,09 = 121,575 + 79,11 = 200,685 → **200,69**.
- INSS = 155,69 + 200,69 = **356,38** (soma crua 356,370 → 356,37, divergente).
- IRRF: bases 2.000 − 155,69 = 1.844,31 e 2.500 − 200,69 = 2.299,31, ambas ≤ 2.428,80 (isento), sem dependentes → 0,00.

## Riscos
- Golden promovidos podem variar 0,01 (tolerância do runner 0,01): rodar `flutter test test/golden`; divergência é achado, nunca se ajusta o esperado ao app.
- ⚖️ A convenção segue sem validação de contador.

## Open Questions
- Nenhuma que bloqueie. Se algum caso de B4 passar a divergir além de 0,01, o executor reporta.
