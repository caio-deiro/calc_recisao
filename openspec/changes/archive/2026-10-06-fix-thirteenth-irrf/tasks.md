## 1. Caso golden primeiro (B2-08, B6-03)
- [x] 1.1 Mover `docs/golden-dossie/rascunho/golden_sem_justa_causa_c2_c5.json` para `test/golden/cases/` (B2-08): `fonte.tipo = "calculo_legal"`, remover a chave `validacao`, `fonte.descricao` idêntica à de `golden_pedido_demissao.json`, `referencia` com a âncora `#golden_sem_justa_causa_c2_c5`; valores esperados intactos (IRRF 1.242,41; paidAtTermination 51.947,14)
- [x] 1.2 Rodar `flutter test test/golden` e ver o caso falhar só em `irrf` e nos totais (prova do bug) antes de mexer no código

## 2. Código (B2-08 C5, B2-07 C4)
- [x] 2.1 Em `calculateTerminationTaxes`, apurar o IRRF do 13º com `calculateIrrf` (tabela mensal) em vez de `calculateIrrfAnnual` (B2-08)
- [x] 2.2 Passar o rendimento bruto (saldo; 13º) ao redutor mensal em vez da base deduzida; o imposto bruto continua sobre a base deduzida (B2-07, B2-08)
- [x] 2.3 Remover `calculateIrrfAnnual`, `_applyAnnualReducer`, `_getAnnualReducerConfig`, `getIrrfAnnualTable` e, se sem uso, `irrf_2026_anual` e `irrf_redutor_2026.anual` no JSON; atualizar o docstring de `calculateTerminationTaxes` (B2-08)

## 3. Testes (B2-07, B2-08)
- [x] 3.1 Unitário: 13º 9.000, 1 dependente, 2026-09-05 resulta em IRRF 1.242,41 e `inssThirteenth` 988,09 (B2-08)
- [x] 3.2 Unitário do redutor sobre o bruto: bruto 7.500 com base deduzida abaixo de 7.350 sem redução; bruto 6.000 com redução 179,752; bruto até 5.000 com imposto zero (B2-07, B2-08)
- [x] 3.3 Ajustar ou remover os testes de `test/unit/tax_tables_service_test.dart` (~linhas 127 e 178) que usam `calculateIrrfAnnual`; recalcular esperados à mão pela lei, citando a fonte (B2-08)
- [x] 3.4 `flutter test test/golden` verde com o caso promovido; depois `flutter analyze` e `flutter test` completos (B2-08)
- [x] 3.5 Confirmar que `golden_acordo_mutuo` permanece em `rascunho/` e `noticeProjectionMutualAgreement` em `pendingValidationRules` (B2-08)

## 4. Docs (mesmo commit)
- [x] 4.1 Atualizar `docs/PROJECT.md §6` (IRRF do 13º mensal; redutor sobre bruto, com as bases legais) e `docs/golden-dossie/README.md` (caso promovido, divergência resolvida) (B2-08)
