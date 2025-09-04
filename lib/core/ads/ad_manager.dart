import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_ids.dart';

class AdManager {
  static const String _lastInterstitialKey = 'last_interstitial_time';
  static const int _interstitialCooldownMinutes = 3;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: AdIds.bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Banner ad loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed to load: $error');
        },
      ),
    );
  }

  static Future<InterstitialAd?> createInterstitialAd() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTime = prefs.getInt(_lastInterstitialKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final minutesSinceLastAd = (now - lastTime) / (1000 * 60);

      if (minutesSinceLastAd < _interstitialCooldownMinutes) {
        return null;
      }

      InterstitialAd? interstitialAd;
      await InterstitialAd.load(
        adUnitId: AdIds.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _updateLastInterstitialTime();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                debugPrint('Interstitial ad failed to show: $error');
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
      return interstitialAd;
    } catch (e) {
      debugPrint('Error creating interstitial ad: $e');
      return null;
    }
  }

  static Future<void> _updateLastInterstitialTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastInterstitialKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> showInterstitialAd() async {
    final ad = await createInterstitialAd();
    if (ad != null) {
      await ad.show();
    }
  }
}
