## Purpose

Garante que builds Android de release submetidos à Google Play segmentem o SDK exigido (API 36+) e permaneçam atualizáveis após o prazo de compliance da Play Console.

## ADDED Requirements

### Requirement: Release target SDK meets Play floor
Builds de release do app Android MUST declarar `targetSdkVersion` (nível desejado da API) 36 ou superior, de forma que a verificação de compliance da Google Play aceite atualizações após o prazo de agosto de 2026.

#### Scenario: Release artifact targets API 36 or higher
- **WHEN** um AAB/APK de release é gerado para publicação na Google Play
- **THEN** o artefato MUST reportar `targetSdkVersion` igual a 36 ou superior

#### Scenario: Compile SDK supports the target floor
- **WHEN** o módulo Android do app é configurado para build
- **THEN** o `compileSdk` MUST ser 36 ou superior para permitir segmentar o nível desejado exigido

### Requirement: Min SDK remains compatible
A atualização do nível desejado da API MUST NÃO reduzir a faixa de dispositivos suportados além do `minSdk` já definido no projeto.

#### Scenario: Existing minSdk is preserved
- **WHEN** `compileSdk` e `targetSdk` são elevados para 36 ou superior
- **THEN** o `minSdk` MUST permanecer 24 (ou o valor já adotado pelo projeto, se maior), sem exclusão adicional de dispositivos só por causa deste compliance

### Requirement: App remains usable after targeting Android 16
Após segmentar API 36, o app MUST continuar abrindo e permitindo o fluxo principal de cálculo em dispositivos Android suportados, sem regressão bloqueante causada apenas pelo bump de target.

#### Scenario: Cold start on supported device
- **WHEN** o usuário abre o app em um dispositivo com Android suportado pelo `minSdk`
- **THEN** o app MUST iniciar a UI principal sem crash atribuível ao target SDK 36

#### Scenario: Core calculation flow still works
- **WHEN** o usuário preenche os dados necessários e solicita o cálculo de rescisão
- **THEN** o sistema MUST apresentar o resultado do cálculo como antes do bump de target
