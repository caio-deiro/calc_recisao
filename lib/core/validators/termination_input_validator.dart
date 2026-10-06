import '../../domain/entities/termination_input.dart';
import '../../domain/entities/termination_type.dart';
import '../../domain/rules/vacation_periods.dart';
import '../exceptions/app_exceptions.dart';

/// Resultado da validação
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, String> fieldErrors;

  /// Avisos que não bloqueiam o cálculo (ex.: término normal fora do fim previsto).
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.fieldErrors = const {},
    this.warnings = const [],
  });

  factory ValidationResult.success({List<String> warnings = const []}) =>
      ValidationResult(isValid: true, warnings: warnings);

  factory ValidationResult.failure({
    required List<String> errors,
    Map<String, String> fieldErrors = const {},
    List<String> warnings = const [],
  }) => ValidationResult(
    isValid: false,
    errors: errors,
    fieldErrors: fieldErrors,
    warnings: warnings,
  );
}

/// Validador para dados de entrada de rescisão
class TerminationInputValidator {
  /// Valida todos os campos do input. Com [type] a prazo, valida também o fim previsto (B4-03).
  static ValidationResult validate(
    TerminationInput input, {
    TerminationType? type,
  }) {
    final errors = <String>[];
    final fieldErrors = <String, String>{};
    final warnings = <String>[];

    // Validar datas
    _validateDates(input, errors, fieldErrors);

    // Validar valores monetários
    _validateMonetaryValues(input, errors, fieldErrors);

    // Validar regras de negócio
    _validateBusinessRules(input, errors, fieldErrors);

    // Validar contrato a prazo (fim previsto)
    if (type != null && fixedTermTypes.contains(type)) {
      _validateFixedTerm(input, type, errors, fieldErrors, warnings);
    }

    if (errors.isEmpty && fieldErrors.isEmpty) {
      return ValidationResult.success(warnings: warnings);
    }

    return ValidationResult.failure(
      errors: errors,
      fieldErrors: fieldErrors,
      warnings: warnings,
    );
  }

  /// Tipos que exigem a data de fim previsto do contrato.
  static const Set<TerminationType> fixedTermTypes = {
    TerminationType.fixedTermEnd,
    TerminationType.fixedTermEarlyByEmployer,
    TerminationType.fixedTermEarlyByEmployee,
  };

  /// Aviso (não bloqueante) do término normal com rescisão diferente do fim previsto.
  static String? normalEndMismatchWarning(DateTime termination, DateTime end) {
    if (termination == end) return null;
    return 'A data de desligamento é diferente do fim previsto do contrato. '
        'Se o contrato foi encerrado antes do fim, escolha a opção de encerramento antecipado.';
  }

  /// Fim previsto: obrigatório e posterior à admissão; nas antecipadas, a rescisão não passa
  /// do fim; no término normal, rescisão diferente do fim só gera aviso. Sem regra de "futuro".
  static void _validateFixedTerm(
    TerminationInput input,
    TerminationType type,
    List<String> errors,
    Map<String, String> fieldErrors,
    List<String> warnings,
  ) {
    final end = input.fixedTermEndDate;
    if (end == null) {
      errors.add('Informe a data de fim previsto do contrato');
      fieldErrors['fixedTermEndDate'] = 'Campo obrigatório';
      return;
    }
    if (!end.isAfter(input.admissionDate)) {
      errors.add('Data de fim previsto deve ser posterior à data de admissão');
      fieldErrors['fixedTermEndDate'] = 'Data inválida';
      return;
    }
    if (type == TerminationType.fixedTermEnd) {
      final warning = normalEndMismatchWarning(input.terminationDate, end);
      if (warning != null) warnings.add(warning);
    } else if (input.terminationDate.isAfter(end)) {
      errors.add(
        'Data de desligamento deve ser até o fim previsto do contrato',
      );
      fieldErrors['terminationDate'] = 'Data de rescisão inválida';
    }
  }

  /// Valida as datas
  static void _validateDates(
    TerminationInput input,
    List<String> errors,
    Map<String, String> fieldErrors,
  ) {
    // Data de admissão não pode ser no futuro
    if (input.admissionDate.isAfter(DateTime.now())) {
      errors.add('Data de admissão não pode ser no futuro');
      fieldErrors['admissionDate'] = 'Data inválida';
    }

    // Data de rescisão não pode ser no futuro (com margem de 1 dia)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (input.terminationDate.isAfter(tomorrow)) {
      errors.add('Data de rescisão não pode ser no futuro');
      fieldErrors['terminationDate'] = 'Data inválida';
    }

    // Data de rescisão deve ser após data de admissão
    if (input.terminationDate.isBefore(input.admissionDate)) {
      errors.add('Data de rescisão deve ser posterior à data de admissão');
      fieldErrors['terminationDate'] = 'Data de rescisão inválida';
    }

    // Verificar se não é muito antiga (mais de 100 anos)
    final hundredYearsAgo = DateTime.now().subtract(
      const Duration(days: 365 * 100),
    );
    if (input.admissionDate.isBefore(hundredYearsAgo)) {
      errors.add('Data de admissão muito antiga');
      fieldErrors['admissionDate'] = 'Data muito antiga';
    }
  }

  /// Valida valores monetários
  static void _validateMonetaryValues(
    TerminationInput input,
    List<String> errors,
    Map<String, String> fieldErrors,
  ) {
    // Salário base deve ser positivo
    if (input.baseSalary <= 0) {
      errors.add('Salário base deve ser maior que zero');
      fieldErrors['baseSalary'] = 'Valor inválido';
    }

    // Salário base não pode ser muito alto (limite razoável: R$ 1.000.000)
    const maxSalary = 1000000.0;
    if (input.baseSalary > maxSalary) {
      errors.add('Salário base muito alto. Verifique o valor informado');
      fieldErrors['baseSalary'] = 'Valor muito alto';
    }

    // Adições médias não podem ser negativas
    if (input.averageAdditions < 0) {
      errors.add('Adições médias não podem ser negativas');
      fieldErrors['averageAdditions'] = 'Valor inválido';
    }

    // FGTS existente não pode ser negativo
    if (input.hasExistingFgts && input.existingFgtsAmount < 0) {
      errors.add('Valor de FGTS existente não pode ser negativo');
      fieldErrors['existingFgtsAmount'] = 'Valor inválido';
    }

    // Outros descontos não podem ser negativos
    if (input.otherDiscounts < 0) {
      errors.add('Outros descontos não podem ser negativos');
      fieldErrors['otherDiscounts'] = 'Valor inválido';
    }

    // Dependentes não podem ser negativos
    if (input.dependents < 0) {
      errors.add('Número de dependentes não pode ser negativo');
      fieldErrors['dependents'] = 'Valor inválido';
    }

    // Dependentes não podem ser muitos (limite razoável: 20)
    if (input.dependents > 20) {
      errors.add(
        'Número de dependentes muito alto. Verifique o valor informado',
      );
      fieldErrors['dependents'] = 'Valor muito alto';
    }
  }

  /// Valida regras de negócio
  static void _validateBusinessRules(
    TerminationInput input,
    List<String> errors,
    Map<String, String> fieldErrors,
  ) {
    // Dias trabalhados no mês devem estar entre 0 e 31
    if (input.workedDaysInMonth < 0 || input.workedDaysInMonth > 31) {
      errors.add('Dias trabalhados no mês devem estar entre 0 e 31');
      fieldErrors['workedDaysInMonth'] = 'Valor inválido';
    }

    // Se informou dias trabalhados, deve ser consistente com a data
    if (input.workedDaysInMonth > 0) {
      final daysInMonth = input.terminationDate.day;
      if (input.workedDaysInMonth > daysInMonth) {
        // Apenas aviso, não erro crítico
        // Pode ser que o usuário queira especificar manualmente
      }
    }

    // Períodos de férias gozados entre 0 e n (anos completos). Com datas
    // inconsistentes, só os erros de data são reportados.
    if (!input.terminationDate.isBefore(input.admissionDate)) {
      final n = fullServiceYears(input.admissionDate, input.terminationDate);
      if (input.vacationPeriodsTaken < 0 || input.vacationPeriodsTaken > n) {
        errors.add('Períodos de férias gozados devem estar entre 0 e $n');
        fieldErrors['vacationPeriodsTaken'] = 'Valor inválido';
      }
    }

    // Se tem FGTS existente marcado, deve ter valor
    if (input.hasExistingFgts && input.existingFgtsAmount == 0) {
      // Apenas aviso, não erro crítico
      // Pode ser que o usuário não saiba o valor exato
    }
  }

  /// Valida e lança exceção se inválido
  static void validateAndThrow(TerminationInput input) {
    final result = validate(input);
    if (!result.isValid) {
      throw ValidationException(
        result.errors.join('; '),
        fieldErrors: result.fieldErrors,
      );
    }
  }
}
