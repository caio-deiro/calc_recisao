import 'package:flutter/material.dart';

class DisclaimerWidget extends StatelessWidget {
  const DisclaimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aviso Importante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Esta calculadora fornece estimativas com base em regras gerais da CLT. '
            'Situações específicas podem exigir outras verbas. '
            'Consulte um profissional (contador/advogado) antes de tomar decisões.',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
