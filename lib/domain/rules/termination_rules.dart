import '../entities/termination_type.dart';

/// Regras de verbas por tipo de rescisão (PRD §6.1, com C1).
///
/// Tabela imutável: o use case consulta aqui antes de adicionar cada item.
class TerminationRules {
  const TerminationRules({
    required this.noticePercent,
    required this.fgtsFineShare,
    required this.paysThirteenth,
    required this.paysProportionalVacation,
    required this.paysAccruedVacation,
    required this.noticeDeductible,
    this.hasIndemnity479 = false,
    this.hasDiscount480 = false,
  });

  /// Percentual do aviso indenizado devido ao empregado (100/50/0).
  /// CLT art. 487 §1º (integral) e art. 484-A I "a" (metade no acordo).
  final int noticePercent;

  /// Fração aplicada à alíquota da multa lida de `tax_tables.json` (1,0/0,5/0).
  /// Lei 8.036/90 art. 18 §1º (40%) e CLT art. 484-A I "b" (metade).
  final double fgtsFineShare;
  final bool paysThirteenth;
  final bool paysProportionalVacation;

  /// CLT art. 146 caput: férias adquiridas são devidas "qualquer que seja a causa" (C1).
  final bool paysAccruedVacation;

  /// Aviso não cumprido pelo empregado é descontado (CLT art. 487 §2º).
  final bool noticeDeductible;

  /// Art. 479 CLT (B4): sempre falso até B4.
  final bool hasIndemnity479;

  /// Art. 480 CLT (B4): sempre falso até B4.
  final bool hasDiscount480;

  bool get paysFgtsFine => fgtsFineShare > 0;

  static const Map<TerminationType, TerminationRules> _byType = {
    TerminationType.withoutJustCause: TerminationRules(
      noticePercent: 100,
      fgtsFineShare: 1.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
    ),
    // ⚖️ Proporcionais pagas com menos de 12 meses: segue o PRD; contador deve confirmar.
    TerminationType.resignation: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 0.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: true,
    ),
    TerminationType.fixedTerm: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 0.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
    ),
    // CLT art. 146 parágrafo único: proporcionais não são devidas; vencidas sim (C1).
    TerminationType.withJustCause: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 0.0,
      paysThirteenth: false,
      paysProportionalVacation: false,
      paysAccruedVacation: true,
      noticeDeductible: false,
    ),
    TerminationType.mutualAgreement: TerminationRules(
      noticePercent: 50,
      fgtsFineShare: 0.5,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
    ),
  };

  static TerminationRules of(TerminationType type) => _byType[type]!;
}
