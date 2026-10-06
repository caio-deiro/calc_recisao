import 'dart:convert';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class TaxTable {
  final String description;
  final List<TaxRange> ranges;
  final double? ceiling;

  TaxTable({required this.description, required this.ranges, this.ceiling});

  factory TaxTable.fromJson(Map<String, dynamic> json) {
    return TaxTable(
      description: json['description'] ?? '',
      ranges: (json['faixas'] as List<dynamic>?)?.map((range) => TaxRange.fromJson(range)).toList() ?? [],
      ceiling: json['teto'] != null ? (json['teto'] as num).toDouble() : null,
    );
  }
}

class TaxRange {
  final double limite;
  final double aliquota;
  final double? deducao;
  final String descricao;

  TaxRange({required this.limite, required this.aliquota, this.deducao, required this.descricao});

  factory TaxRange.fromJson(Map<String, dynamic> json) {
    return TaxRange(
      limite: (json['limite'] as num).toDouble(),
      aliquota: (json['aliquota'] as num).toDouble(),
      deducao: json['deducao'] != null ? (json['deducao'] as num).toDouble() : null,
      descricao: json['descricao'] ?? '',
    );
  }
}

class IrrfReducerConfig {
  const IrrfReducerConfig({
    required this.exemptionLimit,
    required this.maxReduction,
    required this.gradualLimit,
    required this.formulaConstant,
    required this.formulaCoefficient,
  });

  final double exemptionLimit;
  final double maxReduction;
  final double gradualLimit;
  final double formulaConstant;
  final double formulaCoefficient;
}

class TerminationTaxResult {
  const TerminationTaxResult({required this.inssSalary, required this.inssThirteenth, required this.irrf});

  /// INSS do saldo de salário (tabela e teto próprios).
  final double inssSalary;

  /// INSS do 13º, apurado em separado (tabela e teto próprios).
  final double inssThirteenth;
  final double irrf;

  double get inss => inssSalary + inssThirteenth;
}

class TaxTablesService {
  static TaxTablesService? _instance;
  static TaxTablesService get instance => _instance ??= TaxTablesService._();

  TaxTablesService._();

  Map<String, dynamic>? _taxTablesData;
  TaxTable? _inss2025;
  TaxTable? _inss2026;
  TaxTable? _irrf2025JanAbr;
  TaxTable? _irrf2025MaiDez;
  TaxTable? _irrf2026Mensal;
  Map<String, dynamic>? _irrfRedutor2026;
  Map<String, dynamic>? _fgts;
  Map<String, dynamic>? _avisoPrevio;

  Future<void> loadTaxTables() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config/tax_tables.json');
      _taxTablesData = json.decode(jsonString);
      if (_taxTablesData != null) {
        _inss2025 = TaxTable.fromJson(_taxTablesData!['inss_2025']);
        _inss2026 = TaxTable.fromJson(_taxTablesData!['inss_2026']);
        _irrf2025JanAbr = TaxTable.fromJson(_taxTablesData!['irrf_2025_jan_abr']);
        _irrf2025MaiDez = TaxTable.fromJson(_taxTablesData!['irrf_2025_mai_dez']);
        _irrf2026Mensal = TaxTable.fromJson(_taxTablesData!['irrf_2026_mensal']);
        _irrfRedutor2026 = _taxTablesData!['irrf_redutor_2026'] as Map<String, dynamic>?;
        _fgts = _taxTablesData!['fgts'];
        _avisoPrevio = _taxTablesData!['aviso_previo'];
      }
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar tabelas fiscais', e, stackTrace);
      throw Exception('Erro ao carregar tabelas fiscais: $e');
    }
  }

  TaxTable get inss2025 {
    if (_inss2025 == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    return _inss2025!;
  }

  TaxTable get inss2026 {
    if (_inss2026 == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    return _inss2026!;
  }

  TaxTable getInssTable(DateTime referenceDate) {
    final year2026 = DateTime(2026, 1, 1);
    if (referenceDate.isAfter(year2026) || referenceDate.isAtSameMomentAs(year2026)) {
      return inss2026;
    }
    return inss2025;
  }

  TaxTable getIrrfTable(DateTime terminationDate) {
    if (_irrf2025JanAbr == null || _irrf2025MaiDez == null || _irrf2026Mensal == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    final year2026 = DateTime(2026, 1, 1);
    if (terminationDate.isAfter(year2026) || terminationDate.isAtSameMomentAs(year2026)) {
      return _irrf2026Mensal!;
    }
    final may2025 = DateTime(2025, 5, 1);
    if (terminationDate.isAfter(may2025) || terminationDate.isAtSameMomentAs(may2025)) {
      return _irrf2025MaiDez!;
    }
    return _irrf2025JanAbr!;
  }

  bool usesIrrfReducer(DateTime terminationDate) {
    final year2026 = DateTime(2026, 1, 1);
    return terminationDate.isAfter(year2026) || terminationDate.isAtSameMomentAs(year2026);
  }

  double getDependentDeduction(DateTime terminationDate) {
    if (!usesIrrfReducer(terminationDate) || _irrfRedutor2026 == null) {
      return 0.0;
    }
    return (_irrfRedutor2026!['deducao_dependente_mensal'] as num).toDouble();
  }

  Map<String, dynamic> get fgts {
    if (_fgts == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    return _fgts!;
  }

  Map<String, dynamic> get avisoPrevio {
    if (_avisoPrevio == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    return _avisoPrevio!;
  }

  double calculateInss(double baseValue, [DateTime? referenceDate]) {
    if (baseValue <= 0) {
      return 0.0;
    }
    final DateTime date = referenceDate ?? DateTime.now();
    return _calculateInssProgressive(baseValue, getInssTable(date));
  }

  double _calculateInssProgressive(double baseValue, TaxTable table) {
    final double cappedBase = table.ceiling != null && baseValue > table.ceiling! ? table.ceiling! : baseValue;
    double previousLimit = 0.0;
    double total = 0.0;
    for (final TaxRange range in table.ranges) {
      if (cappedBase <= previousLimit) {
        break;
      }
      final double bandWidth = range.limite - previousLimit;
      final double taxableInBand = (cappedBase - previousLimit) < bandWidth ? (cappedBase - previousLimit) : bandWidth;
      total += taxableInBand * range.aliquota;
      previousLimit = range.limite;
    }
    return total;
  }

  /// IRRF mensal. [baseValue] é o rendimento já sem INSS; o redutor da Lei
  /// 15.270/2025 usa [grossIncome] (rendimento tributável bruto, antes de INSS
  /// e dependentes) e, se omitido, [baseValue]. ⚖️
  double calculateIrrf(double baseValue, DateTime terminationDate, {int dependents = 0, double? grossIncome}) {
    if (baseValue <= 0) {
      return 0.0;
    }
    final double dependentDeduction = getDependentDeduction(terminationDate) * dependents;
    final double taxableBase = baseValue - dependentDeduction;
    if (taxableBase <= 0) {
      return 0.0;
    }
    final double grossIrrf = _calculateIrrfFromTable(taxableBase, getIrrfTable(terminationDate));
    if (!usesIrrfReducer(terminationDate)) {
      return grossIrrf < 0 ? 0.0 : grossIrrf;
    }
    return _applyMonthlyReducer(grossIrrf, grossIncome ?? baseValue);
  }

  /// Apura INSS e IRRF da rescisão.
  ///
  /// C5: INSS do saldo e do 13º em bases independentes, cada uma com a tabela
  /// progressiva e o teto próprios (Decreto 3.048/99 art. 214 §6º e §7º). O IRRF
  /// do saldo deduz o INSS do saldo e o do 13º deduz o INSS do 13º, ambos pela
  /// tabela MENSAL (13º tributado em separado: Lei 7.713/88 art. 26). O redutor
  /// usa o rendimento bruto de cada pagamento (Lei 15.270/2025).
  /// C4: férias (vencidas ou proporcionais) ficam fora das duas bases
  /// (Decreto 3.048/99 art. 214 §9º IV; Súmulas 125 e 386 STJ, AD PGFN 14/2008). ⚖️
  TerminationTaxResult calculateTerminationTaxes({
    required double salaryBalance,
    required double thirteenthSalary,
    required DateTime terminationDate,
    int dependents = 0,
  }) {
    final double inssSalary = calculateInss(salaryBalance, terminationDate);
    final double inssThirteenth = calculateInss(thirteenthSalary, terminationDate);
    final double salaryIrrf = calculateIrrf(
      salaryBalance - inssSalary,
      terminationDate,
      dependents: dependents,
      grossIncome: salaryBalance,
    );
    final double thirteenthIrrf = calculateIrrf(
      thirteenthSalary - inssThirteenth,
      terminationDate,
      dependents: dependents,
      grossIncome: thirteenthSalary,
    );
    return TerminationTaxResult(inssSalary: inssSalary, inssThirteenth: inssThirteenth, irrf: salaryIrrf + thirteenthIrrf);
  }

  double _calculateIrrfFromTable(double baseValue, TaxTable table) {
    for (final TaxRange range in table.ranges) {
      if (baseValue <= range.limite) {
        if (range.deducao != null) {
          return (baseValue * range.aliquota) - range.deducao!;
        }
        return baseValue * range.aliquota;
      }
    }
    final TaxRange lastRange = table.ranges.last;
    if (lastRange.deducao != null) {
      return (baseValue * lastRange.aliquota) - lastRange.deducao!;
    }
    return baseValue * lastRange.aliquota;
  }

  double _applyMonthlyReducer(double grossIrrf, double grossIncome) {
    if (grossIrrf <= 0) {
      return 0.0;
    }
    final IrrfReducerConfig config = _getMonthlyReducerConfig();
    final double reduction = _calculateReducerAmount(grossIncome, grossIrrf, config);
    final double netIrrf = grossIrrf - reduction;
    return netIrrf < 0 ? 0.0 : netIrrf;
  }

  double _calculateReducerAmount(double grossIncome, double grossIrrf, IrrfReducerConfig config) {
    if (grossIncome <= config.exemptionLimit) {
      return grossIrrf < config.maxReduction ? grossIrrf : config.maxReduction;
    }
    if (grossIncome <= config.gradualLimit) {
      final double formulaReduction = config.formulaConstant - (config.formulaCoefficient * grossIncome);
      final double reduction = formulaReduction < grossIrrf ? formulaReduction : grossIrrf;
      return reduction < 0 ? 0.0 : reduction;
    }
    return 0.0;
  }

  IrrfReducerConfig _getMonthlyReducerConfig() {
    final Map<String, dynamic> mensal = _irrfRedutor2026!['mensal'] as Map<String, dynamic>;
    return IrrfReducerConfig(
      exemptionLimit: (mensal['limite_isencao'] as num).toDouble(),
      maxReduction: (mensal['reducao_maxima'] as num).toDouble(),
      gradualLimit: (mensal['limite_reducao_gradual'] as num).toDouble(),
      formulaConstant: (mensal['formula_constante'] as num).toDouble(),
      formulaCoefficient: (mensal['formula_coeficiente'] as num).toDouble(),
    );
  }

  double getFgtsAliquota() {
    return (fgts['aliquota'] as num).toDouble();
  }

  double getFgtsPenaltyAliquota() {
    return (fgts['multa_sem_justa_causa'] as num).toDouble();
  }

  int getAvisoPrevioBaseDays() {
    return avisoPrevio['dias_base'] as int;
  }

  int getAvisoPrevioDaysPerYear() {
    return avisoPrevio['dias_por_ano'] as int;
  }

  int getAvisoPrevioMaxDays() {
    return avisoPrevio['maximo_dias'] as int;
  }
}
