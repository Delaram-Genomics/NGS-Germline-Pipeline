# Interview guide

## Thirty-second project explanation

> I built this project to connect my wet-lab genetics and clinical variant-
> interpretation experience with reproducible NGS analysis. It takes approved
> paired-end WES FASTQs through QC, GRCh38 alignment, BAM processing, GATK
> germline calling, normalisation and offline VEP annotation. Nextflow manages
> dependencies and restartability, while automated tests and provenance records
> make failures and assumptions visible. It is deliberately described as a
> research portfolio workflow, not a validated diagnostic pipeline.

## Two-minute technical explanation

1. Validate the samplesheet and gzip streams before compute.
2. Compare FastQC before and after fastp; interpret MultiQC across samples.
3. Align with read groups, fix mate tags, coordinate-sort and mark duplicates.
4. Call gVCFs with HaplotypeCaller and genotype the sample.
5. Label SNP/indel hard-filter failures without deleting audit evidence.
6. Normalise variant representation and annotate offline with a pinned VEP
   cache release.
7. Use only transparent research triage, leaving clinical classification to an
   authorised, evidence-based process.
8. Verify wiring with synthetic data and accuracy with GIAB/hap.py.

## Likely questions and strong answers

### Why WES rather than WGS?

The first version has a deliberately narrow, achievable scope aligned with my
experience and available compute. WES also forces explicit consideration of
capture targets, non-uniform coverage and the difference between target and
benchmark regions. WGS, CNV and SV analysis are valid future extensions, not
features I claim prematurely.

### Why mark rather than remove duplicates?

Marking preserves records and communicates duplicate status to downstream
tools. Removing them discards evidence and may not be appropriate for every
assay. Duplication must be interpreted with library complexity and WES capture
in mind.

### Why use gVCF mode for one sample?

It separates read-level calling from genotyping and provides a path to later
joint genotyping. The current demonstration genotypes independently, and the
documentation states that cohort joint calling is not yet implemented.

### Are the hard filters clinical thresholds?

No. They are visible demonstration defaults based on GATK guidance. Their
effect must be measured on the selected assay and benchmark; a regulated test
would require documented local validation and change control.

### Does VEP classify pathogenicity?

No. VEP provides transcript consequences and external annotations. ClinVar and
in-silico predictions require evaluation of their underlying evidence,
transcript, phenotype, inheritance, disease mechanism and technical read data.

### What would you improve next?

Complete the smoke and HG002 runs, investigate discordant calls, refactor the
Nextflow stage-level design into per-sample modules, pin environments more
tightly, add target-coverage/contamination checks and test a second public
reference sample.

## STAR example: protecting patient data

- **Situation:** A real laboratory patient FASTQ was available during portfolio
  development.
- **Task:** Continue learning NGS analysis without risking confidential data or
  overstating permission.
- **Action:** Excluded the file from processing and public version control,
  documented data-governance rules, added privacy-oriented tests and selected
  public GIAB data for benchmarking.
- **Result:** The portfolio remains reproducible and reviewable without relying
  on confidential material, while demonstrating judgement relevant to quality-
  focused genomics work.

## Honest answer when a run is pending

> The implementation and automated tests are complete, but the full external-
> tool run and GIAB accuracy benchmark are still pending. I have documented that
> explicitly and would not report performance until the versioned run and error
> analysis are complete.
