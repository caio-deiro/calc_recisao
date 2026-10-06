---
description: Cria e envia a tag v<versão do pubspec> a partir da main, disparando o release Android para a trilha internal
---

Dispare o release Android criando a tag da versão atual do `pubspec.yaml`. O workflow `.github/workflows/release-android.yml` faz o resto. Siga os passos em ordem e pare no primeiro que falhar, dizendo o motivo.

1. Rode `git fetch origin`. Confirme que a branch atual é `main`, que `git status --short` está vazio e que `main` está igual a `origin/main` (`git rev-parse HEAD origin/main`). Se algo falhar, pare: não troque de branch nem descarte mudanças por conta própria.
2. Leia a linha `version:` do `pubspec.yaml` (ex.: `1.3.1+17`). A tag é `v` + versão sem o `+N` (ex.: `v1.3.1`). O `+N` é o `versionCode`.
3. Se a tag já existe, local (`git tag -l`) ou remota (`git ls-remote --tags origin`), pare e avise.
4. Mostre ao usuário a versão, o `versionCode`, a tag e o commit (`git log -1 --oneline`). Peça confirmação explícita: o push da tag publica o app na trilha internal da Play.
5. Só com o "sim": `git tag v<versão>` e `git push origin v<versão>`.
6. Diga ao usuário para acompanhar o run em `gh run list --workflow release-android.yml --limit 1` e conferir o build na trilha internal do Play Console. A promoção para produção é manual.
