## Why
A auditoria de ASO (`docs/store/AUDITORIA.md` P0 #3, #4, #5 e P2 #13 a #16) achou links, e-mail e nomes errados no app Android: `calcrescisao.com` (domínio que não existe) em `AppConstants`, no `SupportService` e na `SupportScreen`; link de compartilhamento com ID de pacote falso (`com.calcrescisao.app`) em código morto; `install_source` fixo e falso; meta-data de ASO sem efeito no manifesto; nomes divergentes ("Calculadora Rescisão CLT", "Calc CLT") e "Trabalhista 2025" na `description`. Cumpre B7-01 (URL da política) e B7-05 (e-mail único).

## What Changes
Decisões do responsável (não rediscutir): nome canônico **Calculadora de Rescisão CLT**; e-mail único **caioguimaraes12@outlook.com**; política em **https://caio-deiro.github.io/calc_recisao**; `calcrescisao.com` não existe.
- `AppConstants.supportEmail` e `privacyPolicyUrl` passam aos valores acima; `termsOfServiceUrl` removida (nenhum uso em `lib/` ou `test/`).
- `SupportScreen` passa a exibir `AppConstants.supportEmail` (hoje tem `suporte@calcrescisao.com` literal, linha 132).
- Remover o card "Perguntas Frequentes" e `SupportService.openFaq` (apontava para `calcrescisao.com/faq`, inexistente; não há FAQ).
- Remover código morto: `lib/core/ab_testing/aso_ab_testing.dart` e `lib/core/deep_links/aso_deep_links.dart` (grep: nenhum import em `lib/` ou `test/`).
- Remover `lib/core/analytics/aso_analytics.dart` e suas 2 chamadas (`main.dart:20`, `home_screen.dart:29`): só grava `install_source` (falso), `first_open` e `session_count` em SharedPreferences; `getConversionMetrics` nunca é chamado, nenhuma chave é lida e os `track*` têm corpo vazio. YAGNI. As chaves `install_source`, `first_open`, `session_count` entram em `LegacyCleanup.legacyKeys`.
- Manifest: remover meta-data `app_category`, `app_keywords`, `app_description`; `android:label` = "Calculadora de Rescisão CLT" (via `@string/app_name`, com `strings.xml` `app_name` alinhado; hoje "Calc CLT"). `lib/app.dart` já usa o nome canônico (sem mudança). iOS fora de escopo.
- `pubspec.yaml` `description` sem "Trabalhista 2025".
- Delta em `consent-analytics`: o requisito "Minimal event set" deixa de citar `aso_analytics.dart` (arquivo removido).

## Capabilities
- Novas: `app-identity-links` (e-mail, URL da política, nome canônico, ausência do domínio inexistente).
- Modificadas: `consent-analytics` (referência a `aso_analytics.dart`).

## Impact
`lib/core/constants/app_constants.dart`, `lib/core/services/support_service.dart`, `lib/core/services/legacy_cleanup.dart`, `lib/presentation/screens/support/support_screen.dart`, `lib/main.dart`, `lib/presentation/screens/home/home_screen.dart`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/strings.xml`, `pubspec.yaml`, `docs/ARCHITECTURE.md` (linhas ~76-80, 209, 244), `docs/SPECS.md` (B7-05). Testes novos/ajustados em `test/unit/` e `test/widget/`.

## Fora de escopo
iOS; idiomas além de pt-BR; textos da listagem na Play Console; remover o pacote `url_launcher` (segue usado por `support_service.dart`); abrir a política de privacidade dentro do app (nenhum uso hoje de `privacyPolicyUrl`; só a constante é corrigida).
