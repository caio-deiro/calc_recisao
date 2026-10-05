import 'package:flutter/foundation.dart';

import '../../domain/entities/termination_type.dart';
import 'analytics_sink.dart';
import 'consent_service.dart';

/// Único ponto de emissão de eventos (B1-13, B0-03).
///
/// Sem consentimento nada sai. Só os eventos e parâmetros da lista abaixo são
/// aceitos; nunca salário, datas, valores ou resultado.
class AnalyticsService {
  AnalyticsService._();

  static AnalyticsSink _sink = const FirebaseAnalyticsSink();

  @visibleForTesting
  static set sink(AnalyticsSink value) => _sink = value;

  static const Map<String, Set<String>> _allowed = {
    'calc_completed': {'tipo_rescisao'},
    'share_used': {},
    'pdf_exported': {},
    'consent_decision': {'decisao'},
  };

  /// Chamado no boot: aplica a decisão persistida (desligada por padrão).
  static Future<void> initialize() async {
    final enabled = await ConsentService.hasAccepted();
    await _guard(() => _sink.setCollectionEnabled(enabled));
  }

  /// Registra a decisão: aceite liga a coleta; recusa a mantém desligada.
  static Future<void> recordConsent({required bool accepted}) async {
    await ConsentService.saveDecision(accepted: accepted);
    await _guard(() => _sink.setCollectionEnabled(accepted));
    await _emit('consent_decision', {'decisao': accepted ? 'aceitou' : 'recusou'});
  }

  static Future<void> calcCompleted(TerminationType type) => _emit('calc_completed', {'tipo_rescisao': type.name});

  static Future<void> shareUsed() => _emit('share_used', const {});

  static Future<void> pdfExported() => _emit('pdf_exported', const {});

  static Future<void> _emit(String name, Map<String, Object> parameters) async {
    final allowedParams = _allowed[name];
    if (allowedParams == null || !allowedParams.containsAll(parameters.keys)) return;
    if (!await ConsentService.hasAccepted()) return;
    await _guard(() => _sink.logEvent(name, parameters.isEmpty ? null : parameters));
  }

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Analytics nunca interrompe o fluxo do usuário.
    }
  }
}
