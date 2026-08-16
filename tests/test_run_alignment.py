import gzip
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]
SCRIPT = REPO_ROOT / "scripts" / "run_alignment.sh"


class RunAlignmentTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.raw_r1 = self._fastq("raw_R1.fastq.gz")
        self.raw_r2 = self._fastq("raw_R2.fastq.gz")
        self.samplesheet = self.root / "samplesheet.csv"
        self.samplesheet.write_text(
            f"sample_id,fastq_r1,fastq_r2\nsample1,{self.raw_r1},{self.raw_r2}\n",
            encoding="utf-8",
        )
        self.reference = self.root / "GRCh38.fa"
        self.reference.write_text(">chr1\nACGT\n", encoding="ascii")
        self.reads_dir = self.root / "trimmed"
        self.reads_dir.mkdir()
        self._fastq_at(self.reads_dir / "sample1_R1.trimmed.fastq.gz")
        self._fastq_at(self.reads_dir / "sample1_R2.trimmed.fastq.gz")

    def tearDown(self):
        self.tempdir.cleanup()

    def _fastq(self, name: str) -> Path:
        path = self.root / name
        self._fastq_at(path)
        return path

    @staticmethod
    def _fastq_at(path: Path) -> None:
        with gzip.open(path, "wt", encoding="ascii") as handle:
            handle.write("@read1\nACGT\n+\nIIII\n")

    def test_trimmed_dry_run_has_complete_bam_workflow(self):
        outdir = self.root / "alignment"
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--samplesheet",
                str(self.samplesheet),
                "--reference",
                str(self.reference),
                "--reads-dir",
                str(self.reads_dir),
                "--outdir",
                str(outdir),
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
        for command in ("bwa mem", "samtools fixmate", "samtools markdup", "samtools flagstat"):
            self.assertIn(command, result.stdout)
        self.assertIn("@RG", result.stdout)

    def test_missing_trimmed_reads_fail(self):
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--samplesheet",
                str(self.samplesheet),
                "--reference",
                str(self.reference),
                "--reads-dir",
                str(self.root / "missing"),
                "--dry-run",
            ],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Trimmed R1 not found", result.stderr)

    def test_raw_dry_run_uses_samplesheet_paths(self):
        result = subprocess.run(
            [
                "bash",
                str(SCRIPT),
                "--samplesheet",
                str(self.samplesheet),
                "--reference",
                str(self.reference),
                "--use-raw",
                "--dry-run",
            ],
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(str(self.raw_r1), result.stdout)
        self.assertIn(str(self.raw_r2), result.stdout)


if __name__ == "__main__":
    unittest.main()
