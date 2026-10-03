"""PostToolUse (Edit|Write): valida assets/config/tax_tables.json.

Hook 3 do harness. Se a tabela quebrar, o app não consegue calcular
(`main.dart` trata como erro crítico), então o erro volta ao agente na hora.

Confere: JSON válido, as chaves que `TaxTablesService.loadTaxTables()` lê,
faixas de INSS/IRRF com campos numéricos e limites crescentes, e os blocos
`fgts`, `aviso_previo` e `irrf_redutor_2026`.
"""

import json
import os
import sys

TARGET = "assets/config/tax_tables.json"

# Chaves lidas por lib/core/services/tax_tables_service.dart.
REQUIRED_TABLES = (
    "inss_2025",
    "inss_2026",
    "irrf_2025_jan_abr",
    "irrf_2025_mai_dez",
    "irrf_2026_mensal",
    "irrf_2026_anual",
)
REDUCER_KEYS = (
    "limite_isencao",
    "reducao_maxima",
    "limite_reducao_gradual",
    "formula_constante",
    "formula_coeficiente",
)


def is_num(value) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def check_table(name: str, table) -> list[str]:
    errors = []
    if not isinstance(table, dict):
        return [f"{name}: deveria ser um objeto"]
    ranges = table.get("faixas")
    if not isinstance(ranges, list) or not ranges:
        return [f"{name}: 'faixas' ausente ou vazia"]
    previous = float("-inf")
    for i, r in enumerate(ranges):
        if not isinstance(r, dict) or not is_num(r.get("limite")) or not is_num(r.get("aliquota")):
            errors.append(f"{name}.faixas[{i}]: 'limite' e 'aliquota' devem ser numéricos")
            continue
        if "deducao" in r and not is_num(r["deducao"]):
            errors.append(f"{name}.faixas[{i}]: 'deducao' deve ser numérica")
        if not 0 <= r["aliquota"] <= 1:
            errors.append(f"{name}.faixas[{i}]: 'aliquota' fora de 0..1 ({r['aliquota']})")
        if r["limite"] <= previous:
            errors.append(f"{name}.faixas[{i}]: 'limite' deve ser crescente")
        previous = r["limite"]
    if name.startswith("inss_") and not is_num(table.get("teto")):
        errors.append(f"{name}: 'teto' ausente ou não numérico")
    return errors


def validate(data) -> list[str]:
    if not isinstance(data, dict):
        return ["raiz do JSON deve ser um objeto"]
    errors = []
    for name in REQUIRED_TABLES:
        if name not in data:
            errors.append(f"chave obrigatória ausente: {name}")
    for name, table in data.items():
        if name.startswith(("inss_", "irrf_")) and name != "irrf_redutor_2026":
            errors.extend(check_table(name, table))

    reducer = data.get("irrf_redutor_2026")
    if not isinstance(reducer, dict):
        errors.append("irrf_redutor_2026 ausente")
    else:
        if not is_num(reducer.get("deducao_dependente_mensal")):
            errors.append("irrf_redutor_2026.deducao_dependente_mensal ausente ou não numérico")
        for period in ("mensal", "anual"):
            block = reducer.get(period)
            if not isinstance(block, dict):
                errors.append(f"irrf_redutor_2026.{period} ausente")
                continue
            for key in REDUCER_KEYS:
                if not is_num(block.get(key)):
                    errors.append(f"irrf_redutor_2026.{period}.{key} ausente ou não numérico")

    fgts = data.get("fgts")
    if not isinstance(fgts, dict) or not all(is_num(fgts.get(k)) for k in ("aliquota", "multa_sem_justa_causa")):
        errors.append("fgts: 'aliquota' e 'multa_sem_justa_causa' devem existir e ser numéricos")

    notice = data.get("aviso_previo")
    if not isinstance(notice, dict) or not all(is_num(notice.get(k)) for k in ("dias_base", "dias_por_ano", "maximo_dias")):
        errors.append("aviso_previo: 'dias_base', 'dias_por_ano' e 'maximo_dias' devem existir e ser numéricos")
    return errors


def main() -> int:
    sys.stderr.reconfigure(encoding="utf-8")
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    file_path = (payload.get("tool_input") or {}).get("file_path") or ""
    if os.path.normpath(file_path).replace("\\", "/").lower().endswith(TARGET) is False:
        return 0
    if not os.path.isfile(file_path):
        return 0

    try:
        with open(file_path, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"tax_tables.json inválido: {exc}", file=sys.stderr)
        return 2

    errors = validate(data)
    if errors:
        print("tax_tables.json com problemas (o app não calcula sem estas chaves):", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
