import 'package:flutter/material.dart';
import 'app.dart';
import 'core/ads/ad_manager.dart';
import 'core/analytics/aso_analytics.dart';
import 'core/utils/pro_utils.dart';
import 'core/services/tax_tables_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar serviços de forma paralela quando possível
    await Future.wait([
      AdManager.initialize(),
      ProUtils.initializePurchaseService(),
      TaxTablesService.instance.loadTaxTables(),
      AsoAnalytics.initialize(),
    ], eagerError: false); // Não falhar se um serviço falhar
  } catch (e) {
    // Log do erro mas continua a inicialização
    debugPrint('Erro na inicialização de serviços: $e');
    // Tenta carregar tabelas fiscais mesmo se outros serviços falharem
    try {
      await TaxTablesService.instance.loadTaxTables();
    } catch (_) {
      // Se tabelas fiscais falharem, app não pode funcionar
      debugPrint('Erro crítico: não foi possível carregar tabelas fiscais');
    }
  }

  runApp(const App());
}
