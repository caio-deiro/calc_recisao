import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calc_recisao/core/services/onboarding_service.dart';

void main() {
  group('OnboardingService Tests', () {
    late OnboardingService onboardingService;

    setUp(() async {
      // Limpar SharedPreferences antes de cada teste
      SharedPreferences.setMockInitialValues({});
      onboardingService = await OnboardingService.instance;
    });

    test('should return false for hasCompletedOnboarding on first run', () async {
      final hasCompleted = await onboardingService.hasCompletedOnboarding();
      expect(hasCompleted, isFalse);
    });

    test('should return true after completing onboarding', () async {
      await onboardingService.completeOnboarding();
      final hasCompleted = await onboardingService.hasCompletedOnboarding();
      expect(hasCompleted, isTrue);
    });

    test('should reset onboarding correctly', () async {
      // Primeiro completa o onboarding
      await onboardingService.completeOnboarding();
      expect(await onboardingService.hasCompletedOnboarding(), isTrue);

      // Depois reseta
      await onboardingService.resetOnboarding();
      expect(await onboardingService.hasCompletedOnboarding(), isFalse);
    });

    test('should persist onboarding state across service instances', () async {
      // Completa o onboarding
      await onboardingService.completeOnboarding();
      expect(await onboardingService.hasCompletedOnboarding(), isTrue);

      // Cria uma nova instância do serviço
      final newService = await OnboardingService.instance;
      expect(await newService.hasCompletedOnboarding(), isTrue);
    });
  });
}
