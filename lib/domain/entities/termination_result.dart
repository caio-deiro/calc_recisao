import 'assumption.dart';
import 'breakdown_item.dart';

/// Valores depositados no FGTS pelo empregador por causa da rescisão (hoje, só a multa).
/// Não são pagos ao empregado na rescisão.
class FgtsDeposit {
  const FgtsDeposit({this.items = const []});

  final List<BreakdownItem> items;

  double get total => items.fold(0.0, (sum, item) => sum + item.value);
}

class TerminationResult {
  const TerminationResult({
    required this.additions,
    required this.deductions,
    required this.totalToReceive,
    required this.totalDeductions,
    required this.netAmount,
    required this.calculationDate,
    this.paidAtTermination = 0.0,
    this.fgtsDeposit = const FgtsDeposit(),
    this.assumptions = const [],
  });

  /// Proventos pagos na rescisão (sem a multa do FGTS, que está em [fgtsDeposit]).
  final List<BreakdownItem> additions;
  final List<BreakdownItem> deductions;

  /// Semântica antiga: proventos mais a multa do FGTS. Use [paidAtTermination] e [fgtsDeposit].
  @Deprecated('Use paidAtTermination e fgtsDeposit; removido em B5.')
  final double totalToReceive;
  final double totalDeductions;

  /// Semântica antiga: líquido mais a multa do FGTS. Use [paidAtTermination] e [fgtsDeposit].
  @Deprecated('Use paidAtTermination e fgtsDeposit; removido em B5.')
  final double netAmount;
  final DateTime calculationDate;

  /// Proventos menos descontos, sem a multa do FGTS. Em registro legado (histórico
  /// anterior ao `schemaVersion` 2) não é inferido e vale 0: exiba o [netAmount] gravado.
  final double paidAtTermination;
  final FgtsDeposit fgtsDeposit;
  final List<Assumption> assumptions;

  double get totalAdditions =>
      additions.fold(0, (sum, item) => sum + item.value);
  double get calculatedDeductions =>
      deductions.fold(0, (sum, item) => sum + item.value);
}
