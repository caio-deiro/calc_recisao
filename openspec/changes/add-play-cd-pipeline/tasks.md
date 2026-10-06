## 1. Workflow de release (B7-08)

- [x] 1.1 Confirmar localmente `flutter --version` (esperado 3.47.6, `.fvm/version`) e o JDK 21 do build; registrar divergência no design.md
- [x] 1.2 Criar `.github/workflows/release-android.yml` com `on: push: tags: ['v*']`, `permissions: contents: read`, `concurrency` por tag e job `ubuntu-latest`
- [x] 1.3 Passos de ambiente: checkout, `actions/setup-java` (Temurin 21), `subosito/flutter-action` com versão exata e cache, `flutter pub get`
- [x] 1.4 Passo de validação tag x `pubspec.yaml` (falha antes do build quando divergem)
- [x] 1.5 Passos `flutter analyze` e `flutter test`
- [x] 1.6 Passo que remove `org.gradle.java.home` de `android/gradle.properties` só no runner
- [x] 1.7 Passo que decodifica o keystore, monta o arquivo de propriedades de assinatura e grava o config do Firebase a partir dos secrets, sem imprimir segredos
- [x] 1.8 Passo `flutter build appbundle --release` sem `--build-number`/`--build-name`
- [x] 1.9 Passo `r0adkll/upload-google-play` com `track: internal` e o secret da service account
- [x] 1.10 Passo final `if: always()` removendo os arquivos sensíveis temporários

## 2. Arquivos de apoio (B7-08)

- [x] 2.1 Criar o `.example` das propriedades de assinatura em `android/` apenas com placeholders (`storeFile=upload-keystore.jks`)
- [x] 2.2 Confirmar que `.gitignore` já cobre keystore, propriedades de assinatura e config do Firebase (sem alterar se cobre)

## 3. Documentação (B7-08)

- [x] 3.1 `docs/SPECS.md`: conferir a linha B7-08 e a contagem do mapa (sem renumerar IDs)
- [x] 3.2 `docs/ARCHITECTURE.md`: §9 descreve workflow, secrets e fluxo; §10 ganha linha de ADR "CD por tag para internal"
- [x] 3.3 `docs/PROJECT.md` §13: passo a passo de release (bump, merge, tag, conferir internal, promover manualmente); sem Q29
- [x] 3.4 `.claude/skills/orchestrate/references/loop.md` item 9: o worker continua sem criar tag nem publicar; o upload é disparado pela tag do usuário
- [x] 3.5 Regenerar `docs/PROGRESS.md` com `python scripts/specs_progress.py` e conferir `--check`

## 4. Validação (B7-08)

- [x] 4.1 `flutter analyze` e `flutter test` locais limpos
- [x] 4.2 Lint do workflow com `actionlint` (se disponível) ou parse do YAML sem erro
- [x] 4.3 Revisar o diff: nenhum segredo, nenhum valor real, `gradle.properties` inalterado
- [x] 4.4 `openspec validate add-play-cd-pipeline --strict`

## 5. Passos manuais do usuário (B7-08)

- [ ] 5.1 (Manual) Criar service account no Google Cloud, gerar a chave JSON e conceder a ela permissão de release no Play Console (Usuários e permissões)
- [ ] 5.2 (Manual) Cadastrar os 6 secrets no GitHub: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `GOOGLE_SERVICES_JSON_BASE64`, `PLAY_SERVICE_ACCOUNT_JSON`
- [ ] 5.3 (Manual) Após o próximo bump (ex.: `1.3.1+17`) mergeado, criar a tag `v1.3.1`, acompanhar a aba Actions e conferir o build na trilha internal; promoção para produção segue manual
