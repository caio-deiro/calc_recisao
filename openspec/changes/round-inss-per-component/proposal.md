## Why
O INSS do saldo de salário e o do 13º são recolhimentos distintos (bases, tabelas e tetos próprios; C5; Decreto 3.048/99 art. 214 §6º e §7º). Decisão do responsável: cada um é arredondado half-up a 2 casas **antes** de somar, `inss = round(inssSaldo) + round(inss13º)`. Hoje `TerminationTaxResult.inss` soma os valores sem arredondar e `CalculateTermination` arredonda a soma, o que diverge em meio centavo (saldo 2.000 + 13º 2.500: oráculo 356,38, app 356,37). Os casos golden de B4 foram montados com entradas que evitam esse ponto; a divergência ficou registrada no dossiê.

## What Changes
- `calculateTerminationTaxes` passa a arredondar `inssSalary` e `inssThirteenth` (half-up, 2 casas) ao apurá-los; `inss` é a soma dos já arredondados.
- A base do IRRF de cada parcela usa o INSS **já arredondado** daquela parcela. Hoje usa o INSS cru (`salaryBalance - inssSalary` sem arredondar); isso muda e fica registrado.
- Teste unitário com valores calculados à mão pela lei, incluindo saldo 2.000 + 13º 2.500 = 356,38.
- Revisão dos casos golden de B4 cujas entradas foram trocadas para evitar a diferença; se possível, restaurar/adicionar um caso que a exercite.
- `docs/PROJECT.md` §6.7 e `docs/golden-dossie/README.md` registram a convenção.

IDs: B2-08 (C5, INSS do 13º separado) e B6-03 (oráculo externo, nunca a saída do app). Fonte dos casos: `calculo_legal`. ⚖️ mantido (sem validação de contador).

## Capabilities
### Modified Capabilities
- `calculation-core`: requisito "C5 independent INSS on thirteenth" (arredondamento por parcela).

## Impact
- `lib/core/services/tax_tables_service.dart` (`calculateTerminationTaxes`), `lib/domain/usecases/calculate_termination.dart` (arredondamento da soma do item INSS), testes de serviço/use case, `test/golden/cases/`, `docs/`.
- Efeito esperado: diferença de no máximo 0,01 no INSS e, via base, no IRRF em casos raros; nenhum golden promovido deve passar da tolerância (verificar).

## Fora de escopo
Novas regras de INSS/IRRF, tabelas, projeção do aviso (caso `acordo_mutuo`), promoção de regras ⚖️ (art. 479/480, férias em dobro).
