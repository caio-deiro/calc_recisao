"""Testes de scripts/specs_progress.py. Rode: python -m unittest scripts.test_specs_progress -v"""

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import specs_progress as sp  # noqa: E402

SPECS = """# SPECS
## B1 — Remoção do PRO
| ID | Requisito |
|---|---|
| B1-01 | **Remover** PurchaseService |
| B1-02 | Remover ProScreen |
| B1-10a | Banner adaptativo |
| B1-10b | Intersticial ao sair |
## B2 — Núcleo de cálculo
| ID | Requisito | Obs |
|---|---|---|
| B2-01 | Identidade de verba | x |
| B2-02 | Regras por tipo | y |
| B2-03 | Sem remoção posterior | z |
Texto solto citando B2-01 não define nada.
"""


def write(root: Path, rel: str, content: str) -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")


class SpecsProgressTest(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        write(self.root, "docs/SPECS.md", SPECS)

    def tearDown(self):
        self._tmp.cleanup()

    def states(self):
        rep = sp.build(self.root)
        return {rid: sp.state_of(rep.refs.get(rid, [])) for rid in rep.reqs}, rep

    # --- leitura do SPECS ---
    def test_define_ids_so_pela_primeira_celula(self):
        reqs, titles = sp.parse_specs(self.root / "docs" / "SPECS.md")
        self.assertEqual(set(reqs), {"B1-01", "B1-02", "B1-10a", "B1-10b", "B2-01", "B2-02", "B2-03"})
        self.assertEqual(reqs["B1-01"].text, "Remover PurchaseService")
        self.assertEqual(titles["B2"], "Núcleo de cálculo")

    # --- estados ---
    def test_sem_changes_tudo_sem_plano(self):
        st, _ = self.states()
        self.assertTrue(all(v == "sem_plano" for v in st.values()))

    def test_planejado_andamento_implementado(self):
        write(self.root, "openspec/changes/c1/tasks.md",
              "## 1. Remoção\n- [ ] 1.1 Apagar serviço B1-01\n- [ ] 1.2 Apagar tela B1-02\n- [x] 1.3 Banner B1-10a\n")
        st, _ = self.states()
        self.assertEqual(st["B1-01"], "planejado")
        self.assertEqual(st["B1-10a"], "implementado")
        self.assertEqual(st["B1-10b"], "sem_plano")
        write(self.root, "openspec/changes/c1/tasks.md",
              "- [x] 1.1 Apagar serviço B1-01\n- [ ] 1.2 Outra parte de B1-01\n")
        st, _ = self.states()
        self.assertEqual(st["B1-01"], "em_andamento")

    def test_entregue_exige_change_arquivada(self):
        write(self.root, "openspec/changes/archive/2026-10-05-c1/tasks.md", "- [x] 1.1 Feito B1-01\n")
        st, rep = self.states()
        self.assertEqual(st["B1-01"], "entregue")
        self.assertFalse(sp.has_errors(rep))

    def test_id_em_ativa_e_arquivada_nao_e_entregue(self):
        write(self.root, "openspec/changes/archive/old/tasks.md", "- [x] 1 B1-01\n")
        write(self.root, "openspec/changes/new/tasks.md", "- [x] 1 B1-01 de novo\n")
        st, _ = self.states()
        self.assertEqual(st["B1-01"], "implementado")

    # --- citações ---
    def test_intervalo_de_ids(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [x] 1.1 Tudo de B2-01…03\n")
        st, _ = self.states()
        self.assertEqual([st[f"B2-0{i}"] for i in (1, 2, 3)], ["implementado"] * 3)
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1.1 B1-01..B1-02\n")
        st, _ = self.states()
        self.assertEqual((st["B1-01"], st["B1-02"]), ("planejado", "planejado"))

    def test_id_no_titulo_vale_para_as_tasks_abaixo(self):
        write(self.root, "openspec/changes/c1/tasks.md",
              "## 1. Identidade (B2-01)\n- [x] 1.1 Criar enum\n- [x] 1.2 Migrar\n## 2. Outro\n- [ ] 2.1 sem id\n")
        st, _ = self.states()
        self.assertEqual(st["B2-01"], "implementado")
        self.assertEqual(st["B2-02"], "sem_plano")

    def test_sufixo_e_item_proprio(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [x] 1 só B1-10a\n")
        st, _ = self.states()
        self.assertEqual((st["B1-10a"], st["B1-10b"]), ("implementado", "sem_plano"))

    # --- alertas ---
    def test_id_inexistente_gera_alerta_de_erro(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1.1 Typo B2-99\n")
        _, rep = self.states()
        self.assertIn("B2-99", rep.unknown)
        self.assertTrue(sp.has_errors(rep))
        self.assertIn("`B2-99`", sp.render(rep))

    def test_arquivada_com_task_pendente_e_erro(self):
        write(self.root, "openspec/changes/archive/x/tasks.md", "- [ ] 1 B1-01\n")
        _, rep = self.states()
        self.assertTrue(sp.has_errors(rep))

    def test_buraco_so_aparece_em_bloco_em_andamento(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1 B1-01\n")
        text = sp.render(sp.build(self.root))
        self.assertIn("**B1** tem requisitos planejados", text)
        self.assertNotIn("**B2** tem requisitos planejados", text)

    # --- relatório e CLI ---
    def test_resumo_e_percentuais(self):
        write(self.root, "openspec/changes/archive/a/tasks.md", "- [x] 1 B1-01\n- [x] 2 B1-02\n")
        text = sp.render(sp.build(self.root))
        self.assertIn("**2/7 requisitos entregues (29%)**", text)
        self.assertIn("| B1 | Remoção do PRO | 4 | 2 | 0 | 0 | 0 | 2 | 50% |", text)

    def test_saida_deterministica(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1 B1-01\n")
        self.assertEqual(sp.render(sp.build(self.root)), sp.render(sp.build(self.root)))

    def _run(self, *args):
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            code = sp.main(["--root", str(self.root), *args])
        return code, out.getvalue(), err.getvalue()

    def test_cli_escreve_e_check(self):
        code, out, _ = self._run()
        self.assertEqual(code, 0)
        self.assertIn("0/7 requisitos entregues", out)
        self.assertTrue((self.root / "docs" / "PROGRESS.md").is_file())
        self.assertEqual(self._run("--check")[0], 0)
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1 B1-01\n")
        code, _, err = self._run("--check")
        self.assertEqual(code, 1)
        self.assertIn("desatualizado", err)
        self._run()
        self.assertEqual(self._run("--check")[0], 0)

    def test_cli_check_falha_com_erro_mesmo_atualizado(self):
        write(self.root, "openspec/changes/c1/tasks.md", "- [ ] 1 B9-99\n")
        self._run()
        self.assertEqual(self._run("--check")[0], 1)

    def test_cli_sem_specs(self):
        (self.root / "docs" / "SPECS.md").unlink()
        self.assertEqual(self._run()[0], 2)


if __name__ == "__main__":
    unittest.main()
