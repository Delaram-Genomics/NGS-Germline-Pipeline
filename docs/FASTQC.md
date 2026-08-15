# Raw-read quality control

## Purpose

Raw-read QC asks whether the sequencing data are technically suitable for the
next analytical stage and whether preprocessing changes the data as expected.
It does not prove that a sample is clinically acceptable or that a downstream
variant call is correct.

The QC workflow runs:

1. **FastQC on raw R1 and R2** to inspect the original data.
2. **fastp** to detect paired-end adapters and remove adapter/low-quality bases.
3. **FastQC on trimmed R1 and R2** to show the effect of preprocessing.
4. **MultiQC** to combine all sample reports into one review surface.

## Run the stage

```bash
python3 scripts/validate_inputs.py --samplesheet samplesheet.csv

scripts/run_qc.sh \
  --samplesheet samplesheet.csv \
  --outdir qc \
  --threads 4
```

Before running expensive tools, a beginner can inspect the commands safely:

```bash
scripts/run_qc.sh \
  --samplesheet samplesheet.csv \
  --outdir qc \
  --threads 4 \
  --dry-run
```

## Review order

Open `qc/multiqc/multiqc_report.html` and review the following for every sample
and for R1/R2 separately.

| Metric | Question to ask | Important caution |
| --- | --- | --- |
| Per-base quality | Does quality decline near read ends? | A warning alone is not a reason to discard a run. |
| Adapter content | Are adapter sequences present and reduced after fastp? | Heavy trimming may shorten usable reads. |
| Sequence length | Is the post-trim distribution plausible? | Variable length is expected after trimming. |
| GC content | Is the shape plausible for the library design? | WES capture makes genome-wide expectations inappropriate. |
| Duplication | Is duplication consistent with library complexity and capture? | WES often has higher duplication than WGS. |
| Overrepresented sequences | Do they represent adapters, primers or biological sequence? | Identify the sequence before deciding what to do. |
| Read retention | How many read pairs and bases remain after fastp? | High retention does not by itself prove good data. |

## Interpretation framework

Document each observation using four fields:

- **Observation:** what the report shows.
- **Possible cause:** the technical or biological explanation.
- **Impact:** how it could affect alignment or variant calling.
- **Action:** proceed, investigate, repeat a step, or escalate for review.

Example:

> R2 quality declines after cycle 130 and fastp removes a small terminal region.
> Adapter content is reduced and most read pairs are retained. This is unlikely
> to prevent alignment, but the post-trim FastQC report and downstream coverage
> metrics should be reviewed before accepting the sample.

## What not to claim

- Do not write "all green ticks means the sample passed".
- Do not use one universal threshold for every platform, assay and laboratory.
- Do not claim trimming always improves variant calling.
- Do not describe public test data as patient data.
- Do not infer sample identity or contamination from FastQC alone.

## Outputs retained as evidence

```text
qc/
├── raw_fastqc/
├── trimmed_fastq/
├── fastp/
├── trimmed_fastqc/
├── multiqc/multiqc_report.html
└── logs/software_versions.tsv
```

Large generated outputs are intentionally excluded from Git. A portfolio case
study should include only non-sensitive summary figures, interpretation and
reproduction instructions.
