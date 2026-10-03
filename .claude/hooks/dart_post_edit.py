"""PostToolUse (Edit|Write): formata e analisa o arquivo .dart editado.

Hooks 1 e 2 do harness. Rodam em sequência no mesmo script para que a análise
veja o arquivo já formatado.

- Formatar: `dart format` silencioso (não gasta tokens).
- Analisar: `dart analyze` no arquivo; só erros e warnings voltam ao agente
  (exit 2 + stderr). Infos são ignoradas para não gerar ruído.

Usa o `dart` do SDK fixado pelo FVM (`.fvm/flutter_sdk`), com fallback ao PATH.
"""

import json
import os
import re
import shutil
import subprocess
import sys

SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".mocks.dart")
SKIP_DIRS = ("build", ".dart_tool", ".fvm")
ISSUE_RE = re.compile(r"^\s*(error|warning)\s+-\s+", re.IGNORECASE)


def find_dart(project_dir: str) -> str | None:
    exe = "dart.bat" if os.name == "nt" else "dart"
    pinned = os.path.join(project_dir, ".fvm", "flutter_sdk", "bin", exe)
    if os.path.isfile(pinned):
        return pinned
    return shutil.which("dart")


def main() -> int:
    sys.stderr.reconfigure(encoding="utf-8")
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    file_path = (payload.get("tool_input") or {}).get("file_path") or ""
    if not file_path.endswith(".dart") or file_path.endswith(SKIP_SUFFIXES):
        return 0

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or os.getcwd()
    path = os.path.abspath(file_path)
    rel = os.path.relpath(path, project_dir)
    if rel.startswith("..") or rel.split(os.sep)[0] in SKIP_DIRS or not os.path.isfile(path):
        return 0

    dart = find_dart(project_dir)
    if not dart:
        return 0  # sem SDK disponível: não bloqueia o fluxo

    subprocess.run([dart, "format", path], cwd=project_dir, capture_output=True, text=True, timeout=30)

    result = subprocess.run(
        [dart, "analyze", path], cwd=project_dir, capture_output=True, text=True, timeout=90
    )
    issues = [ln for ln in (result.stdout + result.stderr).splitlines() if ISSUE_RE.match(ln)]
    if issues:
        print(f"dart analyze: {len(issues)} problema(s) em {rel}", file=sys.stderr)
        print("\n".join(issues), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except subprocess.TimeoutExpired:
        sys.exit(0)  # timeout não deve travar a edição
