import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../domain/entities/calculation_history.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/disclaimer_widget.dart';
import '../result/result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CalculationHistory> _history = [];
  int _unreadableCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final repository = HistoryRepository();
      _history = await repository.getHistory();
      _unreadableCount = await repository.unreadableCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar histórico: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Cálculos'),
        actions: [
          if (_history.isNotEmpty) IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _showClearHistoryDialog),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty && _unreadableCount == 0
          ? _buildEmptyState()
          : _buildHistoryList(),
      bottomNavigationBar: const AdBanner(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Nenhum cálculo encontrado', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Os cálculos realizados aparecerão aqui',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        if (_unreadableCount > 0) _buildUnreadableNotice(),
        if (_history.length >= AppConstants.historyWarningThreshold) _buildHistoryLimitNotice(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _history.length,
            itemBuilder: (context, index) {
              final calculation = _history[index];
              return _buildHistoryCard(calculation);
            },
          ),
        ),
        const DisclaimerWidget(),
      ],
    );
  }

  Widget _buildUnreadableNotice() {
    return Semantics(
      identifier: 'history_unreadable_notice',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          _unreadableCount == 1
              ? '1 registro não pôde ser lido e foi mantido no aparelho.'
              : '$_unreadableCount registros não puderam ser lidos e foram mantidos no aparelho.',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildHistoryLimitNotice() {
    return Semantics(
      identifier: 'history_limit_notice',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Text(
          'Histórico quase cheio: guardamos os ${AppConstants.maxHistorySize} cálculos mais recentes. '
          'Os mais antigos são apagados automaticamente.',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(CalculationHistory calculation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewCalculation(calculation),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          calculation.terminationType.label,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.formatDate(calculation.timestamp),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        if (calculation.isLegacy)
                          Text(
                            'Calculado em versão anterior',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.formatCurrency(calculation.result.netAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Salário: ${Formatters.formatCurrency(calculation.input.baseSalary)}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
              if (calculation.note != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    calculation.note!,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _viewCalculation(CalculationHistory calculation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResultScreen(input: calculation.input, terminationType: calculation.terminationType),
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Histórico'),
        content: const Text(
          'Tem certeza que deseja apagar todo o histórico de cálculos? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    try {
      final repository = HistoryRepository();
      await repository.clearHistory();

      setState(() {
        _history = [];
        _unreadableCount = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Histórico limpo com sucesso')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao limpar histórico: $e')));
      }
    }
  }
}
