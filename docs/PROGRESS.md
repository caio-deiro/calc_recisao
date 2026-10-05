# PROGRESS — andamento do docs/SPECS.md

> **Gerado por `scripts/specs_progress.py`. Não edite à mão.** Cruza os requisitos do [SPECS.md](SPECS.md) com as tasks das changes em `openspec/changes/` (ativas e arquivadas).
> Atualize com `python scripts/specs_progress.py` nos marcos do pipeline (ver skill `orchestrate`).

**Estados:** 🚀 entregue (change arquivada) · ✔ implementado (tasks marcadas, change ainda ativa) · 🔨 em andamento · 📋 planejado (task existe, nenhuma marcada) · 🎯 sem plano (nenhuma task cita o ID)

## Resumo

**22/76 requisitos entregues (29%)**

| Estado | Requisitos |
|---|--:|
| 🚀 Entregue | 22 |
| ✔ Implementado | 0 |
| 🔨 Em andamento | 0 |
| 📋 Planejado | 0 |
| 🎯 Sem plano | 54 |

## Por bloco

| Bloco | Título | Total | 🚀 | ✔ | 🔨 | 📋 | 🎯 | Entregue |
|---|---|--:|--:|--:|--:|--:|--:|--:|
| B0 | Convenções e pré-requisitos transversais | 8 | 5 | 0 | 0 | 0 | 3 | 62% |
| B1 | Remoção do PRO e monetização só com AdMob | 17 | 17 | 0 | 0 | 0 | 0 | 100% |
| B2 | Núcleo de cálculo: modelo, correções e Decimal | 15 | 0 | 0 | 0 | 0 | 15 | 0% |
| B3 | Períodos de férias e férias em dobro | 8 | 0 | 0 | 0 | 0 | 8 | 0% |
| B4 | Contratos a prazo e rescisão indireta | 9 | 0 | 0 | 0 | 0 | 9 | 0% |
| B5 | Resultado, compartilhamento e PDF | 6 | 0 | 0 | 0 | 0 | 6 | 0% |
| B6 | Validação e infraestrutura de testes golden | 6 | 0 | 0 | 0 | 0 | 6 | 0% |
| B7 | Conformidade, privacidade e operação | 7 | 0 | 0 | 0 | 0 | 7 | 0% |

## Detalhe

### B0 — Convenções e pré-requisitos transversais

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B0-01 | 🚀 Entregue | flutter analyze sem novos avisos e flutter test verde antes de qualquer commi... | `2026-10-04-remove-pro-ads-only` |
| B0-02 | 🎯 Sem plano | Teste antes da regra: mudança em cálculo só entra com teste que a cubra (gold... | — |
| B0-03 | 🚀 Entregue | Nenhum dado pessoal em log, evento de analytics ou relatório de crash: sem sa... | `2026-10-04-remove-pro-ads-only` |
| B0-04 | 🎯 Sem plano | Base legal no commit: mudança de regra trabalhista/tributária cita artigo, sú... | — |
| B0-05 | 🚀 Entregue | Mudou camada, dependência, fluxo ou regra → atualizar docs/ARCHITECTURE.md e/... | `2026-10-04-remove-pro-ads-only` |
| B0-06 | 🚀 Entregue | D3 — Firebase não é inicializado (main.dart não chama Firebase.initializeApp)... | `2026-10-04-remove-pro-ads-only` |
| B0-07 | 🎯 Sem plano | Strings novas de UI vão em lib/l10n/app_localizations_pt.dart quando houver c... | — |
| B0-08 | 🚀 Entregue | Cada bloco sai como versão publicável pequena; pubspec.yaml ganha bump de ver... | `2026-10-04-remove-pro-ads-only` |

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
| B2-01 | 🎯 Sem plano | Identidade de verba (D8): BreakdownItem ganha code (enum BreakdownCode: salar... | — |
| B2-02 | 🎯 Sem plano | Regras por tipo em tabela, não em if espalhados: um TerminationRules imutável... | — |
| B2-03 | 🎯 Sem plano | O use case deixa de remover itens depois de adicioná-los (padrão atual para j... | — |
| B2-04 | 🎯 Sem plano | C1 Justa causa paga férias vencidas | — |
| B2-05 | 🎯 Sem plano | C2 Aviso indenizado projeta tempo | — |
| B2-06 | 🎯 Sem plano | C3 Férias proporcionais pelo período aquisitivo | — |
| B2-07 | 🎯 Sem plano | C4 Férias indenizadas sem IRRF e sem INSS | — |
| B2-08 | 🎯 Sem plano | C5 INSS do 13º separado do salário | — |
| B2-09 | 🎯 Sem plano | TerminationResult passa a expor paidAtTermination (soma dos proventos pagos −... | — |
| B2-10 | 🎯 Sem plano | Premissas: TerminationResult.assumptions: List<Assumption> com code, texto, o... | — |
| B2-11 | 🎯 Sem plano | Histórico compatível: CalculationHistory.toJson ganha schemaVersion (inteiro)... | — |
| B2-12 | 🎯 Sem plano | O TerminationType.values.firstWhere(...) em CalculationHistory.fromJson não t... | — |
| B2-13 | 🎯 Sem plano | Introduzir Decimal (package:decimal, já no pubspec) em domain/. Cálculo inter... | — |
| B2-14 | 🎯 Sem plano | Fronteiras convertem para double (apresentação, toJson); o JSON do histórico ... | — |
| B2-15 | 🎯 Sem plano | Critério de migração: os testes golden (B6) passam antes e depois da troca pa... | — |

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
| B5-01 | 🎯 Sem plano | ResultScreen exibe dois totais — "Pago na rescisão" e "Depositado no FGTS" — ... | — |
| B5-02 | 🎯 Sem plano | Seção "Premissas desta estimativa" recolhível (fechada por padrão). Marcador ... | — |
| B5-03 | 🎯 Sem plano | ShareUtils.generateShareText/generateSimpleShareText e PdfUtils._generatePdf ... | — |
| B5-04 | 🎯 Sem plano | O aviso legal permanece nas telas atuais (Home, Formulário, Resultado, Histór... | — |
| B5-05 | 🎯 Sem plano | Texto do compartilhamento sem dado pessoal além do próprio cálculo; nenhuma m... | — |
| B5-06 | 🎯 Sem plano | A tela de histórico abre um registro usando a mesma ResultScreen; registros l... | — |

### B6 — Validação e infraestrutura de testes golden

| ID | Estado | Requisito | Changes |
|---|---|---|---|
| B6-01 | 🎯 Sem plano | Criar test/golden/cases/*.json. Cada arquivo: fonte (TRCT anonimizado, calcul... | — |
| B6-02 | 🎯 Sem plano | Um único *runner* (test/golden/golden_test.dart) carrega todos os casos e com... | — |
| B6-03 | 🎯 Sem plano | O resultado esperado vem sempre do documento externo, nunca da saída do app. ... | — |
| B6-04 | 🎯 Sem plano | Plano B: regras cujo caso golden ainda não existe (art. 479/480, férias em do... | — |
| B6-05 | 🎯 Sem plano | Cobertura mínima antes de publicar B2: um caso por tipo de rescisão ativo e p... | — |
| B6-06 | 🎯 Sem plano | Pendências do responsável (bloqueiam a publicação, não o código): fornecer TR... | — |

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

**Buracos no plano** (bloco em andamento com requisitos sem task):
- **B0** tem requisitos planejados, mas estes não têm task: B0-02, B0-04, B0-07
