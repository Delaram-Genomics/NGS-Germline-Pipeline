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
- Executed the workflow end to end on public GIAB HG002 Agilent V6 WES data,
  achieving 95.45% SNP recall, 98.54% SNP precision, 89.28% indel recall and
  87.35% indel precision within high-confidence capture targets.
- Measured 180.42x mean Q20 target depth, 95.42% of target bases at >=20x and
  a 72.82% usable on-target alignment rate.

## Concise benchmark bullet

> Benchmarked an end-to-end Nextflow germline WES workflow on public GIAB HG002
> Agilent V6 data using hap.py, achieving 98.54% SNP precision/95.45% recall
> and 87.35% indel precision/89.28% recall within high-confidence capture
> targets, with 95.42% of target bases covered at >=20x (baseQ/mapQ >=20).

## LinkedIn/project description

> I am developing an educational, reproducible germline WES workflow that
> connects my molecular-genetics and NHS variant-interpretation experience with
> practical bioinformatics engineering. The project uses Nextflow DSL2,
> FastQC/MultiQC, BWA-MEM, samtools, GATK, bcftools and offline VEP. It includes
> automated testing, provenance and data-governance controls. I benchmarked the
> WES workflow on public NIST GIAB HG002 data within Agilent V6 capture targets
> and documented its accuracy and limitations. It is a research portfolio
> project, not a clinical diagnostic pipeline.

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
