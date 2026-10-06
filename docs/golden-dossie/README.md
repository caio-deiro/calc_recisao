# Dossiê dos casos golden (cálculo legal, sem contador)

**Status (2026-10-05):** decisão do responsável: sem acesso a contador, os casos se apoiam em **lei e fontes oficiais**, com `fonte.tipo = "calculo_legal"` (cálculo manual, sem revisão profissional). Isso é mais fraco que `trct` ou `exemplo_contador`: se um TRCT real ou um contador aparecer, ele prevalece.

- **Promovidos** para `test/golden/cases/` (batem com o app): `golden_justa_causa_c1`, `golden_pedido_demissao`, `golden_prazo_determinado_termino`, `golden_sem_justa_causa_c2_c5`, `golden_inss_arredondado_por_parcela` (o bug do IRRF do 13º foi corrigido pela change `fix-thirteenth-irrf`) e `golden_acordo_mutuo` (change `notice-projection-by-date`, com a projeção do aviso por data; valores recalculados pela lei, não os do rascunho original).
- **Pendente** em `rascunho/`: nenhum caso.

**Por que existe:** o teste golden só vale se o valor esperado vier de **fora do app** (B6-03, `docs/PROJECT.md` §11). Estes casos foram calculados por um script independente do app (sem ler `lib/`), direto da CLT e das tabelas oficiais abaixo.

## Fontes das tabelas (consultadas em 2026-10-05)

- **INSS 2026:** Portaria Interministerial MPS/MF nº 13, de 9/1/2026. Faixas progressivas: até 1.621,00 (7,5%); até 2.902,84 (9%); até 4.354,27 (12%); até 8.475,55 (14%, teto).
- **IRRF 2026 (mensal):** Receita Federal, tabela 2026: até 2.428,80 isento; até 2.826,65 7,5% (dedução 182,16); até 3.751,05 15% (394,16); até 4.664,68 22,5% (675,49); acima 27,5% (908,73). Dependente 189,59; desconto simplificado 607,20.
- **Redução do IRRF:** Lei 15.270/2025 (art. 3º-A da Lei 9.250/95): rendimentos tributáveis mensais até 5.000,00 → redução até 312,89 (imposto zero); de 5.000,01 a 7.350,00 → redução de 978,62 − 0,133145 × rendimentos; acima, sem redução.

## Premissas aplicadas (base legal)

| Verba | Regra aplicada | Base |
|---|---|---|
| Saldo de salário | salário ÷ 30 × dias trabalhados no mês | CLT art. 457, 477 |
| Aviso prévio indenizado | (salário + média) ÷ 30 × dias; dias = 30 + 3 por ano completo, máx. 90 | Lei 12.506/2011 |
| 13º proporcional | (salário + média) × avos ÷ 12; avos do ano-calendário, mês com ≥ 15 dias conta | Lei 4.090/62 art. 1º §2º |
| Projeção do aviso (C2) | por data: o aviso indenizado (dias pagos) projeta a saída até `rescisão + dias pagos` e as avos de 13º e férias proporcionais contam até essa data (regra de 15 dias, teto 12; 13º com virada de ano soma o ano da rescisão e o novo). Revisa a Q7a a pedido do responsável em 2026-10-06 | CLT art. 487 §1º; OJ 82 SDI-1 e Súmula 371 TST |
| Férias vencidas | (salário + média) × 4/3 por período vencido simples | CLT art. 129, 146; CF art. 7º XVII |
| Férias proporcionais (C3) | avos desde o último aniversário da admissão (≥ 15 dias conta) × 4/3 | CLT art. 146 par. único, 147 |
| Justa causa (C1) | paga saldo e férias vencidas; sem 13º e sem proporcionais | CLT art. 146 caput; Súmula 171 TST |
| INSS (C5) | saldo e 13º apurados **separados**, cada um com faixas e teto próprios | Decreto 3.048/99 art. 214 §§6º e 7º |
| Fora do INSS e do IRRF (C4) | aviso indenizado e férias (vencidas e proporcionais) indenizadas | Decreto 3.048/99 art. 214 §9º; Súmulas 125 e 386 STJ |
| Multa FGTS | saldo informado × 40% (sem justa causa) ou 20% (acordo); fora do "pago na rescisão" | Lei 8.036/90 art. 18; CLT art. 484-A |
| Acordo mútuo | aviso × 50%; multa 20% | CLT art. 484-A |
| Arredondamento | half-up, 2 casas, por verba. O INSS do saldo e o do 13º são recolhimentos distintos (bases separadas, C5): cada um é arredondado antes de somar; a base do IRRF de cada parcela usa o INSS já arredondado | convenção do dossiê, adotada pelo app (change `round-inss-per-component`); saldo 2.000 + 13º 2.500 → 155,69 + 200,69 = 356,38 (caso `golden_inss_arredondado_por_parcela`). |

## Perguntas ⚖️ e como foram resolvidas (fontes da internet)

1. **Projeção do aviso no acordo (24 dias de aviso pago):** projeção **por data**: `31/07/2026 + 24 dias = 24/08/2026`; 13º 8 avos (agosto com 24 dias conta) e férias proporcionais 7 avos (15/01 a 15/08 = 7 meses; sobram 10 dias, não contam). A projeção usa os dias efetivamente pagos (fontes secundárias: COAD; Bizneo; Empresário); não há norma primária explícita: **fonte fraca**, segue ⚖️ com a marca "cálculo em validação" (`noticeProjectionMutualAgreement`).
2. **Redução da Lei 15.270 no 13º:** **aplica-se.** Lei 15.270/2025, art. 3º-A §3º: a redução vale também para o imposto exclusivo na fonte do 13º.
3. **Desconto simplificado (607,20) na rescisão:** convenção mantida (maior entre INSS + dependentes e 607,20, na base mensal). Nenhum caso promovido depende disso (imposto zero).
4. **Base do IRRF do saldo:** saldo − INSS − dependentes (ou simplificado, o maior).
5. **Média de variáveis:** integra aviso, 13º e férias; o saldo de salário usa só o salário base. Convenção do app, conferida pelo caso `pedido_demissao` (bate).
6. **Contagem de avos:** mês com ≥ 15 dias conta (Lei 4.090/62 art. 1º §2º).
7. **IRRF do 13º na rescisão:** **devido**, em separado, pela tabela **mensal** vigente, no mês da rescisão (Lei 7.713/88 art. 26; SEFAZ-SP, "Rendimentos sujeitos a tributação exclusiva na fonte"). A redução da Lei 15.270 usa o **rendimento bruto**, não a base já deduzida (exemplo oficial da Receita: 978,62 − 0,133145 × 6.000).

## Diagnóstico: onde o app diverge (rodado em 2026-10-05, só para informação)

Os rascunhos foram copiados temporariamente para `test/golden/cases/`, rodados e removidos. **Os valores esperados não foram ajustados ao app.** Resultado: 3 de 5 batem ao centavo (`justa_causa_c1`, `pedido_demissao`, `prazo_determinado_termino`) e 2 divergem:

| Caso | Divergência | O que pode ser |
|---|---|---|
| `sem_justa_causa_c2_c5` | IRRF esperado 1.242,41 (13º de 9.000 → base 7.822,32 → 27,5%, sem redução por estar acima de 7.350), app devolve **0,00** | **Resolvido** (`fix-thirteenth-irrf`): `calculateTerminationTaxes` usava a tabela e a redução **anuais** no 13º; agora usa a tabela mensal (pergunta 7). |
| `acordo_mutuo` | 13º esperado 2.333,33 (8 avos, com +1 de projeção), app dava 2.041,67 (7 avos); férias proporcionais idem; o INSS acompanha | **Resolvido** (`notice-projection-by-date`): a projeção passou a ser por data (pergunta 1): 13º 8 avos = 2.333,33 e férias 7 avos = 2.722,22 (o rascunho trazia 8 avos e 3.111,11; a conta pela data dá 7). |

## Fora deste dossiê (ainda sem caso)

O gate de publicação (`coverage_matrix.dart`) exige `exemplo_contador` (não `calculo_legal`) para as regras ⚖️ pendentes:  **`art479`**, **`art480`** e **`doubleVacation`**. As entradas de B4 (fim previsto e cláusula) já existem, e os casos `calculo_legal` de art. 479/480 abaixo conferem o app, mas **não** retiram as regras de `pendingValidationRules`: isso exige `exemplo_contador`/fonte (B6). O de férias em dobro segue sem exemplo.

## Casos de B4 (contratos a prazo e rescisão indireta)

Valores calculados à mão a partir da CLT e das tabelas oficiais 2026 (fonte `calculo_legal`), antes de rodar o app. Os casos de art. 479/480 usam salário e datas em que o INSS cai na 1ª faixa (7,5 %); o ponto do meio centavo (INSS arredondado por parcela) é exercitado pelo caso `golden_inss_arredondado_por_parcela`, abaixo. Dias restantes = fim previsto − rescisão (PROJECT.md §6.6).

| Caso | Tipo | Resumo | Pago na rescisão |
|---|---|---|---:|
| `golden_prazo_determinado_termino` | `fixedTermEnd` | sem aviso e sem multa | 2591.67 |
| `golden_rescisao_indireta` | `indirectTermination` | igual a `golden_sem_justa_causa_c2_c5` | 52672.14 |
| `golden_prazo_antecipada_empregador` | `fixedTermEarlyByEmployer` | salário 2.400, 30 dias restantes: art. 479 = 1.200,00; multa 800,00 | 4671.67 |
| `golden_prazo_antecipada_empregador_clausula` | `fixedTermEarlyByEmployer` + cláusula | regras do sem justa causa: aviso 2.400,00 (projetado até 19/11/2026: 13º 6 avos, férias 5 avos), multa 800,00, sem art. 479 | 6323.33 |
| `golden_prazo_antecipada_empregado_abaixo_teto` | `fixedTermEarlyByEmployee` | 30 dias restantes: art. 480 = 1.200,00 (abaixo do teto de 2.400,00) | 2271.67 |
| `golden_prazo_antecipada_empregado_no_teto` | `fixedTermEarlyByEmployee` | 120 dias restantes: art. 479 equivalente 4.800,00, limitado a 2.400,00 | 1071.67 |

## Como promover (depois do "ok" do contador)

1. Copiar o JSON de `rascunho/` (a pasta está vazia desde a promoção de `golden_acordo_mutuo`) para `test/golden/cases/` com `fonte.tipo = "calculo_legal"` e sem a chave `validacao`.
2. `flutter test test/golden`: deve ficar verde (tolerância 0,01). Divergência = o documento prevalece e o app é corrigido (nunca o contrário).
3. Atualizar `pendingValidationRules` em `test/golden/validation_status.dart` para as regras que ganharam caso.

## Casos
### golden_sem_justa_causa_c2_c5
**Tipo:** Sem justa causa  
**Entrada:** admissão 10/03/2021, rescisão 05/09/2026, salário R$ 12000, média R$ 0, dependentes 1, FGTS informado R$ 40000, períodos de férias gozados 4, dias trabalhados no mês 5.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 2000.00 |
| Aviso prévio indenizado | 18000.00 |
| 13º proporcional | 9000.00 |
| Férias vencidas + 1/3 | 16000.00 |
| Férias proporcionais + 1/3 | 9333.33 |
| INSS (saldo + 13º) | 1143.78 |
| IRRF (saldo + 13º) | 1517.41 |
| Multa FGTS (fora do pago) | 16000.00 |

Total de proventos 55333.33 · descontos 2661.19 · **pago na rescisão 52672.14** · FGTS depositado (multa) 16000.00.

Detalhe: aviso 45 dias; data efetiva 20/10/2026 (05/09 + 45); períodos vencidos 1; avos13=10 (jan a set + outubro com 20 dias) avosFerias=7 (10/03 a 10/10 = 7 meses, 11 dias não contam); INSS saldo 155.69 + 13º 988.09; IRRF saldo 0.00 + 13º 1517.41 (10.000 − 988,09 − 189,59 = 8.822,32 × 27,5% − 908,73).

### golden_justa_causa_c1
**Tipo:** Justa causa  
**Entrada:** admissão 14/02/2023, rescisão 20/08/2026, salário R$ 3500, média R$ 0, dependentes 0, FGTS informado R$ 15000, períodos de férias gozados 2, dias trabalhados no mês 20.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 2333.33 |
| Férias vencidas + 1/3 | 4666.67 |
| INSS (saldo + 13º) | 185.68 |
| IRRF (saldo + 13º) | 0.00 |

Total de proventos 7000.00 · descontos 185.68 · **pago na rescisão 6814.32** · FGTS depositado (multa) 0.00.

Detalhe: aviso 39 dias; períodos vencidos 1; ; INSS saldo 185.68 + 13º 0; IRRF saldo 0.00 + 13º 0.

### golden_pedido_demissao
**Tipo:** Pedido de demissão  
**Entrada:** admissão 01/06/2022, rescisão 20/04/2026, salário R$ 4000, média R$ 300, dependentes 2, FGTS informado R$ 0, períodos de férias gozados 3, aviso trabalhado, dias trabalhados no mês 20.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 2666.67 |
| 13º proporcional | 1433.33 |
| Férias proporcionais + 1/3 | 5255.56 |
| INSS (saldo + 13º) | 323.19 |
| IRRF (saldo + 13º) | 0.00 |

Total de proventos 9355.56 · descontos 323.19 · **pago na rescisão 9032.37** · FGTS depositado (multa) 0.00.

Detalhe: aviso 39 dias; períodos vencidos 0; avos13=4 avosFerias=11 proj=0; INSS saldo 215.69 + 13º 107.50; IRRF saldo 0.00 + 13º 0.00.

### golden_acordo_mutuo
**Tipo:** Acordo mútuo (art. 484-A)  
**Entrada:** admissão 15/01/2020, rescisão 31/07/2026, salário R$ 3500, média R$ 0, dependentes 0, FGTS informado R$ 35000, períodos de férias gozados 6, dias trabalhados no mês 30.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 3500.00 |
| Aviso prévio indenizado | 2800.00 |
| 13º proporcional (8 avos) | 2333.33 |
| Férias proporcionais + 1/3 (7 avos) | 2722.22 |
| INSS (saldo + 13º) | 494.28 |
| IRRF (saldo + 13º) | 0.00 |
| Multa FGTS (fora do pago) | 7000.00 |

Total de proventos 11355.55 · descontos 494.28 · **pago na rescisão 10861.27** · FGTS depositado (multa) 7000.00.

Detalhe: aviso 48 dias (24 pagos); data efetiva 24/08/2026; períodos vencidos 0; avos13=8 avosFerias=7; INSS saldo 308.60 + 13º 185.68; IRRF saldo 0.00 + 13º 0.00.

### golden_prazo_determinado_termino
**Tipo:** Prazo determinado (término normal)  
**Entrada:** admissão 03/11/2025, rescisão 02/05/2026, salário R$ 2500, média R$ 0, dependentes 0, FGTS informado R$ 0, períodos de férias gozados 0, aviso trabalhado, dias trabalhados no mês 2.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 166.67 |
| 13º proporcional | 833.33 |
| Férias proporcionais + 1/3 | 1666.67 |
| INSS (saldo + 13º) | 75.00 |
| IRRF (saldo + 13º) | 0.00 |

Total de proventos 2666.67 · descontos 75.00 · **pago na rescisão 2591.67** · FGTS depositado (multa) 0.00.

Detalhe: aviso 30 dias; períodos vencidos 0; avos13=4 avosFerias=6 proj=0; INSS saldo 12.50 + 13º 62.50; IRRF saldo 0.00 + 13º 0.00.

### golden_inss_arredondado_por_parcela
**Tipo:** Pedido de demissão, aviso trabalhado (exercita o meio centavo do INSS, C5).  
**Entrada:** admissão 10/03/2025, rescisão 20/10/2026, salário R$ 3000, dependentes 0, períodos gozados 1, dias trabalhados no mês 20.

Cálculo à mão (INSS 2026: 7,5% até 1.621,00; 9% até 2.902,84): saldo 3000 ÷ 30 × 20 = 2.000,00; 13º 3000 × 10 ÷ 12 = 2.500,00 (jan a out, outubro com 20 dias conta); férias proporcionais 7 avos (desde 10/03/2026; 10 dias não contam) × 3000 × 4/3 ÷ 12 = 2.333,33. INSS saldo: 121,575 + 379 × 9% = 155,685 → 155,69; INSS 13º: 121,575 + 879 × 9% = 200,685 → 200,69; soma **356,38** (a soma crua daria 356,37). IRRF: bases 2.000 − 155,69 = 1.844,31 e 2.500 − 200,69 = 2.299,31, ambas ≤ 2.428,80 → 0,00.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 2000.00 |
| 13º proporcional (10 avos) | 2500.00 |
| Férias proporcionais + 1/3 (7 avos) | 2333.33 |
| INSS (saldo 155,69 + 13º 200,69) | 356.38 |
| IRRF | 0.00 |

Total de proventos 6833.33 · descontos 356.38 · **pago na rescisão 6476.95** · FGTS depositado (multa) 0.00.

### golden_acordo_mutuo_aviso_trabalhado
**Tipo:** Acordo mútuo (art. 484-A), aviso **trabalhado** (sem aviso indenizado, logo sem projeção: evita a disputa da pergunta 1).  
**Entrada:** admissão 15/01/2020, rescisão 31/07/2026, salário R$ 3500, dependentes 0, FGTS informado R$ 35000, períodos gozados 6, dias trabalhados no mês 30.

| Verba | Valor (R$) |
|---|---:|
| Saldo de salário | 3500.00 |
| 13º proporcional (7 avos) | 2041.67 |
| Férias proporcionais + 1/3 (7 avos) | 2722.22 |
| INSS (saldo 308,60 + 13º 159,44) | 468.04 |
| IRRF | 0.00 |
| Multa FGTS 20% (fora do pago) | 7000.00 |

Total de proventos 8263.89 · descontos 468.04 · **pago na rescisão 7795.85** · FGTS depositado (multa) 7000.00.
