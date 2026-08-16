# Changelog

All notable changes are documented here. The project follows semantic
versioning after the first validated release.

## [Unreleased]

### Validation still required

- Execute the Nextflow workflow in the target Ubuntu/WSL environment.
- Complete the synthetic smoke test with all external tools.
- Run a versioned public HG002 GIAB benchmark and report SNP/indel metrics.
- Confirm VEP cache compatibility and annotation outputs.

## [0.1.0-alpha] - 2026-08-16

### Added

- Input samplesheet validation with gzip-integrity checks.
- Raw and post-trimming FastQC, fastp and MultiQC workflow.
- BWA-MEM alignment, mate fixing, coordinate sorting and duplicate marking.
- BAM validation, indexing and alignment metrics.
- GATK HaplotypeCaller gVCF workflow, genotyping and documented hard filters.
- bcftools normalisation and variant statistics.
- Offline, cache-versioned VEP annotation.
- Transparent non-clinical research-review table.
- Nextflow DSL2 stage orchestration and execution-provenance reports.
- Deterministic non-human smoke fixture and GIAB/hap.py benchmark wrapper.
- Data-governance rules excluding confidential patient data.
- Automated Python, Bash, schema, privacy and workflow-structure tests.

### Changed

- Replaced the original hard-coded and empty script placeholders with tested,
  parameterised stage implementations.
- Narrowed version 1 scope to paired-end Illumina WES, GRCh38, germline SNVs
  and small indels.

### Removed

- Empty notebooks, image placeholders and documentation files that suggested
  work which had not been implemented.

[Unreleased]: https://github.com/Delaram-Genomics/NGS-Germline-Pipeline/compare/v0.1.0-alpha...HEAD
[0.1.0-alpha]: https://github.com/Delaram-Genomics/NGS-Germline-Pipeline/releases/tag/v0.1.0-alpha
