/// Regras ⚖️ sem caso golden com fonte (B6-04). Regra listada que chegue ao
/// usuário deve exibir a premissa "cálculo em validação" (Assumption, B2-10)
/// até existir caso golden com fonte; o gate de cobertura acusa as sem caso.
/// Ao ganhar caso, remova da lista e marque o caso com `cobre`.
const pendingValidationRules = [
  'art479',
  'art480',
  'doubleVacation',
  'noticeProjectionMutualAgreement',
];
