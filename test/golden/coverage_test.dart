@Tags(['release-gate'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/coverage_matrix.dart';
import 'support/golden_case.dart';

/// Gate de publicação (B6-05). Rodar: `flutter test --tags release-gate --run-skipped`.
void main() {
  test('deve haver caso golden para toda a matriz de cobertura', () {
    final missing = missingCoverage(
      loadGoldenCases(Directory('test/golden/cases')),
    );
    expect(
      missing,
      isEmpty,
      reason: 'Faltam casos golden: ${missing.join('; ')}',
    );
  });
}
