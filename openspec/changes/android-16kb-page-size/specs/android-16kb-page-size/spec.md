## Purpose

Garante que builds Android de release submetidos à Google Play sejam compatíveis com dispositivos de 64 bits que usam tamanho de página de memória de 16 KB, evitando bloqueio de atualizações e falhas de instalação/execução nesses dispositivos.

## ADDED Requirements

### Requirement: Release artifact is 16 KB page-size compatible
Builds de release do app Android (AAB/APK destinado à Google Play com target Android 15 ou superior) MUST ser compatíveis com tamanhos de página de memória de 16 KB em ABIs de 64 bits (`arm64-v8a` e, se presentes, `x86_64`).

#### Scenario: Shared libraries meet 16 KB ELF alignment
- **WHEN** um AAB/APK de release contém bibliotecas nativas (`.so`) para ABIs de 64 bits
- **THEN** os segmentos LOAD ELF dessas bibliotecas MUST estar alinhados a no mínimo 16 KB (`2**14` ou superior)

#### Scenario: Uncompressed native libs meet 16 KB ZIP alignment
- **WHEN** o pacote de release empacota bibliotecas nativas sem compactação no ZIP/APK
- **THEN** essas bibliotecas MUST estar alinhadas no arquivo ZIP em limite de 16 KB, de forma que a verificação `zipalign` com página 16 KB passe com sucesso

#### Scenario: Bundle requests 16 KB page alignment
- **WHEN** um Android App Bundle de release é inspecionado quanto à configuração de alinhamento de página
- **THEN** a configuração MUST indicar alinhamento de página de 16 KB (não 4 KB)

### Requirement: Toolchain produces 16 KB-compatible packaging by default
A configuração de build Android do app MUST usar empacotamento e versões de toolchain que produzam pacotes compatíveis com 16 KB sem depender de compactação legada de bibliotecas nativas como solução permanente.

#### Scenario: Non-legacy JNI packaging for release
- **WHEN** o módulo Android do app é configurado para build de release
- **THEN** o empacotamento de `jniLibs` MUST NÃO usar packaging legado que compacta bibliotecas nativas apenas para mascarar desalinhamento

#### Scenario: AGP meets Play 16 KB floor
- **WHEN** o projeto Android resolve o Android Gradle Plugin para builds de release
- **THEN** a versão do AGP MUST ser 8.5.1 ou superior

### Requirement: Incompatible native dependencies are upgraded or removed
Se alguma biblioteca nativa pré-compilada (engine Flutter, plugin ou SDK) impedir a compatibilidade com 16 KB, o projeto MUST atualizar para uma versão compatível ou remover a dependência antes de publicar o release de compliance.

#### Scenario: Unaligned library blocks release
- **WHEN** a verificação de alinhamento reporta uma `.so` de 64 bits como incompatível com 16 KB
- **THEN** o mantenedor MUST NÃO publicar esse artefato como release de compliance até a biblioteca ser atualizada/recompilada e a verificação passar

### Requirement: App remains usable after 16 KB-compatible rebuild
Após gerar um artefato compatível com 16 KB, o app MUST continuar abrindo e permitindo o fluxo principal de cálculo em dispositivos Android suportados, sem regressão bloqueante causada apenas pelo alinhamento/rebuild.

#### Scenario: Cold start after compliant rebuild
- **WHEN** o usuário abre o app construído com o pacote compatível com 16 KB
- **THEN** o app MUST iniciar a UI principal sem crash atribuível ao empacotamento ou alinhamento de 16 KB

#### Scenario: Core calculation flow still works
- **WHEN** o usuário preenche os dados necessários e solicita o cálculo de rescisão
- **THEN** o sistema MUST apresentar o resultado do cálculo como antes do rebuild de compliance
