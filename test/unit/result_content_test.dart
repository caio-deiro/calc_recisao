import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/core/utils/pdf_utils.dart';
import 'package:calc_recisao/core/utils/result_content.dart';
import 'package:calc_recisao/core/utils/share_utils.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/result_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await TaxTablesService.instance.loadTaxTables();
  });

  /// Termos que nenhum texto exportado pode conter (rótulos antigos, marca PRO, promessa de precisão).
  void expectNoBannedTerms(String text) {
    for (final banned in ['Valor Líquido', 'Total a Receber', 'PRO', 'exato', 'garant']) {
      expect(text.contains(banned), isFalse, reason: 'contém "$banned"');
    }
  }

  String fullText(TerminationType type, {double? fgts}) {
    final result = calculate(type, fgts: fgts);
    return ShareUtils.generateShareText(
      input: sampleInput(fgts: fgts),
      result: result,
      terminationType: type,
    );
  }

  String simpleText(TerminationType type, {double? fgts}) {
    final result = calculate(type, fgts: fgts);
    return ShareUtils.generateSimpleShareText(
      input: sampleInput(fgts: fgts),
      result: result,
      terminationType: type,
    );
  }

  group('Texto de compartilhamento completo (B5-03)', () {
    test('deve ter os dois totais, verbas, multa depositada e cada premissa', () {
      final result = calculate(TerminationType.withoutJustCause, fgts: 10000);
      final text = fullText(TerminationType.withoutJustCause, fgts: 10000);

      expect(text, contains('Pago na rescisão'));
      expect(text, contains('Depositado no FGTS'));
      expect(text, contains('Saldo de Salário'));
      expect(text, contains('Multa FGTS (40%)'));
      expect(text, contains('Premissas desta estimativa'));
      for (final a in result.assumptions) {
        expect(text, contains(a.text));
      }
    });

    test('deve manter a ordem do Resultado: totais, verbas, FGTS, premissas', () {
      final text = fullText(TerminationType.withoutJustCause, fgts: 10000);
      final order = ['Totais', 'Verbas pagas', 'Premissas desta estimativa'].map(text.indexOf).toList();
      expect(order, everyElement(greaterThanOrEqualTo(0)));
      expect([...order]..sort(), order);
    });

    test('deve ter a ressalva de estimativa e nenhum termo proibido', () {
      final text = fullText(TerminationType.withoutJustCause, fgts: 10000);
      expect(text, contains('Estimativa'));
      expect(text, contains('TRCT oficial prevalece'));
      expectNoBannedTerms(text);
    });

    test('deve trazer a linha "cálculo em validação" no acordo mútuo e não nos demais', () {
      expect(fullText(TerminationType.mutualAgreement, fgts: 10000).toLowerCase(), contains('cálculo em validação'));
      expect(fullText(TerminationType.withoutJustCause, fgts: 10000).toLowerCase(), isNot(contains('em validação')));
    });
  });

  group('Texto de compartilhamento resumido (B5-03)', () {
    test('deve ter os dois totais e não ter a lista de premissas nem de verbas', () {
      final result = calculate(TerminationType.withoutJustCause, fgts: 10000);
      final text = simpleText(TerminationType.withoutJustCause, fgts: 10000);

      expect(text, contains('Pago na rescisão'));
      expect(text, contains('Depositado no FGTS'));
      expect(text, isNot(contains('Premissas desta estimativa')));
      for (final a in result.assumptions) {
        expect(text, isNot(contains(a.text)));
      }
      expect(text, isNot(contains('Saldo de Salário')));
      expectNoBannedTerms(text);
    });

    test('deve trazer a linha "cálculo em validação" quando houver', () {
      expect(simpleText(TerminationType.mutualAgreement, fgts: 10000).toLowerCase(), contains('cálculo em validação'));
    });

    test('deve manter a ressalva de estimativa', () {
      expect(simpleText(TerminationType.withoutJustCause), contains('TRCT oficial prevalece'));
    });

    test('linha de saque aparece só onde há percentual', () {
      expect(simpleText(TerminationType.withoutJustCause, fgts: 10000), contains('100 %'));
      expect(simpleText(TerminationType.mutualAgreement, fgts: 10000), contains('80 %'));
      expect(simpleText(TerminationType.resignation), isNot(contains('Saque')));
    });
  });

  group('Conteúdo do PDF (B5-03, B5-05)', () {
    String pdfText(TerminationType type, {double? fgts}) {
      final sections = PdfUtils.buildContent(
        input: sampleInput(fgts: fgts),
        result: calculate(type, fgts: fgts),
        terminationType: type,
      );
      return renderSectionsAsText(sections);
    }

    test('deve ter os dois totais, premissas e a ressalva', () {
      final result = calculate(TerminationType.withoutJustCause, fgts: 10000);
      final text = pdfText(TerminationType.withoutJustCause, fgts: 10000);

      expect(text, contains('Pago na rescisão'));
      expect(text, contains('Depositado no FGTS'));
      for (final a in result.assumptions) {
        expect(text, contains(a.text));
      }
      expect(text, contains('TRCT oficial prevalece'));
      expectNoBannedTerms(text);
    });

    test('deve ter a mesma estrutura do compartilhamento completo', () {
      expect(
        pdfText(TerminationType.mutualAgreement, fgts: 10000),
        fullText(TerminationType.mutualAgreement, fgts: 10000),
      );
    });

    test('deve trazer a linha "cálculo em validação" quando houver', () {
      expect(pdfText(TerminationType.mutualAgreement, fgts: 10000).toLowerCase(), contains('cálculo em validação'));
    });
  });
}
