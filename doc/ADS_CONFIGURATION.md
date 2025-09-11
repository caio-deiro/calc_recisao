# Configuração de Anúncios - Calculadora de Rescisão CLT

## 📱 Visão Geral

Este documento detalha a configuração e implementação dos anúncios no app, incluindo estratégias de monetização e controle para usuários PRO.

## 🎯 Estratégia de Monetização

### Modelo Freemium
- **Versão Gratuita:** Anúncios exibidos para monetização
- **Versão PRO:** Anúncios removidos (R$ 4,90/mês)
- **Conversão:** Anúncios como gatilho para upgrade

### Tipos de Anúncios
1. **Banner Ads** - Parte inferior das telas
2. **Interstitial Ads** - Entre ações importantes
3. **App Open Ads** - Ao abrir o app (futuro)

## 🔧 Configuração Técnica

### Google AdMob
- **Plataforma:** Google AdMob
- **SDK:** google_mobile_ads ^6.0.0
- **Inicialização:** No main.dart do app

### IDs de Anúncios

#### IDs de Teste (Desenvolvimento)
```dart
// Banner
static const String bannerTestId = 'ca-app-pub-3940256099942544/6300978111';

// Interstitial
static const String interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';

// App Open
static const String appOpenTestId = 'ca-app-pub-3940256099942544/3419835294';
```

#### IDs de Produção (Substituir)
```dart
// Substituir pelos IDs reais do AdMob
static const String bannerProductionId = 'ca-app-pub-XXXXX/XXXXX';
static const String interstitialProductionId = 'ca-app-pub-XXXXX/XXXXX';
static const String appOpenProductionId = 'ca-app-pub-XXXXX/XXXXX';
```

## 📍 Localização dos Anúncios

### Banner Ads
- **Tela inicial:** Parte inferior, após conteúdo
- **Tela de resultados:** Parte inferior, após resumo
- **Tela de histórico:** Parte inferior, após lista
- **Tela PRO:** Não exibido (usuários PRO)

### Interstitial Ads
- **Após cálculo:** Cooldown de 3 minutos
- **Entre navegações:** Apenas em ações importantes
- **Frequência:** Máximo 1 por sessão de uso

## 🎛️ Controle de Exibição

### Lógica de Controle
```dart
// Verificar se deve mostrar anúncios
static Future<bool> shouldShowAds() async {
  final isPro = await ProUtils.isProUser();
  return !isPro; // Mostra anúncios apenas para usuários gratuitos
}
```

### Implementação
- **AdManager:** Classe centralizada para gerenciar anúncios
- **ProUtils:** Verificação de status PRO
- **Condicionais:** Anúncios só aparecem para usuários gratuitos

## 📊 Métricas e Performance

### KPIs de Anúncios
- **eCPM:** Receita por mil impressões
- **Fill Rate:** Taxa de preenchimento de anúncios
- **CTR:** Taxa de cliques
- **Revenue:** Receita total gerada

### Métricas de Conversão
- **Conversão por anúncio:** Usuários que fazem upgrade após ver anúncios
- **Churn por anúncios:** Usuários que desinstalam por excesso de anúncios
- **Engagement:** Tempo de uso vs frequência de anúncios

## ⚙️ Configurações Avançadas

### Cooldown de Interstitial
```dart
static const int _interstitialCooldownMinutes = 3;
```

### Tamanhos de Banner
```dart
// Banner padrão
size: AdSize.banner

// Banner adaptativo (futuro)
size: AdSize.adaptiveBanner
```

### Tratamento de Erros
```dart
onAdFailedToLoad: (ad, error) {
  ad.dispose();
  debugPrint('Banner ad failed to load: $error');
}
```

## 🚫 Controle para Usuários PRO

### Remoção Completa
- **Banner ads:** Não carregados
- **Interstitial ads:** Não exibidos
- **App open ads:** Não inicializados
- **Verificação:** Sempre antes de carregar anúncios

### Implementação
```dart
static Future<BannerAd?> createBannerAd() async {
  final shouldShowAds = await ProUtils.shouldShowAds();
  if (!shouldShowAds) return null; // Não cria anúncio para PRO
  
  // Cria anúncio apenas para usuários gratuitos
  return BannerAd(...);
}
```

## 📈 Otimização de Receita

### Estratégias
1. **Posicionamento:** Anúncios em locais estratégicos
2. **Frequência:** Balance entre receita e experiência
3. **Qualidade:** Anúncios relevantes para o público
4. **Conversão:** Anúncios como gatilho para PRO

### A/B Testing
- **Frequência:** Testar diferentes cooldowns
- **Posicionamento:** Testar locais alternativos
- **Tipos:** Testar diferentes formatos
- **Conversão:** Medir impacto na conversão PRO

## 🔍 Troubleshooting

### Problemas Comuns

#### Anúncios não aparecem
- Verificar IDs do AdMob
- Confirmar inicialização do SDK
- Verificar status PRO do usuário
- Testar em dispositivo real

#### Anúncios aparecem para usuários PRO
- Verificar lógica de `shouldShowAds()`
- Confirmar status PRO salvo corretamente
- Testar restauração de compras

#### Performance ruim
- Otimizar carregamento de anúncios
- Implementar cache inteligente
- Reduzir frequência se necessário

## 📱 Configuração por Plataforma

### Android
```xml
<!-- AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXX~XXXXX"/>
```

### iOS (Futuro)
```xml
<!-- Info.plist -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXX~XXXXX</string>
```

## 🎯 Próximos Passos

### Curto Prazo
- [ ] Substituir IDs de teste pelos reais
- [ ] Implementar App Open Ads
- [ ] Otimizar posicionamento

### Médio Prazo
- [ ] A/B testing de frequência
- [ ] Análise de métricas detalhadas
- [ ] Otimização de eCPM

### Longo Prazo
- [ ] Anúncios nativos personalizados
- [ ] Integração com outras redes
- [ ] IA para otimização automática

## 📞 Suporte

Para questões técnicas sobre anúncios, consulte a documentação do Google AdMob ou entre em contato com a equipe de desenvolvimento.
