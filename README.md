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
