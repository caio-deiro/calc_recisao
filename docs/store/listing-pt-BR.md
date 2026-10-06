# Listagem da Google Play (pt-BR): fonte da verdade

**Status:** proposta para aplicar no Play Console. Regras em `.claude/skills/aso-rules/SKILL.md`; diagnóstico em `AUDITORIA.md` (P1 #6 a #8). Todos os textos foram contados com código; os números abaixo são de 2026-10-06.

Reconciliado com a política publicada (`caio-deiro.github.io/calc_recisao`) e com a ficha de Data Safety (`DATA-SAFETY.md`): a frase antiga "seus dados não são armazenados nem compartilhados" **não** aparece mais.

## Título (30 caracteres)

`Calculadora de Rescisão CLT` (27)

Mantido. Com " 2026" passaria de 30; o ano vai na descrição curta e na longa.

## Descrição curta (80 caracteres)

Recomendada (A, 71): 
`Férias, 13º, FGTS, INSS e IRRF 2026: cada verba explicada, sem cadastro`

Variantes para Store Listing Experiments, uma por vez:
- B (71): `Calcule rescisão, férias, 13º e FGTS com INSS e IRRF 2026, sem cadastro`
- C (79): `Estimativa de rescisão CLT com cada verba explicada. Tabelas 2026, sem cadastro`

A não repete "rescisão CLT" do título (a Play já indexa o título) e usa o espaço para os termos de busca que o título não cobre: férias, 13º, FGTS, INSS, IRRF e o ano.

## Descrição completa (4.000 caracteres; esta tem 2.147)

```
Calculadora de Rescisão CLT: veja uma estimativa da sua rescisão com saldo de salário, aviso prévio, 13º, férias, FGTS, INSS e IRRF de 2026. Sem cadastro e sem enviar seu salário para ninguém.

O que você calcula
- Demissão sem justa causa, por justa causa, pedido de demissão e acordo entre as partes (art. 484-A da CLT).
- Contrato por prazo determinado: término normal e rescisão antecipada, pelo empregador ou pelo empregado.
- Rescisão indireta.
- Saldo de salário, aviso prévio proporcional ao tempo de casa, 13º proporcional, férias vencidas, férias em dobro e férias proporcionais com 1/3.
- Multa de 40% (ou 20% no acordo) do FGTS, com o seu saldo ou uma estimativa.
- INSS e IRRF com as tabelas de 2026, inclusive a nova redução do imposto de renda.

Cada verba explicada
Você vê o valor de cada item e as premissas usadas no cálculo, por exemplo quantos avos de 13º e de férias entraram e como o aviso prévio foi projetado. O resultado mostra dois totais: o que é pago na rescisão e o que é depositado no FGTS.

Como usar
1. Escolha o tipo de rescisão.
2. Informe as datas de admissão e de saída, o salário e, se tiver, o saldo do FGTS.
3. Veja o resultado em segundos, salve no histórico e compartilhe em texto ou PDF.

Sua privacidade
O cálculo é feito no seu aparelho. Salário, datas e resultado não saem dele. O histórico fica só no seu celular. O app tem anúncios do Google e, se você aceitar, coleta dados de uso anônimos e relatórios de falha. Política completa: caio-deiro.github.io/calc_recisao

Para quem é
Trabalhadores CLT que querem conferir o que a empresa calculou e profissionais de RH, contadores e advogados que precisam de uma estimativa rápida.

Importante
É uma estimativa, não um parecer jurídico nem contábil. O termo de rescisão (TRCT) emitido pela empresa prevalece. Algumas regras ainda estão em validação e aparecem marcadas no resultado como "cálculo em validação". Este app é independente e não tem vínculo com o governo nem com qualquer órgão público. As tabelas e regras seguem fontes públicas, como a CLT, a Receita Federal e o INSS.

Calcule sua rescisão CLT agora e entenda cada valor antes de assinar.
```

Por que assim:
- Os primeiros 167 caracteres (o que aparece antes do "ver mais") já têm rescisão, aviso prévio, 13º, férias, FGTS, INSS, IRRF e 2026.
- Sem emojis, sem caixa alta e sem repetição artificial de termos (política de metadados da Play).
- Só descreve o que o app faz hoje: acordo, prazo determinado, rescisão indireta e férias em dobro entraram na versão 1.3.
- Não promete exatidão e traz o aviso de independência exigido pelo projeto.
- Não cita PRO, seguro-desemprego (o app não calcula) nem horas extras.

## O que há de novo (500 caracteres)

Rascunho para a **próxima publicação**; reescrever a cada release (checklist da `aso-rules`).

```
Novidades:
- Férias em dobro quando o período vencido passou do prazo.
- Contratos por prazo determinado e rescisão indireta.
- Aviso prévio projetado até a data de saída, para um 13º e férias mais fiéis.
- IRRF do 13º corrigido (tabela mensal e redução de 2026) e INSS calculado por parcela.
- Sem cadastro: seus dados continuam no aparelho.
```

(342 caracteres; limite 500.)

## Palavras-chave

A Play não tem campo de palavras-chave: ela indexa título, descrição curta, descrição completa e avaliações. Termos cobertos de forma natural: rescisão, CLT, calculadora, FGTS, INSS, IRRF, 13º, férias, aviso prévio, multa de 40%, justa causa, pedido de demissão, acordo, rescisão indireta, contrato por prazo determinado. Cada um aparece 2 a 4 vezes na descrição completa; não repetir mais que isso.

## Categoria

Decisão do responsável, ainda pendente. Hoje: **Ferramentas**. A recomendação do plano é **Finanças** (duas concorrentes diretas estão lá), mas o líder está em Ferramentas e a evidência é mista (`AUDITORIA.md` P1 #10). Se mudar, responder "nenhuma funcionalidade financeira" na declaração do Play Console. Mudar a categoria não é testável por experimento de listagem: faça uma coisa por vez e meça.

## Como aplicar no Play Console

1. **Play Console > selecione o app > Crescer usuários > Presença na loja > Página principal da loja** (em inglês: *Grow users > Store presence > Main store listing*).
2. Em **Detalhes do app**: confira o **Nome** (30 caracteres), cole a **Descrição curta** e a **Descrição completa**. Cole o texto de dentro do bloco, sem as crases.
3. Clique em **Salvar**, depois em **Enviar alterações para revisão** (*Publishing overview*). O Google revisa antes de a mudança aparecer.
4. **O que há de novo** não fica nessa tela: ele é escrito **por versão**, ao criar o lançamento em **Testar e lançar > Produção** (ou na trilha `internal`), no campo "Notas da versão". Cole o texto de "O que há de novo" em um bloco `<pt-BR>...</pt-BR>`.
5. **Categoria:** em **Crescer usuários > Configurações da loja > Categoria do app**.
6. Para testar a descrição curta: **Crescer usuários > Experimentos de página da loja** > criar experimento de listagem (só um campo por vez, com a variante B ou C).
7. Depois de publicado, abra a página pública do app e confira o texto e a seção "Segurança dos dados".

## Checklist antes de colar

- [ ] Descrição curta ≤ 80 caracteres e completa ≤ 4.000 (já contados).
- [ ] Sem PRO, "exclusivo" ou "ilimitado" (`grep -riE "\bpro\b|ilimitad|exclusiv" docs/store/listing-pt-BR.md` só acha as linhas que listam a proibição).
- [ ] A ficha de Data Safety e a política publicadas coincidem com a frase de privacidade.
- [ ] Screenshots condizem com o texto (change D, ainda pendente).
