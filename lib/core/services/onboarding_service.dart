import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static OnboardingService? _instance;
  static SharedPreferences? _prefs;

  OnboardingService._();

  static Future<OnboardingService> get instance async {
    _instance ??= OnboardingService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  /// Verifica se o usuário já completou o onboarding
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Marca o onboarding como completo
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Reseta o onboarding (útil para testes ou reset de configurações)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
