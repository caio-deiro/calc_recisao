import 'dart:io';

import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/assumption.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/rules/fixed_term.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contratos a prazo e rescisão indireta (B4). Datas fixas; salário 3.000 e rescisão em
/// 2026-03-10, então 30 dias restantes = fim em 2026-04-09.
void main() {
  const useCase = CalculateTerminationUseCase();

  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());
  setUp(() async => TaxTablesService.instance.loadTaxTables());

  TerminationInput input({
    DateTime? end,
    double average = 0,
    bool clause = false,
    bool noticeWorked = false,
    bool taxes = true,
  }) => TerminationInput(
    admissionDate: DateTime(2026, 1, 12),
    terminationDate: DateTime(2026, 3, 10),
    baseSalary: 3000,
    averageAdditions: average,
    noticeWorked: noticeWorked,
    calculateTaxes: taxes,
    fixedTermEndDate: end,
    hasRecipientClause: clause,
  );

  final end30 = DateTime(2026, 4, 9);
  final end120 = DateTime(2026, 7, 8);

  BreakdownItem? item(TerminationResult r, BreakdownCode code) {
    for (final i in [...r.additions, ...r.deductions, ...r.fgtsDeposit.items]) {
      if (i.code == code) return i;
    }
    return null;
  }

  bool has(TerminationResult r, BreakdownCode code) => item(r, code) != null;

  Assumption? assumption(
    TerminationResult r,
    AssumptionCode code, {
    String? ruleId,
  }) {
    for (final a in r.assumptions) {
      if (a.code == code && (ruleId == null || a.ruleId == ruleId)) return a;
    }
    return null;
  }

  group('remainingDays', () {
    test('deve contar fim menos rescisão, sem contar o dia da rescisão', () {
      expect(remainingDays(DateTime(2026, 4, 9), DateTime(2026, 3, 10)), 30);
      expect(remainingDays(DateTime(2026, 3, 11), DateTime(2026, 3, 10)), 1);
    });

    test('deve ser zero no dia do fim e nunca negativo', () {
      expect(remainingDays(DateTime(2026, 3, 10), DateTime(2026, 3, 10)), 0);
      expect(remainingDays(DateTime(2026, 3, 1), DateTime(2026, 3, 10)), 0);
    });

    test('deve ignorar a hora e a mudança de horário', () {
      expect(
        remainingDays(DateTime(2026, 11, 1, 23), DateTime(2026, 10, 1, 1)),
        31,
      );
    });
  });

  group('Art. 479 (antecipada pelo empregador)', () {
    test(
      'deve calcular metade da remuneração dos dias restantes, em provento',
      () {
        final r = useCase.execute(
          input(end: end30),
          TerminationType.fixedTermEarlyByEmployer,
        );
        final i = item(r, BreakdownCode.indemnity479)!;
        expect(i.value, 1500.00);
        expect(i.type, BreakdownType.addition);
      },
    );

    test('deve incluir a média de variáveis na base', () {
      final r = useCase.execute(
        input(end: end30, average: 600),
        TerminationType.fixedTermEarlyByEmployer,
      );
      expect(item(r, BreakdownCode.indemnity479)!.value, 1800.00);
    });

    test('deve arredondar a 2 casas, meio centavo para cima', () {
      // 3000 / 30 × 7 × 50 % = 350,00; com média 100,10: 3100,10 × 7 / 60 = 361,6783... -> 361,68
      final r = useCase.execute(
        input(end: DateTime(2026, 3, 17), average: 100.10),
        TerminationType.fixedTermEarlyByEmployer,
      );
      expect(item(r, BreakdownCode.indemnity479)!.value, 361.68);
    });

    test('deve ficar fora de INSS e IRRF', () {
      final com = useCase.execute(
        input(end: end120),
        TerminationType.fixedTermEarlyByEmployer,
      );
      final sem = useCase.execute(
        input(end: DateTime(2026, 3, 10)),
        TerminationType.fixedTermEarlyByEmployer,
      );
      expect(has(sem, BreakdownCode.indemnity479), isFalse);
      expect(
        item(com, BreakdownCode.inss)!.value,
        item(sem, BreakdownCode.inss)!.value,
      );
      expect(
        item(com, BreakdownCode.irrf)?.value,
        item(sem, BreakdownCode.irrf)?.value,
      );
      expect(com.totalDeductions, sem.totalDeductions);
    });

    test('deve manter a multa de 40 % do FGTS', () {
      final r = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEarlyByEmployer,
      );
      expect(has(r, BreakdownCode.fgtsFine), isTrue);
      expect(has(r, BreakdownCode.notice), isFalse);
    });

    test('deve exibir a premissa de cálculo em validação do art. 479', () {
      final r = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEarlyByEmployer,
      );
      expect(
        assumption(r, AssumptionCode.validationPending, ruleId: 'art479'),
        isNotNull,
      );
      expect(
        assumption(r, AssumptionCode.validationPending, ruleId: 'art480'),
        isNull,
      );
    });

    test(
      'deve resolver para sem justa causa com cláusula: aviso, multa e sem art. 479',
      () {
        final r = useCase.execute(
          input(end: end30, clause: true),
          TerminationType.fixedTermEarlyByEmployer,
        );
        final semJustaCausa = useCase.execute(
          input(end: end30),
          TerminationType.withoutJustCause,
        );
        expect(has(r, BreakdownCode.indemnity479), isFalse);
        expect(
          item(r, BreakdownCode.notice)!.value,
          item(semJustaCausa, BreakdownCode.notice)!.value,
        );
        expect(has(r, BreakdownCode.fgtsFine), isTrue);
        expect(
          assumption(r, AssumptionCode.validationPending, ruleId: 'art479'),
          isNull,
        );
        expect(r.paidAtTermination, semJustaCausa.paidAtTermination);
      },
    );
  });

  group('Art. 480 (antecipada pelo empregado)', () {
    test(
      'deve descontar o valor do art. 479 equivalente quando abaixo do teto',
      () {
        final r = useCase.execute(
          input(end: end30),
          TerminationType.fixedTermEarlyByEmployee,
        );
        final i = item(r, BreakdownCode.indemnity480)!;
        expect(i.value, 1500.00);
        expect(i.type, BreakdownType.deduction);
      },
    );

    test('deve limitar a 1 remuneração mensal (salário + média)', () {
      final r = useCase.execute(
        input(end: end120),
        TerminationType.fixedTermEarlyByEmployee,
      );
      expect(item(r, BreakdownCode.indemnity480)!.value, 3000.00);
      final comMedia = useCase.execute(
        input(end: end120, average: 500),
        TerminationType.fixedTermEarlyByEmployee,
      );
      expect(item(comMedia, BreakdownCode.indemnity480)!.value, 3500.00);
    });

    test(
      'deve valer exatamente o teto quando o art. 479 equivalente o iguala',
      () {
        // 60 dias: 3000 / 30 × 60 / 2 = 3000
        final r = useCase.execute(
          input(end: DateTime(2026, 5, 9)),
          TerminationType.fixedTermEarlyByEmployee,
        );
        expect(item(r, BreakdownCode.indemnity480)!.value, 3000.00);
      },
    );

    test('deve ficar fora da base de impostos e só aumentar os descontos', () {
      final com = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEarlyByEmployee,
      );
      final sem = useCase.execute(
        input(end: DateTime(2026, 3, 10)),
        TerminationType.fixedTermEarlyByEmployee,
      );
      expect(
        item(com, BreakdownCode.inss)!.value,
        item(sem, BreakdownCode.inss)!.value,
      );
      expect(
        item(com, BreakdownCode.irrf)?.value,
        item(sem, BreakdownCode.irrf)?.value,
      );
      expect(com.totalDeductions - sem.totalDeductions, closeTo(1500.00, 1e-9));
    });

    test('deve não ter multa de 40 % nem provento de art. 479', () {
      final r = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEarlyByEmployee,
      );
      expect(has(r, BreakdownCode.fgtsFine), isFalse);
      expect(has(r, BreakdownCode.indemnity479), isFalse);
      expect(r.fgtsDeposit.total, 0);
    });

    test(
      'deve exibir o aviso de valor máximo e a premissa de validação do art. 480',
      () {
        final r = useCase.execute(
          input(end: end30),
          TerminationType.fixedTermEarlyByEmployee,
        );
        final cap = assumption(r, AssumptionCode.indemnity480Cap)!;
        expect(
          cap.text,
          contains('valor máximo; depende de comprovação do prejuízo'),
        );
        expect(cap.origin, AssumptionOrigin.estimated);
        expect(
          assumption(r, AssumptionCode.validationPending, ruleId: 'art480'),
          isNotNull,
        );
        expect(
          assumption(r, AssumptionCode.validationPending, ruleId: 'art479'),
          isNull,
        );
      },
    );

    test(
      'deve resolver para pedido de demissão com cláusula: desconto de aviso e sem art. 480',
      () {
        final r = useCase.execute(
          input(end: end30, clause: true),
          TerminationType.fixedTermEarlyByEmployee,
        );
        final pedido = useCase.execute(
          input(end: end30),
          TerminationType.resignation,
        );
        expect(has(r, BreakdownCode.indemnity480), isFalse);
        expect(has(r, BreakdownCode.noticeDiscount), isTrue);
        expect(has(r, BreakdownCode.fgtsFine), isFalse);
        expect(assumption(r, AssumptionCode.indemnity480Cap), isNull);
        expect(r.paidAtTermination, pedido.paidAtTermination);
      },
    );

    test('deve respeitar o aviso trabalhado com cláusula', () {
      final r = useCase.execute(
        input(end: end30, clause: true, noticeWorked: true),
        TerminationType.fixedTermEarlyByEmployee,
      );
      expect(has(r, BreakdownCode.noticeDiscount), isFalse);
    });
  });

  group('Término normal do contrato a prazo', () {
    test(
      'deve pagar saldo, 13º e férias, sem aviso, desconto de aviso nem multa',
      () {
        final r = useCase.execute(
          input(end: DateTime(2026, 3, 10)),
          TerminationType.fixedTermEnd,
        );
        expect(has(r, BreakdownCode.notice), isFalse);
        expect(has(r, BreakdownCode.noticeDiscount), isFalse);
        expect(has(r, BreakdownCode.fgtsFine), isFalse);
        expect(has(r, BreakdownCode.thirteenth), isTrue);
        expect(has(r, BreakdownCode.proportionalVacation), isTrue);
        expect(r.fgtsDeposit.total, 0);
      },
    );

    test('deve ignorar a cláusula assecuratória', () {
      final sem = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEnd,
      );
      final com = useCase.execute(
        input(end: end30, clause: true),
        TerminationType.fixedTermEnd,
      );
      expect(com.paidAtTermination, sem.paidAtTermination);
      expect(
        com.additions.map((i) => i.code),
        sem.additions.map((i) => i.code),
      );
    });

    test('deve não gerar art. 479 nem art. 480', () {
      final r = useCase.execute(
        input(end: end30),
        TerminationType.fixedTermEnd,
      );
      expect(has(r, BreakdownCode.indemnity479), isFalse);
      expect(has(r, BreakdownCode.indemnity480), isFalse);
    });
  });

  group('Rescisão indireta', () {
    test(
      'deve ter itens, valores e totais iguais aos da dispensa sem justa causa',
      () {
        final i = input();
        final indireta = useCase.execute(
          i,
          TerminationType.indirectTermination,
        );
        final semJustaCausa = useCase.execute(
          i,
          TerminationType.withoutJustCause,
        );
        expect(
          indireta.additions.map((e) => (e.code, e.value)).toList(),
          semJustaCausa.additions.map((e) => (e.code, e.value)).toList(),
        );
        expect(
          indireta.deductions.map((e) => (e.code, e.value)).toList(),
          semJustaCausa.deductions.map((e) => (e.code, e.value)).toList(),
        );
        expect(
          indireta.fgtsDeposit.items.map((e) => (e.code, e.value)).toList(),
          semJustaCausa.fgtsDeposit.items
              .map((e) => (e.code, e.value))
              .toList(),
        );
        expect(indireta.paidAtTermination, semJustaCausa.paidAtTermination);
        expect(indireta.totalDeductions, semJustaCausa.totalDeductions);
      },
    );
  });

  group('Use case sem ramificação por tipo (B4-08)', () {
    test('deve não conter comparação nem referência a TerminationType.', () {
      final source = File(
        'lib/domain/usecases/calculate_termination.dart',
      ).readAsStringSync();
      expect(source.contains('type =='), isFalse);
      expect(source.contains('TerminationType.'), isFalse);
    });
  });
}
