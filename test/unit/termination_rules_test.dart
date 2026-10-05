import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/rules/termination_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matriz do PRD §6.1 (com C1: férias vencidas também na justa causa).
void main() {
  group('TerminationRules', () {
    test('deve cobrir todos os tipos atuais', () {
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

    test('deve espelhar a coluna de pedido de demissão', () {
      final r = TerminationRules.of(TerminationType.resignation);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.paysAccruedVacation, isTrue);
      expect(r.noticeDeductible, isTrue);
    });

    test('deve espelhar a coluna de prazo determinado', () {
      final r = TerminationRules.of(TerminationType.fixedTerm);
      expect(r.noticePercent, 0);
      expect(r.fgtsFineShare, 0.0);
      expect(r.paysThirteenth, isTrue);
      expect(r.paysProportionalVacation, isTrue);
      expect(r.noticeDeductible, isFalse);
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
    });

    test('deve manter art. 479/480 desligados até B4', () {
      for (final t in TerminationType.values) {
        final r = TerminationRules.of(t);
        expect(r.hasIndemnity479, isFalse);
        expect(r.hasDiscount480, isFalse);
      }
    });

    test('deve informar o percentual de saque do FGTS só onde há regra', () {
      expect(TerminationRules.of(TerminationType.withoutJustCause).fgtsWithdrawalPercent, 100);
      expect(TerminationRules.of(TerminationType.mutualAgreement).fgtsWithdrawalPercent, 80);
      expect(TerminationRules.of(TerminationType.resignation).fgtsWithdrawalPercent, isNull);
      expect(TerminationRules.of(TerminationType.fixedTerm).fgtsWithdrawalPercent, isNull);
      expect(TerminationRules.of(TerminationType.withJustCause).fgtsWithdrawalPercent, isNull);
    });
  });
}
