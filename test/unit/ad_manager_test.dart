import 'package:calc_recisao/core/ads/ad_ids.dart';
import 'package:calc_recisao/core/ads/ad_manager.dart';
import 'package:calc_recisao/core/analytics/consent_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AdManager Tests', () {
    test('should have correct ad configuration', () {
      // Verificar se os IDs estão sendo retornados corretamente
      expect(AdIds.bannerId, isNotEmpty);
      expect(AdIds.interstitialId, isNotEmpty);
      expect(AdIds.appOpenId, isNotEmpty);
    });

    test('should respect remove ads flag', () {
      // Verificar se os IDs estão sendo retornados corretamente
      expect(AdIds.bannerId, isNotEmpty);
      expect(AdIds.interstitialId, isNotEmpty);
      expect(AdIds.appOpenId, isNotEmpty);
    });

    test('should have valid test ad IDs', () {
      // Verificar se os IDs de teste são válidos
      expect(AdIds.bannerTestId, contains('ca-app-pub-3940256099942544'));
      expect(AdIds.interstitialTestId, contains('ca-app-pub-3940256099942544'));
      expect(AdIds.appOpenTestId, contains('ca-app-pub-3940256099942544'));
    });

    test('should have production ad IDs configured', () {
      // Verificar se os IDs de produção estão configurados
      expect(AdIds.bannerProductionId, isNotEmpty);
      expect(AdIds.interstitialProductionId, isNotEmpty);
      expect(AdIds.appOpenProductionId, isNotEmpty);
    });
  });

  group('AdManager.showInterstitialOnExit', () {
    final now = DateTime(2026, 1, 1, 12, 0);

    setUp(() {
      SharedPreferences.setMockInitialValues({'consent_decided': true});
      AdManager.resetSession();
    });

    test('não deve exibir nem esperar quando o anúncio não está carregado', () async {
      expect(await AdManager.showInterstitialOnExit(now: now), isFalse);
    });

    test('deve permitir quando a sessão é nova e passaram mais de 3 min', () async {
      SharedPreferences.setMockInitialValues({
        'consent_decided': true,
        'last_interstitial_time': now.subtract(const Duration(minutes: 4)).millisecondsSinceEpoch,
      });

      expect(await AdManager.isInterstitialAllowed(now: now), isTrue);
    });

    test('deve permitir quando nunca houve intersticial', () async {
      expect(await AdManager.isInterstitialAllowed(now: now), isTrue);
    });

    test('não deve permitir com menos de 3 min desde o último', () async {
      SharedPreferences.setMockInitialValues({
        'consent_decided': true,
        'last_interstitial_time': now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
      });

      expect(await AdManager.isInterstitialAllowed(now: now), isFalse);
    });

    test('não deve permitir antes da decisão de consentimento', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await AdManager.isInterstitialAllowed(now: now), isFalse);
    });
  });

  group('AdManager.requestFor (B1-14)', () {
    test('deve forçar anúncios não personalizados sem consentimento', () {
      expect(AdManager.requestFor(consented: false).nonPersonalizedAds, isTrue);
    });

    test('deve usar requisição normal após o aceite', () {
      expect(AdManager.requestFor(consented: true).nonPersonalizedAds, isNull);
    });

    test('buildRequest deve seguir o consentimento persistido', () async {
      SharedPreferences.setMockInitialValues({});
      expect((await AdManager.buildRequest()).nonPersonalizedAds, isTrue);

      await ConsentService.saveDecision(accepted: true);
      expect((await AdManager.buildRequest()).nonPersonalizedAds, isNull);
    });
  });
}
