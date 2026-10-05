## Context

Hoje: `BreakdownItem` tem só `description/value/type/details`; o use case adiciona itens e depois os remove por texto (justa causa, acordo); `TerminationType` tem booleanos soltos; `TerminationResult.netAmount` inclui a multa do FGTS; `calculateTerminationTaxes` soma saldo e 13º numa única apuração de INSS e põe férias na base do IRRF; as avos contam fração `dia/30` em mês com menos de 15 dias; `CalculationHistory.fromJson` usa `firstWhere` sem `orElse` e o `HistoryRepository` ignora registros que falham. A infra golden (B6) está arquivada: `test/golden/support/provisional_code_map.dart` é uma ponte que esta change remove. Não há casos golden reais (B6-06 pendente). `Decimal` (B2-13..15) está na change `migrate-money-to-decimal`.

## Decisions

### D1. Ordem de implementação e o que bloqueia publicação
`B0-02`: toda regra começa por teste. Enquanto não há TRCT/contador, os testes de C1–C5 são **unitários com valor calculado à mão a partir do texto legal**, nunca copiados da saída do app. Quando os casos golden reais chegarem, entram em `test/golden/cases/` com `cobre` (C1–C5). Publicação exige `flutter test --tags release-gate --run-skipped` verde (B6-05); isso é o que fica bloqueado por B6-06, não o código. `migrate-money-to-decimal` depende desta change e só começa com golden real.

### D2. `BreakdownCode` e `TerminationRules` (B2-01..03)
`BreakdownCode` com os 10 códigos do SPECS, mais `legacy` (só para leitura de histórico, D5). `TerminationRules`: classe const, mapa `Map<TerminationType, TerminationRules>`. Campos: `noticePercent` (int 100/50/0), `fgtsFineShare` (double 1,0/0,5/0, multiplicando a alíquota de 40 % lida de `tax_tables.json`; não guardar 0,4/0,2 na tabela evita duplicar a alíquota, DRY), `paysThirteenth`, `paysProportionalVacation`, `paysAccruedVacation`, `noticeDeductible`, `hasIndemnity479`, `hasDiscount480` (as duas últimas `false` até B4). O use case consulta a tabela e só então adiciona itens. A fração de 50 % é aplicada **antes** de arredondar uma única vez (hoje o 50 % não é arredondado); pode mover 1 centavo, a explicar se algum caso golden divergir.
Descartado: manter `if` por tipo e só trocar texto por code (não cumpre B2-02).

### D3. C1 a C5 e avos (B2-04..08)
- **C1**: `paysAccruedVacation = true` para todos os tipos atuais.
- **C2**: função pura `noticeProjectionMonths(noticeDays)` = `noticeDays ~/ 30` (30–59 = 1, 60–89 = 2, 90 = 3). Só com aviso indenizado. No acordo mútuo usa os dias do aviso efetivamente pago (50 %). Avos totais = min(12, avos + projeção).
- **C3**: função própria `proportionalVacationMonths(admission, termination, projection)` em `lib/domain/`, contando desde o último aniversário da admissão; B3 a reaproveita. O 13º segue o ano-calendário + projeção.
- **Mês < 15 dias = zero**: um único ponto (`monthsFromDays` ou equivalente) usado por 13º e férias; substitui `dia/30`.
- **C4**: `calculateTerminationTaxes` perde o parâmetro `vacationAmount` (o INSS já excluía férias; só o IRRF as incluía).
- **C5**: `TerminationTaxResult` ganha `inssSalary` e `inssThirteenth`; `inss` = soma. IRRF mensal deduz `inssSalary`; anual deduz `inssThirteenth`. Remove a divisão proporcional de hoje.

### D4. Resultado (B2-09, B2-10, B6-04)
`TerminationResult`: `paidAtTermination`, `fgtsDeposit` (`FgtsDeposit{items,total}`), `assumptions`. `fgtsFine` sai de `additions`. `netAmount` e `totalToReceive` ficam `@Deprecated`, com a semântica antiga (incluem a multa), até B5; os consumidores (`result_screen`, `history_screen`, `pdf_utils`, `share_utils`) renderizam a multa a partir de `fgtsDeposit.items` **sem mudar o layout**. `Assumption{code, text, origin (informed|estimated), value?}` com `AssumptionCode`; a chave de UI é o code (B0-07). A premissa de validação usa `AssumptionCode.validationPending` e referencia a regra pendente. `lib/` não pode importar `test/`: `lib/domain/` mantém sua constante `validationPendingRules` e um teste a compara com `test/golden/validation_status.dart`, que continua dono do gate de cobertura.

### D5. Histórico (B2-11, B2-12)
`schemaVersion = 2` para registros novos; ausente = 1 (legado). Item sem `code` recebe `BreakdownCode.legacy` (sem inferir pelo texto, para respeitar B2-01). Registro legado: `isLegacy = true`, só marca "calculado em versão anterior", **sem recalcular**; `paidAtTermination` não é inferido e o `netAmount` original é exibido como estava. Tabela única de aliases de tipos (`fixedTerm` → `fixedTermEnd` entra quando B4-01 existir). `HistoryRepository` trabalha com as strings brutas: grava de volta as entradas ilegíveis sem alterá-las e expõe `unreadableCount`; `history_screen` mostra o aviso. Log sem dados pessoais (B0-03).
**Limite conhecido:** `_viewCalculation` (`history_screen.dart`) reabre o Resultado recalculando só com `input` e `type`; logo, "sem recalcular" vale apenas para o card/lista, e um registro legado mostra no Resultado um valor diferente do card. A correção exige a `ResultScreen` aceitar um resultado salvo, o que é B5-06 (mesma `ResultScreen` + marca legada). **Follow-up explícito de B5**, critério: "Resultado de registro legado mostra o valor salvo + a marca 'calculado em versão anterior'".

## Risks / Trade-offs
- C1–C5 e a regra de menos de 15 dias interpretam a lei (⚖️): publicar sem o gate verde é proibido; a validação vence o código (PRD §6.3).
- Contar zero para menos de 15 dias reduz 13º e férias em relação a hoje; testes existentes que fixavam `dia/30` mudam e a justificativa fica por escrito.
- Registros legados exibem totais com semântica antiga; mitigado pela marca (no card; ver limite conhecido em D5).
- **Pré-requisito de release:** B5 (premissas na UI, PDF e compartilhamento) MUST entrar antes de qualquer publicação desta change; sem isso, acordo mútuo e C1–C5 saem sem aviso ao usuário. Além disso, o release-gate (B6-05/B6-06) precisa estar verde.
- C1–C5 e a regra de menos de 15 dias são ⚖️, mas **não estão em `pendingValidationRules`** (que lista só art. 479/480, dobro e projeção no acordo mútuo); logo não geram a premissa "cálculo em validação". A mitigação é o release-gate com casos golden reais, não a marca na tela.

## Decidido pelo usuário em 2026-10-05 (antes Open Questions)
- **Dividir a change:** esta cobre B2-01..12; B2-13..15 vão para `migrate-money-to-decimal`, que depende desta e só começa com golden real (B6-06). Handoffs de B6: B2-01 (mapa provisório) e B2-10 (`Assumption`/B6-04) nesta; B2-13 (tolerância 0,00) na outra. O SPECS ainda aponta uma change só; o orquestrador ajusta `docs/`.
- **Acordo mútuo (B2-05):** a projeção usa o aviso efetivamente pago (50 %), com "cálculo em validação" até um contador confirmar. Ressalva ⚖️: CLT art. 484-A II paga as demais verbas "na integralidade", o que pode sustentar projeção do aviso integral.
- **C2, teto:** a projeção limita o total a 12 avos; confirmar com golden de novembro/dezembro (⚖️ cruzar o ano-calendário).
- **Mês com menos de 15 dias:** passa a contar ZERO (corrige o `dia/30`). Requisito e task novos, teste antes (B0-02). Lei 4.090 art. 1º §2º; ainda ⚖️.
- **Histórico legado:** só marcar "calculado em versão anterior", sem recalcular.
- **`netAmount`:** alias `@Deprecated` até B5; a multa fica visível via `fgtsDeposit`. Consumidores no código: `result_screen`, `history_screen`, `pdf_utils`, `share_utils`, `calculation_history`.

## Verificação das bases legais (firecrawl, acesso em 2026-10-05; cache em `.firecrawl/`)
| Base citada | Situação |
|---|---|
| CLT art. 146 caput e parágrafo único (`planalto.gov.br/ccivil_03/decreto-lei/del5452.htm`) | **Confirmada.** Caput: férias adquiridas devidas "qualquer que seja a causa" (C1). Parágrafo único: proporcionais não devidas na justa causa; 1/12 por mês ou fração superior a 14 dias. O art. 147 trata do período incompleto antes de 12 meses (sem justa causa ou prazo determinado). |
| CLT art. 487 §1º (mesma URL) | **Confirmada.** Falta de aviso do empregador dá direito aos salários do prazo, "garantida sempre a integração desse período no seu tempo de serviço". |
| OJ 82 SDI-1 TST (compilação em `trt2.jus.br/geral/tribunal2/TST/OJ_SDI_I.html`; página estável do tst.jus.br não localizada) | **Confirmada, com alcance menor:** a data de saída na CTPS é a do fim do aviso, ainda que indenizado. Sustenta a projeção no tempo de serviço, não fixa o cálculo em avos. |
| Súmula 380 TST | **Não necessária e não confirmada em fonte oficial.** Trata do início da contagem do aviso, não da projeção; removida das bases. |
| CLT art. 484-A I "a" e II (mesma URL) | **Confirmada:** aviso indenizado e multa por metade; demais verbas na integralidade. |
| Lei 4.090/62 art. 1º §2º (`planalto.gov.br/ccivil_03/leis/l4090.htm`) | **Confirmada:** fração igual ou superior a 15 dias é mês integral. A consequência "menos de 15 dias = zero" é leitura do usuário, ⚖️. |
| Lei 7.713/88 art. 6º V (`planalto.gov.br/ccivil_03/leis/l7713.htm`) | **Corrigida:** o inciso trata de indenização e aviso prévio por despedida; **não menciona férias**. Removida como base de C4. |
| Súmulas 125 e 386 STJ, AD PGFN 14/2008 (página PGFN, `gov.br/pgfn/pt-br/cidadania-tributaria/por-assunto/imposto-de-renda-pessoa-fisica-irpf-2/copy_of_conceito-de-rendimentos-e-verbas-nao-tributaveis/ferias`) | **Confirmadas por fonte oficial (PGFN):** cita as Súmulas 125 e 136 (indenização de direito não gozado, sem IR), 386 (férias proporcionais e 1/3 isentas) e o Ato Declaratório 14/2008 (férias em dobro sem IR). Base do IRRF em C4. O texto integral das súmulas não foi lido no site do STJ. |
| Decreto 3.048/99 art. 214 §9º IV (`planalto.gov.br/ccivil_03/decreto/d3048.htm`) | **Confirmada:** férias indenizadas, 1/3 e a dobra do art. 137 CLT não integram o salário de contribuição. Base do INSS em C4. |
| Lei 8.212/91 art. 28 §7º (`planalto.gov.br/ccivil_03/leis/l8212cons.htm`) | **Corrigida:** só diz que o 13º integra o salário de contribuição. A apuração separada está no **Decreto 3.048/99 art. 214 §6º e §7º** ("aplicação, em separado, da tabela"), nova base de C5. |
| Súmula 261 TST (proporcionais no pedido de demissão com menos de 1 ano) | Não pesquisada; fora do escopo de B2. O art. 147 CLT só cita demissão sem justa causa e término de prazo. |

Continuam ⚖️ (leitura do usuário/contador): C1 a C5 como regras de produto, acordo mútuo (art. 484-A II), teto de 12 avos e virada de ano, "menos de 15 dias = zero".

## Open Questions (restantes)
1. B6-06 (responsável): TRCTs anonimizados (um por tipo, cobrindo C1–C5), contador (art. 479/480, dobro) e calculadora de referência. Bloqueia a publicação.
2. Pedido de demissão com menos de 12 meses paga proporcionais? A matriz do PRD §6.1 diz sim; confirmar com TRCT real (Súmula 261 TST não verificada).

## Divergências PRD / SPECS / código
- SPECS B2-02 lista taxa da multa 0,4/0,2; o design usa fração sobre a alíquota do JSON (DRY).
- PRD §6.2 não menciona que o código contava fração do mês com menos de 15 dias; corrigido por decisão do usuário.
- SPECS B2-15 ("sem alterar tolerância") × B2-13/B6-02: tratado em `migrate-money-to-decimal`.
- SPECS indica uma change única para B2; agora são duas (docs a ajustar pelo orquestrador).
