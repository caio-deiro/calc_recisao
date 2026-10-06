enum TerminationType {
  withoutJustCause('Sem Justa Causa', 'Empregador demite sem justificativa'),
  indirectTermination(
    'Rescisão Indireta',
    'Empregado sai por falta grave do empregador',
  ),
  resignation('Pedido de Demissão', 'Empregado pede demissão'),
  withJustCause('Com Justa Causa', 'Demissão por justa causa'),
  mutualAgreement('Acordo Mútuo', 'Acordo entre as partes'),
  fixedTermEnd(
    'Fim do Contrato a Prazo',
    'O contrato com data de fim chegou ao término',
  ),
  fixedTermEarlyByEmployer(
    'Contrato a Prazo: Empresa Encerra Antes',
    'A empresa encerra o contrato antes da data de fim',
  ),
  fixedTermEarlyByEmployee(
    'Contrato a Prazo: Empregado Sai Antes',
    'O empregado encerra o contrato antes da data de fim',
  );

  const TerminationType(this.label, this.description);

  final String label;
  final String description;
}
