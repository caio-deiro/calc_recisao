import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/analytics/aso_analytics.dart';
import '../../../core/utils/pro_utils.dart';
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
    final isPro = await ProUtils.isProUser();
    setState(() {
      _isPro = isPro;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    _bannerAd = await AdManager.createBannerAd();
    _bannerAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Rescisão CLT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HistoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportScreen())),
          ),
          IconButton(
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
                  const Text(
                    'Escolha o tipo de rescisão:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (!_isPro) ...[_buildProUpgradeCard(), const SizedBox(height: 16)],
                  ...TerminationType.values.map(
                    (type) => Padding(
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
          if (_bannerAd != null) _buildBannerAd(),
        ],
      ),
    );
  }

  Widget _buildBannerAd() {
    if (_bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Widget _buildProUpgradeCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.blue.shade200, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProScreen())),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade para PRO',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ 4,90/mês • Sem anúncios • PDF • Histórico ilimitado',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.8), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context, TerminationType type) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => FormScreen(terminationType: type)));
  }
}
