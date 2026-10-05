## 1. Schema e loader (B6-01, B6-03)

- [x] 1.1 B6-01 Criar `test/golden/cases/.gitkeep` e `test/golden/support/golden_case.dart` (modelo tipado + loader conforme design D1). Verificar: `flutter analyze` limpo.
- [x] 1.2 B6-03 Teste unitário do loader (`test/golden/loader_test.dart`, fixtures inline `fixture_*` com `oraculo: false`): caso válido, sem fonte, tipo desconhecido, code inválido, valor não numérico.
- [x] 1.3 B6-03 Loader rejeita `oraculo: false` e `id` `fixture_*` em `cases/`; sem qualquer gerador de `esperado`; teste cobrindo a rejeição.

## 2. Runner e tolerância (B6-02)

- [x] 2.1 B6-02 Criar `test/golden/support/tolerance.dart` com `goldenTolerance = 0.01` e comentário citando B2-13 como ponto de troca para 0,00.
- [x] 2.2 B6-02 Criar `test/golden/support/provisional_code_map.dart` (`codeOf`) conforme D2, com comentário "remover em B2-01".
- [x] 2.3 B6-02 Teste de `codeOf`: cada descrição atual do use case mapeia; descrição desconhecida lança erro.
- [x] 2.4 B6-02 Criar o comparador (tolerância, verba extra não zero, totais suportados, skips explícitos) e teste unitário com fixtures inline: 100,00 vs 100,01 passa; 100,02 falha; verba extra falha; entrada não suportada pulada com motivo.
- [x] 2.5 B6-02 Criar `test/golden/golden_test.dart` gerando um teste por caso de `cases/`; com 0 casos passa e imprime aviso. Verificar `flutter test test/golden`.

## 3. Plano B e cobertura (B6-04, B6-05)

- [x] 3.1 B6-04 Criar `test/golden/validation_status.dart` com as regras ⚖️ pendentes (art479, art480, doubleVacation, noticeProjectionMutualAgreement).
- [x] 3.2 B6-05 Criar `dart_test.yaml` na raiz declarando a tag `release-gate` e excluindo-a por padrão.
- [x] 3.3 B6-05 Criar `test/golden/coverage_test.dart` (`@Tags(['release-gate'])`) com a matriz: um caso por tipo ativo, um por C1–C5 e exemplos `exemplo_contador` antes de B3/B4; inclui a checagem das regras de 3.1 (B6-04).
- [x] 3.4 B6-05 Teste do próprio gate com fixtures inline: matriz completa passa, faltando C4 falha listando a verba. Confirmar que `flutter test` padrão não o executa e que `flutter test --tags release-gate` falha hoje (esperado: 0 casos).

## 4. Documentação (B6-04, B6-05, B6-06)

- [x] 4.1 B6-05 Atualizar `docs/ARCHITECTURE.md §8` (pasta `test/golden/`, tag `release-gate`, comando) no mesmo commit.
- [x] 4.2 B6-04 Deixar anotado para B2 (no design da change de B2, não em código): remover `provisional_code_map.dart` em B2-01, exigir `Assumption` "cálculo em validação" em B2-10 e baixar a tolerância para 0,00 em B2-13. Transferida para a change de B2 (nota a registrar lá): remover `provisional_code_map.dart` em B2-01; exigir `Assumption` "cálculo em validação" em B2-10, citando B6-04; baixar `goldenTolerance` para 0,00 em B2-13.
- [x] 4.3 B6-06 Reportar ao usuário a lista de pendências (TRCTs, contador, calculadora de referência) das Open Questions do design; não criar casos sem fonte.

## 5. Verificação final (B6-01…06)

- [x] 5.1 B6-01…06 `flutter analyze` sem novos avisos e `flutter test` verde; `git diff --stat` só em `test/golden/**`, `dart_test.yaml` e docs citadas.
