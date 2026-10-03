---
name: flutter-conventions
description: Convenções de código Flutter/Dart deste projeto: camadas e responsabilidades, gerência de estado atual (StatefulWidget + setState, sem pacote externo), navegação imperativa com Navigator, padrões de tela, testes unitários e de widget, UI amigável ao Maestro (Semantics/Keys), lints, privacidade e segurança. Use sempre que for escrever, alterar ou revisar código em lib/ ou test/: telas, widgets, serviços, repositórios, use cases, formulários, navegação, e ao criar ou corrigir testes. Não se aplica a documentação nem a regras de cálculo em si (use calc-rules).
---

# Convenções Flutter

Descreve o código **como ele é** e como estendê-lo sem inventar outro padrão. A decisão (registrada no PRD) é **manter** a arquitetura, a gerência de estado e a navegação atuais: nada de GoRouter, BLoC, Provider ou monorepo. Quando um padrão novo parecer necessário, pare e proponha ao usuário em vez de adotá-lo.

## Camadas
`presentation → domain ← data`, com `core/` transversal (detalhes em `docs/ARCHITECTURE.md`).
- **`domain/`**: entidades e use cases. Dart puro e determinístico; **sem** `BuildContext`, widgets nem `SharedPreferences`.
- **`data/`**: repositórios (hoje, `HistoryRepository` sobre `SharedPreferences`).
- **`presentation/`**: telas e widgets. Não há camada de controle: o `State` da tela cumpre esse papel e chama use cases e repositórios diretamente.
- **`core/`**: constantes, serviços, utilitários, tema, exceções.

Regra prática: **lógica de negócio não mora no `State`**. Se a tela calcula, valida regra ou decide algo de domínio, mova para o use case/validator e teste lá.

## Gerência de estado
`StatefulWidget` + `setState`; singletons/estáticos nos serviços. Sem pacote externo.
- Estado de UI (loading, campos, seleção) fica no `State`; estado compartilhado vem de serviço ou repositório, relido ao voltar para a tela.
- **Depois de todo `await`, cheque `if (!mounted) return;`** antes de `setState` ou de usar `context`.
- Faça `dispose()` de controllers, `FocusNode`s e anúncios.
- Mantenha `setState` pequeno e perto da mudança; não reconstrua a tela inteira por um campo.
- Tela com mais de ~250 linhas: extraia widgets (`presentation/widgets/`) ao mexer nela, sem refatoração oportunista fora do escopo da task.
- Prefira `const` onde possível e `ListView.builder` para listas longas.

## Navegação
Imperativa, com `Navigator.of(context)`: `push(MaterialPageRoute(...))`, `pushReplacement`, `pop`.
- Devolver resultado: `pop(valor)` e `final r = await push(...)`.
- Fluxo atual: `Splash → (Onboarding) → Home → Form → Result`; `Home → History | Support | About`.
- Depois de um `await` de navegação, cheque `mounted`.
- Não introduza rotas nomeadas nem roteador novo.

## Padrões de tela
- Textos de UI em português, claros e sem juridiquês (`PRODUCT.md`); strings reutilizáveis em `lib/l10n/` quando já houver chave.
- Cores, tipografia e espaçamentos vêm do tema (`core/theme/app_theme.dart`, tokens em `DESIGN.md`); não crie estilos soltos.
- O **aviso legal** (`DisclaimerWidget`) permanece nas telas Home, Formulário, Resultado e Histórico.
- Anúncios: regras do PRD §8 (banner no rodapé; intersticial só ao **sair** do Resultado; nunca antes do resultado).

## UI amigável ao Maestro
Os fluxos E2E localizam elementos pela **árvore de acessibilidade**, então toda ação do usuário precisa de um identificador estável:
- Campos e botões que um fluxo toca ganham `Semantics(identifier: '...')` (ou `Key`) com nome estável, em minúsculas e com `_` (ex.: `salary_field`, `calculate_button`).
- Não dependa só de texto que pode mudar (rótulos, traduções).
- Confira o que o Maestro enxerga com `maestro hierarchy` (skill `maestro-e2e`).

## Testes
Estrutura em `test/`: `unit/`, `widget/`, `integration/`, `mocks/`, `test_helpers/`. Espelhe o caminho do código testado.
- **Unitário de domínio:** `TestWidgetsFlutterBinding.ensureInitialized()` em `setUpAll`; `await TaxTablesService.instance.loadTaxTables()` em `setUp`; instancie o use case direto (`const CalculateTerminationUseCase()`).
- **`SharedPreferences`:** use `test/test_helpers/shared_preferences_setup.dart` (`SharedPreferences.setMockInitialValues`); limpe no `tearDown`.
- **Widget:** envolva em `MaterialApp`; teste tamanhos pequeno, médio e grande com `tester.binding.setSurfaceSize(...)`; `await tester.pumpAndSettle()`; confirme `tester.takeException()` nulo e os textos/identificadores esperados. Restaure o tamanho ao final.
- Nomes em português no formato `deve <comportamento>`; `group` por unidade.
- Mocks: o projeto tem `mockito` e mocks escritos à mão em `test/mocks/`; prefira os existentes. Evite `golden_toolkit` salvo necessidade clara.
- Teste cobre **comportamento**, não detalhe de implementação. Datas fixas, nunca `DateTime.now()`.
- Regra de cálculo: caso golden primeiro (skill `calc-rules`).

## Qualidade, privacidade e segurança
- Os hooks do projeto rodam `dart format` e `dart analyze` a cada edição de `.dart`: erro ou warning que voltar deve ser corrigido na hora.
- Ao terminar uma task: `flutter analyze` e `flutter test` (o arquivo tocado, e a suíte antes de entregar).
- **Nunca** registre salário, datas ou resultado em log, evento de analytics ou relatório de crash; sem `print`/`debugPrint` com dado do usuário (use `AppLogger`).
- Segredos (`android/key.properties`, keystore, `.env`, configs de serviço) estão bloqueados por hook; não os leia nem os edite.
- Falhas viram exceções tipadas (`AppException`), com mensagem amigável na UI.
- Dinheiro: hoje `double` com arredondamento por item; migra para `Decimal` na change `fix-calculation-rules`. Não misture os dois no mesmo cálculo.

## Antes de entregar
Rode `flutter analyze` e `flutter test`; confira que só os arquivos da task mudaram; atualize `docs/ARCHITECTURE.md` se mudou camada, dependência ou fluxo (no mesmo commit).
