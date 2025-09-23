import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/calculation_history.dart';
import '../../core/utils/pro_utils.dart';
import '../../core/services/offline_service.dart';

class HistoryRepository {
  static const String _historyKey = 'calculation_history';

  final SharedPreferences? _prefs;

  HistoryRepository({SharedPreferences? prefs}) : _prefs = prefs;

  Future<List<CalculationHistory>> getHistory() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];

    return historyJson.map((json) => CalculationHistory.fromJson(jsonDecode(json))).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> saveCalculation(CalculationHistory calculation) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final history = await getHistory();

    // Adicionar novo cálculo no início
    history.insert(0, calculation);

    // Manter apenas os cálculos permitidos baseado no status PRO
    final maxSize = await ProUtils.getMaxHistorySize();
    if (history.length > maxSize) {
      history.removeRange(maxSize, history.length);
    }

    // Salvar no SharedPreferences
    final historyJson = history.map((calc) => jsonEncode(calc.toJson())).toList();

    await prefs.setStringList(_historyKey, historyJson);

    // Cache offline para usuários PRO
    await OfflineService.cacheCalculation(calculation);
  }

  Future<void> deleteCalculation(String id) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((calc) => calc.id == id);

    final historyJson = history.map((calc) => jsonEncode(calc.toJson())).toList();

    await prefs.setStringList(_historyKey, historyJson);
  }

  Future<void> clearHistory() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> addNote(String id, String note) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final history = await getHistory();

    final index = history.indexWhere((calc) => calc.id == id);
    if (index != -1) {
      final updatedCalc = CalculationHistory(
        id: history[index].id,
        input: history[index].input,
        result: history[index].result,
        terminationType: history[index].terminationType,
        timestamp: history[index].timestamp,
        note: note,
      );

      history[index] = updatedCalc;

      final historyJson = history.map((calc) => jsonEncode(calc.toJson())).toList();

      await prefs.setStringList(_historyKey, historyJson);
    }
  }
}
