## Context

C2 (PRD §6.3, Q7a) soma `noticeDays ~/ 30` avos. O responsável decidiu, em 2026-10-06 e sem contador, aplicar a lei por data. Esta change **revisa a Q7a a pedido dele**.

## Fontes (acessadas em 2026-10-06)

- **OJ 82 SDI-1 TST**: "A data de saída a ser anotada na CTPS deve corresponder à do término do prazo do aviso prévio, ainda que indenizado." Texto confirmado apenas por **citação em acórdão do TST** (https://jurisprudencia-backend2.tst.jus.br/rest/documentos/192978dab9d33f3346a041b0cd1d908e) e em páginas secundárias (Sescon-RJ, https://sescon-rj.org.br/2019/09/19/data-da-baixa-na-ctps-sob-otica-da-oj-82-da-sdi-1-do-tst/). **O texto primário da OJ (página de orientações do TST) não foi lido.** A OJ trata da data de baixa na CTPS; que ela gere avos é a leitura do responsável, junto com CLT art. 487 §1º (o período do aviso integra o tempo de serviço para todos os efeitos legais) e Súmula 371 TST. Nada disso valida a regra: segue ⚖️.
- Lei 4.090/62 art. 1º §2º (13º, fração de 15 dias ou mais é mês); CLT art. 146 parágrafo único e art. 147 (férias proporcionais), já usados no código.
- Acordo mútuo (CLT art. 484-A I "a": metade do aviso): a projeção pelos dias pagos vem de fontes secundárias (COAD, Empresário Online), sem norma primária explícita. **Fonte fraca; continua ⚖️ com a marca "cálculo em validação".**

## Decisões

1. **Data efetiva** `E = terminationDate + diasDeAvisoPagos` dias de calendário, montada com `DateTime(y, m, d + n)` (sem `Duration`, para não depender de horário nem de fuso). `diasDeAvisoPagos` é o `paidNoticeDays` que o use case já calcula (`noticeDays * noticePercent ~/ 100` quando há aviso indenizado, senão 0). Sem aviso indenizado, `E = terminationDate` e nada muda.
2. **13º**: `thirteenthMonths(admission, termination, {noticeEnd})`. Mesmo ano-calendário: conta os meses de janeiro (ou da admissão) até `E`, regra de 15 dias, teto 12. **Virada de ano** (`E.year > termination.year`): o contrato segue vigente até `E` (OJ 82), logo o 13º do ano da rescisão fica completo e o do ano de `E` começa. O app não sabe se o 13º do ano da rescisão foi quitado; como já cobra o 13º do ano da rescisão na rescisão, **soma os dois**: `avos = avos(ano da rescisão até 31/12) + avos(1º de janeiro até E)`, cada parcela com teto 12. Isso se afasta da leitura literal "só o ano da data efetiva", que faria uma rescisão em dezembro perder ~11 avos já devidos; o responsável pediu que a escolha fosse resolvida pela lei e documentada. Exemplo: admissão 10/03/2020, rescisão 20/12/2026, 30 dias pagos, `E = 19/01/2027`: 12 (2026) + 1 (janeiro/2027, 19 dias) = 13 avos.
3. **Férias proporcionais**: `proportionalVacationMonths(admission, termination, {noticeEnd})`. O início do período aquisitivo é o último aniversário da admissão **na data da rescisão** (como hoje); a contagem vai até `E` (meses completos + fração de 15 dias, teto 12). Se o aniversário cai dentro do aviso, a contagem passa de 12 e é limitada a 12, o mesmo resultado prático do `+N` antigo; **não** se cria período vencido (PROJECT.md §6.4, fora de escopo).
4. **Mensagem e premissa**: `Assumption(code: noticeProjection, origin: estimated)`. Texto: `Aviso indenizado projetado até DD/MM/AAAA: +A avo(s) no 13º e +B avo(s) nas férias proporcionais.` com `A = avos13(com E) - avos13(sem projeção)` e `B` análogo (os avos extras reais; podem ser 0, mas a premissa aparece sempre que `diasPagos > 0`, para o usuário ver a data). `value` = `diasPagos` (era `+N`; consumidores de `value` são só testes). Cláusula omitida para a verba que o tipo não paga. Para acordo mútuo, a marca "cálculo em validação" (`noticeProjectionMutualAgreement`) vem junto, como hoje.
5. **Remoção**: `noticeProjectionMonths` e o parâmetro `projection` saem. O `details` do 13º (`N/12 do ano da rescisão`) passa a `N/12` com a decomposição `(a do ano X + b do ano Y)` só quando há virada de ano.
6. **Casos golden recalculados à mão** (nunca pela saída do app), fonte `calculo_legal`. Contas no fim deste arquivo.

### Alternativas descartadas

- **Manter `~/ 30` e só documentar**: contraria a decisão do responsável.
- **Só o ano da data efetiva no 13º, literal**: perde avos já devidos em rescisões de dezembro (ver decisão 2).
- **Derivar os períodos de férias vencidos até `E`**: mudaria férias vencidas/em dobro e o stepper do formulário; fora do pedido. Registrado como questão aberta.

## Módulos afetados

`lib/domain/rules/avos.dart` (funções de avos; `addMonths` e `countsAsMonth` ficam), `lib/domain/usecases/calculate_termination.dart` (data efetiva, premissa, `details`), testes e casos golden. `vacation_periods.dart`, `termination_rules.dart` e a UI não mudam.

## Compatibilidade

Resultados antigos do histórico guardam a Assumption pronta; não há migração e o texto antigo ("+N mês(es)") continua legível. Cálculos refeitos a partir da entrada dão o valor novo.

## Riscos

- ⚖️ A leitura da OJ 82 / art. 487 §1º / Súmula 371 como regra de avos por data é do responsável, sem contador. Se um TRCT real ou contador divergir, ele prevalece e esta change se reverte.
- ⚖️ Virada de ano: INSS e IRRF do 13º são apurados sobre **uma** parcela (soma dos dois anos), tratando-a como a do mês da rescisão; legalmente seriam dois 13º, cada um com teto de INSS e tabela próprios. Simplificação aceita; só afeta rescisões em que o aviso cruza 31/12.
- ⚖️ Acordo mútuo: fonte secundária.
- Aniversário dentro do aviso: férias do período completo não aparecem como vencidas (limite herdado).
- Testes existentes que fixam `+N mês` por 30 dias quebrarão e devem ser reescritos pela lei (tasks), não ajustados à saída.

## Open Questions

1. Aniversário da admissão dentro do aviso deve criar período de férias vencido? Recomendação: não nesta change (escopo); abrir change própria se o responsável quiser.
2. 13º com virada de ano: tributar como dois 13º? Recomendação: manter uma parcela até haver demanda.
3. Texto primário da OJ 82 não lido: reconfirmar no site do TST quando houver acesso.

## Contas à mão (INSS 2026: 7,5% até 1.621,00; 9% até 2.902,84; 12% até 4.354,27; 14% até 8.475,55, teto = 988,09; IRRF mensal 2026 e redução da Lei 15.270, conforme `docs/golden-dossie/README.md`)

**A. `golden_sem_justa_causa_c2_c5` e `golden_rescisao_indireta`** (admissão 10/03/2021, rescisão 05/09/2026, salário 12.000, 1 dependente, aviso indenizado de 30 + 3×5 = 45 dias): `E = 05/09 + 45 = 20/10/2026`. 13º: janeiro a setembro = 9, outubro com 20 dias conta = **10 avos** → 12.000 × 10 / 12 = **10.000,00** (antes 9.000,00). Férias: 10/03/2026 a 10/10/2026 = 7 meses, resto 11 dias (não conta) = **7 avos** → 12.000 × 7 / 9 = 9.333,33 (igual). Aviso 18.000,00, saldo 2.000,00 (5 dias), férias vencidas 16.000,00, multa FGTS 16.000,00 (40% de 40.000). INSS saldo 155,69 (121,575 + 379 × 9%); INSS 13º: 10.000 acima do teto = 988,09; total **1.143,78** (igual). IRRF saldo: 2.000 − 155,69 − dedução (simplificado 607,20 > 155,69 + 189,59) → 1.392,80, isento = 0. IRRF 13º: 10.000 − 988,09 − 189,59 = 8.822,32; 27,5% = 2.426,138 − 908,73 = 1.517,408 → **1.517,41** (sem redução, bruto acima de 7.350). Proventos 2.000 + 18.000 + 10.000 + 16.000 + 9.333,33 = **55.333,33**; descontos 1.143,78 + 1.517,41 = **2.661,19**; pago na rescisão **52.672,14**; FGTS depositado 16.000,00.

**B. `golden_acordo_mutuo`** (admissão 15/01/2020, rescisão 31/07/2026, salário 3.500, sem dependentes, aviso 30 + 3×6 = 48 dias, acordo paga 24): `E = 31/07 + 24 = 24/08/2026` (o rascunho/pedido citava 29/08: a conta correta é 24/08). 13º: janeiro a julho = 7, agosto com 24 dias conta = **8 avos** → 3.500 × 8 / 12 = **2.333,33**. Férias: 15/01/2026 a 15/08/2026 = 7 meses, resto 10 dias (15 a 24/08, inclusive) não conta = **7 avos** → 3.500 × 7 / 9 = **2.722,22** (rascunho: 8 avos, 3.111,11). Saldo 3.500,00 (30 dias), aviso 3.500 / 30 × 48 × 50% = 2.800,00, multa 20% de 35.000 = 7.000,00. INSS saldo 308,60 (236,9406 + 597,16 × 12%), 13º 185,68 (121,575 + 712,33 × 9%), total **494,28**; IRRF 0,00 (bases abaixo de 5.000: redução zera). Proventos 3.500 + 2.800 + 2.333,33 + 2.722,22 = **11.355,55**; descontos **494,28**; pago na rescisão **10.861,27**; FGTS depositado 7.000,00. Coerência: férias 7 avos e saldo iguais ao `golden_acordo_mutuo_aviso_trabalhado`.

**C. `golden_prazo_antecipada_empregador_clausula`** (admissão 12/06/2026, rescisão 20/10/2026, aviso 30 dias indenizado): `E = 19/11/2026`. 13º: junho (19 dias) a outubro = 5, novembro com 19 dias conta = 6 avos = 1.200,00; férias: 12/06 a 12/11 = 5 meses, resto 8 dias = 5 avos = 1.333,33. **Valores iguais**; só a descrição ("projetado em 1 avo") é reescrita.

**D. Testes de avos (unitários)**: (1) A: 13º 10 e férias 7. (2) menos avos que o método antigo: adm 15/01/2016, rescisão 15/08/2026, 60 dias pagos: `E = 15/08 + 60 = 14/10/2026` (16 dias até 31/08, +30 de setembro = 46, +14); 13º = janeiro a setembro = 9 (agosto com 15 dias já contava na rescisão; outubro com 14 dias não conta); antes (8 + 60 ÷ 30) dava 10. Férias: início 15/01/2026; 8 meses completos até 15/09, resto 15/09 a 14/10 = 30 dias conta = 9; antes (7 + 2) também 9. (3) B: 13º 8, férias 7. (4) virada de ano: adm 10/03/2020, rescisão 20/12/2026, 30 dias, `E = 19/01/2027`: 13º = 12 + 1 = 13; férias: 10/03/2026 a 10/01/2027 = 10 meses, resto 10 dias = 10. (5) aniversário no aviso: adm 10/03/2021, rescisão 05/03/2026, 45 dias, `E = 19/04/2026`: férias: início 10/03/2025, 13 meses → limitado a 12; 13º = 4. (5b) teto: adm 10/03/2020, rescisão 26/02/2026, 48 dias, `E = 15/04/2026`: férias 13 → 12; 13º = 4. (5c) 33 dias: adm 10/03/2025, rescisão 20/05/2026, `E = 22/06/2026`: 13º 6, férias 3; 60 dias (adm 2015, 26/08/2025, `E = 25/10/2025`): 13º 10, férias 8; 90 dias (adm 2005, `E = 24/11/2025`): 13º 11, férias 9. (6) dias pagos 0: `E` = rescisão, avos iguais às atuais. (7) `DateTime(2026, 12, 31 + 1)` vira 01/01/2027 (sem horário).
