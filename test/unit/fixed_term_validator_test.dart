import 'package:calc_recisao/core/validators/termination_input_validator.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validação do fim previsto e entrada de contratos a prazo (B4-03). Datas fixas no passado.
void main() {
  TerminationInput input({
    DateTime? end,
    DateTime? termination,
    bool clause = false,
  }) => TerminationInput(
    admissionDate: DateTime(2024, 1, 10),
    terminationDate: termination ?? DateTime(2024, 6, 10),
    baseSalary: 3000,
    fixedTermEndDate: end,
    hasRecipientClause: clause,
  );

  group('TerminationInputValidator (contrato a prazo)', () {
    test('deve exigir o fim previsto nos 3 tipos a prazo', () {
      for (final t in TerminationInputValidator.fixedTermTypes) {
        final r = TerminationInputValidator.validate(input(), type: t);
        expect(r.isValid, isFalse, reason: t.name);
        expect(
          r.fieldErrors.containsKey('fixedTermEndDate'),
          isTrue,
          reason: t.name,
        );
      }
    });

    test('deve não exigir o fim previsto nos demais tipos', () {
      for (final t in TerminationType.values) {
        if (TerminationInputValidator.fixedTermTypes.contains(t)) continue;
        expect(
          TerminationInputValidator.validate(input(), type: t).isValid,
          isTrue,
          reason: t.name,
        );
      }
    });

    test('deve não exigir o fim previsto quando o tipo não é informado', () {
      expect(TerminationInputValidator.validate(input()).isValid, isTrue);
    });

    test('deve bloquear fim previsto igual ou anterior à admissão', () {
      for (final end in [DateTime(2024, 1, 10), DateTime(2023, 12, 1)]) {
        final r = TerminationInputValidator.validate(
          input(end: end, termination: DateTime(2024, 1, 9)),
          type: TerminationType.fixedTermEnd,
        );
        expect(r.fieldErrors['fixedTermEndDate'], isNotNull);
        expect(r.isValid, isFalse);
      }
    });

    test(
      'deve bloquear rescisão posterior ao fim previsto nas antecipadas',
      () {
        for (final t in [
          TerminationType.fixedTermEarlyByEmployer,
          TerminationType.fixedTermEarlyByEmployee,
        ]) {
          final r = TerminationInputValidator.validate(
            input(end: DateTime(2024, 6, 9)),
            type: t,
          );
          expect(r.isValid, isFalse, reason: t.name);
          expect(r.fieldErrors['terminationDate'], isNotNull, reason: t.name);
        }
      },
    );

    test('deve aceitar rescisão igual ou anterior ao fim nas antecipadas', () {
      for (final end in [DateTime(2024, 6, 10), DateTime(2024, 12, 31)]) {
        final r = TerminationInputValidator.validate(
          input(end: end),
          type: TerminationType.fixedTermEarlyByEmployer,
        );
        expect(r.isValid, isTrue);
        expect(r.warnings, isEmpty);
      }
    });

    test(
      'deve avisar sem bloquear quando o término normal difere do fim previsto',
      () {
        for (final end in [DateTime(2024, 6, 9), DateTime(2024, 12, 31)]) {
          final r = TerminationInputValidator.validate(
            input(end: end),
            type: TerminationType.fixedTermEnd,
          );
          expect(r.isValid, isTrue);
          expect(r.warnings, hasLength(1));
        }
      },
    );

    test(
      'deve não avisar quando o término normal coincide com o fim previsto',
      () {
        final r = TerminationInputValidator.validate(
          input(end: DateTime(2024, 6, 10)),
          type: TerminationType.fixedTermEnd,
        );
        expect(r.isValid, isTrue);
        expect(r.warnings, isEmpty);
      },
    );

    test('deve não aplicar a regra de data no futuro ao fim previsto', () {
      final r = TerminationInputValidator.validate(
        input(end: DateTime(2099, 1, 1)),
        type: TerminationType.fixedTermEarlyByEmployee,
      );
      expect(r.isValid, isTrue);
    });
  });

  group('TerminationInput (campos do contrato a prazo)', () {
    test('deve preservar fim previsto e cláusula em toJson e fromJson', () {
      final back = TerminationInput.fromJson(
        input(end: DateTime(2024, 12, 31), clause: true).toJson(),
      );
      expect(back.fixedTermEndDate, DateTime(2024, 12, 31));
      expect(back.hasRecipientClause, isTrue);
    });

    test('deve ler JSON antigo sem os campos novos como nulo e falso', () {
      final json = input().toJson()
        ..remove('fixedTermEndDate')
        ..remove('hasRecipientClause');
      final back = TerminationInput.fromJson(json);
      expect(back.fixedTermEndDate, isNull);
      expect(back.hasRecipientClause, isFalse);
    });

    test('deve gravar o fim previsto no histórico e reabrir o registro', () {
      final json = {
        'schemaVersion': currentHistorySchemaVersion,
        'id': 'h1',
        'input': input(end: DateTime(2024, 12, 31), clause: true).toJson(),
        'result': {
          'additions': <dynamic>[],
          'deductions': <dynamic>[],
          'totalDeductions': 0.0,
          'calculationDate': DateTime(2024, 6, 10).toIso8601String(),
          'paidAtTermination': 0.0,
        },
        'terminationType': 'fixedTermEarlyByEmployer',
        'timestamp': DateTime(2024, 6, 10).toIso8601String(),
      };
      final h = CalculationHistory.fromJson(json);
      expect(h.terminationType, TerminationType.fixedTermEarlyByEmployer);
      expect(h.input.fixedTermEndDate, DateTime(2024, 12, 31));
      expect(h.input.hasRecipientClause, isTrue);
    });
  });
}
