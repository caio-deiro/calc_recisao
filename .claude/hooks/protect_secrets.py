"""PreToolUse (Read|Edit|Write|NotebookEdit|Bash): protege arquivos de segredo.

Hook 4 do harness. Nega acesso a keystore de assinatura e a configs de serviço
que contêm credenciais. `android/key.properties` existe neste repositório e
guarda a senha do keystore de release.

Em Bash, nega comandos que citem esses arquivos. Isso é uma rede de segurança
contra deslize, não uma barreira contra um agente malicioso.
"""

import json
import os
import re
import sys

# Nomes de arquivo (basename) protegidos, em minúsculas.
PROTECTED_NAMES = {
    "key.properties",
    "google-services.json",
    "googleservice-info.plist",
    ".env",
}
PROTECTED_SUFFIXES = (".jks", ".keystore", ".p12", ".pfx")
PROTECTED_ENV_PREFIX = ".env."  # .env.local, .env.production...
ENV_EXAMPLE = {".env.example", ".env.sample", ".env.template"}

# Em comandos Bash: o nome precisa aparecer como "palavra de arquivo".
BASH_RE = re.compile(
    r"(?<![\w.-])("
    r"key\.properties|google-services\.json|GoogleService-Info\.plist"
    r"|\.env(?:\.[\w-]+)?"
    r"|[\w./\\-]+\.(?:jks|keystore|p12|pfx)"
    r")(?![\w-])",
    re.IGNORECASE,
)
REASON = (
    "Acesso bloqueado: arquivo de segredo (keystore, key.properties, .env ou config de serviço). "
    "Se for realmente necessário, peça ao usuário para executar a ação."
)


def is_protected_path(path: str) -> bool:
    name = os.path.basename(path.replace("\\", "/")).lower()
    if name in ENV_EXAMPLE:
        return False
    if name in PROTECTED_NAMES or name.endswith(PROTECTED_SUFFIXES):
        return True
    return name.startswith(PROTECTED_ENV_PREFIX)


def bash_hits(command: str) -> bool:
    for match in BASH_RE.finditer(command):
        token = match.group(1).lower()
        if token not in ENV_EXAMPLE:
            return True
    return False


def deny() -> None:
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": REASON,
                }
            }
        )
    )


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    tool = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}

    if tool == "Bash":
        if bash_hits(tool_input.get("command") or ""):
            deny()
        return 0

    path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if path and is_protected_path(path):
        deny()
    return 0


if __name__ == "__main__":
    sys.exit(main())
