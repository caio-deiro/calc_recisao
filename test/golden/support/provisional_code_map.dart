// Remover em B2-01: quando `BreakdownCode` existir, `codeOf` vira `item.code.name`.
import 'package:calc_recisao/domain/entities/breakdown_item.dart';

const Map<String, String> _codeByDescription = {
  'Saldo de Salário': 'salaryBalance',
  'Aviso Prévio Indenizado': 'notice',
  'Aviso Prévio Indenizado (50%)': 'notice',
  'Desconto Aviso Prévio': 'noticeDiscount',
  '13º Salário Proporcional': 'thirteenth',
  'Férias Vencidas + 1/3': 'accruedVacation',
  'Férias Proporcionais + 1/3': 'proportionalVacation',
  'Multa FGTS (40%)': 'fgtsFine',
  'Multa FGTS (20%)': 'fgtsFine',
  'INSS': 'inss',
  'IRRF': 'irrf',
  'Outros Descontos': 'otherDiscounts',
};

/// Code (nome final do enum de B2-01) da verba. Única dependência de `description`.
String codeOf(BreakdownItem item) {
  final code = _codeByDescription[item.description];
  if (code == null) {
    throw StateError('Verba sem mapeamento de code: "${item.description}"');
  }
  return code;
}
