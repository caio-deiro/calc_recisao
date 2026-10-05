## 1. Confirmar toolchain e packaging

- [x] 1.1 Confirmar que AGP em `android/settings.gradle.kts` permanece ≥ 8.5.1
- [x] 1.2 Confirmar que `android/app/build.gradle.kts` mantém `jniLibs.useLegacyPackaging = false` (sem fallback para packaging legado)

## 2. Build e auditoria de alinhamento 16 KB

- [x] 2.1 Gerar artefato de release (`flutter build appbundle` e/ou `apk`)
- [x] 2.2 Verificar alinhamento ZIP 16 KB (`zipalign -c -P 16 -v 4` no APK de release ou APK derivado)
- [x] 2.3 Verificar alinhamento ELF das `.so` 64 bits (`arm64-v8a` / `x86_64`) com `align` ≥ `2**14` (llvm-objdump / APK Analyzer)
- [x] 2.4 Se AAB disponível, confirmar `PAGE_ALIGNMENT_16K` via `bundletool dump config` (quando a ferramenta estiver no ambiente)

## 3. Corrigir bibliotecas nativas incompatíveis

- [x] 3.1 Se alguma `.so` falhar na auditoria, identificar a origem (Flutter engine vs plugin/SDK)
- [x] 3.2 Atualizar a dependência mínima necessária (FVM Flutter e/ou plugin) até a auditoria passar; não publicar artefato desalinhado

## 4. Documentação

- [x] 4.1 Atualizar `doc/GOOGLE_PLAY_SETUP.md` com requisito 16 KB, AGP ≥ 8.5.1, packaging não legado e comandos de verificação

## 5. Validação

- [x] 5.1 Smoke test: cold start do app sem crash após o rebuild compatível
- [x] 5.2 Smoke test: fluxo principal de cálculo de rescisão ainda apresenta resultado
- [ ] 5.3 (Manual) Publicar AAB na Play Console (produção) e confirmar que o aviso de 16 KB some no Policy status
