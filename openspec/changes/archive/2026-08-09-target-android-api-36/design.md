## Context

Ver proposal.md (Why). Estado atual do projeto:

- `android/app/build.gradle.kts` usa `compileSdk = flutter.compileSdkVersion` e `targetSdk = flutter.targetSdkVersion`.
- Flutter via FVM `3.44.9` já define `compileSdkVersion` / `targetSdkVersion` = 36 em `FlutterExtension`.
- A versão publicada na Play ainda reporta target Android 15 (API 35) — compliance exige novo artefato com API 36.
- AGP `8.7.0`, Kotlin `2.2.10`, `minSdk = 24`. Manifesto sem lock de orientação.
- Change relacionado (separado): `upgrade-play-billing-library` (Billing ≥ 8.0.0), mesmo prazo aproximado de Play Console.

## Goals / Non-Goals

**Goals:**

- Garantir que todo release build declare `targetSdk` ≥ 36 (e `compileSdk` ≥ 36).
- Verificar no artefato gerado que o merged manifest reflete API 36.
- Validar smoke do app após o bump (abertura + cálculo).
- Documentar o requisito para não regredir em builds futuros.

**Non-Goals:**

- Subir `minSdk`.
- Migrar para API 37+ “por precaução”.
- Refatorar UI/edge-to-edge além do necessário para regressão real.
- Alterar Billing / compras (outro change).
- Publicação automática na Play (ação manual do mantenedor).

## Decisions

### 1. Pin explícito de `compileSdk` / `targetSdk` = 36 no Gradle do app

- **Escolha:** Em `android/app/build.gradle.kts`, definir `compileSdk = 36` e `targetSdk = 36` de forma explícita (em vez de depender só de `flutter.*SdkVersion`).
- **Por quê:** O default do Flutter 3.44.9 já é 36, mas um build acidental com SDK Flutter mais antigo voltaria a 35 e reabriria o bloqueio da Play. Pin explícito torna o compliance auditável no repositório.
- **Alternativas:** (a) manter `flutter.compileSdkVersion` / `flutter.targetSdkVersion` e só republicar — funciona hoje, frágil se o Flutter do ambiente mudar; (b) `max(flutter.targetSdkVersion, 36)` — mais complexo sem ganho claro neste projeto.

### 2. Manter `minSdk = 24`

- **Escolha:** Não alterar `minSdk`.
- **Por quê:** O aviso da Play é só sobre nível desejado (`targetSdk`); subir `minSdk` cortaria usuários sem necessidade.
- **Alternativa:** Alinhar `minSdk` ao floor da Play para apps novos — fora do escopo e prejudicaria a base instalada.

### 3. Verificação de compliance no artefato, não só no Gradle

- **Escolha:** Após `flutter build appbundle` (ou apk), inspecionar o merged manifest / saída `aapt dump badging` e confirmar `targetSdkVersion:'36'` (ou ≥ 36).
- **Por quê:** A Play valida o binário enviado; divergências de merge/manifest podem mascarar um Gradle “certo” na aparência.

### 4. Escopo de adaptação Android 16

- **Escolha:** Não antecipar refactors grandes; smoke test + correção só se houver regressão (layouts/insets). O app não declara `screenOrientation` locked.
- **Por quê:** Para um utilitário phone-first sem lock de orientação, o risco comportamental do API 36 é baixo; over-engineering atrasa o compliance.
- **Alternativa:** Auditoria completa de adaptive layouts / large-screen — adiar até evidência de problema.

### 5. Documentação mínima

- **Escolha:** Registrar em `doc/GOOGLE_PLAY_SETUP.md` (ou seção equivalente) que releases Android MUST target API 36+ e que o pin está no Gradle.
- **Por quê:** O projeto já documenta requisitos de Play; evita novo aviso no próximo ciclo anual.

## Risks / Trade-offs

- [SDK Platform 36 ausente na máquina de build] → Instalar via Android SDK Manager antes do release; falha de compile deixa claro o gap.
- [Flutter/plugin incompatível com compileSdk 36] → Toolchain atual (FVM 3.44.9 + AGP 8.7) já alinha a 36; se algum plugin falhar, atualizar o plugin, não baixar o target.
- [Regressão visual edge-to-edge em API 36] → Smoke em emulador/dispositivo API 36; ajustar SafeArea/insets só se necessário.
- [Play continua marcando não-conforme após bump no repo] → Compliance só fecha após upload do AAB novo; republicar e revalidar Policy status.
- [Pin 36 “atrasa” defaults futuros do Flutter] → Aceitável; no próximo ciclo anual (API 37) repetir bump explícito.

## Migration Plan

1. Ajustar `compileSdk` / `targetSdk` para 36 em `android/app/build.gradle.kts`.
2. Confirmar Android SDK Platform 36 no ambiente; build debug e release.
3. Verificar `targetSdkVersion` no artefato.
4. Smoke test (abertura + cálculo); corrigir regressões mínimas se houver.
5. Atualizar doc de Play setup.
6. Publicar AAB na Play Console antes do prazo (~30/31 ago 2026).
7. Rollback: reverter o pin no Gradle e republicar só se o bump impedir release crítico — ciente de que após o prazo o rollback reabre o bloqueio de atualização.
