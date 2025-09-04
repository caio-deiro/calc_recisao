class BreakdownItem {
  const BreakdownItem({required this.description, required this.value, required this.type, this.details});

  final String description;
  final double value;
  final BreakdownType type;
  final String? details;

  bool get isAddition => type == BreakdownType.addition;
  bool get isDeduction => type == BreakdownType.deduction;
}

enum BreakdownType {
  addition('Adicional'),
  deduction('Desconto');

  const BreakdownType(this.label);
  final String label;
}
