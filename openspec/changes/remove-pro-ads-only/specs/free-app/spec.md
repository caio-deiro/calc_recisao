## ADDED Requirements

### Requirement: No PRO or purchase code
O app MUST NOT conter código, dependência, constante ou tela de PRO/compra in-app. Os arquivos `purchase_service.dart`, `offline_service.dart`, `pro_utils.dart` e `pro_screen.dart` MUST ser removidos, assim como `in_app_purchase` e `in_app_purchase_android` do `pubspec.yaml` e as constantes `proProductId`, `proMonthlyPrice`, `proSupportEmail`, `proSupportResponseHours`, `maxFreeHistorySize`, `maxProHistorySize`.

#### Scenario: Static check finds no PRO references
- **WHEN** se executa `grep -rn "ProUtils\|PurchaseService\|OfflineService\|in_app_purchase" lib pubspec.yaml`
- **THEN** a saída MUST ser vazia

#### Scenario: Release has no billing permission
- **WHEN** o APK de release é gerado
- **THEN** o manifesto mesclado MUST NOT declarar a permissão `com.android.vending.BILLING`

#### Scenario: No upgrade UI
- **WHEN** o usuário navega por Home, Histórico, Resultado e Suporte
- **THEN** nenhuma tela MUST exibir card de upgrade, banner de limite PRO, bloqueio de PDF ou e-mail de suporte PRO

### Requirement: Legacy PRO data cleanup
Na primeira execução da nova versão, o app MUST remover do `SharedPreferences` as chaves `is_pro_user`, `pro_purchase_date`, `pro_purchase_id`, `pro_purchase_token`, `offline_cache`, `pending_sync`, `pro_conversion`. A operação MUST ser idempotente.

#### Scenario: Legacy keys removed
- **WHEN** o app inicia com as 7 chaves presentes
- **THEN** nenhuma delas MUST existir após o bootstrap e as demais chaves (histórico) MUST permanecer intactas

#### Scenario: Idempotent cleanup
- **WHEN** o bootstrap roda duas vezes seguidas ou sem nenhuma chave legada
- **THEN** não MUST ocorrer erro e o estado MUST ser igual ao da primeira execução

### Requirement: PDF available to everyone
A exportação e o salvamento de PDF MUST estar disponíveis a todos os usuários, sem verificação de status.

#### Scenario: PDF export without gate
- **WHEN** o usuário toca em exportar PDF no Resultado
- **THEN** o PDF MUST ser gerado sem consultar qualquer status de usuário nem exibir diálogo de bloqueio

### Requirement: History limited to 100 with FIFO
`AppConstants.maxHistorySize` MUST ser 100. `HistoryRepository.saveCalculation` MUST descartar o item mais antigo ao exceder o limite. O formato JSON do histórico MUST NOT mudar.

#### Scenario: 101st calculation discards oldest
- **WHEN** existem 100 cálculos salvos e um novo é salvo
- **THEN** MUST existir exatamente 100 e o mais antigo MUST ter sido descartado

#### Scenario: Existing history still loads
- **WHEN** o app abre com histórico gravado pela versão anterior
- **THEN** os itens MUST ser lidos sem erro

### Requirement: Near-full history notice
Quando o histórico tiver 90 ou mais itens após salvar, a tela de Histórico MUST exibir um aviso discreto e não bloqueante, no lugar do banner de upgrade.

#### Scenario: Notice at 90
- **WHEN** a tela de Histórico abre com 90 itens
- **THEN** o aviso MUST estar visível

#### Scenario: No notice below 90
- **WHEN** a tela de Histórico abre com 89 itens
- **THEN** o aviso MUST NOT estar visível
