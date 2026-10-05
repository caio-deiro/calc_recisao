import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_ids.dart';
import '../analytics/consent_service.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

class AdManager {
  AdManager._();

  static const String _lastInterstitialKey = 'last_interstitial_time';

  static InterstitialAd? _interstitial;
  static bool _isLoadingInterstitial = false;
  static bool _shownThisSession = false;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    await loadInterstitial();
  }

  /// Não personalizado até o aceite do consentimento (B1-14).
  @visibleForTesting
  static AdRequest requestFor({required bool consented}) => AdRequest(nonPersonalizedAds: consented ? null : true);

  static Future<AdRequest> buildRequest() async => requestFor(consented: await ConsentService.hasAccepted());

  /// Banner adaptativo ancorado de largura [width]; null se não for possível.
  static Future<BannerAd?> createAdaptiveBanner(int width, {VoidCallback? onLoaded}) async {
    try {
      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null) return null;
      return BannerAd(
        adUnitId: AdIds.bannerId,
        size: size,
        request: await buildRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) => onLoaded?.call(),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            AppLogger.warning('Banner não carregou: ${error.code}');
          },
        ),
      );
    } catch (e) {
      AppLogger.warning('Erro ao criar banner', e);
      return null;
    }
  }

  /// Pré-carrega o intersticial para que a saída do Resultado nunca espere.
  static Future<void> loadInterstitial() async {
    if (_interstitial != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: AdIds.interstitialId,
        request: await buildRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                loadInterstitial();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                loadInterstitial();
              },
            );
            _interstitial = ad;
            _isLoadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            _isLoadingInterstitial = false;
            AppLogger.warning('Intersticial não carregou: ${error.code}');
          },
        ),
      );
    } catch (e) {
      _isLoadingInterstitial = false;
      AppLogger.warning('Erro ao carregar intersticial', e);
    }
  }

  /// 1 por sessão, 1 a cada 3 min e nunca antes da decisão de consentimento.
  @visibleForTesting
  static Future<bool> isInterstitialAllowed({DateTime? now}) async {
    if (_shownThisSession) return false;
    if (!await ConsentService.isDecided()) return false;

    final prefs = await SharedPreferences.getInstance();
    final lastTime = prefs.getInt(_lastInterstitialKey) ?? 0;
    final elapsed = (now ?? DateTime.now()).millisecondsSinceEpoch - lastTime;
    return elapsed >= AppConstants.interstitialAdCooldown.inMilliseconds;
  }

  /// Exibe o intersticial ao sair do Resultado, se permitido. Nunca espera.
  static Future<bool> showInterstitialOnExit({DateTime? now}) async {
    final ad = _interstitial;
    if (ad == null) return false;
    if (!await isInterstitialAllowed(now: now)) return false;

    _interstitial = null;
    _shownThisSession = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastInterstitialKey, (now ?? DateTime.now()).millisecondsSinceEpoch);
    await ad.show();
    return true;
  }

  @visibleForTesting
  static void resetSession() => _shownThisSession = false;
}
