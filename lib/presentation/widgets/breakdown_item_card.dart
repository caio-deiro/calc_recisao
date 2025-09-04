import 'package:flutter/material.dart';
import '../../domain/entities/breakdown_item.dart';
import '../../core/utils/formatters.dart';

class BreakdownItemCard extends StatelessWidget {
  const BreakdownItemCard({super.key, required this.item});

  final BreakdownItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (item.details != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.details!,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: item.isAddition ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.isAddition ? Colors.green : Colors.red, width: 1),
              ),
              child: Text(
                '${item.isAddition ? '+' : '-'} ${Formatters.formatCurrency(item.value)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: item.isAddition ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
