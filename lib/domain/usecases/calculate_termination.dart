import 'package:decimal/decimal.dart';

import '../entities/assumption.dart';
import '../entities/breakdown_code.dart';
import '../entities/breakdown_item.dart';
import '../entities/termination_input.dart';
import '../entities/termination_result.dart';
import '../entities/termination_type.dart';
import '../rules/avos.dart';
import '../rules/fixed_term.dart';
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

  static final Decimal _zero = Decimal.zero;

  /// Fronteira de entrada (B2-14): `double` vira [Decimal] pelo texto, sem herdar
  /// a imprecisão binária.
  Decimal _dec(double value) => Decimal.parse(value.toString());

  /// Arredonda valores monetários (half-up; valores nunca negativos) para o número
  /// de casas decimais configurado, nos mesmos pontos de sempre (B2-13).
  Decimal _roundCurrency(Decimal value) =>
      value.round(scale: AppConstants.decimalPlaces);

  /// Divisão com escala explícita (20 casas, bem além dos centavos). Os chamadores
  /// multiplicam antes e dividem uma única vez, então não há erro acumulado.
  Decimal _divide(Decimal numerator, int denominator) =>
      (numerator / Decimal.fromInt(denominator)).toDecimal(
        scaleOnInfinitePrecision: 20,
      );

  Decimal _sum(Iterable<BreakdownItem> items) =>
      items.fold(_zero, (sum, item) => sum + _dec(item.value));

  /// Calcula a rescisão trabalhista baseada nos dados fornecidos.
  ///
  /// Throws [CalculationException] se houver erro no cálculo
  TerminationResult execute(TerminationInput input, TerminationType type) {
    try {
      AppLogger.info('Iniciando cálculo de rescisão: ${type.label}');
      final rules = TerminationRules.resolve(type, input.hasRecipientClause);
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
      final baseSalary = _dec(input.baseSalary);
      final monthlyBase = baseSalary + _dec(input.averageAdditions);
      final noticeIndemnified = rules.noticePercent > 0 && !input.noticeWorked;
      final paidNoticeDays = noticeIndemnified
          ? noticeDays * rules.noticePercent ~/ 100
          : 0;
      // C2: projeção por data do aviso indenizado nas avos (CLT art. 487 §1º;
      // OJ 82 SDI-1 TST). Data de calendário, sem horário. ⚖️
      final term = input.terminationDate;
      final noticeEnd = DateTime(
        term.year,
        term.month,
        term.day + paidNoticeDays,
      );

      // 1. Saldo de salário
      final daysWorked = input.workedDaysInMonth > 0
          ? input.workedDaysInMonth
          : input.terminationDate.day;
      final salaryBalance = _roundCurrency(
        _divide(baseSalary * Decimal.fromInt(daysWorked), 30),
      );
      additions.add(
        BreakdownItem(
          code: BreakdownCode.salaryBalance,
          description: 'Saldo de Salário',
          value: salaryBalance.toDouble(),
          type: BreakdownType.addition,
          details:
              '$daysWorked dias × R\$ ${_roundCurrency(_divide(baseSalary, 30)).toStringAsFixed(2)}',
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
              _divide(
                monthlyBase * Decimal.fromInt(noticeDays * rules.noticePercent),
                3000,
              ),
            ).toDouble(),
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
            value: _roundCurrency(
              _divide(monthlyBase * Decimal.fromInt(noticeDays), 30),
            ).toDouble(),
            type: BreakdownType.deduction,
            details: 'Aviso prévio não cumprido pelo empregado',
          ),
        );
      }

      // 3. 13º salário proporcional (Lei 4.090/62)
      var thirteenthSalary = _zero;
      var extraThirteenth = 0;
      var extraVacation = 0;
      var thirteenthDecomposition = '';
      if (rules.paysThirteenth) {
        final avos = thirteenthMonths(
          input.admissionDate,
          input.terminationDate,
          noticeEnd: noticeEnd,
        );
        extraThirteenth =
            avos - thirteenthMonths(input.admissionDate, input.terminationDate);
        assumptions.add(
          _monthsAssumption(
            AssumptionCode.thirteenthMonths,
            '13º salário',
            avos,
          ),
        );
        if (noticeEnd.year > term.year) {
          final a = thirteenthMonths(
            input.admissionDate,
            input.terminationDate,
            noticeEnd: DateTime(term.year, 12, 31),
          );
          thirteenthDecomposition =
              ' ($a do ano ${term.year} + ${avos - a} do ano ${noticeEnd.year})';
        }
        thirteenthSalary = _roundCurrency(
          _divide(monthlyBase * Decimal.fromInt(avos), 12),
        );
        if (thirteenthSalary > _zero) {
          additions.add(
            BreakdownItem(
              code: BreakdownCode.thirteenth,
              description: '13º Salário Proporcional',
              value: thirteenthSalary.toDouble(),
              type: BreakdownType.addition,
              details: '$avos/12$thirteenthDecomposition',
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
          noticeEnd: noticeEnd,
        );
        extraVacation =
            avos -
            proportionalVacationMonths(
              input.admissionDate,
              input.terminationDate,
            );
        assumptions.add(
          _monthsAssumption(
            AssumptionCode.vacationMonths,
            'férias proporcionais',
            avos,
          ),
        );
        // base × avos/12 × 4/3 (salário + 1/3), dividido uma única vez por 9.
        final proportionalVacation = _roundCurrency(
          _divide(monthlyBase * Decimal.fromInt(avos), 9),
        );
        if (proportionalVacation > _zero) {
          additions.add(
            BreakdownItem(
              code: BreakdownCode.proportionalVacation,
              description: 'Férias Proporcionais + 1/3',
              value: proportionalVacation.toDouble(),
              type: BreakdownType.addition,
              details: '$avos/12 do período aquisitivo',
            ),
          );
        }
      }

      // Premissa da projeção (B2-10): data de fim do aviso e avos extras reais.
      if (paidNoticeDays > 0) {
        final clauses = [
          if (rules.paysThirteenth) '+$extraThirteenth avo(s) no 13º',
          if (rules.paysProportionalVacation)
            '+$extraVacation avo(s) nas férias proporcionais',
        ];
        assumptions.add(
          Assumption(
            code: AssumptionCode.noticeProjection,
            text:
                'Aviso indenizado projetado até ${Formatters.formatDate(noticeEnd)}: ${clauses.join(' e ')}.',
            origin: AssumptionOrigin.estimated,
            value: paidNoticeDays.toDouble(),
          ),
        );
        final pendingRule = rules.noticeProjectionPendingRule;
        if (pendingRule != null) {
          assumptions.addAll(_validationPending(pendingRule));
        }
      }

      // 5.1. Art. 479 CLT: metade da remuneração até o termo, fora de INSS e IRRF ⚖️
      final fixedTermEnd = input.fixedTermEndDate;
      final daysLeft = fixedTermEnd == null
          ? 0
          : remainingDays(fixedTermEnd, input.terminationDate);
      final indemnity = _indemnity479(monthlyBase, daysLeft);
      if (rules.hasIndemnity479 && indemnity > _zero) {
        additions.add(
          BreakdownItem(
            code: BreakdownCode.indemnity479,
            description: 'Indenização Art. 479 (término antecipado)',
            value: indemnity.toDouble(),
            type: BreakdownType.addition,
            details:
                '50% da remuneração dos $daysLeft dias restantes do contrato',
          ),
        );
        assumptions.addAll(_validationPending('art479'));
      }

      // 5.2. Art. 480 CLT: desconto limitado a 1 remuneração mensal (art. 477 §5º) ⚖️
      if (rules.hasDiscount480 && indemnity > _zero) {
        final discount480 = indemnity < monthlyBase ? indemnity : monthlyBase;
        deductions.add(
          BreakdownItem(
            code: BreakdownCode.indemnity480,
            description: 'Indenização Art. 480 (saída antecipada)',
            value: discount480.toDouble(),
            type: BreakdownType.deduction,
            details:
                'Limitada a 1 remuneração mensal; metade da remuneração dos dias restantes',
          ),
        );
        assumptions.add(
          Assumption(
            code: AssumptionCode.indemnity480Cap,
            text:
                'Indenização do art. 480: valor máximo; depende de comprovação do prejuízo.',
            origin: AssumptionOrigin.estimated,
            value: discount480.toDouble(),
          ),
        );
        assumptions.addAll(_validationPending('art480'));
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
            ? _dec(input.existingFgtsAmount)
            : _estimateFgts(input);
        final fineRate =
            taxService.getFgtsPenaltyAliquota() * _dec(rules.fgtsFineShare);
        final percent = (fineRate * Decimal.fromInt(100))
            .round()
            .toBigInt()
            .toInt();
        assumptions.add(
          Assumption(
            code: AssumptionCode.fgtsBalance,
            text: fgtsInformed
                ? 'Saldo do FGTS informado por você.'
                : 'Saldo do FGTS estimado pelo tempo de serviço.',
            origin: fgtsInformed
                ? AssumptionOrigin.informed
                : AssumptionOrigin.estimated,
            value: _roundCurrency(fgtsBalance).toDouble(),
          ),
        );
        fgtsItems.add(
          BreakdownItem(
            code: BreakdownCode.fgtsFine,
            description: 'Multa FGTS ($percent%)',
            value: _roundCurrency(fgtsBalance * fineRate).toDouble(),
            type: BreakdownType.addition,
            details: '$percent% sobre FGTS do vínculo',
          ),
        );
      }

      // 7. Descontos. C4: férias fora das bases de INSS e IRRF; C5: INSS separado.
      if (input.calculateTaxes) {
        final taxes = TaxTablesService.instance.calculateTerminationTaxes(
          salaryBalance: salaryBalance,
          thirteenthSalary: thirteenthSalary,
          terminationDate: input.terminationDate,
          dependents: input.dependents,
        );
        if (taxes.inss > _zero) {
          deductions.add(
            BreakdownItem(
              code: BreakdownCode.inss,
              description: 'INSS',
              value: taxes.inss.toDouble(),
              type: BreakdownType.deduction,
              details: 'Sobre saldo de salário e 13º proporcional',
            ),
          );
        }
        if (taxes.irrf > _zero) {
          deductions.add(
            BreakdownItem(
              code: BreakdownCode.irrf,
              description: 'IRRF',
              value: _roundCurrency(taxes.irrf).toDouble(),
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
            value: _roundCurrency(_dec(input.otherDiscounts)).toDouble(),
            type: BreakdownType.deduction,
            details: 'Descontos diversos',
          ),
        );
      }

      final totalAdditions = _roundCurrency(_sum(additions));
      final totalDeductions = _roundCurrency(_sum(deductions));
      final fgtsDeposit = FgtsDeposit(items: fgtsItems);
      final paidAtTermination = _roundCurrency(
        totalAdditions - totalDeductions,
      );

      final result = TerminationResult(
        additions: additions,
        deductions: deductions,
        totalDeductions: totalDeductions.toDouble(),
        calculationDate: DateTime.now(),
        paidAtTermination: paidAtTermination.toDouble(),
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
      'art479' =>
        'Cálculo em validação: indenização do término antecipado pelo empregador (CLT art. 479).',
      'art480' =>
        'Cálculo em validação: indenização do término antecipado pelo empregado (CLT art. 480).',
      'noticeProjectionMutualAgreement' =>
        'Cálculo em validação: projeção do aviso no acordo mútuo (CLT art. 484-A).',
      _ => 'Cálculo em validação.',
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

  /// Art. 479 CLT: (salário + média) / 30 × dias restantes × 50 %, multiplicando
  /// antes de dividir uma única vez (convenção B2-13).
  Decimal _indemnity479(Decimal monthlyBase, int days) =>
      _roundCurrency(_divide(monthlyBase * Decimal.fromInt(days), 60));

  /// Um item por código: simples = base × 4/3 por período; dobro = 2 × base × 4/3
  /// (1/3 sobre o total dobrado, Súmula 328 TST). Fora de INSS/IRRF (C4).
  List<BreakdownItem> _accruedVacationItems(
    Decimal base,
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
          value: _roundCurrency(
            _divide(base * Decimal.fromInt(simple * 4), 3),
          ).toDouble(),
          type: BreakdownType.addition,
          details:
              '$simple ${simple == 1 ? 'período' : 'períodos'} (salário + 1/3 constitucional)',
        ),
      if (doubled > 0)
        BreakdownItem(
          code: BreakdownCode.accruedVacationDouble,
          description: 'Férias em Dobro + 1/3 (indenização)',
          value: _roundCurrency(
            _divide(base * Decimal.fromInt(doubled * 8), 3),
          ).toDouble(),
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
  Decimal _estimateFgts(TerminationInput input) {
    final averageMonthlySalary =
        _dec(input.baseSalary) + _dec(input.averageAdditions);
    return (averageMonthlySalary *
            TaxTablesService.instance.getFgtsAliquota()) *
        Decimal.fromInt(_calculateMonthsWorked(input));
  }

  /// Meses entre admissão e rescisão (conta o mês se o dia da rescisão >= dia da admissão).
  int _calculateMonthsWorked(TerminationInput input) {
    final years = input.terminationDate.year - input.admissionDate.year;
    final months = input.terminationDate.month - input.admissionDate.month;
    final totalMonths = (years * 12) + months;
    if (input.terminationDate.day >= input.admissionDate.day) {
      return totalMonths;
    }
    return totalMonths - 1;
  }
}
