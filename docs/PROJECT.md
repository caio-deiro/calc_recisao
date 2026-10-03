# PROJECT — PRD da Calculadora de Rescisão CLT

> Documento de produto (PRD) vivo. Responde **por que** o app existe, **para quem**, **o que** faz,
> **como se sustenta** e **como saberemos se está certo**. Decisões técnicas ficam em
> [ARCHITECTURE.md](ARCHITECTURE.md); identidade visual em [`DESIGN.md`](../DESIGN.md); tom e
> princípios de experiência em [`PRODUCT.md`](../PRODUCT.md).
>
> **Convenções de leitura**
> - ✅ **Atual** = confirmado no código hoje (versão 1.0.11+13).
> - 🎯 **Decidido** = decisão de produto tomada, **ainda não implementada**. É o alvo.
> - ⚖️ **Validar** = regra trabalhista/tributária que exige confirmação por contador ou advogado antes de
>   ser tratada como correta.
> - 🧪 **Hipótese** = acreditamos, mas não medimos.
>
> | Campo | Valor |
> |---|---|
> | Produto | Calculadora de Rescisão CLT (`com.caiodeiro.calcclt`) |
> | Plataforma | **Mobile apenas** (Android principal; iOS como scaffold) |
> | Responsável | Caio Guimarães (desenvolvedor solo) |
> | Última revisão | 2026-10-02 |
> | Natureza do projeto | **Projeto de portfólio**, sem meta de receita (decisão Q19) |

---

## 1. Resumo executivo

Aplicativo móvel **100 % gratuito** que **estima as verbas rescisórias de um contrato CLT em poucos
toques**, sem cadastro, sem internet obrigatória e sem enviar dados do usuário a lugar nenhum. Entrega
o valor final **e o detalhamento linha a linha**, com linguagem simples e aviso explícito de que é uma
estimativa. Sustenta-se apenas com **anúncios do AdMob**, desenhados para nunca competir com o
resultado.

**Proposta de valor:** *"Saiba quanto vai receber na rescisão, em segundos, no celular, sem planilha,
sem contador e sem cadastro — e veja de onde vem cada centavo."*

### O que mudou nesta revisão
- 🎯 **O plano PRO foi extinto.** Tudo é gratuito; a monetização é só AdMob (§8).
- 🎯 O resultado separa **"Pago na rescisão"** de **"Depositado no FGTS"** (§6.5).
- 🎯 Regras de cálculo serão corrigidas e ampliadas: períodos de férias, **férias em dobro**, **art.
  479/480**, rescisão indireta (§6).
- 🎯 Consentimento único para anúncios personalizados e analytics (§8.4, §9).

---

## 2. Problema e oportunidade

### 2.1 Problema
- Rescisão é um momento financeiramente crítico e emocionalmente carregado. O trabalhador **não sabe se
  o valor calculado pela empresa está certo**.
- As regras são complexas: o tipo de rescisão muda quais verbas existem; INSS é progressivo; IRRF varia
  por ano, dependentes e redutores; aviso prévio cresce com o tempo de casa; férias têm período
  aquisitivo e concessivo.
- As alternativas são ruins: planilhas soltas, sites cheios de anúncios e formulários longos, ou depender
  de contador/advogado (custo e demora).

### 2.2 Oportunidade
Um app **rápido, honesto e privado**, atualizado a cada virada de tabela, atendendo tanto quem está
sendo desligado quanto o profissional que faz simulações repetidas.

### 2.3 Por que agora
- INSS e IRRF **mudam todo ano** (2026 trouxe nova tabela e redutor). ✅ O app já embute 2025 e 2026.
- Manter-se atualizado é, por si só, um diferencial frente a apps abandonados.

---

## 3. Público-alvo e personas

Pesos **iguais** entre trabalhador e profissional (`PRODUCT.md`). Com o PRO extinto, ambos usam o mesmo
produto gratuito.

| | **Persona A — Trabalhador em transição** | **Persona B — Profissional de apoio** |
|---|---|---|
| Quem | Empregado CLT demitido, pedindo demissão ou negociando acordo | RH/DP, contador, advogado trabalhista |
| Contexto | Pressa e ansiedade; quer um número agora | Simulações rápidas; atendimento a clientes |
| Job to be done | "Quanto vou receber e o que está sendo descontado?" | "Conferir/simular sem abrir sistema pesado e mostrar ao cliente" |
| Dor principal | Medo de ser lesado; jargão | Retrabalho em planilha; falta de relatório |
| Sinal de valor | Entende o resultado sem ajuda | Exporta PDF e consulta o histórico |

**Não é público-alvo:** servidores estatutários, autônomos/PJ, trabalhadores domésticos/rurais, e quem
busca *parecer jurídico*.

---

## 4. Objetivos, não-objetivos e princípios

### 4.1 Objetivos
1. **Velocidade:** do tipo de rescisão ao resultado em poucos toques.
2. **Confiança:** cálculo correto e **transparente** (breakdown, premissas visíveis, totais separados).
3. **Privacidade:** nenhum dado pessoal sai do aparelho; sem login; telemetria só com consentimento.
4. **Sustentabilidade mínima:** anúncios discretos que ajudem a manter o app atualizado, sem degradar a
   experiência.

### 4.2 Não-objetivos
- **Não** é parecer jurídico, contábil nem homologação. Resultados são **estimativas educativas**.
- **Não** substitui o TRCT nem calcula verbas de processo trabalhista.
- **Não** exige conta nem cadastro.
- **Não** usa monetização agressiva (§8.3).
- **Não** é afiliado a órgão governamental.

### 4.3 Princípios (resumo; detalhes em `PRODUCT.md`)
Velocidade primeiro · Linguagem humana · Transparência gera confiança · Respeitar o momento do usuário ·
Privacidade por padrão. **Corolário:** o app nunca deve parecer mais preciso do que a legislação e os
dados informados permitem.

---

## 5. Escopo funcional

### 5.1 Funcionalidades atuais (✅)

| Área | Funcionalidade |
|---|---|
| Cálculo | 5 tipos: sem justa causa, pedido de demissão, prazo determinado, justa causa, acordo mútuo (art. 484-A) |
| Cálculo | Saldo de salário, aviso prévio, 13º, férias vencidas e proporcionais + 1/3, multa FGTS, INSS, IRRF, outros descontos |
| Resultado | Breakdown de proventos e descontos, total e líquido, com aviso legal |
| Compartilhar | Texto completo/resumido, copiar |
| Histórico | Salvamento automático dos cálculos (hoje 10 no gratuito) |
| Experiência | Onboarding, tema claro/escuro, responsivo, suporte por e-mail |
| Monetização | Banner + intersticial (AdMob) |
| **PRO (a extinguir)** | Exportar PDF, histórico ilimitado, sem anúncios, "modo offline", "suporte prioritário" |

### 5.2 Escopo alvo (🎯 decidido)

**Tudo gratuito:**
- **Exportar PDF** livre.
- **Histórico de até 100 cálculos** (FIFO), com aviso ao se aproximar do limite. 100 cobre o uso real e
  evita degradar o `SharedPreferences`; se crescer, migrar para SQLite.
- Compartilhar e copiar, como hoje.

**Removido:** compras in-app, tela PRO, "modo offline" como diferencial (o app já funciona offline para
todos) e "suporte prioritário".

**Novos tipos e regras:**

| Item | Resumo | Seção |
|---|---|---|
| Rescisão indireta | Reaproveita as regras do "sem justa causa" | §6.1 |
| Término normal de contrato a prazo | Sem aviso e sem multa de 40 %; saque do FGTS | §6.6 |
| Rescisão antecipada pelo empregador (art. 479) | Indenização de 50 % do restante + multa de 40 % | §6.6 |
| Rescisão antecipada pelo empregado (art. 480) | Desconto limitado a 1 remuneração | §6.6 |
| Cláusula assecuratória (art. 481) | Antecipação segue regras de prazo indeterminado | §6.6 |
| Períodos de férias e **férias em dobro** | Derivados da data de admissão | §6.4 |

### 5.3 Fora do escopo (explícito)
Aposentadoria, falecimento, empregado doméstico/rural, estabilidades, horas extras e adicionais
detalhados, 13º já adiantado, **férias fracionadas, abono pecuniário e férias parcialmente gozadas**,
múltiplos vínculos. Essas limitações devem constar na tela e na listagem da loja.

---

## 6. Regras de negócio

> **Atual (✅)** vem de `lib/domain/usecases/calculate_termination.dart` e `assets/config/tax_tables.json`.
> **Alvo (🎯)** vem das decisões desta revisão. Toda mudança aqui é mudança de produto: atualizar este
> documento, os testes e **citar a base legal**.

### 6.1 Matriz de verbas por tipo de rescisão

| Verba | Sem justa causa / **Indireta** 🎯 | Pedido de demissão | Justa causa | Acordo mútuo | Término normal (prazo) 🎯 | Antecipada empregador (prazo) 🎯 | Antecipada empregado (prazo) 🎯 |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Saldo de salário | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| Aviso prévio indenizado | ✔ 100 % | ✖ (desconta se não cumprir) | ✖ | ✔ 50 % | ✖ | ✖¹ | ✖ |
| 13º proporcional | ✔ | ✔ | ✖ | ✔ | ✔ | ✔ | ✔ |
| Férias vencidas (simples/dobro) 🎯 | ✔ | ✔ | **✔ 🎯 (hoje ✖)** | ✔ | ✔ | ✔ | ✔ |
| Férias proporcionais + 1/3 | ✔ | ✔ | ✖ | ✔ | ✔ | ✔ | ✔ |
| Multa FGTS | 40 % | ✖ | ✖ | 20 % | ✖ | 40 % | ✖ |
| Indenização art. 479 | — | — | — | — | — | ✔ | — |
| Desconto art. 480 | — | — | — | — | — | — | ✔ (máx. 1 remuneração) |

¹ Com **cláusula assecuratória** (art. 481), a antecipação segue as regras de prazo indeterminado
(aviso prévio, etc.).

### 6.2 Fórmulas atuais (✅)

| Verba | Regra implementada |
|---|---|
| Saldo de salário | `salário / 30 × dias trabalhados` |
| Aviso prévio | `(salário + média) / 30 × dias`, `dias = 30 + 3 × anos completos`, máx. **90** |
| 13º proporcional | `(salário + média) × meses / 12`; mês com ≥ 15 dias conta inteiro |
| Férias vencidas | `(salário + média) × 4/3` (um período, sim/não) |
| Férias proporcionais | `(salário + média) × meses / 12 × 4/3`, com meses do **ano-calendário** |
| Multa FGTS | `FGTS informado × 40 %`; senão estima `(salário + média) × 8 % × meses × 40 %` |
| Acordo mútuo | Aviso × 50 %; multa × 50 % (20 %) |

### 6.3 Correções decididas (🎯 ⚖️)

| # | Correção | Motivo |
|---|---|---|
| C1 | **Justa causa paga férias vencidas** (Q2a) | A regra geral garante férias vencidas; o código hoje as bloqueia |
| C2 | **Aviso prévio indenizado projeta tempo** nos avos de 13º e férias proporcionais (Q7a) | O aviso indenizado conta como tempo de serviço; o app subestima |
| C3 | **Férias proporcionais pelo período aquisitivo** (aniversário da admissão), não pelo ano-calendário (Q8a) | Erro sempre que a admissão não é em janeiro. O 13º segue por ano-calendário |
| C4 | **Férias indenizadas sem IRRF e sem INSS** (Q9a) | Hoje entram na base do IRRF |
| C5 | **INSS do 13º calculado separado do salário**, cada um com tabela e teto próprios (Q9a) | Hoje é calculado sobre a soma |
| C6 | **Dinheiro em `Decimal`** (Q22a) | Evita erro de ponto flutuante; introduzido só depois dos testes golden |

> C2 a C5 devem ser confirmados contra os casos de validação (§11) **antes** de entrar em produção.
> Se a validação contradisser a leitura acima, a validação vence.

### 6.4 Períodos de férias e férias em dobro (🎯 ⚖️)

- **Entrada única:** "quantos períodos de férias você já gozou?" (Q24a).
- O app **deriva**, a partir da data de admissão e da data da rescisão, cada período como:
  - **vencido simples** (período aquisitivo completo, ainda dentro do período concessivo);
  - **vencido em dobro** (período concessivo de 12 meses já expirado sem gozo);
  - **proporcional** (período aquisitivo em curso).
- A **tabela de períodos derivados** aparece nas premissas e pode ser conferida pelo usuário.

| Item | Fórmula |
|---|---|
| Vencido simples | `(salário + média) × 4/3` |
| Vencido em dobro | `2 × (salário + média) × 4/3` (1/3 sobre o total dobrado, Súmula 328 TST) |

- Aplica-se a **todos os tipos de rescisão**, inclusive justa causa e pedido de demissão.
- No resultado: linhas separadas **"Férias vencidas (simples)"** e **"Férias vencidas em dobro
  (indenização)"**.
- Tributação: indenizadas, **sem IRRF e sem INSS** (C4).

### 6.5 Resultado: dois totais e premissas (🎯)

Hoje a multa do FGTS entra no total "a receber". Na prática ela é **depositada na conta do FGTS**, não
paga no TRCT em dinheiro. Alvo:

- **Pago na rescisão** — o líquido que o trabalhador recebe.
- **Depositado no FGTS** — multa (40 % ou 20 %), com linha informativa de saque: 100 % no sem justa
  causa, 80 % no acordo mútuo.
- **Premissas desta estimativa** — seção recolhível, mostrando o que foi **informado** e o que foi
  **estimado** (ex.: FGTS estimado pelo tempo de casa), a projeção do aviso e a tabela de períodos de
  férias. Um marcador "estimado" aparece ao lado do valor quando for aproximado.
- A mesma estrutura vale para **compartilhamento e PDF**.

### 6.6 Contratos por prazo determinado (🎯 ⚖️)

Hoje existe um único tipo "Prazo Determinado". Passa a haver:

1. **Término normal:** sem aviso, **sem multa de 40 %**, com saque do FGTS, 13º e férias proporcionais.
2. **Antecipada pelo empregador (art. 479):** indenização de **metade da remuneração devida até o fim do
   contrato** + multa de 40 %.
3. **Antecipada pelo empregado (art. 480):** o empregado indeniza o empregador pelo prejuízo, **limitado
   ao que o empregador pagaria pelo art. 479**. O app **desconta da rescisão**, com teto de **1
   remuneração mensal** (art. 477 §5º). O resultado traz o aviso *"valor máximo; depende de comprovação
   do prejuízo"*.
4. **Cláusula assecuratória (art. 481):** marcador que, quando ativo, faz a antecipação seguir as regras
   do contrato por prazo indeterminado.

A **data de término prevista** passa a ser obrigatória nesses tipos.

| Item | Fórmula |
|---|---|
| Indenização art. 479 | `(salário + média) / 30 × dias restantes × 50 %` |
| Desconto art. 480 | `min(valor do art. 479, 1 remuneração mensal)` |

Tributação: a indenização do art. 479 **não sofre IRRF nem INSS**; o desconto do art. 480 é uma dedução e
não altera a base dos impostos.

### 6.7 Descontos (✅ + 🎯)
- **INSS:** tabela progressiva por **data da rescisão**, com teto. (🎯 13º calculado à parte, C5.)
- **IRRF:** tabelas mensal/anual por ano, dedução por dependente, redutor 2026. (🎯 sem férias
  indenizadas, C4.)
- **Outros descontos:** valor livre. O usuário pode **desligar o cálculo de impostos**.
- Valores arredondados a 2 casas.

### 6.8 Limitações conhecidas (comunicar na UI)
1. Resultado é **estimativa**; o TRCT oficial prevalece.
2. Sem FGTS informado, a multa é aproximação com o salário atual (ignora reajustes, saques, depósitos).
3. Não trata feriados, faltas, licenças ou adicionais além da média informada.
4. Itens do §5.3 estão fora do escopo.

---

## 7. Jornada do usuário

```
Instalação → Splash → Onboarding (1ª vez) → Home
   → escolhe o tipo → preenche os dados → vê o Resultado
        ├─ [1º resultado] aviso único de consentimento (anúncios e analytics)
        ├─ compartilha / copia / exporta PDF  (tudo gratuito)
        ├─ salva automaticamente no histórico (até 100)
        └─ ao SAIR do Resultado → pode aparecer um intersticial (§8.2)
```

**Atrito aceitável:** banner no rodapé; intersticial ao sair do Resultado.
**Atrito inaceitável:** qualquer anúncio ou aviso antes de o usuário ver o resultado.

⚠️ **Divergência atual:** hoje o intersticial abre **assim que o resultado é renderizado**, cobrindo o
número. Isso contraria o princípio acima e será corrigido (§8.2).

---

## 8. Modelo de negócio

### 8.1 Visão
Gratuito e **sem plano pago**. A única receita são os anúncios do **AdMob**. Não há meta de receita
(Q19b): o objetivo é cobrir, se possível, o custo de manutenção, sem sacrificar a experiência. O PRD não
define KPIs de MRR, conversão ou churn.

### 8.2 Formatos e posicionamento (🎯 Q16a)
- **Banner adaptativo fixo no rodapé** em todas as telas, **exceto Formulário e Splash**.
- **Intersticial somente ao sair do Resultado** (por exemplo, ao voltar para a Home ou ao
  compartilhar), **nunca ao entrar**, com **no máximo 1 a cada 3 minutos e 1 por sessão**.
- **Sem anúncio recompensado**: com tudo gratuito não há o que recompensar, e ele adicionaria atrito.

### 8.3 Guardrails
- Anúncios nunca competem com a tarefa principal nem aparecem **antes** do resultado.
- Sem textos que explorem a ansiedade do usuário.
- A experiência de cálculo é completa e idêntica para todos.

### 8.4 Consentimento (🎯 Q13a, Q17a)
- **Um único aviso**, mostrado **após o primeiro resultado**, com o formulário de consentimento do Google
  (UMP) e a escolha sobre analytics.
- **Anúncios não personalizados até o consentimento.**
- **Analytics é opt-in.** O Crashlytics fica sob o mesmo consentimento.
- 🧪 A contrapartida é um eCPM menor; reavaliar com dados reais do AdMob.

### 8.5 Encerramento do PRO
- ✅ **Não há assinantes** (Q15). Não há reembolso nem aviso a fazer.
- Desativar no Play Console o produto `calc_recisao_pro_monthly`.
- Remover do app: `PurchaseService`, `ProScreen`, `ProUtils`, `OfflineService` e as dependências
  `in_app_purchase*`. A exigência de Billing Library ≥ 8.0 deixa de se aplicar.
- Atualizar a listagem da loja, a política de privacidade e a Data Safety (§12).

### 8.6 Custos
Sem servidor. Custos: taxa única da conta Google Play, comissão zero (sem vendas), tempo de manutenção
anual das tabelas, hospedagem da política de privacidade (GitHub Pages — `_config.yml`).

---

## 9. Métricas e analytics

Sem metas de receita. As métricas servem para **saber se o app é usado e se está correto**.

### 9.1 Eventos (🎯 Q21a), apenas com consentimento
Nenhum evento carrega valores financeiros, salários ou datas.

| Evento | Parâmetro |
|---|---|
| `calc_completed` | `tipo_rescisao` |
| `share_used` | — |
| `pdf_exported` | — |
| `consent_decision` | `aceitou` \| `recusou` |

### 9.2 Outras fontes (sem código nosso)

| Categoria | Métrica | Fonte |
|---|---|---|
| Aquisição e retenção | Instalações, D1/D7/D30 | Play Console |
| Qualidade | Nota, ANR, crash | Play Console / Crashlytics |
| Anúncios | Impressões, eCPM, receita | AdMob |
| Corretude | Casos de teste aprovados; bugs de cálculo reportados | Testes e suporte |

⚠️ Os "percentuais de uso" e "metas de conversão" dos documentos anteriores não tinham fonte e foram
descartados.

---

## 10. Requisitos não funcionais

| Requisito | Critério |
|---|---|
| **Desempenho** | Resultado em < 1 s após o envio; app abre em ≤ 2 s |
| **Disponibilidade** | 100 % funcional sem internet (só anúncios precisam de rede) |
| **Privacidade** | Nada de dado pessoal; telemetria só com consentimento; política fiel ao comportamento real |
| **Correção** | Toda regra coberta por teste; tabelas atualizadas até **janeiro** de cada ano |
| **Acessibilidade** | Texto legível, alvos de toque adequados, sem depender só de cor |
| **Compatibilidade** | Android 7.0+ (`minSdk 24`), target 36 |
| **Compliance** | Política da Play (target SDK, 16 KB, declaração de anúncios, Data Safety), LGPD |

---

## 11. Validação das regras de cálculo

Os testes atuais verificam *o que o código faz*, não *o que é correto*. Decisão (Q10, Q28a):

1. **Testes golden** a partir de **TRCTs reais anonimizados** (fornecidos pelo responsável), em que o
   resultado esperado vem do documento, e não do código.
2. **Calculadora oficial de referência** para os casos que não houver TRCT.
3. **Art. 479/480 e férias em dobro:** poucos TRCTs reais. Validar por **citação direta de artigos da CLT
   e súmulas do TST**, mais **2 a 3 exemplos resolvidos à mão** confirmados por um contador, antes de
   publicar.
4. **Plano B:** se a revisão não chegar a tempo, essas regras saem com o aviso *"cálculo em validação"*,
   em vez de ficarem ocultas ou de serem apresentadas como certas.

**Formato de um caso golden:** tipo de rescisão, datas de admissão e de rescisão, salário, média de
variáveis, dependentes, FGTS informado, períodos de férias gozados e o valor de cada verba do documento.

---

## 12. Riscos e mitigação

| # | Risco | Prob. | Impacto | Mitigação |
|---|---|:-:|:-:|---|
| R1 | **Cálculo incorreto** gera decisão financeira errada e dano reputacional | M | Alto | Golden tests, validação (§11), aviso legal, canal de reporte |
| R2 | Tabelas defasadas após a virada do ano | A | Alto | Checklist anual (§13) |
| R3 | O escopo ampliado (dobro, 479/480) introduz erros novos | M | Alto | Versões pequenas, validação reforçada, plano B do §11 |
| R4 | Mudança de política da Play (target SDK, 16 KB) | M | Alto | Specs em `openspec/` |
| R5 | Anúncios percebidos como invasivos geram avaliação ruim | M | M | Guardrails §8.3; intersticial só ao sair do Resultado |
| R6 | eCPM baixo (anúncios não personalizados, nicho BR) | A | Baixo | Sem meta de receita; revisar com dados reais |
| R7 | Política de privacidade/Data Safety incoerente com AdMob e Crashlytics | M | Alto | Atualizar antes de publicar (§14) |
| R8 | Concorrentes gratuitos | A | M | Velocidade, privacidade, transparência e atualização anual |
| R9 | Dependência de uma só pessoa | A | M | Documentação e testes |

---

## 13. Operação e manutenção

### Checklist anual de tabelas (janeiro)
1. Obter a Portaria do INSS (faixas e teto) e a tabela de IRRF/redutor do ano.
2. Atualizar `assets/config/tax_tables.json` e a seleção por ano em `TaxTablesService`.
3. Criar `test/unit/termination_<ano>_test.dart` com casos de borda.
4. Citar a portaria no commit; publicar e atualizar a listagem ("Trabalhista <ano>").

### Cadência
- Avaliações e reportes de erro: semanal. Políticas da Play e SDKs: trimestral.
- Revisão deste PRD: a cada release com mudança de regra, anúncios ou escopo.

---

## 14. Legal e conformidade

- **Natureza da informação:** simulação educativa; aviso legal visível no resultado e na loja.
- **Sem afiliação governamental:** reforçar nas telas e na loja.
- **LGPD / Data Safety:** a política atual afirma "não coleta dados", mas o app usa **AdMob** (identificador
  de publicidade) e, quando ativo, **Crashlytics/Analytics**. A política, a Data Safety e a declaração
  "contém anúncios" precisam refletir isso **antes da próxima publicação**.
- **Contatos divergentes:** a política usa `caioguimaraes12@outlook.com`; o app usa
  `suporte@calcrescisao.com`. Confirmar o que existe. Com o PRO extinto, `pro@calcrescisao.com` deixa de
  ser necessário.

---

## 15. Plano de execução

Quatro changes de OpenSpec, **em sequência**, cada uma como uma versão pequena (Q20a, Q28a):

| # | Change | Conteúdo |
|---|---|---|
| 1 | `remove-pro-ads-only` | Remove PRO, compras e `OfflineService`; PDF livre e histórico de 100; novo posicionamento de anúncios; consentimento (UMP + analytics); eventos |
| 2 | `fix-calculation-rules` | C1 a C5, dois totais e premissas (§6.5), golden tests, depois `Decimal` (C6) |
| 3 | `add-vacation-periods` | Períodos de férias e férias em dobro (§6.4) |
| 4 | `add-fixed-term-and-indirect` | Tipos de prazo determinado, art. 479/480, assecuratória, rescisão indireta (§6.6) |

**Pendências do responsável:** fornecer TRCTs reais anonimizados; contador para os exemplos manuais;
desativar o produto `calc_recisao_pro_monthly` no Play Console.

---

## 16. Registro de decisões (Q1–Q28)

| Q | Decisão |
|---|---|
| 1 | Resultado com "Pago na rescisão" e "Depositado no FGTS" separados |
| 2 | Justa causa paga férias vencidas |
| 3 | Promessa de precisão: estimativa educativa, com premissas visíveis |
| 4, 12, 14 | **Superadas**: não há mais PRO |
| 5 | Firebase Analytics com eventos mínimos e consentimento |
| 6 | Sem promessas de recursos inexistentes (tela PRO removida) |
| 7 | Aviso indenizado projeta tempo para 13º e férias |
| 8 | Férias proporcionais pelo período aquisitivo (detalhada na Q24) |
| 9 | Férias indenizadas sem IRRF/INSS; INSS do 13º separado |
| 10 | Validação por TRCTs reais (a) + calculadora oficial (b) |
| 11 | Dois totais + seção recolhível de premissas; mesma estrutura no PDF |
| 13 | Consentimento opt-in após o 1º resultado |
| 15 | Não há assinantes |
| 16 | Banner no rodapé + intersticial ao sair do Resultado (≤ 1/3 min e 1/sessão) |
| 17 | Anúncios não personalizados até o consentimento (UMP) |
| 18 | PDF livre; histórico de 100 itens |
| 19 | Sem meta de receita (projeto de portfólio) |
| 20 | Começar pela remoção do PRO, depois as correções |
| 21 | Quatro eventos de analytics |
| 22 | `Decimal` no domínio, após os testes golden |
| 23 | Rescisão indireta, término normal, **art. 479/480 e férias em dobro** incluídos |
| 24 | Entrada "períodos já gozados", derivando simples/dobro/proporcional |
| 25 | Dobro = `2 × base × 4/3`, linhas separadas, sem impostos |
| 26 | Quatro tipos de contrato a prazo, com cláusula assecuratória |
| 27 | Art. 479 = 50 % do restante; art. 480 limitado a 1 remuneração |
| 28 | Quatro changes em sequência, com validação reforçada |

---

## 17. Glossário

| Termo | Significado |
|---|---|
| **CLT** | Consolidação das Leis do Trabalho |
| **TRCT** | Termo de Rescisão do Contrato de Trabalho |
| **FGTS** | Fundo de Garantia do Tempo de Serviço (8 % ao mês) |
| **Multa do FGTS** | 40 % (sem justa causa) ou 20 % (acordo), depositada na conta do FGTS |
| **INSS / IRRF** | Contribuição previdenciária / imposto de renda retido na fonte |
| **Período aquisitivo** | 12 meses de trabalho que geram direito a férias |
| **Período concessivo** | 12 meses seguintes, em que o empregador deve conceder as férias |
| **Férias em dobro** | Pagamento dobrado quando o período concessivo expira sem gozo |
| **Art. 479 / 480** | Indenização da rescisão antecipada de contrato a prazo (empregador / empregado) |
| **Art. 481** | Cláusula assecuratória do direito recíproco de rescisão antecipada |
| **UMP** | User Messaging Platform, o formulário de consentimento do Google |

---

## 18. Documentação relacionada

| Arquivo | Conteúdo |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Stack, camadas, fluxo de dados, dívidas técnicas |
| [`../PRODUCT.md`](../PRODUCT.md) | Registro, personalidade de marca, princípios de design |
| [`../DESIGN.md`](../DESIGN.md) | Tokens e componentes de design |
| `../openspec/specs/` | Specs de compliance (target SDK; `play-billing` será arquivada na change 1) |
| `../google-play-assets/` | Material de listagem da loja |
