import 'package:flutter/material.dart';
import '../../../core/services/support_service.dart';
import '../../widgets/ad_banner.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suporte')),
      bottomNavigationBar: const AdBanner(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _buildSupportOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Canais de Suporte', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildSupportCard(
          icon: Icons.email,
          title: 'Enviar Email',
          description: 'Resposta em 3-5 dias úteis',
          onTap: () => SupportService.openSupportChannel(),
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.lightbulb,
          title: 'Sugerir Funcionalidade',
          description: 'Envie suas ideias para melhorias',
          onTap: () => SupportService.openFeatureRequest(),
        ),
        const SizedBox(height: 12),
        _buildSupportCard(
          icon: Icons.help_outline,
          title: 'Perguntas Frequentes',
          description: 'Encontre respostas rápidas',
          onTap: () => SupportService.openFaq(),
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  'suporte@calcrescisao.com',
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
                  'Resposta em 3-5 dias úteis',
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
