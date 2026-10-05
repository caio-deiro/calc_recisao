import 'package:flutter/material.dart';

/// Localizações da aplicação
/// 
/// Classe base para internacionalização
abstract class AppLocalizations {
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Títulos e navegação
  String get appTitle;
  String get homeTitle;
  String get formTitle;
  String get resultTitle;
  String get historyTitle;
  String get aboutTitle;
  String get supportTitle;

  // Formulário
  String get chooseTerminationType;
  String get basicInfo;
  String get admissionDate;
  String get terminationDate;
  String get remuneration;
  String get baseSalary;
  String get averageAdditions;
  String get workedDaysInMonth;
  String get options;
  String get hasAccruedVacation;
  String get noticeWorked;
  String get hasExistingFgts;
  String get existingFgtsAmount;
  String get dependents;
  String get otherDiscounts;
  String get calculateTaxes;
  String get calculateTermination;
  String get fieldRequired;

  // Resultado
  String get additions;
  String get deductions;
  String get totalToReceive;
  String get totalDeductions;
  String get netAmount;
  String get share;
  String get shareSimple;
  String get copy;
  String get copySimple;
  String get exportPdf;
  String get savePdf;

  // Histórico
  String get noHistory;
  String get clearHistory;
  String get clearHistoryConfirmation;
  String get deleteCalculation;

  // Mensagens
  String get loading;
  String get error;
  String get success;
  String get cancel;
  String get confirm;
  String get ok;
  String get close;

  // Erros
  String get errorProcessingData;
  String get invalidDateFormat;
  String get genericError;
  String get networkError;
  String get validationError;
}

