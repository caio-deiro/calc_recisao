import 'package:calc_recisao/core/analytics/analytics_service.dart';
import 'package:calc_recisao/core/analytics/analytics_sink.dart';
import 'package:calc_recisao/core/analytics/consent_service.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSink implements AnalyticsSink {
  final List<(String, Map<String, Object>?)> events = [];
  final List<bool> collection = [];

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    events.add((name, parameters));
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collection.add(enabled);
  }
}

void main() {
  late _FakeSink sink;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sink = _FakeSink();
    AnalyticsService.sink = sink;
  });

  group('AnalyticsService sem consentimento', () {
    test('deve descartar qualquer evento sem erro', () async {
      await AnalyticsService.calcCompleted(TerminationType.withoutJustCause);
      await AnalyticsService.shareUsed();
      await AnalyticsService.pdfExported();

      expect(sink.events, isEmpty);
    });

    test('deve manter a coleta desligada no boot', () async {
      await AnalyticsService.initialize();

      expect(sink.collection, [false]);
    });

    test('recusar não liga a coleta nem emite consent_decision', () async {
      await AnalyticsService.recordConsent(accepted: false);

      expect(sink.collection, [false]);
      expect(sink.events, isEmpty);
      expect(await ConsentService.isDecided(), isTrue);
      expect(await ConsentService.hasAccepted(), isFalse);
    });
  });

  group('AnalyticsService com consentimento', () {
    setUp(() async {
      await AnalyticsService.recordConsent(accepted: true);
      sink.events.clear();
    });

    test('deve ligar a coleta e emitir consent_decision ao aceitar', () async {
      SharedPreferences.setMockInitialValues({});
      final fresh = _FakeSink();
      AnalyticsService.sink = fresh;

      await AnalyticsService.recordConsent(accepted: true);

      expect(fresh.collection, [true]);
      expect(fresh.events.single.$1, 'consent_decision');
      expect(fresh.events.single.$2, {'decisao': 'aceitou'});
    });

    test('calc_completed deve enviar apenas tipo_rescisao', () async {
      await AnalyticsService.calcCompleted(TerminationType.withoutJustCause);

      expect(sink.events.single.$1, 'calc_completed');
      expect(sink.events.single.$2, {'tipo_rescisao': 'withoutJustCause'});
    });

    test('share_used e pdf_exported não devem ter parâmetros', () async {
      await AnalyticsService.shareUsed();
      await AnalyticsService.pdfExported();

      expect(sink.events, [('share_used', null), ('pdf_exported', null)]);
    });
  });
}
