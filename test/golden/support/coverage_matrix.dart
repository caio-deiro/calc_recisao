import 'package:calc_recisao/domain/entities/termination_type.dart';

import '../validation_status.dart';
import 'golden_case.dart';

/// Correções C1–C5 do PRD que exigem caso (marcador `cobre` no JSON).
const correctionMarkers = ['C1', 'C2', 'C3', 'C4', 'C5'];

/// Itens da matriz de cobertura sem caso. Vazio = gate passa.
///  - um caso por tipo de rescisão ativo;
///  - um caso por correção C1–C5 (`cobre`);
///  - um caso `exemplo_contador` por regra ⚖️ pendente (`cobre` com o nome da regra).
List<String> missingCoverage(List<GoldenCase> cases) {
  final missing = <String>[];
  for (final t in TerminationType.values) {
    if (!cases.any((c) => c.type == t)) missing.add('tipo ${t.name}');
  }
  for (final m in correctionMarkers) {
    if (!cases.any((c) => c.cobre.contains(m))) {
      missing.add('verba corrigida $m');
    }
  }
  for (final r in pendingValidationRules) {
    if (!cases.any(
      (c) => c.fonteTipo == 'exemplo_contador' && c.cobre.contains(r),
    )) {
      missing.add('regra ⚖️ $r (exemplo_contador)');
    }
  }
  return missing;
}
