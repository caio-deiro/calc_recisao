import 'app_localizations.dart';

/// Localizações em Português (Brasil)
class AppLocalizationsPt extends AppLocalizations {
  // Títulos e navegação
  @override
  String get appTitle => 'Calculadora de Rescisão CLT';

  @override
  String get homeTitle => 'Calculadora de Rescisão CLT';

  @override
  String get formTitle => 'Dados da Rescisão';

  @override
  String get resultTitle => 'Resultado da Rescisão';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get supportTitle => 'Suporte';

  // Formulário
  @override
  String get chooseTerminationType => 'Escolha o tipo de rescisão:';

  @override
  String get basicInfo => 'Informações Básicas';

  @override
  String get admissionDate => 'Data de Admissão';

  @override
  String get terminationDate => 'Data de Desligamento';

  @override
  String get remuneration => 'Remuneração';

  @override
  String get baseSalary => 'Salário Base Mensal';

  @override
  String get averageAdditions => 'Média de Adicionais Fixos (opcional)';

  @override
  String get workedDaysInMonth => 'Dias Trabalhados no Mês (opcional)';

  @override
  String get options => 'Opções';

  @override
  String get hasAccruedVacation => 'Férias vencidas?';

  @override
  String get noticeWorked => 'Aviso prévio trabalhado';

  @override
  String get hasExistingFgts => 'Possui depósitos FGTS existentes';

  @override
  String get existingFgtsAmount => 'Valor total do FGTS no vínculo';

  @override
  String get dependents => 'Número de Dependentes';

  @override
  String get otherDiscounts => 'Outros Descontos (opcional)';

  @override
  String get calculateTaxes => 'Calcular descontos (INSS/IRRF)';

  @override
  String get calculateTermination => 'Calcular Rescisão';

  @override
  String get fieldRequired => 'Campo obrigatório';

  // Resultado
  @override
  String get additions => 'Proventos';

  @override
  String get deductions => 'Descontos';

  @override
  String get paidAtTermination => 'Pago na rescisão';

  @override
  String get fgtsDeposit => 'Depositado no FGTS';

  @override
  String fgtsWithdrawalInfo(int percent) => 'Saque de $percent % do saldo do FGTS (informativo)';

  @override
  String get assumptionsTitle => 'Premissas desta estimativa';

  @override
  String get estimatedMarker => 'estimado';

  @override
  String get validationNotice => 'Cálculo em validação';

  @override
  String get legacyMark => 'Calculado em versão anterior';

  @override
  String get disclaimerText =>
      'Esta calculadora faz uma estimativa com base em regras gerais da CLT; o TRCT oficial prevalece. '
      'Sem o saldo do FGTS informado, a multa é uma aproximação (usa o salário atual e ignora reajustes, '
      'saques e depósitos). Feriados, faltas, licenças e adicionais além da média informada não entram no '
      'cálculo. Consulte um contador ou advogado antes de decidir.';

  @override
  String get legacyValueLabel => 'Valor calculado';

  @override
  String get assumptionInformed => 'informado';

  @override
  String get assumptionEstimated => 'estimado';

  @override
  String get totalDeductions => 'Total de Descontos';

  @override
  String get share => 'Compartilhar Completo';

  @override
  String get shareSimple => 'Compartilhar Resumido';

  @override
  String get copy => 'Copiar Completo';

  @override
  String get copySimple => 'Copiar Resumido';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get savePdf => 'Salvar PDF';

  // Histórico
  @override
  String get noHistory => 'Nenhum cálculo salvo ainda';

  @override
  String get clearHistory => 'Limpar Histórico';

  @override
  String get clearHistoryConfirmation => 'Tem certeza que deseja apagar todo o histórico de cálculos?';

  @override
  String get deleteCalculation => 'Excluir cálculo';

  // Mensagens
  @override
  String get loading => 'Carregando...';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fechar';

  // Erros
  @override
  String get errorProcessingData => 'Erro ao processar dados';

  @override
  String get invalidDateFormat => 'Formato de data inválido. Verifique se as datas estão no formato dd/mm/aaaa';

  @override
  String get genericError => 'Ocorreu um erro inesperado. Tente novamente.';

  @override
  String get networkError => 'Erro de conexão. Verifique sua internet.';

  @override
  String get validationError => 'Dados inválidos. Verifique os campos preenchidos.';
}
