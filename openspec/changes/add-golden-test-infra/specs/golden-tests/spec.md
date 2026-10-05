## ADDED Requirements

### Requirement: Golden case schema
Cada caso golden MUST ser um arquivo `test/golden/cases/*.json` contendo `id`, `fonte` (`tipo` em `trct|calculadora|exemplo_contador`, `descricao`, `referencia`), `tipo` de rescisão, `entrada` e `esperado` com valores por `code` de verba (nomes do enum de B2-01) e `totais`. O caso MAY ter o campo opcional `cobre`, lista de strings usada pelo gate de cobertura; valores válidos: `C1` a `C5`, `art479`, `art480`, `doubleVacation`, `noticeProjectionMutualAgreement`. O loader MUST rejeitar com erro que cite o arquivo qualquer caso sem `fonte.tipo` ou `fonte.descricao`, com `tipo` desconhecido, com `code` fora da lista ou com valor não numérico.

#### Scenario: Valid case is loaded
- **WHEN** o loader recebe um JSON completo e válido
- **THEN** devolve o caso tipado com datas, entrada e esperado por code

#### Scenario: Case with cobre satisfies the gate
- **WHEN** um caso traz `cobre: ['C4']`
- **THEN** o gate MUST considerar satisfeita a verba corrigida C4

#### Scenario: Case without source is rejected
- **WHEN** o loader recebe um JSON sem `fonte` ou com `fonte.descricao` vazia
- **THEN** MUST lançar erro citando o arquivo e nenhum teste golden MUST ser gerado para ele

#### Scenario: Unknown verba code is rejected
- **WHEN** `esperado.verbas` contém um code fora da lista de B2-01
- **THEN** o loader MUST falhar com o code inválido na mensagem

### Requirement: Single golden runner
Um único `test/golden/golden_test.dart` MUST carregar todos os casos de `test/golden/cases/` e comparar cada verba e cada total suportado, usando a constante única `goldenTolerance`, igual a 0,01 antes de B2-13 e 0,00 depois. Verba produzida pelo app e ausente do esperado MUST falhar o caso se o valor for diferente de zero. Item do resultado sem mapeamento de code MUST falhar o teste com a descrição do item. Campo de entrada ou total ainda não suportado pelo app MUST ser pulado com motivo explícito, nunca em silêncio.

#### Scenario: Value within tolerance passes
- **WHEN** o comparador recebe 100,00 e 100,01 com tolerância 0,01
- **THEN** considera igual, e com 100,02 MUST considerar diferente

#### Scenario: Extra verba fails
- **WHEN** o app produz uma verba de valor 50,00 que o esperado não lista
- **THEN** o caso MUST falhar apontando o code da verba

#### Scenario: Unsupported input is skipped visibly
- **WHEN** um caso traz `periodosFeriasGozados` e o app ainda não suporta o campo
- **THEN** o caso MUST ser pulado com o motivo impresso, e não contado como aprovado

#### Scenario: Empty cases directory
- **WHEN** `test/golden/cases/` não tem nenhum caso
- **THEN** `flutter test test/golden` MUST passar e imprimir que não há casos

### Requirement: Oracle never comes from the app
O valor esperado MUST vir de documento externo citado em `fonte`; MUST NOT existir código que gere ou atualize `esperado` a partir do resultado do app. Casos sem fonte MUST NOT entrar em `test/golden/cases/`. Fixtures técnicas usadas nos autotestes MUST ser inline, com `id` prefixado `fixture_` e `oraculo: false`, e o loader MUST rejeitar qualquer arquivo assim em `cases/`.

#### Scenario: Fixture in cases directory is rejected
- **WHEN** um arquivo em `cases/` tem `oraculo: false` ou `id` iniciando em `fixture_`
- **THEN** o loader MUST falhar

#### Scenario: No generator of expected values
- **WHEN** se inspeciona `test/golden` por código que escreve em `test/golden/cases/`
- **THEN** nenhum código MUST gravar nesse diretório

### Requirement: Provisional verba mapping isolated
Antes de B2-01, o runner MUST identificar verbas por uma única função `codeOf` em `test/golden/support/provisional_code_map.dart`, baseada na `description` atual, e nenhum outro arquivo MUST depender do texto de `description`. A change MUST NOT adicionar `BreakdownCode` a `lib/`.

#### Scenario: Mapping covers current verbas
- **WHEN** o use case calcula um caso que gera todas as verbas atuais
- **THEN** `codeOf` MUST devolver um code válido para cada item

#### Scenario: Unmapped description fails loudly
- **WHEN** `codeOf` recebe uma descrição desconhecida
- **THEN** MUST lançar erro com a descrição

### Requirement: Validation-pending rules registry
O projeto MUST manter `test/golden/validation_status.dart` listando as regras ⚖️ sem caso golden com fonte (art. 479, art. 480, férias em dobro, projeção do aviso no acordo mútuo). Regra listada que chegue ao usuário MUST exibir a premissa "cálculo em validação" (`Assumption` de B2-10) até existir caso golden com fonte, e o gate de cobertura MUST acusar regra listada sem caso.

#### Scenario: Pending rule without case is reported
- **WHEN** o gate roda e `art479` consta na lista sem caso golden
- **THEN** o gate MUST falhar nomeando a regra

### Requirement: Minimum coverage gate
`test/golden/coverage_test.dart`, com tag `release-gate` marcada com `skip` em `dart_test.yaml` (`exclude_tags` venceria `--tags` e resultaria em "No tests ran"), MUST exigir um caso por tipo de rescisão ativo e um por verba corrigida C1–C5 (campo `cobre`) antes de publicar B2, e um caso `fonte.tipo = exemplo_contador` com a regra em `cobre` para cada regra de `validation_status.dart` antes de B3/B4.

#### Scenario: Default run ignores the gate
- **WHEN** se executa `flutter test`
- **THEN** a suíte padrão MUST pular o gate (skip da tag `release-gate`)

#### Scenario: Gate fails when matrix is incomplete
- **WHEN** se executa `flutter test --tags release-gate --run-skipped` e falta caso para C4
- **THEN** a execução MUST falhar listando a verba faltante
