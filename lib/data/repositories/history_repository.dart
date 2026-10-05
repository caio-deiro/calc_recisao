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

  /// Lê as entradas gravadas: registros legíveis e as strings brutas ilegíveis.
  ///
  /// Registro que falha ao decodificar NUNCA é descartado: o dado bruto é mantido
  /// e devolvido em [_StoredHistory.unreadable]. O log não leva conteúdo do registro
  /// (B0-03), só o tipo do erro.
  Future<_StoredHistory> _read(SharedPreferences prefs) async {
    final readable = <CalculationHistory>[];
    final unreadable = <String>[];
    for (final raw in prefs.getStringList(_historyKey) ?? <String>[]) {
      try {
        readable.add(CalculationHistory.fromJson(jsonDecode(raw)));
      } catch (e) {
        AppLogger.warning('Registro do histórico ilegível (${e.runtimeType})');
        unreadable.add(raw);
      }
    }
    readable.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return _StoredHistory(readable, unreadable);
  }

  Future<void> _write(SharedPreferences prefs, List<CalculationHistory> history, List<String> unreadable) {
    return prefs.setStringList(_historyKey, [...history.map((calc) => jsonEncode(calc.toJson())), ...unreadable]);
  }

  /// Recupera todo o histórico de cálculos, ordenado por data (mais recente primeiro).
  ///
  /// Retorna lista vazia se não houver histórico. Registros ilegíveis não entram
  /// na lista, mas continuam armazenados (veja [unreadableCount]).
  ///
  /// Throws [StorageException] se houver erro ao acessar o armazenamento
  Future<List<CalculationHistory>> getHistory() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      return (await _read(prefs)).readable;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao obter histórico', e, stackTrace);
      throw StorageException('Erro ao carregar histórico de cálculos', originalError: e);
    }
  }

  /// Quantidade de registros gravados que não puderam ser lidos.
  Future<int> unreadableCount() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return (await _read(prefs)).unreadable.length;
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
      final stored = await _read(prefs);
      final history = stored.readable;

      // Adicionar novo cálculo no início
      history.insert(0, calculation);

      // FIFO: o histórico está ordenado do mais recente ao mais antigo
      if (history.length > AppConstants.maxHistorySize) {
        history.removeRange(AppConstants.maxHistorySize, history.length);
      }

      await _write(prefs, history, stored.unreadable);
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
    final stored = await _read(prefs);
    final history = stored.readable;

    history.removeWhere((calc) => calc.id == id);

    await _write(prefs, history, stored.unreadable);
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
    final stored = await _read(prefs);
    final history = stored.readable;

    final index = history.indexWhere((calc) => calc.id == id);
    if (index != -1) {
      final updatedCalc = CalculationHistory(
        id: history[index].id,
        input: history[index].input,
        result: history[index].result,
        terminationType: history[index].terminationType,
        timestamp: history[index].timestamp,
        note: note,
        schemaVersion: history[index].schemaVersion,
        legacyNetAmount: history[index].legacyNetAmount,
      );

      history[index] = updatedCalc;

      await _write(prefs, history, stored.unreadable);
    }
  }
}

class _StoredHistory {
  const _StoredHistory(this.readable, this.unreadable);

  final List<CalculationHistory> readable;
  final List<String> unreadable;
}
