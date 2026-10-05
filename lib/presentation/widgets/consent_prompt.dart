import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/analytics/consent_service.dart';

/// Passo do formulário de consentimento do Google (UMP). Substituível em testes.
@visibleForTesting
Future<void> Function() umpStep = _runUmp;

Future<void> _runUmp() async {
  try {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => done.complete(),
      (_) => done.complete(),
    );
    await done.future.timeout(const Duration(seconds: 10));
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
  } catch (_) {
    // Falha no UMP não impede o app; anúncios seguem não personalizados.
  }
}

/// Mostra, uma única vez, o consentimento (UMP + escolha de analytics).
/// Chamar ao voltar à Home depois do primeiro resultado.
Future<void> showConsentPromptIfNeeded(BuildContext context) async {
  if (!await ConsentService.shouldPrompt()) return;
  await umpStep();
  if (!context.mounted) return;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Ajude a melhorar o app'),
      content: const Text(
        'Podemos coletar dados de uso anônimos (como o tipo de rescisão calculado) '
        'e relatórios de falha. Nunca coletamos salário, datas ou valores. '
        'Aceitando, os anúncios também podem ser personalizados.',
      ),
      actions: [
        Semantics(
          identifier: 'consent_decline_button',
          child: TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Agora não')),
        ),
        Semantics(
          identifier: 'consent_accept_button',
          child: ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Aceitar')),
        ),
      ],
    ),
  );

  await AnalyticsService.recordConsent(accepted: accepted ?? false);
}
