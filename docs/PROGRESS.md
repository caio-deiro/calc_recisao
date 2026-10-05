# PROGRESS — andamento do docs/SPECS.md

> **Gerado por `scripts/specs_progress.py`. Não edite à mão.** Cruza os requisitos do [SPECS.md](SPECS.md) com as tasks das changes em `openspec/changes/` (ativas e arquivadas).
> Atualize com `python scripts/specs_progress.py` nos marcos do pipeline (ver skill `orchestrate`).

**Estados:** 🚀 entregue (change arquivada) · ✔ implementado (tasks marcadas, change ainda ativa) · 🔨 em andamento · 📋 planejado (task existe, nenhuma marcada) · 🎯 sem plano (nenhuma task cita o ID)

## Resumo

**32/76 requisitos entregues (42%)**

| Estado | Requisitos |
|---|--:|
| 🚀 Entregue | 32 |
| ✔ Implementado | 12 |
| 🔨 Em andamento | 6 |
| 📋 Planejado | 2 |
| 🎯 Sem plano | 24 |

## Por bloco

| Bloco | Título | Total | 🚀 | ✔ | 🔨 | 📋 | 🎯 | Entregue |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| B0 | Convenções e pré-requisitos transversais | 8 | 2 | 3 | 3 | 0 | 0 | 25% |
| B1 | Remoção do PRO e monetização só com AdMob | 17 | 17 | 0 | 0 | 0 | 0 | 100% |
| B2 | Núcleo de cálculo: modelo, correções e Decimal | 15 | 10 | 2 | 1 | 2 | 0 | 67% |
| B3 | Períodos de férias e férias em dobro | 8 | 0 | 0 | 0 | 0 | 8 | 0% |
| B4 | Contratos a prazo e rescisão indireta | 9 | 0 | 0 | 0 | 0 | 9 | 0% |
| B5 | Resultado, compartilhamento e PDF | 6 | 0 | 6 | 0 | 0 | 0 | 0% |
| B6 | Validação e infraestrutura de testes golden | 6 | 3 | 1 | 2 | 0 | 0 | 50% |
| B7 | Conformidade, privacidade e operação | 7 | 0 | 0 | 0 | 0 | 7 | 0% |

## Detalhe

### B0 — Convenções e pré-requisitos transversais

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B0-01 | 🔨 Em andamento | flutter analyze sem novos avisos e flutter test verde antes de qualquer commi... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-fix-calculation-rules`, `migrate-money-to-decimal`, `result-assumptions-and-two-totals` |
| B0-02 | ✔ Implementado | Teste antes da regra: mudança em cálculo só entra com teste que a cubra (gold... | `2026-10-05-fix-calculation-rules`, `result-assumptions-and-two-totals` |
| B0-03 | ✔ Implementado | Nenhum dado pessoal em log, evento de analytics ou relatório de crash: sem sa... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-fix-calculation-rules`, `result-assumptions-and-two-totals` |
| B0-04 | 🚀 Entregue | Base legal no commit: mudança de regra trabalhista/tributária cita artigo, sú... | `2026-10-05-fix-calculation-rules` |
| B0-05 | 🔨 Em andamento | Mudou camada, dependência, fluxo ou regra → atualizar docs/ARCHITECTURE.md e/... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-fix-calculation-rules`, `migrate-money-to-decimal`, `result-assumptions-and-two-totals` |
| B0-06 | 🚀 Entregue | D3 — Firebase não é inicializado (main.dart não chama Firebase.initializeApp)... | `2026-10-04-remove-pro-ads-only` |
| B0-07 | ✔ Implementado | Strings novas de UI vão em lib/l10n/app_localizations_pt.dart quando houver c... | `result-assumptions-and-two-totals` |
| B0-08 | 🔨 Em andamento | Cada bloco sai como versão publicável pequena; pubspec.yaml ganha bump de ver... | `2026-10-04-remove-pro-ads-only`, `2026-10-05-fix-calculation-rules`, `migrate-money-to-decimal`, `result-assumptions-and-two-totals` |

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
| B2-07 | 🚀 Entregue | C4 Férias indenizadas sem IRRF e sem INSS | `2026-10-05-fix-calculation-rules` |
| B2-08 | 🚀 Entregue | C5 INSS do 13º separado do salário | `2026-10-05-fix-calculation-rules` |
| B2-09 | ✔ Implementado | TerminationResult passa a expor paidAtTermination (soma dos proventos pagos −... | `2026-10-05-fix-calculation-rules`, `result-assumptions-and-two-totals` |
| B2-10 | 🚀 Entregue | Premissas: TerminationResult.assumptions: List<Assumption> com code, texto, o... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules` |
| B2-11 | ✔ Implementado | Histórico compatível: CalculationHistory.toJson ganha schemaVersion (inteiro)... | `2026-10-05-fix-calculation-rules`, `result-assumptions-and-two-totals` |
| B2-12 | 🚀 Entregue | O TerminationType.values.firstWhere(...) em CalculationHistory.fromJson não t... | `2026-10-05-fix-calculation-rules` |
| B2-13 | 🔨 Em andamento | Introduzir Decimal (package:decimal, já no pubspec) em domain/. Cálculo inter... | `2026-10-05-add-golden-test-infra`, `migrate-money-to-decimal` |
| B2-14 | 📋 Planejado | Fronteiras convertem para double (apresentação, toJson); o JSON do histórico ... | `migrate-money-to-decimal` |
| B2-15 | 📋 Planejado | Critério de migração: os testes golden (B6) passam antes da troca para Decima... | `migrate-money-to-decimal` |

### B3 — Períodos de férias e férias em dobro

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B3-01 | 🎯 Sem plano | Entrada: TerminationInput.hasAccruedVacation (bool) → vacationPeriodsTaken (i... | — |
| B3-02 | 🎯 Sem plano | Função pura VacationPeriods.derive(admission, termination, taken) em domain/,... | — |
| B3-03 | 🎯 Sem plano | Algoritmo: com n = anos completos entre admissão e rescisão; período i (1…n) ... | — |
| B3-04 | 🎯 Sem plano | Valores: simples = base × 4/3; dobro = 2 × base × 4/3 (1/3 sobre o total dobr... | — |
| B3-05 | 🎯 Sem plano | Itens do resultado: BreakdownCode.accruedVacationSimple, accruedVacationDoubl... | — |
| B3-06 | 🎯 Sem plano | Formulário: campo "Períodos de férias já gozados" com *stepper* limitado a n ... | — |
| B3-07 | 🎯 Sem plano | Premissas: tabela de períodos derivados (B3-02) em Premissas (B2-10), conferí... | — |
| B3-08 | 🎯 Sem plano | Validação (B2-13): tetos coerentes (taken ≤ n); datas inconsistentes seguem o... | — |

### B4 — Contratos a prazo e rescisão indireta

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B4-01 | 🎯 Sem plano | TerminationType ganha: indirectTermination, fixedTermEnd, fixedTermEarlyByEmp... | — |
| B4-02 | 🎯 Sem plano | Compatibilidade: fixedTerm (valor antigo) permanece apenas como alias de leit... | — |
| B4-03 | 🎯 Sem plano | Entrada nova: fixedTermEndDate (obrigatória nos três tipos a prazo) e hasReci... | — |
| B4-04 | 🎯 Sem plano | Assecuratória ativa: na rescisão antecipada passa a valer o TerminationRules ... | — |
| B4-05 | 🎯 Sem plano | Art. 479: indenização = (salário + média) / 30 × dias restantes × 50 %, com d... | — |
| B4-06 | 🎯 Sem plano | Art. 480: desconto = min(valor do art. 479, 1 remuneração mensal) (art. 477 §... | — |
| B4-07 | 🎯 Sem plano | Término normal: sem aviso e sem multa; com 13º, férias proporcionais, saque d... | — |
| B4-08 | 🎯 Sem plano | Rescisão indireta: mesmas regras do "sem justa causa". Implementada pela tabe... | — |
| B4-09 | 🎯 Sem plano | Formulário: campos de B4-03 aparecem somente nos tipos a prazo; TerminationTy... | — |

### B5 — Resultado, compartilhamento e PDF

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B5-01 | ✔ Implementado | ResultScreen exibe dois totais — "Pago na rescisão" e "Depositado no FGTS" — ... | `result-assumptions-and-two-totals` |
| B5-02 | ✔ Implementado | Seção "Premissas desta estimativa" recolhível (fechada por padrão). Marcador ... | `result-assumptions-and-two-totals` |
| B5-03 | ✔ Implementado | ShareUtils.generateShareText/generateSimpleShareText e PdfUtils._generatePdf ... | `result-assumptions-and-two-totals` |
| B5-04 | ✔ Implementado | O aviso legal permanece nas telas atuais (Home, Formulário, Resultado, Histór... | `result-assumptions-and-two-totals` |
| B5-05 | ✔ Implementado | Texto do compartilhamento sem dado pessoal além do próprio cálculo; nenhuma m... | `result-assumptions-and-two-totals` |
| B5-06 | ✔ Implementado | A tela de histórico abre um registro usando a mesma ResultScreen; registros l... | `result-assumptions-and-two-totals` |

### B6 — Validação e infraestrutura de testes golden

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B6-01 | 🚀 Entregue | Criar test/golden/cases/*.json. Cada arquivo: fonte (TRCT anonimizado, calcul... | `2026-10-05-add-golden-test-infra` |
| B6-02 | 🔨 Em andamento | Um único *runner* (test/golden/golden_test.dart) carrega todos os casos e com... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules`, `migrate-money-to-decimal` |
| B6-03 | 🚀 Entregue | O resultado esperado vem sempre do documento externo, nunca da saída do app. ... | `2026-10-05-add-golden-test-infra` |
| B6-04 | ✔ Implementado | Plano B: regras cujo caso golden ainda não existe (art. 479/480, férias em do... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules`, `result-assumptions-and-two-totals` |
| B6-05 | 🚀 Entregue | Cobertura mínima antes de publicar B2: um caso por tipo de rescisão ativo e p... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules` |
| B6-06 | 🔨 Em andamento | Pendências do responsável (bloqueiam a publicação, não o código): fornecer TR... | `2026-10-05-add-golden-test-infra`, `2026-10-05-fix-calculation-rules`, `migrate-money-to-decimal` |

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
