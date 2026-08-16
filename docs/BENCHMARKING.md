# Smoke testing and GIAB benchmarking

## Two different questions

The project separates two forms of evidence:

1. **Smoke test:** does the workflow run from inputs to outputs without broken
   wiring? A tiny deterministic, non-human fixture answers this.
2. **Accuracy benchmark:** how well do calls agree with an independently
   characterised truth set inside defined benchmark regions? GIAB HG002 and
   `hap.py` answer this.

A successful smoke test is not evidence of analytical accuracy.

## Synthetic smoke test

Activate the Conda environment, then generate and index the fixture:

```bash
scripts/prepare_smoke_test.sh --outdir test_data/smoke
```

Run the workflow without VEP, because the synthetic contig has no Ensembl
annotation:

```bash
nextflow run main.nf \
  -profile conda,test \
  --samplesheet test_data/smoke/samplesheet.csv \
  --reference test_data/smoke/synthetic.fa \
  --intervals test_data/smoke/targets.bed \
  --skip_annotation true \
  --outdir test_results \
  -resume
```

The fixture contains one deliberately introduced heterozygous SNV recorded in
`expected_variant.txt`. Because this is a tiny artificial dataset, detection of
that SNV is a functional observation only, not a sensitivity estimate.

## GIAB HG002 benchmark inputs

Use an approved public HG002 sequencing dataset plus all of the following from
one compatible GIAB release:

- GRCh38 truth VCF and index;
- matching GRCh38 confident-region BED;
- the exact compatible GRCh38 reference and indexes;
- the pipeline query VCF for HG002;
- source URLs, release identifiers and published checksums.

Do not mix GRCh37, standard GRCh38 and GIAB-modified GRCh38 resources. Contig
names and reference sequences must match.

NIST recommends HG002 as a starting GIAB genome. For WES, benchmark within the
intersection of the assay target regions and GIAB confident regions. Report the
exact region operation and files used.

## Run hap.py

Activate the isolated benchmark environment first:

```bash
conda activate ngs_benchmark
```

The separate environment prevents the legacy Python runtime required by the
current Bioconda `hap.py` build from weakening the main Python 3.12 analysis
environment.

```bash
scripts/run_benchmark.sh \
  --truth /path/to/HG002_GRCh38_truth.vcf.gz \
  --query results/variants/filtered/HG002.filtered.normalised.vcf.gz \
  --confident-regions /path/to/HG002_GRCh38_confident_regions.bed \
  --reference /path/to/compatible_GRCh38.fa \
  --output-prefix results/benchmark/HG002 \
  --threads 4
```

The wrapper records SHA-256 checksums for every benchmark input.

## Metrics

For each variant class, report counts and rates together:

\[
\text{Precision} = \frac{TP}{TP + FP}
\]

\[
\text{Recall} = \frac{TP}{TP + FN}
\]

\[
F_1 = 2 \times \frac{\text{Precision} \times \text{Recall}}
{\text{Precision} + \text{Recall}}
\]

- **TP:** query and truth agree after haplotype-aware comparison.
- **FP:** query call is not supported by truth inside benchmark regions.
- **FN:** truth variant was missed by the query callset.

## Minimum report

Record:

- sample and sequencing dataset accession;
- pipeline commit and Nextflow version;
- truth-set release, reference build and checksums;
- capture targets and benchmark-region intersection method;
- SNP and indel TP/FP/FN, precision, recall and F1 separately;
- stratification by relevant genome context where available;
- limitations, excluded regions and failures.

Do not call the result "clinical sensitivity" or "clinical validation". A
single public reference sample measures performance only for the tested data,
regions, resources, pipeline version and conditions.
