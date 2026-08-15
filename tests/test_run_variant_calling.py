import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]
SCRIPT = REPO_ROOT / "scripts" / "run_variant_calling.sh"


class RunVariantCallingTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.samplesheet = self.root / "samplesheet.csv"
        self.samplesheet.write_text(
            "sample_id,fastq_r1,fastq_r2\n"
            "HG002,/public/HG002_R1.fastq.gz,/public/HG002_R2.fastq.gz\n",
            encoding="utf-8",
        )
        self.reference = self.root / "GRCh38.fa"
        self.reference.write_text(">chr1\nACGT\n", encoding="ascii")
        self.intervals = self.root / "targets.interval_list"
        self.intervals.write_text("@HD\tVN:1.6\tSO:coordinate\nchr1\t1\t4\t+\ttest\n", encoding="ascii")
        self.bam_dir = self.root / "bam"
        self.bam_dir.mkdir()
        (self.bam_dir / "HG002.markdup.bam").write_bytes(b"synthetic-test-placeholder")

    def tearDown(self):
        self.tempdir.cleanup()

    def _base_command(self):
        return [
            "bash",
            str(SCRIPT),
            "--samplesheet",
            str(self.samplesheet),
            "--reference",
            str(self.reference),
            "--intervals",
            str(self.intervals),
            "--bam-dir",
            str(self.bam_dir),
            "--outdir",
            str(self.root / "variants"),
            "--dry-run",
        ]

    def test_dry_run_has_call_filter_normalise_and_stats(self):
        result = subprocess.run(
            self._base_command(),
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        for command in (
            "HaplotypeCaller",
            "GenotypeGVCFs",
            "VariantFiltration",
            "MergeVcfs",
            "bcftools norm",
            "bcftools stats",
        ):
            self.assertIn(command, result.stdout)
        self.assertIn("QD\\ \\<\\ 2.0", result.stdout)

    def test_missing_bam_fails(self):
        (self.bam_dir / "HG002.markdup.bam").unlink()
        result = subprocess.run(
            self._base_command(),
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Input BAM missing", result.stderr)

    def test_invalid_memory_fails(self):
        command = self._base_command()
        command[command.index("--dry-run"):command.index("--dry-run") + 1] = ["--memory-gb", "0", "--dry-run"]
        result = subprocess.run(
            command,
            cwd=REPO_ROOT,
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("memory-gb must be a positive integer", result.stderr)


if __name__ == "__main__":
    unittest.main()
