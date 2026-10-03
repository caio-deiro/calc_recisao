# Princípios de engenharia

## Simplicidade (KISS + YAGNI)
- Faça a solução mais simples que cumpre a spec. Sem abstração, parâmetro, camada ou dependência "para o futuro".
- Antes de adicionar algo, procure o que já existe no projeto e siga o padrão atual. Padrão ou pacote novo exige pergunta ao usuário.
- Prefira remover ou simplificar código a acrescentar. Código que ninguém usa se apaga.
- Se a explicação da solução precisa de um diagrama, ela está complicada demais.

## Sem repetição (DRY)
- Cada regra de negócio e cada constante tem **um único lugar** (ex.: tabelas em `tax_tables.json`, valores em `AppConstants`, regras por tipo em tabela).
- DRY é sobre conhecimento duplicado, não sobre texto parecido. Duas coisas semelhantes por coincidência não se unificam.
- Abstraia na **terceira** repetição, nunca na segunda. Duplicar é melhor que a abstração errada.
- Testes podem repetir: clareza vence reuso. Não crie helpers que escondam o que o teste verifica.

## Escopo e honestidade
- Mude só o que a tarefa pede. Achou algo fora do escopo? Reporte, não corrija por conta própria.
- Não declare "pronto" sem ter verificado (analyze, testes). Diga o que não foi verificado.
- Decisão de produto ou regra trabalhista sem fonte (⚖️) é do usuário: pergunte, com uma recomendação.
- Quando DRY e clareza brigarem, escolha a clareza.
