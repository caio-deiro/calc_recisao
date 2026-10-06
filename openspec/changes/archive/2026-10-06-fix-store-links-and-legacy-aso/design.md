## Context
Confirmado por leitura e grep (lib e test): `termsOfServiceUrl` e `privacyPolicyUrl` sem uso; `supportEmail` usado só em `support_service.dart`; `support_screen.dart:132` tem e-mail literal; `support_service.dart:31` usa `calcrescisao.com/faq`; `aso_ab_testing.dart` e `aso_deep_links.dart` sem nenhum import; nenhum teste referencia o código a remover. `url_launcher` segue usado em `support_service.dart`, então o pacote fica.

## Decisions
- **Remover `aso_analytics.dart` inteiro.** Alternativa (manter só o que não é falso) descartada: `first_open` e `session_count` só são gravados, nunca lidos (`getConversionMetrics` sem chamadas), e os `track*` têm corpo vazio. O analytics real é `analytics_service` (B1-13). Remove `AsoAnalytics.initialize()` do `Future.wait` de `main.dart` e a chamada (e import) em `home_screen.dart:29`.
- **Chaves legadas**: as três chaves vão para `LegacyCleanup.legacyKeys` (mesmo padrão de `pro_conversion`), sem deixar lixo em instalações existentes.
- **FAQ removido**, não redirecionado: não há página de FAQ; apontar para a política seria enganoso. Reintroduzir só com conteúdo real.
- **Nome**: `android:label="@string/app_name"` com `strings.xml` = "Calculadora de Rescisão CLT", uma só fonte. `app_description` em `strings.xml` não é referenciado; sai junto.
- **Testes de arquivos** (manifest, strings, pubspec, varredura de `calcrescisao.com`) usam `dart:io` com caminhos relativos à raiz, de onde `flutter test` roda.
- O rótulo longo pode ser truncado no launcher; aceito por decisão do responsável.

## Risks
- Editar o `Future.wait` de `main.dart`: conferir que as demais inicializações seguem iguais.
- `docs/ARCHITECTURE.md` cita os módulos removidos (linhas ~76-80, 209, 244); atualizar no mesmo commit.

## Open Questions
Nenhuma. Nenhum item ⚖️.
