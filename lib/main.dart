import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/ads/ad_manager.dart';
import 'core/analytics/analytics_service.dart';
import 'core/services/legacy_cleanup.dart';
import 'core/services/tax_tables_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar serviços de forma paralela quando possível
    await Future.wait([
      LegacyCleanup.run(),
      _initFirebase(),
      AdManager.initialize(),
      TaxTablesService.instance.loadTaxTables(),
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

/// Firebase com coleta desligada por padrão (manifesto + boot); só liga após o
/// aceite do consentimento (B0-06, B1-12).
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    await AnalyticsService.initialize();
  } catch (e) {
    debugPrint('Firebase indisponível: $e');
  }
}
