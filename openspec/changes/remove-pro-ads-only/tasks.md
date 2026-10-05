## 1. Remover PRO e compras — B1-01…B1-04

- [x] 1.1 Remover `purchase_service.dart`, `offline_service.dart`, `pro_utils.dart`, `pro_screen.dart` e a rota/navegação para o PRO (B1-01)
- [x] 1.2 Remover acessos a `ProUtils`/`PurchaseService`/`OfflineService` em `main.dart`, `ad_manager.dart`, `support_service.dart`, `history_repository.dart` e telas home/history/result/support (card de upgrade, banner de limite, bloqueio de PDF, e-mail PRO) (B1-02)
- [x] 1.3 Remover `in_app_purchase` e `in_app_purchase_android` do `pubspec.yaml`; confirmar que o manifesto mesclado de release não tem `BILLING` (B1-03)
- [x] 1.4 Remover de `AppConstants` as 6 constantes PRO listadas (B1-04)
- [x] 1.5 Verificar `grep -rn "ProUtils\|PurchaseService\|OfflineService\|in_app_purchase" lib pubspec.yaml` vazio (B1-01, B1-02, B1-03)

## 2. Limpeza de dados legados — B1-05

- [x] 2.1 Teste unitário: com as 7 chaves presentes somem; sem chaves não falha; rodar duas vezes é igual; histórico preservado (B1-05)
- [x] 2.2 Implementar limpeza idempotente chamada no bootstrap (B1-05)

## 3. PDF e histórico — B1-08, B1-09

- [x] 3.1 Liberar `PdfUtils`/`ShareUtils.exportToPdf`/`savePdfToFile` sem verificação de status; ajustar `pdf_export_test.dart` (B1-08, B1-07)
- [x] 3.2 Teste: 101 salvos resultam em 100 com o mais antigo descartado (FIFO) (B1-09)
- [x] 3.3 `AppConstants.maxHistorySize = 100` e FIFO em `saveCalculation`; adequar `history_repository_test.dart` (B1-09, B1-07)
- [x] 3.4 Widget test do aviso com 90 itens (visível) e 89 (ausente); implementar aviso discreto no Histórico (B1-09)

## 4. Anúncios — B1-10a…B1-10d, B1-14

- [x] 4.1 Testes do `AdManager.showInterstitialOnExit()`: não carregado, 2ª vez na sessão, menos de 3 min, caso permitido; adequar `ad_manager_test.dart` (B1-10c, B1-07)
- [x] 4.2 Remover `shouldShowAds`; implementar `showInterstitialOnExit()` com flag de sessão e `last_interstitial_time` (B1-10c)
- [x] 4.3 Remover a chamada do intersticial ao entrar em `result_screen.dart` (D9); chamar `showInterstitialOnExit()` ao voltar à Home e ao concluir compartilhar/exportar (B1-10b)
- [x] 4.4 Banner adaptativo ancorado em Home, Resultado, Histórico, Suporte e Sobre; ausente em Formulário e Splash; widget tests de presença/ausência (B1-10a)
- [x] 4.5 Confirmar ausência de anúncio recompensado e de anúncio em Splash/Formulário (grep `RewardedAd`) (B1-10d)
- [x] 4.6 Teste e implementação: `AdRequest(nonPersonalizedAds: true)` sem consentimento, normal após aceite; manter `AD_ID` no manifesto (B1-14)

## 5. Firebase, consentimento e analytics — B0-06, B1-11…B1-13

- [x] 5.1 Obter a config Firebase do usuário (bloqueada para o agente) e inicializar `Firebase.initializeApp` no `main`, com meta-data do manifesto de coleta desligada (B0-06, B1-12)
- [x] 5.2 Reativar `firebase_analytics` no `pubspec.yaml`; `setAnalyticsCollectionEnabled(false)` no boot; Crashlytics sob a mesma decisão (B1-12)
- [x] 5.3 Testes do ponto central em `core/analytics/`: descarta sem consentimento, envia com consentimento, só os 4 eventos e parâmetros permitidos (B1-13, B0-03)
- [x] 5.4 Implementar o ponto central; remover `pro_conversion` de `aso_analytics.dart`; emitir `calc_completed`, `share_used`, `pdf_exported`, `consent_decision` (B1-13)
- [x] 5.5 Widget tests do aviso: ausente antes do 1º resultado, exibido uma vez após, não repetido; persistir `consent_decided`/`analytics_enabled` (B1-11)
- [x] 5.6 Implementar UMP (`ConsentInformation`) + escolha de analytics após o primeiro resultado; aceite liga coleta e anúncios normais (B1-11, B1-12, B1-14)

## 6. Specs, testes e fluxo E2E — B1-06, B1-07

- [x] 6.1 Apagar `test/unit/pro_features_test.dart`; ajustar testes restantes quebrados pela remoção (B1-07)
- [x] 6.2 Registrar o archive da spec `play-billing` (delta REMOVED desta change) e confirmar que `android-target-sdk` permanece; o `openspec archive` fica para depois da aprovação (B1-06)
- [x] 6.3 Fluxo Maestro: cálculo, resultado sem intersticial ao entrar, aviso de consentimento uma vez, PDF sem bloqueio (B1-08, B1-10b, B1-11)

## 7. Docs e fechamento — B0-05, B0-08

- [x] 7.1 Atualizar `docs/ARCHITECTURE.md` e `docs/PROJECT.md` (remoção do PRO, anúncios, consentimento, analytics, D3 e D9 resolvidas) no mesmo commit (B0-05)
- [x] 7.2 `flutter analyze` e `flutter test` verdes; bump de versão no `pubspec.yaml` (B0-01, B0-08)
- [x] 7.3 Verificar o APK de release sem `BILLING` e, no DebugView, nenhum evento sem consentimento (B1-03, B1-12, B1-14)

## 8. Toolchain e privacidade (escopo adicional aprovado pelo usuário)

- [x] 8.1 Subir o wrapper do Gradle para 8.14.3 (`android/gradle/wrapper/gradle-wrapper.properties`), exigido pelo Flutter 3.47.6; e subir AGP 8.7.0 → 8.11.1 e Kotlin 2.2.10 → 2.2.20 em `android/settings.gradle.kts` (mínimos do Flutter 3.47.6); copiar `data_extraction_rules.xml` do branch `chore/android-16kb-compliance` (o lint de release reprovava o arquivo antigo)
- [x] 8.2 Atualizar o texto da política de privacidade em `about_screen.dart` (analytics/crash só com consentimento; AdMob não personalizado até o aceite) e cobrir com teste de widget
