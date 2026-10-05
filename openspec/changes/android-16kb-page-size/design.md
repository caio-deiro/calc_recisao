## Context

Ver proposal.md (Why). Estado atual do projeto:

- AGP `8.7.0` (≥ 8.5.1) já declarado em `android/settings.gradle.kts`, com comentário explícito sobre 16 KB.
- `android/app/build.gradle.kts` já define `packaging { jniLibs { useLegacyPackaging = false } }` e `compileSdk`/`targetSdk` = 36.
- A Play Console ainda marca a **produção** como incompatível com 16 KB — o gap é o artefato publicado (e/ou libs nativas ainda desalinhadas), não a ausência total de configuração.
- App Flutter com plugins que trazem `.so` (Ads, Firebase, IAP, printing, path_provider, etc.); o engine Flutter também embute nativos.
- Change paralelo (separado): `target-android-api-36` (API 36). O mesmo AAB de release pode fechar os dois avisos, mas os critérios de verificação são distintos.
- Referência oficial: [Suporte a tamanhos de página de 16 KB](https://developer.android.com/guide/practices/page-sizes?hl=pt-br#build).

## Goals / Non-Goals

**Goals:**

- Produzir um AAB de release que passe nas verificações locais de alinhamento 16 KB (ELF + ZIP/`zipalign`, e config do bundle quando aplicável).
- Identificar e corrigir qualquer `.so` de 64 bits ainda desalinhada (upgrade de Flutter/plugin/SDK).
- Documentar o checklist de verificação para não regredir.
- Deixar o upload de produção pronto para a Play reconhecer compatibilidade 16 KB.

**Non-Goals:**

- Usar `useLegacyPackaging = true` / libs compactadas como “solução” permanente (aumenta footprint e só evita o problema de instalação).
- Alterar `minSdk`, produto/UX, iOS.
- Resolver o aviso de target API 36 (change `target-android-api-36`).
- Publicação automática na Play (ação manual do mantenedor).
- Teste obrigatório em emulador 16 KB se a verificação de alinhamento do artefato já passar — recomendado, mas não bloqueante do design se o ambiente não tiver a system image.

## Decisions

### 1. Tratar o problema como verificação + upgrade de nativos, não como novo feature flag

- **Escolha:** Auditoria do AAB/APK de release → listar `.so` desalinhadas → atualizar a origem (Flutter/NDK/plugin) → rebuild → revalidar.
- **Por quê:** O Gradle já está no caminho “moderno” (AGP 8.7 + libs não compactadas). O aviso da Play em produção indica binário antigo e/ou `.so` pré-compilada ainda em 4 KB.
- **Alternativas:** (a) forçar packaging legado — rejeitada (anti-padrão da doc Google); (b) só republicar o AAB atual sem auditar — risco de o aviso persistir.

### 2. Manter AGP ≥ 8.5.1 e `useLegacyPackaging = false`

- **Escolha:** Preservar AGP 8.7.0 e packaging não legado; só subir versões se o build exigir.
- **Por quê:** AGP 8.5.1+ alinha ZIP de `.so` não compactadas em 16 KB e é o caminho recomendado pela Google para Play.
- **Alternativa:** Downgrade/workaround com libs compactadas — descartada.

### 3. Critério de aceite local antes do upload

- **Escolha:** Aceitar o artefato só se:
  1. `zipalign -c -P 16 -v 4 <apk>` reportar verificação bem-sucedida (APK derivado do release, se necessário); e
  2. segmentos LOAD ELF das `.so` `arm64-v8a`/`x86_64` tiverem `align` ≥ `2**14`; e
  3. para AAB, `bundletool dump config` indicar `PAGE_ALIGNMENT_16K` (quando a ferramenta estiver disponível no ambiente).
- **Por quê:** A Play valida o binário; “Gradle parece certo” não basta. ELF e ZIP são falhas distintas.
- **Alternativa:** Confiar só no status pós-upload da Play Console — atrasaria o ciclo de correção.

### 4. Flutter/plugins: bump mínimo que elimine `.so` desalinhadas

- **Escolha:** Se a auditoria apontar engine ou plugin específico, atualizar só o necessário (FVM Flutter patch/minor e/ou versão do plugin) até o artefato passar.
- **Por quê:** O app já usa toolchain recente; upgrades cirúrgicos reduzem risco vs. “upgrade everything”.
- **Alternativa:** Recompilar plugins a partir do fonte com flags `-Wl,-z,max-page-size=16384` — só se não houver binário pré-built compatível.

### 5. Documentação no setup Google Play

- **Escolha:** Registrar em `doc/GOOGLE_PLAY_SETUP.md` o requisito 16 KB, AGP ≥ 8.5.1, packaging não legado, e os comandos de verificação.
- **Por quê:** Mesmo padrão da change de target SDK; evita regressão no próximo release.

## Risks / Trade-offs

- [Plugin/SDK sem build 16 KB disponível] → Abrir issue/upgrade; se bloqueante, substituir ou remover o plugin antes do compliance.
- [Flutter engine desalinhado na versão FVM atual] → Subir Flutter via FVM para versão com engine 16 KB-ready; revalidar golden/smoke.
- [Play continua marcando incompatível após upload] → Confirmar que o track de produção recebeu o AAB novo (não só internal); reanalisar o artefato enviado.
- [Smoke em device 16 KB indisponível] → Priorizar verificação de alinhamento do artefato; agendar teste em emulador 16 KB quando a system image estiver instalada.
- [Mesmo AAB também cobre API 36] → Coordenar publicação única com `target-android-api-36` se ambos estiverem prontos; não misturar critérios de aceite nas tasks.

## Migration Plan

1. Gerar AAB/APK de release com a config atual.
2. Auditar alinhamento (ZIP + ELF; bundle config se possível).
3. Corrigir origens das `.so` desalinhadas (Flutter/plugin/SDK) e rebuild.
4. Repetir auditoria até passar.
5. Smoke test (abertura + cálculo).
6. Atualizar `doc/GOOGLE_PLAY_SETUP.md`.
7. Publicar AAB na produção e confirmar que o aviso de 16 KB some no Policy status.
8. Rollback: republicar artefato anterior só em emergência — ciente de que o aviso de 16 KB permanece até haver build compatível.

## Open Questions

- Nenhum bloqueante: se o ambiente Windows não tiver o script `check_elf_alignment.sh`, usar `llvm-objdump` / APK Analyzer / `zipalign` equivalentes documentados na própria doc Android.
