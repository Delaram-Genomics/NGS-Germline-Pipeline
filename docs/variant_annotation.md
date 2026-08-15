# Variant annotation and research triage

## Purpose

Annotation adds transcript, consequence, population-frequency and database
context to technically called variants. It does not classify pathogenicity.
The same variant may have different consequences across transcripts, and
external database assertions may conflict or change between releases.

## VEP configuration

The pipeline runs Ensembl VEP offline against an explicitly selected cache
release and the same GRCh38 FASTA used for calling. It records:

- gene symbol and stable gene/transcript identifiers;
- MANE Select and canonical transcript indicators;
- Sequence Ontology consequence and impact category;
- HGVS coding and protein descriptions;
- population allele frequencies where available in the cache;
- ClinVar significance strings as evidence requiring review;
- SIFT and PolyPhen predictions.

`--pick` selects one documented representative consequence per allele using a
fixed ordering that prioritises MANE Select and canonical transcripts. This is
useful for a compact portfolio table but can hide alternative transcript
effects; the annotated VCF remains the source record.

## Run the stage

```bash
scripts/run_annotation.sh \
  --samplesheet samplesheet.csv \
  --reference /path/to/GRCh38.fa \
  --vep-cache-dir /path/to/vep_cache \
  --vep-cache-version 113 \
  --vcf-dir results/variants/filtered \
  --outdir results/annotation \
  --forks 4
```

Use the cache version actually installed on the analysis system; `113` is only
an example. Run with `--dry-run` first to inspect the complete command.

## Research-review rule

The generated TSV uses a deliberately simple and visible rule:

- `DO_NOT_PRIORITISE`: the VCF record has a technical filter label;
- `REVIEW`: the record is `PASS`, VEP impact is HIGH or MODERATE, and `MAX_AF`
  is missing or no greater than 1%;
- `LOWER_PRIORITY`: the record does not meet that technical rule.

This rule is a queueing aid only. It is not an ACMG/ACGS criterion set and must
not be described as classification. Frequency, predicted impact and a ClinVar
label are not sufficient to determine pathogenicity.

## Manual review questions

For any row marked `REVIEW`, ask:

1. Is coverage and allelic balance adequate in the BAM?
2. Is the locus difficult to map or sequence?
3. Is the transcript relevant and correctly represented?
4. Is the population frequency compatible with the disease model?
5. Does phenotype and inheritance information support relevance?
6. What is the underlying evidence behind ClinVar submissions?
7. Is orthogonal confirmation or expert escalation required?

For public GIAB benchmarking, phenotype-based interpretation is not performed.
The case study focuses on technical accuracy and reproducibility.

## Outputs

```text
results/annotation/
├── vcf/<sample>.vep.vcf.gz
├── vcf/<sample>.vep.vcf.gz.tbi
├── tables/<sample>.research_review.tsv
├── stats/<sample>.vep.summary.html
└── logs/annotation_provenance.tsv
```

## Limitations

- Cache contents and ClinVar assertions change over time.
- `--pick` is a presentation choice, not proof of the clinically relevant
  transcript.
- In silico predictors are supporting evidence, not standalone conclusions.
- The table does not encode phenotype, segregation, de novo status or disease
  mechanism.
- No row may be reported clinically from this portfolio pipeline.
