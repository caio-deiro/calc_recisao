import 'package:flutter/material.dart';

import '../../widgets/ad_banner.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      bottomNavigationBar: const AdBanner(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculadora de Rescisão CLT',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Versão 1.0.0',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta aplicação foi desenvolvida para auxiliar no cálculo '
                      'estimativo de verbas rescisórias conforme a Consolidação '
                      'das Leis do Trabalho (CLT).',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Funcionalidades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFeatureItem(context, 'Cálculo de saldo de salário', 'Proporcional aos dias trabalhados no mês'),
            _buildFeatureItem(context, 'Aviso prévio indenizado', '30 dias + adicional por tempo de serviço'),
            _buildFeatureItem(context, '13º salário proporcional', 'Baseado nos meses trabalhados'),
            _buildFeatureItem(context, 'Férias vencidas e proporcionais', 'Incluindo 1/3 constitucional'),
            _buildFeatureItem(context, 'FGTS e multa de 40%', 'Quando aplicável'),
            _buildFeatureItem(context, 'Descontos INSS e IRRF', 'Cálculo aproximado das alíquotas'),
            const SizedBox(height: 24),
            const Text('Aviso Legal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Esta calculadora fornece estimativas com base em regras gerais da CLT. '
                'Situações específicas podem exigir outras verbas ou cálculos diferentes. '
                'Sempre consulte um profissional qualificado (contador ou advogado) '
                'antes de tomar decisões baseadas nestes cálculos.',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Política de Privacidade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Os cálculos são feitos no seu aparelho e o histórico fica só nele. '
              'Salário, datas, valores e resultados nunca são enviados. '
              'Se você aceitar, coletamos dados de uso anônimos (tipo de rescisão calculado, '
              'uso de compartilhar e de PDF, e sua decisão sobre este aviso) e relatórios de falha. '
              'Sem o seu aceite, nada disso é coletado. '
              'Os anúncios são do Google AdMob e não são personalizados até você aceitar.',
            ),
            const SizedBox(height: 24),
            const Text('Suporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text(
              'Para dúvidas, sugestões ou reportar problemas, '
              'entre em contato através dos canais oficiais da aplicação.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  description,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
