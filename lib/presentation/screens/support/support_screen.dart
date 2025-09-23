import 'package:flutter/material.dart';
import '../../../core/services/support_service.dart';
import '../../../core/utils/pro_utils.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _isPro = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suporte'),
        backgroundColor: _isPro ? Colors.amber.shade700 : null,
        foregroundColor: _isPro ? Colors.white : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPro) _buildProBanner(),
            const SizedBox(height: 24),
            _buildSupportOptions(),
            const SizedBox(height: 24),
            _buildFaqSection(),
            const SizedBox(height: 24),
            _buildContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.amber.shade800]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suporte PRO Ativo',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Resposta em até ${SupportService.getSupportResponseTime()}',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Canais de Suporte', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSupportCard(
          icon: Icons.email,
          title: 'Enviar Email',
          description: _isPro ? 'Suporte prioritário - Resposta em 24h' : 'Suporte básico - Resposta em 3-5 dias',
          onTap: () => SupportService.openSupportChannel(),
          isPro: _isPro,
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.lightbulb,
          title: 'Sugerir Funcionalidade',
          description: _isPro ? 'Suas sugestões têm prioridade' : 'Envie suas ideias para melhorias',
          onTap: () => SupportService.openFeatureRequest(),
          isPro: _isPro,
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.help_outline,
          title: 'Perguntas Frequentes',
          description: 'Encontre respostas rápidas',
          onTap: () => SupportService.openFaq(),
          isPro: false,
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isPro,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: isPro ? Colors.amber.shade700 : Theme.of(context).primaryColor, size: 28),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: isPro ? Colors.amber.shade800 : null),
        ),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perguntas Frequentes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildFaqItem(
          'Como funciona o cálculo de rescisão?',
          'O app utiliza as tabelas oficiais do INSS e IRRF para calcular automaticamente todos os valores da rescisão.',
        ),
        _buildFaqItem(
          'Posso confiar nos cálculos?',
          'Sim! Utilizamos as tabelas oficiais atualizadas e seguimos a legislação trabalhista vigente.',
        ),
        _buildFaqItem(
          'O que inclui a versão PRO?',
          'Sem anúncios, exportação PDF, histórico ilimitado, modo offline e suporte prioritário.',
        ),
        _buildFaqItem(
          'Como cancelar a assinatura PRO?',
          'Acesse as configurações da Google Play Store > Assinaturas e cancele quando desejar.',
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações de Contato',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  _isPro ? 'pro@calcrescisao.com' : 'suporte@calcrescisao.com',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 20, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  _isPro ? 'Resposta em até 24 horas' : 'Resposta em 3-5 dias úteis',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
