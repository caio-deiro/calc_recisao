import 'package:flutter/material.dart';
import 'app.dart';
import 'core/ads/ad_manager.dart';
import 'core/utils/pro_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar AdMob
  await AdManager.initialize();

  // Inicializar serviço de compras
  await ProUtils.initializePurchaseService();

  runApp(const App());
}
