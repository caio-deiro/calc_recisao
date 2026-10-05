## Context

Ver proposal.md (Why). Estado atual do projeto:

- `in_app_purchase: ^3.2.3` e `in_app_purchase_android: ^0.4.0+4` (lock em `0.4.0+5`), que embutem Play Billing ~7.1.1.
- `PurchaseService` usa a API facade (`queryProductDetails`, `buyNonConsumable`, `restorePurchases`, `completePurchase`) e não chama `queryPurchaseHistory`.
- Flutter via FVM em `3.44.9`, compatível com `in_app_purchase_android` ≥ `0.5.0` (e com `0.5.0+1`, que pede Flutter 3.44+).
- Não há override explícito de `com.android.billingclient:billing` no Gradle do app.

## Goals / Non-Goals

**Goals:**

- Subir as dependências Flutter para uma combinação que embuta Billing Library ≥ 8.0.0.
- Confirmar no build Android que a versão nativa resolvida atende o piso da Play Console.
- Validar regressão do fluxo PRO (carregar produto, comprar, restaurar, ativar flag local).

**Non-Goals:**

- Forçar Billing 9.x enquanto o plugin oficial ainda embute 8.0.0.
- Adicionar verificação server-side de recibos (TODO já existente fora deste change).
- Alterar ID do produto PRO, pricing, UX da tela PRO ou política de ads.
- Mudanças iOS/StoreKit além do que vier transitivamente do bump do facade.

## Decisions

### 1. Atualizar via plugins Flutter, não via Gradle manual

- **Escolha:** Bump de `in_app_purchase` → `^3.3.0` (depende de `in_app_purchase_android` `^0.5.0`) e constraint direta `in_app_purchase_android: ^0.5.2`.
- **Por quê:** `3.3.0` é o bump oficial do facade que puxa Android 0.5.x com Billing 8.0.0. Override manual no `build.gradle` já causou falhas reportadas na comunidade (query de produtos quebrada).
- **Alternativas:** (a) só pin `in_app_purchase_android` sem bump do facade — frágil se o facade ainda declarar 0.4.x; (b) forçar `billing:8.x` no Gradle — rejeitado; (c) migrar para RevenueCat/outro SDK — fora de escopo.

### 2. Aceitar Billing 8.0.0 do plugin (não exigir 9 ainda)

- **Escolha:** Cumprir o piso 8.0.0 exigido pela Play; não introduzir Billing 9 até o plugin oficial embutir.
- **Por quê:** A mensagem da Play permite ≥ 8.0.0; “upgrade para 9” é recomendação de features, não o requisito do prazo.
- **Alternativa:** Fork/patch do plugin para Billing 9 — custo alto sem necessidade imediata.

### 3. Tratamento do breaking change 0.4 → 0.5

- **Escolha:** Nenhuma adaptação de API esperada no app; apenas revisão e testes. Se algo quebrar, ajustar apenas chamadas Android-specific.
- **Por quê:** O breaking documentado remove `queryPurchaseHistory`; o app já usa `restorePurchases()`.
- **Alternativa:** Reescrever `PurchaseService` em cima de `InAppPurchaseAndroidPlatformAddition` — desnecessário agora.

### 4. Verificação de compliance no apply

- **Escolha:** Após `flutter pub get`, inspecionar a árvore Gradle / metadados do plugin (ou artefato gerado) para confirmar `billingclient` ≥ 8.0.0 antes de considerar o change concluído.
- **Por quê:** O aviso da Play olha a versão nativa no binário, não o número do pacote Dart.

## Risks / Trade-offs

- [Resolução de versão abaixo de 0.5.x] → Fixar constraints `^3.3.0` / `^0.5.2` e conferir `pubspec.lock` após o get.
- [Regressão em query/compra PRO em dispositivo real] → Testar com conta de licença na Play; validar load, buy e restore.
- [Conflito AGP/Kotlin após bump do plugin] → Projeto já em toolchain recente; se o build falhar, alinhar Gradle/Kotlin ao mínimo do plugin sem overrides de billing.
- [Play ainda marcar versão antiga após bump] → Confirmar que o AAB enviado é o build novo; limpar caches de release se necessário.

## Migration Plan

1. Atualizar `pubspec.yaml` e rodar `flutter pub get` (FVM).
2. Build Android release/debug e confirmar Billing ≥ 8.0.0.
3. Smoke test do fluxo PRO (disponibilidade, produto, compra de teste, restore).
4. Publicar AAB na Play Console com antecedência ao prazo de 30/08/2026.
5. Rollback: reverter constraints no `pubspec` e republicar só se o bump impedir release crítico — ciente de que o rollback reabre o bloqueio de compliance após o prazo.
