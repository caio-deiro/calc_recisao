## Context

- Release hoje é 100% manual; não há `.github/`.
- `android/app/build.gradle.kts` já lê a assinatura de `android/key.properties` e `versionCode = flutter.versionCode` (vem do `pubspec.yaml`, `version: 1.3.0+16`). O plugin `com.google.gms.google-services` está aplicado, então o build **exige** `android/app/google-services.json` (arquivo ignorado pelo git).
- Toolchain verificada no repo (2026-10-06):
  - Flutter: `.fvm/version` = `3.47.6`; `.fvmrc` está em `stable` (flutuante, não serve de pin). `pubspec.yaml`: `sdk: ^3.8.1`.
  - AGP **8.11.1** (`android/settings.gradle.kts`; não é 8.7) e Gradle **8.14.3**. O compile Java do app é 11 (`VERSION_11`), mas Gradle/AGP precisam de JDK >= 17.
  - Branch `chore/gradle-jdk21` (commit `281ff87`) fixou o Gradle em **JDK 21** porque o JBR 25 do Android Studio não é parseado pelo AGP/Kotlin. Logo: usar **JDK 21 (Temurin)** no `actions/setup-java`.
- **Armadilha:** `android/gradle.properties` (já em `main`) contém `org.gradle.java.home=D:\\Program Files\\java21`, caminho local do Windows. No runner Linux o Gradle falharia ao localizar o JDK.

## Goals / Non-Goals

**Goals**
- Tag `v*` gera e envia um AAB assinado e testado à trilha `internal`, sem manuseio local da chave.
- Impedir release com tag divergente da versão do `pubspec.yaml`.

**Non-Goals**
- CI em PR, iOS, fastlane, promoção para produção, notas de release automáticas, mudar `gradle.properties`.

## Decisions

1. **Gatilho `on: push: tags: ['v*']`.** Publicar continua ato humano. Alternativa descartada: push em `main` (publicaria a cada merge, inclusive sem bump).
2. **Valida `tag == v<versão do pubspec sem +build>`** em shell (`${GITHUB_REF_NAME#v}` contra `version:` sem o `+N`), antes de qualquer build. Falha aborta o job.
3. **`versionCode`/`versionName` do pubspec**, sem `--build-number`/`--build-name`. Fonte única (DRY); a Play rejeita versionCode repetido, o que serve de rede de proteção.
4. **Portões `flutter analyze` e `flutter test`** antes do build; falha impede build e upload.
5. **Secrets** (6): `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `GOOGLE_SERVICES_JSON_BASE64`, `PLAY_SERVICE_ACCOUNT_JSON`. O workflow decodifica o keystore para `android/upload-keystore.jks`, monta `android/key.properties` com `storeFile=upload-keystore.jks` (relativo a `android/`, como o Gradle espera) e grava `android/app/google-services.json`. Esses arquivos são removidos ao final (`if: always()`). Nenhum valor é impresso (sem `set -x`/`echo` de secrets; o GitHub mascara secrets).
6. **Flutter fixo em versão exata** (`3.47.6`, `channel: stable`) em `subosito/flutter-action`, com cache. Valor **a confirmar** com `flutter --version` local antes de gravar (a leitura de `.fvm/version` é a única evidência até aqui); se divergir, vale o local e registra-se aqui.
7. **JDK 21 (Temurin)** via `actions/setup-java`. Valor **a confirmar** pelo executor com o build local do mesmo commit.
8. **Neutralizar o pin local de JDK no CI:** passo que remove a linha `org.gradle.java.home` de `android/gradle.properties` **apenas no checkout do runner** (`sed -i '/^org.gradle.java.home/d'`), para o Gradle usar o `JAVA_HOME` do setup-java. Alternativa descartada: editar `gradle.properties` no repo (fora de escopo e quebraria a máquina local do usuário).
9. **Upload com `r0adkll/upload-google-play`** (versão fixada pelo executor), `track: internal`, `status: completed`, `releaseFiles: build/app/outputs/bundle/release/app-release.aab`, com `mappingFile`/debug symbols se o build os gerar.
10. **Permissões e concorrência:** `permissions: contents: read`; `concurrency` por tag (`cancel-in-progress: false`); 1 job em `ubuntu-latest`.
11. **Supera o Non-Goal** "publicação automática" da change arquivada `target-android-api-36`, restrito à trilha `internal` e disparado por humano via tag.

## Risks / Trade-offs

- Service account sem permissão de release no Play Console: o upload falha; corrigir permissão e usar "Re-run jobs".
- `google-services.json` ausente quebra o build (o plugin exige); coberto pelo secret dedicado.
- versionCode repetido é rejeitado pela Play: exige bump antes da tag.
- Tag errada: coberta pela validação da decisão 2.
- Pin de JDK no repo: contornado no CI pela decisão 8; frágil se a linha mudar de formato.
- Hooks do repo (`protect_secrets.py`) bloqueiam escrita de arquivos que citem nomes de segredo (keystore, `key.properties`, `google-services.json`); o workflow cita esses nomes. Se barrar, não contornar: pedir ao usuário para criar o arquivo ou liberar. `scope_guard.py` pode impedir o executor de escrever em `.github/`; conferir antes de delegar.
- Não verificável localmente: o upload real. Só um run de tag no GitHub prova o fluxo.

## Migration Plan

1. Implementar workflow e arquivo `.example`; atualizar docs.
2. Usuário cria a service account e os secrets (seção 5 das tasks).
3. No próximo bump (ex.: `1.3.1+17`), mergear e criar a tag `v1.3.1`; acompanhar a aba Actions e a trilha internal.
4. Rollback: remover o workflow; o release manual continua funcionando sem alteração.

## Open Questions

- Anexar o AAB como artefato do run (`actions/upload-artifact`) como fallback manual? Recomendação: **não** (YAGNI); a falha é reexecutável por "Re-run jobs".
- Mover o pin de JDK para `~/.gradle/gradle.properties` (global do usuário) em change futura? Recomendação: sim, em change separada; aqui basta o `sed` no CI.
