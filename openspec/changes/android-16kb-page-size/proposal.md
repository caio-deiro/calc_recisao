## Why

A Google Play exige que apps com `targetSdk` Android 15+ aceitem tamanhos de página de memória de 16 KB em dispositivos 64 bits; a versão de produção atual do CalcCLT foi marcada como incompatível. Sem um release compatível, atualizações futuras podem ser bloqueadas (prazo duro em 31/jan/2027) e o app pode falhar em dispositivos 16 KB.

## What Changes

- Garantir que o AAB/APK de release tenha bibliotecas nativas (`.so`) com alinhamento ELF de 16 KB e alinhamento ZIP de 16 KB para libs não compactadas.
- Confirmar (ou ajustar) toolchain AGP ≥ 8.5.1, empacotamento `jniLibs` sem legacy packaging, e Flutter/NDK/plugins cujas `.so` já venham alinhadas a 16 KB.
- Verificar o artefato de release com `zipalign` / análise ELF (e/ou APK Analyzer) até o pacote passar como compatível com 16 KB.
- Documentar o requisito e o procedimento de verificação na doc de setup Google Play.
- Publicar na produção um build que a Play Console reconheça como compatível com 16 KB.

## Capabilities

### New Capabilities

- `android-16kb-page-size`: Compliance do app Android com tamanhos de página de 16 KB exigidos pela Google Play (alinhamento de bibliotecas nativas no artefato de release e verificação objetiva antes do upload).

### Modified Capabilities

- (nenhuma — ainda não há spec principal de page-size em `openspec/specs/`)

## Impact

- Build Android: `android/app/build.gradle.kts` (packaging `jniLibs`), possível ajuste de AGP/NDK/Flutter se alguma `.so` continuar desalinada.
- Dependências nativas: engine Flutter e plugins com código NDK (ex.: billing/outros) precisam de versões alinhadas a 16 KB.
- Release: novo AAB na Play Console; o aviso de “não aceita tamanhos de página de 16 KB” deve sumir após o upload aprovado.
- Relação com `target-android-api-36`: change separada (API 36); esta change cobre só page-size 16 KB, mesmo que o mesmo AAB possa satisfazer ambos.
- Fora de escopo: mudanças de produto/UX, iOS, alteração de `minSdk`, e o upgrade de Play Billing já tratado em change arquivada.
