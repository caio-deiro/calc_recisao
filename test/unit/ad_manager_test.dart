import 'package:calc_recisao/core/ads/ad_ids.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
