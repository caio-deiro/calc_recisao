/// Chave estável de UI de cada premissa (nunca use `text` como chave).
enum AssumptionCode {
  fgtsBalance,
  noticeProjection,
  thirteenthMonths,
  vacationMonths,
  thirtyDayMonth,
  fifteenDayRule,
  vacationPeriods,
  validationPending,
}

enum AssumptionOrigin { informed, estimated }

/// Premissa do cálculo: o que foi informado pelo usuário e o que o app estimou.
class Assumption {
  const Assumption({
    required this.code,
    required this.text,
    required this.origin,
    this.value,
    this.ruleId,
  });

  final AssumptionCode code;
  final String text;
  final AssumptionOrigin origin;
  final double? value;

  /// Só para `validationPending`: id da regra ⚖️ em `validationPendingRules`.
  final String? ruleId;

  Map<String, dynamic> toJson() => {
    'code': code.name,
    'text': text,
    'origin': origin.name,
    'value': value,
    'ruleId': ruleId,
  };

  factory Assumption.fromJson(Map<String, dynamic> json) => Assumption(
    code: AssumptionCode.values.firstWhere((e) => e.name == json['code']),
    text: json['text'],
    origin: AssumptionOrigin.values.firstWhere((e) => e.name == json['origin']),
    value: json['value']?.toDouble(),
    ruleId: json['ruleId'],
  );
}

/// Regras ⚖️ sem caso golden com fonte (B6-04). Espelha `test/golden/validation_status.dart`
/// (um teste compara as duas listas). Regra aqui que chegue ao resultado gera a
/// premissa "cálculo em validação".
const List<String> validationPendingRules = [
  'art479',
  'art480',
  'doubleVacation',
  'noticeProjectionMutualAgreement',
];
