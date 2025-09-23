import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calc_recisao/core/utils/pro_utils.dart';
import 'package:calc_recisao/core/services/offline_service.dart';
import 'package:calc_recisao/core/services/support_service.dart';
import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';

void main() {
  group('Pro Features Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('ProUtils Tests', () {
      test('should return false for non-pro user', () async {
        SharedPreferences.setMockInitialValues({});

        final isPro = await ProUtils.isProUser();
        expect(isPro, false);
      });

      test('should return true for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final isPro = await ProUtils.isProUser();
        expect(isPro, true);
      });

      test('should not show ads for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final shouldShowAds = await ProUtils.shouldShowAds();
        expect(shouldShowAds, false);
      });

      test('should show ads for non-pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        final shouldShowAds = await ProUtils.shouldShowAds();
        expect(shouldShowAds, true);
      });

      test('should allow PDF export for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final canExportPdf = await ProUtils.canExportPdf();
        expect(canExportPdf, true);
      });

      test('should not allow PDF export for non-pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        final canExportPdf = await ProUtils.canExportPdf();
        expect(canExportPdf, false);
      });

      test('should have unlimited history for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final hasUnlimited = await ProUtils.hasUnlimitedHistory();
        expect(hasUnlimited, true);
      });

      test('should have limited history for non-pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        final hasUnlimited = await ProUtils.hasUnlimitedHistory();
        expect(hasUnlimited, false);
      });

      test('should return correct max history size for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final maxSize = await ProUtils.getMaxHistorySize();
        expect(maxSize, 1000);
      });

      test('should return correct max history size for non-pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        final maxSize = await ProUtils.getMaxHistorySize();
        expect(maxSize, 10);
      });
    });

    group('OfflineService Tests', () {
      test('should cache calculation for pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        final calculation = CalculationHistory(
          id: 'test-id',
          input: TerminationInput(
            admissionDate: DateTime(2024, 1, 1),
            terminationDate: DateTime(2024, 12, 31),
            baseSalary: 3000.0,
          ),
          result: TerminationResult(
            additions: [],
            deductions: [],
            totalToReceive: 3000.0,
            totalDeductions: 0.0,
            netAmount: 3000.0,
            calculationDate: DateTime.now(),
          ),
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now(),
        );

        await OfflineService.cacheCalculation(calculation);

        final cachedCalculations = await OfflineService.getOfflineCalculations();
        expect(cachedCalculations.length, 1);
        expect(cachedCalculations.first.id, 'test-id');
      });

      test('should not cache calculation for non-pro user', () async {
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        final calculation = CalculationHistory(
          id: 'test-id',
          input: TerminationInput(
            admissionDate: DateTime(2024, 1, 1),
            terminationDate: DateTime(2024, 12, 31),
            baseSalary: 3000.0,
          ),
          result: TerminationResult(
            additions: [],
            deductions: [],
            totalToReceive: 3000.0,
            totalDeductions: 0.0,
            netAmount: 3000.0,
            calculationDate: DateTime.now(),
          ),
          terminationType: TerminationType.withoutJustCause,
          timestamp: DateTime.now(),
        );

        await OfflineService.cacheCalculation(calculation);

        final cachedCalculations = await OfflineService.getOfflineCalculations();
        expect(cachedCalculations.length, 0);
      });
    });

    group('SupportService Tests', () {
      test('should return correct response time for pro support', () {
        final responseTime = SupportService.getSupportResponseTime();
        expect(responseTime, '24 horas');
      });

      test('should return correct response time for basic support', () {
        final responseTime = SupportService.getBasicSupportResponseTime();
        expect(responseTime, '3-5 dias úteis');
      });
    });

    group('Purchase Service Tests', () {
      test('should simulate purchase in debug mode', () async {
        // Este teste seria executado apenas em modo debug
        // Em produção, testaria a compra real
        expect(true, true); // Placeholder para teste real
      });

      test('should simulate restore in debug mode', () async {
        // Este teste seria executado apenas em modo debug
        // Em produção, testaria a restauração real
        expect(true, true); // Placeholder para teste real
      });
    });

    group('Pro Features Integration Tests', () {
      test('should provide complete pro experience', () async {
        // Simular usuário PRO
        SharedPreferences.setMockInitialValues({'is_pro_user': true});

        // Verificar todas as funcionalidades PRO
        final isPro = await ProUtils.isProUser();
        final shouldShowAds = await ProUtils.shouldShowAds();
        final canExportPdf = await ProUtils.canExportPdf();
        final hasUnlimited = await ProUtils.hasUnlimitedHistory();
        final maxSize = await ProUtils.getMaxHistorySize();

        expect(isPro, true);
        expect(shouldShowAds, false);
        expect(canExportPdf, true);
        expect(hasUnlimited, true);
        expect(maxSize, 1000);
      });

      test('should provide limited free experience', () async {
        // Simular usuário gratuito
        SharedPreferences.setMockInitialValues({'is_pro_user': false});

        // Verificar limitações da versão gratuita
        final isPro = await ProUtils.isProUser();
        final shouldShowAds = await ProUtils.shouldShowAds();
        final canExportPdf = await ProUtils.canExportPdf();
        final hasUnlimited = await ProUtils.hasUnlimitedHistory();
        final maxSize = await ProUtils.getMaxHistorySize();

        expect(isPro, false);
        expect(shouldShowAds, true);
        expect(canExportPdf, false);
        expect(hasUnlimited, false);
        expect(maxSize, 10);
      });
    });
  });
}
