---
name: calc-rules
description: Regras e procedimento para qualquer trabalho no cálculo de rescisão: verbas por tipo de rescisão, INSS/IRRF, FGTS, férias, art. 479/480, tabelas fiscais, totais e premissas, casos golden e a marca de validação ⚖️. Use sempre que a tarefa tocar lib/domain, tax_tables_service, assets/config/tax_tables.json, o resultado/PDF/compartilhamento, ou testes de cálculo; ao planejar, implementar ou revisar mudança de regra trabalhista ou tributária; e quando o usuário perguntar "como o app calcula X" ou "essa regra está certa?".
---

# Regras de cálculo

A fonte de verdade das regras é **`docs/PROJECT.md §6`** e dos requisitos técnicos **`docs/SPECS.md` (B2–B4, B6)**. Esta skill não as repete (duplicar faz o texto envelhecer); ela diz **como trabalhar** com elas. Leia a subseção do §6 que a tarefa toca, não o documento inteiro.

## Por que tanto cuidado
Um erro aqui vira milhares de reais a mais ou a menos no número que a pessoa vai usar numa negociação. O princípio do produto é *nunca parecer mais preciso do que a lei e os dados permitem*. Teste que apenas repete o que o código já faz não protege ninguém.

## Hierarquia em caso de conflito
**PRD > SPECS > código.** Se o código diverge de uma decisão 🎯 do PRD, o código está atrasado. Se o PRD e a lei parecerem divergir, **não decida**: registre como questão ⚖️ para o usuário.

## Antes de mexer em uma regra
1. Leia a subseção do §6 e as correções C1–C6 que se aplicam; veja se a mudança já está decidida (🎯) ou ainda é questão aberta.
2. Escreva primeiro o **caso golden** (abaixo). Sem oráculo externo, a mudança vira opinião.
3. Só então altere o código.

## Casos golden
Local: `test/golden/cases/*.json`; um runner único (`test/golden/golden_test.dart`) lê todos (SPECS B6-01/02).
Cada caso tem: `fonte` (TRCT anonimizado, calculadora oficial ou exemplo manual confirmado por contador), `tipo`, `entrada` (admissão, rescisão, salário, média, dependentes, FGTS, períodos de férias, fim previsto, cláusula) e `esperado` (valor por código de verba e totais).

Regras que não se quebram:
- O valor esperado vem **do documento externo**, nunca da saída do app. Não "ajuste o esperado para o teste passar".
- Caso sem `fonte` não entra.
- Diferença de centavos entre o app e o documento é **achado**, não ruído: investigue antes de mexer na tolerância.

## Regra sem caso golden (⚖️)
Se a regra está marcada ⚖️ e ainda não há fonte (ex.: art. 479/480, férias em dobro), ela pode ser implementada, mas deve sair com a premissa **"cálculo em validação"** visível no resultado (SPECS B6-04) e o fato deve ser reportado ao usuário. Nunca apresente como certa uma regra sem validação.

## Convenções de implementação
- **Datas:** a tabela de INSS/IRRF é escolhida pela **data da rescisão**, não pela data de hoje. Testes usam datas fixas, nunca `DateTime.now()`.
- **Tabelas fiscais** ficam em `assets/config/tax_tables.json`; nada de alíquota ou faixa hardcoded no Dart. O hook valida o JSON a cada edição.
- **Identidade da verba:** use o código (`BreakdownCode`), nunca o texto de `description` como chave (dívida D8; no código atual ainda existe, não replique).
- **Arredondamento:** meia-unidade para cima, **2 casas por item**, nos mesmos pontos de hoje. Dinheiro em `Decimal` só depois de existirem os testes golden (B2-13).
- **Resultado:** dois totais, "Pago na rescisão" e "Depositado no FGTS", mais premissas (`informado` × `estimado`). A mesma estrutura em tela, PDF e compartilhamento.
- **Privacidade:** nenhum valor, salário ou data em log, evento ou crash.

## Ao terminar
- Rode `flutter analyze` e `flutter test` (ou o arquivo de teste tocado).
- Atualize `docs/PROJECT.md §6` e/ou `docs/SPECS.md` **no mesmo commit** se a regra mudou, citando a base legal (artigo, súmula ou portaria).
- Reporte ao orquestrador: regras alteradas, casos golden adicionados, itens ⚖️ sem fonte.

## Virada de ano
Tabelas novas seguem o checklist de `docs/PROJECT.md §13`: JSON, teste do ano (`termination_<ano>_test.dart`), portaria citada no commit, listagem da loja.
