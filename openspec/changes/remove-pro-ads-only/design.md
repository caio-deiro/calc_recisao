## Context

Hoje `ProUtils`/`PurchaseService`/`OfflineService` condicionam anúncios, PDF, limite de histórico e suporte. O intersticial dispara ao entrar no Resultado (D9). Firebase não é inicializado (D3) e `firebase_analytics` está comentado no `pubspec`. B1 não altera o JSON do histórico.

## Goals / Non-Goals

**Goals:** app gratuito sem código de compra; anúncios e consentimento conforme B1-10…14; analytics mínimo opt-in.
**Non-Goals:** cálculo, novos formatos de anúncio, novos eventos.

## Decisions

1. **Uma change só.** B1 tem 14 requisitos e ~26 tasks, um único bloco publicável; dividir deixaria a base sem PRO mas com consentimento pela metade. Se o executor passar de ~30 tasks, separar B1.4 (consentimento/analytics) em outra change.
2. **Ordem:** remover PRO (B1.1) primeiro, depois PDF/histórico, anúncios, e por fim Firebase/consentimento (depende de B0-06).
3. **Limpeza legada (B1-05):** função idempotente chamada no bootstrap, remove as 7 chaves com `remove` (no-op se ausentes); sem flag de "já executado".
4. **`AdManager`:** remove `shouldShowAds`; expõe `showInterstitialOnExit()` que checa (a) anúncio carregado, (b) flag de sessão em memória, (c) `last_interstitial_time` há mais de 3 min. Falhou qualquer uma: retorna sem esperar. Grava `last_interstitial_time` ao exibir.
5. **Requisição de anúncio:** `nonPersonalizedAds` verdadeiro até o aceite (`consent_decided` e `analytics_enabled` verdadeiros); depois, requisição normal. UMP permanece o formulário de consentimento de anúncios.
6. **Ponto central de analytics** em `lib/core/analytics/`: único método de emissão; lê `analytics_enabled`; sem consentimento retorna silenciosamente. Parâmetros só `tipo_rescisao` em `calc_completed` e `aceitou|recusou` em `consent_decision`. Como sem consentimento nada sai, `consent_decision` só é efetivamente emitido quando `aceitou` (recusa deixa a coleta desligada). Isso é consequência direta de B1-13 e deve ser confirmado (Open Questions).
7. **Firebase (B0-06):** `Firebase.initializeApp` no `main`; meta-data do manifesto com coleta de Analytics e Crashlytics `false`; `setAnalyticsCollectionEnabled(false)` no boot e `true` só após aceite.
8. **Aviso de histórico cheio (B1-09):** exibido na tela de histórico quando `length >= 90`, discreto (texto, não bloqueante).
9. **Descartada:** manter `play-billing` "dormente"; YAGNI, e o plugin sai do build.

## Risks / Trade-offs

- Regressão nas telas que usavam `FutureBuilder` de `ProUtils`: widget tests por tela + Maestro.
- A config de serviço do Firebase é bloqueada por hook para o agente; o usuário precisa fornecê-la.
- Banner adaptativo muda a altura útil: validar overflow em telas pequenas.

## Migration Plan

Primeira execução da nova versão limpa as chaves legadas; histórico intacto. Rollback = versão anterior (sem estado migrado a desfazer).

## Open Questions

- **Banner no Onboarding** (SPECS §4, B1-10a): Q16a diz "todas menos Formulário e Splash", mas B1-10a lista só 5 telas. Esta change segue a lista (sem banner no Onboarding). Recomendação: manter sem banner (primeira impressão limpa). Aguardando confirmação.
- **Config Firebase** (arquivos de configuração do projeto Firebase) ausente: quem fornece? Recomendação: usuário cria o projeto e adiciona os arquivos; o executor para e pede.
- **Momento do aviso de consentimento:** ao primeiro retorno do Resultado ou sobre ele? Recomendação: ao primeiro retorno à Home, antes de qualquer intersticial.
- **`consent_decision` com recusa** não sai (ver decisão 6). Recomendação: aceitar.
