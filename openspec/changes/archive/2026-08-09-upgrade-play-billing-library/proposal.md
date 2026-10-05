## Why

A Google Play exige que, a partir de 30 de agosto de 2026, todos os apps usem a Biblioteca Google Play Faturamento 8.0.0 ou mais recente; atualizações com versão antiga serão recusadas. O app ainda resolve `in_app_purchase_android` 0.4.x (Billing ~7.1.1 via o plugin), então precisa atualizar as dependências Flutter antes desse prazo.

## What Changes

- Atualizar `in_app_purchase` para `^3.3.0` (ou superior), que depende de `in_app_purchase_android` `^0.5.0` e embute Google Play Billing Library 8.0.0.
- Atualizar a constraint direta de `in_app_purchase_android` para `^0.5.2` (ou a mais recente compatível), alinhada ao Flutter do projeto (FVM 3.44.x).
- Regenerar `pubspec.lock` e validar que o AAR/`billingclient` resolvido no build Android seja ≥ 8.0.0.
- Revisar `PurchaseService` e fluxos PRO (compra, restauração, ativação local) após o bump; o código já usa `restorePurchases()` e não chama `queryPurchaseHistory` (API removida em 0.5.0).
- **Não** forçar `com.android.billingclient:billing` manualmente no Gradle do app (evita conflito com o plugin).
- Documentar o requisito de compliance no setup Google Play, se aplicável.

## Capabilities

### New Capabilities

- `play-billing`: Compliance com Google Play Billing Library ≥ 8.0.0 e continuidade do fluxo de compra/restauração PRO no Android.

### Modified Capabilities

- (nenhuma — ainda não há specs principais em `openspec/specs/`)

## Impact

- Dependências: `pubspec.yaml` / `pubspec.lock` (`in_app_purchase`, `in_app_purchase_android` e transitivas).
- Código: principalmente `lib/core/services/purchase_service.dart`; possível impacto mínimo em `pro_utils.dart` / tela PRO se houver breaking na API Dart (improvável para o facade).
- Build Android: resolução nativa do Billing Client via o plugin; sem mudança de produto PRO nem de UX prevista.
- Release: necessário publicar um novo AAB/APK na Play Console antes de 30/08/2026 para passar na verificação de compliance.
- Fora de escopo: migração para Billing 9.x (opcional; o prazo exige ≥ 8.0.0), verificação server-side de recibos, mudanças de preço/produto, iOS StoreKit.
