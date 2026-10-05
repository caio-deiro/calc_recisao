import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/core/services/tax_tables_service.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';

void main() {
  group('Rescisão junho/2026', () {
    late CalculateTerminationUseCase useCase;
    late TaxTablesService taxService;
    final DateTime terminationDate = DateTime(2026, 6, 15);

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      useCase = const CalculateTerminationUseCase();
      taxService = TaxTablesService.instance;
      await taxService.loadTaxTables();
    });

    test('deve calcular verbas rescisórias conforme cenário de referência', () {
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2024, 3, 1),
        terminationDate: terminationDate,
        baseSalary: 4000.0,
        workedDaysInMonth: 15,
        noticeWorked: false,
        calculateTaxes: false,
      );

      final result = useCase.execute(input, TerminationType.withoutJustCause);

      final salaryBalance = result.additions.firstWhere((item) => item.description == 'Saldo de Salário');
      final notice = result.additions.firstWhere((item) => item.description == 'Aviso Prévio Indenizado');
      final thirteenth = result.additions.firstWhere((item) => item.description == '13º Salário Proporcional');
      final vacation = result.additions.firstWhere((item) => item.description == 'Férias Proporcionais + 1/3');

      expect(salaryBalance.value, 2000.0);
      expect(notice.value, closeTo(4800.0, 0.01));
      expect(thirteenth.value, 2000.0);
      expect(vacation.value, closeTo(2666.67, 0.01));
    });

    test('deve aplicar impostos apenas sobre verbas tributáveis em 2026', () {
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2024, 3, 1),
        terminationDate: terminationDate,
        baseSalary: 4000.0,
        workedDaysInMonth: 15,
        noticeWorked: false,
        calculateTaxes: true,
      );

      final result = useCase.execute(input, TerminationType.withoutJustCause);
      final double vacationAmount = result.additions
          .where((item) => item.description.contains('Férias'))
          .fold(0.0, (sum, item) => sum + item.value);

      final inss = result.deductions.where((item) => item.description == 'INSS');

      expect(inss.length, 1);
      expect(inss.first.value, closeTo(taxService.calculateInss(4000.0, terminationDate), 0.01));
      expect(
        taxService.calculateTerminationTaxes(
          salaryBalance: 2000.0,
          thirteenthSalary: 2000.0,
          vacationAmount: vacationAmount,
          terminationDate: terminationDate,
        ).irrf,
        greaterThanOrEqualTo(0),
      );
      expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isTrue);
      expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isTrue);
    });

    test('pedido de demissão deve descontar aviso prévio não cumprido', () {
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2024, 3, 1),
        terminationDate: terminationDate,
        baseSalary: 4000.0,
        workedDaysInMonth: 15,
        noticeWorked: false,
        calculateTaxes: false,
      );

      final result = useCase.execute(input, TerminationType.resignation);

      expect(result.additions.any((item) => item.description == 'Aviso Prévio Indenizado'), isFalse);
      expect(result.deductions.any((item) => item.description == 'Desconto Aviso Prévio'), isTrue);
      expect(result.additions.any((item) => item.description == 'Multa FGTS (40%)'), isFalse);
    });

    test('deve permitir férias vencidas e proporcionais simultaneamente', () {
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2024, 3, 1),
        terminationDate: terminationDate,
        baseSalary: 4000.0,
        hasAccruedVacation: true,
        calculateTaxes: false,
      );

      final result = useCase.execute(input, TerminationType.withoutJustCause);

      expect(result.additions.any((item) => item.description == 'Férias Vencidas + 1/3'), isTrue);
      expect(result.additions.any((item) => item.description == 'Férias Proporcionais + 1/3'), isTrue);
    });
  });
}
