import csv
import gzip
import tempfile
import unittest
from pathlib import Path

import importlib.util
import sys


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "prioritise_variants.py"
SPEC = importlib.util.spec_from_file_location("prioritise_variants", MODULE_PATH)
prioritise_variants = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = prioritise_variants
SPEC.loader.exec_module(prioritise_variants)


class PrioritiseVariantsTests(unittest.TestCase):
    def setUp(self):
        self.tempdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tempdir.name)

    def tearDown(self):
        self.tempdir.cleanup()

    def _vcf(self, records: list[str], include_csq=True) -> Path:
        path = self.root / "annotated.vcf.gz"
        with gzip.open(path, "wt", encoding="utf-8") as handle:
            handle.write("##fileformat=VCFv4.2\n")
            if include_csq:
                handle.write(
                    '##INFO=<ID=CSQ,Number=.,Type=String,Description="VEP. Format: '
                    'Allele|Consequence|IMPACT|SYMBOL|Gene|Feature|BIOTYPE|HGVSc|HGVSp|'
                    'CANONICAL|MANE_SELECT|CLIN_SIG|MAX_AF|SIFT|PolyPhen">\n'
                )
            handle.write("#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n")
            for record in records:
                handle.write(record + "\n")
        return path

    def test_rare_moderate_pass_variant_is_review(self):
        vcf = self._vcf([
            "chr1\t10\t.\tA\tG\t50\tPASS\tCSQ=G|missense_variant|MODERATE|GENE1|ENSG1|ENST1|protein_coding|c.1A>G|p.Lys1Arg|YES|NM_1.1|uncertain_significance|0.001|tolerated|benign"
        ])
        records = prioritise_variants.parse_annotated_vcf(vcf)
        self.assertEqual(records[0]["research_review_flag"], "REVIEW")
        self.assertIn("MAX_AF <= 0.01", records[0]["review_reason"])

    def test_common_variant_is_lower_priority(self):
        vcf = self._vcf([
            "chr1\t11\t.\tC\tT\t50\tPASS\tCSQ=T|missense_variant|MODERATE|GENE2|ENSG2|ENST2|protein_coding||||||0.2||"
        ])
        records = prioritise_variants.parse_annotated_vcf(vcf)
        self.assertEqual(records[0]["research_review_flag"], "LOWER_PRIORITY")

    def test_filtered_variant_is_not_prioritised(self):
        vcf = self._vcf([
            "chr1\t12\t.\tG\tA\t20\tSNP_QD2\tCSQ=A|stop_gained|HIGH|GENE3|ENSG3|ENST3|protein_coding|||||||||"
        ])
        records = prioritise_variants.parse_annotated_vcf(vcf)
        self.assertEqual(records[0]["research_review_flag"], "DO_NOT_PRIORITISE")

    def test_missing_csq_header_fails(self):
        vcf = self._vcf(["chr1\t10\t.\tA\tG\t50\tPASS\tDP=20"], include_csq=False)
        with self.assertRaisesRegex(prioritise_variants.AnnotationError, "CSQ header"):
            prioritise_variants.parse_annotated_vcf(vcf)

    def test_write_tsv_has_stable_columns(self):
        vcf = self._vcf([
            "chr1\t10\t.\tA\tG\t50\tPASS\tCSQ=G|missense_variant|MODERATE|GENE1|ENSG1|ENST1|protein_coding||||||0.001||"
        ])
        output = self.root / "review.tsv"
        prioritise_variants.write_tsv(prioritise_variants.parse_annotated_vcf(vcf), output)
        with output.open(newline="", encoding="utf-8") as handle:
            row = next(csv.DictReader(handle, delimiter="\t"))
        self.assertEqual(tuple(row), prioritise_variants.OUTPUT_FIELDS)


if __name__ == "__main__":
    unittest.main()
