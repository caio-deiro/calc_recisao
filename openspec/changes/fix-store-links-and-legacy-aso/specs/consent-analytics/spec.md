## MODIFIED Requirements

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
