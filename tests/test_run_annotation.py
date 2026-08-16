import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]
SCRIPT = REPO_ROOT / "scripts" / "run_annotation.sh"


class RunAnnotationTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)
        self.samplesheet = self.root / "samplesheet.csv"
        self.samplesheet.write_text(
            "sample_id,fastq_r1,fastq_r2\nHG002,/public/R1.fastq.gz,/public/R2.fastq.gz\n",
            encoding="utf-8",
        )
        self.reference = self.root / "GRCh38.fa"
        self.reference.write_text(">chr1\nACGT\n", encoding="ascii")
        self.cache = self.root / "vep_cache"
        self.cache.mkdir()
        self.vcf_dir = self.root / "filtered"
        self.vcf_dir.mkdir()
        (self.vcf_dir / "HG002.filtered.normalised.vcf.gz").write_bytes(b"synthetic-vcf-placeholder")

    def tearDown(self):
        self.tempdir.cleanup()

    def _command(self):
        return [
            "bash",
            str(SCRIPT),
            "--samplesheet",
            str(self.samplesheet),
            "--reference",
            str(self.reference),
            "--vep-cache-dir",
            str(self.cache),
            "--vep-cache-version",
            "113",
            "--vcf-dir",
            str(self.vcf_dir),
            "--outdir",
            str(self.root / "annotation"),
            "--dry-run",
        ]

    def test_dry_run_is_offline_versioned_and_nonclinical(self):
        result = subprocess.run(
            self._command(), cwd=REPO_ROOT, check=False, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("vep", result.stdout)
        self.assertIn("--offline", result.stdout)
        self.assertIn("--cache_version 113", result.stdout)
        self.assertIn("--clin_sig_allele 1", result.stdout)
        self.assertNotIn("--clin_sig ", result.stdout)
        self.assertIn("grep 'ensembl-vep'", SCRIPT.read_text(encoding="utf-8"))
        self.assertIn("prioritise_variants.py", result.stdout)

    def test_missing_vcf_fails(self):
        (self.vcf_dir / "HG002.filtered.normalised.vcf.gz").unlink()
        result = subprocess.run(
            self._command(), cwd=REPO_ROOT, check=False, capture_output=True, text=True
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("Normalised input VCF missing", result.stderr)


if __name__ == "__main__":
    unittest.main()
