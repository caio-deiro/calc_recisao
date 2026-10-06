import 'dart:io';

import 'package:calc_recisao/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Identidade e links do app', () {
    test('deve usar o e-mail e a URL de política decididos', () {
      expect(AppConstants.supportEmail, 'caioguimaraes12@outlook.com');
      expect(
        AppConstants.privacyPolicyUrl,
        'https://caio-deiro.github.io/calc_recisao',
      );
    });

    test('não deve citar o domínio inexistente em lib/ nem test/', () {
      const needle =
          'calcrescisao'
          '.com';
      final offenders = <String>[];
      for (final dir in ['lib', 'test']) {
        for (final f in Directory(
          dir,
        ).listSync(recursive: true).whereType<File>()) {
          if (!f.path.endsWith('.dart')) continue;
          if (f.path.endsWith('app_identity_test.dart')) continue;
          if (f.readAsStringSync().contains(needle)) offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty);
    });

    test('não deve manter o código morto de ASO', () {
      expect(
        File('lib/core/ab_testing/aso_ab_testing.dart').existsSync(),
        isFalse,
      );
      expect(
        File('lib/core/deep_links/aso_deep_links.dart').existsSync(),
        isFalse,
      );
      expect(
        File('lib/core/analytics/aso_analytics.dart').existsSync(),
        isFalse,
      );
    });

    test('deve ter o nome canônico no Android e no pubspec', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      final strings = File(
        'android/app/src/main/res/values/strings.xml',
      ).readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();

      expect(
        strings,
        contains(
          '<string name="app_name">Calculadora de Rescisão CLT</string>',
        ),
      );
      expect(manifest, contains('android:label="@string/app_name"'));
      expect(manifest, isNot(contains('app_category')));
      expect(manifest, isNot(contains('app_keywords')));
      expect(manifest, isNot(contains('app_description')));
      expect(pubspec, isNot(contains('Trabalhista 2025')));
    });
  });
}
