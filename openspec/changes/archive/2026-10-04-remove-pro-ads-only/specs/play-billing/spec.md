## REMOVED Requirements

### Requirement: Play Billing Library minimum version
**Reason**: O app deixa de ter compras in-app (B1-03); a biblioteca de faturamento sai do build.
**Migration**: Nenhuma. O requisito de target SDK permanece em `android-target-sdk`.

### Requirement: PRO purchase continues after billing upgrade
**Reason**: O PRO é removido; o app é 100 % gratuito (Q15–Q19).
**Migration**: Nenhuma; não há assinantes a migrar.

### Requirement: PRO restore continues after billing upgrade
**Reason**: Sem PRO, não há compra a restaurar.
**Migration**: Chaves locais de PRO são apagadas pela limpeza legada (`free-app`).
