import 'dart:convert';
import 'package:flutter/services.dart';

class TaxTable {
  final String description;
  final List<TaxRange> ranges;

  TaxTable({required this.description, required this.ranges});

  factory TaxTable.fromJson(Map<String, dynamic> json) {
    return TaxTable(
      description: json['description'] ?? '',
      ranges: (json['faixas'] as List<dynamic>?)?.map((range) => TaxRange.fromJson(range)).toList() ?? [],
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

class TaxTablesService {
  static TaxTablesService? _instance;
  static TaxTablesService get instance => _instance ??= TaxTablesService._();

  TaxTablesService._();

  Map<String, dynamic>? _taxTablesData;
  TaxTable? _inss2025;
  TaxTable? _irrf2025JanAbr;
  TaxTable? _irrf2025MaiDez;
  Map<String, dynamic>? _fgts;
  Map<String, dynamic>? _avisoPrevio;

  Future<void> loadTaxTables() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/config/tax_tables.json');
      _taxTablesData = json.decode(jsonString);

      // Carregar tabelas específicas
      if (_taxTablesData != null) {
        _inss2025 = TaxTable.fromJson(_taxTablesData!['inss_2025']);
        _irrf2025JanAbr = TaxTable.fromJson(_taxTablesData!['irrf_2025_jan_abr']);
        _irrf2025MaiDez = TaxTable.fromJson(_taxTablesData!['irrf_2025_mai_dez']);
        _fgts = _taxTablesData!['fgts'];
        _avisoPrevio = _taxTablesData!['aviso_previo'];
      }
    } catch (e) {
      throw Exception('Erro ao carregar tabelas fiscais: $e');
    }
  }

  TaxTable get inss2025 {
    if (_inss2025 == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }
    return _inss2025!;
  }

  TaxTable getIrrfTable(DateTime terminationDate) {
    if (_irrf2025JanAbr == null || _irrf2025MaiDez == null) {
      throw Exception('Tabelas fiscais não foram carregadas. Chame loadTaxTables() primeiro.');
    }

    // A partir de maio de 2025, usar a nova tabela
    final may2025 = DateTime(2025, 5, 1);

    if (terminationDate.isAfter(may2025) || terminationDate.isAtSameMomentAs(may2025)) {
      return _irrf2025MaiDez!;
    } else {
      return _irrf2025JanAbr!;
    }
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

  double calculateInss(double baseValue) {
    final table = inss2025;

    for (final range in table.ranges) {
      if (baseValue <= range.limite) {
        return baseValue * range.aliquota;
      }
    }

    // Se não encontrou faixa, aplicar alíquota apenas sobre o teto
    final lastRange = table.ranges.last;
    return lastRange.limite * lastRange.aliquota;
  }

  double calculateIrrf(double baseValue, DateTime terminationDate) {
    final table = getIrrfTable(terminationDate);

    for (final range in table.ranges) {
      if (baseValue <= range.limite) {
        if (range.deducao != null) {
          return (baseValue * range.aliquota) - range.deducao!;
        } else {
          return baseValue * range.aliquota;
        }
      }
    }

    // Se não encontrou faixa, usar a última (maior)
    final lastRange = table.ranges.last;
    if (lastRange.deducao != null) {
      return (baseValue * lastRange.aliquota) - lastRange.deducao!;
    } else {
      return baseValue * lastRange.aliquota;
    }
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
