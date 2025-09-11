import 'package:flutter/material.dart';
import '../../../domain/entities/termination_input.dart';
import '../../../domain/entities/termination_result.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../domain/entities/calculation_history.dart';
import '../../../domain/usecases/calculate_termination.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/share_utils.dart';
import '../../../core/utils/pro_utils.dart';
import '../../../core/ads/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../widgets/disclaimer_widget.dart';
import '../../widgets/breakdown_item_card.dart';
import '../pro/pro_screen.dart';

enum ShareAction { share, shareSimple, copy, copySimple, exportPdf, savePdf }

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

  Future<void> _loadBannerAd() async {
    _bannerAd = await AdManager.createBannerAd();
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
    if (_result == null) return;

    // Mostrar menu de opções de compartilhamento
    final action = await _showShareOptions();
    if (action == null) return;

    try {
      switch (action) {
        case ShareAction.share:
          await ShareUtils.shareResult(input: widget.input, result: _result!, terminationType: widget.terminationType);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Resultado compartilhado com sucesso!')));
          }
          break;
        case ShareAction.shareSimple:
          await ShareUtils.shareResult(
            input: widget.input,
            result: _result!,
            terminationType: widget.terminationType,
            simple: true,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Resultado compartilhado com sucesso!')));
          }
          break;
        case ShareAction.copy:
          await ShareUtils.copyResultToClipboard(
            input: widget.input,
            result: _result!,
            terminationType: widget.terminationType,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Resultado copiado para área de transferência!')));
          }
          break;
        case ShareAction.copySimple:
          await ShareUtils.copyResultToClipboard(
            input: widget.input,
            result: _result!,
            terminationType: widget.terminationType,
            simple: true,
          );
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Resultado copiado para área de transferência!')));
          }
          break;
        case ShareAction.exportPdf:
          await ShareUtils.exportToPdf(input: widget.input, result: _result!, terminationType: widget.terminationType);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('PDF gerado e compartilhado com sucesso!')));
          }
          break;
        case ShareAction.savePdf:
          await ShareUtils.savePdfToFile(
            input: widget.input,
            result: _result!,
            terminationType: widget.terminationType,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF salvo com sucesso!')));
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<ShareAction?> _showShareOptions() async {
    final canExportPdf = await ProUtils.canExportPdf();

    if (!mounted) return null;

    return await showModalBottomSheet<ShareAction>(
      context: context,
      builder: (context) {
        if (!mounted) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Compartilhar Resultado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Compartilhar Completo'),
                  subtitle: const Text('Compartilha todos os detalhes'),
                  onTap: () => Navigator.pop(context, ShareAction.share),
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Compartilhar Resumido'),
                  subtitle: const Text('Compartilha apenas o resumo'),
                  onTap: () => Navigator.pop(context, ShareAction.shareSimple),
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copiar Completo'),
                  subtitle: const Text('Copia todos os detalhes'),
                  onTap: () => Navigator.pop(context, ShareAction.copy),
                ),
                ListTile(
                  leading: const Icon(Icons.copy_outlined),
                  title: const Text('Copiar Resumido'),
                  subtitle: const Text('Copia apenas o resumo'),
                  onTap: () => Navigator.pop(context, ShareAction.copySimple),
                ),
                if (canExportPdf) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Exportar PDF'),
                    subtitle: const Text('Gera e compartilha PDF'),
                    onTap: () => Navigator.pop(context, ShareAction.exportPdf),
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt),
                    title: const Text('Salvar PDF'),
                    subtitle: const Text('Salva PDF no dispositivo'),
                    onTap: () => Navigator.pop(context, ShareAction.savePdf),
                  ),
                ] else ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.grey),
                    title: const Text('Exportar PDF'),
                    subtitle: const Text('Recurso PRO - Faça upgrade'),
                    onTap: () {
                      Navigator.pop(context);
                      _showProUpgradeDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.save_alt, color: Colors.grey),
                    title: const Text('Salvar PDF'),
                    subtitle: const Text('Recurso PRO - Faça upgrade'),
                    onTap: () {
                      Navigator.pop(context);
                      _showProUpgradeDialog();
                    },
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recurso PRO'),
        content: const Text(
          'A exportação PDF é um recurso exclusivo da versão PRO. Faça upgrade para acessar esta funcionalidade.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProScreen()));
            },
            child: const Text('Fazer Upgrade'),
          ),
        ],
      ),
    );
  }
}
