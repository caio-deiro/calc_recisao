import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'loader_test.dart' show fixtureJson, parseFixture;
import 'support/coverage_matrix.dart';
import 'support/golden_case.dart';
import 'validation_status.dart';

GoldenCase caso(
  String tipo, {
  String fonte = 'trct',
  List<String> cobre = const [],
}) {
  final json = fixtureJson()
    ..['tipo'] = tipo
    ..['cobre'] = cobre;
  (json['fonte'] as Map)['tipo'] = fonte;
  return parseFixture(json);
}

List<GoldenCase> matrizCompleta() => [
  for (final t in TerminationType.values) caso(t.name),
  caso('withoutJustCause', cobre: correctionMarkers),
  for (final r in pendingValidationRules)
    caso('withoutJustCause', fonte: 'exemplo_contador', cobre: [r]),
];

void main() {
  group('missingCoverage (lógica do gate release-gate)', () {
    test('deve passar com a matriz completa', () {
      expect(missingCoverage(matrizCompleta()), isEmpty);
    });

    test('deve listar a verba C4 quando faltar', () {
      final cases = [
        for (final t in TerminationType.values) caso(t.name),
        caso('withoutJustCause', cobre: ['C1', 'C2', 'C3', 'C5']),
        for (final r in pendingValidationRules)
          caso('withoutJustCause', fonte: 'exemplo_contador', cobre: [r]),
      ];
      expect(missingCoverage(cases), ['verba corrigida C4']);
    });

    test('deve acusar regra ⚖️ pendente sem caso exemplo_contador', () {
      final cases = matrizCompleta()
          .where((c) => !c.cobre.contains('art479'))
          .toList();
      expect(missingCoverage(cases).single, contains('art479'));
    });

    test('deve acusar tudo com 0 casos', () {
      expect(missingCoverage([]), isNotEmpty);
    });
  });
}
