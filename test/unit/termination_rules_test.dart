import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/rules/termination_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matriz do PRD §6.1 (com C1: férias vencidas também na justa causa) e B4.
void main() {
  group('TerminationRules', () {
    test('deve cobrir todos os tipos', () {
      expect(TerminationType.values, hasLength(8));
      for (final t in TerminationType.values) {
        expect(() => TerminationRules.of(t), returnsNormally);
      }
    });

    test('deve espelhar a coluna de sem justa causa', () {
      final r = TerminationRules.of(TerminationType.withoutJustCause);
      expect(r.noticePercent, 100);
      expect(r.fgtsFineShare, 1.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isFalse);
    });

    test(
      'deve espelhar a coluna de rescisão indireta, igual à de sem justa causa',
      () {
        final i = TerminationRules.of(TerminationType.indirectTermination);
        final w = TerminationRules.of(TerminationType.withoutJustCause);
        expect(i.noticePercent, w.noticePercent);
        expect(i.fgtsFineShare, w.fgtsFineShare);
        expect(i.paysThirteenth, w.paysThirteenth);
        expect(i.paysProportionalVacation, w.paysProportionalVacation);
        expect(i.paysAccruedVacation, w.paysAccruedVacation);
        expect(i.noticeDeductible, w.noticeDeductible);
        expect(i.fgtsWithdrawalPercent, w.fgtsWithdrawalPercent);
        expect(i.hasIndemnity479, w.hasIndemnity479);
        expect(i.hasDiscount480, w.hasDiscount480);
        expect(i.noticeProjectionPendingRule, w.noticeProjectionPendingRule);
      },
    );

    test('deve espelhar a coluna de pedido de demissão', () {
      final r = TerminationRules.of(TerminationType.resignation);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isTrue);
    });

    test('deve espelhar a coluna do término normal do contrato a prazo', () {
      final r = TerminationRules.of(TerminationType.fixedTermEnd);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isFalse);
      expect(r.fgtsWithdrawalPercent, 100);
      expect(r.hasIndemnity479, isFalse);
      expect(r.hasDiscount480, isFalse);
    });

    test('deve espelhar a coluna da antecipada pelo empregador', () {
      final r = TerminationRules.of(TerminationType.fixedTermEarlyByEmployer);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 1.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isFalse);
      expect(r.fgtsWithdrawalPercent, 100);
      expect(r.hasIndemnity479, isTrue);
      expect(r.hasDiscount480, isFalse);
    });

    test('deve espelhar a coluna da antecipada pelo empregado', () {
      final r = TerminationRules.of(TerminationType.fixedTermEarlyByEmployee);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isFalse);
      expect(r.fgtsWithdrawalPercent, isNull);
      expect(r.hasIndemnity479, isFalse);
      expect(r.hasDiscount480, isTrue);
    });

    test('deve pagar só férias vencidas na justa causa (C1)', () {
      final r = TerminationRules.of(TerminationType.withJustCause);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isFalse);
      expect(r.paysProportionalVacation, isFalse);
      expect(r.paysAccruedVacation, isTrue);
    });

    test('deve reduzir aviso e multa à metade no acordo mútuo', () {
      final r = TerminationRules.of(TerminationType.mutualAgreement);
      expect(r.noticePercent, 50);
      expect(r.fgtsFineShare, 0.5);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeProjectionPendingRule, 'noticeProjectionMutualAgreement');
    });

    test(
      'deve ligar art. 479 só na antecipada pelo empregador e art. 480 só na do empregado',
      () {
        for (final t in TerminationType.values) {
          final r = TerminationRules.of(t);
          expect(
            r.hasIndemnity479,
            t == TerminationType.fixedTermEarlyByEmployer,
            reason: t.name,
          );
          expect(
            r.hasDiscount480,
            t == TerminationType.fixedTermEarlyByEmployee,
            reason: t.name,
          );
        }
      },
    );

    test('deve informar o percentual de saque do FGTS só onde há regra', () {
      const expected = {
        TerminationType.withoutJustCause: 100,
        TerminationType.indirectTermination: 100,
        TerminationType.fixedTermEnd: 100,
        TerminationType.fixedTermEarlyByEmployer: 100,
        TerminationType.mutualAgreement: 80,
        TerminationType.resignation: null,
        TerminationType.withJustCause: null,
        TerminationType.fixedTermEarlyByEmployee: null,
      };
      for (final e in expected.entries) {
        expect(
          TerminationRules.of(e.key).fgtsWithdrawalPercent,
          e.value,
          reason: e.key.name,
        );
      }
    });
  });

  group('TerminationRules.resolve (cláusula assecuratória)', () {
    test(
      'deve resolver a antecipada pelo empregador para sem justa causa com cláusula',
      () {
        final r = TerminationRules.resolve(
          TerminationType.fixedTermEarlyByEmployer,
          true,
        );
        expect(r, same(TerminationRules.of(TerminationType.withoutJustCause)));
        expect(r.hasIndemnity479, isFalse);
      },
    );

    test(
      'deve resolver a antecipada pelo empregado para pedido de demissão com cláusula',
      () {
        final r = TerminationRules.resolve(
          TerminationType.fixedTermEarlyByEmployee,
          true,
        );
        expect(r, same(TerminationRules.of(TerminationType.resignation)));
        expect(r.hasDiscount480, isFalse);
        expect(r.noticeDeductible, isTrue);
      },
    );

    test('deve resolver para o próprio tipo sem cláusula', () {
      for (final t in TerminationType.values) {
        expect(
          TerminationRules.resolve(t, false),
          same(TerminationRules.of(t)),
          reason: t.name,
        );
      }
    });

    test(
      'deve ignorar a cláusula nos demais tipos, inclusive no término normal',
      () {
        for (final t in TerminationType.values) {
          if (t == TerminationType.fixedTermEarlyByEmployer ||
              t == TerminationType.fixedTermEarlyByEmployee) {
            continue;
          }
          expect(
            TerminationRules.resolve(t, true),
            same(TerminationRules.of(t)),
            reason: t.name,
          );
        }
      },
    );
  });
}
