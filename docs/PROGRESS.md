# PROGRESS — andamento do docs/SPECS.md

> **Gerado por `scripts/specs_progress.py`. Não edite à mão.** Cruza os requisitos do [SPECS.md](SPECS.md) com as tasks das changes em `openspec/changes/` (ativas e arquivadas).
> Atualize com `python scripts/specs_progress.py` nos marcos do pipeline (ver skill `orchestrate`).

**Estados:** 🚀 entregue (change arquivada) · ✔ implementado (tasks marcadas, change ainda ativa) · 🔨 em andamento · 📋 planejado (task existe, nenhuma marcada) · 🎯 sem plano (nenhuma task cita o ID)

## Resumo

**69/76 requisitos entregues (91%)**

| Estado | Requisitos |
|---|--:|
| 🚀 Entregue | 69 |
| ✔ Implementado | 0 |
| 🔨 Em andamento | 0 |
| 📋 Planejado | 0 |
| 🎯 Sem plano | 7 |

## Por bloco

| Bloco | Título | Total | 🚀 | ✔ | 🔨 | 📋 | 🎯 | Entregue |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| B0 | Convenções e pré-requisitos transversais | 8 | 8 | 0 | 0 | 0 | 0 | 100% |
| B1 | Remoção do PRO e monetização só com AdMob | 17 | 17 | 0 | 0 | 0 | 0 | 100% |
| B2 | Núcleo de cálculo: modelo, correções e Decimal | 15 | 15 | 0 | 0 | 0 | 0 | 100% |
| B3 | Períodos de férias e férias em dobro | 8 | 8 | 0 | 0 | 0 | 0 | 100% |
| B4 | Contratos a prazo e rescisão indireta | 9 | 9 | 0 | 0 | 0 | 0 | 100% |
| B5 | Resultado, compartilhamento e PDF | 6 | 6 | 0 | 0 | 0 | 0 | 100% |
| B6 | Validação e infraestrutura de testes golden | 6 | 6 | 0 | 0 | 0 | 0 | 100% |
| B7 | Conformidade, privacidade e operação | 7 | 0 | 0 | 0 | 0 | 7 | 0% |

## Detalhe

### B0 — Convenções e pré-requisitos transversais

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B0-01 | 🚀 Entregue | flutter analyze sem novos avisos e flutter test verde antes de qualquer commi... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-add-vacation-periods`, `2026-10-05-fix-calculation-rules`, `2026-10-05-migrate-money-to-decimal`, `2026-10-05-result-assumptions-and-two-totals` |
| B0-02 | 🚀 Entregue | Teste antes da regra: mudança em cálculo só entra com teste que a cubra (gold... | `2026-10-05-fix-calculation-rules`, `2026-10-05-result-assumptions-and-two-totals` |
| B0-03 | 🚀 Entregue | Nenhum dado pessoal em log, evento de analytics ou relatório de crash: sem sa... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-fix-calculation-rules`, `2026-10-05-result-assumptions-and-two-totals` |
| B0-04 | 🚀 Entregue | Base legal no commit: mudança de regra trabalhista/tributária cita artigo, sú... | `2026-10-05-fix-calculation-rules` |
| B0-05 | 🚀 Entregue | Mudou camada, dependência, fluxo ou regra → atualizar docs/ARCHITECTURE.md e/... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-add-vacation-periods`, `2026-10-05-fix-calculation-rules`, `2026-10-05-migrate-money-to-decimal`, `2026-10-05-result-assumptions-and-two-totals` |
| B0-06 | 🚀 Entregue | D3 — Firebase não é inicializado (main.dart não chama Firebase.initializeApp)... | `2026-10-04-remove-pro-ads-only` |
| B0-07 | 🚀 Entregue | Strings novas de UI vão em lib/l10n/app_localizations_pt.dart quando houver c... | `2026-10-05-result-assumptions-and-two-totals` |
| B0-08 | 🚀 Entregue | Cada bloco sai como versão publicável pequena; pubspec.yaml ganha bump de ver... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-add-vacation-periods`, `2026-10-05-fix-calculation-rules`, `2026-10-05-migrate-money-to-decimal`, `2026-10-05-result-assumptions-and-two-totals` |

### B1 — Remoção do PRO e monetização só com AdMob

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B1-01 | 🚀 Entregue | Remover lib/core/services/purchase_service.dart, lib/core/services/offline_se... | `2026-10-04-remove-pro-ads-only` |
| B1-02 | 🚀 Entregue | Remover todo acesso a ProUtils/PurchaseService/OfflineService. Pontos conheci... | `2026-10-04-remove-pro-ads-only` |
| B1-03 | 🚀 Entregue | Remover de pubspec.yaml: in_app_purchase e in_app_purchase_android. Confirmar... | `2026-10-04-remove-pro-ads-only` |
| B1-04 | 🚀 Entregue | Remover de AppConstants: proProductId, proMonthlyPrice, proSupportEmail, proS... | `2026-10-04-remove-pro-ads-only` |
| B1-05 | 🚀 Entregue | Limpeza de dados legados: na primeira execução da nova versão, remover de Sha... | `2026-10-04-remove-pro-ads-only` |
| B1-06 | 🚀 Entregue | Arquivar a spec openspec/specs/play-billing (a exigência deixa de valer). Man... | `2026-10-04-remove-pro-ads-only` |
| B1-07 | 🚀 Entregue | Remover/ajustar testes: test/unit/pro_features_test.dart (apagar), ad_manager... | `2026-10-04-remove-pro-ads-only` |
| B1-08 | 🚀 Entregue | PDF (PdfUtils/ShareUtils.exportToPdf/savePdfToFile) disponível para todos, se... | `2026-10-04-remove-pro-ads-only` |
| B1-09 | 🚀 Entregue | AppConstants.maxHistorySize = 100. HistoryRepository.saveCalculation descarta... | `2026-10-04-remove-pro-ads-only` |
| B1-10a | 🚀 Entregue | Banner adaptativo (AdSize ancorado adaptativo) fixo no rodapé nas telas Home,... | `2026-10-04-remove-pro-ads-only` |
| B1-10b | 🚀 Entregue | Intersticial somente ao sair do Resultado (voltar à Home, ou ao concluir comp... | `2026-10-04-remove-pro-ads-only` |
| B1-10c | 🚀 Entregue | Frequência: no máximo 1 a cada 3 min (persistir last_interstitial_time, ✅ exi... | `2026-10-04-remove-pro-ads-only` |
| B1-10d | 🚀 Entregue | Sem anúncio recompensado; sem anúncio em Splash e Formulário (decisão Q16a). | `2026-10-04-remove-pro-ads-only` |
| B1-11 | 🚀 Entregue | Aviso único após o primeiro resultado: formulário de consentimento do Google ... | `2026-10-04-remove-pro-ads-only` |
| B1-12 | 🚀 Entregue | Analytics opt-in (firebase_analytics, reativar no pubspec). Coleta desligada ... | `2026-10-04-remove-pro-ads-only` |
| B1-13 | 🚀 Entregue | Eventos permitidos (únicos): calc_completed{tipo_rescisao}, share_used, pdf_e... | `2026-10-04-remove-pro-ads-only` |
| B1-14 | 🚀 Entregue | Anúncios não personalizados até o consentimento (AdRequest(nonPersonalizedAds... | `2026-10-04-remove-pro-ads-only` |

### B2 — Núcleo de cálculo: modelo, correções e Decimal

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B2-01 | 🚀 Entregue | Identidade de verba (D8): BreakdownItem ganha code (enum BreakdownCode: salar... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules` |
| B2-02 | 🚀 Entregue | Regras por tipo em tabela, não em if espalhados: um TerminationRules imutável... | `2026-10-05-fix-calculation-rules` |
| B2-03 | 🚀 Entregue | O use case deixa de remover itens depois de adicioná-los (padrão atual para j... | `2026-10-05-fix-calculation-rules` |
| B2-04 | 🚀 Entregue | C1 Justa causa paga férias vencidas | `2026-10-05-fix-calculation-rules` |
| B2-05 | 🚀 Entregue | C2 Aviso indenizado projeta tempo | `2026-10-05-fix-calculation-rules` |
| B2-06 | 🚀 Entregue | C3 Férias proporcionais pelo período aquisitivo | `2026-10-05-fix-calculation-rules` |
| B2-07 | 🚀 Entregue | C4 Férias indenizadas sem IRRF e sem INSS | `2026-10-05-fix-calculation-rules`, `2026-10-06-fix-thirteenth-irrf` |
| B2-08 | 🚀 Entregue | C5 INSS do 13º separado do salário | `2026-10-05-fix-calculation-rules`, `2026-10-06-fix-thirteenth-irrf` |
| B2-09 | 🚀 Entregue | TerminationResult passa a expor paidAtTermination (soma dos proventos pagos −... | `2026-10-05-fix-calculation-rules`, `2026-10-05-result-assumptions-and-two-totals` |
| B2-10 | 🚀 Entregue | Premissas: TerminationResult.assumptions: List<Assumption> com code, texto, o... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules` |
| B2-11 | 🚀 Entregue | Histórico compatível: CalculationHistory.toJson ganha schemaVersion (inteiro)... | `2026-10-05-fix-calculation-rules`, `2026-10-05-result-assumptions-and-two-totals` |
| B2-12 | 🚀 Entregue | O TerminationType.values.firstWhere(...) em CalculationHistory.fromJson não t... | `2026-10-05-fix-calculation-rules` |
| B2-13 | 🚀 Entregue | Introduzir Decimal (package:decimal, já no pubspec) em domain/. Cálculo inter... | `2026-10-05-add-golden-test-infra`, `2026-10-05-migrate-money-to-decimal` |
| B2-14 | 🚀 Entregue | Fronteiras convertem para double (apresentação, toJson); o JSON do histórico ... | `2026-10-05-migrate-money-to-decimal` |
| B2-15 | 🚀 Entregue | Critério de migração: os testes golden (B6) passam antes da troca para Decima... | `2026-10-05-migrate-money-to-decimal` |

### B3 — Períodos de férias e férias em dobro

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B3-01 | 🚀 Entregue | Entrada: TerminationInput.hasAccruedVacation (bool) → vacationPeriodsTaken (i... | `2026-10-05-add-vacation-periods` |
| B3-02 | 🚀 Entregue | Função pura VacationPeriods.derive(admission, termination, taken) em domain/,... | `2026-10-05-add-vacation-periods` |
| B3-03 | 🚀 Entregue | Algoritmo: com n = anos completos entre admissão e rescisão; período i (1…n) ... | `2026-10-05-add-vacation-periods` |
| B3-04 | 🚀 Entregue | Valores: simples = base × 4/3; dobro = 2 × base × 4/3 (1/3 sobre o total dobr... | `2026-10-05-add-vacation-periods` |
| B3-05 | 🚀 Entregue | Itens do resultado: BreakdownCode.accruedVacationSimple, accruedVacationDoubl... | `2026-10-05-add-vacation-periods` |
| B3-06 | 🚀 Entregue | Formulário: campo "Períodos de férias já gozados" com *stepper* limitado a n ... | `2026-10-05-add-vacation-periods` |
| B3-07 | 🚀 Entregue | Premissas: tabela de períodos derivados (B3-02) em Premissas (B2-10), conferí... | `2026-10-05-add-vacation-periods` |
| B3-08 | 🚀 Entregue | Validação (B2-13): tetos coerentes (taken ≤ n); datas inconsistentes seguem o... | `2026-10-05-add-vacation-periods` |

### B4 — Contratos a prazo e rescisão indireta

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B4-01 | 🚀 Entregue | TerminationType ganha: indirectTermination, fixedTermEnd, fixedTermEarlyByEmp... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-02 | 🚀 Entregue | Compatibilidade: fixedTerm (valor antigo) permanece apenas como alias de leit... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-03 | 🚀 Entregue | Entrada nova: fixedTermEndDate (obrigatória nos três tipos a prazo) e hasReci... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-04 | 🚀 Entregue | Assecuratória ativa: na rescisão antecipada passa a valer o TerminationRules ... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-05 | 🚀 Entregue | Art. 479: indenização = (salário + média) / 30 × dias restantes × 50 %, com d... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-06 | 🚀 Entregue | Art. 480: desconto = min(valor do art. 479, 1 remuneração mensal) (art. 477 §... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-07 | 🚀 Entregue | Término normal: sem aviso e sem multa; com 13º, férias proporcionais, saque d... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-08 | 🚀 Entregue | Rescisão indireta: mesmas regras do "sem justa causa". Implementada pela tabe... | `2026-10-06-add-fixed-term-and-indirect` |
| B4-09 | 🚀 Entregue | Formulário: campos de B4-03 aparecem somente nos tipos a prazo; TerminationTy... | `2026-10-06-add-fixed-term-and-indirect` |

### B5 — Resultado, compartilhamento e PDF

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B5-01 | 🚀 Entregue | ResultScreen exibe dois totais — "Pago na rescisão" e "Depositado no FGTS" — ... | `2026-10-05-result-assumptions-and-two-totals` |
| B5-02 | 🚀 Entregue | Seção "Premissas desta estimativa" recolhível (fechada por padrão). Marcador ... | `2026-10-05-result-assumptions-and-two-totals` |
| B5-03 | 🚀 Entregue | ShareUtils.generateShareText/generateSimpleShareText e PdfUtils._generatePdf ... | `2026-10-05-result-assumptions-and-two-totals` |
| B5-04 | 🚀 Entregue | O aviso legal permanece nas telas atuais (Home, Formulário, Resultado, Histór... | `2026-10-05-result-assumptions-and-two-totals` |
| B5-05 | 🚀 Entregue | Texto do compartilhamento sem dado pessoal além do próprio cálculo; nenhuma m... | `2026-10-05-result-assumptions-and-two-totals` |
| B5-06 | 🚀 Entregue | A tela de histórico abre um registro usando a mesma ResultScreen; registros l... | `2026-10-05-result-assumptions-and-two-totals` |

### B6 — Validação e infraestrutura de testes golden

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B6-01 | 🚀 Entregue | Criar test/golden/cases/*.json. Cada arquivo: fonte (TRCT anonimizado, calcul... | `2026-10-05-add-golden-test-infra` |
| B6-02 | 🚀 Entregue | Um único *runner* (test/golden/golden_test.dart) carrega todos os casos e com... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules`, `2026-10-05-migrate-money-to-decimal` |
| B6-03 | 🚀 Entregue | O resultado esperado vem sempre do documento externo, nunca da saída do app. ... | `2026-10-05-add-golden-test-infra`, `2026-10-06-fix-thirteenth-irrf` |
| B6-04 | 🚀 Entregue | Plano B: regras cujo caso golden ainda não existe (art. 479/480, férias em do... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules`, `2026-10-05-result-assumptions-and-two-totals` |
| B6-05 | 🚀 Entregue | Cobertura mínima antes de publicar B2: um caso por tipo de rescisão ativo e p... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules` |
| B6-06 | 🚀 Entregue | Pendências do responsável (bloqueiam a publicação, não o código): fornecer TR... | `2026-10-05-add-golden-test-infra`, `2026-10-05-add-vacation-periods`, `2026-10-05-fix-calculation-rules`, `2026-10-05-migrate-money-to-decimal` |

### B7 — Conformidade, privacidade e operação

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B7-01 | 🎯 Sem plano | Política de privacidade reescrita: AdMob (ID de publicidade), Analytics/Crash... | — |
| B7-02 | 🎯 Sem plano | Data Safety da Play alinhada a B7-01 e declaração "contém anúncios". | — |
| B7-03 | 🎯 Sem plano | Desativar o produto calc_recisao_pro_monthly (sem assinantes). | — |
| B7-04 | 🎯 Sem plano | Listagem da loja sem qualquer menção a PRO, PDF "exclusivo" ou histórico "ili... | — |
| B7-05 | 🎯 Sem plano | Confirmar e unificar o e-mail de contato (política × app). | — |
| B7-06 | 🎯 Sem plano | Manutenção anual das tabelas (checklist do PRD §13): JSON, teste do ano, list... | — |
| B7-07 | 🎯 Sem plano | Specs de compliance Android (android-target-sdk, 16 KB) preservadas; prazo da... | — |

## Alertas

Nenhum.
