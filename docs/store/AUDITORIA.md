# Auditoria de ASO: Calculadora de Rescisão CLT (Google Play, pt-BR)

**Data:** 2026-10-06. **Método:** skills `aso-audit` e `android-aso` (pesos adaptados à Play) sobre a página pública da loja, o repositório e os concorrentes do `CONTEXTO.md`. **Limites:** sem Play Console, sem API de dados de mercado e sem baseline; os fatores que dependem disso estão como "não medido". Restrições do projeto: `aso-rules`.

## Placar (parcial: 85% dos pesos medidos)

| Fator | Peso | Nota | Evidência |
|---|--:|--:|---|
| Título | 20 | 70 | Nome claro e dentro de 30 caracteres; sem termo diferenciador nem ano |
| Descrição curta | 15 | 35 | 44 de 80 caracteres, genérica ("em poucos segundos"), sem 2026, sem tipos de rescisão |
| Descrição longa | 15 | 40 | Boa estrutura, mas com afirmação que contradiz a Data Safety, adjetivos vazios ("confiável") e sem os recursos novos |
| Screenshots | 15 | 45 | 5 imagens, em formato paisagem 16:9; sem como avaliar legendas e conteúdo pela página |
| Vídeo | 5 | 60 | Existe trailer; conteúdo não verificado |
| Avaliações | 15 | 25 | A página não exibe nota; sem estratégia de pedido nem de resposta |
| Ícone | 5 | n/m | Não avaliado visualmente |
| Posição por palavra-chave | 10 | n/m | Sem ferramenta de ranking |
| Conversão | 5 | n/m | Sem Play Console |

**Nota indicativa: 46 de 100** (média ponderada dos fatores medidos). Serve como régua para comparar depois; não é nota oficial.

## Achados por prioridade

### P0: conformidade e credibilidade (risco de rejeição ou suspensão)

| # | Achado | Evidência | Ação | Executa |
|---|---|---|---|---|
| 1 | A descrição diz "seus dados não são armazenados nem compartilhados", mas a Data Safety declara coleta de localização, informações financeiras e outros, e compartilhamento com terceiros | Página da Play, 2026-10-06 | Reconciliar: ou a Data Safety foi declarada em excesso (os SDKs de anúncio costumam gerar isso) ou a descrição está errada. Corrigir os dois pelo que o app realmente faz | Responsável decide (⚖️ LGPD); B7-02 |
| 2 | Política de privacidade inconsistente: o `README.md` diz que não coleta dados, mas o app usa AdMob e Crashlytics; `assets/privacy.md` está de 2025 | `README.md`, `assets/privacy.md` | Reescrever (autorizado) e manter no GitHub Pages | B7-01 |
| 3 | Link de compartilhamento do app aponta para `com.calcrescisao.app`, que não é o ID real (`com.caiodeiro.calcclt`) | `lib/core/deep_links/aso_deep_links.dart` | Corrigir ou remover o arquivo (código morto) | Change A |
| 4 | URLs `calcrescisao.com/privacy` e `/terms` no código não existem | `AppConstants:42-43` | Apontar para a URL real do GitHub Pages | Change A / B7-01 |
| 5 | E-mail de contato diverge entre código e loja | `AppConstants:39`, página da Play | Unificar | B7-05 |

### P1: conversão e descoberta

| # | Achado | Ação | Executa |
|---|---|---|---|
| 6 | Descrição curta fraca (44 de 80) | Reescrever com benefício, ano e escopo, por exemplo variantes de "Rescisão, férias e 13º 2026: veja cada verba explicada" (contar caracteres com código) | Change B |
| 7 | Descrição longa sem os recursos que o app tem hoje (acordo, rescisão indireta, contrato a prazo, férias em dobro, dois totais, premissas, tabelas 2026) | Reescrever em `listing-pt-BR.md` seguindo `aso-rules` | Change B |
| 8 | Sem o ano na descrição: concorrentes usam "2026" (título ou descrição) | Colocar "2026" na curta e na longa; manter o título em 27 caracteres, pois com " 2026" passaria de 30 | Change B |
| 9 | Screenshots em paisagem e apenas 5; os concorrentes têm 8 | Gerar 6 a 8 em retrato com legenda curta (via Maestro), mostrando o fluxo, os dois totais e as premissas | Change D |
| 10 | Categoria Ferramentas, onde está o líder (5 mi+); duas concorrentes diretas estão em Finanças. Evidência mista | Decidir após comparar com mais concorrentes; a recomendação do plano continua Finanças, com a ressalva de que a declaração de funcionalidades financeiras precisa dizer que o app é só estimativa | Responsável |
| 11 | Sem nota visível e sem pedido de avaliação no app | `add-in-app-review` e rotina de resposta a avaliações (`review-management`) | Change G |
| 12 | Cadência de atualização: nossa última atualização pública foi em 8/8/2026; "O que há de novo" não existe no pipeline | `whatsnew` no workflow de release | Change F |

### P2: higiene

| # | Achado | Ação |
|---|---|---|
| 13 | Três nomes do app: "Calculadora de Rescisão CLT", "Calculadora Rescisão CLT" (label do Android) e "Calc CLT" (iOS, fora de escopo) | Unificar Android e `lib/app.dart` |
| 14 | `app_category`, `app_keywords` e `app_description` no manifest não têm efeito algum | Remover (Change A) |
| 15 | `aso_ab_testing.dart` e `aso_deep_links.dart` sem uso; `aso_analytics.dart` grava um `install_source` fixo e falso | Remover o que não tem uso; avaliar remover o contador falso (Change A) |
| 16 | `description` do `pubspec.yaml` diz "Trabalhista 2025" | Atualizar |
| 17 | Endereço do desenvolvedor aparece publicamente na página da Play | É exigência da conta de desenvolvedor para apps com anúncios; só registrar, sem ação no repositório |

## Concorrência: oportunidades

- **Transparência do cálculo** (verba por verba, premissas, dois totais) e **privacidade** (dados no aparelho) não são destacadas por nenhum concorrente; são os diferenciais reais do app e podem entrar na curta e nas screenshots, sem prometer precisão exata.
- O líder está sem atualização há cerca de um ano; atualizações frequentes e "tabelas 2026" são um sinal de frescor.
- Termos que os concorrentes cobrem e nós não: "seguro-desemprego" (não existe no app: não prometer), "salário líquido", "horas extras" (fora de escopo). Foco: rescisão, férias, 13º, FGTS, INSS e IRRF.

## Backlog priorizado

1. **P0** #1, #2, #5: política, Data Safety e e-mail (B7-01, B7-02, B7-05), com a decisão do responsável sobre o que o app coleta.
2. **P0** #3, #4 + P2 #13 a #16: change A (código e manifest).
3. **P1** #6 a #8: `listing-pt-BR.md` (change B), já reconciliada com o item 1.
4. **P1** #9: screenshots (change D).
5. **P1** #11 e #12: avaliação no app (G) e `whatsnew` (F).
6. **P1** #10: decidir a categoria.

## Medição (depois de publicar)

Baseline com as 2 a 4 primeiras semanas do Play Console: impressões, conversão da listagem, instalações, retenção D1 e D7, nota. Repetir esta auditoria com a mesma régua depois das mudanças.
