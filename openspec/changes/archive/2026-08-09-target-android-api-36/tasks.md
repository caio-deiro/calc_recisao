## 1. Configuração Android

- [x] 1.1 Em `android/app/build.gradle.kts`, definir `compileSdk = 36` e `targetSdk = 36` (pin explícito)
- [x] 1.2 Confirmar que `minSdk` permanece `24` (sem alteração)
- [x] 1.3 Garantir que o Android SDK Platform 36 está instalado no ambiente de build

## 2. Build e verificação de compliance

- [x] 2.1 Compilar release (`flutter build appbundle` ou `apk`) e corrigir falhas de compile/plugin sem baixar o target
- [x] 2.2 Inspecionar o artefato (merged manifest / `aapt dump badging`) e confirmar `targetSdkVersion` ≥ 36

## 3. Documentação

- [x] 3.1 Atualizar `doc/GOOGLE_PLAY_SETUP.md` com o requisito de target API 36+ e o pin no Gradle

## 4. Validação

- [x] 4.1 Smoke test: cold start do app sem crash após o bump
- [x] 4.2 Smoke test: fluxo principal de cálculo de rescisão ainda apresenta resultado
- [x] 4.3 (Manual) Publicar AAB na Play Console e confirmar que o aviso de API 36 some no Policy status
