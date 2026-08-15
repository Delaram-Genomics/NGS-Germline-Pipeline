import gzip
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]
SCRIPT = REPO_ROOT / "scripts" / "run_qc.sh"


class RunQcTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.r1 = self._fastq("sample_R1.fastq.gz")
        self.r2 = self._fastq("sample_R2.fastq.gz")
        self.samplesheet = self.root / "samplesheet.csv"
        self.samplesheet.write_text(
            f"sample_id,fastq_r1,fastq_r2\nsample1,{self.r1},{self.r2}\n",
            encoding="utf-8",
        )

    def tearDown(self):
        self.tempdir.cleanup()

    def _fastq(self, name: str) -> Path:
        path = self.root / name
        with gzip.open(path, "wt", encoding="ascii") as handle:
            handle.write("@read1\nACGT\n+\nIIII\n")
        return path

    def test_dry_run_prints_all_tools(self):
        output_dir = self.root / "qc"
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--samplesheet",
                str(self.samplesheet),
                "--outdir",
                str(output_dir),
                "--threads",
                "2",
                "--dry-run",
            ],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("DRY-RUN: fastqc", result.stdout)
        self.assertIn("DRY-RUN: fastp", result.stdout)
        self.assertIn("DRY-RUN: multiqc", result.stdout)
        self.assertTrue((output_dir / "raw_fastqc").is_dir())
        self.assertTrue((output_dir / "trimmed_fastqc").is_dir())

    def test_invalid_thread_count_fails(self):
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--samplesheet",
                str(self.samplesheet),
                "--threads",
                "zero",
                "--dry-run",
            ],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("positive integer", result.stderr)


if __name__ == "__main__":
    unittest.main()
