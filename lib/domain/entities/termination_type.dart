enum TerminationType {
  withoutJustCause('Sem Justa Causa', 'Empregador demite sem justificativa'),
  resignation('Pedido de Demissão', 'Empregado pede demissão'),
  fixedTerm('Prazo Determinado', 'Contrato por prazo determinado'),
  withJustCause('Com Justa Causa', 'Demissão por justa causa'),
  mutualAgreement('Acordo Mútuo', 'Acordo entre as partes');

  const TerminationType(this.label, this.description);

  final String label;
  final String description;

  bool get hasFgtsPenalty => this == TerminationType.withoutJustCause || this == TerminationType.mutualAgreement;
  bool get allowsFgtsWithdrawal => this == TerminationType.withoutJustCause;
  bool get hasReducedFgtsPenalty => this == TerminationType.mutualAgreement;
  bool get hasReducedNotice => this == TerminationType.mutualAgreement;
}
