# Portfolio and application wording

Use only wording supported by the current project status. Update claims after a
real run rather than writing anticipated results as completed achievements.

## Current CV bullets

- Developed a reproducible paired-end germline WES workflow in Bash and
  Nextflow DSL2, covering FASTQ validation, FastQC/fastp/MultiQC, GRCh38
  alignment, BAM processing, GATK gVCF calling, filtering, normalisation and
  offline VEP annotation.
- Built an automated test suite covering metadata validation, failure handling,
  workflow structure, non-clinical variant triage and data-governance controls;
  all current tests pass in the local development environment.
- Implemented provenance capture for software versions, reference/resource
  checksums and Nextflow execution reports, with explicit separation of
  technical research outputs from clinical interpretation.
- Designed a validation pathway using a deterministic non-human smoke fixture
  and NIST GIAB HG002/hap.py benchmarking; end-to-end and accuracy execution are
  documented as pending rather than claimed as completed.

## CV bullet after successful GIAB benchmark

Use this only after inserting verified numbers:

> Benchmarked germline SNV/indel calls for public GIAB HG002 data within
> versioned high-confidence target regions using hap.py, achieving [SNP
> precision/recall] and [indel precision/recall]; investigated false-positive
> and false-negative contexts and documented reference, truth-set and pipeline
> checksums for reproducibility.

## LinkedIn/project description

> I am developing an educational, reproducible germline WES workflow that
> connects my molecular-genetics and NHS variant-interpretation experience with
> practical bioinformatics engineering. The project uses Nextflow DSL2,
> FastQC/MultiQC, BWA-MEM, samtools, GATK, bcftools and offline VEP. It includes
> automated testing, provenance, data-governance controls and a planned NIST
> GIAB benchmark. It is a research portfolio project, not a clinical diagnostic
> pipeline.

## Suitable target roles

- Genomics Laboratory Scientist or Associate Scientist with NGS analysis.
- Molecular Diagnostics Scientist/Technician with bioinformatics exposure.
- Research Technician or Research Assistant in genomic medicine.
- Junior Genomics Analyst or Bioinformatics Assistant where wet-lab literacy is
  valued.

## Evidence to show a recruiter

1. Repository README and workflow diagram.
2. Passing CI and test summary.
3. MultiQC and Nextflow reports from public data.
4. GIAB benchmark report with honest limitations.
5. A three-minute demonstration and one-page case-study summary.

Do not present confidential laboratory data, patient-derived screenshots or
unverified performance figures.
