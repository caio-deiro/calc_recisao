import 'package:url_launcher/url_launcher.dart';

class AsoDeepLinks {
  // URLs para diferentes funcionalidades do app
  static const String _baseUrl = 'https://calcrescisao.com';

  // Deep links para funcionalidades específicas
  static const String _calculationUrl = '$_baseUrl/calculate';
  static const String _proUrl = '$_baseUrl/pro';
  static const String _supportUrl = '$_baseUrl/support';
  static const String _faqUrl = '$_baseUrl/faq';

  // Métodos para gerar links otimizados para ASO
  static String generateCalculationLink({required String terminationType, required double salary}) {
    return '$_calculationUrl?type=$terminationType&salary=$salary';
  }

  static String generateProUpgradeLink({required String source}) {
    return '$_proUrl?source=$source&utm_campaign=pro_upgrade';
  }

  static String generateSupportLink({required String channel}) {
    return '$_supportUrl?channel=$channel';
  }

  // Métodos para abrir links externos
  static Future<void> openCalculationLink({required String terminationType, required double salary}) async {
    final url = generateCalculationLink(terminationType: terminationType, salary: salary);
    await _launchUrl(url);
  }

  static Future<void> openProUpgradeLink({required String source}) async {
    final url = generateProUpgradeLink(source: source);
    await _launchUrl(url);
  }

  static Future<void> openSupportLink({required String channel}) async {
    final url = generateSupportLink(channel: channel);
    await _launchUrl(url);
  }

  static Future<void> openFaqLink() async {
    await _launchUrl(_faqUrl);
  }

  // Método para abrir URL genérica
  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Métodos para compartilhamento otimizado para ASO
  static String generateShareText({required String terminationType, required double salary, required double result}) {
    return '''
💰 Calculei minha rescisão CLT com a Calculadora Rescisão CLT!

📊 Resultado: R\$ ${result.toStringAsFixed(2)}
💼 Tipo: $terminationType
💵 Salário: R\$ ${salary.toStringAsFixed(2)}

📱 Baixe grátis: https://play.google.com/store/apps/details?id=com.calcrescisao.app

#RescisãoCLT #FGTS #INSS #Trabalhista #Calculadora
''';
  }

  static String generateProShareText() {
    return '''
⭐ Upgrade para PRO da Calculadora Rescisão CLT!

✅ Sem anúncios
✅ Exportação PDF
✅ Histórico ilimitado
✅ Modo offline
✅ Suporte prioritário

💰 Apenas R\$ 4,90/mês

📱 Baixe: https://play.google.com/store/apps/details?id=com.calcrescisao.app

#RescisãoCLT #PRO #Trabalhista
''';
  }

  // Métodos para URLs de referência
  static String generateReferralLink({required String userId, required String campaign}) {
    return '$_baseUrl/ref?user=$userId&campaign=$campaign';
  }

  static String generateSocialMediaLink({required String platform, required String content}) {
    final encodedContent = Uri.encodeComponent(content);
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return 'https://wa.me/?text=$encodedContent';
      case 'telegram':
        return 'https://t.me/share/url?url=$encodedContent';
      case 'twitter':
        return 'https://twitter.com/intent/tweet?text=$encodedContent';
      case 'facebook':
        return 'https://www.facebook.com/sharer/sharer.php?u=$encodedContent';
      default:
        return '$_baseUrl/share?platform=$platform&content=$encodedContent';
    }
  }

  // Métodos para tracking de conversão
  static String generateConversionLink({required String source, required String medium, required String campaign}) {
    return '$_baseUrl/convert?utm_source=$source&utm_medium=$medium&utm_campaign=$campaign';
  }

  // Métodos para URLs de retenção
  static String generateRetentionLink({required String userId, required int daysSinceInstall}) {
    return '$_baseUrl/retention?user=$userId&days=$daysSinceInstall';
  }
}
