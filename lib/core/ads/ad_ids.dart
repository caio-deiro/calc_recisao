class AdIds {
  // IDs de teste do AdMob
  static const String bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String appOpenTestId = 'ca-app-pub-3940256099942544/3419835294';

  // IDs de produção do AdMob (substitua pelos seus IDs reais)
  static const String bannerProductionId = 'ca-app-pub-3940256099942544/6300978111'; // ID de teste para demonstração
  static const String interstitialProductionId =
      'ca-app-pub-3940256099942544/1033173712'; // ID de teste para demonstração
  static const String appOpenProductionId = 'ca-app-pub-3940256099942544/3419835294'; // ID de teste para demonstração

  // Flag para remover anúncios (versão PRO)
  static const bool kRemoveAds = false;

  // IDs atuais baseados na flag
  static String get bannerId => kRemoveAds ? '' : bannerTestId;
  static String get interstitialId => kRemoveAds ? '' : interstitialTestId;
  static String get appOpenId => kRemoveAds ? '' : appOpenTestId;
}
