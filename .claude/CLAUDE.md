# CLAUDE.md

Calculadora de Rescisão CLT — app Flutter **mobile** (Android/iOS), offline-first, sem backend.
Este arquivo é um **índice**: aponta onde está cada informação. Não duplique conteúdo aqui.

## Onde procurar

| Preciso de… | Ler |
|---|---|
| Stack, camadas, fluxo de dados, convenções, dívidas técnicas | `docs/ARCHITECTURE.md` |
| Por que o app existe, regras de negócio, escopo, modelo de negócio, decisões de produto (Q1–Q28), plano de execução | `docs/PROJECT.md` |
| Fatiamento técnico do PRD em blocos (IDs `B<n>-<nn>`) | `docs/SPECS.md` |
| Quanto do SPECS já foi entregue pelo pipeline (**gerado**, não edite) | `docs/PROGRESS.md` (`python scripts/specs_progress.py`) |
| Tom, personalidade e princípios de experiência | `PRODUCT.md` |
| Tokens e componentes visuais | `DESIGN.md` |
| Specs de compliance (target SDK, Play Billing) | `openspec/specs/` |
| Mudanças em andamento | `openspec/changes/` |

## Como usar os docs

- Leia só a seção necessária, não o arquivo inteiro.
- `docs/` tem duas marcas: ✅ atual (código de hoje) e 🎯 decidido, ainda **não implementado**. Não trate 🎯 como existente.
- Mudou camada, dependência, fluxo ou regra de negócio? Atualize o doc correspondente **no mesmo commit**.

## Regras

- **Hooks ativos** (`.claude/settings.json`, scripts em `.claude/hooks/`): `.dart` editado é formatado e analisado (erros/warnings voltam); `assets/config/tax_tables.json` é validado a cada edição; segredos (`key.properties`, keystore, `.env`, configs de serviço) estão bloqueados. Se um hook negar algo, não contorne: peça ao usuário.
