"""PreToolUse (Edit|Write|NotebookEdit): limita onde um agente pode escrever.

Uso, no frontmatter do agente:
    command: python "$CLAUDE_PROJECT_DIR/.claude/hooks/scope_guard.py" <agente> <glob> [<glob> ...]

Cada <glob> é relativo à raiz do projeto, com `/`. `*` casa dentro de uma pasta
e `**` casa em qualquer profundidade. Escrita fora de todos os globs é negada e o
agente recebe a instrução de reportar a necessidade em vez de contornar.

É uma rede de segurança de escopo, não uma barreira contra um agente malicioso.
"""

import json
import os
import re
import sys


def glob_to_regex(glob: str) -> re.Pattern:
    out, i = [], 0
    while i < len(glob):
        if glob.startswith("**/", i):
            out.append("(?:.*/)?")
            i += 3
        elif glob.startswith("**", i):
            out.append(".*")
            i += 2
        elif glob[i] == "*":
            out.append("[^/]*")
            i += 1
        elif glob[i] == "?":
            out.append("[^/]")
            i += 1
        else:
            out.append(re.escape(glob[i]))
            i += 1
    return re.compile("^" + "".join(out) + "$", re.IGNORECASE)


def deny(agent: str, rel: str, globs: list[str]) -> None:
    reason = (
        f"Escrita fora do escopo do agente '{agent}': {rel}. "
        f"Pode escrever apenas em: {', '.join(globs)}. "
        "Não contorne: registre a necessidade no relatório (status 'bloqueado') para o orquestrador decidir."
    )
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )


def main() -> int:
    if len(sys.argv) < 3:
        return 0  # mal configurado: não bloqueia por engano
    agent, globs = sys.argv[1], sys.argv[2:]

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool_input = payload.get("tool_input") or {}
    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if not path:
        return 0

    project = os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or os.getcwd()
    absolute = os.path.abspath(path if os.path.isabs(path) else os.path.join(project, path))
    try:
        rel = os.path.relpath(absolute, project).replace("\\", "/")
    except ValueError:  # outro drive no Windows
        deny(agent, absolute, globs)
        return 0

    if rel.startswith(".."):
        deny(agent, absolute, globs)  # fora do projeto
        return 0
    if any(glob_to_regex(g).match(rel) for g in globs):
        return 0
    deny(agent, rel, globs)
    return 0


if __name__ == "__main__":
    sys.exit(main())
