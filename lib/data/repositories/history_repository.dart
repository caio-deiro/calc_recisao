import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/calculation_history.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/exceptions/app_exceptions.dart';

/// Repositório responsável pelo gerenciamento do histórico de cálculos.
///
/// Armazena e recupera cálculos de rescisão usando SharedPreferences.
/// Guarda no máximo [AppConstants.maxHistorySize] itens (FIFO).
class HistoryRepository {
  static const String _historyKey = 'calculation_history';

  final SharedPreferences? _prefs;

  /// Cria uma instância do repositório.
  ///
  /// [prefs] - Instância de SharedPreferences (opcional, para testes)
  HistoryRepository({SharedPreferences? prefs}) : _prefs = prefs;

  /// Recupera todo o histórico de cálculos, ordenado por data (mais recente primeiro).
  ///
  /// Retorna lista vazia se não houver histórico.
  /// Ignora itens inválidos no histórico.
  ///
  /// Throws [StorageException] se houver erro ao acessar o armazenamento
  Future<List<CalculationHistory>> getHistory() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      return historyJson
          .map((json) {
            try {
              return CalculationHistory.fromJson(jsonDecode(json));
            } catch (e) {
              AppLogger.warning('Erro ao decodificar item do histórico', e);
              return null;
            }
          })
          .whereType<CalculationHistory>()
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao obter histórico', e, stackTrace);
      throw StorageException('Erro ao carregar histórico de cálculos', originalError: e);
    }
  }

  /// Salva um novo cálculo no histórico.
  ///
  /// Adiciona no início da lista; ao exceder o limite, descarta o mais antigo.
  ///
  /// [calculation] - Cálculo a ser salvo
  /// Throws [StorageException] se houver erro ao salvar
  Future<void> saveCalculation(CalculationHistory calculation) async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final history = await getHistory();

      // Adicionar novo cálculo no início
      history.insert(0, calculation);

      // FIFO: o histórico está ordenado do mais recente ao mais antigo
      if (history.length > AppConstants.maxHistorySize) {
        history.removeRange(AppConstants.maxHistorySize, history.length);
      }

      // Salvar no SharedPreferences
      final historyJson = history.map((calc) => jsonEncode(calc.toJson())).toList();

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao salvar cálculo no histórico', e, stackTrace);
      throw StorageException('Erro ao salvar cálculo no histórico', originalError: e);
    }
  }

  /// Remove um cálculo específico do histórico.
  ///
  /// [id] - ID do cálculo a ser removido
  /// Não faz nada se o cálculo não existir
  Future<void> deleteCalculation(String id) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((calc) => calc.id == id);

    final historyJson = history.map((calc) => jsonEncode(calc.toJson())).toList();

    await prefs.setStringList(_historyKey, historyJson);
  }

  /// Remove todo o histórico de cálculos.
  ///
  /// Esta ação não pode ser desfeita.
  Future<void> clearHistory() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  /// Adiciona ou atualiza uma nota em um cálculo existente.
  ///
  /// [id] - ID do cálculo
  /// [note] - Texto da nota
  /// Não faz nada se o cálculo não existir
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
