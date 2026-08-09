---
name: Calculadora de Rescisão CLT
description: Ferramenta móvel prática para estimar verbas rescisórias com clareza e velocidade
colors:
  primary: "#1976D2"
  primary-deep: "#1565C0"
  primary-light: "#42A5F5"
  on-primary: "#FFFFFF"
  surface: "#FAFAFA"
  surface-dark: "#121212"
  on-surface: "#1C1B1F"
  on-surface-variant: "#49454F"
  error: "#B3261E"
  error-container: "#F9DEDC"
  success: "#2E7D32"
  danger: "#C62828"
  pro-gradient-start: "#1E88E5"
  pro-gradient-end: "#1565C0"
typography:
  display:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: "28px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "normal"
  headline:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "normal"
  title:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: 1.35
    letterSpacing: "normal"
  body:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: "normal"
  label:
    fontFamily: "Roboto, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "normal"
rounded:
  sm: "8px"
  md: "12px"
  pill: "16px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  xxl: "32px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.sm}"
    padding: "12px 24px"
  card-surface:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.md}"
    padding: "16px"
  input-outline:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.sm}"
    padding: "12px 16px"
---

# Design System: Calculadora de Rescisão CLT

## Overview

**Creative North Star: "A Mesa de Cálculo"**

O visual deve parecer uma mesa de trabalho organizada — números à vista, rótulos claros, nada escondido atrás de ornamentos. Material 3 com azul confiável como âncora, densidade moderada e hierarquia que guia do tipo de rescisão ao valor final em poucos toques. Rejeita o visual de fintech genérico, a confusão de portais governamentais e qualquer monetização que roube atenção do cálculo.

O sistema segue `ThemeData` com `ColorScheme.fromSeed` (#1976D2), suporte a tema claro/escuro via `ThemeMode.system`, e componentes Flutter nativos (Card, InkWell, OutlineInputBorder). Profundidade vem de elevação leve em cards, não de gradientes decorativos — exceto o card PRO, que deve ser tratado como exceção a refinar, não como padrão.

**Key Characteristics:**

- Azul Material como cor de confiança e ação primária
- Cards com cantos suaves (12px) e padding generoso (16px)
- Tipografia Roboto padrão, pesos bold para títulos de seção
- Verde/vermelho semântico apenas em valores de breakdown (adição/desconto)
- Disclaimers em container de aviso, nunca escondidos
- Fluxo vertical com scroll; AppBar centrada e sem elevação

## Colors

Paleta enxuta: um acento azul, neutros do Material 3, e verde/vermelho funcionais para valores.

### Primary

- **Azul Confiança** (#1976D2): seed do `ColorScheme`, AppBar, splash, botões primários, links de ação. Transmite seriedade sem parecer instituição governamental.
- **Azul Profundo** (#1565C0): estados pressed, gradiente PRO (fim), ênfase secundária.
- **Azul Claro** (#42A5F5): feedback visual leve, highlights em tema escuro.

### Neutral

- **Superfície Clara** (#FAFAFA): fundo de cards e inputs em tema light (via `colorScheme.surface`).
- **Superfície Escura** (#121212): fundo base em tema dark.
- **Texto Principal** (#1C1B1F): títulos e valores em destaque (`onSurface`).
- **Texto Secundário** (#49454F): descrições, detalhes de breakdown, subtítulos (`onSurfaceVariant`).

### Tertiary (funcional)

- **Verde Verba** (#2E7D32): adições no breakdown (`BreakdownItemCard`, fundo 10% opacity).
- **Vermelho Desconto** (#C62828): descontos e erros de validação.
- **Aviso** (#B3261E / container #F9DEDC): `DisclaimerWidget` e alertas legais.

### Named Rules

**The One Accent Rule.** O azul primário aparece em ações e navegação. Verde e vermelho são exclusivos para valores monetários positivos/negativos e erros — nunca como decoração de marketing.

## Typography

**Display Font:** Roboto (sistema Flutter / Material)
**Body Font:** Roboto (sistema Flutter / Material)

**Character:** Neutra, legível, sem personalidade tipográfica exagerada. A clareza vem do peso e tamanho, não de fontes customizadas.

### Hierarchy

- **Display** (700, 28px, 1.2): splash screen, títulos de onboarding
- **Headline** (700, 20px, 1.3): títulos de seção na home e formulário ("Escolha o tipo de rescisão")
- **Title** (700, 18px, 1.35): rótulos de cards (`TerminationTypeCard`)
- **Body** (400, 14px, 1.5): descrições, texto de disclaimer, detalhes de verbas
- **Label** (400, 12px, 1.4): metadados, preço PRO, detalhes secundários de breakdown

### Named Rules

**The Plain Language Rule.** Títulos em português direto; evitar siglas sem expansão na primeira ocorrência. Peso bold marca hierarquia, não caixa alta.

## Elevation

Sistema predominantemente plano com elevação sutil. AppBar com `elevation: 0`. Cards usam `elevation: 2` para separação da superfície. Profundidade adicional via bordas em disclaimers e chips de valor, não via sombras pesadas.

### Shadow Vocabulary

- **Card resting** (`elevation: 2` / Material shadow): cards de tipo de rescisão, itens de breakdown
- **PRO card** (`blurRadius: 8, offset: 0 4, color: blue-200`): única sombra colorida — candidata a simplificação

### Named Rules

**The Flat-By-Default Rule.** Superfícies em repouso são planas ou com elevação mínima. Sombras coloridas e gradientes são exceções, não vocabulário base.

## Components

### Buttons

- **Shape:** Cantos suaves (8px `BorderRadius.circular(8)`)
- **Primary:** `ElevatedButton` com padding 24×12 horizontal/vertical, cor do `colorScheme.primary`
- **Hover / Focus:** ripple Material padrão (`InkWell`); sem animações customizadas
- **Icon buttons:** AppBar actions (histórico, PRO, suporte, sobre) — 48dp touch target implícito

### Cards / Containers

- **TerminationTypeCard:** Card 12px, padding 16px, InkWell ripple, título 18px bold + descrição 14px variant, chevron à direita
- **BreakdownItemCard:** Card 12px, chip de valor com pill 16px — verde (adição) ou vermelho (desconto), borda 1px
- **DisclaimerWidget:** Container 12px, fundo `errorContainer` 10% opacity, borda 30% opacity, ícone warning + título error bold
- **PRO Upgrade Card:** gradiente azul 600→800, texto branco — tratamento promocional, não replicar em outras superfícies

### Inputs / Fields

- **Style:** `OutlineInputBorder` 8px, padding 16×12, labels acima do campo
- **Focus:** borda primary do Material 3
- **Currency/Date:** widgets customizados (`CurrencyTextField`, `DateInputField`) seguem `inputDecorationTheme`

### Navigation

- **AppBar:** título centrado, sem elevação, ícones de ação à direita
- **Fluxo:** Splash → Onboarding (primeira vez) → Home → Form → Result; History e Pro como rotas secundárias

### Breakdown Value Chip (signature)

Chip pill com cor semântica: fundo 10% opacity, borda 1px sólida, texto bold 16px. Prefixo `+` ou `-` antes do valor formatado em BRL.

## Do's and Don'ts

### Do:

- **Do** usar `Theme.of(context).colorScheme` para cores — nunca hardcodar azul fora de tokens conhecidos
- **Do** manter padding de 16px como unidade base em cards e telas com scroll
- **Do** exibir `DisclaimerWidget` em home, formulário e resultado
- **Do** usar `Semantics` em cards e ações principais para leitores de tela
- **Do** formatar valores com `Formatters.formatCurrency` consistentemente

### Don't:

- **Don't** usar gradientes decorativos em cards de conteúdo — reservar gradiente apenas ao upsell PRO (e preferir simplificar no futuro)
- **Don't** replicar o visual de apps genéricos de finanças: grids de cards idênticos com ícones coloridos, hero metrics gigantes, ou estética startup/SaaS
- **Don't** densificar como site governamental: múltiplas seções competindo, labels técnicos sem contexto, informação legal acima do formulário
- **Don't** colocar anúncios ou upsell no caminho crítico entre "calcular" e ver o resultado
- **Don't** usar `border-left` colorido como acento em list items ou alertas
- **Don't** depender só de cor para significado — sempre acompanhar com texto ou ícone (+/-, warning)
