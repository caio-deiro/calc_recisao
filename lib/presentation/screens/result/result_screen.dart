import 'package:flutter/material.dart';
import '../../../domain/entities/termination_input.dart';
import '../../../domain/entities/termination_result.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../domain/entities/calculation_history.dart';
import '../../../domain/usecases/calculate_termination.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/share_utils.dart';
import '../../../core/ads/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../widgets/disclaimer_widget.dart';
import '../../widgets/breakdown_item_card.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.input, required this.terminationType});

  final TerminationInput input;
  final TerminationType terminationType;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  TerminationResult? _result;
  bool _isLoading = true;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResult();
      _loadBannerAd();
    });
  }

  void _loadResult() {
    setState(() {
      _isLoading = true;
    });

    // Simular cálculo (em produção, seria assíncrono)
    Future.delayed(const Duration(milliseconds: 500), () async {
      final useCase = const CalculateTerminationUseCase();
      final result = useCase.execute(widget.input, widget.terminationType);

      // Salvar no histórico
      try {
        final historyRepository = HistoryRepository();
        final calculationHistory = CalculationHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          input: widget.input,
          result: result,
          terminationType: widget.terminationType,
          timestamp: DateTime.now(),
        );
        await historyRepository.saveCalculation(calculationHistory);
      } catch (e) {
        // Log error but don't interrupt the user flow
        debugPrint('Erro ao salvar no histórico: $e');
      }

      setState(() {
        _result = result;
        _isLoading = false;
      });

      // Mostrar anúncio intersticial após o cálculo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AdManager.showInterstitialAd();
      });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager.createBannerAd();
    _bannerAd?.load();
  }

  Widget _buildBannerAd() {
    if (_bannerAd == null) return const SizedBox.shrink();

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Rescisão'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [if (_result != null) IconButton(icon: const Icon(Icons.share), onPressed: _shareResult)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
          ? const Center(child: Text('Erro ao calcular rescisão'))
          : _buildResultContent(),
    );
  }

  Widget _buildResultContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildBreakdownSection(),
                const SizedBox(height: 24),
                const DisclaimerWidget(),
              ],
            ),
          ),
        ),
        _buildBottomSection(),
        if (_bannerAd != null) _buildBannerAd(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo da Rescisão',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSummaryItem('Total a Receber', _result!.totalToReceive, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryItem('Total Descontos', _result!.totalDeductions, Colors.red)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Valor Líquido',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Formatters.formatCurrency(_result!.netAmount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          Formatters.formatCurrency(value),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhamento das Verbas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_result!.additions.isNotEmpty) ...[
          Text(
            'Adicionais',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._result!.additions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BreakdownItemCard(item: item),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_result!.deductions.isNotEmpty) ...[
          Text(
            'Descontos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._result!.deductions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BreakdownItemCard(item: item),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nova Rescisão')),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Refazer')),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResult() async {
    if (_result != null) {
      try {
        await ShareUtils.shareResult(input: widget.input, result: _result!, terminationType: widget.terminationType);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Resultado compartilhado com sucesso!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao compartilhar: $e')));
        }
      }
    }
  }
}
