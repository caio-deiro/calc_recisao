## 1. Dependências

- [x] 1.1 Atualizar `pubspec.yaml`: `in_app_purchase` para `^3.3.0` e `in_app_purchase_android` para `^0.5.2`
- [x] 1.2 Rodar `flutter pub get` (via FVM) e confirmar no `pubspec.lock` que `in_app_purchase_android` resolve ≥ `0.5.0`
- [x] 1.3 Garantir que não existe override manual de `com.android.billingclient:billing` no Gradle do app

## 2. Compatibilidade e código

- [x] 2.1 Revisar `PurchaseService` (e callers PRO) quanto a APIs removidas/alteradas no bump 0.4→0.5; ajustar só se necessário
- [x] 2.2 Compilar o app Android (`flutter build apk` ou `appbundle`) e corrigir eventuais quebras de AGP/Kotlin sem forçar Billing no Gradle

## 3. Verificação de compliance

- [x] 3.1 Inspecionar a árvore de dependências Android / metadados do plugin e confirmar Billing Client ≥ 8.0.0
- [x] 3.2 Atualizar `doc/GOOGLE_PLAY_SETUP.md` (ou nota equivalente) com o requisito de Billing ≥ 8.0.0 e o caminho via plugin

## 4. Validação do fluxo PRO

- [x] 4.1 Smoke test: disponibilidade da loja + carregamento do produto PRO
- [x] 4.2 Smoke test: iniciar compra PRO (licença de teste) e confirmar ativação PRO local após sucesso
- [x] 4.3 Smoke test: restaurar compras com e sem compra ativa; confirmar que não ativa PRO indevidamente
