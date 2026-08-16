# Alignment and BAM quality control

## Purpose

Alignment assigns sequencing reads to locations in GRCh38. The output BAM is a
technical representation of evidence, not a diagnostic result. Before variant
calling, the file must be structurally valid and its mapping, pairing,
duplication and coverage characteristics must be reviewed.

## Workflow

```text
paired FASTQ
  -> BWA-MEM with read groups
  -> name sort
  -> samtools fixmate
  -> coordinate sort
  -> samtools markdup
  -> quickcheck + index
  -> flagstat + stats
```

`fixmate` adds mate-coordinate and mate-score tags required by `markdup`.
Duplicate reads are marked, not deleted, so downstream tools can apply their
own behaviour and the original evidence remains reviewable.

## Command

The default uses trimmed reads from the QC stage:

```bash
scripts/run_alignment.sh \
  --samplesheet samplesheet.csv \
  --reference /path/to/GRCh38.fa \
  --reads-dir qc/trimmed_fastq \
  --outdir results/alignment \
  --threads 4
```

Preview commands without running BWA or samtools:

```bash
scripts/run_alignment.sh \
  --samplesheet samplesheet.csv \
  --reference /path/to/GRCh38.fa \
  --reads-dir qc/trimmed_fastq \
  --dry-run
```

## Read groups

Each BAM receives an `@RG` record containing:

| Tag | Meaning | Project value |
| --- | --- | --- |
| `ID` | Read-group identifier | sample ID |
| `SM` | Biological sample | sample ID |
| `LB` | Library | `<sample>.lib1` in version 1 |
| `PL` | Platform | `ILLUMINA` |

Read groups are necessary for sample identity and downstream GATK processing.
If a real sample contains several libraries or lanes, the metadata model must
be expanded rather than pretending they are one read group.

## Metrics to review

| Metric | Interpretation question | Possible concern |
| --- | --- | --- |
| Total reads | Is the count consistent with FASTQ and fastp reports? | Unexpected loss or double counting |
| Mapped reads | Did reads align to the intended build? | Wrong reference, contamination, poor reads |
| Properly paired | Are mates aligned with a plausible relationship? | Library or reference problems |
| Secondary/supplementary | Is the fraction plausible for read length and genome? | Repetitive or complex sequence |
| Duplicates | Is duplication consistent with WES capture and library complexity? | Low complexity or over-sequencing |
| Insert size | Is the distribution consistent with library preparation? | Fragmentation or adapter problems |
| Error rate | Is it consistent across samples and read cycles? | Sequencing or alignment issue |

Mapping percentage alone is not an acceptance decision. The earlier project
note reported nearly 100% mapping, but that value must be reproduced from the
actual BAM and interpreted together with duplication, coverage, sample identity
and assay-specific expectations.

## Outputs

```text
results/alignment/
├── bam/<sample>.markdup.bam
├── bam/<sample>.markdup.bam.bai
├── metrics/<sample>.markdup.metrics.txt
├── metrics/<sample>.flagstat.txt
├── metrics/<sample>.stats.txt
└── logs/alignment_provenance.tsv
```

## Current limitations

- Coverage over target intervals is not yet calculated; it is required before
  making claims about WES completeness.
- Sample contamination, relatedness and sex concordance are not yet assessed.
- The initial read-group model assumes one library per sample.
- BQSR and variant calling are separate later milestones.
- Thresholds must be justified for the assay and cannot be copied blindly from
  another laboratory.
