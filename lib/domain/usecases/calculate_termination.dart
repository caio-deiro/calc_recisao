import '../entities/termination_input.dart';
import '../entities/termination_result.dart';
import '../entities/breakdown_item.dart';
import '../entities/termination_type.dart';
import '../../core/services/tax_tables_service.dart';
import '../../core/utils/logger.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/constants/app_constants.dart';

/// Use case responsável por calcular rescisões trabalhistas conforme a CLT.
/// 
/// Implementa todas as regras de cálculo para diferentes tipos de rescisão:
/// - Sem justa causa
/// - Com justa causa
/// - Pedido de demissão
/// - Acordo mútuo
/// - Prazo determinado
class CalculateTerminationUseCase {
  const CalculateTerminationUseCase();

  /// Arredonda valores monetários para o número de casas decimais configurado.
  /// 
  /// [value] - Valor a ser arredondado
  /// Retorna o valor arredondado ou o valor original em caso de erro
  double _roundCurrency(double value) {
    try {
      return double.parse(value.toStringAsFixed(AppConstants.decimalPlaces));
    } catch (e) {
      AppLogger.error('Erro ao arredondar valor monetário', e);
      return value;
    }
  }

  /// Calcula a rescisão trabalhista baseada nos dados fornecidos
  /// 
  /// [input] - Dados da rescisão
  /// [type] - Tipo de rescisão
  /// 
  /// Retorna [TerminationResult] com todos os cálculos
  /// 
  /// Throws [CalculationException] se houver erro no cálculo
  TerminationResult execute(TerminationInput input, TerminationType type) {
    try {
      AppLogger.info('Iniciando cálculo de rescisão: ${type.label}');
    final additions = <BreakdownItem>[];
    final deductions = <BreakdownItem>[];

    // 1. Saldo de salário
    final salaryBalance = _roundCurrency(_calculateSalaryBalance(input));
    additions.add(
      BreakdownItem(
        description: 'Saldo de Salário',
        value: salaryBalance,
        type: BreakdownType.addition,
        details: input.workedDaysInMonth > 0
            ? '${input.workedDaysInMonth} dias × R\$ ${(input.baseSalary / 30).toStringAsFixed(2)}'
            : '${input.terminationDate.day} dias × R\$ ${(input.baseSalary / 30).toStringAsFixed(2)}',
      ),
    );

    // 2. Aviso prévio indenizado (não se aplica a com justa causa, prazo determinado e pedido de demissão)
    if (!input.noticeWorked && _receivesIndemnifiedNotice(type)) {
      final noticeAmount = _roundCurrency(_calculateNoticeAmount(input, type));
      final description = 'Aviso Prévio Indenizado';
      final details = '30 dias + adicional por tempo de serviço';

      additions.add(
        BreakdownItem(description: description, value: noticeAmount, type: BreakdownType.addition, details: details),
      );
    }

    // 2.1. Desconto de aviso prévio no pedido de demissão (quando não cumprido)
    if (!input.noticeWorked && type == TerminationType.resignation) {
      final noticeDiscount = _roundCurrency(_calculateNoticeAmount(input, type));
      deductions.add(
        BreakdownItem(
          description: 'Desconto Aviso Prévio',
          value: noticeDiscount,
          type: BreakdownType.deduction,
          details: 'Aviso prévio não cumprido pelo empregado',
        ),
      );
    }

    // 3. 13º Salário Proporcional (não se aplica a com justa causa)
    if (type != TerminationType.withJustCause) {
      final thirteenthSalary = _roundCurrency(_calculateThirteenthSalary(input));
      if (thirteenthSalary > 0) {
        additions.add(
          BreakdownItem(
            description: '13º Salário Proporcional',
            value: thirteenthSalary,
            type: BreakdownType.addition,
            details: 'Proporcional aos meses trabalhados',
          ),
        );
      }
    }

    // 4. Férias vencidas (não se aplica a com justa causa)
    if (input.hasAccruedVacation && type != TerminationType.withJustCause) {
      final vacationAmount = _roundCurrency(_calculateAccruedVacation(input));
      additions.add(
        BreakdownItem(
          description: 'Férias Vencidas + 1/3',
          value: vacationAmount,
          type: BreakdownType.addition,
          details: 'Salário + 1/3 constitucional',
        ),
      );
    }

    // 5. Férias proporcionais (não se aplica a com justa causa)
    if (type != TerminationType.withJustCause) {
      final proportionalVacation = _roundCurrency(_calculateProportionalVacation(input));
      if (proportionalVacation > 0) {
        additions.add(
          BreakdownItem(
            description: 'Férias Proporcionais + 1/3',
            value: proportionalVacation,
            type: BreakdownType.addition,
            details: 'Proporcional aos meses trabalhados',
          ),
        );
      }
    }

    // 6. Multa FGTS (se aplicável)
    // Nota: O FGTS em si não é pago na rescisão, apenas a multa é paga pelo empregador
    if (type.hasFgtsPenalty) {
      final fgtsPenalty = _roundCurrency(_calculateFgtsPenalty(input));
      additions.add(
        BreakdownItem(
          description: 'Multa FGTS (40%)',
          value: fgtsPenalty,
          type: BreakdownType.addition,
          details: '40% sobre FGTS do vínculo',
        ),
      );
    }

    // 7.1. Regras específicas para Rescisão com Justa Causa
    if (type == TerminationType.withJustCause) {
      // Na rescisão por justa causa, o empregado não tem direito a:
      // - Aviso prévio
      // - Multa FGTS
      // - Saque do FGTS
      // - 13º salário proporcional
      // - Férias proporcionais

      // Remover itens que não se aplicam
      additions.removeWhere(
        (item) =>
            item.description == 'Aviso Prévio Indenizado' ||
            item.description == '13º Salário Proporcional' ||
            item.description == 'Férias Proporcionais + 1/3' ||
            item.description == 'Multa FGTS (40%)',
      );
    }

    // 7.2. Regras específicas para Acordo Mútuo (art. 484-A)
    if (type == TerminationType.mutualAgreement) {
      // No acordo mútuo, o empregado tem direito a:
      // - 50% do aviso prévio (se não trabalhado)
      // - 20% da multa FGTS (reduzida de 40% para 20%)
      // - Demais verbas normalmente

      // Ajustar aviso prévio para 50%
      final noticeIndex = additions.indexWhere((item) => item.description == 'Aviso Prévio Indenizado');
      if (noticeIndex != -1 && !input.noticeWorked) {
        final originalNotice = additions[noticeIndex];
        additions[noticeIndex] = BreakdownItem(
          description: 'Aviso Prévio Indenizado (50%)',
          value: originalNotice.value * 0.5,
          type: BreakdownType.addition,
          details: '50% do aviso prévio (acordo mútuo)',
        );
      }

      // Ajustar multa FGTS para 20%
      final fgtsPenaltyIndex = additions.indexWhere((item) => item.description == 'Multa FGTS (40%)');
      if (fgtsPenaltyIndex != -1) {
        final originalPenalty = additions[fgtsPenaltyIndex];
        additions[fgtsPenaltyIndex] = BreakdownItem(
          description: 'Multa FGTS (20%)',
          value: originalPenalty.value * 0.5, // 20% = 50% de 40%
          type: BreakdownType.addition,
          details: '20% sobre FGTS do vínculo (acordo mútuo)',
        );
      }
    }

    // 8. Descontos
    if (input.calculateTaxes) {
      final double salaryBalanceAmount = additions
          .where((item) => item.description == 'Saldo de Salário')
          .fold(0.0, (sum, item) => sum + item.value);
      final double thirteenthSalaryAmount = additions
          .where((item) => item.description == '13º Salário Proporcional')
          .fold(0.0, (sum, item) => sum + item.value);
      final double vacationAmount = additions
          .where((item) => item.description.contains('Férias'))
          .fold(0.0, (sum, item) => sum + item.value);
      final TerminationTaxResult taxes = TaxTablesService.instance.calculateTerminationTaxes(
        salaryBalance: salaryBalanceAmount,
        thirteenthSalary: thirteenthSalaryAmount,
        vacationAmount: vacationAmount,
        terminationDate: input.terminationDate,
        dependents: input.dependents,
      );
      if (taxes.inss > 0) {
        deductions.add(
          BreakdownItem(
            description: 'INSS',
            value: _roundCurrency(taxes.inss),
            type: BreakdownType.deduction,
            details: 'Sobre saldo de salário e 13º proporcional',
          ),
        );
      }
      if (taxes.irrf > 0) {
        deductions.add(
          BreakdownItem(
            description: 'IRRF',
            value: _roundCurrency(taxes.irrf),
            type: BreakdownType.deduction,
            details: 'Sobre verbas tributáveis (saldo, 13º e férias)',
          ),
        );
      }
    }

    // 9. Outros descontos
    if (input.otherDiscounts > 0) {
      deductions.add(
        BreakdownItem(
          description: 'Outros Descontos',
          value: _roundCurrency(input.otherDiscounts),
          type: BreakdownType.deduction,
          details: 'Descontos diversos',
        ),
      );
    }

    final totalAdditions = _roundCurrency(additions.fold(0.0, (sum, item) => sum + item.value));
    final totalDeductions = _roundCurrency(deductions.fold(0.0, (sum, item) => sum + item.value));
    final netAmount = _roundCurrency(totalAdditions - totalDeductions);

    final result = TerminationResult(
      additions: additions,
      deductions: deductions,
      totalToReceive: totalAdditions,
      totalDeductions: totalDeductions,
      netAmount: netAmount,
      calculationDate: DateTime.now(),
    );

    AppLogger.info('Cálculo concluído. Valor líquido: R\$ ${netAmount.toStringAsFixed(2)}');
    return result;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao calcular rescisão', e, stackTrace);
      throw CalculationException(
        'Erro ao calcular rescisão. Verifique os dados informados.',
        originalError: e,
      );
    }
  }

  bool _receivesIndemnifiedNotice(TerminationType type) {
    return type != TerminationType.withJustCause &&
        type != TerminationType.fixedTerm &&
        type != TerminationType.resignation;
  }

  /// Calcula o saldo de salário proporcional aos dias trabalhados no mês.
  /// 
  /// Se [workedDaysInMonth] for informado, usa esse valor.
  /// Caso contrário, calcula baseado no dia da rescisão.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o valor do saldo de salário
  double _calculateSalaryBalance(TerminationInput input) {
    if (input.workedDaysInMonth > 0) {
      return _roundCurrency((input.baseSalary / 30) * input.workedDaysInMonth);
    }

    // Se não especificado, calcular baseado no dia da rescisão
    final daysInMonth = input.terminationDate.day;
    return _roundCurrency((input.baseSalary / 30) * daysInMonth);
  }

  /// Calcula o valor do aviso prévio indenizado.
  /// 
  /// Considera dias base + dias adicionais por tempo de serviço,
  /// respeitando o limite máximo de dias.
  /// 
  /// [input] - Dados da rescisão
  /// [type] - Tipo de rescisão (pode afetar o cálculo)
  /// Retorna o valor do aviso prévio
  double _calculateNoticeAmount(TerminationInput input, TerminationType type) {
    final taxService = TaxTablesService.instance;
    final yearsOfService = input.terminationDate.difference(input.admissionDate).inDays / 365;

    final baseDays = taxService.getAvisoPrevioBaseDays();
    final daysPerYear = taxService.getAvisoPrevioDaysPerYear();
    final maxDays = taxService.getAvisoPrevioMaxDays();

    final noticeDays = baseDays + (yearsOfService.floor() * daysPerYear);
    final cappedNoticeDays = noticeDays > maxDays ? maxDays.toDouble() : noticeDays.toDouble();

    // Calcular valor base do aviso prévio (sem redução)
    return _roundCurrency(((input.baseSalary + input.averageAdditions) / 30) * cappedNoticeDays);
  }

  /// Calcula os meses trabalhados no ano da rescisão, considerando a regra de 15 dias.
  /// 
  /// Se trabalhou >= 15 dias no mês, conta o mês completo, senão calcula proporcional.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o número de meses trabalhados no ano da rescisão
  double _calculateMonthsInCurrentYear(TerminationInput input) {
    final currentYear = input.terminationDate.year;
    final admissionYear = input.admissionDate.year;

    if (currentYear == admissionYear) {
      // Mesmo ano: calcular meses do ano atual
      double months = (input.terminationDate.month - input.admissionDate.month).toDouble();
      // Se trabalhou pelo menos 15 dias no mês da rescisão, conta proporcional
      if (input.terminationDate.day >= 15) {
        months += 1.0;
      } else {
        months += (input.terminationDate.day / 30.0);
      }
      return months;
    } else {
      // Anos diferentes: calcular apenas os meses do ano da rescisão
      if (input.terminationDate.month == 1) {
        return input.terminationDate.day >= 15 ? 1.0 : (input.terminationDate.day / 30.0);
      } else {
        double months = (input.terminationDate.month - 1).toDouble();
        if (input.terminationDate.day >= 15) {
          months += 1.0;
        } else {
          months += (input.terminationDate.day / 30.0);
        }
        return months;
      }
    }
  }

  /// Calcula o 13º salário proporcional aos meses trabalhados no ano da rescisão.
  /// 
  /// Considera a regra de 15 dias: se trabalhou pelo menos 15 dias no mês,
  /// conta o mês completo, caso contrário, calcula proporcional.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o valor do 13º salário proporcional
  double _calculateThirteenthSalary(TerminationInput input) {
    final monthsInCurrentYear = _calculateMonthsInCurrentYear(input);
    return _roundCurrency((input.baseSalary + input.averageAdditions) * (monthsInCurrentYear / 12));
  }

  /// Calcula o valor das férias vencidas + 1/3 constitucional.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o valor das férias vencidas com adicional
  double _calculateAccruedVacation(TerminationInput input) {
    final baseValue = input.baseSalary + input.averageAdditions;
    return _roundCurrency(baseValue + (baseValue / 3));
  }

  /// Calcula o valor das férias proporcionais + 1/3 constitucional.
  /// 
  /// Aplica a mesma lógica de cálculo de meses do 13º salário.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o valor das férias proporcionais com adicional
  double _calculateProportionalVacation(TerminationInput input) {
    final monthsInCurrentYear = _calculateMonthsInCurrentYear(input);
    final proportionalSalary = ((input.baseSalary + input.averageAdditions) * monthsInCurrentYear) / 12;
    return _roundCurrency(proportionalSalary + (proportionalSalary / 3));
  }

  /// Calcula a multa do FGTS (40% ou 20% conforme tipo de rescisão).
  /// 
  /// Se o usuário informou o valor existente do FGTS, usa esse valor.
  /// Caso contrário, estima baseado no tempo de serviço e salário médio.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o valor da multa do FGTS
  double _calculateFgtsPenalty(TerminationInput input) {
    final taxService = TaxTablesService.instance;
    final penaltyAliquota = taxService.getFgtsPenaltyAliquota(); // 40%

    if (input.hasExistingFgts && input.existingFgtsAmount > 0) {
      return _roundCurrency(input.existingFgtsAmount * penaltyAliquota);
    }

    // Aproximação baseada no tempo de serviço
    final monthsWorked = _calculateMonthsWorked(input);
    final averageMonthlySalary = input.baseSalary + input.averageAdditions;
    final fgtsAliquota = taxService.getFgtsAliquota();
    final estimatedFgts = (averageMonthlySalary * fgtsAliquota) * monthsWorked;
    return _roundCurrency(estimatedFgts * penaltyAliquota);
  }

  /// Calcula o número de meses trabalhados entre admissão e rescisão.
  /// 
  /// Considera o dia da rescisão: se >= dia da admissão, conta o mês completo.
  /// 
  /// [input] - Dados da rescisão
  /// Retorna o número de meses trabalhados
  double _calculateMonthsWorked(TerminationInput input) {
    // Calcular meses baseado na diferença de anos e meses
    final years = input.terminationDate.year - input.admissionDate.year;
    final months = input.terminationDate.month - input.admissionDate.month;
    final totalMonths = (years * 12) + months;

    // Se o dia da rescisão é maior ou igual ao dia da admissão, conta o mês
    if (input.terminationDate.day >= input.admissionDate.day) {
      return totalMonths.toDouble();
    } else {
      return (totalMonths - 1).toDouble();
    }
  }
}
