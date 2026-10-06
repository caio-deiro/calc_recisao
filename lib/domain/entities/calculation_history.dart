import 'assumption.dart';
import 'breakdown_code.dart';
import 'breakdown_item.dart';
import 'termination_input.dart';
import 'termination_result.dart';
import 'termination_type.dart';

/// Versão do formato gravado. Ausente no JSON = 1 (registros 1.0.x, sem `code`).
const int currentHistorySchemaVersion = 2;

/// Nomes antigos de [TerminationType] já gravados em histórico, mapeados para o nome atual.
/// `fixedTerm` (antes de B4) vira `fixedTermEnd`.
const Map<String, String> terminationTypeAliases = {
  'fixedTerm': 'fixedTermEnd',
};

/// Resolve o tipo gravado; `null` se o nome não existe nem tem alias.
TerminationType? resolveTerminationType(
  String? name, {
  Map<String, String> aliases = terminationTypeAliases,
}) {
  final resolved = aliases[name] ?? name;
  for (final type in TerminationType.values) {
    if (type.name == resolved) {
      return type;
    }
  }
  return null;
}

class CalculationHistory {
  const CalculationHistory({
    required this.id,
    required this.input,
    required this.result,
    required this.terminationType,
    required this.timestamp,
    this.note,
    this.schemaVersion = currentHistorySchemaVersion,
    this.legacyNetAmount,
  });

  final String id;
  final TerminationInput input;
  final TerminationResult result;
  final TerminationType terminationType;
  final DateTime timestamp;
  final String? note;
  final int schemaVersion;

  /// Valor líquido gravado por versão anterior (chave de JSON legada `netAmount`); nulo em
  /// registro atual. É o único valor exibido de um registro legado; nada é inferido dele.
  final double? legacyNetAmount;

  /// Calculado em versão anterior do app: não é recalculado, só marcado na UI.
  bool get isLegacy => schemaVersion < currentHistorySchemaVersion;

  Map<String, dynamic> _itemToJson(BreakdownItem item) => {
    'code': item.code.name,
    'description': item.description,
    'value': item.value,
    'type': item.type.name,
    'details': item.details,
  };

  static BreakdownItem _itemFromJson(Map<String, dynamic> item) =>
      BreakdownItem(
        code:
            BreakdownCode.values
                .where((e) => e.name == item['code'])
                .firstOrNull ??
            BreakdownCode.legacy,
        description: item['description'],
        value: item['value'].toDouble(),
        type: BreakdownType.values.firstWhere((e) => e.name == item['type']),
        details: item['details'],
      );

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'input': input.toJson(),
      'result': {
        'additions': result.additions.map(_itemToJson).toList(),
        'deductions': result.deductions.map(_itemToJson).toList(),
        'totalDeductions': result.totalDeductions,
        if (legacyNetAmount != null) 'netAmount': legacyNetAmount,
        'calculationDate': result.calculationDate.toIso8601String(),
        'paidAtTermination': result.paidAtTermination,
        'fgtsDeposit': {
          'items': result.fgtsDeposit.items.map(_itemToJson).toList(),
        },
        'assumptions': result.assumptions.map((a) => a.toJson()).toList(),
      },
      'terminationType': terminationType.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  /// Aceita registros legados (sem `schemaVersion`, sem `code`, sem os campos novos).
  /// Lança [FormatException] se o tipo de rescisão for desconhecido; o repositório
  /// trata isso como registro ilegível (preservado, nunca descartado).
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    final type = resolveTerminationType(json['terminationType']);
    if (type == null) {
      throw const FormatException('Tipo de rescisão desconhecido no histórico');
    }
    final r = json['result'];
    final int schemaVersion = json['schemaVersion'] ?? 1;
    List<BreakdownItem> items(Object? list) => ((list ?? const []) as List)
        .map((e) => _itemFromJson(e as Map<String, dynamic>))
        .toList();

    return CalculationHistory(
      id: json['id'],
      input: TerminationInput.fromJson(json['input']),
      result: TerminationResult(
        additions: items(r['additions']),
        deductions: items(r['deductions']),
        totalDeductions: r['totalDeductions'].toDouble(),
        calculationDate: DateTime.parse(r['calculationDate']),
        paidAtTermination: (r['paidAtTermination'] ?? 0).toDouble(),
        fgtsDeposit: FgtsDeposit(items: items(r['fgtsDeposit']?['items'])),
        assumptions: ((r['assumptions'] ?? const []) as List)
            .map((e) => Assumption.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      terminationType: type,
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
      schemaVersion: schemaVersion,
      legacyNetAmount: schemaVersion < currentHistorySchemaVersion
          ? r['netAmount']?.toDouble()
          : null,
    );
  }
}
