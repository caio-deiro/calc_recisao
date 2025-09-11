class AdIds {
  // IDs de teste do AdMob
  static const String bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
  static const String interstitialTestId = 'ca-app-pub-3940256099942544/1033173712';
  static const String appOpenTestId = 'ca-app-pub-3940256099942544/3419835294';

  // IDs de produção do AdMob
  static const String bannerProductionId = 'ca-app-pub-2507636022850832/3598485459';
  static const String interstitialProductionId = 'ca-app-pub-2507636022850832/1974450586';
  static const String appOpenProductionId = 'ca-app-pub-2507636022850832/3598485459'; // Usando o mesmo ID por enquanto

  // Flag para usar IDs de produção (true) ou teste (false)
  static const bool kUseProductionIds = true;

  // Flag para remover anúncios (versão PRO)
  static const bool kRemoveAds = false;

  // IDs atuais baseados nas flags
  static String get bannerId => kRemoveAds ? '' : (kUseProductionIds ? bannerProductionId : bannerTestId);
  static String get interstitialId =>
      kRemoveAds ? '' : (kUseProductionIds ? interstitialProductionId : interstitialTestId);
  static String get appOpenId => kRemoveAds ? '' : (kUseProductionIds ? appOpenProductionId : appOpenTestId);
}
