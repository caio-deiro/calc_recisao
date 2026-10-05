import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/core/utils/result_content.dart';
import 'package:calc_recisao/domain/entities/assumption.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const useCase = CalculateTerminationUseCase();

  setUp(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  // Admissão 15/06/2022, rescisão 16/06/2024: n = 2. Com taken = 0, o período 1 expirou
  // (concessivo até 15/06/2024) e o 2 está em curso de concessão.
  TerminationInput input({
    int taken = 0,
    double average = 0,
    DateTime? admission,
    DateTime? termination,
    bool taxes = false,
  }) => TerminationInput(
    admissionDate: admission ?? DateTime(2022, 6, 15),
    terminationDate: termination ?? DateTime(2024, 6, 16),
    baseSalary: 3000,
    averageAdditions: average,
    vacationPeriodsTaken: taken,
    calculateTaxes: taxes,
  );

  double? valueOf(TerminationResult r, BreakdownCode code) {
    final items = r.additions.where((i) => i.code == code);
    return items.isEmpty ? null : items.single.value;
  }

  Assumption? assumption(TerminationResult r, AssumptionCode code) {
    final list = r.assumptions.where((a) => a.code == code);
    return list.isEmpty ? null : list.single;
  }

  group('Férias vencidas: valores', () {
    test('deve pagar um período simples de 4.000,00 sem dobro', () {
      final r = useCase.execute(
        input(taken: 1),
        TerminationType.withoutJustCause,
      );
      expect(valueOf(r, BreakdownCode.accruedVacationSimple), 4000.00);
      expect(valueOf(r, BreakdownCode.accruedVacationDouble), isNull);
    });

    test(
      'deve pagar o período expirado em dobro, 8.000,00, como indenização',
      () {
        final r = useCase.execute(input(), TerminationType.withoutJustCause);
        final dobro = r.additions.singleWhere(
          (i) => i.code == BreakdownCode.accruedVacationDouble,
        );
        expect(dobro.value, 8000.00);
        expect(dobro.description, contains('indenização'));
        expect(
          valueOf(r, BreakdownCode.accruedVacationSimple),
          4000.00,
        ); // período 2
      },
    );

    test(
      'deve pagar dobro e simples com média de 600,00: 9.600,00 e 4.800,00',
      () {
        final r = useCase.execute(
          input(average: 600),
          TerminationType.withoutJustCause,
        );
        expect(valueOf(r, BreakdownCode.accruedVacationDouble), 9600.00);
        expect(valueOf(r, BreakdownCode.accruedVacationSimple), 4800.00);
      },
    );

    test('deve somar os períodos do mesmo tipo em um item só', () {
      final r = useCase.execute(
        input(
          admission: DateTime(2022, 6, 15),
          termination: DateTime(2025, 6, 16),
        ),
        TerminationType.withoutJustCause,
      );
      // períodos 1 e 2 em dobro, 3 simples
      expect(valueOf(r, BreakdownCode.accruedVacationDouble), 16000.00);
      expect(valueOf(r, BreakdownCode.accruedVacationSimple), 4000.00);
      expect(
        r.additions.where((i) => i.code == BreakdownCode.accruedVacationDouble),
        hasLength(1),
      );
    });

    test('deve pagar só o simples e nenhum proporcional na justa causa', () {
      final r = useCase.execute(input(taken: 1), TerminationType.withJustCause);
      expect(valueOf(r, BreakdownCode.accruedVacationSimple), 4000.00);
      expect(valueOf(r, BreakdownCode.proportionalVacation), isNull);
    });

    test(
      'não deve pagar férias vencidas quando todos os períodos foram gozados',
      () {
        final r = useCase.execute(
          input(taken: 2),
          TerminationType.withoutJustCause,
        );
        expect(valueOf(r, BreakdownCode.accruedVacationSimple), isNull);
        expect(valueOf(r, BreakdownCode.accruedVacationDouble), isNull);
      },
    );

    test('não deve dobrar quando nenhum concessivo expirou', () {
      // 15/06/2024 é o último dia do concessivo do período 1: ainda simples.
      final r = useCase.execute(
        input(termination: DateTime(2024, 6, 15)),
        TerminationType.withoutJustCause,
      );
      expect(valueOf(r, BreakdownCode.accruedVacationDouble), isNull);
      expect(valueOf(r, BreakdownCode.accruedVacationSimple), 8000.00);
    });

    test('deve manter INSS e IRRF iguais aos do caso sem férias vencidas', () {
      final com = useCase.execute(
        input(taxes: true),
        TerminationType.withoutJustCause,
      );
      final sem = useCase.execute(
        input(taken: 2, taxes: true),
        TerminationType.withoutJustCause,
      );
      expect(valueOf(sem, BreakdownCode.accruedVacationDouble), isNull);
      double deduction(TerminationResult r, BreakdownCode c) => r.deductions
          .where((i) => i.code == c)
          .fold(0.0, (s, i) => s + i.value);
      expect(
        deduction(com, BreakdownCode.inss),
        deduction(sem, BreakdownCode.inss),
      );
      expect(
        deduction(com, BreakdownCode.irrf),
        deduction(sem, BreakdownCode.irrf),
      );
    });

    test('nunca deve gerar o code antigo accruedVacation', () {
      for (final type in TerminationType.values) {
        final r = useCase.execute(input(), type);
        expect(
          r.additions.any((i) => i.code == BreakdownCode.accruedVacation),
          isFalse,
          reason: type.name,
        );
      }
    });

    test('deve somar as novas linhas em paidAtTermination', () {
      final com = useCase.execute(input(), TerminationType.withoutJustCause);
      final sem = useCase.execute(
        input(taken: 2),
        TerminationType.withoutJustCause,
      );
      expect(
        com.paidAtTermination - sem.paidAtTermination,
        closeTo(12000.00, 0.001),
      );
    });

    test(
      'deve levar a projeção do aviso só às avos do proporcional, sem criar período vencido',
      () {
        // n = 2, taken = 2: com aviso de 60+ dias projetado, nada vencido aparece.
        final r = useCase.execute(
          input(taken: 2),
          TerminationType.withoutJustCause,
        );
        expect(assumption(r, AssumptionCode.noticeProjection), isNotNull);
        expect(valueOf(r, BreakdownCode.accruedVacationSimple), isNull);
        expect(valueOf(r, BreakdownCode.accruedVacationDouble), isNull);
      },
    );
  });

  group('Férias vencidas: premissas', () {
    test(
      'deve listar um período por linha: gozado, dobro, simples e proporcional',
      () {
        final r = useCase.execute(
          input(
            admission: DateTime(2021, 6, 15),
            termination: DateTime(2024, 6, 16),
            taken: 1,
          ),
          TerminationType.withoutJustCause,
        );
        final lines = assumption(
          r,
          AssumptionCode.vacationPeriods,
        )!.text.split('\n');
        expect(lines, hasLength(4));
        expect(lines[0], endsWith('gozado'));
        expect(lines[1], endsWith('dobro'));
        expect(lines[2], endsWith('simples'));
        expect(lines[3], contains('proporcional'));
        expect(lines[1], contains('15/06/2022–14/06/2023'));
        expect(lines[1], contains('concessivo até 15/06/2024'));
        expect(
          assumption(r, AssumptionCode.vacationPeriods)!.origin,
          AssumptionOrigin.estimated,
        );
      },
    );

    test(
      'deve marcar "cálculo em validação" de férias em dobro só com período dobrado',
      () {
        final com = useCase.execute(input(), TerminationType.withoutJustCause);
        final pending = com.assumptions
            .where((a) => a.code == AssumptionCode.validationPending)
            .single;
        expect(pending.ruleId, 'doubleVacation');
        expect(pending.text, contains('férias em dobro'));

        final sem = useCase.execute(
          input(taken: 1),
          TerminationType.withoutJustCause,
        );
        expect(
          sem.assumptions.any(
            (a) => a.code == AssumptionCode.validationPending,
          ),
          isFalse,
        );
      },
    );

    test('não deve mudar a marca do acordo mútuo', () {
      final r = useCase.execute(
        input(admission: DateTime(2015, 3, 10), termination: DateTime(2025, 8, 26), taken: 10),
        TerminationType.mutualAgreement,
      );
      final pending = r.assumptions
          .where((a) => a.code == AssumptionCode.validationPending)
          .single;
      expect(pending.ruleId, 'noticeProjectionMutualAgreement');
      expect(pending.text, contains('acordo mútuo'));
    });

    test('deve manter só a linha proporcional com n = 0', () {
      final r = useCase.execute(
        input(
          admission: DateTime(2024, 3, 10),
          termination: DateTime(2024, 6, 15),
        ),
        TerminationType.withoutJustCause,
      );
      expect(
        assumption(r, AssumptionCode.vacationPeriods)!.text.split('\n'),
        hasLength(1),
      );
    });

    test(
      'deve manter as regras pendentes do resultado dentro de validationPendingRules',
      () {
        final r = useCase.execute(input(), TerminationType.withoutJustCause);
        for (final a in r.assumptions.where(
          (a) => a.code == AssumptionCode.validationPending,
        )) {
          expect(validationPendingRules, contains(a.ruleId));
        }
      },
    );

    test(
      'deve levar a tabela com a linha dobro ao texto completo do compartilhamento e do PDF',
      () {
        final i = input();
        final r = useCase.execute(i, TerminationType.withoutJustCause);
        final sections = buildResultSections(
          input: i,
          result: r,
          terminationType: TerminationType.withoutJustCause,
        );
        final text = renderSectionsAsText(sections);
        expect(text, contains('dobro'));
        expect(text, contains('1) 15/06/2022–14/06/2023'));
        expect(text, contains('Cálculo em validação: férias em dobro'));
        final resumo = renderSectionsAsText(
          buildResultSections(
            input: i,
            result: r,
            terminationType: TerminationType.withoutJustCause,
            full: false,
          ),
        );
        expect(resumo, isNot(contains('1) 15/06/2022')));
      },
    );
  });
}
