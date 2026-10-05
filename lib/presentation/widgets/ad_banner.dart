import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ads/ad_manager.dart';

/// Banner adaptativo ancorado no rodapé (Scaffold.bottomNavigationBar).
/// Fica vazio até o anúncio carregar.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _isLoaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    final ad = await AdManager.createAdaptiveBanner(
      width,
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
    );
    if (ad == null) return;
    if (!mounted) {
      ad.dispose();
      return;
    }
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_isLoaded || ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
