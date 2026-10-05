import 'package:shared_preferences/shared_preferences.dart';

class AsoAnalytics {
  static const String _installSourceKey = 'install_source';
  static const String _firstOpenKey = 'first_open';
  static const String _sessionCountKey = 'session_count';

  static Future<void> initialize() async {
    await _trackInstallSource();
    await _trackFirstOpen();
    await _incrementSessionCount();
  }

  static Future<void> _trackInstallSource() async {
    final prefs = await SharedPreferences.getInstance();
    final installSource = prefs.getString(_installSourceKey);

    if (installSource == null) {
      // Detectar fonte de instalação
      final source = await _detectInstallSource();
      await prefs.setString(_installSourceKey, source);
    }
  }

  static Future<String> _detectInstallSource() async {
    // Em um app real, você usaria referrers do Google Play
    // Por enquanto, vamos simular diferentes fontes
    return 'google_play_search'; // ou 'google_play_browse', 'referral', etc.
  }

  static Future<void> _trackFirstOpen() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstOpen = prefs.getBool(_firstOpenKey) ?? true;

    if (isFirstOpen) {
      await prefs.setBool(_firstOpenKey, false);
    }
  }

  static Future<void> _incrementSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCount = prefs.getInt(_sessionCountKey) ?? 0;
    await prefs.setInt(_sessionCountKey, sessionCount + 1);

    // Log local para debug (removido para produção)
  }

  // Eventos específicos para ASO
  static Future<void> trackCalculation({
    required String terminationType,
    required double salary,
    required bool isProUser,
  }) async {
    // Log local para debug (removido para produção)
  }

  static Future<void> trackPdfExport({required bool isProUser, required String terminationType}) async {
    // Log local para debug (removido para produção)
  }

  static Future<void> trackShare({
    required String method,
    required String terminationType,
    required bool isProUser,
  }) async {
    // Log local para debug (removido para produção)
  }

  static Future<void> trackSupport({required String channel, required bool isProUser}) async {
    // Log local para debug (removido para produção)
  }

  // Métricas ASO específicas
  static Future<void> trackUserEngagement({
    required String action,
    required String screen,
    required int timeSpent,
  }) async {
    // Log local para debug (removido para produção)
  }

  static Future<void> trackFeatureUsage({
    required String feature,
    required bool isProUser,
    required bool success,
  }) async {
    // Log local para debug (removido para produção)
  }

  static Future<void> trackRetention({required int daysSinceInstall, required bool isProUser}) async {
    // Log local para debug (removido para produção)
  }

  // Métricas de conversão
  static Future<Map<String, dynamic>> getConversionMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionCount = prefs.getInt(_sessionCountKey) ?? 0;

    return {'session_count': sessionCount};
  }
}
