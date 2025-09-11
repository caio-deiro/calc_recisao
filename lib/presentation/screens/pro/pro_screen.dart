import 'package:flutter/material.dart';
import '../../../core/utils/pro_utils.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  bool _isPro = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkProStatus();
  }

  Future<void> _checkProStatus() async {
    final isPro = await ProUtils.isProUser();
    setState(() {
      _isPro = isPro;
    });
  }

  Future<void> _upgradeToPro() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ProUtils.upgradeToPro();

      if (success) {
        await _checkProStatus();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Upgrade para PRO realizado com sucesso!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Não foi possível realizar a compra. Tente novamente.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao fazer upgrade: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePro() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ProUtils.restorePro();
      await _checkProStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compra PRO restaurada com sucesso!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao restaurar compra: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Versão PRO'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPro) ...[_buildProActiveCard()] else ...[_buildUpgradeCard()],
            const SizedBox(height: 24),
            _buildFeaturesList(),
            const SizedBox(height: 24),
            _buildBenefitsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProActiveCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.verified, color: Colors.green.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Versão PRO Ativa',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Você está aproveitando todos os benefícios da versão PRO!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.star, color: Colors.blue.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Upgrade para PRO',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Remova anúncios e tenha acesso a recursos exclusivos',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blue.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _upgradeToPro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Fazer Upgrade - R\$ 4,90/mês'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assinatura mensal via Google Play',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _isLoading ? null : _restorePro, child: const Text('Restaurar Compra')),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recursos da Versão PRO',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.block, 'Sem Anúncios', 'Navegue sem interrupções', _isPro),
        _buildFeatureItem(Icons.picture_as_pdf, 'Exportação PDF', 'Gere relatórios em PDF', _isPro),
        _buildFeatureItem(Icons.history, 'Histórico Ilimitado', 'Salve todos os seus cálculos', _isPro),
        _buildFeatureItem(Icons.cloud_off, 'Modo Offline', 'Funcione sem internet', _isPro),
        _buildFeatureItem(Icons.support_agent, 'Suporte Prioritário', 'Atendimento preferencial', _isPro),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: isActive ? Colors.green.shade600 : Colors.grey.shade400, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey.shade600),
                ),
                Text(
                  description,
                  style: TextStyle(color: isActive ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isActive) Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por que escolher a Versão PRO?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Experiência sem anúncios para cálculos mais rápidos\n'
              '• Exportação de relatórios em PDF profissionais\n'
              '• Histórico ilimitado de todos os seus cálculos\n'
              '• Funcionamento offline completo\n'
              '• Suporte prioritário para dúvidas\n'
              '• Atualizações e novos recursos primeiro',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
