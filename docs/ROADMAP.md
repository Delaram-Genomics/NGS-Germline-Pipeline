# Eight-week delivery and learning roadmap

The project is designed for a wet-lab molecular geneticist developing practical
NGS analysis skills for UK genomics, diagnostics and biotechnology roles. Each
week produces evidence that can be shown in a CV, application or interview.

## Week 1 - Scope, inputs and quality foundation

- Define WES, GRCh38 and germline SNV/indel scope.
- Add samplesheet and configuration contracts.
- Add input validation, unit tests and continuous integration.
- Explain FASTQ structure, paired-end reads and Phred quality.

**Evidence:** tested validator, scope table and quality/limitations document.

## Week 2 - Raw-read QC and preprocessing

- Implement FastQC, fastp and MultiQC.
- Document adapter, quality, duplication, GC and overrepresented-sequence
  interpretation.
- Define QC review rather than automatic pass/fail claims.

**Evidence:** reproducible QC report and a written interpretation of findings.

## Week 3 - Alignment and BAM processing

- Align against GRCh38 with read groups.
- Sort, mark duplicates and index alignments.
- Collect mapping, insert-size, duplication and coverage metrics.

**Evidence:** command provenance, alignment metrics and troubleshooting notes.

## Week 4 - Germline short-variant calling

- Implement GATK HaplotypeCaller in gVCF mode.
- Genotype and normalise variants.
- Separate single-sample demonstration from future cohort joint calling.

**Evidence:** validated VCF plus explanation of DP, GQ, AD, QUAL and FILTER.

## Week 5 - Filtering and annotation

- Apply transparent filtering appropriate to the demonstration dataset.
- Annotate with VEP and version annotation resources.
- Produce a research prioritisation table without automated clinical claims.

**Evidence:** annotated VCF, prioritisation table and limitations statement.

## Week 6 - Workflow orchestration

- Implement the complete analysis in Nextflow DSL2.
- Add restartability, profiles, resource controls and pinned environments.
- Retain the Bash scripts as readable learning references.

**Evidence:** one-command workflow and reproducibility metadata.

## Week 7 - Verification and portfolio case study

- Run a public Genome in a Bottle sample in a bounded test region.
- Compare calls to the truth set and report precision/recall honestly.
- Test expected failures and document recovery.

**Evidence:** benchmark report, limitations and an interview-ready case study.

## Week 8 - Release and job campaign

- Create a tagged release with installation and usage documentation.
- Record a short pipeline demonstration.
- Add evidence-based CV bullets and STAR interview examples.
- Tailor applications to wet-lab/NGS hybrid roles and track outcomes.

**Evidence:** release, demonstration, updated CV and application tracker.

## Weekly working rhythm (20+ hours)

| Activity | Hours |
| --- | ---: |
| Guided implementation and debugging | 8 |
| Concepts and command-line practice | 5 |
| Independent rerun and notes | 4 |
| Portfolio documentation | 2 |
| Job search, applications and interview practice | 3 |

Progress is reviewed using observable evidence: tests passed, commands rerun
independently, concepts explained in plain language, and targeted applications
submitted. Employment is influenced by the market and cannot be guaranteed.
