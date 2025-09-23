import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class AsoAbTesting {
  static const String _abTestGroupKey = 'aso_ab_test_group';

  // Variantes dos testes
  static const String _variantA = 'A';
  static const String _variantB = 'B';
  static const String _variantC = 'C';

  static Future<void> initialize() async {
    await _assignTestGroups();
  }

  static Future<void> _assignTestGroups() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar se já foi atribuído
    if (prefs.getString(_abTestGroupKey) != null) return;

    // Atribuir grupos aleatoriamente
    final random = Random();
    final group = random.nextInt(3); // 0, 1, 2

    String groupName;
    switch (group) {
      case 0:
        groupName = _variantA;
        break;
      case 1:
        groupName = _variantB;
        break;
      default:
        groupName = _variantC;
        break;
    }

    await prefs.setString(_abTestGroupKey, groupName);
  }

  // Teste A/B para layout da tela inicial
  static Future<String> getHomeScreenLayout() async {
    // 50% para cada variante
    final random = Random();
    final isVariantB = random.nextBool();

    return isVariantB ? _variantB : _variantA;
  }

  // Teste A/B para CTA de upgrade PRO
  static Future<String> getProUpgradeCta() async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    // Variantes baseadas no grupo
    switch (group) {
      case _variantA:
        return 'upgrade_cta_urgent'; // "Upgrade agora e economize!"
      case _variantB:
        return 'upgrade_cta_benefit'; // "Desbloqueie recursos PRO"
      case _variantC:
        return 'upgrade_cta_social'; // "Junte-se a milhares de usuários PRO"
      default:
        return 'upgrade_cta_default';
    }
  }

  // Teste A/B para fluxo de cálculo
  static Future<String> getCalculationFlow() async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    switch (group) {
      case _variantA:
        return 'calculation_flow_simple'; // Fluxo simplificado
      case _variantB:
        return 'calculation_flow_detailed'; // Fluxo detalhado
      case _variantC:
        return 'calculation_flow_guided'; // Fluxo guiado
      default:
        return 'calculation_flow_default';
    }
  }

  // Teste A/B para prompt de compartilhamento
  static Future<String> getSharePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    switch (group) {
      case _variantA:
        return 'share_prompt_immediate'; // Prompt imediato
      case _variantB:
        return 'share_prompt_delayed'; // Prompt após 3 segundos
      case _variantC:
        return 'share_prompt_contextual'; // Prompt contextual
      default:
        return 'share_prompt_default';
    }
  }

  // Teste A/B para cores do tema
  static Future<String> getThemeColors() async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    switch (group) {
      case _variantA:
        return 'theme_blue'; // Azul padrão
      case _variantB:
        return 'theme_green'; // Verde
      case _variantC:
        return 'theme_purple'; // Roxo
      default:
        return 'theme_default';
    }
  }

  // Teste A/B para posicionamento de anúncios
  static Future<String> getAdPlacement() async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    switch (group) {
      case _variantA:
        return 'ad_placement_bottom'; // Anúncio no rodapé
      case _variantB:
        return 'ad_placement_interstitial'; // Anúncio intersticial
      case _variantC:
        return 'ad_placement_native'; // Anúncio nativo
      default:
        return 'ad_placement_default';
    }
  }

  // Teste A/B para texto de botões
  static Future<String> getButtonText(String buttonType) async {
    final prefs = await SharedPreferences.getInstance();
    final group = prefs.getString(_abTestGroupKey) ?? _variantA;

    switch (buttonType) {
      case 'calculate':
        switch (group) {
          case _variantA:
            return 'Calcular Rescisão';
          case _variantB:
            return 'Calcular Agora';
          case _variantC:
            return 'Ver Resultado';
          default:
            return 'Calcular';
        }
      case 'upgrade':
        switch (group) {
          case _variantA:
            return 'Fazer Upgrade';
          case _variantB:
            return 'Tornar-se PRO';
          case _variantC:
            return 'Desbloquear PRO';
          default:
            return 'Upgrade';
        }
      case 'share':
        switch (group) {
          case _variantA:
            return 'Compartilhar';
          case _variantB:
            return 'Enviar Resultado';
          case _variantC:
            return 'Compartilhar Resultado';
          default:
            return 'Compartilhar';
        }
      default:
        return buttonType;
    }
  }

  // Métodos para tracking de conversão por variante
  static Future<void> trackConversion({
    required String testName,
    required String variant,
    required String action,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${testName}_${variant}_$action';
    final count = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, count + 1);
  }

  // Métodos para obter métricas de conversão
  static Future<Map<String, dynamic>> getConversionMetrics(String testName) async {
    final prefs = await SharedPreferences.getInstance();

    final variantAConversions = prefs.getInt('${testName}_${_variantA}_conversion') ?? 0;
    final variantBConversions = prefs.getInt('${testName}_${_variantB}_conversion') ?? 0;
    final variantCConversions = prefs.getInt('${testName}_${_variantC}_conversion') ?? 0;

    final variantAViews = prefs.getInt('${testName}_${_variantA}_view') ?? 0;
    final variantBViews = prefs.getInt('${testName}_${_variantB}_view') ?? 0;
    final variantCViews = prefs.getInt('${testName}_${_variantC}_view') ?? 0;

    return {
      'variant_a': {
        'conversions': variantAConversions,
        'views': variantAViews,
        'conversion_rate': variantAViews > 0 ? variantAConversions / variantAViews : 0.0,
      },
      'variant_b': {
        'conversions': variantBConversions,
        'views': variantBViews,
        'conversion_rate': variantBViews > 0 ? variantBConversions / variantBViews : 0.0,
      },
      'variant_c': {
        'conversions': variantCConversions,
        'views': variantCViews,
        'conversion_rate': variantCViews > 0 ? variantCConversions / variantCViews : 0.0,
      },
    };
  }

  // Método para determinar a variante vencedora
  static Future<String> getWinningVariant(String testName) async {
    final metrics = await getConversionMetrics(testName);

    double bestRate = 0.0;
    String winningVariant = _variantA;

    for (final entry in metrics.entries) {
      final rate = entry.value['conversion_rate'] as double;
      if (rate > bestRate) {
        bestRate = rate;
        winningVariant = entry.key;
      }
    }

    return winningVariant;
  }
}
