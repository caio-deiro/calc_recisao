## Why
O teste golden (`docs/golden-dossie/README.md`, caso `golden_sem_justa_causa_c2_c5`) achou um bug de regra: `TaxTablesService.calculateTerminationTaxes` apura o IRRF do 13º com `calculateIrrfAnnual` (tabela e redução ANUAIS). O app devolve IRRF 0,00 onde o cálculo legal dá 1.242,41. O 13º é tributado exclusivamente na fonte, em separado do salário, pela tabela progressiva MENSAL vigente no mês da rescisão (Lei 7.713/88 art. 26). Diverge de B2-08 (C5) e é o oráculo externo que o B6-03 exige.

Também foi confirmado no código que o redutor MENSAL (Lei 15.270/2025) recebe a base já deduzida (`salário - INSS - dependentes`) em vez do rendimento tributável bruto, e a lei e a Receita usam o bruto (exemplo oficial: 978,62 - 0,133145 x 6.000).

## What Changes
- IRRF do 13º passa a usar a tabela mensal e o redutor mensal, no mês da rescisão (B2-08, C5).
- O redutor mensal (saldo e 13º) passa a ser avaliado sobre o rendimento tributável BRUTO (B2-07 e B2-08; C4 delimita o que é rendimento: férias indenizadas fora).
- Remover o caminho anual (`calculateIrrfAnnual`, `_applyAnnualReducer`, `getIrrfAnnualTable`) por ficar sem uso (YAGNI), com seus testes e as chaves `anual` de `tax_tables.json` se nada mais as usar.
- Promover `golden_sem_justa_causa_c2_c5` para `test/golden/cases/` como `calculo_legal`.
- `golden_acordo_mutuo` fica fora (pendência ⚖️ `noticeProjectionMutualAgreement`).

## Capabilities
### Modified Capabilities
- `calculation-core`: requisito "C5 independent INSS on thirteenth" (IRRF do 13º) e novo requisito do redutor sobre rendimento bruto.

## Impact
`lib/core/services/tax_tables_service.dart`, `assets/config/tax_tables.json`, `test/unit/tax_tables_service_test.dart`, `test/golden/cases/`. Docs (`docs/PROJECT.md §6`, `docs/golden-dossie/README.md`) atualizados no mesmo commit. Cálculos com rendimento bruto entre 5.000,01 e 7.350 mudam de valor; INSS não muda.

## Fora de escopo
Projeção do aviso no acordo mútuo; desconto simplificado (607,20); regras art. 479/480 e férias em dobro; migração para Decimal.
