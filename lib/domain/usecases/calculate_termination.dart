import '../entities/assumption.dart';
import '../entities/breakdown_code.dart';
import '../entities/breakdown_item.dart';
import '../entities/termination_input.dart';
import '../entities/termination_result.dart';
import '../entities/termination_type.dart';
import '../rules/avos.dart';
import '../rules/termination_rules.dart';
import '../rules/vacation_periods.dart';
import '../../core/services/tax_tables_service.dart';
import '../../core/utils/logger.dart';
import '../../core/exceptions/app_exceptions.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

/// Use case responsável por calcular rescisões trabalhistas conforme a CLT.
///
/// As regras por tipo de rescisão vêm de [TerminationRules]; o use case decide
/// quais verbas entram antes de adicioná-las (nunca remove itens depois).
class CalculateTerminationUseCase {
  const CalculateTerminationUseCase();

  /// Arredonda valores monetários para o número de casas decimais configurado.
  double _roundCurrency(double value) {
    try {
      return double.parse(value.toStringAsFixed(AppConstants.decimalPlaces));
    } catch (e) {
      AppLogger.error('Erro ao arredondar valor monetário', e);
      return value;
    }
  }

  /// Calcula a rescisão trabalhista baseada nos dados fornecidos.
  ///
  /// Throws [CalculationException] se houver erro no cálculo
  TerminationResult execute(TerminationInput input, TerminationType type) {
    try {
      AppLogger.info('Iniciando cálculo de rescisão: ${type.label}');
      final rules = TerminationRules.of(type);
      final additions = <BreakdownItem>[];
      final deductions = <BreakdownItem>[];
      final fgtsItems = <BreakdownItem>[];
      final assumptions = <Assumption>[
        const Assumption(
          code: AssumptionCode.thirtyDayMonth,
          text: 'Saldo de salário e aviso prévio usam mês de 30 dias.',
          origin: AssumptionOrigin.estimated,
        ),
      ];

      final noticeDays = _noticeDays(input);
      final monthlyBase = input.baseSalary + input.averageAdditions;
      final noticeIndemnified = rules.noticePercent > 0 && !input.noticeWorked;
      final paidNoticeDays = noticeIndemnified
          ? noticeDays * rules.noticePercent ~/ 100
          : 0;
      // C2: projeção do aviso indenizado nas avos (CLT art. 487 §1º; OJ 82 SDI-1 TST). ⚖️
      final projection = noticeProjectionMonths(paidNoticeDays);

      // 1. Saldo de salário
      final daysWorked = input.workedDaysInMonth > 0
          ? input.workedDaysInMonth
          : input.terminationDate.day;
      additions.add(
        BreakdownItem(
          code: BreakdownCode.salaryBalance,
          description: 'Saldo de Salário',
          value: _roundCurrency((input.baseSalary / 30) * daysWorked),
          type: BreakdownType.addition,
          details:
              '$daysWorked dias × R\$ ${(input.baseSalary / 30).toStringAsFixed(2)}',
        ),
      );

      // 2. Aviso prévio indenizado (percentual por tipo; fração aplicada antes de arredondar)
      if (noticeIndemnified) {
        final isFull = rules.noticePercent == 100;
        additions.add(
          BreakdownItem(
            code: BreakdownCode.notice,
            description: isFull
                ? 'Aviso Prévio Indenizado'
                : 'Aviso Prévio Indenizado (${rules.noticePercent}%)',
            value: _roundCurrency(
              (monthlyBase / 30) * noticeDays * rules.noticePercent / 100,
            ),
            type: BreakdownType.addition,
            details: isFull
                ? '30 dias + adicional por tempo de serviço'
                : '${rules.noticePercent}% do aviso prévio (acordo mútuo)',
          ),
        );
      }

      // 2.1. Desconto de aviso prévio não cumprido pelo empregado (CLT art. 487 §2º)
      if (!input.noticeWorked && rules.noticeDeductible) {
        deductions.add(
          BreakdownItem(
            code: BreakdownCode.noticeDiscount,
            description: 'Desconto Aviso Prévio',
            value: _roundCurrency((monthlyBase / 30) * noticeDays),
            type: BreakdownType.deduction,
            details: 'Aviso prévio não cumprido pelo empregado',
          ),
        );
      }

      if (projection > 0) {
        assumptions.add(
          Assumption(
            code: AssumptionCode.noticeProjection,
            text:
                'Aviso indenizado projetado em 13º e férias proporcionais: +$projection mês(es).',
            origin: AssumptionOrigin.estimated,
            value: projection.toDouble(),
          ),
        );
        if (type == TerminationType.mutualAgreement) {
          assumptions.addAll(
            _validationPending('noticeProjectionMutualAgreement'),
          );
        }
      }

      // 3. 13º salário proporcional (Lei 4.090/62)
      var thirteenthSalary = 0.0;
      if (rules.paysThirteenth) {
        final avos = thirteenthMonths(
          input.admissionDate,
          input.terminationDate,
          projection: projection,
        );
        assumptions.add(
          _monthsAssumption(
            AssumptionCode.thirteenthMonths,
            '13º salário',
            avos,
          ),
        );
        thirteenthSalary = _roundCurrency(monthlyBase * avos / 12);
        if (thirteenthSalary > 0) {
          additions.add(
            BreakdownItem(
              code: BreakdownCode.thirteenth,
              description: '13º Salário Proporcional',
              value: thirteenthSalary,
              type: BreakdownType.addition,
              details: '$avos/12 do ano da rescisão',
            ),
          );
        }
      }

      // 4. Férias vencidas: simples e em dobro por período derivado (C1: devidas em
      // qualquer rescisão, CLT art. 146 caput; dobro: CLT art. 137, Súmula 328 TST) ⚖️
      final vacation = VacationPeriods.derive(
        input.admissionDate,
        input.terminationDate,
        input.vacationPeriodsTaken,
      );
      final hasDoublePeriod = vacation.periods.any(
        (p) => p.status == VacationPeriodStatus.double,
      );
      if (rules.paysAccruedVacation) {
        additions.addAll(_accruedVacationItems(monthlyBase, vacation.periods));
      }
      final hasOverduePeriod = vacation.periods.any(
        (p) =>
            p.status == VacationPeriodStatus.simple ||
            p.status == VacationPeriodStatus.double,
      );
      if (rules.paysProportionalVacation ||
          (rules.paysAccruedVacation && hasOverduePeriod)) {
        assumptions.add(_vacationPeriodsAssumption(vacation.periods));
      }
      if (rules.paysAccruedVacation && hasDoublePeriod) {
        assumptions.addAll(_validationPending('doubleVacation'));
      }

      // 5. Férias proporcionais + 1/3 (C3: período aquisitivo desde o aniversário) ⚖️
      if (rules.paysProportionalVacation) {
        final avos = proportionalVacationMonths(
          input.admissionDate,
          input.terminationDate,
          projection: projection,
        );
        assumptions.add(
          _monthsAssumption(
            AssumptionCode.vacationMonths,
            'férias proporcionais',
            avos,
          ),
        );
        final proportionalSalary = (monthlyBase * avos) / 12;
        final proportionalVacation = _roundCurrency(
          proportionalSalary + (proportionalSalary / 3),
        );
        if (proportionalVacation > 0) {
          additions.add(
            BreakdownItem(
              code: BreakdownCode.proportionalVacation,
              description: 'Férias Proporcionais + 1/3',
              value: proportionalVacation,
              type: BreakdownType.addition,
              details: '$avos/12 do período aquisitivo',
            ),
          );
        }
      }
      if (rules.paysThirteenth || rules.paysProportionalVacation) {
        assumptions.add(
          const Assumption(
            code: AssumptionCode.fifteenDayRule,
            text: 'Mês com menos de 15 dias trabalhados não conta nos avos.',
            origin: AssumptionOrigin.estimated,
          ),
        );
      }

      // 6. Multa do FGTS: depositada na conta do FGTS, não paga na rescisão
      if (rules.paysFgtsFine) {
        final taxService = TaxTablesService.instance;
        final fgtsInformed =
            input.hasExistingFgts && input.existingFgtsAmount > 0;
        final fgtsBalance = fgtsInformed
            ? input.existingFgtsAmount
            : _estimateFgts(input);
        final fineRate =
            taxService.getFgtsPenaltyAliquota() * rules.fgtsFineShare;
        final percent = (fineRate * 100).round();
        assumptions.add(
          Assumption(
            code: AssumptionCode.fgtsBalance,
            text: fgtsInformed
                ? 'Saldo do FGTS informado por você.'
                : 'Saldo do FGTS estimado pelo tempo de serviço.',
            origin: fgtsInformed
                ? AssumptionOrigin.informed
                : AssumptionOrigin.estimated,
            value: _roundCurrency(fgtsBalance),
          ),
        );
        fgtsItems.add(
          BreakdownItem(
            code: BreakdownCode.fgtsFine,
            description: 'Multa FGTS ($percent%)',
            value: _roundCurrency(fgtsBalance * fineRate),
            type: BreakdownType.addition,
            details: '$percent% sobre FGTS do vínculo',
          ),
        );
      }

      // 7. Descontos. C4: férias fora das bases de INSS e IRRF; C5: INSS separado.
      if (input.calculateTaxes) {
        final salaryBalance = additions.first.value;
        final taxes = TaxTablesService.instance.calculateTerminationTaxes(
          salaryBalance: salaryBalance,
          thirteenthSalary: thirteenthSalary,
          terminationDate: input.terminationDate,
          dependents: input.dependents,
        );
        if (taxes.inss > 0) {
          deductions.add(
            BreakdownItem(
              code: BreakdownCode.inss,
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
              code: BreakdownCode.irrf,
              description: 'IRRF',
              value: _roundCurrency(taxes.irrf),
              type: BreakdownType.deduction,
              details:
                  'Sobre saldo de salário e 13º (férias não entram na base)',
            ),
          );
        }
      }

      // 8. Outros descontos
      if (input.otherDiscounts > 0) {
        deductions.add(
          BreakdownItem(
            code: BreakdownCode.otherDiscounts,
            description: 'Outros Descontos',
            value: _roundCurrency(input.otherDiscounts),
            type: BreakdownType.deduction,
            details: 'Descontos diversos',
          ),
        );
      }

      final totalAdditions = _roundCurrency(
        additions.fold(0.0, (sum, item) => sum + item.value),
      );
      final totalDeductions = _roundCurrency(
        deductions.fold(0.0, (sum, item) => sum + item.value),
      );
      final fgtsDeposit = FgtsDeposit(items: fgtsItems);
      final paidAtTermination = _roundCurrency(
        totalAdditions - totalDeductions,
      );

      final result = TerminationResult(
        additions: additions,
        deductions: deductions,
        totalDeductions: totalDeductions,
        calculationDate: DateTime.now(),
        paidAtTermination: paidAtTermination,
        fgtsDeposit: fgtsDeposit,
        assumptions: assumptions,
      );

      AppLogger.info('Cálculo concluído.');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao calcular rescisão', e, stackTrace);
      throw CalculationException(
        'Erro ao calcular rescisão. Verifique os dados informados.',
        originalError: e,
      );
    }
  }

  Assumption _monthsAssumption(AssumptionCode code, String label, int avos) {
    return Assumption(
      code: code,
      text: 'Avos de $label: $avos/12.',
      origin: AssumptionOrigin.estimated,
      value: avos.toDouble(),
    );
  }

  /// Premissa "cálculo em validação" (B6-04) para regra ainda sem caso golden com fonte.
  List<Assumption> _validationPending(String ruleId) {
    if (!validationPendingRules.contains(ruleId)) {
      return const [];
    }
    final text = switch (ruleId) {
      'doubleVacation' =>
        'Cálculo em validação: férias em dobro quando o prazo de concessão venceu (CLT art. 137; Súmula 328 TST).',
      _ =>
        'Cálculo em validação: projeção do aviso no acordo mútuo (CLT art. 484-A).',
    };
    return [
      Assumption(
        code: AssumptionCode.validationPending,
        text: text,
        origin: AssumptionOrigin.estimated,
        ruleId: ruleId,
      ),
    ];
  }

  /// Um item por código: simples = base × 4/3 por período; dobro = 2 × base × 4/3
  /// (1/3 sobre o total dobrado, Súmula 328 TST). Fora de INSS/IRRF (C4).
  List<BreakdownItem> _accruedVacationItems(
    double base,
    List<VacationPeriod> periods,
  ) {
    final simple = periods
        .where((p) => p.status == VacationPeriodStatus.simple)
        .length;
    final doubled = periods
        .where((p) => p.status == VacationPeriodStatus.double)
        .length;
    return [
      if (simple > 0)
        BreakdownItem(
          code: BreakdownCode.accruedVacationSimple,
          description: 'Férias Vencidas + 1/3',
          value: _roundCurrency(simple * base * 4 / 3),
          type: BreakdownType.addition,
          details:
              '$simple ${simple == 1 ? 'período' : 'períodos'} (salário + 1/3 constitucional)',
        ),
      if (doubled > 0)
        BreakdownItem(
          code: BreakdownCode.accruedVacationDouble,
          description: 'Férias em Dobro + 1/3 (indenização)',
          value: _roundCurrency(doubled * 2 * base * 4 / 3),
          type: BreakdownType.addition,
          details:
              '$doubled ${doubled == 1 ? 'período' : 'períodos'} com prazo de concessão vencido',
        ),
    ];
  }

  /// Tabela dos períodos derivados, uma linha por período (B3-07).
  Assumption _vacationPeriodsAssumption(List<VacationPeriod> periods) {
    final lines = periods.map((p) {
      final start = Formatters.formatDate(p.acquisitiveStart);
      if (p.status == VacationPeriodStatus.proportional) {
        return '${p.index}) desde $start: proporcional';
      }
      final end = Formatters.formatDate(
        DateTime(
          p.acquisitiveEnd.year,
          p.acquisitiveEnd.month,
          p.acquisitiveEnd.day - 1,
        ),
      );
      final status = switch (p.status) {
        VacationPeriodStatus.taken => 'gozado',
        VacationPeriodStatus.simple => 'simples',
        _ => 'dobro',
      };
      return '${p.index}) $start–$end, concessivo até ${Formatters.formatDate(p.concessiveEnd)}: $status';
    });
    return Assumption(
      code: AssumptionCode.vacationPeriods,
      text: lines.join('\n'),
      origin: AssumptionOrigin.estimated,
    );
  }

  /// Dias do aviso prévio: base + dias por ano de serviço, até o máximo da tabela.
  int _noticeDays(TerminationInput input) {
    final taxService = TaxTablesService.instance;
    final yearsOfService =
        input.terminationDate.difference(input.admissionDate).inDays / 365;
    final noticeDays =
        taxService.getAvisoPrevioBaseDays() +
        (yearsOfService.floor() * taxService.getAvisoPrevioDaysPerYear());
    final maxDays = taxService.getAvisoPrevioMaxDays();
    return noticeDays > maxDays ? maxDays : noticeDays;
  }

  /// Estima o saldo do FGTS pelo tempo de serviço quando o usuário não informa.
  double _estimateFgts(TerminationInput input) {
    final averageMonthlySalary = input.baseSalary + input.averageAdditions;
    return (averageMonthlySalary *
            TaxTablesService.instance.getFgtsAliquota()) *
        _calculateMonthsWorked(input);
  }

  /// Meses entre admissão e rescisão (conta o mês se o dia da rescisão >= dia da admissão).
  double _calculateMonthsWorked(TerminationInput input) {
    final years = input.terminationDate.year - input.admissionDate.year;
    final months = input.terminationDate.month - input.admissionDate.month;
    final totalMonths = (years * 12) + months;
    if (input.terminationDate.day >= input.admissionDate.day) {
      return totalMonths.toDouble();
    }
    return (totalMonths - 1).toDouble();
  }
}
