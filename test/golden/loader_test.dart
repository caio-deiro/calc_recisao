import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_case.dart';

Map<String, dynamic> fixtureJson() => {
  'id': 'fixture_basico',
  'oraculo': false,
  'fonte': {
    'tipo': 'trct',
    'descricao': 'fixture técnica',
    'referencia': 'n/a',
  },
  'tipo': 'withoutJustCause',
  'entrada': {
    'admissao': '2023-01-10',
    'rescisao': '2025-03-20',
    'salarioBase': 3000.00,
    'mediaVariaveis': 0,
    'dependentes': 1,
  },
  'esperado': {
    'verbas': <String, dynamic>{'salaryBalance': 2000.00},
    'totais': <String, dynamic>{'totalAdditions': 2000.00},
  },
};

GoldenCase parseFixture(Map<String, dynamic> json) =>
    GoldenCase.parse(json, origin: 'fixture.json', allowFixtures: true);

void main() {
  group('GoldenCase.parse', () {
    test(
      'deve carregar caso válido com datas, entrada e esperado por code',
      () {
        final c = parseFixture(fixtureJson());
        expect(c.type, TerminationType.withoutJustCause);
        expect(c.input.terminationDate, DateTime(2025, 3, 20));
        expect(c.input.baseSalary, 3000.0);
        expect(c.input.dependents, 1);
        expect(c.verbas['salaryBalance'], 2000.0);
        expect(c.totais['totalAdditions'], 2000.0);
      },
    );

    test('deve ler feriasGozadas como int e assumir 0 quando ausente', () {
      expect(parseFixture(fixtureJson()).input.vacationPeriodsTaken, 0);
      final json = fixtureJson();
      (json['entrada'] as Map<String, dynamic>)['feriasGozadas'] = 2;
      expect(parseFixture(json).input.vacationPeriodsTaken, 2);
    });

    test('deve aceitar os codes de férias simples e em dobro no esperado', () {
      final json = fixtureJson();
      (json['esperado']['verbas'] as Map<String, dynamic>)
        ..['accruedVacationSimple'] = 4000.00
        ..['accruedVacationDouble'] = 8000.00;
      final c = parseFixture(json);
      expect(c.verbas['accruedVacationDouble'], 8000.0);
    });

    test('deve rejeitar caso sem fonte citando o arquivo', () {
      final json = fixtureJson()..remove('fonte');
      expect(
        () => parseFixture(json),
        throwsA(
          isA<GoldenCaseException>().having(
            (e) => e.toString(),
            'msg',
            contains('fixture.json'),
          ),
        ),
      );
    });

    test('deve rejeitar fonte.descricao vazia', () {
      final json = fixtureJson();
      (json['fonte'] as Map)['descricao'] = ' ';
      expect(() => parseFixture(json), throwsA(isA<GoldenCaseException>()));
    });

    test('deve rejeitar tipo de rescisão desconhecido', () {
      final json = fixtureJson()..['tipo'] = 'inexistente';
      expect(() => parseFixture(json), throwsA(isA<GoldenCaseException>()));
    });

    test('deve rejeitar code de verba inválido com o code na mensagem', () {
      final json = fixtureJson();
      ((json['esperado'] as Map)['verbas'] as Map)['codigoFalso'] = 1.0;
      expect(
        () => parseFixture(json),
        throwsA(
          isA<GoldenCaseException>().having(
            (e) => e.toString(),
            'msg',
            contains('codigoFalso'),
          ),
        ),
      );
    });

    test('deve rejeitar valor não numérico', () {
      final json = fixtureJson();
      ((json['esperado'] as Map)['verbas'] as Map)['salaryBalance'] = '2000,00';
      expect(() => parseFixture(json), throwsA(isA<GoldenCaseException>()));
    });

    test('deve marcar entrada não suportada', () {
      final json = fixtureJson();
      (json['entrada'] as Map)['fimPrevisto'] = '2025-12-31';
      expect(parseFixture(json).unsupportedInputs, ['fimPrevisto']);
    });

    test(
      'deve rejeitar fixture (oraculo:false ou id fixture_*) como arquivo de cases/',
      () {
        expect(
          () => GoldenCase.parse(fixtureJson(), origin: 'cases/x.json'),
          throwsA(isA<GoldenCaseException>()),
        );
        final soId = fixtureJson()..remove('oraculo');
        expect(
          () => GoldenCase.parse(soId, origin: 'cases/x.json'),
          throwsA(isA<GoldenCaseException>()),
        );
      },
    );
  });
}
