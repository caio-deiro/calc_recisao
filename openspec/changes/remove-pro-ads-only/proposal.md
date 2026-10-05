## Why

O app passa a ser 100 % gratuito (projeto de portfólio, sem meta de receita; decisões Q15–Q19, Q21 em `docs/PROJECT.md §16`). Não há assinantes (Q15), então remover o PRO não exige reembolso nem aviso. A monetização passa a ser só AdMob, reposicionada para não cobrir o resultado (dívida D9), com consentimento único e analytics mínimo opt-in. Bloco B1 de `docs/SPECS.md` (pré-requisitos transversais B0-03 e B0-06).

## What Changes

- Remover PRO, compras in-app, cache offline PRO e `ProScreen` (B1-01…04), com limpeza idempotente de chaves legadas do `SharedPreferences` (B1-05).
- PDF liberado para todos (B1-08); histórico de 100 itens com FIFO e aviso discreto a partir de 90 (B1-09).
- Banner adaptativo em Home, Resultado, Histórico, Suporte e Sobre; intersticial só ao sair do Resultado, 1 por sessão e 1 a cada 3 min; sem recompensado (B1-10a…d).
- Consentimento único (UMP + escolha de analytics) após o primeiro resultado (B1-11); anúncios não personalizados até o aceite (B1-14).
- Firebase inicializado com coleta desligada por padrão (B0-06); Analytics reativado, opt-in, 4 eventos, ponto central de emissão; Crashlytics sob a mesma decisão (B1-12, B1-13). Aposenta `pro_conversion`.
- Arquivar a exigência `play-billing` (B1-06) e ajustar testes (B1-07).
- **BREAKING** (interno): remoção de `purchase_service`, `offline_service`, `pro_utils`, `pro_screen`, constantes PRO e dependências `in_app_purchase*`.

## Capabilities

### New Capabilities
- `free-app`: ausência de PRO/compras, limpeza de legado, PDF livre, histórico de 100.
- `ads-monetization`: posicionamento, frequência e personalização dos anúncios.
- `consent-analytics`: consentimento único, analytics/crashlytics opt-in, eventos permitidos.

### Modified Capabilities
- `play-billing`: todos os requisitos REMOVED (não há mais faturamento). `android-target-sdk` permanece.

## Impact

- Código: `lib/main.dart`, `lib/core/{ads,analytics,services,utils,constants}`, `lib/data/repositories/history_repository.dart`, telas `home/history/result/support/about/pro`.
- `pubspec.yaml` (remove `in_app_purchase*`, reativa `firebase_analytics`), `AndroidManifest.xml`, config Firebase, testes e `docs/ARCHITECTURE.md`/`PROJECT.md` (B0-05). Bump de versão no merge (B0-08).
- Sem alteração de regra de cálculo nem do JSON do histórico. Nenhum item ⚖️.

## Fora de escopo

- Qualquer mudança de cálculo (B2+), recompensado, anúncios em Splash/Formulário, eventos além dos 4 listados.
- Banner no Onboarding: não incluído (B1-10a lista as telas); ver Open Questions em `design.md`.
