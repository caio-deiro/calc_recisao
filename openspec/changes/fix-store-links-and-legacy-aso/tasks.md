## 1. Constantes, e-mail e política (B7-01, B7-05)
- [x] 1.1 Teste `test/unit/app_identity_test.dart`: `supportEmail == 'caioguimaraes12@outlook.com'` e `privacyPolicyUrl == 'https://caio-deiro.github.io/calc_recisao'` (literais à mão) (B7-01, B7-05)
- [x] 1.2 Ajustar `AppConstants`: `supportEmail`, `privacyPolicyUrl`; remover `termsOfServiceUrl` (B7-01, B7-05)
- [x] 1.3 `SupportScreen`: exibir `AppConstants.supportEmail` no lugar do literal; remover o card "Perguntas Frequentes" (B7-05)
- [x] 1.4 `SupportService`: remover `openFaq` (B7-05)
- [x] 1.5 Teste de widget da `SupportScreen`: mostra o e-mail e não mostra "Perguntas Frequentes" (B7-05)
- [x] 1.6 Teste: nenhum `.dart` de `lib/` nem de `test/` (exceto o próprio teste) contém `calcrescisao.com` (B7-01, B7-05)

## 2. Código morto de ASO (B1-13)
- [x] 2.1 Remover `lib/core/ab_testing/aso_ab_testing.dart` e `lib/core/deep_links/aso_deep_links.dart` (e pastas vazias); grep sem imports restantes
- [x] 2.2 Remover `lib/core/analytics/aso_analytics.dart`, `AsoAnalytics.initialize()` em `main.dart` e chamada/import em `home_screen.dart` (B1-13)
- [x] 2.3 Adicionar `install_source`, `first_open`, `session_count` a `LegacyCleanup.legacyKeys` e teste em `legacy_cleanup_test.dart` (B1-13)
- [x] 2.4 Teste: Home com SharedPreferences vazio não grava as três chaves (B1-13)
- [x] 2.5 Reportar se `url_launcher` deixou de ser usado (esperado: segue usado em `support_service.dart`; não remover o pacote)

## 3. Android e pubspec (B7-05)
- [x] 3.1 `AndroidManifest.xml`: remover meta-data `app_category`, `app_keywords`, `app_description`; `android:label="@string/app_name"`
- [x] 3.2 `strings.xml`: `app_name` = "Calculadora de Rescisão CLT"; remover `app_description`
- [x] 3.3 `pubspec.yaml`: `description` sem "Trabalhista 2025" (ex.: "Calculadora de Rescisão CLT: FGTS, INSS e IRRF")
- [x] 3.4 Teste lendo manifest, strings e pubspec conforme o spec `app-identity-links`

## 4. Docs e verificação
- [x] 4.1 `docs/ARCHITECTURE.md`: remover `ab_testing/`, `deep_links/` e `aso_analytics` da árvore (~76-80), a linha `install_source` da tabela de chaves (~209, citando a limpeza legada) e a nota de `AsoAnalytics`/`AsoAbTesting` (~244)
- [x] 4.2 `docs/SPECS.md` B7-05: registrar o e-mail unificado em `AppConstants.supportEmail` e `README.md` (B7-05)
- [x] 4.3 `flutter analyze` e `flutter test` verdes
