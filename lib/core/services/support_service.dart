import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class SupportService {
  static const String _supportSubject = 'Suporte - Calculadora de Rescisão CLT';

  static Future<void> openSupportChannel() async {
    final email = AppConstants.supportEmail;
    final subject = _supportSubject;
    final body = '''
Olá! Tenho uma dúvida sobre a Calculadora de Rescisão CLT.

[Descreva sua dúvida ou problema aqui]

Obrigado!
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openFeatureRequest() async {
    final email = AppConstants.supportEmail;
    const subject = 'Sugestão de Funcionalidade';
    const body = '''
Olá! Gostaria de sugerir:

[Descreva sua sugestão aqui]

Obrigado!
''';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static String getBasicSupportResponseTime() {
    return '3-5 dias úteis';
  }
}
