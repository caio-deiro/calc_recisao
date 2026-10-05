import 'package:shared_preferences/shared_preferences.dart';

/// Remove do `SharedPreferences` as chaves da antiga versão PRO (B1-05).
///
/// Idempotente: `remove` de chave ausente não faz nada, então pode rodar a
/// cada inicialização. O histórico e as demais chaves não são tocados.
class LegacyCleanup {
  LegacyCleanup._();

  static const List<String> legacyKeys = [
    'is_pro_user',
    'pro_purchase_date',
    'pro_purchase_id',
    'pro_purchase_token',
    'offline_cache',
    'pending_sync',
    'pro_conversion',
  ];

  static Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in legacyKeys) {
      await prefs.remove(key);
    }
  }
}
