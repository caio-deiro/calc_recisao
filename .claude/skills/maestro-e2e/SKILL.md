---
name: maestro-e2e
description: Organizar, escrever, rodar e diagnosticar testes E2E com Maestro (CLI e MCP) no emulador Android deste app, seguindo a convenção goal-driven (jornadas do usuário em .maestro/tests, segmentadas por estado do app). Cobre subir e consertar o emulador, instalar o APK, criar fluxos e subfluxos YAML, config.yaml com `flows`, tags, rodar com relatório, interpretar falhas e reportar ao executor. Use sempre que o usuário pedir teste E2E, "fluxo Maestro", "jornada", "teste no emulador", "valide no app", "rode o maestro", ao revisar uma change que muda telas ou fluxos de usuário, e como etapa de validação do reviewer.
---

# Maestro E2E

Valida o app **como o usuário o usa**, no emulador: o que testes unitários e de widget não alcançam (navegação, teclado, anúncios, persistência real). O Maestro localiza elementos pela **árvore de acessibilidade**, não por imagem.

Ambiente: Maestro 2.8.0 (`D:\maestro\bin`), AVD `Medium_Phone`, `appId` **`com.caiodeiro.calcclt`**, SDK em `D:\android\Sdk`. No PATH: `D:\maestro\bin` e `D:\android\Sdk\platform-tools`. Modelos de fluxo deste app: [references/flows.md](references/flows.md).

## Convenção: goal-driven (jornadas)
O app existe para o usuário **chegar a um resultado**: escolher o tipo de rescisão, preencher os dados e ver o valor. Esse é o funil, e o sucesso é o **resultado visível** (a "confirmação do pedido" deste app). Por isso a suíte se organiza **por jornada**, cobrindo as variações da tarefa principal, e se segmenta pelo **estado do app**:

```
.maestro/
├── config.yaml                  # flows: tests/**
├── tests/
│   ├── first_run/               # equivale a "new users": app recém-instalado
│   │   ├── onboarding_to_first_result.yaml
│   │   └── consent_after_first_result.yaml
│   └── returning/               # equivale a "existing users": onboarding concluído
│       ├── termination_without_just_cause.yaml
│       ├── termination_resignation.yaml
│       ├── termination_mutual_agreement.yaml
│       ├── termination_just_cause.yaml
│       ├── share_result.yaml
│       ├── export_pdf.yaml
│       └── history_open_saved_calculation.yaml
├── subflows/                    # trechos reutilizáveis (runFlow); fora de tests/
│   ├── skip_onboarding.yaml
│   ├── dismiss_consent.yaml
│   └── fill_basic_form.yaml
└── utils/                       # scripts JS (runScript), se necessários
```

- **`config.yaml`** define a busca com a chave `flows`, em glob: `flows: tests/**`. Isso limita a descoberta a `tests/`, então **subfluxos e scripts nunca rodam sozinhos como teste**. Sem essa separação, um subfluxo vira teste falso.
- **Segmentos.** O app não tem contas, então o "estado" é local: `first_run` parte de `clearState` e vê onboarding e consentimento; `returning` parte de `clearState` + o subfluxo que pula o onboarding (e, se a jornada precisar de histórico, um cálculo prévio).
- **Uma jornada = um objetivo.** Termina no resultado e **confere valores** (ex.: "Pago na rescisão" e "Depositado no FGTS" para uma entrada conhecida), não só que a tela abriu.
- Novas variações do funil (art. 479/480, férias em dobro, rescisão indireta) viram **novos arquivos** em `returning/`, nomeados `termination_<variacao>.yaml`.
- Nomes de arquivo em inglês, `snake_case`; o `name:` do fluxo em português.
- **Tags** no cabeçalho de cada fluxo: `smoke` (uma jornada por objetivo, roda sempre), `calculation`, `share`, `pdf`, `history`, `regression`. Rode um subconjunto com `--include-tags smoke`.

Criação inicial: crie a pasta, o `config.yaml`, os subfluxos e **um** fluxo `smoke`; valide com `maestro check-syntax <arquivo>`; só depois amplie.

## 1. Preparar o emulador
```bash
flutter emulators --launch Medium_Phone
adb wait-for-device
adb shell getprop sys.boot_completed      # repita até devolver 1
adb devices                                # precisa mostrar "device", não "offline"
```
Se aparecer `offline`: `adb reconnect offline`; depois `adb kill-server` + `adb start-server`; por último reabra o emulador. Poucas tentativas e, se não resolver, **pare e reporte**.

## 2. Instalar o app
```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
Reinstale sempre que o código mudar; APK desatualizado dá resultado falso.

## 3. Escrever fluxos
Modelos em [references/flows.md](references/flows.md). Regras:
- Comece com `launchApp` + `clearState: true`. Nenhum fluxo depende do estado deixado por outro.
- Prefira **`id`** (`Semantics.identifier`) a texto. Convenção: `<tela>_<elemento>` (`form_salary_field`, `form_calculate_button`, `result_paid_total`). Se um elemento não tem `id`, a correção é **no app** (skill `flutter-conventions`), nunca seletor por coordenada.
- Espere por estado, não por tempo: `extendedWaitUntil` / `assertVisible`; evite pausas fixas. `retry` só em trecho pequeno, pois esconde instabilidade do app.
- Entradas fixas via `env:`/`-e` (nunca a data de hoje); `optional: true` só no que é realmente opcional (anúncio, consentimento).
- Cada comando importante ganha `label:` legível, que aparece no relatório.
- `maestro check-syntax` antes de rodar.

### Particularidades deste app
- **Anúncios:** o banner pode cobrir botões; use `scrollUntilVisible` e `id`. Falha de anúncio não pode falhar um fluxo de cálculo: o fechamento do intersticial (ao sair do Resultado) é **opcional**.
- **Consentimento (UMP + analytics):** aparece após o 1º resultado (change `remove-pro-ads-only`); `dismiss_consent` o trata de forma opcional.
- **Onboarding:** só na 1ª abertura; `skip_onboarding` o pula nos fluxos `returning`.

## 4. Rodar

**CLI** (padrão em CI e para a suíte):
```bash
maestro --device emulator-5554 test .maestro --format JUNIT --output build/maestro/report.xml --test-output-dir build/maestro
maestro --device emulator-5554 test .maestro --include-tags smoke
maestro --device emulator-5554 test .maestro/tests/returning/termination_resignation.yaml -e SALARY=4000
```
Apontar para `.maestro` usa o `config.yaml` da raiz do workspace (`--config` aceita outro). Falha pode ser instabilidade: **reexecute só o fluxo que falhou, uma vez**; falhou duas vezes, é falha real.

**MCP** (`maestro`, já configurado no escopo local; só com o emulador de pé). Use para **explorar e depurar**, não para a suíte:
1. `list_devices` → obtenha o `device_id` (obrigatório nas demais).
2. `inspect_screen` → hierarquia em JSON, para descobrir `id` e textos reais. Reinspecione após qualquer mudança de tela.
3. `run` → `yaml` inline para experimentar, ou `files`/`dir` (com `include_tags`/`exclude_tags` sem `@`).
4. `cheat_sheet` antes de usar um comando que você não conhece.
Ao abrir uma sessão via MCP, mostre ao usuário o link do **Maestro Viewer** (`http://127.0.0.1:9999/`), que o `cheat_sheet` informa.

**Proibido:** `run_on_cloud`, `list_cloud_devices`, `get_cloud_run_status`, `describe_cloud_run`, `maestro cloud`, `--analyze`, `assertWithAI`, `assertNoDefectsWithAI`, `extractTextWithAI`. Enviam telas ou fluxos a serviços externos e contrariam a privacidade do projeto.

## 5. Screenshots: só quando necessário
O Maestro **não precisa** de screenshots para rodar. Em falha, ele grava sozinho, em disco, o log, os comandos e a captura (em `~/.maestro/tests/<data>/` ou no `--test-output-dir`).
1. Leia primeiro o **texto** (saída, relatório JUnit, log). Quase sempre basta.
2. **Abra a imagem só se** o texto não explicar a falha.
3. Não use `takeScreenshot`/`assertScreenshot` nos fluxos, salvo caso visual específico combinado.
4. Nunca devolva imagem ao executor: devolva texto.

## 6. Relatório (curto)
```
E2E: <n> fluxos | <n> passaram | <n> falharam   (tags: <...>)
Falhou: <fluxo> — passo: <label/comando> — causa provável: <1 linha>
Reexecução: <passou | falhou de novo>
Pede ao executor: <ação concreta, ex.: "dar identifier ao campo de salário">
```
Separe sempre: **falha do app** (comportamento errado), **falha de teste** (seletor ou fluxo desatualizado) e **ambiente** (emulador, APK antigo).

## O que fica de fora
Não altere código do app a partir daqui (só `.maestro/`). Se faltar `id` ou o comportamento estiver errado, **reporte** ao executor.
