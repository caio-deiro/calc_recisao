import 'package:calc_recisao/domain/entities/calculation_history.dart';
import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_result.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';
import 'package:calc_recisao/domain/usecases/calculate_termination.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Entrada de 10 anos de casa (aviso de 60 dias), rescisão em 26/08/2025. Exige as
/// tabelas fiscais carregadas (`TaxTablesService.instance.loadTaxTables()`).
TerminationInput sampleInput({double? fgts}) => TerminationInput(
  admissionDate: DateTime(2015, 3, 10),
  terminationDate: DateTime(2025, 8, 26),
  baseSalary: 3000,
  hasExistingFgts: fgts != null,
  existingFgtsAmount: fgts ?? 0,
  calculateTaxes: false,
);

TerminationResult calculate(TerminationType type, {double? fgts}) =>
    const CalculateTerminationUseCase().execute(sampleInput(fgts: fgts), type);

CalculationHistory savedRecord(TerminationType type, {double? fgts, TerminationResult? result}) => CalculationHistory(
  id: 'saved_1',
  input: sampleInput(fgts: fgts),
  result: result ?? calculate(type, fgts: fgts),
  terminationType: type,
  timestamp: DateTime(2025, 8, 26),
);

/// Localiza pelo `Semantics.identifier`, o mesmo que o Maestro usa.
Finder byId(String id) => find.byWidgetPredicate((w) => w is Semantics && w.properties.identifier == id);
