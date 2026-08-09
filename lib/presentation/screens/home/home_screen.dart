import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/analytics/aso_analytics.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pro_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../widgets/termination_type_card.dart';
import '../../widgets/disclaimer_widget.dart';
import '../form/form_screen.dart';
import '../about/about_screen.dart';
import '../history/history_screen.dart';
import '../pro/pro_screen.dart';
import '../support/support_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isPro = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _checkProStatus();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await AsoAnalytics.trackUserEngagement(action: 'screen_view', screen: 'home', timeSpent: 0);
  }

  Future<void> _checkProStatus() async {
    final bool isPro = await ProUtils.isProUser();
    if (!mounted) return;
    setState(() => _isPro = isPro);
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    final BannerAd? bannerAd = await AdManager.createBannerAd(
      onLoaded: () {
        if (mounted) setState(() {});
      },
    );
    if (!mounted) return;
    setState(() => _bannerAd = bannerAd);
    bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.homeTitle ?? 'Calculadora de Rescisão CLT'),
        actions: [
          IconButton(
            tooltip: 'Ver histórico de cálculos',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n?.proTitle ?? 'Versão PRO',
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n?.supportTitle ?? 'Suporte',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SupportScreen()),
            ),
          ),
          IconButton(
            tooltip: l10n?.aboutTitle ?? 'Sobre',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
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
                      child: TerminationTypeCard(
                        type: type,
                        onTap: () => _navigateToForm(context, type),
                      ),
                    ),
                  ),
                  if (!_isPro) ...[
                    const SizedBox(height: 4),
                    _buildProUpgradeCard(colorScheme),
                  ],
                  const SizedBox(height: 24),
                  const DisclaimerWidget(),
                ],
              ),
            ),
          ),
          if (_bannerAd != null) _buildBannerAd(colorScheme),
        ],
      ),
    );
  }

  Widget _buildBannerAd(ColorScheme colorScheme) {
    final BannerAd bannerAd = _bannerAd!;
    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: SizedBox(
        width: double.infinity,
        height: bannerAd.size.height.toDouble(),
        child: Center(
          child: SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(ad: bannerAd),
          ),
        ),
      ),
    );
  }

  Widget _buildProUpgradeCard(ColorScheme colorScheme) {
    final String formattedPrice = AppConstants.proMonthlyPrice.toStringAsFixed(2).replaceAll('.', ',');
    return Semantics(
      label: 'Upgrade para PRO. R\$ $formattedPrice por mês. Sem anúncios, exportação PDF e histórico ilimitado.',
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colorScheme.primary, AppTheme.primaryDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.star, color: colorScheme.onPrimary, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade para PRO',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ $formattedPrice/mês · Sem anúncios · PDF · Histórico ilimitado',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, TerminationType type) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FormScreen(terminationType: type)),
    );
  }
}
