import csv
import gzip
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "validate_inputs.py"
SPEC = importlib.util.spec_from_file_location("validate_inputs", MODULE_PATH)
validate_inputs = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = validate_inputs
SPEC.loader.exec_module(validate_inputs)


class SamplesheetValidationTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def _fastq(self, name: str) -> Path:
        path = self.root / name
        with gzip.open(path, "wt", encoding="ascii") as handle:
            handle.write("@read1\nACGT\n+\nIIII\n")
        return path

    def _sheet(self, rows: list[dict[str, str]], fields=None) -> Path:
        path = self.root / "samplesheet.csv"
        with path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields or list(validate_inputs.REQUIRED_COLUMNS))
            writer.writeheader()
            writer.writerows(rows)
        return path

    def test_valid_pair_passes(self):
        r1 = self._fastq("sample_R1.fastq.gz")
        r2 = self._fastq("sample_R2.fastq.gz")
        sheet = self._sheet([{"sample_id": "sample-1", "fastq_r1": str(r1), "fastq_r2": str(r2)}])
        samples = validate_inputs.read_samplesheet(sheet)
        validate_inputs.validate_files(samples)
        self.assertEqual(samples[0].sample_id, "sample-1")

    def test_duplicate_sample_id_fails(self):
        rows = [
            {"sample_id": "sample1", "fastq_r1": "a.fastq.gz", "fastq_r2": "b.fastq.gz"},
            {"sample_id": "sample1", "fastq_r1": "c.fastq.gz", "fastq_r2": "d.fastq.gz"},
        ]
        with self.assertRaisesRegex(validate_inputs.ValidationError, "Duplicate"):
            validate_inputs.read_samplesheet(self._sheet(rows))

    def test_missing_column_fails(self):
        fields = ["sample_id", "fastq_r1"]
        rows = [{"sample_id": "sample1", "fastq_r1": "a.fastq.gz"}]
        with self.assertRaisesRegex(validate_inputs.ValidationError, "Missing required"):
            validate_inputs.read_samplesheet(self._sheet(rows, fields=fields))

    def test_same_read_paths_fail(self):
        rows = [{"sample_id": "sample1", "fastq_r1": "same.fastq.gz", "fastq_r2": "same.fastq.gz"}]
        with self.assertRaisesRegex(validate_inputs.ValidationError, "identical"):
            validate_inputs.read_samplesheet(self._sheet(rows))

    def test_corrupt_gzip_fails(self):
        r1 = self.root / "sample_R1.fastq.gz"
        r1.write_text("not gzip", encoding="ascii")
        r2 = self._fastq("sample_R2.fastq.gz")
        sheet = self._sheet([{"sample_id": "sample1", "fastq_r1": str(r1), "fastq_r2": str(r2)}])
        with self.assertRaisesRegex(validate_inputs.ValidationError, "gzip"):
            validate_inputs.validate_files(validate_inputs.read_samplesheet(sheet))


if __name__ == "__main__":
    unittest.main()
