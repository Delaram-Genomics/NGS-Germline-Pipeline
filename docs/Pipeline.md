# Scientific and technical pipeline rationale

## Analytical question

Given paired-end Illumina WES reads from an approved public reference sample,
can a reproducible workflow produce technically reviewed, annotated germline
SNV and small-indel calls against GRCh38?

## Stage rationale

### 1. Input validation

Metadata errors can associate reads with the wrong sample or mate. The pipeline
therefore checks required columns, unique sample IDs, distinct R1/R2 paths,
gzip readability and file existence before expensive work.

### 2. Raw-read QC and preprocessing

FastQC and MultiQC expose quality, adapter, GC, duplication and sequence-
content patterns. fastp performs paired-end adapter detection and trimming.
Both pre- and post-trim evidence are retained because trimming is a change that
must be observed, not assumed beneficial.

### 3. Alignment and BAM processing

BWA-MEM maps reads to the declared reference. Read groups preserve sample and
library context. Name sorting and `fixmate` prepare mate tags; coordinate
sorting and duplicate marking create a downstream-compatible BAM while keeping
duplicate evidence marked rather than deleted.

### 4. Germline short-variant discovery

GATK HaplotypeCaller locally reassembles candidate regions and emits a gVCF.
Genotyping converts reference-confidence evidence into variant records. SNPs
and indels receive separate, visible filter labels; records are retained for
audit and then normalised to reduce representation differences.

### 5. Annotation and research triage

Offline VEP adds versioned transcript, consequence, frequency and database
context. A transparent rule creates a review queue for PASS, rare/unreported,
HIGH/MODERATE-impact records. This is research triage—not pathogenicity
classification.

### 6. Verification

A synthetic fixture tests workflow wiring. Public GIAB HG002 truth calls and
confident regions support haplotype-aware benchmarking with hap.py. SNP and
indel results are reported separately with TP, FP, FN, precision, recall and F1.

## Unsupported conclusions

The workflow cannot determine that:

- a patient has or does not have a genetic condition;
- a variant is pathogenic or benign;
- an uncaptured or difficult locus is reference sequence;
- unsupported CNVs, SVs, repeat expansions or mitochondrial variants are absent;
- performance in one public benchmark generalises to all samples or assays.
