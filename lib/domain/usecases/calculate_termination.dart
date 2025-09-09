import '../entities/termination_input.dart';
import '../entities/termination_result.dart';
import '../entities/breakdown_item.dart';
import '../entities/termination_type.dart';

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
        details: '${input.workedDaysInMonth} dias × R\$ ${(input.baseSalary / 30).toStringAsFixed(2)}',
      ),
    );

    // 2. Aviso prévio indenizado
    if (!input.noticeWorked) {
      final noticeAmount = _calculateNoticeAmount(input);
      additions.add(
        BreakdownItem(
          description: 'Aviso Prévio Indenizado',
          value: noticeAmount,
          type: BreakdownType.addition,
          details: '30 dias + adicional por tempo de serviço',
        ),
      );
    }

    // 3. 13º Salário Proporcional
    final thirteenthSalary = _calculateThirteenthSalary(input);
    additions.add(
      BreakdownItem(
        description: '13º Salário Proporcional',
        value: thirteenthSalary,
        type: BreakdownType.addition,
        details: 'Proporcional aos meses trabalhados',
      ),
    );

    // 4. Férias vencidas
    if (input.hasAccruedVacation) {
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

    // 5. Férias proporcionais
    final proportionalVacation = _calculateProportionalVacation(input);
    additions.add(
      BreakdownItem(
        description: 'Férias Proporcionais + 1/3',
        value: proportionalVacation,
        type: BreakdownType.addition,
        details: 'Proporcional aos meses trabalhados',
      ),
    );

    // 6. FGTS
    final fgtsAmount = _calculateFgts(input, type);
    additions.add(
      BreakdownItem(
        description: 'FGTS',
        value: fgtsAmount,
        type: BreakdownType.addition,
        details: '8% sobre remuneração',
      ),
    );

    // 7. Multa FGTS (se aplicável)
    if (type.hasFgtsPenalty) {
      final fgtsPenalty = _calculateFgtsPenalty(input);
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

    final daysInMonth = input.terminationDate.day;
    return (input.baseSalary / 30) * daysInMonth;
  }

  double _calculateNoticeAmount(TerminationInput input) {
    final yearsOfService = input.terminationDate.difference(input.admissionDate).inDays / 365;
    final noticeDays = 30 + (yearsOfService.floor() * 3);
    final cappedNoticeDays = noticeDays > 90 ? 90.0 : noticeDays;

    return ((input.baseSalary + input.averageAdditions) / 30) * cappedNoticeDays;
  }

  double _calculateThirteenthSalary(TerminationInput input) {
    final monthsWorked = _calculateMonthsWorked(input);
    return (input.baseSalary + input.averageAdditions) * (monthsWorked / 12);
  }

  double _calculateAccruedVacation(TerminationInput input) {
    return input.baseSalary + (input.baseSalary / 3);
  }

  double _calculateProportionalVacation(TerminationInput input) {
    final monthsWorked = _calculateMonthsWorked(input);
    final proportionalSalary = (input.baseSalary * monthsWorked) / 12;
    return proportionalSalary + (proportionalSalary / 3);
  }

  double _calculateFgts(TerminationInput input, TerminationType type) {
    final monthlyFgts = (input.baseSalary + input.averageAdditions) * 0.08;
    final monthsWorked = _calculateMonthsWorked(input);
    return monthlyFgts * monthsWorked;
  }

  double _calculateFgtsPenalty(TerminationInput input) {
    if (input.hasExistingFgts && input.existingFgtsAmount > 0) {
      return input.existingFgtsAmount * 0.4;
    }

    // Aproximação baseada no tempo de serviço
    final monthsWorked = _calculateMonthsWorked(input);
    final averageMonthlySalary = input.baseSalary + input.averageAdditions;
    final estimatedFgts = (averageMonthlySalary * 0.08) * monthsWorked;
    return estimatedFgts * 0.4;
  }

  double _calculateInssDiscount(TerminationInput input) {
    final baseValue = input.baseSalary + input.averageAdditions;

    // Tabela INSS simplificada (2024)
    if (baseValue <= 1412.0) {
      return baseValue * 0.075;
    } else if (baseValue <= 2666.68) {
      return baseValue * 0.09;
    } else if (baseValue <= 4000.03) {
      return baseValue * 0.12;
    } else {
      return baseValue * 0.14;
    }
  }

  double _calculateIrrfDiscount(TerminationInput input, double inssDiscount) {
    final baseValue = input.baseSalary + input.averageAdditions - inssDiscount;

    // Tabela IRRF simplificada (2024) - sem dependentes
    if (baseValue <= 2259.20) {
      return 0;
    } else if (baseValue <= 2826.65) {
      return (baseValue * 0.075) - 169.44;
    } else if (baseValue <= 3751.05) {
      return (baseValue * 0.15) - 381.44;
    } else if (baseValue <= 4664.68) {
      return (baseValue * 0.225) - 662.77;
    } else {
      return (baseValue * 0.275) - 896.00;
    }
  }

  double _calculateMonthsWorked(TerminationInput input) {
    final difference = input.terminationDate.difference(input.admissionDate);
    final totalDays = difference.inDays;
    final months = totalDays / 30.44; // Média de dias por mês

    // Considera mês completo se >= 15 dias
    if (totalDays % 30 >= 15) {
      return months.ceil().toDouble();
    }
    return months.floor().toDouble();
  }
}
