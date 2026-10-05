import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Destino dos eventos e da chave de coleta. Existe para que o ponto central
/// de emissão seja testável sem Firebase.
abstract class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object>? parameters);

  /// Liga/desliga a coleta de Analytics e de Crashlytics (mesma decisão).
  Future<void> setCollectionEnabled(bool enabled);
}

class FirebaseAnalyticsSink implements AnalyticsSink {
  const FirebaseAnalyticsSink();

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) {
    return FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(enabled);
  }
}
