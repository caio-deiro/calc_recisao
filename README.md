# Calculadora de Rescisão CLT

Aplicação Flutter para cálculo estimativo de verbas rescisórias conforme a Consolidação das Leis do Trabalho (CLT).

## 🚀 Funcionalidades

- **Cálculo de saldo de salário** proporcional aos dias trabalhados
- **Aviso prévio indenizado** com adicional por tempo de serviço
- **13º salário proporcional** baseado nos meses trabalhados
- **Férias vencidas e proporcionais** incluindo 1/3 constitucional
- **FGTS e multa de 40%** quando aplicável
- **Descontos INSS e IRRF** com tabelas atualizadas
- **Suporte a diferentes tipos de rescisão** (sem justa causa, pedido de demissão, prazo determinado)

## 📱 Como Executar

### Pré-requisitos
- Flutter SDK >= 3.22
- Dart >= 3.8.1
- Android Studio / VS Code

### Instalação
1. Clone o repositório
2. Execute `flutter pub get` para instalar dependências
3. Execute `flutter run` para iniciar a aplicação

## ⚙️ Configuração

### AdMob
Para configurar anúncios:

1. Edite `lib/core/ads/ad_ids.dart`
2. Substitua os IDs de teste pelos IDs de produção:
   ```dart
   static const String bannerProductionId = 'ca-app-pub-XXXXX/XXXXX';
   static const String interstitialProductionId = 'ca-app-pub-XXXXX/XXXXX';
   ```

3. Altere a flag `kRemoveAds` para `false` quando quiser exibir anúncios

### Tabelas Fiscais
As tabelas INSS e IRRF estão configuradas em `assets/config/tax_tables.json` e podem ser atualizadas conforme necessário.

## 🧪 Testes

Execute os testes com:
```bash
flutter test
```

### Testes Unitários
- `test/unit/calculate_termination_test.dart` - Testa a lógica de cálculo

## 📋 Casos de Uso

### Sem Justa Causa
- Empregador demite sem justificativa
- Inclui multa FGTS de 40%
- Permite saque do FGTS

### Pedido de Demissão
- Empregado pede demissão
- Sem multa FGTS
- Sem saque do FGTS

### Prazo Determinado
- Contrato por prazo determinado
- Sem multa FGTS
- Cálculo proporcional

## ⚠️ Aviso Legal

**Esta calculadora fornece estimativas com base em regras gerais da CLT. Situações específicas podem exigir outras verbas ou cálculos diferentes. Sempre consulte um profissional qualificado (contador ou advogado) antes de tomar decisões baseadas nestes cálculos.**

## 🔧 Estrutura do Projeto

```
lib/
├── core/
│   ├── ads/          # Gerenciamento de anúncios AdMob
│   ├── theme/        # Temas da aplicação
│   └── utils/        # Utilitários e formatadores
├── domain/
│   ├── entities/     # Entidades do domínio
│   └── usecases/     # Casos de uso
└── presentation/
    ├── screens/      # Telas da aplicação
    └── widgets/      # Widgets reutilizáveis
```

## 📱 Publicação na Play Store

### Configurações Android
1. Atualize `android/app/build.gradle.kts` com versão e nome do app
2. Configure ícones em `android/app/src/main/res/`
3. Atualize `android/app/src/main/AndroidManifest.xml` com permissões necessárias

### Permissões Necessárias
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Configuração AdMob
1. Adicione o ID do app no `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXX~XXXXX"/>
   ```

## 🚀 Próximas Funcionalidades

- [ ] Rescisão com justa causa
- [ ] Acordo mútuo (art. 484-A)
- [ ] Exportação para PDF
- [ ] Histórico de cálculos
- [ ] Modo offline
- [ ] Versão PRO sem anúncios

## 📞 Suporte

Para dúvidas, sugestões ou reportar problemas, entre em contato através dos canais oficiais da aplicação.

## 📄 Licença

Este projeto é desenvolvido para fins educacionais e de demonstração. Consulte as licenças das dependências utilizadas.


<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Política de Privacidade - Calculadora CLT</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            line-height: 1.6;
            color: #333;
        }
        h1 {
            color: #004080;
        }
        h2 {
            margin-top: 1.5em;
            color: #0055a5;
        }
    </style>
</head>
<body>
    <h1>Política de Privacidade</h1>
    <p><strong>Última atualização:</strong> 12 de September de 2025</p>

    <p>Este aplicativo foi desenvolvido com o objetivo de fornecer <strong>informações estimadas sobre salários, descontos legais e benefícios relacionados à Consolidação das Leis do Trabalho (CLT)</strong> no Brasil. Nosso objetivo é oferecer uma ferramenta útil, simples e acessível para simular cenários trabalhistas de forma educativa e aproximada.</p>

    <h2>1. Coleta de dados</h2>
    <p>Este aplicativo <strong>não coleta, armazena ou compartilha dados pessoais</strong> dos usuários. Todas as simulações são feitas localmente no dispositivo, sem necessidade de cadastro, login ou acesso a informações sensíveis.</p>

    <h2>2. Fontes de informação</h2>
    <p>As informações utilizadas para os cálculos são baseadas em fontes públicas e oficiais, como:</p>
    <ul>
        <li><a href="https://www.gov.br" target="_blank">https://www.gov.br</a></li>
        <li><a href="https://www.in.gov.br" target="_blank">https://www.in.gov.br</a></li>
        <li><a href="https://www.receita.fazenda.gov.br" target="_blank">https://www.receita.fazenda.gov.br</a></li>
        <li><a href="https://www.previdencia.gov.br" target="_blank">https://www.previdencia.gov.br</a></li>
        <li><a href="https://www.trabalho.gov.br" target="_blank">https://www.trabalho.gov.br</a></li>
    </ul>

    <h2>3. Exoneração de responsabilidade</h2>
    <p>Este aplicativo <strong>não é afiliado, associado ou autorizado por nenhum órgão do governo federal, estadual ou municipal</strong>. As informações fornecidas são aproximadas e <strong>não substituem orientação profissional contábil, jurídica ou governamental</strong>.</p>
    <p>O uso do aplicativo é de responsabilidade do usuário, e recomendamos consultar fontes oficiais e profissionais para decisões importantes.</p>

    <h2>4. Contato</h2>
    <p>Caso tenha dúvidas ou sugestões, entre em contato com o desenvolvedor pelo e-mail:</p>
    <p><strong>caioguimaraes12@outlook.com</strong></p>
</body>
</html>

