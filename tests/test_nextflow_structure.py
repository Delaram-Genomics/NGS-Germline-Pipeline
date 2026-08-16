import json
import os
import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).parents[1]


class NextflowStructureTests(unittest.TestCase):
    def test_required_processes_are_declared_once(self):
        source = (REPO_ROOT / "main.nf").read_text(encoding="utf-8")
        process_names = (
            "RAW_READ_QC",
            "ALIGNMENT_AND_BAM_QC",
            "GERMLINE_SHORT_VARIANTS",
            "OFFLINE_VEP_ANNOTATION",
        )
        for name in process_names:
            self.assertEqual(len(re.findall(rf"process\s+{name}\s*\{{", source)), 1, name)
        self.assertIn("nextflow.enable.dsl = 2", source)
        self.assertIn("checkIfExists: true", source)

    def test_every_process_script_exists_and_is_executable(self):
        for name in (
            "run_qc.sh",
            "run_alignment.sh",
            "run_variant_calling.sh",
            "run_annotation.sh",
        ):
            path = REPO_ROOT / "scripts" / name
            self.assertTrue(path.is_file(), name)
            self.assertTrue(os.access(path, os.X_OK), name)

    def test_every_process_has_a_safe_stub(self):
        source = (REPO_ROOT / "main.nf").read_text(encoding="utf-8")
        self.assertEqual(len(re.findall(r"(?m)^\s{4}stub:\s*$", source)), 4)
        self.assertNotIn("patient", source.lower())

    def test_schema_is_valid_json_and_has_required_inputs(self):
        schema = json.loads((REPO_ROOT / "nextflow_schema.json").read_text(encoding="utf-8"))
        self.assertEqual(set(schema["required"]), {"samplesheet", "reference", "intervals"})
        for name in schema["required"]:
            self.assertIn(name, schema["properties"])

    def test_nextflow_config_emits_provenance_reports(self):
        config = (REPO_ROOT / "nextflow.config").read_text(encoding="utf-8")
        for report in ("timeline", "report", "trace", "dag"):
            self.assertRegex(config, rf"(?m)^{report}\s*\{{")
        self.assertEqual(config.count("overwrite = true"), 4)
        self.assertIn("nextflowVersion = '>=24.10.0'", config)

    def test_ci_profile_overrides_named_process_cpu_requests(self):
        config = (REPO_ROOT / "nextflow.config").read_text(encoding="utf-8")
        test_profile = config.split("test {", maxsplit=1)[1]
        for process_name in (
            "RAW_READ_QC",
            "ALIGNMENT_AND_BAM_QC",
            "GERMLINE_SHORT_VARIANTS",
        ):
            self.assertIn(f"withName: {process_name}", test_profile)
        self.assertGreaterEqual(test_profile.count("memory = '4 GB'"), 4)

    def test_pipeline_info_directory_is_created_before_execution(self):
        source = (REPO_ROOT / "main.nf").read_text(encoding="utf-8")
        workflow_body = source.split("workflow {", maxsplit=1)[1]
        self.assertIn("pipeline_info", workflow_body)
        self.assertIn("mkdirs()", workflow_body)

    def test_patient_like_numeric_identifiers_are_not_in_tracked_content(self):
        # Exclude digit runs embedded inside hexadecimal checksums while still
        # rejecting independent 11-digit identifiers in prose and filenames.
        patient_like_identifier = re.compile(r"(?<![0-9A-Fa-f])\d{11}(?![0-9A-Fa-f])")
        allowed_suffixes = {".md", ".py", ".sh", ".nf", ".json", ".yml", ".yaml", ".cff", ".txt"}
        for path in REPO_ROOT.rglob("*"):
            if ".git" in path.parts or not path.is_file() or path.suffix not in allowed_suffixes:
                continue
            content = path.read_text(encoding="utf-8", errors="ignore")
            self.assertIsNone(patient_like_identifier.search(content), str(path))


if __name__ == "__main__":
    unittest.main()
