import 'dart:convert';

import 'package:calc_recisao/data/repositories/history_repository.dart';
import 'package:calc_recisao/domain/entities/assumption.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
import 'package:calc_recisao/domain/entities/breakdown_item.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// JSON como gravado pela versão 1.0.x: sem `schemaVersion`, sem `code`, sem campos novos.
Map<String, dynamic> legacyJson({
  String type = 'withoutJustCause',
  String id = 'legacy_1',
}) => {
  'id': id,
  'input': {
    'admissionDate': '2023-01-01T00:00:00.000',
    'terminationDate': '2024-06-30T00:00:00.000',
    'baseSalary': 3000.0,
  },
  'result': {
    'additions': [
      {
        'description': 'Saldo de Salário',
        'value': 3000.0,
        'type': 'addition',
        'details': null,
      },
      {
        'description': 'Multa FGTS (40%)',
        'value': 500.0,
        'type': 'addition',
        'details': null,
      },
    ],
    'deductions': [],
    'totalToReceive': 3500.0,
    'totalDeductions': 0.0,
    'netAmount': 3500.0,
    'calculationDate': '2024-06-30T00:00:00.000',
  },
  'terminationType': type,
  'timestamp': '2024-06-30T00:00:00.000',
  'note': null,
};

void main() {
  group('CalculationHistory (B2-11)', () {
    test(
      'deve abrir registro legado 1.0.x como legado, com listas novas vazias',
      () {
        final h = CalculationHistory.fromJson(legacyJson());
        expect(h.isLegacy, isTrue);
        expect(h.schemaVersion, 1);
        expect(
          h.result.additions.every((i) => i.code == BreakdownCode.legacy),
          isTrue,
        );
        expect(h.result.assumptions, isEmpty);
        expect(h.result.fgtsDeposit.items, isEmpty);
        // Não recalcula nem infere: o total gravado continua como estava.
        expect(h.legacyNetAmount, 3500.0);
        expect(h.result.paidAtTermination, 0.0); // não inferido
      },
    );

    test(
      'deve preservar schemaVersion, itens, totais e premissas num round trip novo',
      () {
        final h = CalculationHistory(
          id: 'novo',
          input: TerminationInput(
            admissionDate: DateTime(2023, 1, 1),
            terminationDate: DateTime(2024, 6, 30),
            baseSalary: 3000,
          ),
          result: TerminationResult(
            additions: const [
              BreakdownItem(
                code: BreakdownCode.salaryBalance,
                description: 'Saldo de Salário',
                value: 3000,
                type: BreakdownType.addition,
              ),
            ],
            deductions: const [],
            totalDeductions: 0,
            calculationDate: DateTime(2024, 6, 30),
            paidAtTermination: 3000,
            fgtsDeposit: const FgtsDeposit(
              items: [
                BreakdownItem(
                  code: BreakdownCode.fgtsFine,
                  description: 'Multa FGTS (40%)',
                  value: 500,
                  type: BreakdownType.addition,
                ),
              ],
            ),
            assumptions: const [
              Assumption(
                code: AssumptionCode.validationPending,
                text: 'Cálculo em validação',
                origin: AssumptionOrigin.estimated,
                ruleId: 'noticeProjectionMutualAgreement',
              ),
            ],
          ),
          terminationType: TerminationType.mutualAgreement,
          timestamp: DateTime(2024, 6, 30),
        );

        final back = CalculationHistory.fromJson(
          jsonDecode(jsonEncode(h.toJson())),
        );

        expect(back.schemaVersion, currentHistorySchemaVersion);
        expect(back.isLegacy, isFalse);
        expect(back.legacyNetAmount, isNull);
        expect(jsonEncode(h.toJson()).contains('netAmount'), isFalse);
        expect(jsonEncode(h.toJson()).contains('totalToReceive'), isFalse);
        expect(back.result.additions.single.code, BreakdownCode.salaryBalance);
        expect(back.result.fgtsDeposit.total, 500);
        expect(back.result.paidAtTermination, 3000);
        expect(
          back.result.assumptions.single.ruleId,
          'noticeProjectionMutualAgreement',
        );
        expect(back.terminationType, TerminationType.mutualAgreement);
      },
    );

    test('deve manter a marca legado ao regravar um registro legado', () {
      final h = CalculationHistory.fromJson(legacyJson());
      expect(
        CalculationHistory.fromJson(
          jsonDecode(jsonEncode(h.toJson())),
        ).isLegacy,
        isTrue,
      );
    });
  });

  group('aliases de tipo (B2-12)', () {
    test('deve mapear nome antigo pela tabela de aliases', () {
      expect(
        resolveTerminationType(
          'fixedTermOld',
          aliases: {'fixedTermOld': 'fixedTermEnd'},
        ),
        TerminationType.fixedTermEnd,
      );
    });

    test('deve mapear fixedTerm para fixedTermEnd na tabela oficial', () {
      expect(resolveTerminationType('fixedTerm'), TerminationType.fixedTermEnd);
    });

    test(
      'deve abrir registro antigo com fixedTerm sem fim previsto, com os valores salvos',
      () {
        final h = CalculationHistory.fromJson(legacyJson(type: 'fixedTerm'));
        expect(h.terminationType, TerminationType.fixedTermEnd);
        expect(h.input.fixedTermEndDate, isNull);
        expect(h.input.hasRecipientClause, isFalse);
      },
    );

    test(
      'deve resolver nome atual e devolver null para desconhecido, sem lançar',
      () {
        expect(
          resolveTerminationType('resignation'),
          TerminationType.resignation,
        );
        expect(resolveTerminationType('inexistente'), isNull);
        expect(resolveTerminationType(null), isNull);
      },
    );

    test(
      'fromJson com tipo desconhecido lança FormatException (tratada como ilegível pelo repositório)',
      () {
        expect(
          () => CalculationHistory.fromJson(legacyJson(type: 'inexistente')),
          throwsFormatException,
        );
      },
    );
  });

  group('HistoryRepository com registros ilegíveis (B2-11)', () {
    test(
      'deve manter o dado bruto ilegível após novas gravações e contá-lo',
      () async {
        SharedPreferences.setMockInitialValues({
          'calculation_history': [
            '{isto não é json',
            jsonEncode(legacyJson(type: 'inexistente', id: 'x')),
          ],
        });
        final repo = HistoryRepository();

        expect(await repo.getHistory(), isEmpty);
        expect(await repo.unreadableCount(), 2);

        await repo.saveCalculation(CalculationHistory.fromJson(legacyJson()));
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getStringList('calculation_history'),
          contains('{isto não é json'),
        );
        expect(await repo.unreadableCount(), 2);
        expect((await repo.getHistory()).length, 1);

        await repo.deleteCalculation('legacy_1');
        expect(await repo.unreadableCount(), 2);
      },
    );
  });
}
