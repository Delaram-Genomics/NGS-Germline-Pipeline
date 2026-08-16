import csv
import gzip
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]
FIXTURE_MODULE_PATH = REPO_ROOT / "scripts" / "create_smoke_fixture.py"
SPEC = importlib.util.spec_from_file_location("create_smoke_fixture", FIXTURE_MODULE_PATH)
create_smoke_fixture = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = create_smoke_fixture
SPEC.loader.exec_module(create_smoke_fixture)


class SmokeFixtureTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def test_fixture_is_deterministic_and_valid(self):
        first = self.root / "first"
        second = self.root / "second"
        create_smoke_fixture.create_fixture(first)
        create_smoke_fixture.create_fixture(second)
        self.assertEqual((first / "synthetic.fa").read_bytes(), (second / "synthetic.fa").read_bytes())
        self.assertEqual((first / "expected_variant.txt").read_bytes(), (second / "expected_variant.txt").read_bytes())
        with gzip.open(first / "SYNTH001_R1.fastq.gz", "rt", encoding="ascii") as handle:
            self.assertEqual(sum(1 for _ in handle), 120)
        with (first / "samplesheet.csv").open(newline="", encoding="utf-8") as handle:
            row = next(csv.DictReader(handle))
        self.assertEqual(row["sample_id"], "SYNTH001")
        self.assertTrue(Path(row["fastq_r1"]).is_file())
        self.assertIn("no human or patient data", (first / "README.txt").read_text(encoding="utf-8"))


class BenchmarkWrapperTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.paths = {}
        for name in ("truth.vcf.gz", "query.vcf.gz", "confident.bed", "reference.fa"):
            path = self.root / name
            path.write_text("synthetic-placeholder\n", encoding="ascii")
            self.paths[name] = path

    def tearDown(self):
        self.tempdir.cleanup()

    def _command(self):
        return [
            "bash",
            str(REPO_ROOT / "scripts" / "run_benchmark.sh"),
            "--truth",
            str(self.paths["truth.vcf.gz"]),
            "--query",
            str(self.paths["query.vcf.gz"]),
            "--confident-regions",
            str(self.paths["confident.bed"]),
            "--reference",
            str(self.paths["reference.fa"]),
            "--output-prefix",
            str(self.root / "results" / "HG002"),
            "--dry-run",
        ]

    def test_benchmark_dry_run_has_required_happy_inputs(self):
        result = subprocess.run(
            self._command(), cwd=REPO_ROOT, check=False, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("hap.py", result.stdout)
        self.assertIn("-f", result.stdout)
        self.assertIn("-r", result.stdout)
        self.assertIn("--engine xcmp", result.stdout)

    def test_missing_truth_fails(self):
        self.paths["truth.vcf.gz"].unlink()
        result = subprocess.run(
            self._command(), cwd=REPO_ROOT, check=False, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Benchmark input missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
