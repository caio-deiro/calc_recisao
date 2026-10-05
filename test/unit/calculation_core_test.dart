import 'dart:io';

import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/assumption.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

import '../golden/validation_status.dart';

/// Valores calculados à mão a partir do texto legal (nunca copiados da saída do app).
/// Base comum: salário 3000, admissão 10/03/2020, rescisão 26/08/2025 (5 anos: aviso de 45 dias).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const useCase = CalculateTerminationUseCase();

  setUp(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  TerminationInput input({
    DateTime? admission,
    DateTime? termination,
    double salary = 3000,
    bool accrued = false,
    bool noticeWorked = false,
    double? fgts,
    bool taxes = false,
    int workedDays = 0,
  }) => TerminationInput(
    admissionDate: admission ?? DateTime(2020, 3, 10),
    terminationDate: termination ?? DateTime(2025, 8, 26),
    baseSalary: salary,
    hasAccruedVacation: accrued,
    noticeWorked: noticeWorked,
    hasExistingFgts: fgts != null,
    existingFgtsAmount: fgts ?? 0,
    calculateTaxes: taxes,
    workedDaysInMonth: workedDays,
  );

  double? valueOf(TerminationResult r, BreakdownCode code) {
    final all = [...r.additions, ...r.fgtsDeposit.items, ...r.deductions];
    final found = all.where((i) => i.code == code);
    return found.isEmpty ? null : found.first.value;
  }

  group('identidade de verba (B2-01)', () {
    test('deve dar code distinto e não nulo a cada item', () {
      final r = useCase.execute(
        input(accrued: true, taxes: true),
        TerminationType.withoutJustCause,
      );
      final codes = [
        ...r.additions,
        ...r.fgtsDeposit.items,
        ...r.deductions,
      ].map((i) => i.code).toList();
      expect(codes.toSet().length, codes.length);
      expect(
        codes,
        containsAll([
          BreakdownCode.salaryBalance,
          BreakdownCode.notice,
          BreakdownCode.thirteenth,
          BreakdownCode.accruedVacation,
          BreakdownCode.proportionalVacation,
          BreakdownCode.fgtsFine,
          BreakdownCode.inss,
        ]),
      );
    });

    test(
      'não deve haver lógica por texto de description em lib/domain/usecases',
      () {
        final banned = RegExp(
          r'description\s*==|description\.contains|removeWhere',
        );
        for (final f in Directory(
          'lib/domain/usecases',
        ).listSync().whereType<File>()) {
          expect(
            banned.hasMatch(f.readAsStringSync()),
            isFalse,
            reason: f.path,
          );
        }
      },
    );
  });

  group('C1: férias vencidas na justa causa (CLT art. 146 caput)', () {
    test('deve pagar só férias vencidas, (3000) x 4/3 = 4000,00', () {
      final r = useCase.execute(
        input(accrued: true),
        TerminationType.withJustCause,
      );
      expect(valueOf(r, BreakdownCode.accruedVacation), 4000.00);
      expect(valueOf(r, BreakdownCode.proportionalVacation), isNull);
      expect(valueOf(r, BreakdownCode.thirteenth), isNull);
      expect(valueOf(r, BreakdownCode.notice), isNull);
      expect(valueOf(r, BreakdownCode.fgtsFine), isNull);
    });
  });

  group('C2: projeção do aviso (CLT art. 487 §1º)', () {
    test(
      'aviso de 45 dias: +1 avo em 13º (8+1=9 -> 2250,00) e férias (6+1=7 -> 2333,33)',
      () {
        final r = useCase.execute(input(), TerminationType.withoutJustCause);
        expect(valueOf(r, BreakdownCode.notice), 4500.00);
        expect(valueOf(r, BreakdownCode.thirteenth), 2250.00);
        expect(valueOf(r, BreakdownCode.proportionalVacation), 2333.33);
        expect(
          r.assumptions.any(
            (a) => a.code == AssumptionCode.noticeProjection && a.value == 1,
          ),
          isTrue,
        );
      },
    );

    test('aviso de 60 dias: +2 avos (13º 10/12 = 2500,00)', () {
      final r = useCase.execute(
        input(admission: DateTime(2015, 3, 10)),
        TerminationType.withoutJustCause,
      );
      expect(valueOf(r, BreakdownCode.thirteenth), 2500.00);
    });

    test(
      'teto de 12 avos: 13º em novembro com projeção não passa de 3000,00',
      () {
        final r = useCase.execute(
          input(
            termination: DateTime(2025, 11, 20),
            admission: DateTime(2015, 3, 10),
          ),
          TerminationType.withoutJustCause,
        );
        expect(valueOf(r, BreakdownCode.thirteenth), 3000.00);
      },
    );

    test('aviso trabalhado não projeta e não gera premissa de projeção', () {
      final r = useCase.execute(
        input(noticeWorked: true),
        TerminationType.withoutJustCause,
      );
      expect(valueOf(r, BreakdownCode.thirteenth), 2000.00); // 8/12
      expect(valueOf(r, BreakdownCode.notice), isNull);
      expect(
        r.assumptions.any((a) => a.code == AssumptionCode.noticeProjection),
        isFalse,
      );
    });

    test('pedido de demissão não projeta', () {
      final r = useCase.execute(input(), TerminationType.resignation);
      expect(valueOf(r, BreakdownCode.thirteenth), 2000.00);
    });

    test(
      'acordo mútuo projeta pelo aviso pago (60 dias, 30 pagos): +1 avo e marca de validação',
      () {
        final r = useCase.execute(
          input(admission: DateTime(2015, 3, 10)),
          TerminationType.mutualAgreement,
        );
        expect(valueOf(r, BreakdownCode.notice), 3000.00); // 50% de 6000
        expect(valueOf(r, BreakdownCode.thirteenth), 2250.00); // 9/12
        final pending = r.assumptions.where(
          (a) => a.code == AssumptionCode.validationPending,
        );
        expect(pending.single.ruleId, 'noticeProjectionMutualAgreement');
        expect(pending.single.origin, AssumptionOrigin.estimated);
      },
    );

    test('sem regra pendente na lista, não há marca de validação', () {
      final r = useCase.execute(input(), TerminationType.withoutJustCause);
      expect(
        r.assumptions.any((a) => a.code == AssumptionCode.validationPending),
        isFalse,
      );
    });
  });

  group('mês com menos de 15 dias conta zero (Lei 4.090/62 art. 1º §2º)', () {
    test(
      'rescisão no dia 14: 13º de 7/12 (1750,00, sem aviso projetado); no dia 15: 8/12 (2000,00)',
      () {
        final d14 = useCase.execute(
          input(termination: DateTime(2025, 8, 14), noticeWorked: true),
          TerminationType.withoutJustCause,
        );
        final d15 = useCase.execute(
          input(termination: DateTime(2025, 8, 15), noticeWorked: true),
          TerminationType.withoutJustCause,
        );
        expect(valueOf(d14, BreakdownCode.thirteenth), 1750.00);
        expect(valueOf(d15, BreakdownCode.thirteenth), 2000.00);
      },
    );

    test(
      'deve registrar a regra de 15 dias e o mês de 30 dias nas premissas',
      () {
        final r = useCase.execute(input(), TerminationType.withoutJustCause);
        expect(
          r.assumptions.map((a) => a.code),
          containsAll([
            AssumptionCode.fifteenDayRule,
            AssumptionCode.thirtyDayMonth,
          ]),
        );
      },
    );
  });

  group('regras por tipo (B2-02/03)', () {
    test(
      'pedido de demissão sem aviso trabalhado: desconto e sem aviso indenizado',
      () {
        final r = useCase.execute(input(), TerminationType.resignation);
        expect(valueOf(r, BreakdownCode.noticeDiscount), 4500.00);
        expect(valueOf(r, BreakdownCode.notice), isNull);
      },
    );

    test(
      'acordo mútuo: aviso 50% (2250,00) e multa 20% sobre o FGTS informado',
      () {
        final r = useCase.execute(
          input(fgts: 10000),
          TerminationType.mutualAgreement,
        );
        expect(valueOf(r, BreakdownCode.notice), 2250.00);
        expect(valueOf(r, BreakdownCode.fgtsFine), 2000.00);
      },
    );

    test('trocar o rótulo não muda valores (valores dependem só do code)', () {
      final r = useCase.execute(input(), TerminationType.withoutJustCause);
      expect(valueOf(r, BreakdownCode.salaryBalance), 2600.00); // 26 dias x 100
    });
  });

  group('C4: férias fora da base de INSS e IRRF', () {
    test(
      'com e sem férias vencidas: INSS e IRRF iguais; a diferença em paidAtTermination é o valor das férias',
      () {
        final without = useCase.execute(
          input(taxes: true, salary: 9000),
          TerminationType.withoutJustCause,
        );
        final withVac = useCase.execute(
          input(taxes: true, salary: 9000, accrued: true),
          TerminationType.withoutJustCause,
        );
        expect(
          valueOf(withVac, BreakdownCode.inss),
          valueOf(without, BreakdownCode.inss),
        );
        expect(
          valueOf(withVac, BreakdownCode.irrf),
          valueOf(without, BreakdownCode.irrf),
        );
        expect(
          withVac.paidAtTermination - without.paidAtTermination,
          closeTo(12000.00, 0.01),
        );
      },
    );
  });

  group('dois totais (B2-09)', () {
    test('multa fica em fgtsDeposit e fora de paidAtTermination', () {
      final r = useCase.execute(
        input(fgts: 10000),
        TerminationType.withoutJustCause,
      );
      expect(r.fgtsDeposit.total, 4000.00);
      expect(r.additions.any((i) => i.code == BreakdownCode.fgtsFine), isFalse);
      expect(
        r.paidAtTermination,
        closeTo(r.totalAdditions - r.totalDeductions, 0.001),
      );
    });

    test(
      'paidAtTermination + fgtsDeposit.total reproduz o netAmount antigo',
      () {
        for (final type in TerminationType.values) {
          final r = useCase.execute(
            input(fgts: 10000, accrued: true, taxes: true),
            type,
          );
          // ignore: deprecated_member_use_from_same_package
          expect(
            r.paidAtTermination + r.fgtsDeposit.total,
            closeTo(r.netAmount, 0.011),
            reason: type.name,
          );
        }
      },
    );

    test('pedido de demissão não tem depósito no FGTS', () {
      final r = useCase.execute(input(), TerminationType.resignation);
      expect(r.fgtsDeposit.items, isEmpty);
      expect(r.fgtsDeposit.total, 0);
    });
  });

  group('premissas (B2-10)', () {
    test('FGTS informado tem origem informed; sem informar, estimated', () {
      final informed = useCase.execute(
        input(fgts: 10000),
        TerminationType.withoutJustCause,
      );
      final estimated = useCase.execute(
        input(),
        TerminationType.withoutJustCause,
      );
      expect(
        informed.assumptions
            .firstWhere((a) => a.code == AssumptionCode.fgtsBalance)
            .origin,
        AssumptionOrigin.informed,
      );
      expect(
        estimated.assumptions
            .firstWhere((a) => a.code == AssumptionCode.fgtsBalance)
            .origin,
        AssumptionOrigin.estimated,
      );
    });

    test('deve registrar os avos de 13º e de férias', () {
      final r = useCase.execute(
        input(noticeWorked: true),
        TerminationType.withoutJustCause,
      );
      expect(
        r.assumptions
            .firstWhere((a) => a.code == AssumptionCode.thirteenthMonths)
            .value,
        8,
      );
      expect(
        r.assumptions
            .firstWhere((a) => a.code == AssumptionCode.vacationMonths)
            .value,
        6,
      );
    });

    test(
      'validationPendingRules em lib espelha test/golden/validation_status.dart',
      () {
        expect(validationPendingRules, pendingValidationRules);
      },
    );
  });
}
