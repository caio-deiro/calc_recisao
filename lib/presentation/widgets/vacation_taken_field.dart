import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Stepper "Períodos de férias já gozados", limitado a `[0, maxPeriods]`.
/// `maxPeriods` nulo (datas ainda inválidas) deixa o campo em 0 e desabilitado.
class VacationTakenField extends StatelessWidget {
  const VacationTakenField({super.key, required this.value, required this.maxPeriods, required this.onChanged});

  final int value;
  final int? maxPeriods;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n?.vacationPeriodsTaken ?? 'Períodos de férias já gozados';
    final max = maxPeriods;
    final enabled = max != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Row(
          children: [
            Semantics(
              identifier: 'form_vacation_taken_decrement',
              label: 'Diminuir períodos de férias gozados',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: enabled && value > 0 ? () => onChanged(value - 1) : null,
              ),
            ),
            Semantics(
              identifier: 'form_vacation_taken',
              label: '$label: $value',
              child: ExcludeSemantics(
                child: Text('$value', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            Semantics(
              identifier: 'form_vacation_taken_increment',
              label: 'Aumentar períodos de férias gozados',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: enabled && value < max ? () => onChanged(value + 1) : null,
              ),
            ),
          ],
        ),
        Semantics(
          identifier: 'form_vacation_warning',
          child: Text(
            l10n?.vacationPeriodsWarning ??
                'Férias fracionadas, abono pecuniário (venda de férias) e férias parcialmente gozadas não são tratados.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
