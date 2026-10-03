# Modelos de fluxo (calc_recisao)

Pontos de partida. Os `id` abaixo são a **convenção alvo** (`<tela>_<elemento>`); ainda não existem no app. Confirme os reais com `inspect_screen` (MCP) ou `maestro hierarchy` e ajuste. Os textos de tela vêm do app em português.

Sumário: [config.yaml](#configyaml) · [Subfluxos](#subfluxos) · [Jornada: primeira abertura](#jornada-primeira-abertura-first_run) · [Jornada: cálculo](#jornada-cálculo-returning) · [Variações](#variações-do-funil)

## config.yaml
```yaml
# .maestro/config.yaml
flows:
  - tests/**
```
Subfluxos (`subflows/`) e scripts (`utils/`) ficam fora de `tests/` de propósito: não são testes.

## Subfluxos

`subflows/skip_onboarding.yaml`: pula o onboarding (aparece só na 1ª abertura).
```yaml
appId: com.caiodeiro.calcclt
---
- runFlow:
    when:
      visible: "Pular"
    commands:
      - tapOn: "Pular"
```

`subflows/dismiss_consent.yaml`: dispensa o aviso de consentimento (após a change `remove-pro-ads-only`); opcional por natureza.
```yaml
appId: com.caiodeiro.calcclt
---
- runFlow:
    when:
      visible:
        id: "consent_decline_button"
    commands:
      - tapOn:
          id: "consent_decline_button"
```

`subflows/fill_basic_form.yaml`: preenche o formulário com variáveis recebidas por `env`.
```yaml
appId: com.caiodeiro.calcclt
---
- tapOn:
    id: "form_salary_field"
    label: "Informar salário"
- inputText: ${SALARY}
- hideKeyboard
- tapOn:
    id: "form_calculate_button"
    label: "Calcular"
```

## Jornada: primeira abertura (`first_run`)
`tests/first_run/onboarding_to_first_result.yaml`
```yaml
appId: com.caiodeiro.calcclt
name: Primeira abertura até o primeiro resultado
tags: [smoke, calculation]
env:
  SALARY: "4000"
---
- launchApp:
    clearState: true
- runFlow: ../../subflows/skip_onboarding.yaml
- tapOn:
    text: "Sem Justa Causa"
    label: "Escolher o tipo de rescisão"
- runFlow:
    file: ../../subflows/fill_basic_form.yaml
    env:
      SALARY: ${SALARY}
- extendedWaitUntil:
    visible: "Pago na rescisão"
    timeout: 10000
- assertVisible:
    id: "result_paid_total"
    label: "Resultado exibido"
- runFlow: ../../subflows/dismiss_consent.yaml
```
O caminho de `runFlow` é relativo ao arquivo do fluxo.

## Jornada: cálculo (`returning`)
`tests/returning/termination_resignation.yaml`: parte de um app já usado e confere valores de uma entrada conhecida (os mesmos de um caso golden).
```yaml
appId: com.caiodeiro.calcclt
name: Pedido de demissão com aviso não cumprido
tags: [calculation, regression]
env:
  SALARY: "4000"
---
- launchApp:
    clearState: true
- runFlow: ../../subflows/skip_onboarding.yaml
- tapOn: "Pedido de Demissão"
- runFlow:
    file: ../../subflows/fill_basic_form.yaml
    env:
      SALARY: ${SALARY}
- extendedWaitUntil:
    visible: "Pago na rescisão"
    timeout: 10000
- assertVisible: "Desconto Aviso Prévio"
- assertVisible:
    id: "result_paid_total"
    text: "R\\$ .*"          # os valores exatos vêm do caso golden correspondente
```
Valor esperado exato: use o do **caso golden** (skill `calc-rules`), nunca a saída do app.

## Variações do funil
Cada uma é um arquivo novo em `returning/`, mudando só o tipo e as entradas:

| Arquivo | Muda | Asserção-chave |
|---|---|---|
| `termination_without_just_cause.yaml` | tipo | "Aviso Prévio Indenizado"; bloco "Depositado no FGTS" |
| `termination_mutual_agreement.yaml` | tipo | "Aviso Prévio Indenizado (50%)"; multa de 20% |
| `termination_just_cause.yaml` | tipo | sem 13º nem férias proporcionais; férias vencidas (decisão Q2a) |
| `termination_fixed_term_*.yaml` | tipo + data de término | indenização art. 479 / desconto art. 480 (após B4) |
| `vacation_double.yaml` | períodos gozados | linhas "simples" e "em dobro" (após B3) |
| `share_result.yaml` | ação após o resultado | seletor de compartilhamento abre |
| `export_pdf.yaml` | ação após o resultado | PDF gerado sem aviso de bloqueio |
| `history_open_saved_calculation.yaml` | calcula, volta e abre pelo histórico | mesmo total do resultado |

## Comandos úteis neste app
`launchApp` (`clearState`), `tapOn`, `inputText`, `hideKeyboard`, `assertVisible` / `assertNotVisible`, `extendedWaitUntil`, `scrollUntilVisible`, `runFlow` (`file`, `when`, `env`, `commands`), `back`, `pressKey`, `setOrientation`, `setDarkMode` (tema claro/escuro). Sintaxe completa: `cheat_sheet` (MCP).
