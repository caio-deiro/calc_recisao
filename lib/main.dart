import 'package:flutter/material.dart';
import 'app.dart';
import 'core/ads/ad_manager.dart';
import 'core/analytics/aso_analytics.dart';
import 'core/utils/pro_utils.dart';
import 'core/services/tax_tables_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar AdMob
  await AdManager.initialize();

  // Inicializar serviço de compras
  await ProUtils.initializePurchaseService();

  // Carregar tabelas fiscais
  await TaxTablesService.instance.loadTaxTables();

  // Inicializar analytics ASO
  await AsoAnalytics.initialize();

  runApp(const App());
}
