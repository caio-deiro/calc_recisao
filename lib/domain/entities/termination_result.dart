import 'breakdown_item.dart';

class TerminationResult {
  const TerminationResult({
    required this.additions,
    required this.deductions,
    required this.totalToReceive,
    required this.totalDeductions,
    required this.netAmount,
    required this.calculationDate,
  });

  final List<BreakdownItem> additions;
  final List<BreakdownItem> deductions;
  final double totalToReceive;
  final double totalDeductions;
  final double netAmount;
  final DateTime calculationDate;

  double get totalAdditions => additions.fold(0, (sum, item) => sum + item.value);
  double get calculatedDeductions => deductions.fold(0, (sum, item) => sum + item.value);
}
