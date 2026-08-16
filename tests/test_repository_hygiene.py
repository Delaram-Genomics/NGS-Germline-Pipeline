import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]


class RepositoryHygieneTests(unittest.TestCase):
    def _tracked_files(self):
        result = subprocess.run(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        return [REPO_ROOT / line for line in result.stdout.splitlines() if line]

    def test_no_tracked_file_is_empty(self):
        empty = [str(path.relative_to(REPO_ROOT)) for path in self._tracked_files() if path.is_file() and path.stat().st_size == 0]
        self.assertEqual(empty, [])

    def test_mit_licence_is_complete(self):
        licence = (REPO_ROOT / "LICENSE").read_text(encoding="utf-8")
        self.assertIn("Permission is hereby granted", licence)
        self.assertIn('THE SOFTWARE IS PROVIDED "AS IS"', licence)

    def test_release_metadata_agrees(self):
        citation = (REPO_ROOT / "CITATION.cff").read_text(encoding="utf-8")
        config = (REPO_ROOT / "nextflow.config").read_text(encoding="utf-8")
        changelog = (REPO_ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
        self.assertIn('version: "0.1.0-alpha"', citation)
        self.assertIn("version = '0.1.0-alpha'", config)
        self.assertIn("## [0.1.0-alpha]", changelog)

    def test_legacy_happy_runtime_is_isolated(self):
        main_environment = (REPO_ROOT / "environment.yml").read_text(encoding="utf-8")
        benchmark_environment = (REPO_ROOT / "environment-benchmark.yml").read_text(
            encoding="utf-8"
        )
        self.assertNotIn("hap.py", main_environment)
        self.assertIn("python=2.7", benchmark_environment)
        self.assertIn("hap.py=0.3.15", benchmark_environment)

    def test_vep_runtime_is_isolated_and_versioned(self):
        main_environment = (REPO_ROOT / "environment.yml").read_text(encoding="utf-8")
        annotation_environment = (REPO_ROOT / "environment-annotation.yml").read_text(
            encoding="utf-8"
        )
        workflow = (REPO_ROOT / "main.nf").read_text(encoding="utf-8")
        self.assertNotIn("ensembl-vep", main_environment)
        self.assertIn("ensembl-vep=116.1", annotation_environment)
        self.assertIn("bcftools=1.24", annotation_environment)
        self.assertIn('conda "${projectDir}/environment-annotation.yml"', workflow)

    def test_readme_local_markdown_links_exist(self):
        readme = (REPO_ROOT / "README.md").read_text(encoding="utf-8")
        import re

        missing = []
        for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", readme):
            if "://" in target or target.startswith("#"):
                continue
            if not (REPO_ROOT / target).exists():
                missing.append(target)
        self.assertEqual(missing, [])


if __name__ == "__main__":
    unittest.main()
