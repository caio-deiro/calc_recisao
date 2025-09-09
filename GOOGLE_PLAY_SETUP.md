# Configuração do Google Play Console para Compras In-App

## 📋 Passos para Configurar Compras In-App no Google Play Console

### 1. **Criar o Produto no Google Play Console**

1. Acesse o [Google Play Console](https://play.google.com/console)
2. Selecione seu app "Calculadora de Rescisão CLT"
3. Vá para **Monetização** > **Produtos** > **Assinaturas**
4. Clique em **Criar assinatura**

### 2. **Configurar a Assinatura PRO**

**ID do Produto:** `calc_recisao_pro_monthly`

**Configurações:**
- **Nome:** "Versão PRO - Calculadora de Rescisão CLT"
- **Descrição:** "Remova anúncios e tenha acesso a recursos exclusivos como exportação PDF, histórico ilimitado e suporte prioritário."
- **Preço:** R$ 9,90/mês (ou valor desejado)
- **Período de teste:** 7 dias (opcional)
- **Período de carência:** 3 dias (opcional)

### 3. **Configurar Testes**

1. Vá para **Configuração** > **Testes** > **Testadores de licença**
2. Adicione emails de teste (incluindo o seu)
3. Vá para **Configuração** > **Testes** > **Testadores de assinatura**
4. Adicione os mesmos emails

### 4. **Configurar Conta de Desenvolvedor**

1. Vá para **Configuração** > **Conta de desenvolvedor**
2. Configure informações de pagamento
3. Adicione informações fiscais necessárias

### 5. **Upload da Versão de Teste**

1. Crie uma versão de teste (Internal Testing)
2. Faça upload do APK/AAB com as compras in-app
3. Adicione testadores
4. Teste as compras antes de publicar

## 🔧 Configurações Técnicas

### **IDs de Produto Configurados:**
```dart
// Em lib/core/services/purchase_service.dart
static const String _proProductId = 'calc_recisao_pro_monthly';
```

### **Permissões Adicionadas:**
```xml
<!-- Em android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="com.android.vending.BILLING" />
```

### **Recursos do Produto:**
```xml
<!-- Em android/app/src/main/res/values/billing_products.xml -->
<string name="pro_product_id">calc_recisao_pro_monthly</string>
<string name="pro_price">R$ 9,90</string>
```

## 🧪 Como Testar

### **1. Teste Local (Debug)**
- O app simula compras automaticamente em modo debug
- Use os botões "Fazer Upgrade" e "Restaurar Compra"

### **2. Teste com Google Play**
1. Faça upload de uma versão de teste
2. Adicione-se como testador
3. Instale a versão de teste
4. Teste as compras reais

### **3. Verificar Status PRO**
```dart
// Verificar se usuário é PRO
bool isPro = await ProUtils.isProUser();

// Verificar se deve mostrar anúncios
bool shouldShowAds = await ProUtils.shouldShowAds();
```

## 📱 Funcionalidades PRO

Quando o usuário compra a versão PRO:

✅ **Sem Anúncios** - Remove todos os anúncios do app
✅ **Exportação PDF** - Gera relatórios profissionais
✅ **Histórico Ilimitado** - Salva todos os cálculos
✅ **Modo Offline** - Funciona sem internet
✅ **Suporte Prioritário** - Atendimento preferencial

## 🚨 Importante

1. **Nunca publique** sem testar as compras primeiro
2. **Configure preços** adequados para seu mercado
3. **Teste em dispositivos reais** antes de publicar
4. **Monitore** as compras no Google Play Console
5. **Mantenha backup** das configurações

## 🔍 Troubleshooting

### **Compras não funcionam:**
- Verifique se o produto está ativo no Google Play Console
- Confirme se o ID do produto está correto
- Teste com conta de testador configurada

### **Erro de permissão:**
- Verifique se a permissão BILLING está no AndroidManifest.xml
- Confirme se o app está assinado corretamente

### **Produto não encontrado:**
- Verifique se o produto está publicado no Google Play Console
- Confirme se o app está na mesma conta do Google Play Console
