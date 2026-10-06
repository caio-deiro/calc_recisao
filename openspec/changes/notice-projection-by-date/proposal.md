## Why

A projeção do aviso prévio indenizado (C2, decisão Q7a do PRD) hoje é `diasDeAvisoPagos ~/ 30` meses somados às avos de 13º e de férias proporcionais. Isso ignora **quando** o aviso termina: a OJ 82 da SDI-1 do TST manda tratar a saída como ocorrida na data do fim do aviso, "ainda que indenizado", e a CLT art. 487 §1º integra o período do aviso ao tempo de serviço. Com datas, o resultado muda para mais ou para menos que o "+1 por 30 dias": aviso de 45 dias a partir de 05/09/2026 termina em 20/10/2026 e dá 10 avos de 13º (não 8+1); aviso pago de 24 dias a partir de 31/07/2026 termina em 24/08/2026 e dá +1 avo de 13º mas nenhum de férias.

Decisão do responsável (2026-10-06, sem contador; confia em lei e internet; fonte `calculo_legal`): **revisar a decisão Q7a / C2 do PRD** e fazer a projeção por data. Esta change registra a revisão a pedido dele; não é uma reabertura por iniciativa do planejamento.

## What Changes

- `lib/domain/rules/avos.dart`: remove `noticeProjectionMonths(noticeDays) = noticeDays ~/ 30`. As avos de 13º e de férias proporcionais passam a ser contadas até a **data efetiva** `terminationDate + diasDeAvisoPagos` (calendário, sem horário), pela mesma regra de 15 dias e teto 12 já existentes.
- `lib/domain/usecases/calculate_termination.dart`: calcula a data efetiva, passa às duas funções de avos (no lugar do parâmetro `projection`) e escreve a Assumption `noticeProjection` e a mensagem com os **avos extras reais** (com a projeção menos sem a projeção) e a data de fim do aviso.
- Acordo mútuo: dias pagos = metade do aviso (já existente); a projeção usa os dias **pagos**. Segue ⚖️ com a marca "cálculo em validação" (`noticeProjectionMutualAgreement`).
- Casos golden: recalculados pela lei os afetados (`golden_sem_justa_causa_c2_c5`, `golden_rescisao_indireta`), revisada a descrição de `golden_prazo_antecipada_empregador_clausula` (valores iguais), e `golden_acordo_mutuo` promovido de `docs/golden-dossie/rascunho/` para `test/golden/cases/` com valores recalculados; o rascunho é removido.
- Docs (por tasks, o planejador não edita `docs/`): `docs/PROJECT.md` §6.2/§6.3 (C2), `docs/SPECS.md` B2-05, `docs/golden-dossie/README.md`.

## Capabilities

### New Capabilities
Nenhuma.

### Modified Capabilities
- `calculation-core`: requisitos `C2 notice projection in vacation and thirteenth` (reescrito: projeção por data), `C3 proportional vacation by acquisitive period` (referência à projeção) e `C5 independent INSS on thirteenth` (apenas o cenário do caso golden, cujos valores mudam).

## Impact

- Código: `lib/domain/rules/avos.dart`, `lib/domain/usecases/calculate_termination.dart`. Sem dependência nova, sem mudança de camada.
- Testes: `test/unit/avos_test.dart` (grupo de projeção reescrito), `test/unit/calculation_core_test.dart`, `test/unit/termination_2026_test.dart`, `test/unit/accrued_vacation_test.dart` e outros que assumem "+N mês" por 30 dias (revisar); casos golden.
- Histórico: registros salvos mantêm o texto e os valores antigos (a Assumption é serializada pronta; nenhuma migração).
- Regras ⚖️: a projeção por data (leitura da OJ 82 / art. 487 §1º / Súmula 371 aplicada a avos) e o acordo mútuo seguem sem validação profissional.

## Fora de escopo

- Criar período de férias **vencido** pela projeção quando o aniversário cai dentro do aviso (continua valendo PROJECT.md §6.4: a projeção não cria período vencido).
- Projetar o aviso no FGTS, na multa, no saldo de salário ou em qualquer verba além das avos de 13º e férias proporcionais.
- Tributação separada do 13º de dois anos-calendário (ver design.md, Riscos).
- Qualquer mudança nas tabelas fiscais, no arredondamento ou na interface.

Bloco: B2 (B2-05 C2; B2-10 premissa) e B6 (B6-03, B6-04). Decisões: revisa Q7a (PRD §16) por pedido do responsável.
