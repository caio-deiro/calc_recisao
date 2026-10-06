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
    this.fgtsWithdrawalPercent,
    this.hasIndemnity479 = false,
    this.hasDiscount480 = false,
    this.noticeProjectionPendingRule,
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

  /// Percentual do saldo do FGTS que o trabalhador pode sacar (informativo, sem valor
  /// calculado): 100 sem justa causa; 80 no acordo (CLT art. 484-A §1º). Nulo = sem
  /// linha de saque. ⚖️ 80 % vem do PRD, não reverificado em fonte.
  final int? fgtsWithdrawalPercent;

  /// Art. 479 CLT: indenização na antecipada pelo empregador (sem cláusula).
  final bool hasIndemnity479;

  /// Art. 480 CLT: desconto na antecipada pelo empregado (sem cláusula).
  final bool hasDiscount480;

  /// Regra ⚖️ de `validationPendingRules` que marca a projeção do aviso neste tipo.
  final String? noticeProjectionPendingRule;

  bool get paysFgtsFine => fgtsFineShare > 0;

  static const Map<TerminationType, TerminationRules> _byType = {
    TerminationType.withoutJustCause: TerminationRules(
      noticePercent: 100,
      fgtsFineShare: 1.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
      fgtsWithdrawalPercent: 100,
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
    // Rescisão indireta tem os efeitos da dispensa sem justa causa (CLT art. 483).
    TerminationType.indirectTermination: TerminationRules(
      noticePercent: 100,
      fgtsFineShare: 1.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
      fgtsWithdrawalPercent: 100,
    ),
    // Término normal: sem aviso e sem multa; saque de 100 % (Lei 8.036/90 art. 20 IX).
    TerminationType.fixedTermEnd: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 0.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
      fgtsWithdrawalPercent: 100,
    ),
    // Antecipada pelo empregador: indenização do art. 479 e multa de 40 %. ⚖️
    TerminationType.fixedTermEarlyByEmployer: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 1.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
      fgtsWithdrawalPercent: 100,
      hasIndemnity479: true,
    ),
    // Antecipada pelo empregado: desconto do art. 480, sem multa e sem saque. ⚖️
    TerminationType.fixedTermEarlyByEmployee: TerminationRules(
      noticePercent: 0,
      fgtsFineShare: 0.0,
      paysThirteenth: true,
      paysProportionalVacation: true,
      paysAccruedVacation: true,
      noticeDeductible: false,
      hasDiscount480: true,
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
      fgtsWithdrawalPercent: 80,
      noticeProjectionPendingRule: 'noticeProjectionMutualAgreement',
    ),
  };

  /// Com cláusula assecuratória (CLT art. 481), a antecipada segue as regras do
  /// prazo indeterminado: empregador como sem justa causa, empregado como pedido de demissão.
  static const Map<TerminationType, TerminationType>
  _recipientClauseEquivalent = {
    TerminationType.fixedTermEarlyByEmployer: TerminationType.withoutJustCause,
    TerminationType.fixedTermEarlyByEmployee: TerminationType.resignation,
  };

  static TerminationRules of(TerminationType type) => _byType[type]!;

  /// Regras efetivas do cálculo: aplica a cláusula assecuratória quando houver.
  static TerminationRules resolve(
    TerminationType type,
    bool hasRecipientClause,
  ) => of(
    (hasRecipientClause ? _recipientClauseEquivalent[type] : null) ?? type,
  );
}
