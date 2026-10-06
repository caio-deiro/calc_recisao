import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// Lê um número do JSON como texto (sem herdar imprecisão binária) para [Decimal].
Decimal _decimalOf(Object? value) => Decimal.parse(value.toString());

class TaxTable {
  final String description;
  final List<TaxRange> ranges;
  final Decimal? ceiling;

  TaxTable({required this.description, required this.ranges, this.ceiling});

  factory TaxTable.fromJson(Map<String, dynamic> json) {
    return TaxTable(
      description: json['description'] ?? '',
      ranges:
          (json['faixas'] as List<dynamic>?)
              ?.map((range) => TaxRange.fromJson(range))
              .toList() ??
          [],
      ceiling: json['teto'] != null ? _decimalOf(json['teto']) : null,
    );
  }
}

class TaxRange {
  final Decimal limite;
  final Decimal aliquota;
  final Decimal? deducao;
  final String descricao;

  TaxRange({
    required this.limite,
    required this.aliquota,
    this.deducao,
    required this.descricao,
  });

  factory TaxRange.fromJson(Map<String, dynamic> json) {
    return TaxRange(
      limite: _decimalOf(json['limite']),
      aliquota: _decimalOf(json['aliquota']),
      deducao: json['deducao'] != null ? _decimalOf(json['deducao']) : null,
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

  final Decimal exemptionLimit;
  final Decimal maxReduction;
  final Decimal gradualLimit;
  final Decimal formulaConstant;
  final Decimal formulaCoefficient;
}

class TerminationTaxResult {
  const TerminationTaxResult({
    required this.inssSalary,
    required this.inssThirteenth,
    required this.irrf,
  });

  /// INSS do saldo de salário (tabela e teto próprios).
  final Decimal inssSalary;

  /// INSS do 13º, apurado em separado (tabela e teto próprios).
  final Decimal inssThirteenth;
  final Decimal irrf;

  Decimal get inss => inssSalary + inssThirteenth;
}

/// Tabelas e fórmulas fiscais. Valores monetários e alíquotas são [Decimal] exatos
/// (só há soma, subtração e multiplicação aqui); o arredondamento a 2 casas por item
/// é feito pelo use case.
class TaxTablesService {
  static TaxTablesService? _instance;
  static TaxTablesService get instance => _instance ??= TaxTablesService._();

  TaxTablesService._();

  static final Decimal _zero = Decimal.zero;

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
      final String jsonString = await rootBundle.loadString(
        'assets/config/tax_tables.json',
      );
      _taxTablesData = json.decode(jsonString);
      if (_taxTablesData != null) {
        _inss2025 = TaxTable.fromJson(_taxTablesData!['inss_2025']);
        _inss2026 = TaxTable.fromJson(_taxTablesData!['inss_2026']);
        _irrf2025JanAbr = TaxTable.fromJson(
          _taxTablesData!['irrf_2025_jan_abr'],
        );
        _irrf2025MaiDez = TaxTable.fromJson(
          _taxTablesData!['irrf_2025_mai_dez'],
        );
        _irrf2026Mensal = TaxTable.fromJson(
          _taxTablesData!['irrf_2026_mensal'],
        );
        _irrfRedutor2026 =
            _taxTablesData!['irrf_redutor_2026'] as Map<String, dynamic>?;
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
      throw Exception(
        'Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.',
      );
    }
    return _inss2025!;
  }

  TaxTable get inss2026 {
    if (_inss2026 == null) {
      throw Exception(
        'Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.',
      );
    }
    return _inss2026!;
  }

  TaxTable getInssTable(DateTime referenceDate) {
    final year2026 = DateTime(2026, 1, 1);
    if (referenceDate.isAfter(year2026) ||
        referenceDate.isAtSameMomentAs(year2026)) {
      return inss2026;
    }
    return inss2025;
  }

  TaxTable getIrrfTable(DateTime terminationDate) {
    if (_irrf2025JanAbr == null ||
        _irrf2025MaiDez == null ||
        _irrf2026Mensal == null) {
      throw Exception(
        'Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.',
      );
    }
    final year2026 = DateTime(2026, 1, 1);
    if (terminationDate.isAfter(year2026) ||
        terminationDate.isAtSameMomentAs(year2026)) {
      return _irrf2026Mensal!;
    }
    final may2025 = DateTime(2025, 5, 1);
    if (terminationDate.isAfter(may2025) ||
        terminationDate.isAtSameMomentAs(may2025)) {
      return _irrf2025MaiDez!;
    }
    return _irrf2025JanAbr!;
  }

  bool usesIrrfReducer(DateTime terminationDate) {
    final year2026 = DateTime(2026, 1, 1);
    return terminationDate.isAfter(year2026) ||
        terminationDate.isAtSameMomentAs(year2026);
  }

  Decimal getDependentDeduction(DateTime terminationDate) {
    if (!usesIrrfReducer(terminationDate) || _irrfRedutor2026 == null) {
      return _zero;
    }
    return _decimalOf(_irrfRedutor2026!['deducao_dependente_mensal']);
  }

  Map<String, dynamic> get fgts {
    if (_fgts == null) {
      throw Exception(
        'Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.',
      );
    }
    return _fgts!;
  }

  Map<String, dynamic> get avisoPrevio {
    if (_avisoPrevio == null) {
      throw Exception(
        'Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.',
      );
    }
    return _avisoPrevio!;
  }

  Decimal calculateInss(Decimal baseValue, [DateTime? referenceDate]) {
    if (baseValue <= _zero) {
      return _zero;
    }
    final DateTime date = referenceDate ?? DateTime.now();
    return _calculateInssProgressive(baseValue, getInssTable(date));
  }

  Decimal _calculateInssProgressive(Decimal baseValue, TaxTable table) {
    final Decimal cappedBase =
        table.ceiling != null && baseValue > table.ceiling!
        ? table.ceiling!
        : baseValue;
    Decimal previousLimit = _zero;
    Decimal total = _zero;
    for (final TaxRange range in table.ranges) {
      if (cappedBase <= previousLimit) {
        break;
      }
      final Decimal bandWidth = range.limite - previousLimit;
      final Decimal taxableInBand = (cappedBase - previousLimit) < bandWidth
          ? (cappedBase - previousLimit)
          : bandWidth;
      total += taxableInBand * range.aliquota;
      previousLimit = range.limite;
    }
    return total;
  }

  /// IRRF mensal. [baseValue] é o rendimento já sem INSS; o redutor da Lei
  /// 15.270/2025 usa [grossIncome] (rendimento tributável bruto, antes de INSS
  /// e dependentes) e, se omitido, [baseValue]. ⚖️
  Decimal calculateIrrf(
    Decimal baseValue,
    DateTime terminationDate, {
    int dependents = 0,
    Decimal? grossIncome,
  }) {
    if (baseValue <= _zero) {
      return _zero;
    }
    final Decimal dependentDeduction =
        getDependentDeduction(terminationDate) * Decimal.fromInt(dependents);
    final Decimal taxableBase = baseValue - dependentDeduction;
    if (taxableBase <= _zero) {
      return _zero;
    }
    final Decimal grossIrrf = _calculateIrrfFromTable(
      taxableBase,
      getIrrfTable(terminationDate),
    );
    if (!usesIrrfReducer(terminationDate)) {
      return grossIrrf < _zero ? _zero : grossIrrf;
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
    required Decimal salaryBalance,
    required Decimal thirteenthSalary,
    required DateTime terminationDate,
    int dependents = 0,
  }) {
    final Decimal inssSalary = calculateInss(salaryBalance, terminationDate);
    final Decimal inssThirteenth = calculateInss(
      thirteenthSalary,
      terminationDate,
    );
    final Decimal salaryIrrf = calculateIrrf(
      salaryBalance - inssSalary,
      terminationDate,
      dependents: dependents,
      grossIncome: salaryBalance,
    );
    final Decimal thirteenthIrrf = calculateIrrf(
      thirteenthSalary - inssThirteenth,
      terminationDate,
      dependents: dependents,
      grossIncome: thirteenthSalary,
    );
    return TerminationTaxResult(
      inssSalary: inssSalary,
      inssThirteenth: inssThirteenth,
      irrf: salaryIrrf + thirteenthIrrf,
    );
  }

  Decimal _calculateIrrfFromTable(Decimal baseValue, TaxTable table) {
    for (final TaxRange range in table.ranges) {
      if (baseValue <= range.limite) {
        return _irrfInRange(baseValue, range);
      }
    }
    return _irrfInRange(baseValue, table.ranges.last);
  }

  Decimal _irrfInRange(Decimal baseValue, TaxRange range) {
    final Decimal tax = baseValue * range.aliquota;
    return range.deducao != null ? tax - range.deducao! : tax;
  }

  Decimal _applyMonthlyReducer(Decimal grossIrrf, Decimal grossIncome) {
    if (grossIrrf <= _zero) {
      return _zero;
    }
    final IrrfReducerConfig config = _getMonthlyReducerConfig();
    final Decimal reduction = _calculateReducerAmount(
      grossIncome,
      grossIrrf,
      config,
    );
    final Decimal netIrrf = grossIrrf - reduction;
    return netIrrf < _zero ? _zero : netIrrf;
  }

  Decimal _calculateReducerAmount(
    Decimal grossIncome,
    Decimal grossIrrf,
    IrrfReducerConfig config,
  ) {
    if (grossIncome <= config.exemptionLimit) {
      return grossIrrf < config.maxReduction ? grossIrrf : config.maxReduction;
    }
    if (grossIncome <= config.gradualLimit) {
      final Decimal formulaReduction =
          config.formulaConstant - (config.formulaCoefficient * grossIncome);
      final Decimal reduction = formulaReduction < grossIrrf
          ? formulaReduction
          : grossIrrf;
      return reduction < _zero ? _zero : reduction;
    }
    return _zero;
  }

  IrrfReducerConfig _getMonthlyReducerConfig() {
    final Map<String, dynamic> mensal =
        _irrfRedutor2026!['mensal'] as Map<String, dynamic>;
    return IrrfReducerConfig(
      exemptionLimit: _decimalOf(mensal['limite_isencao']),
      maxReduction: _decimalOf(mensal['reducao_maxima']),
      gradualLimit: _decimalOf(mensal['limite_reducao_gradual']),
      formulaConstant: _decimalOf(mensal['formula_constante']),
      formulaCoefficient: _decimalOf(mensal['formula_coeficiente']),
    );
  }

  Decimal getFgtsAliquota() {
    return _decimalOf(fgts['aliquota']);
  }

  Decimal getFgtsPenaltyAliquota() {
    return _decimalOf(fgts['multa_sem_justa_causa']);
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
