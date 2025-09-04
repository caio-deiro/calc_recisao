import 'package:flutter/material.dart';
import 'app.dart';
import 'core/ads/ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.initialize();
  runApp(const App());
}
