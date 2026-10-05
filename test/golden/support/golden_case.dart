import 'dart:convert';
import 'dart:io';

import 'package:calc_recisao/domain/entities/termination_input.dart';
import 'package:calc_recisao/domain/entities/termination_type.dart';

/// Codes de verba aceitos (nomes finais do enum de B2-01).
const goldenVerbaCodes = {
  'salaryBalance',
  'notice',
  'noticeDiscount',
  'thirteenth',
  'accruedVacation',
  'proportionalVacation',
  'fgtsFine',
  'inss',
  'irrf',
  'otherDiscounts',
};

const goldenTotalKeys = {
  'totalAdditions',
  'totalDeductions',
  'paidAtTermination',
  'fgtsDeposit',
};

/// Totais que o app ainda não produz (B2-10): pulados com motivo.
const unsupportedTotalKeys = {'paidAtTermination', 'fgtsDeposit'};

const goldenFonteTipos = {'trct', 'calculadora', 'exemplo_contador'};

/// Campos de entrada que o app ainda não suporta (B3/B4): o caso é pulado.
const unsupportedInputKeys = [
  'periodosFeriasGozados',
  'fimPrevisto',
  'clausula',
];

/// Erro de schema; a mensagem sempre cita a origem (arquivo).
class GoldenCaseException implements Exception {
  GoldenCaseException(this.origin, this.message);
  final String origin;
  final String message;

  @override
  String toString() => 'Caso golden inválido ($origin): $message';
}

class GoldenCase {
  GoldenCase._({
    required this.id,
    required this.fonteTipo,
    required this.fonteDescricao,
    required this.fonteReferencia,
    required this.type,
    required this.input,
    required this.unsupportedInputs,
    required this.verbas,
    required this.totais,
    required this.cobre,
  });

  final String id;
  final String fonteTipo;
  final String fonteDescricao;
  final String? fonteReferencia;
  final TerminationType type;
  final TerminationInput input;

  /// Campos de `entrada` presentes que o app ainda não suporta.
  final List<String> unsupportedInputs;
  final Map<String, double> verbas;
  final Map<String, double> totais;

  /// Marcadores de cobertura do gate (ex.: `C4`, `art479`); opcional.
  final Set<String> cobre;

  /// Valida e converte um caso. [allowFixtures] só existe para os autotestes;
  /// arquivos de `cases/` são sempre carregados com `false`.
  factory GoldenCase.parse(
    Map<String, dynamic> json, {
    required String origin,
    bool allowFixtures = false,
  }) {
    Never fail(String msg) => throw GoldenCaseException(origin, msg);

    final id = json['id'];
    if (id is! String || id.isEmpty) fail('"id" ausente');
    if (!allowFixtures &&
        (json['oraculo'] == false || id.startsWith('fixture_'))) {
      fail('fixture não pode estar em cases/ (oraculo:false ou id fixture_*)');
    }

    final fonte = json['fonte'];
    if (fonte is! Map) fail('"fonte" ausente');
    final fonteTipo = fonte['tipo'];
    if (fonteTipo is! String || !goldenFonteTipos.contains(fonteTipo)) {
      fail('"fonte.tipo" ausente ou desconhecido: $fonteTipo');
    }
    final fonteDescricao = fonte['descricao'];
    if (fonteDescricao is! String || fonteDescricao.trim().isEmpty) {
      fail('"fonte.descricao" ausente');
    }

    final typeName = json['tipo'];
    final type = TerminationType.values
        .where((t) => t.name == typeName)
        .firstOrNull;
    if (type == null) fail('"tipo" desconhecido: $typeName');

    final entrada = json['entrada'];
    if (entrada is! Map) fail('"entrada" ausente');

    double number(Object? v, String where) {
      if (v is! num) fail('valor não numérico em $where: $v');
      return v.toDouble();
    }

    DateTime date(String key) {
      final v = entrada[key];
      final parsed = v is String ? DateTime.tryParse(v) : null;
      if (parsed == null) fail('data inválida em entrada.$key: $v');
      return parsed;
    }

    final fgts = entrada['fgtsInformado'];
    final input = TerminationInput(
      admissionDate: date('admissao'),
      terminationDate: date('rescisao'),
      baseSalary: number(entrada['salarioBase'], 'entrada.salarioBase'),
      averageAdditions: number(
        entrada['mediaVariaveis'] ?? 0,
        'entrada.mediaVariaveis',
      ),
      dependents: (entrada['dependentes'] ?? 0) as int,
      hasExistingFgts: fgts != null,
      existingFgtsAmount: fgts == null
          ? 0.0
          : number(fgts, 'entrada.fgtsInformado'),
      hasAccruedVacation: entrada['feriasVencidas'] == true,
      noticeWorked: entrada['avisoTrabalhado'] == true,
      workedDaysInMonth: (entrada['diasTrabalhadosNoMes'] ?? 0) as int,
      otherDiscounts: number(
        entrada['outrosDescontos'] ?? 0,
        'entrada.outrosDescontos',
      ),
    );

    final esperado = json['esperado'];
    if (esperado is! Map) fail('"esperado" ausente');
    final verbas = <String, double>{};
    for (final e in ((esperado['verbas'] ?? {}) as Map).entries) {
      if (!goldenVerbaCodes.contains(e.key)) {
        fail('code de verba inválido: ${e.key}');
      }
      verbas[e.key as String] = number(e.value, 'esperado.verbas.${e.key}');
    }
    final totais = <String, double>{};
    for (final e in ((esperado['totais'] ?? {}) as Map).entries) {
      if (!goldenTotalKeys.contains(e.key)) {
        fail('chave de total inválida: ${e.key}');
      }
      totais[e.key as String] = number(e.value, 'esperado.totais.${e.key}');
    }

    return GoldenCase._(
      id: id,
      fonteTipo: fonteTipo,
      fonteDescricao: fonteDescricao,
      fonteReferencia: fonte['referencia'] as String?,
      type: type,
      input: input,
      unsupportedInputs: unsupportedInputKeys
          .where(entrada.containsKey)
          .toList(),
      verbas: verbas,
      totais: totais,
      cobre: {...((json['cobre'] ?? const []) as List).cast<String>()},
    );
  }
}

/// Carrega todos os `*.json` de [dir]; qualquer erro de schema propaga.
List<GoldenCase> loadGoldenCases(Directory dir) {
  if (!dir.existsSync()) return [];
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final f in files)
      GoldenCase.parse(
        jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
        origin: f.uri.pathSegments.last,
      ),
  ];
}
