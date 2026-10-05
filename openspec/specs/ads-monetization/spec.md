# ads-monetization Specification

## Purpose
TBD - created by archiving change remove-pro-ads-only. Update Purpose after archive.

## Requirements

### Requirement: Adaptive banner placement
O app MUST exibir um banner adaptativo ancorado no rodapé nas telas Home, Resultado, Histórico, Suporte e Sobre, e MUST NOT exibir banner em Formulário e Splash.

#### Scenario: Banner on listed screens
- **WHEN** o usuário abre Home, Resultado, Histórico, Suporte ou Sobre
- **THEN** o widget de banner MUST estar presente no rodapé

#### Scenario: No banner on form and splash
- **WHEN** o usuário está em Formulário ou Splash
- **THEN** nenhum widget de banner MUST estar presente

### Requirement: Interstitial only on exiting Result
O intersticial MUST ser exibido somente ao sair do Resultado (voltar à Home ou ao concluir compartilhar/exportar) e MUST NOT ser exibido ao entrar. A chamada em `addPostFrameCallback` de `result_screen.dart` MUST ser removida.

#### Scenario: Entering Result shows no interstitial
- **WHEN** o Resultado é aberto
- **THEN** nenhum intersticial MUST ser solicitado para exibição

#### Scenario: Leaving Result may show interstitial
- **WHEN** o usuário sai do Resultado, o anúncio está carregado e a frequência permite
- **THEN** o intersticial MUST ser exibido uma vez

### Requirement: Interstitial frequency cap
`AdManager.showInterstitialOnExit()` MUST exibir no máximo 1 intersticial a cada 3 minutos (persistindo `last_interstitial_time`) e 1 por sessão (flag em memória). Se o anúncio não estiver carregado, a navegação MUST seguir sem bloqueio nem espera.

#### Scenario: Second exit in same session
- **WHEN** um intersticial já foi exibido na sessão e o usuário sai do Resultado de novo
- **THEN** nenhum intersticial MUST ser exibido

#### Scenario: Within 3 minutes of last display
- **WHEN** `last_interstitial_time` tem menos de 3 min (nova sessão)
- **THEN** nenhum intersticial MUST ser exibido

#### Scenario: Ad not loaded
- **WHEN** o anúncio não está carregado ao sair do Resultado
- **THEN** a navegação MUST concluir imediatamente sem espera

### Requirement: No interstitial before consent decision
Nenhum intersticial MUST ser exibido antes de `consent_decided` ser verdadeiro. Como o aviso de consentimento aparece no primeiro retorno à Home depois do primeiro resultado, o intersticial da primeira saída do Resultado MUST ser omitido.

#### Scenario: First exit from Result
- **WHEN** o usuário sai do Resultado pela primeira vez e `consent_decided` é falso
- **THEN** nenhum intersticial MUST ser exibido

#### Scenario: After consent decision
- **WHEN** `consent_decided` é verdadeiro, o anúncio está carregado e a frequência permite
- **THEN** o intersticial MUST ser exibido ao sair do Resultado

### Requirement: No rewarded or splash/form ads
O app MUST NOT exibir anúncio recompensado nem qualquer anúncio em Splash e Formulário.

#### Scenario: No rewarded code path
- **WHEN** se inspeciona `lib/` por uso de `RewardedAd`
- **THEN** MUST NOT haver ocorrência

### Requirement: Non-personalized ads until consent
Até a decisão de consentimento positiva, as requisições de anúncio MUST usar `AdRequest(nonPersonalizedAds: true)`; após o aceite, requisição normal. A permissão `AD_ID` MUST permanecer declarada no manifesto.

#### Scenario: No consent
- **WHEN** um anúncio é solicitado sem consentimento
- **THEN** o `AdRequest` MUST ter `nonPersonalizedAds` verdadeiro

#### Scenario: After acceptance
- **WHEN** o usuário aceitou e um anúncio é solicitado
- **THEN** o `AdRequest` MUST ser normal (não forçado não personalizado)
