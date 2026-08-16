# Synthetic smoke-test report

Execution date: 2026-08-16  
Tested commit: `bc7723f79d247ed08f0fc8a1cb3beecbfd71e549`  
Platform: Ubuntu on WSL2, x86_64, 7.6 GiB RAM  
Data classification: deterministic synthetic, non-human fixture

## Purpose

This test asked whether the implemented workflow could execute through read
quality control, preprocessing, alignment, BAM processing and germline
short-variant calling on a low-memory workstation. It was a functional wiring
test, not an analytical-accuracy or clinical-validation study.

## Recorded software

| Component | Version |
| --- | --- |
| Python | 3.12.13 |
| Nextflow | 26.04.6 |
| FastQC | 0.12.1 |
| fastp | 1.3.6 |
| MultiQC | 1.35 |
| BWA | 0.7.19-r1273 |
| samtools | 1.24 |
| bcftools | 1.24 |
| GATK | 4.6.2.0 |

## Execution

The fixture was generated and indexed with:

```bash
scripts/prepare_smoke_test.sh --outdir test_data/smoke
```

The real workflow, without annotation, was executed with:

```bash
nextflow run main.nf \
  -profile test \
  --samplesheet test_data/smoke/samplesheet.csv \
  --reference test_data/smoke/synthetic.fa \
  --intervals test_data/smoke/targets.bed \
  --skip_annotation true \
  --outdir test_results \
  -resume
```

All three scheduled processes completed successfully:

- `RAW_READ_QC`
- `ALIGNMENT_AND_BAM_QC`
- `GERMLINE_SHORT_VARIANTS`

## Functional observation

The fixture generator introduced one heterozygous SNV. The expected and called
records agreed exactly:

| Contig | Position | REF | ALT | Genotype | FILTER |
| --- | ---: | --- | --- | --- | --- |
| `synthetic_chr` | 401 | C | A | `0/1` | `PASS` |

`bcftools stats` reported one sample, one record, one SNP, no indels and no
multiallelic sites.

## SHA-256 evidence

| File | SHA-256 |
| --- | --- |
| `synthetic.fa` | `c745fd30c915f2977e7263788d388cf19e54566529af9f52674570443fa0907c` |
| `SYNTH001_R1.fastq.gz` | `10439ba52f95e5b35d76d55bfb3aa31978716e12ba4362545d000702f9b716af` |
| `SYNTH001_R2.fastq.gz` | `c54065d629f6ec3238b8db04190bfb7bc756eb204054a7c2a8d6e9957cb47068` |
| `expected_variant.txt` | `8003bed9b75b926ecf4dcbcbe01fd0874051696040662befa96db3e4ca11b8d1` |
| `SYNTH001.filtered.normalised.vcf.gz` | `3c0b718422e28f5bcab0f62fc9ffef45f807f9f16c6bb0953b13fbe2088b7860` |

## Interpretation and limitations

This result demonstrates successful workflow connectivity and recovery of the
single deliberately introduced variant in this tiny deterministic fixture. It
does not estimate sensitivity, specificity, precision, recall, false-positive
rate or performance on human WES data. VEP annotation was intentionally
skipped because the synthetic contig has no Ensembl annotation. Public GIAB
HG002 benchmarking remains required before any analytical-performance claim.

