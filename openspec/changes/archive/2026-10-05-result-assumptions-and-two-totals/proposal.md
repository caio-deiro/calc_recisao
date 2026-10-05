## Why

O modelo de domínio já entrega `paidAtTermination`, `fgtsDeposit` e `assumptions` (B2-09/10), mas nenhuma tela os exibe: o Resultado, o histórico, o PDF e o compartilhamento ainda mostram "Total a Receber" e "Valor Líquido" com a semântica antiga (a multa do FGTS misturada, D10) e **sem premissas**. A change arquivada `fix-calculation-rules` declarou B5 como **pré-requisito de qualquer publicação**: sem premissas visíveis, acordo mútuo, C1–C5 e a marca "cálculo em validação" (B6-04) saem sem aviso ao usuário. Além disso, `_viewCalculation` recalcula o Resultado de um registro do histórico só com `input` e `type`, o que mostra ao usuário um valor diferente do card e do que foi salvo (limite conhecido do D5). Bloco B5 de `docs/SPECS.md`; decisões Q1, Q3, Q11 (`docs/PROJECT.md §16`), PRD §6.5, §6.8 e §7.

## What Changes

- `ResultScreen` mostra dois totais, **"Pago na rescisão"** e **"Depositado no FGTS"**, com linha informativa de saque (100 % sem justa causa; 80 % acordo mútuo), seção recolhível "Premissas desta estimativa" (fechada por padrão), marcador "estimado" e aviso "cálculo em validação" visível sem expandir (B5-01, B5-02, B6-04).
- `ShareUtils` (completo e resumido) e `PdfUtils` espelham a mesma estrutura, sem marca PRO e sem promessa de precisão (B5-03, B5-05, Q3).
- O aviso legal permanece em Home, Formulário, Resultado e Histórico, com texto alinhado ao PRD §6.8 (B5-04).
- O histórico abre o registro com a **mesma `ResultScreen`** mostrando o resultado **salvo** (sem recalcular, sem novo registro no histórico, sem novo evento); registro legado exibe o valor salvo + "Calculado em versão anterior" (B5-06, B2-11).
- Migra os consumidores de `netAmount`/`totalToReceive` e **remove o alias deprecado** de `TerminationResult` (B2-09).
- `TerminationRules` ganha o percentual de saque do FGTS (fonte única da linha informativa) (B5-01).
- Fluxos Maestro para Resultado com premissas, aviso de validação, Histórico, marca de legado e aviso de registro ilegível, por `Semantics.identifier` (B5-01, B5-02, B5-06, B2-11).

## Capabilities

### New Capabilities
- `result-presentation`: Resultado, premissas, compartilhamento, PDF, aviso legal e reabertura do histórico.

### Modified Capabilities
- `calculation-core`: remoção do alias `netAmount`/`totalToReceive`, `legacyNetAmount` no histórico e percentual de saque em `TerminationRules`.

## Impact

- Código: `lib/presentation/screens/{result,history}/`, `lib/presentation/widgets/disclaimer_widget.dart`, `lib/core/utils/{share_utils,pdf_utils}.dart`, `lib/domain/{rules/termination_rules,entities/termination_result,entities/calculation_history}.dart`, `lib/l10n/`.
- Testes: ~60 usos de `netAmount`/`totalToReceive` em `test/` migram para os dois totais; novos testes de widget, texto de compartilhamento/PDF e fluxos em `.maestro/tests/`.
- Docs: `docs/PROJECT.md §6.5` (🎯 UI vira ✅), `docs/ARCHITECTURE.md`; a linha "Change:" de B5 em `docs/SPECS.md` é ajustada pelo orquestrador.
- `pubspec.yaml`: bump de versão no merge (B0-08).

## Fora de escopo

- Tabela de períodos de férias e marca "dobro" nas premissas (B3-07), campos e tipos a prazo/indireta (B4), `Decimal` (B2-13..15).
- Migração completa de strings para l10n (D5 fica parcial; só as strings novas desta change).
- Resolver o release-gate golden (B6-05/B6-06, pendência do responsável) e a validação ⚖️ das regras: esta change só **mostra** premissas e marca; não valida regra.
