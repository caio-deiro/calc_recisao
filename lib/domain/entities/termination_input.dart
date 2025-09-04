class TerminationInput {
  const TerminationInput({
    required this.admissionDate,
    required this.terminationDate,
    required this.baseSalary,
    this.averageAdditions = 0.0,
    this.hasAccruedVacation = false,
    this.workedDaysInMonth = 0,
    this.noticeWorked = false,
    this.hasExistingFgts = false,
    this.existingFgtsAmount = 0.0,
    this.dependents = 0,
    this.otherDiscounts = 0.0,
    this.calculateTaxes = true,
  });

  final DateTime admissionDate;
  final DateTime terminationDate;
  final double baseSalary;
  final double averageAdditions;
  final bool hasAccruedVacation;
  final int workedDaysInMonth;
  final bool noticeWorked;
  final bool hasExistingFgts;
  final double existingFgtsAmount;
  final int dependents;
  final double otherDiscounts;
  final bool calculateTaxes;

  Map<String, dynamic> toJson() => {
    'admissionDate': admissionDate.toIso8601String(),
    'terminationDate': terminationDate.toIso8601String(),
    'baseSalary': baseSalary,
    'averageAdditions': averageAdditions,
    'hasAccruedVacation': hasAccruedVacation,
    'workedDaysInMonth': workedDaysInMonth,
    'noticeWorked': noticeWorked,
    'hasExistingFgts': hasExistingFgts,
    'existingFgtsAmount': existingFgtsAmount,
    'dependents': dependents,
    'otherDiscounts': otherDiscounts,
    'calculateTaxes': calculateTaxes,
  };

  factory TerminationInput.fromJson(Map<String, dynamic> json) => TerminationInput(
    admissionDate: DateTime.parse(json['admissionDate']),
    terminationDate: DateTime.parse(json['terminationDate']),
    baseSalary: json['baseSalary']?.toDouble() ?? 0.0,
    averageAdditions: json['averageAdditions']?.toDouble() ?? 0.0,
    hasAccruedVacation: json['hasAccruedVacation'] ?? false,
    workedDaysInMonth: json['workedDaysInMonth'] ?? 0,
    noticeWorked: json['noticeWorked'] ?? false,
    hasExistingFgts: json['hasExistingFgts'] ?? false,
    existingFgtsAmount: json['existingFgtsAmount']?.toDouble() ?? 0.0,
    dependents: json['dependents'] ?? 0,
    otherDiscounts: json['otherDiscounts']?.toDouble() ?? 0.0,
    calculateTaxes: json['calculateTaxes'] ?? true,
  );
}
