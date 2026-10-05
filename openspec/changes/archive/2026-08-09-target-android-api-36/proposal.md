## Why

A Google Play exige que, a partir de ~30/31 de agosto de 2026, novos apps e atualizações segmentem Android 16 (nível 36 da API) ou superior; uploads com target mais antigo serão recusados. O app publicado ainda está em Android 15 (API 35), então precisa de um build/release com `targetSdk` ≥ 36 antes desse prazo.

## What Changes

- Garantir que o módulo Android do app compile e segmente API 36 (`compileSdk` e `targetSdk` ≥ 36) em builds de release.
- Confirmar que o Flutter via FVM permanece em versão cujo default (`flutter.targetSdkVersion` / `flutter.compileSdkVersion`) seja ≥ 36, ou pin explícito no Gradle se for a forma mais segura de compliance.
- Gerar AAB/APK e verificar no artefato (merged manifest / `aapt`) que `targetSdkVersion` = 36.
- Revisar impactos comportamentais do Android 16 relevantes ao app (ex.: edge-to-edge, restrições de orientação em telas grandes) e ajustar só o que for necessário.
- Documentar o requisito de target API na doc de setup Google Play, se aplicável.
- Publicar nova versão na Play Console antes do prazo de compliance.

## Capabilities

### New Capabilities

- `android-target-sdk`: Compliance do app Android com o nível desejado da API exigido pela Google Play (API 36+) e verificação do `targetSdk` no artefato de release.

### Modified Capabilities

- (nenhuma — ainda não há specs principais em `openspec/specs/`)

## Impact

- Build Android: `android/app/build.gradle.kts` (`compileSdk` / `targetSdk`); possível nota em `android/settings.gradle.kts` / toolchain se o SDK Platform 36 não estiver instalado.
- Toolchain: Flutter FVM (`3.44.9` já defaulta compile/target para 36); Android SDK Platform 36 no ambiente de build.
- Código Dart/UI: impacto esperado baixo; o manifesto atual não trava orientação. Possível revisão de insets/edge-to-edge se algum layout quebrar em API 36.
- Release: necessário publicar um novo AAB na Play Console antes do prazo (~30/31 ago 2026).
- Fora de escopo: alterar `minSdk` (permanece 24), mudanças de produto/UX, iOS, e o upgrade de Play Billing (change separado `upgrade-play-billing-library`).
