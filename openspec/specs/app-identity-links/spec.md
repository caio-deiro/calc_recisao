# app-identity-links Specification

## Purpose
TBD - created by archiving change fix-store-links-and-legacy-aso. Update Purpose after archive.

## Requirements

### Requirement: Single support contact and privacy policy URL
`AppConstants.supportEmail` MUST ser `caioguimaraes12@outlook.com` e `AppConstants.privacyPolicyUrl` MUST ser `https://caio-deiro.github.io/calc_recisao`. Todo e-mail de suporte exibido ou usado em `mailto:` MUST vir de `AppConstants.supportEmail`. `AppConstants.termsOfServiceUrl` MUST NOT existir.

#### Scenario: Constants have the decided values
- **WHEN** um teste lê `AppConstants.supportEmail` e `AppConstants.privacyPolicyUrl`
- **THEN** os valores MUST ser exatamente os literais acima, escritos à mão no teste

#### Scenario: Support screen shows the constant
- **WHEN** a `SupportScreen` é renderizada
- **THEN** o texto `caioguimaraes12@outlook.com` MUST estar visível e nenhum card "Perguntas Frequentes" MUST existir

### Requirement: No nonexistent domain in code
O domínio `calcrescisao.com` MUST NOT aparecer em `lib/` nem em `test/` (exceto no teste de verificação que o procura).

#### Scenario: Repository grep is clean
- **WHEN** um teste varre os arquivos `.dart` de `lib/`
- **THEN** nenhum MUST conter `calcrescisao.com`

### Requirement: ASO dead code and fake install source removed
O app MUST NOT conter `aso_ab_testing.dart`, `aso_deep_links.dart` nem `aso_analytics.dart`, nem gravar `install_source`, `first_open` ou `session_count`. `LegacyCleanup` MUST remover essas três chaves de instalações antigas.

#### Scenario: Legacy ASO keys cleaned
- **WHEN** `LegacyCleanup.run()` roda com `install_source`, `first_open` e `session_count` gravadas
- **THEN** as três chaves MUST ser removidas

#### Scenario: Home does not write ASO keys
- **WHEN** a Home é exibida com SharedPreferences vazio
- **THEN** `install_source`, `first_open` e `session_count` MUST estar ausentes

### Requirement: Canonical Android app name
O `android:label` MUST resolver para "Calculadora de Rescisão CLT" (via `@string/app_name`) e o manifesto MUST NOT conter as meta-data `app_category`, `app_keywords` e `app_description`. A `description` do `pubspec.yaml` MUST NOT conter "Trabalhista 2025".

#### Scenario: Manifest and pubspec verified
- **WHEN** um teste lê `AndroidManifest.xml`, `strings.xml` e `pubspec.yaml`
- **THEN** `app_name` MUST ser "Calculadora de Rescisão CLT", o label MUST ser `@string/app_name`, as três meta-data MUST estar ausentes e "Trabalhista 2025" MUST estar ausente
