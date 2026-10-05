import 'package:calc_recisao/core/services/legacy_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LegacyCleanup', () {
    const legacy = <String, Object>{
      'is_pro_user': true,
      'pro_purchase_date': '2025-01-01',
      'pro_purchase_id': 'abc',
      'pro_purchase_token': 'tok',
      'offline_cache': <String>['x'],
      'pending_sync': <String>['y'],
      'pro_conversion': 2,
    };

    test('deve remover as 7 chaves legadas e preservar o histórico', () async {
      SharedPreferences.setMockInitialValues({
        ...legacy,
        'calculation_history': <String>['{"id":"1"}'],
        'onboarding_completed': true,
      });

      await LegacyCleanup.run();

      final prefs = await SharedPreferences.getInstance();
      for (final key in legacy.keys) {
        expect(prefs.containsKey(key), isFalse, reason: key);
      }
      expect(prefs.getStringList('calculation_history'), ['{"id":"1"}']);
      expect(prefs.getBool('onboarding_completed'), isTrue);
    });

    test('não deve falhar quando não há chaves legadas', () async {
      SharedPreferences.setMockInitialValues({
        'calculation_history': <String>[],
      });

      await LegacyCleanup.run();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'calculation_history'});
    });

    test('deve ser idempotente ao rodar duas vezes', () async {
      SharedPreferences.setMockInitialValues({
        ...legacy,
        'calculation_history': <String>['a'],
      });

      await LegacyCleanup.run();
      final prefs = await SharedPreferences.getInstance();
      final afterFirst = prefs.getKeys();
      await LegacyCleanup.run();

      expect(prefs.getKeys(), afterFirst);
    });
  });
}
