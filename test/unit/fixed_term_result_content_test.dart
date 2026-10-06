import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/core/utils/result_content.dart';
import 'package:calc_recisao/core/utils/share_utils.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter_test/flutter_test.dart';

/// Itens do art. 479/480 e suas premissas no texto compartilhado e nas seções do PDF (B4-05, B4-06).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async => TaxTablesService.instance.loadTaxTables());

  TerminationInput input() => TerminationInput(
    admissionDate: DateTime(2026, 1, 12),
    terminationDate: DateTime(2026, 3, 10),
    baseSalary: 3000,
    fixedTermEndDate: DateTime(2026, 4, 9),
  );

  String share(TerminationType type) => ShareUtils.generateShareText(
    input: input(),
    result: const CalculateTerminationUseCase().execute(input(), type),
    terminationType: type,
  );

  test(
    'deve mostrar a indenização do art. 479 e a marca de validação no texto compartilhado',
    () {
      final text = share(TerminationType.fixedTermEarlyByEmployer);
      expect(text, contains('Indenização Art. 479'));
      expect(text, contains('Cálculo em validação'));
    },
  );

  test(
    'deve mostrar o desconto do art. 480 e o aviso de valor máximo no texto compartilhado',
    () {
      final text = share(TerminationType.fixedTermEarlyByEmployee);
      expect(text, contains('Indenização Art. 480'));
      expect(
        text,
        contains('valor máximo; depende de comprovação do prejuízo'),
      );
      expect(text, contains('Cálculo em validação'));
    },
  );

  test('deve manter o texto do acordo mútuo fora das indenizações a prazo', () {
    final text = share(TerminationType.fixedTermEarlyByEmployer);
    expect(text.contains('acordo mútuo'), isFalse);
  });

  test('deve montar as seções com o item do art. 479 em Verbas pagas', () {
    final result = const CalculateTerminationUseCase().execute(
      input(),
      TerminationType.fixedTermEarlyByEmployer,
    );
    final sections = buildResultSections(
      input: input(),
      result: result,
      terminationType: TerminationType.fixedTermEarlyByEmployer,
    );
    final paid = sections.firstWhere((s) => s.title == 'Verbas pagas');
    expect(paid.rows.any((r) => r.label.contains('Art. 479')), isTrue);
  });

  test('deve mostrar a linha de saque de 100 % no término normal', () {
    final text = share(TerminationType.fixedTermEnd);
    expect(text, contains('Saque de 100 %'));
  });
}
