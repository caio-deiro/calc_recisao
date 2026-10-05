## Context

`lib/` hoje não tem `BreakdownCode` (B2-01) nem `Assumption` (B2-10): `BreakdownItem` só tem `description`, `value`, `type`. `TerminationInput` cobre admissão, rescisão, salário, média, dependentes, FGTS e `hasAccruedVacation`; não cobre períodos de férias, fim previsto nem cláusula (B3/B4). `TerminationType` atual: `withoutJustCause, resignation, fixedTerm, withJustCause, mutualAgreement`.

## Decisions

### D1. Schema do caso (B6-01)
Um arquivo por caso, `test/golden/cases/<id>.json`:
```
{ "id", "fonte": {"tipo": "trct|calculadora|exemplo_contador", "descricao", "referencia"},
  "tipo": "<TerminationType>",
  "entrada": { admissao, rescisao, salarioBase, mediaVariaveis, dependentes, fgtsInformado?,
               feriasVencidas?, avisoTrabalhado?, diasTrabalhadosNoMes?, outrosDescontos?,
               periodosFeriasGozados?, fimPrevisto?, clausula? },
  "esperado": { "verbas": { "<code>": valor },
                "totais": { totalAdditions?, totalDeductions?, paidAtTermination?, fgtsDeposit? } },
  "cobre"?: ["C1".."C5" | "art479" | "art480" | "doubleVacation" | "noticeProjectionMutualAgreement"] }
```
`cobre` é opcional: lista de strings que declara qual correção ou regra ⚖️ o caso cobre; só o gate (D6) a usa.
Datas ISO `AAAA-MM-DD`, valores numéricos com 2 casas. Os `<code>` são os **nomes finais do enum de B2-01** (`salaryBalance`, `notice`, `noticeDiscount`, `thirteenth`, `accruedVacation`, `proportionalVacation`, `fgtsFine`, `inss`, `irrf`, `otherDiscounts`), como string. Assim os JSONs não mudam quando B2-01 chegar.

### D2. Identificação de verba antes de B2-01 (sem antecipar B2)
O runner resolve cada `BreakdownItem` para um code string por **uma função única** `codeOf(item)` em `test/golden/support/provisional_code_map.dart`, que mapeia a `description` atual (tabela literal; `Multa FGTS (40%)` e `(20%)` para `fgtsFine`; `Aviso Prévio Indenizado (50%)` para `notice`). É dívida temporária, explícita e isolada em `test/`. Item sem mapeamento faz o runner **falhar** com o texto da descrição. Em B2-01 o arquivo é apagado e `codeOf` passa a usar `item.code.name` (tarefa de B2).
Descartado: criar `BreakdownCode` agora (antecipa B2 e toca `lib/`); casar por texto direto nos JSONs (acopla o oráculo a strings de UI).

### D3. Runner (B6-02)
`golden_test.dart` lista `cases/*.json` e gera um `test()` por caso. Compara cada verba esperada; verba produzida e ausente do esperado precisa ser 0, senão falha. Constante única `goldenTolerance` em `test/golden/support/tolerance.dart` = `0.01`; B2-13/B2-15 a mudam para `0.00`. Comparação `(a - b).abs() <= tolerance` sobre valores de 2 casas.
Campos de `entrada` ou chaves de `totais` ainda não suportados pelo app (períodos de férias, fim previsto, cláusula; `paidAtTermination`, `fgtsDeposit`) fazem o caso/chave ser **pulado de forma explícita** (skip com motivo impresso), nunca ignorado em silêncio. Totais verificáveis hoje: `totalAdditions`, `totalDeductions`.
Zero casos em `cases/` não falha o runner: imprime "0 casos golden (infra apenas)".

### D4. Integridade do oráculo (B6-03)
O loader valida o schema e **rejeita** (exceção citando o arquivo) caso sem `fonte.tipo`/`fonte.descricao`, `tipo` desconhecido, code fora da lista da D1 ou valor não numérico. Não existe modo "gravar esperado a partir da saída do app". O reviewer confere `fonte` por caso; o commit que adiciona caso cita o documento de origem. Fixtures de autoteste são **inline** no teste, com `id` prefixado `fixture_` e `"oraculo": false`; o loader rejeita esses marcadores se aparecerem em `cases/`.

### D5. Plano B (B6-04)
Contrato: toda regra ⚖️ sem caso golden que chegue ao usuário MUST ter `Assumption` "cálculo em validação" visível no Resultado, até haver caso com fonte. B6 fornece só o mecanismo de checagem: `test/golden/validation_status.dart` (regras ⚖️ pendentes: `art479`, `art480`, `doubleVacation`, `noticeProjectionMutualAgreement`) e o gate (D6), que acusa regra listada sem caso. A `Assumption` e a UI são de B2-10/B5; a change de B2 deve citar B6-04. Dependência: `Assumption` não existe hoje.

### D6. Cobertura mínima (B6-05)
`test/golden/coverage_test.dart` com `@Tags(['release-gate'])`. `dart_test.yaml` na raiz declara a tag com `skip` (não `exclude_tags`, que vence `--tags` e daria "No tests ran"), então `flutter test` fica verde com 0 casos; roda com `flutter test --tags release-gate --run-skipped` antes de publicar B2. Exige um caso por tipo de rescisão ativo e um por verba corrigida C1–C5 via `cobre` (C1 férias vencidas na justa causa; C2 projeção do aviso; C3 férias proporcionais por período aquisitivo; C4 férias indenizadas sem IRRF; C5 INSS do 13º separado). Antes de B3/B4 exige um caso `fonte.tipo = exemplo_contador` com a regra em `cobre` para cada regra de `validation_status.dart`. A lógica fica em `test/golden/support/coverage_matrix.dart` (`missingCoverage`).

## Risks / Trade-offs
- Mapa provisório por `description` quebra se o texto mudar antes de B2-01: falha alta e clara, não silenciosa.
- Gate pulado (`skip`) no padrão pode ser esquecido: entra no checklist de publicação (task de docs).
- Tolerância 0,01 pode mascarar erro de centavo: diferença de centavo é investigada antes de mexer na constante (calc-rules).
- Hoje o gate falha por construção (0 casos): é o comportamento desejado até B6-06 ser atendido.

## Handoff para B2
Notas para a change de B2 (nenhuma é feita aqui):
- B2-01: remover `test/golden/support/provisional_code_map.dart`; `codeOf` passa a usar `item.code.name`.
- B2-10: exigir `Assumption` "cálculo em validação" para regras de `validation_status.dart`, citando B6-04.
- B2-13: baixar `goldenTolerance` para 0,00.

## Open Questions (dependem do usuário; B6-06)
1. **TRCTs reais anonimizados**, um por tipo ativo e cobrindo C1–C5. Recomendação: começar por 5 TRCTs (um por tipo) que já cubram C4/C5; anonimizar sem alterar valores nem datas relativas.
2. **Contador** para 2 a 3 exemplos de art. 479/480 e férias em dobro (⚖️). Recomendação: fechar a revisão antes de B4; até lá vale o Plano B (D5) e nenhum caso sem fonte.
3. **Calculadora de referência** aceita para casos sem TRCT. Recomendação: calculadora oficial gov.br/MTE, com URL e data de acesso em `fonte.referencia`.
4. Aceitar o gate `release-gate` fora do `flutter test` padrão (D6). Recomendação: aceitar, para não deixar o CI vermelho enquanto B6-06 está pendente.
