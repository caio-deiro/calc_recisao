## Why

O app já está na Play Store (`com.caiodeiro.calcclt`, versão `1.3.0+16`), mas todo release é manual: bump da versão no `pubspec.yaml`, build local do AAB e upload à mão. O repositório não tem `.github/`, então também não existe CI. Isso é lento e sujeito a erro (versionCode repetido, build sem `analyze`/`test`, chave de upload manuseada localmente). O item **B7-08** do `docs/SPECS.md` pede um release Android automatizado por tag.

## What Changes

- Novo workflow `.github/workflows/release-android.yml`, disparado por tag `v*`: valida que a tag é igual à versão do `pubspec.yaml`, roda `flutter analyze` e `flutter test`, gera `appbundle --release` assinado com a chave de upload vinda de secrets e envia o AAB à trilha **internal** da Play.
- `versionCode`/`versionName` continuam vindo do `pubspec.yaml` (nenhum `--build-number`).
- Novo `android/key.properties.example` (apenas placeholders) documentando o formato esperado pelo Gradle.
- Documentação do fluxo de release (SPECS, ARCHITECTURE, PROJECT, `loop.md`) no mesmo commit da implementação.
- Passos manuais do usuário: service account da Play, secrets do GitHub, tag de teste.

## Capabilities

### New Capabilities

- `android-release-pipeline`: pipeline de release Android disparado por tag, com portões de qualidade (`analyze`/`test`), assinatura por secrets e upload somente à trilha `internal`.

### Modified Capabilities

- (nenhuma; `android-target-sdk` e as demais specs de compliance não mudam)

## Impact

- Novos arquivos: `.github/workflows/release-android.yml`, `android/key.properties.example`.
- Docs: `docs/SPECS.md` (B7-08 já presente; só conferir), `docs/ARCHITECTURE.md` (§9 e ADR), `docs/PROJECT.md` (§13), `docs/PROGRESS.md` (gerado), `.claude/skills/orchestrate/references/loop.md` (item 9).
- Nada em `lib/`, `test/` ou `pubspec.yaml`. `android/gradle.properties` não é alterado; o workflow lida com o pin local de JDK (ver design).
- Supera, só para a trilha `internal`, o Non-Goal "publicação automática" da change arquivada `target-android-api-36`. Publicar continua ato humano (criar a tag), coerente com `loop.md` item 9.

## Fora de escopo

CI em pull request, iOS, fastlane, promoção automática internal para produção, notas de release automáticas, cache além do que `subosito/flutter-action` já oferece, alteração de `android/gradle.properties`.
