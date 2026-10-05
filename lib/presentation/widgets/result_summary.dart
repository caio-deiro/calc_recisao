import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/assumption.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_pt.dart';

AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(context) ?? AppLocalizationsPt();

/// Marcador "estimado" ao lado de valor aproximado por premissa (B5-02).
class EstimatedMarker extends StatelessWidget {
  const EstimatedMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: 'result_estimated_marker',
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
        child: Text(_l10n(context).estimatedMarker, style: TextStyle(fontSize: 11, color: scheme.onSecondaryContainer)),
      ),
    );
  }
}

/// Aviso "cálculo em validação", visível sem expandir as premissas (B6-04).
class ValidationNotice extends StatelessWidget {
  const ValidationNotice({super.key, required this.assumptions});

  final List<Assumption> assumptions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: 'result_validation_notice',
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final a in assumptions) Text(a.text, style: TextStyle(color: scheme.onTertiaryContainer))],
        ),
      ),
    );
  }
}

/// Cartão com os dois totais: "Pago na rescisão" e "Depositado no FGTS" (B5-01).
class ResultTotalsCard extends StatelessWidget {
  const ResultTotalsCard({
    super.key,
    required this.paidAtTermination,
    required this.fgtsTotal,
    required this.fgtsEstimated,
    this.withdrawalPercent,
  });

  final double paidAtTermination;
  final double fgtsTotal;
  final bool fgtsEstimated;

  /// Percentual de saque do FGTS (`TerminationRules.fgtsWithdrawalPercent`); nulo = sem linha.
  final int? withdrawalPercent;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              identifier: 'result_paid_total',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.paidAtTermination,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.formatCurrency(paidAtTermination),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'result_fgts_total',
              child: Row(
                children: [
                  Expanded(child: Text(l10n.fgtsDeposit, style: theme.textTheme.titleMedium)),
                  if (fgtsEstimated) const EstimatedMarker(),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.formatCurrency(fgtsTotal),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (withdrawalPercent != null)
              Semantics(
                identifier: 'result_fgts_withdrawal_info',
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.fgtsWithdrawalInfo(withdrawalPercent!),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Seção recolhível "Premissas desta estimativa", fechada por padrão (B5-02).
class AssumptionsSection extends StatelessWidget {
  const AssumptionsSection({super.key, required this.assumptions});

  final List<Assumption> assumptions;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    return Card(
      child: Semantics(
        identifier: 'result_assumptions_toggle',
        child: ExpansionTile(
          initiallyExpanded: false,
          title: Text(l10n.assumptionsTitle),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in assumptions)
              Semantics(
                identifier: 'result_assumption_${a.code.name}',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${a.text} (${a.origin == AssumptionOrigin.informed ? l10n.assumptionInformed : l10n.assumptionEstimated})',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Valor salvo de um registro legado, com a marca "Calculado em versão anterior".
class LegacyResultCard extends StatelessWidget {
  const LegacyResultCard({super.key, required this.legacyNetAmount});

  final double legacyNetAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(l10n.legacyValueLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(legacyNetAmount),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              identifier: 'result_legacy_mark',
              child: Text(l10n.legacyMark, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
