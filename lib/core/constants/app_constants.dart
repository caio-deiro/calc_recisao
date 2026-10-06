// Constantes da aplicação
//
// Centraliza todos os valores configuráveis e magic numbers

class AppConstants {
  AppConstants._(); // Classe privada para evitar instanciação

  // Histórico
  static const int maxHistorySize = 100;
  static const int historyWarningThreshold = 90;

  // Anúncios
  static const Duration interstitialAdCooldown = Duration(minutes: 3);

  // Performance
  static const Duration calculationDelay = Duration(milliseconds: 500);
  static const Duration splashScreenDelay = Duration(seconds: 2);

  // Validação
  static const double maxSalary = 1000000.0; // R$ 1.000.000
  static const int maxDependents = 20;
  static const int maxWorkedDaysInMonth = 31;
  static const int maxYearsForAdmission = 100;

  // Datas
  static const int daysInFutureAllowed = 1; // Permite até 1 dia no futuro

  // Formatação
  static const int decimalPlaces = 2;
  static const String currencySymbol = 'R\$';
  static const String dateFormat = 'dd/MM/yyyy';

  // Mensagens de erro
  static const String genericErrorMessage =
      'Ocorreu um erro inesperado. Tente novamente.';
  static const String networkErrorMessage =
      'Erro de conexão. Verifique sua internet.';
  static const String validationErrorMessage =
      'Dados inválidos. Verifique os campos preenchidos.';

  // Suporte
  static const String supportEmail = 'caioguimaraes12@outlook.com';

  // URLs
  static const String privacyPolicyUrl =
      'https://caio-deiro.github.io/calc_recisao';
}
