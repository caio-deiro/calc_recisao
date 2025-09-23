import 'package:flutter/material.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../../../core/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Pequeno delay para mostrar o splash
    await Future.delayed(const Duration(milliseconds: 500));

    final onboardingService = await OnboardingService.instance;
    final hasCompletedOnboarding = await onboardingService.hasCompletedOnboarding();

    if (mounted) {
      if (hasCompletedOnboarding) {
        // Usuário já viu o onboarding, vai direto para a home
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        // Primeira vez, mostra o onboarding
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const OnboardingScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 80, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(height: 24),
            Text(
              'Calculadora de Rescisão CLT',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Carregando...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
}
