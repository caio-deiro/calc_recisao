import 'package:flutter/material.dart';
import '../../../domain/entities/breakdown_item.dart';
import '../../../domain/entities/termination_input.dart';
import '../../../domain/entities/termination_result.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../domain/entities/calculation_history.dart';
import '../../../domain/usecases/calculate_termination.dart';
import '../../../data/repositories/history_repository.dart';
import '../../../core/utils/share_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/ads/ad_manager.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/analytics/consent_service.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/disclaimer_widget.dart';
import '../../widgets/breakdown_item_card.dart';
import '../../widgets/result_summary.dart';
import '../../../domain/entities/assumption.dart';
import '../../../domain/rules/termination_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_pt.dart';

enum ShareAction { share, shareSimple, copy, copySimple, exportPdf, savePdf }

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.input, required this.terminationType}) : history = null;

  /// Abre o resultado **salvo** de um registro do histórico: não recalcula, não grava
  /// histórico, não pede consentimento e não emite evento (B5-06, B0-03).
  ResultScreen.fromHistory(CalculationHistory this.history, {super.key})
    : input = history.input,
      terminationType = history.terminationType;

  final TerminationInput input;
  final TerminationType terminationType;
  final CalculationHistory? history;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  TerminationResult? _result;
  bool _isLoading = true;

  bool get _isLegacy => widget.history?.isLegacy ?? false;

  @override
  void initState() {
    super.initState();
    final saved = widget.history;
    if (saved != null) {
      _result = saved.result;
      _isLoading = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResult();
    });
  }

  void _loadResult() {
    setState(() {
      _isLoading = true;
    });

    // Calcular de forma assíncrona
    Future.delayed(AppConstants.calculationDelay, () async {
      try {
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
        } catch (e, stackTrace) {
          // Log error but don't interrupt the user flow
          AppLogger.warning('Erro ao salvar no histórico', e, stackTrace);
        }

        if (!mounted) return;
        setState(() {
          _result = result;
          _isLoading = false;
        });

        await ConsentService.markFirstResult();
        await AnalyticsService.calcCompleted(widget.terminationType);
      } catch (e, stackTrace) {
        AppLogger.error('Erro ao calcular rescisão', e, stackTrace);
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e is AppException ? e.message : 'Erro ao calcular rescisão. Tente novamente.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // Intersticial só ao sair do Resultado, nunca ao entrar (B1-10b).
        if (didPop) AdManager.showInterstitialOnExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultado da Rescisão'),
          leading: Semantics(
            identifier: 'result_back_button',
            child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          ),
          actions: [
            if (_result != null && !_isLegacy)
              Semantics(
                identifier: 'result_share_button',
                child: IconButton(icon: const Icon(Icons.share), onPressed: _shareResult),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _result == null
            ? const Center(child: Text('Erro ao calcular rescisão'))
            : _buildResultContent(),
        bottomNavigationBar: const AdBanner(),
      ),
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
                ..._buildSummary(),
                const SizedBox(height: 24),
                _buildBreakdownSection(),
                const SizedBox(height: 24),
                const DisclaimerWidget(),
              ],
            ),
          ),
        ),
        _buildBottomSection(),
      ],
    );
  }

  /// Registro legado: só o valor salvo e a marca. Resultado atual: aviso de validação,
  /// os dois totais e as premissas (fechadas por padrão).
  List<Widget> _buildSummary() {
    final result = _result!;
    if (_isLegacy) {
      return [LegacyResultCard(legacyNetAmount: widget.history!.legacyNetAmount ?? 0)];
    }
    final validation = result.assumptions.where((a) => a.code == AssumptionCode.validationPending).toList();
    return [
      if (validation.isNotEmpty) ValidationNotice(assumptions: validation),
      ResultTotalsCard(
        paidAtTermination: result.paidAtTermination,
        fgtsTotal: result.fgtsDeposit.total,
        fgtsEstimated: _fgtsEstimated,
        withdrawalPercent: TerminationRules.of(widget.terminationType).fgtsWithdrawalPercent,
      ),
      if (result.assumptions.isNotEmpty) ...[
        const SizedBox(height: 16),
        AssumptionsSection(assumptions: result.assumptions),
      ],
    ];
  }

  /// O marcador "estimado" só vale para o FGTS aproximado por premissa.
  bool get _fgtsEstimated =>
      _result!.assumptions.any((a) => a.code == AssumptionCode.fgtsBalance && a.origin == AssumptionOrigin.estimated);

  Widget _buildBreakdownSection() {
    final result = _result!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalhamento das Verbas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (result.additions.isNotEmpty) _buildItemGroup('Verbas pagas na rescisão', Colors.green, result.additions),
        if (result.deductions.isNotEmpty) _buildItemGroup('Descontos', Colors.red, result.deductions),
        if (result.fgtsDeposit.items.isNotEmpty)
          _buildItemGroup(
            _l10n.fgtsDeposit,
            Theme.of(context).colorScheme.primary,
            result.fgtsDeposit.items,
            estimated: _fgtsEstimated,
          ),
      ],
    );
  }

  AppLocalizations get _l10n => AppLocalizations.of(context) ?? AppLocalizationsPt();

  Widget _buildItemGroup(String title, Color color, List<BreakdownItem> items, {bool estimated = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              if (estimated) const EstimatedMarker(),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BreakdownItemCard(item: item),
            ),
          ),
        ],
      ),
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
          _afterShareOrExport(pdf: false);
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
          _afterShareOrExport(pdf: false);
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
          _afterShareOrExport(pdf: true);
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
          _afterShareOrExport(pdf: true);
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

  /// Evento de analytics (só se houver consentimento) e intersticial ao concluir.
  void _afterShareOrExport({required bool pdf}) {
    if (pdf) {
      AnalyticsService.pdfExported();
    } else {
      AnalyticsService.shareUsed();
    }
    AdManager.showInterstitialOnExit();
  }

  Future<ShareAction?> _showShareOptions() async {
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
                const Divider(),
                Semantics(
                  identifier: 'share_export_pdf',
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: const Text('Exportar PDF'),
                    subtitle: const Text('Gera e compartilha PDF'),
                    onTap: () => Navigator.pop(context, ShareAction.exportPdf),
                  ),
                ),
                Semantics(
                  identifier: 'share_save_pdf',
                  child: ListTile(
                    leading: const Icon(Icons.save_alt),
                    title: const Text('Salvar PDF'),
                    subtitle: const Text('Salva PDF no dispositivo'),
                    onTap: () => Navigator.pop(context, ShareAction.savePdf),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ],
            ),
          ),
        );
      },
    );
  }
}
