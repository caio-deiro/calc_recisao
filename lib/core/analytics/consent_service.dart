import 'package:shared_preferences/shared_preferences.dart';

/// Estado persistido do consentimento único (B1-11).
class ConsentService {
  ConsentService._();

  static const String decidedKey = 'consent_decided';
  static const String analyticsEnabledKey = 'analytics_enabled';
  static const String firstResultKey = 'first_result_done';

  static Future<bool> isDecided() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(decidedKey) ?? false;
  }

  /// Analytics e anúncios personalizados dependem do mesmo aceite.
  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(decidedKey) ?? false) && (prefs.getBool(analyticsEnabledKey) ?? false);
  }

  static Future<void> markFirstResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(firstResultKey, true);
  }

  /// O aviso só aparece depois do primeiro resultado e uma única vez.
  static Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(firstResultKey) ?? false) && !(prefs.getBool(decidedKey) ?? false);
  }

  static Future<void> saveDecision({required bool accepted}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(analyticsEnabledKey, accepted);
    await prefs.setBool(decidedKey, true);
  }
}
