import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../core/analytics/aso_analytics.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/consent_prompt.dart';
import '../../widgets/termination_type_card.dart';
import '../../widgets/disclaimer_widget.dart';
import '../form/form_screen.dart';
import '../about/about_screen.dart';
import '../history/history_screen.dart';
import '../support/support_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await AsoAnalytics.trackUserEngagement(action: 'screen_view', screen: 'home', timeSpent: 0);
  }

  /// Abre uma tela e, ao voltar, pergunta o consentimento se ainda for a hora
  /// (após o primeiro resultado, antes de qualquer intersticial).
  Future<void> _openAndAskConsent(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
    if (!mounted) return;
    await showConsentPromptIfNeeded(context);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.homeTitle ?? 'Calculadora de Rescisão CLT'),
        actions: [
          Semantics(
            identifier: 'home_history_button',
            child: IconButton(
              tooltip: 'Ver histórico de cálculos',
              icon: const Icon(Icons.history),
              onPressed: () => _openAndAskConsent(const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n?.supportTitle ?? 'Suporte',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportScreen())),
          ),
          IconButton(
            tooltip: l10n?.aboutTitle ?? 'Sobre',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AboutScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.chooseTerminationType ?? 'Escolha o tipo de rescisão:',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...TerminationType.values.map(
                    (TerminationType type) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TerminationTypeCard(type: type, onTap: () => _navigateToForm(context, type)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const DisclaimerWidget(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }

  void _navigateToForm(BuildContext context, TerminationType type) {
    _openAndAskConsent(FormScreen(terminationType: type));
  }
}
