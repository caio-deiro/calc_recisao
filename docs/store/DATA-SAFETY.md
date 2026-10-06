# Ficha de Segurança dos dados (Data Safety) — respostas propostas para o Play Console

**Status:** decisões do responsável registradas em 2026-10-06 (exclusão: **sim, por e-mail**; contato: `caioguimaraes12@outlook.com`; bases legais aprovadas). Falta preencher o formulário no Play Console (B7-02), que é passo manual.
**Base:** levantamento do código em 2026-10-06 (`pubspec.yaml`, `AndroidManifest.xml`, `lib/core/analytics`, `lib/core/ads`, `lib/presentation/widgets/consent_prompt.dart`) e as orientações oficiais do Google para os SDKs (AdMob: `developers.google.com/admob/android/privacy/play-data-disclosure`; Firebase: `firebase.google.com/docs/android/play-data-disclosure`). Confira o texto de cada pergunta no formulário, que o Google atualiza.

## O que o app faz de fato

| Fato | Evidência |
|---|---|
| Cálculos e histórico ficam no aparelho (`SharedPreferences`); salário, datas e resultado **nunca** saem | `lib/data/repositories/history_repository.dart`; `analytics_service.dart` (lista fechada de eventos) |
| Firebase Analytics e Crashlytics começam **desligados** e só ligam se o usuário aceitar | `AndroidManifest.xml` (`firebase_analytics_collection_enabled=false`, `firebase_crashlytics_collection_enabled=false`); `AnalyticsService.initialize` |
| Eventos de Analytics: `calc_completed{tipo_rescisao}`, `share_used`, `pdf_exported`, `consent_decision{decisao}` | `analytics_service.dart` |
| Anúncios (AdMob) carregam sempre; sem aceite, são não personalizados | `ad_manager.dart:25` (`nonPersonalizedAds`) |
| Permissão de ID de publicidade declarada | `AndroidManifest.xml` (`AD_ID`) |
| Consentimento: formulário UMP do Google + aviso do app, pedido uma vez depois do primeiro resultado | `consent_prompt.dart` |
| Sem conta, sem login, sem localização por GPS, sem câmera, sem contatos | permissões do manifesto |
| **Sem como revogar o consentimento depois** | não há tela de configuração; só `ConsentService.saveDecision` na hora do aviso |

## Respostas propostas

**Coleta ou compartilha dados do usuário?** Sim (por causa do AdMob, sempre; e do Firebase, com aceite).

### Tipos de dados

| Categoria Play | Tipo | Coletado | Compartilhado | Opcional? | Finalidades | Origem |
|---|---|---|---|---|---|---|
| Localização | Localização aproximada | Sim | Sim (Google) | Não* | Publicidade, análise, prevenção de fraude | AdMob (deriva do IP); Analytics |
| Atividade no app | Interações com o app | Sim | Sim (Google) | AdMob: não*; Analytics: sim | Publicidade, análise | AdMob; Analytics (4 eventos) |
| Informações e desempenho do app | Registros de falha; diagnósticos | Sim | Sim (Google) | Crashlytics: sim (só com aceite); AdMob: não* | Análise, estabilidade | Crashlytics; AdMob |
| Dispositivo ou outros IDs | ID de publicidade; ID de instalação/app set | Sim | Sim (Google) | ID de publicidade: o usuário pode redefinir ou apagar nas configurações do Android | Publicidade, análise, prevenção de fraude | AdMob; Firebase |
| Informações financeiras | — | **Não** | **Não** | — | — | Ver abaixo |

\* "Não opcional" significa que o SDK de anúncios coleta por padrão; o usuário pode limitar nas configurações de anúncios do Android.

### O que **sair** da ficha atual

A página pública da Play (2026-10-06) mostra "Informações financeiras" como dado coletado. Pelo código, **isso não é coletado**: salário, valores e resultado são processados só no aparelho, e nenhum SDK recebe esses campos (a lista de eventos é fechada e sem valores). Pela definição do Google, dado que não sai do aparelho não é "coletado". Recomendação: remover "Informações financeiras" da ficha. Se uma versão futura enviar valor do cálculo a algum serviço, a ficha tem que ser atualizada antes.

### Práticas de segurança

- **Dados criptografados em trânsito:** Sim (os SDKs do Google usam HTTPS).
- **Usuário pode solicitar exclusão dos dados:** **Sim, por e-mail** (decisão do responsável). A política explica que o histórico local some ao limpar os dados do app ou desinstalar, e que os dados do Google (anúncios, Firebase) também se controlam pelas configurações do Google. O e-mail de contato precisa ser monitorado.
- **Comprometimento com as diretrizes de Famílias:** não se aplica (app não é voltado a crianças).
- **Validação independente de segurança:** não.

### Outras declarações do Play Console (B7-02)

- **Contém anúncios:** Sim.
- **ID de publicidade:** Sim, usado para publicidade (já há a permissão `AD_ID`).
- **Funcionalidades financeiras:** o app **não** oferece empréstimo, pagamento, investimento nem aconselhamento; é uma estimativa. Responder como "nenhuma funcionalidade financeira". Relevante se a categoria mudar para Finanças.
- **Público-alvo:** adultos (trabalhadores). Sem apelo a crianças.
- **Classificação de conteúdo:** manter "Livre" (hoje).

## Lacunas que a ficha expõe (viram trabalho)

1. **Revogação do consentimento:** a LGPD exige que revogar seja tão fácil quanto consentir (art. 8º, §5º). Hoje não há tela. Proposta: uma opção "Dados de uso e anúncios" na tela Sobre, com o estado atual e a troca. Entra como change própria pelo laço (precisa de decisão de produto sobre o texto).
2. **Duas decisões em um aviso só:** o aviso mistura analytics e personalização de anúncios. Funciona, mas a política precisa dizer isso claramente (já diz, no rascunho).
3. **Reconciliar a descrição da loja** com a ficha (ver `AUDITORIA.md` P0 #1): trocar "seus dados não são armazenados nem compartilhados" por texto verdadeiro, por exemplo: "O cálculo é feito no seu aparelho. Salário e resultado não saem dele."
