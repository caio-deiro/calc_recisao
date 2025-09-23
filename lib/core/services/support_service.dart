import 'package:url_launcher/url_launcher.dart';
import '../utils/pro_utils.dart';

class SupportService {
  static const String _supportEmail = 'suporte@calcrescisao.com';
  static const String _proSupportEmail = 'pro@calcrescisao.com';
  static const String _supportSubject = 'Suporte - Calculadora de Rescisão CLT';
  static const String _proSupportSubject = 'Suporte PRO - Calculadora de Rescisão CLT';

  static Future<void> openSupportChannel() async {
    final isPro = await ProUtils.isProUser();

    if (isPro) {
      await _openProSupport();
    } else {
      await _openBasicSupport();
    }
  }

  static Future<void> _openProSupport() async {
    final email = _proSupportEmail;
    final subject = _proSupportSubject;
    final body = '''
Olá! Sou um usuário PRO da Calculadora de Rescisão CLT.

[Descreva sua dúvida ou problema aqui]

Informações do dispositivo:
- Versão do app: [versão]
- Dispositivo: [modelo]
- Sistema operacional: [Android/iOS]

Aguardo retorno em até 24h conforme prometido no plano PRO.

Obrigado!
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> _openBasicSupport() async {
    final email = _supportEmail;
    final subject = _supportSubject;
    final body = '''
Olá! Tenho uma dúvida sobre a Calculadora de Rescisão CLT.

[Descreva sua dúvida ou problema aqui]

Obrigado!
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openFaq() async {
    // Implementar FAQ ou abrir URL da documentação
    final faqUrl = Uri.parse('https://calcrescisao.com/faq');

    if (await canLaunchUrl(faqUrl)) {
      await launchUrl(faqUrl, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openFeatureRequest() async {
    final isPro = await ProUtils.isProUser();

    final email = isPro ? _proSupportEmail : _supportEmail;
    final subject = isPro ? 'Sugestão de Funcionalidade PRO' : 'Sugestão de Funcionalidade';
    final body =
        '''
${isPro ? 'Olá! Como usuário PRO, gostaria de sugerir:' : 'Olá! Gostaria de sugerir:'}

[Descreva sua sugestão aqui]

${isPro ? 'Como usuário PRO, espero que esta funcionalidade seja priorizada.' : ''}

Obrigado!
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String getSupportResponseTime() {
    // Em uma implementação real, isso viria de uma API
    return '24 horas';
  }

  static String getBasicSupportResponseTime() {
    return '3-5 dias úteis';
  }
}
