import '../entities/termination_input.dart';
import '../entities/termination_result.dart';
import '../entities/breakdown_item.dart';
import '../entities/termination_type.dart';
import '../../core/services/tax_tables_service.dart';

class CalculateTerminationUseCase {
  const CalculateTerminationUseCase();

  TerminationResult execute(TerminationInput input, TerminationType type) {
    final additions = <BreakdownItem>[];
    final deductions = <BreakdownItem>[];

    // 1. Saldo de salário
    final salaryBalance = _calculateSalaryBalance(input);
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

    // 2. Aviso prévio indenizado (não se aplica a com justa causa e prazo determinado)
    if (!input.noticeWorked && type != TerminationType.withJustCause && type != TerminationType.fixedTerm) {
      final noticeAmount = _calculateNoticeAmount(input, type);
      final description = type == TerminationType.mutualAgreement
          ? 'Aviso Prévio Indenizado (50%)'
          : 'Aviso Prévio Indenizado';
      final details = type == TerminationType.mutualAgreement
          ? '50% do aviso prévio (acordo mútuo)'
          : '30 dias + adicional por tempo de serviço';

      additions.add(
        BreakdownItem(description: description, value: noticeAmount, type: BreakdownType.addition, details: details),
      );
    }

    // 3. 13º Salário Proporcional (não se aplica a com justa causa)
    if (type != TerminationType.withJustCause) {
      final thirteenthSalary = _calculateThirteenthSalary(input);
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
      final vacationAmount = _calculateAccruedVacation(input);
      additions.add(
        BreakdownItem(
          description: 'Férias Vencidas + 1/3',
          value: vacationAmount,
          type: BreakdownType.addition,
          details: 'Salário + 1/3 constitucional',
        ),
      );
    }

    // 5. Férias proporcionais (não se aplica a com justa causa e só se não há férias vencidas)
    if (type != TerminationType.withJustCause && !input.hasAccruedVacation) {
      final proportionalVacation = _calculateProportionalVacation(input);
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

    // 6. FGTS (só para demissão sem justa causa e acordo mútuo)
    final fgtsAmount = _calculateFgts(input, type);
    if (fgtsAmount > 0) {
      additions.add(
        BreakdownItem(
          description: 'FGTS',
          value: fgtsAmount,
          type: BreakdownType.addition,
          details: '8% sobre remuneração',
        ),
      );
    }

    // 7. Multa FGTS (se aplicável)
    if (type.hasFgtsPenalty) {
      final fgtsPenalty = _calculateFgtsPenalty(input);
      additions.add(
        BreakdownItem(
          description: type == TerminationType.mutualAgreement ? 'Multa FGTS (20%)' : 'Multa FGTS (40%)',
          value: fgtsPenalty,
          type: BreakdownType.addition,
          details: type == TerminationType.mutualAgreement
              ? '20% sobre FGTS do vínculo (acordo mútuo)'
              : '40% sobre FGTS do vínculo',
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
      final inssDiscount = _calculateInssDiscount(input);
      deductions.add(
        BreakdownItem(
          description: 'INSS',
          value: inssDiscount,
          type: BreakdownType.deduction,
          details: 'Desconto previdenciário',
        ),
      );

      final irrfDiscount = _calculateIrrfDiscount(input, inssDiscount);
      deductions.add(
        BreakdownItem(
          description: 'IRRF',
          value: irrfDiscount,
          type: BreakdownType.deduction,
          details: 'Imposto de renda retido na fonte',
        ),
      );
    }

    // 9. Outros descontos
    if (input.otherDiscounts > 0) {
      deductions.add(
        BreakdownItem(
          description: 'Outros Descontos',
          value: input.otherDiscounts,
          type: BreakdownType.deduction,
          details: 'Descontos diversos',
        ),
      );
    }

    final totalAdditions = additions.fold(0.0, (sum, item) => sum + item.value);
    final totalDeductions = deductions.fold(0.0, (sum, item) => sum + item.value);
    final netAmount = totalAdditions - totalDeductions;

    return TerminationResult(
      additions: additions,
      deductions: deductions,
      totalToReceive: totalAdditions,
      totalDeductions: totalDeductions,
      netAmount: netAmount,
      calculationDate: DateTime.now(),
    );
  }

  double _calculateSalaryBalance(TerminationInput input) {
    if (input.workedDaysInMonth > 0) {
      return (input.baseSalary / 30) * input.workedDaysInMonth;
    }

    // Se não especificado, calcular baseado no dia da rescisão
    final daysInMonth = input.terminationDate.day;
    return (input.baseSalary / 30) * daysInMonth;
  }

  double _calculateNoticeAmount(TerminationInput input, TerminationType type) {
    final taxService = TaxTablesService.instance;
    final yearsOfService = input.terminationDate.difference(input.admissionDate).inDays / 365;

    final baseDays = taxService.getAvisoPrevioBaseDays();
    final daysPerYear = taxService.getAvisoPrevioDaysPerYear();
    final maxDays = taxService.getAvisoPrevioMaxDays();

    final noticeDays = baseDays + (yearsOfService.floor() * daysPerYear);
    final cappedNoticeDays = noticeDays > maxDays ? maxDays.toDouble() : noticeDays.toDouble();

    double noticeAmount = ((input.baseSalary + input.averageAdditions) / 30) * cappedNoticeDays;

    // Em acordo mútuo, o aviso prévio é reduzido para 50%
    if (type == TerminationType.mutualAgreement) {
      noticeAmount = noticeAmount * 0.5;
    }

    return noticeAmount;
  }

  double _calculateThirteenthSalary(TerminationInput input) {
    // Calcular apenas os meses trabalhados no ano da rescisão
    final currentYear = input.terminationDate.year;
    final admissionYear = input.admissionDate.year;

    if (currentYear == admissionYear) {
      // Mesmo ano: calcular meses do ano atual
      final monthsInCurrentYear = (input.terminationDate.month - input.admissionDate.month).toDouble();
      return (input.baseSalary + input.averageAdditions) * (monthsInCurrentYear / 12);
    } else {
      // Anos diferentes: calcular apenas os meses do ano da rescisão
      // Se a rescisão é em janeiro, não há 13º proporcional
      if (input.terminationDate.month == 1) {
        return 0.0;
      }
      final monthsInCurrentYear = input.terminationDate.month.toDouble();
      return (input.baseSalary + input.averageAdditions) * (monthsInCurrentYear / 12);
    }
  }

  double _calculateAccruedVacation(TerminationInput input) {
    return input.baseSalary + (input.baseSalary / 3);
  }

  double _calculateProportionalVacation(TerminationInput input) {
    // Calcular apenas os meses trabalhados no ano da rescisão
    final currentYear = input.terminationDate.year;
    final admissionYear = input.admissionDate.year;

    double monthsInCurrentYear;
    if (currentYear == admissionYear) {
      // Mesmo ano: calcular meses do ano atual
      monthsInCurrentYear = (input.terminationDate.month - input.admissionDate.month).toDouble();
    } else {
      // Anos diferentes: calcular apenas os meses do ano da rescisão
      // Se a rescisão é em janeiro, não há férias proporcionais
      if (input.terminationDate.month == 1) {
        return 0.0;
      }
      monthsInCurrentYear = input.terminationDate.month.toDouble();
    }

    final proportionalSalary = ((input.baseSalary + input.averageAdditions) * monthsInCurrentYear) / 12;
    return proportionalSalary + (proportionalSalary / 3);
  }

  double _calculateFgts(TerminationInput input, TerminationType type) {
    // FGTS só é pago em demissão sem justa causa e acordo mútuo
    if (!type.hasFgtsPenalty && type != TerminationType.mutualAgreement) {
      return 0.0;
    }

    final taxService = TaxTablesService.instance;
    final fgtsAliquota = taxService.getFgtsAliquota();
    final monthlyFgts = (input.baseSalary + input.averageAdditions) * fgtsAliquota;
    final monthsWorked = _calculateMonthsWorked(input);
    return monthlyFgts * monthsWorked;
  }

  double _calculateFgtsPenalty(TerminationInput input) {
    final taxService = TaxTablesService.instance;
    final penaltyAliquota = taxService.getFgtsPenaltyAliquota();

    if (input.hasExistingFgts && input.existingFgtsAmount > 0) {
      return input.existingFgtsAmount * penaltyAliquota;
    }

    // Aproximação baseada no tempo de serviço
    final monthsWorked = _calculateMonthsWorked(input);
    final averageMonthlySalary = input.baseSalary + input.averageAdditions;
    final fgtsAliquota = taxService.getFgtsAliquota();
    final estimatedFgts = (averageMonthlySalary * fgtsAliquota) * monthsWorked;
    return estimatedFgts * penaltyAliquota;
  }

  double _calculateInssDiscount(TerminationInput input) {
    final baseValue = input.baseSalary + input.averageAdditions;
    final taxService = TaxTablesService.instance;
    return taxService.calculateInss(baseValue);
  }

  double _calculateIrrfDiscount(TerminationInput input, double inssDiscount) {
    final baseValue = input.baseSalary + input.averageAdditions - inssDiscount;
    final taxService = TaxTablesService.instance;
    return taxService.calculateIrrf(baseValue, input.terminationDate);
  }

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
