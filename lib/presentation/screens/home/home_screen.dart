import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../core/ads/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../widgets/termination_type_card.dart';
import '../../widgets/disclaimer_widget.dart';
import '../form/form_screen.dart';
import '../about/about_screen.dart';
import '../history/history_screen.dart';
import '../pro/pro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
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

  void _navigateToForm(BuildContext context, TerminationType type) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => FormScreen(terminationType: type)));
  }
}
