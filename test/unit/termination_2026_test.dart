import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calc_recisao/domain/entities/breakdown_code.dart';
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

      final salaryBalance = result.additions.firstWhere(
        (item) => item.code == BreakdownCode.salaryBalance,
      );
      final notice = result.additions.firstWhere(
        (item) => item.code == BreakdownCode.notice,
      );
      final thirteenth = result.additions.firstWhere(
        (item) => item.code == BreakdownCode.thirteenth,
      );
      final vacation = result.additions.firstWhere(
        (item) => item.code == BreakdownCode.proportionalVacation,
      );

      expect(salaryBalance.value, 2000.0);
      expect(notice.value, closeTo(4800.0, 0.01));
      // Aviso de 36 dias (2 anos) projeta +1 avo (C2, CLT art. 487 §1º).
      // 13º: jan a jun/2026 (junho, dia 15, conta) = 6 + 1 = 7/12 de 4000 = 2333,33.
      expect(thirteenth.value, closeTo(2333.33, 0.01));
      // Férias (C3): período aquisitivo desde 01/03/2026 = 3 meses + 15 dias (conta) = 4, +1 de projeção = 5/12 x 4000 x 4/3 = 2222,22.
      expect(vacation.value, closeTo(2222.22, 0.01));
    });

    test('deve arredondar o INSS de saldo e 13º antes de somar (356,38)', () {
      // Saldo 3000/30 x 20 = 2.000 (155,685 -> 155,69); 13º 10/12 x 3000 = 2.500
      // (200,685 -> 200,69). Soma 356,38; a soma crua daria 356,37.
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2025, 3, 10),
        terminationDate: DateTime(2026, 10, 20),
        baseSalary: 3000.0,
        workedDaysInMonth: 20,
        noticeWorked: true,
        vacationPeriodsTaken: 1,
        calculateTaxes: true,
      );

      final result = useCase.execute(input, TerminationType.resignation);
      final inss = result.deductions.firstWhere(
        (item) => item.code == BreakdownCode.inss,
      );

      expect(inss.value, 356.38);
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
      final inss = result.deductions.where(
        (item) => item.code == BreakdownCode.inss,
      );

      expect(inss.length, 1);
      // C5: INSS do saldo (2000,00) e do 13º (2333,33) apurados em separado.
      expect(
        inss.first.value,
        closeTo(
          (taxService.calculateInss(Decimal.parse('2000.0'), terminationDate) +
                  taxService.calculateInss(
                    Decimal.parse('2333.33'),
                    terminationDate,
                  ))
              .toDouble(),
          0.01,
        ),
      );
      expect(
        taxService
            .calculateTerminationTaxes(
              salaryBalance: Decimal.parse('2000.0'),
              thirteenthSalary: Decimal.parse('2000.0'),
              terminationDate: terminationDate,
            )
            .irrf
            .toDouble(),
        greaterThanOrEqualTo(0),
      );
      expect(
        result.additions.any((item) => item.code == BreakdownCode.notice),
        isTrue,
      );
      expect(
        result.fgtsDeposit.items.any(
          (item) => item.code == BreakdownCode.fgtsFine,
        ),
        isTrue,
      );
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

      expect(
        result.additions.any((item) => item.code == BreakdownCode.notice),
        isFalse,
      );
      expect(
        result.deductions.any(
          (item) => item.code == BreakdownCode.noticeDiscount,
        ),
        isTrue,
      );
      expect(
        result.fgtsDeposit.items.any(
          (item) => item.code == BreakdownCode.fgtsFine,
        ),
        isFalse,
      );
    });

    test('deve permitir férias vencidas e proporcionais simultaneamente', () {
      final TerminationInput input = TerminationInput(
        admissionDate: DateTime(2024, 3, 1),
        terminationDate: terminationDate,
        baseSalary: 4000.0,
        vacationPeriodsTaken: 1,
        calculateTaxes: false,
      );

      final result = useCase.execute(input, TerminationType.withoutJustCause);

      expect(
        result.additions.any(
          (item) => item.code == BreakdownCode.accruedVacationSimple,
        ),
        isTrue,
      );
      expect(
        result.additions.any(
          (item) => item.code == BreakdownCode.proportionalVacation,
        ),
        isTrue,
      );
    });
  });
}
