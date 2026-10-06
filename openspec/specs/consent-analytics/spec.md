# consent-analytics Specification

## Purpose
TBD - created by archiving change remove-pro-ads-only. Update Purpose after archive.

## Requirements

### Requirement: Single consent prompt after first result
O app MUST exibir uma única vez, após o primeiro resultado, o formulário de consentimento do Google (UMP) e a escolha de analytics, persistindo `consent_decided` e `analytics_enabled`. MUST NOT exibir aviso antes do primeiro resultado nem repeti-lo depois de decidido.

#### Scenario: No prompt before first result
- **WHEN** o app é aberto pela primeira vez e o usuário ainda não concluiu um cálculo
- **THEN** nenhum aviso de consentimento MUST ser exibido

#### Scenario: Prompt after first result
- **WHEN** o usuário conclui o primeiro cálculo e `consent_decided` é falso
- **THEN** o aviso MUST ser exibido e a decisão MUST ser persistida

#### Scenario: Not repeated
- **WHEN** `consent_decided` é verdadeiro e o usuário conclui outro cálculo
- **THEN** o aviso MUST NOT ser exibido

### Requirement: Firebase initialized with collection off by default
O app MUST inicializar o Firebase no `main` com coleta de Analytics e Crashlytics desligada por padrão (meta-data do manifesto e `setAnalyticsCollectionEnabled(false)` no boot). A coleta MUST ligar somente após o aceite, para Analytics e Crashlytics sob a mesma decisão.

#### Scenario: Fresh install
- **WHEN** o app inicia sem decisão registrada
- **THEN** Analytics e Crashlytics MUST estar com coleta desabilitada

#### Scenario: Accepted
- **WHEN** o usuário aceita
- **THEN** `setAnalyticsCollectionEnabled(true)` e `setCrashlyticsCollectionEnabled(true)` MUST ser chamados

#### Scenario: Declined
- **WHEN** o usuário recusa
- **THEN** a coleta MUST permanecer desabilitada

### Requirement: Minimal event set via central emitter
Os únicos eventos permitidos MUST ser `calc_completed{tipo_rescisao}`, `share_used`, `pdf_exported` e `consent_decision{aceitou|recusou}`, emitidos por um único ponto em `core/analytics/` que MUST descartar silenciosamente qualquer evento sem consentimento. Eventos MUST NOT conter salário, datas, valores ou resultado (B0-03). O app MUST NOT conter lógica de analytics local ou de conversão paralela ao ponto central (`aso_analytics.dart` removido).

#### Scenario: Event dropped without consent
- **WHEN** um evento é emitido com `analytics_enabled` falso
- **THEN** nada MUST ser enviado ao Firebase e nenhum erro MUST ocorrer

#### Scenario: Event sent with consent
- **WHEN** `analytics_enabled` é verdadeiro e um cálculo conclui
- **THEN** `calc_completed` MUST ser enviado apenas com o parâmetro `tipo_rescisao`

#### Scenario: No personal data
- **WHEN** qualquer evento é emitido
- **THEN** seus parâmetros MUST ser somente os listados para aquele evento
