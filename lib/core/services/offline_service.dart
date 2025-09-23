import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/connectivity_utils.dart';
import '../utils/pro_utils.dart';
import '../../domain/entities/calculation_history.dart';

class OfflineService {
  static const String _offlineCacheKey = 'offline_cache';
  static const String _pendingSyncKey = 'pending_sync';

  static Future<bool> isOfflineMode() async {
    final isOffline = await ConnectivityUtils.isOfflineMode();
    final isPro = await ProUtils.isProUser();

    // Modo offline completo apenas para usuários PRO
    return isOffline && isPro;
  }

  static Future<void> cacheCalculation(CalculationHistory calculation) async {
    final isPro = await ProUtils.isProUser();
    if (!isPro) return;

    final cache = await _getOfflineCache();

    // Adicionar ao cache offline
    cache.insert(0, calculation);

    // Manter apenas os últimos 50 cálculos no cache
    if (cache.length > 50) {
      cache.removeRange(50, cache.length);
    }

    await _saveOfflineCache(cache);
  }

  static Future<List<CalculationHistory>> getOfflineCalculations() async {
    final isPro = await ProUtils.isProUser();
    if (!isPro) return [];

    return await _getOfflineCache();
  }

  static Future<void> syncWhenOnline() async {
    final isPro = await ProUtils.isProUser();
    if (!isPro) return;

    final isOnline = !(await ConnectivityUtils.isOfflineMode());
    if (!isOnline) return;

    // Sincronizar cache offline com histórico principal
    final pendingSync = await _getPendingSync();

    // Adicionar cálculos pendentes ao histórico principal
    for (final calculation in pendingSync) {
      // Aqui você implementaria a lógica de sincronização
      // Por enquanto, apenas limpar o cache
      // print('Sincronizando cálculo: ${calculation.id}'); // Removido para produção
      // Usar a variável calculation para evitar warning
      if (calculation.id.isNotEmpty) {
        // Lógica de sincronização será implementada aqui
      }
    }

    // Limpar cache offline após sincronização
    await _clearOfflineCache();
    await _clearPendingSync();
  }

  static Future<void> addToPendingSync(CalculationHistory calculation) async {
    final prefs = await SharedPreferences.getInstance();
    final pending = await _getPendingSync();

    pending.add(calculation);

    final pendingJson = pending.map((calc) => jsonEncode(calc.toJson())).toList();
    await prefs.setStringList(_pendingSyncKey, pendingJson);
  }

  static Future<List<CalculationHistory>> _getOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = prefs.getStringList(_offlineCacheKey) ?? [];

    return cacheJson.map((json) => CalculationHistory.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> _saveOfflineCache(List<CalculationHistory> cache) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheJson = cache.map((calc) => jsonEncode(calc.toJson())).toList();
    await prefs.setStringList(_offlineCacheKey, cacheJson);
  }

  static Future<List<CalculationHistory>> _getPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getStringList(_pendingSyncKey) ?? [];

    return pendingJson.map((json) => CalculationHistory.fromJson(jsonDecode(json))).toList();
  }

  static Future<void> _clearOfflineCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineCacheKey);
  }

  static Future<void> _clearPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSyncKey);
  }
}
