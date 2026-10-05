## Purpose

Garante compliance do app Android com a Biblioteca Google Play Faturamento exigida pela Play Console e preserva o fluxo de compra e restauração do PRO.

## ADDED Requirements

### Requirement: Play Billing Library minimum version
O app Android MUST incluir a Biblioteca Google Play Faturamento na versão 8.0.0 ou mais recente em builds de release submetidos à Google Play, de forma que a verificação de compliance da Play Console aceite atualizações após 30 de agosto de 2026.

#### Scenario: Release build meets billing library floor
- **WHEN** um AAB/APK de release é gerado para publicação na Google Play
- **THEN** a dependência nativa de faturamento resolvida no artefato MUST ser Google Play Billing Library 8.0.0 ou superior

#### Scenario: Plugin-mediated billing version
- **WHEN** as dependências de compra in-app do projeto são resolvidas
- **THEN** a versão efetiva do Billing Client MUST vir da implementação Android do plugin de compras in-app (sem override manual conflitante no Gradle do app)

### Requirement: PRO purchase continues after billing upgrade
Após o upgrade da biblioteca de faturamento, o sistema MUST continuar permitindo que o usuário inicie a compra do produto PRO não consumível no Android quando a loja estiver disponível e o produto estiver carregado.

#### Scenario: Successful PRO purchase initiation
- **WHEN** compras in-app estão disponíveis, o produto PRO foi carregado e o usuário solicita a compra PRO
- **THEN** o sistema MUST iniciar o fluxo de compra do produto PRO e MUST marcar a compra como pendente até receber atualização da loja

#### Scenario: Purchase unavailable
- **WHEN** compras in-app não estão disponíveis ou o produto PRO não foi carregado
- **THEN** o sistema MUST NÃO iniciar a compra e MUST indicar falha de forma não bloqueante para o restante do app

### Requirement: PRO restore continues after billing upgrade
O sistema MUST continuar permitindo restaurar compras PRO ativas via a API de restauração suportada pela biblioteca atual (sem depender de APIs de histórico de compra removidas).

#### Scenario: Restore active PRO entitlement
- **WHEN** o usuário solicita restaurar compras e existe uma compra PRO válida ativa
- **THEN** o sistema MUST processar o evento de restauração e MUST ativar o estado PRO local

#### Scenario: Restore with no prior purchase
- **WHEN** o usuário solicita restaurar compras e não há compra PRO ativa
- **THEN** o sistema MUST concluir a tentativa de restauração sem ativar PRO indevidamente
