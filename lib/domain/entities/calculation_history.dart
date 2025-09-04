import 'termination_input.dart';
import 'termination_result.dart';
import 'termination_type.dart';
import 'breakdown_item.dart';

class CalculationHistory {
  const CalculationHistory({
    required this.id,
    required this.input,
    required this.result,
    required this.terminationType,
    required this.timestamp,
    this.note,
  });

  final String id;
  final TerminationInput input;
  final TerminationResult result;
  final TerminationType terminationType;
  final DateTime timestamp;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'input': input.toJson(),
      'result': {
        'additions': result.additions
            .map(
              (item) => {
                'description': item.description,
                'value': item.value,
                'type': item.type.name,
                'details': item.details,
              },
            )
            .toList(),
        'deductions': result.deductions
            .map(
              (item) => {
                'description': item.description,
                'value': item.value,
                'type': item.type.name,
                'details': item.details,
              },
            )
            .toList(),
        'totalToReceive': result.totalToReceive,
        'totalDeductions': result.totalDeductions,
        'netAmount': result.netAmount,
        'calculationDate': result.calculationDate.toIso8601String(),
      },
      'terminationType': terminationType.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      id: json['id'],
      input: TerminationInput.fromJson(json['input']),
      result: TerminationResult(
        additions: (json['result']['additions'] as List)
            .map(
              (item) => BreakdownItem(
                description: item['description'],
                value: item['value'].toDouble(),
                type: BreakdownType.values.firstWhere((e) => e.name == item['type']),
                details: item['details'],
              ),
            )
            .toList(),
        deductions: (json['result']['deductions'] as List)
            .map(
              (item) => BreakdownItem(
                description: item['description'],
                value: item['value'].toDouble(),
                type: BreakdownType.values.firstWhere((e) => e.name == item['type']),
                details: item['details'],
              ),
            )
            .toList(),
        totalToReceive: json['result']['totalToReceive'].toDouble(),
        totalDeductions: json['result']['totalDeductions'].toDouble(),
        netAmount: json['result']['netAmount'].toDouble(),
        calculationDate: DateTime.parse(json['result']['calculationDate']),
      ),
      terminationType: TerminationType.values.firstWhere((e) => e.name == json['terminationType']),
      timestamp: DateTime.parse(json['timestamp']),
      note: json['note'],
    );
  }
}
