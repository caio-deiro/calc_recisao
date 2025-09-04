class Formatters {
  static String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  static DateTime parseDate(String dateString) {
    // Converte formato dd/mm/aaaa para DateTime
    final parts = dateString.split('/');
    if (parts.length != 3) {
      throw FormatException('Formato de data inválido. Use dd/mm/aaaa');
    }

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    return DateTime(year, month, day);
  }

  static String formatMonthYear(DateTime date) {
    final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final month = months[date.month - 1];
    final year = date.year.toString();
    return '$month/$year';
  }

  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }

  static String formatMonths(int months) {
    if (months == 1) return '1 mês';
    return '$months meses';
  }

  static String formatYears(int years) {
    if (years == 1) return '1 ano';
    return '$years anos';
  }
}
