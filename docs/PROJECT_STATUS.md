# Project status

Status date: 2026-08-16

Planned release: `v0.1.0-alpha`

## Implemented and locally tested

- Samplesheet structure, path and gzip validation.
- Raw/post-trim FastQC, fastp and MultiQC stage commands.
- BWA-MEM, samtools fixmate/sort/markdup/index and alignment metrics.
- GATK HaplotypeCaller gVCF, genotyping and labelled hard filters.
- bcftools normalisation and statistics.
- Offline VEP command construction and research-review table parser.
- Nextflow DSL2 stage orchestration, profiles, schema and provenance reports.
- Deterministic synthetic fixture and hap.py benchmark wrapper.
- Automated tests for expected success and failure paths.

## Verified in this development environment

- All Python unit tests pass.
- Python sources compile.
- Bash scripts pass syntax checks.
- JSON schema parses successfully.
- Git whitespace checks pass.
- Patient-like numeric identifiers are rejected from tracked text by a test.
- Nextflow 26.04.6 completed the synthetic workflow through variant calling on
  Ubuntu/WSL2 with 7.6 GiB RAM.
- The one introduced heterozygous SNV was recovered as `0/1` with `PASS`; see
  `docs/SMOKE_TEST_REPORT.md` for commands, versions, checksums and limitations.

## Not yet verified

- End-to-end execution with FastQC, fastp, BWA, samtools, GATK, bcftools, VEP
  and hap.py together.
- VEP cache compatibility and real annotation output.
- GIAB HG002 precision, recall and F1 metrics.
- Performance across more than one public reference sample or capture design.

## Release gate

Do not mark the project `v1.0.0` or describe it as production-ready until:

1. the synthetic workflow completes through variant calling;
2. HG002 completes with versioned public inputs;
3. hap.py metrics and failure analysis are reviewed;
4. commands, resource versions and checksums are published;
5. a second person can reproduce the documented run;
6. limitations and unresolved failures are recorded.

Clinical validation remains outside the repository scope.
