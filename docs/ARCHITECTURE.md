# ARCHITECTURE

> Fonte de verdade técnica do projeto **Calculadora de Rescisão CLT** (`calc_recisao`).
> Descreve stack, arquitetura, convenções e dívidas técnicas conhecidas.
> Decisões de produto e regras de negócio ficam em [PROJECT.md](PROJECT.md).
>
> **Regra de manutenção:** este documento descreve o que o código *faz hoje*. Se uma mudança altera
> camadas, dependências, fluxo de dados ou convenções, atualize este arquivo no mesmo commit.
> Itens marcados com ⚠️ são divergências entre intenção e código — não os trate como verdade.
>
> **Estado atual × alvo.** Este documento descreve o código **de hoje** (1.0.11+13). Onde o PRD
> ([PROJECT.md](PROJECT.md)) já decidiu uma mudança, ela aparece marcada com 🎯 e **ainda não está
> implementada**. A decisão mais estrutural: o **plano PRO será extinto** (monetização só com AdMob), o que
> remove compras in-app, `ProUtils`, `PurchaseService`, `OfflineService` e `ProScreen` (§10, change
> `remove-pro-ads-only`).

---

## 1. Visão geral

App Flutter **offline-first**, sem backend próprio. Todo o cálculo roda no dispositivo e os dados
(histórico, preferências) ficam em `SharedPreferences`. Monetização: AdMob. 🎯 **Hoje** ainda existe
assinatura PRO via Google Play Billing; **o alvo é um app 100 % gratuito, só com anúncios**.

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
| `shared_preferences` | Persistência única do app | Histórico, flag PRO, onboarding, cache offline, analytics local |
| `google_mobile_ads` | Banner e intersticial | Hoje só para não-PRO. 🎯 Para todos; adicionar o formulário de consentimento UMP |
| `in_app_purchase` + `in_app_purchase_android` | Assinatura PRO | 🎯 **Serão removidos** (PRO extinto). Hoje: Billing ≥ 8.0.0 vem do plugin (`openspec/specs/play-billing`, a arquivar) |
| `pdf` + `printing` | Exportação de PDF (PRO) | `core/utils/pdf_utils.dart` |
| `share_plus` | Compartilhar resultado | `core/utils/share_utils.dart` |
| `url_launcher` | E-mail de suporte, links | |
| `path_provider` | Salvar PDF em arquivo | |
| `firebase_core` + `firebase_crashlytics` | Relato de erros não-fatais | ⚠️ ver §9 (Firebase não é inicializado). 🎯 Sob consentimento opt-in |
| `firebase_analytics` | — | Comentado no `pubspec`. 🎯 Reativar com 4 eventos mínimos e consentimento (PROJECT.md §9) |
| `decimal` | — | ⚠️ declarado, **não usado**. 🎯 Passa a ser o tipo do dinheiro no domínio (change `fix-calculation-rules`, depois dos testes golden) |
| `cupertino_icons` | Ícones | |

`firebase_analytics` está comentado no `pubspec.yaml` por problema de build.

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
│   ├── analytics/             # aso_analytics.dart (contadores locais em SharedPreferences)
│   ├── constants/             # app_constants.dart — única fonte de "magic numbers"
│   ├── deep_links/            # aso_deep_links.dart
│   ├── exceptions/            # hierarquia AppException
│   ├── services/              # tax_tables, purchase, onboarding, offline, support
│   ├── theme/                 # app_theme.dart (light/dark)
│   ├── utils/                 # logger, formatters, pdf, share, pro_utils, responsive, connectivity
│   └── validators/            # termination_input_validator.dart
├── data/
│   └── repositories/          # history_repository.dart
├── domain/
│   ├── entities/              # TerminationInput/Result/Type, BreakdownItem, CalculationHistory
│   └── usecases/              # calculate_termination.dart
├── l10n/                      # AppLocalizations manual (pt)
└── presentation/
    ├── screens/               # splash, onboarding, home, form, result, history, pro, support, about
    └── widgets/               # componentes reutilizáveis (cards, campos de moeda/data, disclaimer)

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
    ├─ regras por tipo de rescisão      ← ver PROJECT.md §6
    ├─ TaxTablesService.calculateTerminationTaxes()  ← INSS/IRRF por data da rescisão
    └─ retorna TerminationResult { additions[], deductions[], totalToReceive, totalDeductions, netAmount }
    │
    ▼
ResultScreen ──► HistoryRepository.save() ──► SharedPreferences
             ├─► ShareUtils (texto) 
             └─► PdfUtils (somente PRO)
```

- O resultado é uma lista de `BreakdownItem` (`addition`/`deduction`) — a UI renderiza o *breakdown*
  sem recalcular. **Princípio de produto: transparência.** Não esconda itens do cálculo.
- Erros de cálculo viram `CalculationException` (mensagem amigável + `originalError`).

### 5.2 Tabelas fiscais

`assets/config/tax_tables.json` contém, por chave de ano/período (`inss_2025`, `inss_2026`,
`irrf_2025_jan_abr`, …), faixas, alíquotas, deduções, teto, regras de aviso prévio e dedução por
dependente. `TaxTablesService` (singleton, `loadTaxTables()` no boot) escolhe a tabela pela **data
da rescisão**, não pela data atual.

> **Atualização anual** é a manutenção mais crítica do app. Ao mudar uma tabela: editar o JSON,
> adicionar/ajustar o teste em `test/unit/termination_<ano>_test.dart` e `tax_tables_service_test.dart`.

### 5.3 PRO, anúncios e limites (estado atual — 🎯 PRO será removido)

> 🎯 No alvo, `ProUtils`, `PurchaseService` e a flag `is_pro_user` deixam de existir. PDF é livre, o
> histórico tem teto fixo de **100 itens** e os anúncios valem para todos. O fluxo abaixo descreve o
> código atual, para orientar a remoção.

```
PurchaseService (singleton, stream do Play Billing)
        │ compra/restauração confirmada
        ▼
ProUtils.setProUser(true)  ──►  SharedPreferences['is_pro_user']
        ▲
        │ lido por
AdManager.shouldShowAds · HistoryRepository (maxFree=10 / PRO≈ilimitado)
PdfUtils/ResultScreen (canExportPdf) · OfflineService · ProScreen
```

`ProUtils` é o **único ponto de leitura** do status PRO. Nenhuma tela deve ler a chave direto.

### 5.4 Persistência (chaves principais de `SharedPreferences`)

| Chave | Dono | Conteúdo |
|---|---|---|
| `calculation_history` | `HistoryRepository` | `List<String>` de JSON de `CalculationHistory` |
| `is_pro_user`, `pro_purchase_*` | `ProUtils` | flag e metadados da compra |
| `last_interstitial_time` | `AdManager` | controle do cooldown de 3 min |
| `offline_cache`, `pending_sync` | `OfflineService` | cache PRO (últimos 50) |
| `install_source`, `first_open`, `session_count`, `pro_conversion` | `AsoAnalytics` | métricas **locais** |

---

## 6. Gerenciamento de estado, navegação e UI

- **Estado:** `StatefulWidget` + `setState`, com serviços estáticos/singletons. Sem camada de
  ViewModel. Telas grandes (`form_screen`, `result_screen`, `home_screen`) concentram lógica de UI —
  extraia widgets ao tocá-las.
- **Navegação:** `Navigator.push(MaterialPageRoute)` imperativo. Fluxo:
  `Splash → (Onboarding, 1ª vez) → Home → Form → Result`; `Home → History | Pro | Support | About`.
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
  🎯 Telemetria (Analytics e Crashlytics) só **após consentimento opt-in**, pedido uma única vez depois do
  primeiro resultado, junto com o UMP dos anúncios. Anúncios **não personalizados** até o consentimento.
- `AsoAnalytics` e `AsoAbTesting` são **contadores locais**; nada sai do aparelho.

---

## 8. Testes e qualidade

| Pasta | Foco |
|---|---|
| `test/unit/` | Regras de cálculo (`calculate_termination`, `edge_cases`, `termination_2026`, `comprehensive_termination_review`), validação, repositório, PRO, PDF, logger, onboarding |
| `test/widget/` | Onboarding |
| `test/integration/` | Fluxo de cálculo ponta a ponta |
| `test/mocks`, `test_helpers/` | Setup de `SharedPreferences` |

Comandos:

```bash
flutter pub get
flutter analyze          # lints: flutter_lints (analysis_options.yaml)
flutter test             # toda a suíte
flutter test test/unit/termination_2026_test.dart   # um arquivo
```

**Definição de pronto para mudanças em cálculo:** teste novo cobrindo o caso, `flutter analyze`
limpo, `flutter test` verde. Mudança de regra trabalhista exige citar a base legal no commit/PR.

---

## 9. Build, release e compliance Android

- Assinatura de release configurada em `android/app/build.gradle.kts` (keystore fora do repositório).
- **Target SDK 36** e **páginas de 16 KB** são exigências da Play Console (prazo ≈ 31/08/2026) e
  estão especificadas em `openspec/specs/android-target-sdk` e `openspec/changes/android-16kb-page-size`.
- 🎯 **Billing Library:** a exigência deixa de valer quando `in_app_purchase*` for removido. Até lá,
  vem do plugin `in_app_purchase_android`; **não** fixar versão no Gradle (spec `play-billing`).
- Produto PRO (a **desativar no Play Console**; não há assinantes): ID `calc_recisao_pro_monthly`. Configuração de console
  (assinatura, testadores, compliance de SDK/16 KB) está resumida acima e nas specs do OpenSpec.
- Fluxo **spec-driven** com OpenSpec: mudanças de compliance entram em `openspec/changes/<nome>` e,
  ao serem arquivadas, viram `openspec/specs/<capability>/spec.md`.

### Dívidas técnicas conhecidas

| # | Dívida | Impacto | Sugestão |
|---|---|---|---|
| D1 | **Dinheiro em `double`**; `decimal` está no `pubspec` mas não é usado | Erros de arredondamento acumulados | Migrar o use case para `Decimal` ou inteiros em centavos |
| D2 | ~~Status PRO só local~~ | 🎯 **Resolvida pela extinção do PRO** | Remover `ProUtils`/`PurchaseService` |
| D3 | `Firebase.initializeApp()` não é chamado em `main.dart` | Crashlytics provavelmente inoperante (o logger só ignora o erro) | Inicializar com `firebase_options` + `google-services.json`, ou remover a dependência |
| D4 | Telas muito grandes, sem separação UI/lógica | Difícil testar e evoluir | Extrair widgets/controllers |
| D5 | Strings de domínio hardcoded; l10n manual | Bloqueia en-US real | Migrar para ARB/`gen-l10n` |
| D6 | Singletons estáticos (`ProUtils`, `TaxTablesService`) | Testes dependem de estado global | Injeção simples por construtor nos use cases/repositórios |
| D7 | `OfflineService` sem consumidor | 🎯 **Resolvida pela remoção** | Apagar na change `remove-pro-ads-only` |
| D8 | Descrições de itens do cálculo usadas como *chave* (`removeWhere(item.description == ...)`) | Frágil a renomeações; piora com férias em dobro e art. 479/480 | Usar enum/ID no `BreakdownItem` **antes** de adicionar verbas |
| D9 | Intersticial exibido logo ao renderizar o Resultado (`result_screen.dart`) | Cobre o número do usuário; viola o guardrail do PRD | 🎯 Exibir só ao **sair** do Resultado, ≤ 1/3 min e 1/sessão |
| D10 | Cálculo e apresentação misturam "a receber" e multa do FGTS | Total enganoso | 🎯 `TerminationResult` com dois totais (pago na rescisão × depositado no FGTS) e premissas |
| D11 | `hasAccruedVacation` booleano e meses por ano-calendário | Não modela períodos nem dobro | 🎯 Modelo de períodos derivado da admissão (change `add-vacation-periods`) |

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
| 2026-10 | 🎯 **Extinguir o PRO; monetizar só com AdMob** | Simplicidade; público de uso pontual converte mal em assinatura; elimina compliance de Billing |
| 2026-10 | 🎯 Intersticial só ao sair do Resultado; anúncios não personalizados até consentimento | Respeitar o momento do usuário; privacidade por padrão |
| 2026-10 | 🎯 Dinheiro em `Decimal`, após testes golden | Evitar erro de ponto flutuante com refatoração protegida |
| 2026-10 | 🎯 Histórico limitado a 100 itens em `SharedPreferences` | Não degradar o armazenamento; migrar para SQLite se crescer |
| 2026-10 | 🎯 Execução em 4 changes OpenSpec sequenciais | Versões pequenas isolam regressões (ver PROJECT.md §15) |

> Novas decisões: acrescente uma linha (data, decisão, motivo). Se for grande, crie uma change
> em `openspec/changes/`.
