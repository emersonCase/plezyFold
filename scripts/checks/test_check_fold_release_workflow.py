#!/usr/bin/env python3
"""Behavior tests for the plezyFold release-workflow guard."""

from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
CHECKER = ROOT / "scripts/checks/check_fold_release_workflow.py"
WORKFLOW = ROOT / ".github/workflows/fold-release.yml"


class FoldReleaseWorkflowGuardTest(unittest.TestCase):
    def _workflow(self) -> str:
        return WORKFLOW.read_text(encoding="utf-8")

    def _run(self, workflow: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="plezy-fold-release-test-") as directory:
            fixture = Path(directory) / "fold-release.yml"
            fixture.write_text(workflow, encoding="utf-8")
            return subprocess.run(
                [sys.executable, str(CHECKER), str(fixture)],
                cwd=ROOT,
                check=False,
                capture_output=True,
                text=True,
            )

    def test_current_workflow_passes(self) -> None:
        result = self._run(self._workflow())

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("fold release workflow checks passed", result.stdout)

    def test_ordinary_push_trigger_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            '    tags:\n      - "v*.*.*"',
            "    branches:\n      - main",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("trigger only from v-prefixed version tags", result.stderr)

    def test_release_without_tests_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "      - name: Run unit and widget tests\n        shell: bash\n        run: scripts/run_tests.sh\n\n",
            "",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing a required validation or build step", result.stderr)

    def test_release_without_vendored_development_dependencies_is_rejected(self) -> None:
        workflow = self._workflow().replace(
            "      - name: Install wakelock_plus development dependencies\n"
            "        working-directory: packages/wakelock_plus\n"
            "        shell: bash\n"
            "        run: flutter pub get --enforce-lockfile --no-example\n\n",
            "",
            1,
        )

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing a required validation or build step", result.stderr)

    def test_publish_without_build_dependency_is_rejected(self) -> None:
        workflow = self._workflow().replace("    needs: build-and-test\n", "", 1)

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("publication must require the tested build job", result.stderr)

    def test_draft_release_is_rejected(self) -> None:
        workflow = self._workflow().replace("          draft: false\n", "          draft: true\n", 1)

        result = self._run(workflow)

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("non-draft release", result.stderr)


if __name__ == "__main__":
    unittest.main()
