import 'package:flutter/material.dart';
import 'app_localizations.dart';
import 'app_localizations_pt.dart';

/// Delegate para localizações da aplicação
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['pt', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Por enquanto, sempre retorna português
    // Futuramente, adicionar suporte a inglês
    switch (locale.languageCode) {
      case 'pt':
        return AppLocalizationsPt();
      case 'en':
        // TODO: Implementar AppLocalizationsEn
        return AppLocalizationsPt();
      default:
        return AppLocalizationsPt();
    }
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

