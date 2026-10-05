# SPECS — Fatiamento técnico do PRD

> Traduz os requisitos de produto de [PROJECT.md](PROJECT.md) em **blocos técnicos** implementáveis.
> O PRD diz **o quê e por quê**; este documento diz **onde e com que contrato** isso toca o código.
> Arquitetura de referência: [ARCHITECTURE.md](ARCHITECTURE.md).
>
> **Como se encaixa no fluxo**
> ```
> PROJECT.md (produto) → SPECS.md (blocos técnicos) → openspec/changes/<change> (proposal, design, tasks)
> ```
> Cada bloco aponta a *change* de OpenSpec que o executa. Este arquivo **não** lista tarefas; isso é o
> `tasks.md` da change.
>
> **Progresso:** este arquivo é o plano e **não registra status**. O andamento real (o que já foi
> entregue pelo pipeline) está em [PROGRESS.md](PROGRESS.md), gerado a partir deste arquivo e das tasks
> das changes. Por isso os IDs `B<n>-<nn>` são contrato: não os renumere nem os reaproveite.
>
> **Convenções**
> - ✅ atual no código · 🎯 decidido, não implementado · ⚖️ regra que exige validação humana (§B6).
> - IDs: `B<bloco>-<nn>` para requisitos técnicos (ex.: `B2-04`). Referenciar nos commits e testes.
> - Caminhos são relativos à raiz do repositório. "Módulos afetados" indica **onde mexer**, não o
>   resultado final do design.
> - **Fonte de verdade em conflito:** PRD > SPECS > código. Se o código diverge de uma decisão 🎯, o
>   código está atrasado, não o documento.

---

## 1. Mapa dos blocos

| Bloco | Título | Change OpenSpec | Depende de | PRD |
|---|---|---|---|---|
| **B0** | Convenções e pré-requisitos transversais | — | — | §4, §10 |
| **B1** | Remoção do PRO e monetização só com AdMob | `remove-pro-ads-only` | B0 | §5.2, §8, §9 |
| **B2** | Núcleo de cálculo: modelo, correções e `Decimal` | `fix-calculation-rules` (B2-01..12) e `migrate-money-to-decimal` (B2-13..15) | B0, B6 | §6.2–6.3, §6.5, §6.7 |
| **B3** | Períodos de férias e férias em dobro | `add-vacation-periods` | B2 | §6.4 |
| **B4** | Contratos a prazo e rescisão indireta | `add-fixed-term-and-indirect` | B2 | §6.1, §6.6 |
| **B5** | Resultado, compartilhamento e PDF | `result-assumptions-and-two-totals` | B1, B2 | §6.5, §7 |
| **B6** | Validação e infraestrutura de testes golden | (distribuída; começa em B2) | — | §11 |
| **B7** | Conformidade, privacidade e operação | (fora do código, com checklist) | B1 | §12–14 |

### Ordem de execução
`B0 → B6 (infra de golden tests) → B1 → B2 → B3 → B4`, com B5 e B7 acompanhando.
**Motivo:** B6 vem antes de qualquer regra mudar (sem oráculo, a correção é opinião); B1 é mecânica e
reduz a base antes das fórmulas; B3 e B4 dependem do modelo de B2 (identidade de verba, dois totais,
`Decimal`).

### Rastreabilidade PRD → bloco

| Decisão do PRD | Bloco |
|---|---|
| Q15, Q18, Q19 (fim do PRO, histórico 100, sem meta) | B1 |
| Q16, Q17 (anúncios, consentimento) | B1 |
| Q5, Q13, Q21 (analytics) | B1 |
| Q1, Q11 (dois totais, premissas) | B2, B5 |
| Q2, Q7, Q9 (C1–C5) | B2 |
| Q22 (`Decimal`) | B2 |
| Q8, Q24, Q25 (períodos, dobro) | B3 |
| Q23, Q26, Q27 (prazo determinado, 479/480, indireta) | B4 |
| Q10, Q28 (validação) | B6 |
| Q3 (promessa de precisão) | B2, B5 |

---

## B0 — Convenções e pré-requisitos transversais

Valem para todos os blocos. Existem para impedir que cada bloco reinvente a regra.

| ID | Requisito técnico |
|---|---|
| B0-01 | `flutter analyze` sem **novos** avisos e `flutter test` verde antes de qualquer commit de bloco. Os 3 avisos atuais (`app.dart` import não usado, `app_constants.dart` comentário solto, `termination_2026_test.dart` variável não usada) devem ser zerados na primeira change. |
| B0-02 | **Teste antes da regra:** mudança em cálculo só entra com teste que a cubra (golden quando houver oráculo; unitário caso contrário). |
| B0-03 | **Nenhum dado pessoal** em log, evento de analytics ou relatório de crash: sem salário, datas, valores nem resultado. Evento só carrega o parâmetro listado em B1-12. |
| B0-04 | **Base legal no commit:** mudança de regra trabalhista/tributária cita artigo, súmula ou portaria. |
| B0-05 | Mudou camada, dependência, fluxo ou regra → atualizar `docs/ARCHITECTURE.md` e/ou `docs/PROJECT.md` **no mesmo commit**. |
| B0-06 | **D3 — Firebase não é inicializado** (`main.dart` não chama `Firebase.initializeApp`). Resolver antes de B1-12, pois Analytics e Crashlytics dependem disso: adicionar `firebase_options`/`google-services.json` e inicializar, **com coleta desligada por padrão** (ver B1-10). |
| B0-07 | Strings novas de UI vão em `lib/l10n/app_localizations_pt.dart` quando houver chave equivalente; descrições de verba usam o `code` da verba (B2-01), nunca o texto como chave. |
| B0-08 | Cada bloco sai como **versão publicável pequena**; `pubspec.yaml` ganha bump de versão no merge da change. |

---

## B1 — Remoção do PRO e monetização só com AdMob

**Change:** `remove-pro-ads-only` · **PRD:** §5.2, §8, §9, Q15–Q19, Q21 · **Persona:** ambas

**Objetivo técnico:** app 100 % gratuito; nenhum código de compra; PDF livre; histórico de 100;
anúncios reposicionados; consentimento único; analytics mínimo.

### B1.1 Remoção de PRO e compras

| ID | Requisito |
|---|---|
| B1-01 | Remover `lib/core/services/purchase_service.dart`, `lib/core/services/offline_service.dart`, `lib/core/utils/pro_utils.dart` e `lib/presentation/screens/pro/pro_screen.dart`. |
| B1-02 | Remover todo acesso a `ProUtils`/`PurchaseService`/`OfflineService`. Pontos conhecidos: `lib/main.dart`, `lib/core/ads/ad_manager.dart`, `lib/core/services/support_service.dart`, `lib/data/repositories/history_repository.dart`, `lib/presentation/screens/{home,history,result,support}/*` (card de upgrade, banner de limite, bloqueio de PDF, e-mail PRO). |
| B1-03 | Remover de `pubspec.yaml`: `in_app_purchase` e `in_app_purchase_android`. Confirmar que o `AndroidManifest.xml` não declara permissão de faturamento residual. |
| B1-04 | Remover de `AppConstants`: `proProductId`, `proMonthlyPrice`, `proSupportEmail`, `proSupportResponseHours`, `maxFreeHistorySize`, `maxProHistorySize`. |
| B1-05 | **Limpeza de dados legados:** na primeira execução da nova versão, remover de `SharedPreferences` as chaves `is_pro_user`, `pro_purchase_date`, `pro_purchase_id`, `pro_purchase_token`, `offline_cache`, `pending_sync`, `pro_conversion`. Operação idempotente. |
| B1-06 | Arquivar a spec `openspec/specs/play-billing` (a exigência deixa de valer). Manter `android-target-sdk`. |
| B1-07 | Remover/ajustar testes: `test/unit/pro_features_test.dart` (apagar), `ad_manager_test.dart`, `pdf_export_test.dart`, `history_repository_test.dart` (adequar às novas regras). |

### B1.2 PDF e histórico

| ID | Requisito |
|---|---|
| B1-08 | PDF (`PdfUtils`/`ShareUtils.exportToPdf`/`savePdfToFile`) disponível para todos, sem verificação de status. |
| B1-09 | `AppConstants.maxHistorySize = 100`. `HistoryRepository.saveCalculation` descarta o mais antigo (FIFO) ao exceder. Quando `length >= 90` após salvar, a UI exibe aviso discreto na tela de histórico. Substitui o banner de upgrade. |

### B1.3 Anúncios

| ID | Requisito |
|---|---|
| B1-10a | **Banner adaptativo** (`AdSize` ancorado adaptativo) fixo no rodapé nas telas Home, Resultado, Histórico, Suporte e Sobre; **ausente** em Formulário e Splash. Hoje: banner só em Home/Resultado/Histórico (✅). |
| B1-10b | **Intersticial somente ao sair do Resultado** (voltar à Home, ou ao concluir compartilhar/exportar). **Nunca** ao entrar. Remover a chamada atual em `result_screen.dart` (`addPostFrameCallback` → `AdManager.showInterstitialAd()`), que cobre o resultado (dívida **D9**). |
| B1-10c | Frequência: **no máximo 1 a cada 3 min** (persistir `last_interstitial_time`, ✅ existente) **e 1 por sessão** (flag em memória). Se o anúncio não estiver carregado, a navegação segue sem bloqueio nem espera. |
| B1-10d | Sem anúncio recompensado; sem anúncio em `Splash` e `Formulário` (decisão Q16a). |

### B1.4 Consentimento e analytics

| ID | Requisito |
|---|---|
| B1-11 | **Aviso único** após o primeiro resultado: formulário de consentimento do Google (UMP, `ConsentInformation` do `google_mobile_ads`) + escolha de analytics. Decisão persistida; não repetir. Nenhum aviso antes do primeiro resultado. |
| B1-12 | **Analytics opt-in** (`firebase_analytics`, reativar no `pubspec`). Coleta **desligada por padrão** (meta-data do manifesto e `setAnalyticsCollectionEnabled(false)`); só liga após aceite. Crashlytics sob a mesma decisão (`setCrashlyticsCollectionEnabled`). |
| B1-13 | Eventos permitidos (únicos): `calc_completed{tipo_rescisao}`, `share_used`, `pdf_exported`, `consent_decision{aceitou\|recusou}`. Um ponto central de emissão (`core/analytics/`) que **descarta silenciosamente** se não houver consentimento. Aposentar a lógica de `pro_conversion` em `aso_analytics.dart`. |
| B1-14 | **Anúncios não personalizados até o consentimento** (`AdRequest(nonPersonalizedAds: true)`); após aceite, solicitação normal. A permissão `AD_ID` permanece declarada no manifesto (✅). |

### Contratos e dados
- Sem novo modelo de domínio. `SharedPreferences`: removem-se as chaves de B1-05; acrescentam-se
  `consent_decided` (bool) e `analytics_enabled` (bool).
- `AdManager`: remover o parâmetro/checagem de PRO (`shouldShowAds`); expor
  `showInterstitialOnExit()` que aplica B1-10c.

### Critérios de aceite técnicos
- `grep -rn "ProUtils\|PurchaseService\|OfflineService\|in_app_purchase" lib pubspec.yaml` retorna vazio.
- Com 101 cálculos salvos, existem exatamente 100, e o mais antigo foi descartado.
- Abrir o Resultado **não** dispara intersticial; sair dele dispara no máximo um por sessão e por 3 min.
- Sem consentimento: nenhum evento sai (inspecionável no DebugView) e a requisição é não personalizada.
- `flutter analyze` e `flutter test` verdes; APK de release gera sem `BILLING`.

**Riscos:** regressão em telas que dependem do `FutureBuilder` de `ProUtils`; perda do histórico se a
serialização mudar (mitigação: B1 não altera o JSON do histórico).

---

## B2 — Núcleo de cálculo: modelo, correções e `Decimal`

**Change:** `fix-calculation-rules` (B2-01..12) e `migrate-money-to-decimal` (B2-13..15, só começa com golden real, B6-06) · **PRD:** §6.2–6.3, §6.5, §6.7, Q1–Q3, Q7, Q9, Q11, Q22 · **Persona:** ambas

**Objetivo técnico:** tornar o cálculo **data-driven, identificável e preciso**, corrigir C1–C5 e
entregar o resultado com dois totais e premissas.

### B2.1 Identidade de verba e regras por tipo

| ID | Requisito |
|---|---|
| B2-01 | **Identidade de verba (D8):** `BreakdownItem` ganha `code` (enum `BreakdownCode`: `salaryBalance`, `notice`, `noticeDiscount`, `thirteenth`, `accruedVacation`, `proportionalVacation`, `fgtsFine`, `inss`, `irrf`, `otherDiscounts`, …). Nenhuma lógica pode depender do texto de `description`. Remover os `removeWhere(item.description == …)` e `.contains('Férias')` do use case. |
| B2-02 | **Regras por tipo em tabela**, não em `if` espalhados: um `TerminationRules` imutável por `TerminationType` que espelha a matriz do PRD §6.1: fator do aviso (1,0 / 0,5 / 0), taxa da multa FGTS (0,4 / 0,2 / 0), paga 13º, paga férias proporcionais, paga férias vencidas, aviso descontável, indenização 479, desconto 480. `TerminationType` perde os booleanos soltos (`hasFgtsPenalty`, `hasReducedNotice`, …) ou os deriva dessa tabela. |
| B2-03 | O use case deixa de remover itens depois de adicioná-los (padrão atual para justa causa/acordo): decide **antes**, pelas regras de B2-02. |

### B2.2 Correções de regra (⚖️ validar em B6 antes de publicar)

| ID | Correção | Observação técnica |
|---|---|---|
| B2-04 | **C1** Justa causa paga férias vencidas | Remove `type != withJustCause` da condição de férias vencidas; proporcionais continuam ✖. |
| B2-05 | **C2** Aviso indenizado projeta tempo | Para tipos com aviso indenizado, soma à contagem de avos de 13º e férias proporcionais `+1 mês` mais `+1 mês` por 30 dias adicionais do aviso (aviso de 30–59 dias → +1; 60–89 → +2; 90 → +3). No acordo mútuo, a projeção segue a duração do aviso (⚖️). Registrar a projeção em Premissas (B2-10). |
| B2-06 | **C3** Férias proporcionais pelo período aquisitivo | Avos contados desde o último aniversário da admissão (fim da responsabilidade em B3); o 13º continua por ano-calendário. Até B3 existir, extrair o cálculo de avos de férias para função própria, já com a regra correta. |
| B2-07 | **C4** Férias indenizadas sem IRRF e sem INSS | Em `TaxTablesService.calculateTerminationTaxes`, `vacationAmount` deixa de compor a base de IRRF. |
| B2-08 | **C5** INSS do 13º separado do salário | Duas apurações independentes, cada uma com a tabela progressiva e o teto próprios; `inss = inssSalário + inss13º`. |

### B2.3 Resultado: dois totais e premissas

| ID | Requisito |
|---|---|
| B2-09 | `TerminationResult` passa a expor **`paidAtTermination`** (soma dos proventos pagos − descontos), **`fgtsDeposit`** (lista de itens e total: multa 40 %/20 %) e as listas atuais. Hoje `netAmount` inclui a multa (D10); o novo `paidAtTermination` **não** a inclui. Manter `netAmount` apenas se necessário como alias **deprecado** até B5 migrar a UI. |
| B2-10 | **Premissas:** `TerminationResult.assumptions: List<Assumption>` com `code`, `texto`, `origem` (`informado` \| `estimado`) e `valor?`. Mínimo: FGTS estimado vs informado, projeção do aviso (C2), avos de 13º e de férias, mês de 30 dias, regra de ≥ 15 dias. |
| B2-11 | **Histórico compatível:** `CalculationHistory.toJson` ganha `schemaVersion` (inteiro). `fromJson` aceita registros **sem** `schemaVersion` (legado) e sem os novos campos, preenchendo com vazios; a UI marca registros legados como "calculado em versão anterior" quando os totais não forem recalculáveis. Nunca descartar silenciosamente um item (hoje o `HistoryRepository` ignora item que falha ao decodificar). |
| B2-12 | O `TerminationType.values.firstWhere(...)` em `CalculationHistory.fromJson` não tem `orElse`. Adicionar `orElse` e **mapear nomes antigos** (ex.: `fixedTerm` → `fixedTermEnd`, ver B4-02) para não perder histórico ao renomear o enum. |

### B2.4 Precisão (`Decimal`) — **só depois dos testes golden**

| ID | Requisito |
|---|---|
| B2-13 | Introduzir `Decimal` (`package:decimal`, já no `pubspec`) em `domain/`. Cálculo interno todo em `Decimal`/`Rational`; divisões convertidas com escala explícita; **arredondamento half-up a 2 casas por item**, como hoje (`_roundCurrency`), aplicado nos mesmos pontos. |
| B2-14 | Fronteiras convertem para `double` (apresentação, `toJson`); o JSON do histórico continua com números. `TerminationInput` mantém `double` na borda e converte na entrada do use case. |
| B2-15 | **Critério de migração:** os testes golden (B6) passam **antes** da troca para `Decimal` (tolerância 0,01) e **depois** dela (tolerância 0,00, B2-13), sem alterar os valores esperados. Divergência de centavos entre as duas versões deve ser explicada, e quem está certo é o documento oficial. |

### Módulos afetados
`lib/domain/usecases/calculate_termination.dart`, `lib/domain/entities/{termination_type,termination_result,breakdown_item,calculation_history,termination_input}.dart`,
`lib/core/services/tax_tables_service.dart`, `lib/data/repositories/history_repository.dart`,
`assets/config/tax_tables.json` (sem mudança de dados esperada).

### Critérios de aceite técnicos
- Nenhuma comparação por `description` no use case (busca textual vazia).
- Para cada caso golden do bloco, `Σ itens = totais` e cada verba bate com o documento de referência.
- Registros de histórico gravados na versão 1.0.x continuam abrindo.
- `paidAtTermination + fgtsDeposit` reproduz o antigo `netAmount` nos casos sem alteração de regra.

**Riscos:** C2–C5 interpretam a lei (⚖️); a migração para `Decimal` altera centavos silenciosamente; o
histórico antigo exibe totais com a semântica antiga.

---

## B3 — Períodos de férias e férias em dobro

**Change:** `add-vacation-periods` · **PRD:** §6.4, Q8, Q24, Q25 · **Persona:** ambas

**Objetivo técnico:** substituir o booleano "férias vencidas" por um modelo de períodos **derivado da
admissão**, com pagamento simples e em dobro.

| ID | Requisito |
|---|---|
| B3-01 | **Entrada:** `TerminationInput.hasAccruedVacation` (bool) → `vacationPeriodsTaken` (int ≥ 0). `fromJson` tolerante: registros antigos sem o campo assumem 0, e o legado `hasAccruedVacation = true` vira "1 período vencido" apenas para **exibição** do histórico (⚖️ sem recalcular). |
| B3-02 | **Função pura** `VacationPeriods.derive(admission, termination, taken)` em `domain/`, retornando para cada período: início e fim aquisitivo, fim do concessivo e `status ∈ {simples, dobro, proporcional}`. Sem I/O. |
| B3-03 | **Algoritmo:** com `n = anos completos entre admissão e rescisão`; período `i` (1…n) tem aquisitivo `[A+(i−1)a, A+i·a)` e concessivo até `A+(i+1)a`; `i ≤ taken` → gozado; `i > taken` e rescisão antes do fim do concessivo → **simples**; rescisão após o fim do concessivo → **dobro**; o período em curso (após `A+n·a`) é **proporcional**. Tratar 29/02 e admissões no fim do mês (⚖️ regra de ancoragem). |
| B3-04 | **Valores:** simples `= base × 4/3`; dobro `= 2 × base × 4/3` (1/3 sobre o total dobrado, Súmula 328 TST); `base = salário + média`. Proporcional: avos do período em curso + projeção do aviso (B2-05), com 1/3. |
| B3-05 | Itens do resultado: `BreakdownCode.accruedVacationSimple`, `accruedVacationDouble` e `proportionalVacation`, em **linhas separadas**; o dobro rotulado como indenização. Sem IRRF/INSS (B2-07). Vale para todos os tipos de rescisão (B2-02). |
| B3-06 | **Formulário:** campo "Períodos de férias já gozados" com *stepper* limitado a `n` (calculado das datas); recalcular o limite ao mudar as datas. Mostrar aviso: férias fracionadas, abono e férias parcialmente gozadas **não** são tratadas. |
| B3-07 | **Premissas:** tabela de períodos derivados (B3-02) em Premissas (B2-10), conferível pelo usuário; marcar o que é "dobro". |
| B3-08 | **Validação (B2-13):** tetos coerentes (`taken ≤ n`); datas inconsistentes seguem o `TerminationInputValidator` (✅). |

**Critérios de aceite técnicos:** casos de borda cobertos por teste (admissão em 29/02; rescisão exatamente no
aniversário; concessivo expirando no dia; `taken = n`; `n = 0`); o dobro nunca aparece quando o concessivo não
expirou; nenhum teste depende do ano-calendário atual (datas fixas ou relógio injetado).

**Riscos:** ancoragem das datas (⚖️); histórico legado; o formulário ficar longo (o PRD pede mínimo de atrito).

---

## B4 — Contratos a prazo e rescisão indireta

**Change:** `add-fixed-term-and-indirect` · **PRD:** §6.1, §6.6, Q23, Q26, Q27 · **Persona:** ambas

| ID | Requisito |
|---|---|
| B4-01 | `TerminationType` ganha: `indirectTermination`, `fixedTermEnd`, `fixedTermEarlyByEmployer`, `fixedTermEarlyByEmployee`. Entradas do `TerminationRules` (B2-02) conforme a matriz do PRD §6.1. |
| B4-02 | **Compatibilidade:** `fixedTerm` (valor antigo) permanece apenas como **alias de leitura** do histórico → mapeado para `fixedTermEnd` (B2-12). A UI não o oferece mais. |
| B4-03 | **Entrada nova:** `fixedTermEndDate` (obrigatória nos três tipos a prazo) e `hasRecipientClause` (cláusula assecuratória, art. 481). Validações: data fim > admissão; rescisão ≤ fim previsto nos tipos "antecipada"; tipo "término normal" exige rescisão ≈ fim previsto (aviso, não bloqueio). |
| B4-04 | **Assecuratória ativa:** na rescisão antecipada passa a valer o `TerminationRules` do contrato por prazo indeterminado equivalente (empregador → sem justa causa; empregado → pedido de demissão), com aviso prévio. |
| B4-05 | **Art. 479:** `indenização = (salário + média) / 30 × dias restantes × 50 %`, com `dias restantes = fixedTermEndDate − terminationDate` (⚖️ convenção de contagem de dias). Item `BreakdownCode.indemnity479`, em provento, **sem IRRF e sem INSS**. Mantém multa de 40 % (B2-02). |
| B4-06 | **Art. 480:** `desconto = min(valor do art. 479, 1 remuneração mensal)` (art. 477 §5º). Item `BreakdownCode.indemnity480` em desconto, **fora da base de impostos**. O resultado exibe o aviso *"valor máximo; depende de comprovação do prejuízo"*. Sem multa de 40 %. |
| B4-07 | **Término normal:** sem aviso e **sem multa**; com 13º, férias proporcionais, saque do FGTS (linha informativa). |
| B4-08 | **Rescisão indireta:** mesmas regras do "sem justa causa". Implementada pela tabela de regras (B4-01), sem ramificação nova no use case. |
| B4-09 | **Formulário:** campos de B4-03 aparecem **somente** nos tipos a prazo; `TerminationTypeCard` lista os tipos novos com a descrição em linguagem simples (sem juridiquês). |

**Critérios de aceite técnicos:** nenhuma condicional por tipo fora da tabela de regras (busca por
`type ==` no use case retorna vazio); testes por tipo e por combinação com a cláusula assecuratória; o
desconto do 480 nunca excede 1 remuneração; os registros antigos de `fixedTerm` abrem.

**Riscos:** interpretação do art. 479/480 (⚖️); contagem de dias; o PRD admite o plano B "cálculo em
validação" se não houver revisão (B6-04).

---

## B5 — Resultado, compartilhamento e PDF

**Change:** `result-assumptions-and-two-totals` (a UI do resultado herda o modelo de B2) · **PRD:** §6.5, §7, Q1, Q3, Q11

| ID | Requisito |
|---|---|
| B5-01 | `ResultScreen` exibe dois totais — **"Pago na rescisão"** e **"Depositado no FGTS"** — com linha informativa de saque (100 % sem justa causa e indireta; 80 % acordo mútuo; informativo, sem valor calculado). |
| B5-02 | Seção **"Premissas desta estimativa"** recolhível (fechada por padrão). Marcador "estimado" ao lado de valores aproximados (ex.: FGTS). |
| B5-03 | `ShareUtils.generateShareText`/`generateSimpleShareText` e `PdfUtils._generatePdf` espelham a **mesma estrutura**: dois totais + premissas (no resumo, apenas os dois totais). |
| B5-04 | O aviso legal permanece nas telas atuais (Home, Formulário, Resultado, Histórico), com texto alinhado ao PRD §6.8. |
| B5-05 | Texto do compartilhamento sem dado pessoal além do próprio cálculo; nenhuma marca de "versão PRO". |
| B5-06 | A tela de histórico abre um registro usando a mesma `ResultScreen`; registros legados exibem a marca de B2-11. |

**Critérios de aceite técnicos:** testes de widget para o resultado (dois totais visíveis, premissas
recolhidas por padrão) e testes de texto para compartilhamento e PDF contendo os dois totais.

---

## B6 — Validação e infraestrutura de testes golden

**PRD:** §11, Q10, Q28 · **Bloqueia B2–B4.**

| ID | Requisito |
|---|---|
| B6-01 | Criar `test/golden/cases/*.json`. Cada arquivo: `fonte` (TRCT anonimizado, calculadora de referência ou exemplo manual validado), `tipo`, `entrada` (admissão, rescisão, salário, média, dependentes, FGTS, períodos gozados, fim previsto, cláusula) e `esperado` (valor por `code` de verba e totais). |
| B6-02 | Um único *runner* (`test/golden/golden_test.dart`) carrega todos os casos e compara cada verba. Antes de B2-13: tolerância de 0,01. **Depois:** 0,00. |
| B6-03 | O resultado esperado vem **sempre do documento externo**, nunca da saída do app. Casos sem fonte não entram. |
| B6-04 | **Plano B:** regras cujo caso golden ainda não existe (art. 479/480, férias em dobro) saem com um `Assumption` do tipo "cálculo em validação" visível na tela. Remover a marca quando houver fonte. |
| B6-05 | Cobertura mínima antes de publicar B2: um caso por tipo de rescisão ativo e por verba corrigida (C1–C5). Antes de B3/B4: os exemplos manuais confirmados por contador. |
| B6-06 | **Pendências do responsável (bloqueiam a publicação, não o código):** fornecer TRCTs reais anonimizados; contador para os exemplos manuais. |

---

## B7 — Conformidade, privacidade e operação

Não é código de app, mas gate de publicação. Itens fora do repositório de código têm dono explícito.

| ID | Requisito | Onde |
|---|---|---|
| B7-01 | **Política de privacidade** reescrita: AdMob (ID de publicidade), Analytics/Crashlytics sob consentimento, ausência de dado pessoal no cálculo. Hoje afirma "não coleta dados". | `README.md` (página do GitHub Pages) |
| B7-02 | **Data Safety** da Play alinhada a B7-01 e declaração **"contém anúncios"**. | Play Console |
| B7-03 | **Desativar** o produto `calc_recisao_pro_monthly` (sem assinantes). | Play Console |
| B7-04 | Listagem da loja sem qualquer menção a PRO, PDF "exclusivo" ou histórico "ilimitado". | Play Console |
| B7-05 | Confirmar e unificar o e-mail de contato (política × app). | `README.md`, `AppConstants.supportEmail` |
| B7-06 | **Manutenção anual** das tabelas (checklist do PRD §13): JSON, teste do ano, listagem. | `assets/config/tax_tables.json` |
| B7-07 | Specs de compliance Android (`android-target-sdk`, 16 KB) preservadas; prazo da Play 31/08/2026 já atendido. | `openspec/` |

**Gate:** B1 não é publicada sem B7-01, B7-02 e B7-04 concluídos.

---

## 2. Fora do escopo (todas as specs)

Dos PRD §5.3: aposentadoria, falecimento, empregado doméstico/rural, estabilidades, horas extras e
adicionais detalhados, 13º adiantado, **férias fracionadas, abono pecuniário e férias parcialmente
gozadas**, múltiplos vínculos. Tecnicamente também fora: backend, sincronização, contas de usuário,
internacionalização para en-US (o `supportedLocales` declara, mas a tradução não existe).

---

## 3. Dívidas técnicas e onde são resolvidas

| Dívida (ARCHITECTURE §9) | Resolvida em |
|---|---|
| D1 dinheiro em `double` | B2-13…15 |
| D2 status PRO local | B1-01 (extinto) |
| D3 Firebase não inicializado | B0-06 |
| D4 telas grandes | oportunista; extrair widgets ao tocar `result_screen`/`form_screen` (B3-06, B5) |
| D5 strings hardcoded / l10n manual | B0-07 (parcial); migração completa fica **fora** desta fase |
| D6 singletons estáticos | parcial: `TaxTablesService` e relógio injetável nos testes de B3 |
| D7 `OfflineService` morto | B1-01 |
| D8 descrição como chave | B2-01 |
| D9 intersticial cobre o resultado | B1-10b |
| D10 total mistura multa FGTS | B2-09, B5-01 |
| D11 modelo de férias | B3-01…07 |

---

## 4. Questões abertas

- **Dias restantes do art. 479:** contar inclusive o dia da rescisão? (⚖️ B4-05)
- **Âncora das datas de período** em admissões em 29/02 ou fim de mês. (⚖️ B3-03)
- **Projeção do aviso no acordo mútuo:** segue a duração do aviso de 50 % ou o aviso integral? (⚖️ B2-05)
- **Histórico legado:** recalcular sob as regras novas ou apenas marcar como "versão anterior"? (B2-11)
- **Banner no Onboarding:** a decisão Q16a diz "todas as telas, menos Formulário e Splash", o que inclui o Onboarding; confirmar se isso é desejado, já que é a primeira impressão do app. (B1-10a)
- **`netAmount` deprecado:** existe consumidor fora da UI/PDF/compartilhamento que dependa dele? (B2-09)
