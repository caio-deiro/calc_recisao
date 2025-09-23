import 'package:flutter/material.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../../core/services/onboarding_service.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Calculadora de Rescisão CLT',
      subtitle: 'Calcule suas verbas rescisórias de forma simples e rápida',
      description:
          'Esta aplicação auxilia no cálculo estimativo de verbas rescisórias conforme a CLT, incluindo saldo de salário, 13º proporcional, férias e FGTS.',
      icon: Icons.calculate,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Estimativas e Privacidade',
      subtitle: 'Cálculos locais e dados seguros',
      description:
          'Todos os cálculos são realizados localmente no seu dispositivo. Os resultados são estimativas baseadas em regras gerais da CLT. Consulte sempre um profissional qualificado.',
      icon: Icons.security,
      color: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: ResponsiveHelper.getAdaptivePaddingAll(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - (ResponsiveHelper.getAdaptivePadding(context) * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: ResponsiveHelper.getAdaptiveIconSize(context),
                    height: ResponsiveHelper.getAdaptiveIconSize(context),
                    decoration: BoxDecoration(color: page.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(
                      page.icon,
                      size: ResponsiveHelper.getAdaptiveIconSize(context) * 0.5,
                      color: page.color,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(
                    page.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveHelper.getAdaptiveTitleSize(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75),
                  Text(
                    page.subtitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: ResponsiveHelper.getAdaptiveSubtitleSize(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
                  Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: ResponsiveHelper.getAdaptiveDescriptionSize(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: ResponsiveHelper.getAdaptivePaddingAll(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1 ? _finishOnboarding : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: ResponsiveHelper.getAdaptivePaddingSymmetric(
                  context,
                  vertical: ResponsiveHelper.getAdaptiveSpacing(context),
                ),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Começar' : 'Próximo',
                style: TextStyle(fontSize: ResponsiveHelper.isSmallScreen(context) ? 14 : 16),
              ),
            ),
          ),
          if (_currentPage < _pages.length - 1) ...[
            SizedBox(height: ResponsiveHelper.getAdaptiveSpacing(context) * 0.75),
            TextButton(
              onPressed: _finishOnboarding,
              child: Text('Pular', style: TextStyle(fontSize: ResponsiveHelper.isSmallScreen(context) ? 14 : 16)),
            ),
          ],
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _finishOnboarding() async {
    final onboardingService = await OnboardingService.instance;
    await onboardingService.completeOnboarding();

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
