## Purpose

Garante que o release Android seja disparado por tag, passe por `analyze` e `test`, seja assinado com segredos do GitHub e chegue somente à trilha `internal` da Google Play, sem segredo no repositório.

## ADDED Requirements

### Requirement: Release is triggered only by version tag
O workflow `.github/workflows/release-android.yml` MUST ser disparado exclusivamente por push de tag que case com `v*`, e MUST NOT ser disparado por push em branch nem por pull request.

#### Scenario: Tag triggers the workflow
- **WHEN** a configuração `on:` do workflow é inspecionada
- **THEN** ela MUST conter apenas `push.tags` com o padrão `v*`, sem `branches` nem `pull_request`

### Requirement: Tag must match the pubspec version
O workflow MUST comparar a tag (sem o prefixo `v`) com a versão do `pubspec.yaml` (sem o sufixo `+build`) antes de qualquer build, e MUST falhar sem gerar AAB nem fazer upload quando divergirem.

#### Scenario: Matching tag proceeds
- **WHEN** a tag é `v1.3.0` e o `pubspec.yaml` declara `version: 1.3.0+16`
- **THEN** a validação MUST passar e o job MUST seguir para `analyze`

#### Scenario: Divergent tag aborts
- **WHEN** a tag é `v1.3.1` e o `pubspec.yaml` declara `version: 1.3.0+16`
- **THEN** o job MUST falhar na etapa de validação, antes de `build` e de `upload`

### Requirement: Quality gates precede build and upload
O workflow MUST executar `flutter analyze` e `flutter test` antes de `flutter build appbundle`, e a falha de qualquer um MUST impedir o build e o upload.

#### Scenario: Gate order
- **WHEN** a ordem dos passos do job é inspecionada
- **THEN** `flutter analyze` e `flutter test` MUST aparecer antes de `flutter build appbundle --release`, que MUST aparecer antes do passo de upload

### Requirement: Version comes from pubspec
O build MUST obter `versionCode` e `versionName` do `pubspec.yaml`, sem sobrescrevê-los por `--build-number` ou `--build-name`.

#### Scenario: No version override flags
- **WHEN** o comando de build do workflow é inspecionado
- **THEN** ele MUST NOT conter `--build-number` nem `--build-name`

### Requirement: AAB is signed with a secret-provided upload key
O AAB MUST ser assinado com a chave de upload reconstruída a partir de secrets do GitHub. Keystore, senhas, arquivo de propriedades de assinatura, config do Firebase e JSON de service account MUST NOT ser versionados nem impressos nos logs, e os arquivos temporários MUST ser removidos ao final do job, mesmo em falha.

#### Scenario: Secrets only via secrets context
- **WHEN** o workflow e o arquivo `.example` de propriedades de assinatura são inspecionados
- **THEN** todo valor sensível MUST vir de `secrets.*` e o `.example` MUST conter apenas placeholders

#### Scenario: Cleanup always runs
- **WHEN** qualquer passo anterior falha
- **THEN** o passo de remoção dos arquivos sensíveis temporários MUST ter `if: always()`

### Requirement: Upload goes only to the internal track
O upload à Google Play MUST usar `track: internal`; o workflow MUST NOT publicar em outra trilha (alpha, beta, production). A promoção para produção permanece manual no Play Console.

#### Scenario: Track is internal
- **WHEN** a configuração do passo de upload é inspecionada
- **THEN** `track` MUST ser `internal` e nenhuma outra trilha MUST aparecer no workflow

### Requirement: CI is not broken by the local JDK pin
O workflow MUST garantir que o Gradle use o JDK do runner, neutralizando o `org.gradle.java.home` local de `android/gradle.properties` somente no checkout do CI.

#### Scenario: Gradle resolves JDK on Linux
- **WHEN** o passo de build roda no runner `ubuntu-latest`
- **THEN** a linha `org.gradle.java.home` MUST ter sido removida do checkout antes do build, e o arquivo versionado no repositório MUST permanecer inalterado
