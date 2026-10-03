#!/usr/bin/env python3
"""Gera docs/PROGRESS.md: quanto do docs/SPECS.md já foi feito pelo pipeline.

O progresso é DERIVADO, nunca escrito à mão:
  - os requisitos (IDs `B<n>-<nn>[a-z]`) vêm da 1ª célula das tabelas de docs/SPECS.md;
  - as tasks vêm de openspec/changes/*/tasks.md (ativas) e openspec/changes/archive/*/tasks.md
    (entregues); uma task "cita" um ID se o ID aparece na linha ou no título (##) acima dela.

Estados de cada ID:
  sem_plano      nenhuma task cita o ID
  planejado      há tasks, nenhuma marcada
  em_andamento   algumas tasks marcadas
  implementado   todas marcadas, mas a change ainda não foi arquivada
  entregue       todas marcadas e todas em changes arquivadas

Uso:
  python scripts/specs_progress.py            # escreve docs/PROGRESS.md
  python scripts/specs_progress.py --check    # exit 1 se o arquivo estiver desatualizado ou houver erro
  python scripts/specs_progress.py --stdout   # imprime em vez de escrever

A saída é determinística (sem data/hora): só muda quando o progresso muda.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

STATES = ("entregue", "implementado", "em_andamento", "planejado", "sem_plano")
LABEL = {
    "entregue": "🚀 Entregue",
    "implementado": "✔ Implementado",
    "em_andamento": "🔨 Em andamento",
    "planejado": "📋 Planejado",
    "sem_plano": "🎯 Sem plano",
}

DEF_ROW = re.compile(r"^\|\s*(B\d+-\d+[a-z]?)\s*\|(.*)$")
BLOCK_HEAD = re.compile(r"^##\s+(B\d+)\s+[—-]\s+(.*)$")
TASK_LINE = re.compile(r"^\s*-\s*\[( |x|X)\]\s*(.*)$")
ID_REF = re.compile(
    r"\bB(\d+)-(\d+)([a-z]?)(?:\s*(?:\.\.|…|–)\s*(?:B(\d+)-)?(\d+)([a-z]?))?"
)


@dataclass
class Requirement:
    id: str
    block: str
    number: int
    text: str


@dataclass
class TaskRef:
    change: str
    archived: bool
    done: bool


@dataclass
class Report:
    reqs: dict[str, Requirement]
    block_titles: dict[str, str]
    refs: dict[str, list[TaskRef]] = field(default_factory=dict)
    unknown: dict[str, set[str]] = field(default_factory=dict)  # id -> changes
    archived_pending: set[str] = field(default_factory=set)


def clean_cell(text: str) -> str:
    first = text.split("|")[0].strip()
    first = first.replace("**", "").replace("`", "")
    return (first[:77] + "...") if len(first) > 80 else first


def parse_specs(path: Path) -> tuple[dict[str, Requirement], dict[str, str]]:
    reqs: dict[str, Requirement] = {}
    titles: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        head = BLOCK_HEAD.match(line)
        if head:
            titles[head.group(1)] = head.group(2).strip().replace("`", "")
            continue
        row = DEF_ROW.match(line)
        if row:
            rid = row.group(1)
            m = re.match(r"B(\d+)-(\d+)", rid)
            reqs[rid] = Requirement(rid, f"B{m.group(1)}", int(m.group(2)), clean_cell(row.group(2)))
    return reqs, titles


def expand_ids(line: str, known: set[str]) -> tuple[set[str], set[str]]:
    """Devolve (ids conhecidos citados, ids desconhecidos citados)."""
    found: set[str] = set()
    unknown: set[str] = set()
    for m in ID_REF.finditer(line):
        block, n1, suf1, block2, n2, suf2 = m.groups()
        if n2 is None:
            rid = f"B{block}-{n1}{suf1}"
            (found if rid in known else unknown).add(rid)
            continue
        if block2 not in (None, block):
            unknown.add(m.group(0))
            continue
        low, high = int(n1), int(n2)
        in_range = {
            r
            for r in known
            if r.startswith(f"B{block}-") and low <= int(re.match(r"B\d+-(\d+)", r).group(1)) <= high
        }
        if in_range:
            found |= in_range
        else:
            unknown.add(m.group(0))
    return found, unknown


def scan_tasks(tasks_file: Path, change: str, archived: bool, report: Report) -> None:
    known = set(report.reqs)
    heading_ids: set[str] = set()
    for line in tasks_file.read_text(encoding="utf-8").splitlines():
        if line.lstrip().startswith("#"):
            heading_ids, bad = expand_ids(line, known)
            for u in bad:
                report.unknown.setdefault(u, set()).add(change)
            continue
        task = TASK_LINE.match(line)
        if not task:
            continue
        done = task.group(1).lower() == "x"
        ids, bad = expand_ids(task.group(2), known)
        for u in bad:
            report.unknown.setdefault(u, set()).add(change)
        for rid in ids | heading_ids:
            report.refs.setdefault(rid, []).append(TaskRef(change, archived, done))
            if archived and not done:
                report.archived_pending.add(change)


def build(root: Path) -> Report:
    reqs, titles = parse_specs(root / "docs" / "SPECS.md")
    report = Report(reqs, titles)
    changes = root / "openspec" / "changes"
    if changes.is_dir():
        for d in sorted(p for p in changes.iterdir() if p.is_dir() and p.name != "archive"):
            if (d / "tasks.md").is_file():
                scan_tasks(d / "tasks.md", d.name, False, report)
        archive = changes / "archive"
        if archive.is_dir():
            for d in sorted(p for p in archive.iterdir() if p.is_dir()):
                if (d / "tasks.md").is_file():
                    scan_tasks(d / "tasks.md", d.name, True, report)
    return report


def state_of(refs: list[TaskRef]) -> str:
    if not refs:
        return "sem_plano"
    if all(r.done for r in refs):
        return "entregue" if all(r.archived for r in refs) else "implementado"
    return "em_andamento" if any(r.done for r in refs) else "planejado"


def pct(part: int, total: int) -> str:
    return f"{round(100 * part / total)}%" if total else "—"


def render(report: Report) -> str:
    def rid_key(r: Requirement):
        return (int(r.block[1:]), r.number, r.id)

    ordered = sorted(report.reqs.values(), key=rid_key)
    state = {r.id: state_of(report.refs.get(r.id, [])) for r in ordered}
    blocks = sorted({r.block for r in ordered}, key=lambda b: int(b[1:]))

    def counts(items):
        c = {s: 0 for s in STATES}
        for r in items:
            c[state[r.id]] += 1
        return c

    total = counts(ordered)
    n = len(ordered)
    out: list[str] = []
    out.append("# PROGRESS — andamento do docs/SPECS.md")
    out.append("")
    out.append(
        "> **Gerado por `scripts/specs_progress.py`. Não edite à mão.** Cruza os requisitos do "
        "[SPECS.md](SPECS.md) com as tasks das changes em `openspec/changes/` (ativas e arquivadas)."
    )
    out.append("> Atualize com `python scripts/specs_progress.py` nos marcos do pipeline (ver skill `orchestrate`).")
    out.append("")
    out.append("**Estados:** 🚀 entregue (change arquivada) · ✔ implementado (tasks marcadas, change ainda ativa) · "
               "🔨 em andamento · 📋 planejado (task existe, nenhuma marcada) · 🎯 sem plano (nenhuma task cita o ID)")
    out.append("")
    out.append("## Resumo")
    out.append("")
    out.append(f"**{total['entregue']}/{n} requisitos entregues ({pct(total['entregue'], n)})**")
    out.append("")
    out.append("| Estado | Requisitos |")
    out.append("|---|--:|")
    for s in STATES:
        out.append(f"| {LABEL[s]} | {total[s]} |")
    out.append("")
    out.append("## Por bloco")
    out.append("")
    out.append("| Bloco | Título | Total | 🚀 | ✔ | 🔨 | 📋 | 🎯 | Entregue |")
    out.append("|---|---|--:|--:|--:|--:|--:|--:|--:|")
    for b in blocks:
        items = [r for r in ordered if r.block == b]
        c = counts(items)
        out.append(
            f"| {b} | {report.block_titles.get(b, '')} | {len(items)} | {c['entregue']} | {c['implementado']} | "
            f"{c['em_andamento']} | {c['planejado']} | {c['sem_plano']} | {pct(c['entregue'], len(items))} |"
        )

    out.append("")
    out.append("## Detalhe")
    for b in blocks:
        out.append("")
        out.append(f"### {b} — {report.block_titles.get(b, '')}")
        out.append("")
        out.append("| ID | Estado | Requisito | Changes |")
        out.append("|---|---|---|---|")
        for r in (x for x in ordered if x.block == b):
            changes = sorted({t.change for t in report.refs.get(r.id, [])})
            out.append(
                f"| {r.id} | {LABEL[state[r.id]]} | {r.text.replace('|', '/')} | "
                f"{', '.join(f'`{c}`' for c in changes) if changes else '—'} |"
            )

    alerts: list[str] = []
    gaps: list[str] = []
    for b in blocks:
        items = [r for r in ordered if r.block == b]
        if any(state[r.id] != "sem_plano" for r in items):
            missing = [r.id for r in items if state[r.id] == "sem_plano"]
            if missing:
                gaps.append(f"- **{b}** tem requisitos planejados, mas estes não têm task: {', '.join(missing)}")
    if gaps:
        alerts.append("**Buracos no plano** (bloco em andamento com requisitos sem task):")
        alerts += gaps
    if report.unknown:
        alerts.append("**Tasks citando IDs inexistentes no SPECS.md** (erro de digitação?):")
        for u in sorted(report.unknown):
            alerts.append(f"- `{u}` em {', '.join(f'`{c}`' for c in sorted(report.unknown[u]))}")
    if report.archived_pending:
        alerts.append("**Changes arquivadas com tasks desmarcadas** (inconsistente):")
        alerts += [f"- `{c}`" for c in sorted(report.archived_pending)]
    out.append("")
    out.append("## Alertas")
    out.append("")
    out += alerts if alerts else ["Nenhum."]
    out.append("")
    return "\n".join(out)


def has_errors(report: Report) -> bool:
    return bool(report.unknown or report.archived_pending)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=None, help="raiz do projeto (padrão: pasta acima de scripts/)")
    ap.add_argument("--check", action="store_true", help="falha se PROGRESS.md estiver desatualizado ou houver erros")
    ap.add_argument("--stdout", action="store_true", help="imprime o relatório em vez de escrever o arquivo")
    args = ap.parse_args(argv)

    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):  # evita falha com stdout substituído (testes)
            stream.reconfigure(encoding="utf-8")
    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parent.parent
    if not (root / "docs" / "SPECS.md").is_file():
        print(f"docs/SPECS.md não encontrado em {root}", file=sys.stderr)
        return 2

    report = build(root)
    text = render(report)
    target = root / "docs" / "PROGRESS.md"

    if args.stdout:
        print(text)
        return 0
    if args.check:
        current = target.read_text(encoding="utf-8") if target.is_file() else ""
        if current != text:
            print("docs/PROGRESS.md desatualizado: rode `python scripts/specs_progress.py`", file=sys.stderr)
            return 1
        if has_errors(report):
            print("PROGRESS.md contém alertas de erro (IDs inexistentes ou changes inconsistentes)", file=sys.stderr)
            return 1
        return 0

    target.write_text(text, encoding="utf-8", newline="\n")
    delivered = sum(1 for r in report.reqs.values() if state_of(report.refs.get(r.id, [])) == "entregue")
    print(f"docs/PROGRESS.md atualizado: {delivered}/{len(report.reqs)} requisitos entregues")
    if has_errors(report):
        print("ATENÇÃO: há alertas de erro no relatório (IDs inexistentes ou changes inconsistentes)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
