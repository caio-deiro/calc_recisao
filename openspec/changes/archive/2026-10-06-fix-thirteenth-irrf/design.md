## Context
`calculateTerminationTaxes` soma `calculateIrrf` (saldo) e `calculateIrrfAnnual` (13º). `calculateIrrf` passa `taxableBase` (já menos INSS e dependentes) ao `_applyMonthlyReducer`. Ver `lib/core/services/tax_tables_service.dart` (~204-258 e ~276-306).

## Fontes (⚖️, acesso 2026-10-05, registradas em `docs/golden-dossie/README.md`, perguntas 2 e 7)
- Lei 7.713/88 art. 26: 13º tributado exclusivamente na fonte, separado dos demais rendimentos.
- SEFAZ-SP, "Rendimentos sujeitos a tributação exclusiva na fonte".
- Lei 15.270/2025 (art. 3º-A, §3º, Lei 9.250/95) e exemplo da Receita Federal (rendimento bruto 6.000).
- Decreto 3.048/99 art. 214 §6º e §7º (INSS do 13º).
O planner não reconsultou a web: usa as fontes já registradas no dossiê. A regra continua ⚖️ até o usuário validar.

## Decisions
1. IRRF do 13º: `calculateIrrf(13º - inss13º, data, dependents)` com a tabela mensal. Descartado: manter a tabela anual (contraria Lei 7.713 art. 26 e o oráculo).
2. Redutor sobre o bruto: `calculateIrrf` ganha o rendimento bruto como parâmetro nomeado (ex.: `grossIncome`), usado só em `_calculateReducerAmount`; o imposto bruto segue sobre a base deduzida. Dependente é deduzido também no 13º (já assumido no caso golden: base 7.822,32).
3. YAGNI: remover o caminho anual, seus testes e as chaves `anual` / `irrf_2026_anual` do JSON se `grep` confirmar que nada mais as usa (o hook valida o JSON).
4. `IrrfReducerConfig` e `_getMonthlyReducerConfig` permanecem.

## Risks
- Rendimento bruto entre 5.000,01 e 7.350 passa a ter redução diferente da atual; testes unitários existentes podem mudar. Recalcular o esperado à mão pela lei (nunca pela saída do app) e citar a fonte.
- "Bruto" = rendimento tributável antes de INSS e dependentes (leitura do exemplo da Receita), sem validação de contador.
- Um 13º de rescisão alto passa a ser tributado de fato: mudança visível ao usuário; sem impacto de schema ou histórico.

## Open Questions
Nenhuma que bloqueie. Nenhum item ⚖️ novo sem fonte; a projeção do aviso no acordo segue em `noticeProjectionMutualAgreement`.
