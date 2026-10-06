## 1. Testes primeiro (B2-08, B6-03)
- [x] 1.1 Teste unitário de `calculateTerminationTaxes` com valores calculados à mão pela lei (design.md): saldo 2.000 + 13º 2.500 → 155,69 + 200,69 = 356,38, IRRF 0,00; deve falhar antes da correção (B2-08)
- [x] 1.2 Teste unitário: ambos no teto, cada INSS com 2 casas; e base do IRRF usando o INSS arredondado (B2-08)
- [x] 1.3 Teste do use case: item `BreakdownCode.inss` = 356,38 no cenário saldo 2.000 / 13º 2.500 (B2-08)

## 2. Implementação (B2-08)
- [x] 2.1 Arredondar `inssSalary` e `inssThirteenth` half-up a 2 casas em `calculateTerminationTaxes` (`lib/core/services/tax_tables_service.dart`), antes de somar e de calcular o IRRF (B2-08)
- [x] 2.2 Remover o arredondamento redundante da soma em `lib/domain/usecases/calculate_termination.dart` (item INSS), se ficar sem efeito (B2-08)

## 3. Casos golden (B6-03)
- [x] 3.1 Revisar os casos de B4 em `test/golden/cases/` (ver `git log` e `docs/golden-dossie/README.md`) e rodar `flutter test test/golden`; divergência além de 0,01 é achado, nunca se ajusta o esperado ao app (B6-03)
- [x] 3.2 Se possível, restaurar/adicionar caso `calculo_legal` com saldo 2.000 e 13º 2.500 (INSS 356,38), esperado calculado à mão e `fonte` preenchida (B6-03)

## 4. Documentação (B2-08, B6-03)
- [x] 4.1 Atualizar `docs/PROJECT.md` §6.7: INSS arredondado por parcela antes de somar; base do IRRF usa o INSS arredondado (B2-08)
- [x] 4.2 Atualizar `docs/golden-dossie/README.md`: linha "Arredondamento", nota dos casos de B4 e remoção da ressalva de divergência (B6-03)

## 5. Verificação
- [x] 5.1 `flutter analyze` e `flutter test` verdes; reportar o que não foi verificado (B2-08)
