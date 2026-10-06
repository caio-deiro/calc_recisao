## Why
O PRD (§6.1, §6.6; decisões Q23, Q26, Q27) inclui a rescisão indireta e os contratos por prazo determinado com término normal, rescisão antecipada pelo empregador (art. 479 CLT), rescisão antecipada pelo empregado (art. 480 CLT) e cláusula assecuratória (art. 481 CLT). Hoje existe um único tipo "Prazo Determinado" (`fixedTerm`) sem data de fim. A tabela `TerminationRules` (B2-02) já reserva `hasIndemnity479` e `hasDiscount480`, sempre falsos, e `validationPendingRules` já conhece as regras `art479` e `art480`. Esta change é o bloco B4 do `docs/SPECS.md`.

## What Changes
- `TerminationType` ganha `indirectTermination`, `fixedTermEnd`, `fixedTermEarlyByEmployer`, `fixedTermEarlyByEmployee`; `fixedTerm` sai do enum e vira alias de leitura do histórico para `fixedTermEnd` (B4-01, B4-02).
- `TerminationRules` ganha as quatro entradas da matriz do PRD §6.1 e a resolução da cláusula assecuratória **na própria tabela** (B4-01, B4-04, B4-08).
- `TerminationInput` ganha `fixedTermEndDate` e `hasRecipientClause`, com validações (B4-03).
- Novos itens `BreakdownCode.indemnity479` (provento, fora de IRRF e INSS) e `indemnity480` (desconto, fora da base de impostos) e o aviso "valor máximo; depende de comprovação do prejuízo" (B4-05, B4-06).
- Término normal sem aviso e sem multa; indireta idêntica ao sem justa causa, sem ramificação nova no use case (B4-07, B4-08).
- Formulário mostra os campos novos só nos tipos a prazo; `TerminationTypeCard` lista os tipos novos em linguagem simples (B4-09).
- Art. 479 e 480 continuam em `validationPendingRules` e saem com a premissa "cálculo em validação" (B6-04).

## Capabilities
### New Capabilities
- `fixed-term-contracts`: entrada, validação, formulário e resultado dos contratos a prazo e da rescisão indireta.
### Modified Capabilities
- `calculation-core`: requisitos "Rules table by termination type", "Termination type name mapping" e "FGTS withdrawal percent in the rules table"; novos requisitos do art. 479/480 e da cláusula assecuratória.

## Impact
`lib/domain/entities/` (`termination_type`, `termination_input`, `breakdown_code`, `calculation_history`, `assumption`), `lib/domain/rules/termination_rules.dart`, `lib/domain/usecases/calculate_termination.dart`, `lib/core/validators/termination_input_validator.dart`, `lib/presentation/screens/form/`, `lib/presentation/widgets/termination_type_card.dart`, resultado/PDF/compartilhamento (texto dos itens novos), `test/golden/` (casos novos; `golden_prazo_determinado_termino` muda de tipo), `.maestro/`. Docs: `docs/PROJECT.md §6.1/§6.6`, `docs/ARCHITECTURE.md`, `docs/golden-dossie/README.md`. Histórico antigo com `fixedTerm` continua abrindo.

## Fora de escopo
Limite de 2 anos e prorrogação do contrato a prazo (CLT arts. 445 e 451), contrato de experiência como tipo próprio, estabilidades, remoção da marca "cálculo em validação" (depende de caso golden com fonte, B6), qualquer mudança de regra de B2/B3.
