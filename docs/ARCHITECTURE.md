# ARCHITECTURE

> Fonte de verdade técnica do projeto **Calculadora de Rescisão CLT** (`calc_recisao`).
> Descreve stack, arquitetura, convenções e dívidas técnicas conhecidas.
> Decisões de produto e regras de negócio ficam em [PROJECT.md](PROJECT.md).
>
> **Regra de manutenção:** este documento descreve o que o código *faz hoje*. Se uma mudança altera
> camadas, dependências, fluxo de dados ou convenções, atualize este arquivo no mesmo commit.
> Itens marcados com ⚠️ são divergências entre intenção e código — não os trate como verdade.
>
> **Estado atual × alvo.** Este documento descreve o código **de hoje**. Onde o PRD
> ([PROJECT.md](PROJECT.md)) já decidiu uma mudança ainda não implementada, ela aparece marcada com 🎯.
> ✅ A change `remove-pro-ads-only` (B1) já **extinguiu o PRO**: o app é gratuito, com AdMob, consentimento
> único e analytics opt-in (§5.3, §7, §10).

---

## 1. Visão geral

App Flutter **offline-first**, sem backend próprio. Todo o cálculo roda no dispositivo e os dados
(histórico, preferências) ficam em `SharedPreferences`. Monetização: AdMob. ✅ App **100 % gratuito, só com anúncios** (sem assinatura nem compras in-app).

| Item | Valor |
|---|---|
| Application ID | `com.caiodeiro.calcclt` |
| Versão atual | `1.0.11+13` (`pubspec.yaml`) |
| Plataforma-alvo | **Mobile apenas** (Android principal; iOS como scaffold, sem compra in-app). Sem Web/Desktop |
| Dart SDK | `^3.8.1` |
| Android | `minSdk 24`, `compileSdk 36`, `targetSdk 36` |
| Idiomas | pt-BR (principal), en-US declarado em `supportedLocales` |
| Tema | Material 3, claro/escuro via `ThemeMode.system` |

---

## 2. Stack e dependências

Versões reais de `pubspec.yaml`. Antes de adicionar uma dependência, confirme que ela é necessária
e atualize esta tabela.

### Runtime

| Pacote | Uso | Observações |
|---|---|---|
| `flutter_localizations` / `intl` | Datas, moeda, locale | Localização **manual** em `lib/l10n/` (não usa `gen-l10n`/ARB) |
| `shared_preferences` | Persistência única do app | Histórico, onboarding, consentimento, controle do intersticial, contadores locais |
| `google_mobile_ads` | Banner e intersticial | Banner adaptativo e intersticial para todos; formulário de consentimento UMP; anúncios não personalizados até o aceite |
| `pdf` + `printing` | Exportação de PDF (todos os usuários) | `core/utils/pdf_utils.dart` |
| `share_plus` | Compartilhar resultado | `core/utils/share_utils.dart` |
| `url_launcher` | E-mail de suporte, links | |
| `path_provider` | Salvar PDF em arquivo | |
| `firebase_core` + `firebase_crashlytics` | Relato de erros não-fatais | Inicializados no `main`; coleta desligada por padrão e ligada só após o aceite (§7) |
| `firebase_analytics` | 4 eventos mínimos | Só com consentimento, via `core/analytics/analytics_service.dart` (PROJECT.md §9) |
| `decimal` | — | ⚠️ declarado, **não usado**. 🎯 Passa a ser o tipo do dinheiro no domínio (change `migrate-money-to-decimal`, depois dos testes golden) |
| `cupertino_icons` | Ícones | |


### Dev

`flutter_test`, `flutter_lints ^6`, `mockito`, `build_runner`, `golden_toolkit`, `flutter_launcher_icons`.

### O que o projeto **não** usa (de propósito)

Sem gerenciador de estado externo (Provider/Bloc/Riverpod), sem injeção de dependência (get_it),
sem roteador declarativo (go_router), sem backend/API. Qualquer adoção disso é uma **decisão
arquitetural** e deve ser registrada em §10.

---

## 3. Estrutura de pastas

```
lib/
├── main.dart                  # bootstrap: inicializa serviços e roda App
├── app.dart                   # MaterialApp, tema, localização, home = SplashScreen
├── core/                      # infraestrutura transversal (sem regra de negócio de rescisão)
│   ├── ab_testing/            # aso_ab_testing.dart (experimentos ASO locais)
│   ├── ads/                   # ad_manager.dart, ad_ids.dart
│   ├── analytics/             # analytics_service (ponto central), analytics_sink, consent_service, aso_analytics (contadores locais)
│   ├── constants/             # app_constants.dart — única fonte de "magic numbers"
│   ├── deep_links/            # aso_deep_links.dart
│   ├── exceptions/            # hierarquia AppException
│   ├── services/              # tax_tables, onboarding, support, legacy_cleanup
│   ├── theme/                 # app_theme.dart (light/dark)
│   ├── utils/                 # logger, formatters, pdf, share, responsive, connectivity
│   └── validators/            # termination_input_validator.dart
├── data/
│   └── repositories/          # history_repository.dart
├── domain/
│   ├── entities/              # TerminationInput/Result/Type, BreakdownItem/BreakdownCode, Assumption, CalculationHistory
│   ├── rules/                 # termination_rules.dart (tabela por tipo), avos.dart (13º, férias, projeção, âncora de meses), vacation_periods.dart (períodos de férias)
│   └── usecases/              # calculate_termination.dart
├── l10n/                      # AppLocalizations manual (pt)
└── presentation/
    ├── screens/               # splash, onboarding, home, form, result, history, support, about
    └── widgets/               # componentes reutilizáveis (cards, campos de moeda/data, disclaimer, banner de anúncio, aviso de consentimento)

assets/config/tax_tables.json  # tabelas INSS/IRRF/aviso prévio/dependente versionadas por ano
test/{unit,widget,integration,mocks,test_helpers}
openspec/{specs,changes}       # specs de compliance Android/Play (fluxo spec-driven)
docs/                          # documentação do projeto (este arquivo e PROJECT.md)
```

---

## 4. Camadas e regras de dependência

Estilo **Clean Architecture simplificada**, com três camadas + `core` transversal.

```
presentation  ──►  domain  ◄──  data
      │              ▲            │
      └──────► core ◄┴────────────┘
```

| Camada | Pode depender de | Não pode depender de |
|---|---|---|
| `domain` | Dart puro, `core/constants`, `core/exceptions`, `core/utils/logger`, `core/services/tax_tables_service` | Widgets, `BuildContext`, SharedPreferences direto |
| `data` | `domain`, `core` | `presentation` |
| `presentation` | `domain`, `data`, `core` | — |
| `core` | Nada acima dele (exceto entidades de `domain` em `offline_service`) | `presentation` |

⚠️ **Violações conhecidas das regras acima** (não replique; corrija quando tocar):
- `domain/usecases/calculate_termination.dart` depende do singleton `TaxTablesService` (`core`) e de
  `AppLogger`. Aceitável porque as tabelas são dado de configuração, mas impede testar o use case
  sem carregar o JSON — os testes hoje carregam a tabela real.
- `data/repositories/history_repository.dart` consulta `ProUtils` (regra de produto: limite de
  histórico) em vez de receber o limite por parâmetro.

---

## 5. Fluxo de dados principal

### 5.1 Cálculo de rescisão

```
FormScreen ──(valida)──► TerminationInputValidator
    │
    ▼
TerminationInput + TerminationType
    │
    ▼
CalculateTermination.execute()          ← domain/usecases (função pura, síncrona)
    ├─ regras por tipo de rescisão      ← `TerminationRules` (tabela imutável) + `avos.dart`; ver PROJECT.md §6
    ├─ TaxTablesService.calculateTerminationTaxes()  ← INSS/IRRF por data da rescisão
    └─ retorna TerminationResult { additions[], deductions[], paidAtTermination, fgtsDeposit, assumptions[], totalDeductions }
    │
    ▼
ResultScreen ──► HistoryRepository.save() ──► SharedPreferences
             ├─► ShareUtils (texto)   ┐ ambos usam `buildResultSections` (core/utils/result_content.dart):
             └─► PdfUtils (todos)     ┘ mesma ordem da tela, premissas só no completo
HistoryScreen ──► ResultScreen.fromHistory(registro)   ← resultado salvo: sem use case, sem gravar, sem evento
```

- O resultado é uma lista de `BreakdownItem` (`addition`/`deduction`), cada um com `BreakdownCode` (nunca
  use `description` como chave) — a UI renderiza o *breakdown* sem recalcular. A multa do FGTS fica em
  `fgtsDeposit`; as telas, o PDF e o texto compartilhado a leem de lá.
- Histórico: `schemaVersion` 2; registro sem versão é legado (itens `BreakdownCode.legacy`, marcado
  "calculado em versão anterior", sem recalcular). Registro ilegível é preservado e contado
  (`HistoryRepository.unreadableCount`); nomes antigos de tipo passam pela tabela de aliases. O registro legado guarda
  só `legacyNetAmount` (valor salvo, sem inferir `paidAtTermination`); o JSON novo não grava `netAmount`.
- Resultado: `fgtsWithdrawalPercent` (linha informativa de saque) vem de `TerminationRules`, sem `switch` por tipo na UI.
  Widgets em `presentation/widgets/result_summary.dart`; todo elemento tocado por fluxo E2E tem `Semantics.identifier`
  (`result_*`, `history_*`, `form_*`, `home_*`). **Princípio de produto: transparência.** Não esconda itens do cálculo.
- Erros de cálculo viram `CalculationException` (mensagem amigável + `originalError`).

### 5.2 Tabelas fiscais

`assets/config/tax_tables.json` contém, por chave de ano/período (`inss_2025`, `inss_2026`,
`irrf_2025_jan_abr`, …), faixas, alíquotas, deduções, teto, regras de aviso prévio e dedução por
dependente. `TaxTablesService` (singleton, `loadTaxTables()` no boot) escolhe a tabela pela **data
da rescisão**, não pela data atual.

> **Atualização anual** é a manutenção mais crítica do app. Ao mudar uma tabela: editar o JSON,
> adicionar/ajustar o teste em `test/unit/termination_<ano>_test.dart` e `tax_tables_service_test.dart`.

### 5.3 Anúncios, consentimento e limites

- **Sem PRO.** PDF liberado; histórico com teto de `AppConstants.maxHistorySize` (100) em FIFO
  (`HistoryRepository.saveCalculation`); aviso discreto na tela de Histórico a partir de 90 itens.
- **Banner adaptativo** (`presentation/widgets/ad_banner.dart`, em `Scaffold.bottomNavigationBar`) em Home,
  Resultado, Histórico, Suporte e Sobre; ausente em Formulário, Splash e Onboarding.
- **Intersticial** (`AdManager.showInterstitialOnExit`): só ao **sair** do Resultado (`PopScope`) e ao concluir
  compartilhar/exportar; nunca ao entrar. Pré-carregado; 1 por sessão (flag em memória) e 1 a cada 3 min
  (`last_interstitial_time`); não é exibido antes da decisão de consentimento. Sem recompensado.
- **Consentimento único** (`presentation/widgets/consent_prompt.dart`): ao primeiro retorno à Home depois do
  primeiro resultado (`first_result_done`), UMP + escolha de analytics; persiste `consent_decided` e
  `analytics_enabled`. Antes do aceite os anúncios usam `AdRequest(nonPersonalizedAds: true)`.
- **Analytics** (`core/analytics/analytics_service.dart`): único ponto de emissão; descarta tudo sem
  consentimento; só `calc_completed{tipo_rescisao}`, `share_used`, `pdf_exported`, `consent_decision`.
  `consent_decision` só chega a sair quando `aceitou` (sem consentimento nada sai).
  Nomes definidos na implementação: parâmetro `decisao` (`aceitou`|`recusou`) em `consent_decision` e chave
  `first_result_done` (marca o primeiro resultado, gatilho do aviso).
- **Gate do intersticial:** `AdManager` não exibe intersticial antes de `consent_decided`; logo, o intersticial
  da primeira saída do Resultado é omitido (o aviso de consentimento vem antes de qualquer anúncio de tela cheia).

### 5.4 Persistência (chaves principais de `SharedPreferences`)

| Chave | Dono | Conteúdo |
|---|---|---|
| `calculation_history` | `HistoryRepository` | `List<String>` de JSON de `CalculationHistory` |
| `last_interstitial_time` | `AdManager` | controle do cooldown de 3 min |
| `first_result_done`, `consent_decided`, `analytics_enabled` | `ConsentService` | consentimento único (B1-11) |
| `install_source`, `first_open`, `session_count` | `AsoAnalytics` | métricas **locais** |

As chaves da antiga versão PRO (`is_pro_user`, `pro_purchase_*`, `offline_cache`, `pending_sync`, `pro_conversion`) são
removidas no boot por `LegacyCleanup` (idempotente).

---

## 6. Gerenciamento de estado, navegação e UI

- **Estado:** `StatefulWidget` + `setState`, com serviços estáticos/singletons. Sem camada de
  ViewModel. Telas grandes (`form_screen`, `result_screen`, `home_screen`) concentram lógica de UI —
  extraia widgets ao tocá-las.
- **Navegação:** `Navigator.push(MaterialPageRoute)` imperativo. Fluxo:
  `Splash → (Onboarding, 1ª vez) → Home → Form → Result`; `Home → History | Support | About`.
- **Design system:** definido em `DESIGN.md` (raiz) e implementado em `core/theme/app_theme.dart`
  (azul `#1976D2`, Roboto, raios 8/12/16). Não crie cores/estilos soltos nos widgets.
- **Localização:** strings em `lib/l10n/app_localizations_pt.dart`. Muita string de domínio ainda é
  *hardcoded* em português (ex.: descrições do `BreakdownItem` no use case, `TerminationType.label`).
- **Responsividade:** `core/utils/responsive_helper.dart`.

---

## 7. Tratamento de erros e observabilidade

- Hierarquia `AppException` → `CalculationException`, `ValidationException` (com `fieldErrors`),
  `StorageException`, etc. (`core/exceptions/`). Camadas inferiores lançam exceções tipadas; a UI
  traduz para mensagem amigável (`AppConstants.*ErrorMessage`).
- `AppLogger` (`core/utils/logger.dart`) centraliza logs e tenta relatar ao Crashlytics de forma
  defensiva (ignora se Firebase indisponível).
- **Privacidade:** nunca logar/enviar salário, datas ou resultado. A política de privacidade afirma
  que **nenhum dado pessoal é coletado** — qualquer telemetria nova precisa revisar esse texto.
  ✅ Telemetria (Analytics e Crashlytics) só **após consentimento opt-in**, pedido uma única vez depois do
  primeiro resultado, junto com o UMP dos anúncios. Anúncios **não personalizados** até o consentimento.
  Firebase é inicializado no `main`; coleta desligada no manifesto e no boot. ⚠️ A política de privacidade
  (`about_screen.dart`, site) foi atualizada na rodada 2 (texto a revisar pelo usuário).
- `AsoAnalytics` e `AsoAbTesting` são **contadores locais**; nada sai do aparelho.

---

## 8. Testes e qualidade

| Pasta | Foco |
|---|---|
| `test/unit/` | Regras de cálculo (`calculate_termination`, `edge_cases`, `termination_2026`, `comprehensive_termination_review`), validação, repositório (FIFO de 100), limpeza legada, `AdManager`, analytics, PDF, logger, onboarding |
| `test/widget/` | Onboarding, banner por tela, aviso de histórico cheio, aviso de consentimento, Resultado (dois totais, premissas, validação, legado), histórico abre o resultado salvo, aviso legal nas 4 telas |
| `test/integration/` | Fluxo de cálculo ponta a ponta |
| `test/golden/` | Infra de casos golden (B6): `cases/*.json` (oráculo externo, um arquivo por caso), `support/` (loader, comparador por `item.code.name`, `goldenTolerance`), `golden_test.dart` (runner único), `validation_status.dart` (regras ⚖️ pendentes), `coverage_test.dart` (gate `release-gate`). Hoje sem casos reais (pendência B6-06) |
| `test/mocks`, `test_helpers/` | Setup de `SharedPreferences` |
| `.maestro/` | E2E Maestro por jornada (`tests/first_run`, `tests/returning`), seletores por `Semantics.identifier` (sem coordenadas, sem `hideKeyboard`). Subfluxos não definem defaults de `env`. Tag `seeded` fica fora da suíte padrão (`excludeTags` em `config.yaml`): rode `.maestro/utils/seed_history.sh` (escreve o `SharedPreferences` do APK debug via `run-as`, frágil ao formato do plugin) e depois o fluxo, sem `clearState` |

Comandos:

```bash
flutter pub get
flutter analyze          # lints: flutter_lints (analysis_options.yaml)
flutter test             # toda a suíte
flutter test test/unit/termination_2026_test.dart   # um arquivo
flutter test --tags release-gate --run-skipped      # gate de cobertura golden (B6-05)
```

**Checklist de publicação:** antes de publicar a change B2 (e os exemplos de contador antes de B3/B4),
rodar `flutter test --tags release-gate --run-skipped`. Ele fica fora do `flutter test` padrão
(`dart_test.yaml`) e falha enquanto faltar caso golden na matriz (tipos de rescisão, C1–C5, regras ⚖️).
Caso golden só entra com `fonte` (TRCT, calculadora oficial gov.br/MTE com URL e data, ou exemplo de contador);
o esperado nunca vem da saída do app. Dica: `flutter test --concurrency=1` se o compilador cair por memória.

**Definição de pronto para mudanças em cálculo:** teste novo cobrindo o caso, `flutter analyze`
limpo, `flutter test` verde. Mudança de regra trabalhista exige citar a base legal no commit/PR.

---

## 9. Build, release e compliance Android

- Assinatura de release configurada em `android/app/build.gradle.kts` (keystore fora do repositório).
- **Target SDK 36** e **páginas de 16 KB** são exigências da Play Console (prazo ≈ 31/08/2026) e
  estão especificadas em `openspec/specs/android-target-sdk` e `openspec/changes/android-16kb-page-size`.
- ✅ **Billing Library:** exigência extinta; `in_app_purchase*` foi removido e o manifesto não declara `BILLING`
  (a spec `play-billing` é arquivada junto com a change `remove-pro-ads-only`).
- Produto PRO (`calc_recisao_pro_monthly`): **desativar no Play Console** (não há assinantes).
- Firebase: config do projeto em `android/app` e plugin Gradle do Google Services; sem
  `firebase_options.dart` (Android usa a config nativa). ⚠️ iOS sem o arquivo plist do Firebase: o Firebase fica
  indisponível no iOS até ele ser adicionado (a inicialização falha em silêncio).
- Fluxo **spec-driven** com OpenSpec: mudanças de compliance entram em `openspec/changes/<nome>` e,
  ao serem arquivadas, viram `openspec/specs/<capability>/spec.md`.

### Dívidas técnicas conhecidas

| # | Dívida | Impacto | Sugestão |
|---|---|---|---|
| D1 | **Dinheiro em `double`**; `decimal` está no `pubspec` mas não é usado | Erros de arredondamento acumulados | Migrar o use case para `Decimal` ou inteiros em centavos |
| D2 | ~~Status PRO só local~~ | ✅ **Resolvida pela extinção do PRO** | `ProUtils`/`PurchaseService` removidos |
| D3 | ~~`Firebase.initializeApp()` não era chamado~~ | ✅ **Resolvida** (B0-06): inicializado no `main` com coleta desligada | Falta config iOS |
| D4 | Telas muito grandes, sem separação UI/lógica | Difícil testar e evoluir | Extrair widgets/controllers |
| D5 | Strings de domínio hardcoded; l10n manual | Bloqueia en-US real | Migrar para ARB/`gen-l10n` |
| D6 | Singletons estáticos (`TaxTablesService`, `AdManager`, `AnalyticsService`) | Testes dependem de estado global | Injeção simples por construtor nos use cases/repositórios |
| D7 | ~~`OfflineService` sem consumidor~~ | ✅ **Resolvida pela remoção** | — |
| D8 | ~~Descrições de itens do cálculo usadas como *chave*~~ ✅ **Resolvida** (B2-01): `BreakdownCode`; mantida a descrição só como texto de UI. Antes: (`removeWhere(item.description == ...)`) | Frágil a renomeações; piora com férias em dobro e art. 479/480 | Usar enum/ID no `BreakdownItem` **antes** de adicionar verbas |
| D9 | ~~Intersticial exibido ao renderizar o Resultado~~ | ✅ **Resolvida**: só ao **sair** do Resultado, ≤ 1/3 min e 1/sessão | — |
| D10 | ~~Cálculo e apresentação misturam "a receber" e multa do FGTS~~ | ✅ **Resolvida** (B2-09/10 e B5): `paidAtTermination`, `fgtsDeposit`, `assumptions` no domínio e na UI; alias `netAmount` removido | — |
| D11 | ~~`hasAccruedVacation` booleano e meses por ano-calendário~~ | ✅ **Resolvida** (B3): `vacationPeriodsTaken` (int) e `VacationPeriods.derive` (puro, `rules/vacation_periods.dart`) derivam períodos simples, em dobro e proporcional; legado `hasAccruedVacation` só preservado (`legacyHasAccruedVacation`, fora do cálculo) | — |

---

## 10. Registro de decisões arquiteturais (ADR resumido)

| Data | Decisão | Motivo |
|---|---|---|
| — (histórico) | Cálculo 100 % local, sem backend | Privacidade, custo zero de infra, velocidade |
| — (histórico) | `SharedPreferences` como único storage | Dados pequenos e simples; sem necessidade de SQL |
| — (histórico) | Sem gerenciador de estado externo | Escopo pequeno; evitar complexidade |
| — (histórico) | Tabelas fiscais em JSON versionado por ano | Atualizar lei sem alterar código |
| 2026 | Billing Library via plugin, sem override | Compliance Play (spec `play-billing`) |
| 2026 | Target SDK 36 + 16 KB pages | Exigência da Play Console |
| 2026-10 | ✅ **Extinguir o PRO; monetizar só com AdMob** | Simplicidade; público de uso pontual converte mal em assinatura; elimina compliance de Billing |
| 2026-10 | ✅ Intersticial só ao sair do Resultado; anúncios não personalizados até consentimento | Respeitar o momento do usuário; privacidade por padrão |
| 2026-10 | 🎯 Dinheiro em `Decimal`, após testes golden | Evitar erro de ponto flutuante com refatoração protegida |
| 2026-10 | ✅ Histórico limitado a 100 itens em `SharedPreferences` (FIFO) | Não degradar o armazenamento; migrar para SQLite se crescer |
| 2026-10 | 🎯 Execução em 4 changes OpenSpec sequenciais | Versões pequenas isolam regressões (ver PROJECT.md §15) |

> Novas decisões: acrescente uma linha (data, decisão, motivo). Se for grande, crie uma change
> em `openspec/changes/`.
