# Bounded GIAB HG002 benchmark report

Execution date: 2026-08-16  
Pipeline commit: `2adab60e47db39b3422a5f58260a33e7fd944a3d`  
Platform: Ubuntu on WSL2, x86_64, 7.6 GiB RAM  
Benchmark engine: hap.py 0.3.15 (`xcmp`)  
Truth set: NIST GIAB HG002 v4.2.1, GRCh38

## Question and scope

This experiment measured agreement between this pipeline's germline SNV/indel
calls and the NIST GIAB HG002 v4.2.1 truth set in a bounded region of chr20.
The evaluated interval was `chr20:10,000,000-11,000,000`; its intersection
with GIAB high-confidence regions contained 129 intervals covering 977,840 bp.

The source was public Illumina NovaSeq PCR-free 35x WGS-derived HG002 data made
available for the Google DeepVariant case study. It was not a WES experiment.
Reads overlapping the bounded region and their mates were converted from the
public chr20 BAM back to paired FASTQ before this pipeline realigned them.

## Inputs and preparation

- Reference: `GCA_000001405.15_GRCh38_no_alt_analysis_set`, chr20 sequence.
- Truth VCF: `HG002_GRCh38_1_22_v4.2.1_benchmark.vcf.gz`.
- Confident regions: GIAB v4.2.1 benchmark regions intersected with the bounded
  chr20 interval.
- Paired FASTQ: 130,069 read pairs.
- Excluded singletons retained separately: 1,348 reads.
- BAM, truth and reference all declared chr20 length 64,444,167 bp. The public
  BAM header did not include an `M5` tag, so reference compatibility was also
  assessed from the official source metadata and matching assembly/contig
  declarations rather than a BAM-header MD5 comparison.

The Nextflow workflow completed raw-read QC, preprocessing, BWA-MEM alignment,
BAM processing and GATK germline short-variant calling in 2 minutes 21 seconds.
Annotation was outside this benchmark.

## hap.py results

The PASS metrics are the primary reported results.

| Type | Filter | Truth total | TP | FN | Query FP | Query unknown | Recall | Precision | F1 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| SNP | PASS | 1,354 | 1,351 | 3 | 1 | 68 | 0.997784 | 0.999260 | 0.998522 |
| INDEL | PASS | 234 | 232 | 2 | 1 | 107 | 0.991453 | 0.995708 | 0.993576 |
| SNP | ALL | 1,354 | 1,353 | 1 | 3 | 75 | 0.999261 | 0.997788 | 0.998524 |
| INDEL | ALL | 234 | 232 | 2 | 1 | 107 | 0.991453 | 0.995708 | 0.993576 |

`QUERY.UNK` records are outside the confident comparison space and are not
false positives. The corresponding fractions were 0.047887 for PASS SNPs and
0.314706 for PASS indels; the small bounded region makes these fractions and
all reported metrics sensitive to the selected interval.

## Reproducibility checksums

| Role | SHA-256 |
| --- | --- |
| Truth VCF | `adb4d4a50048aa13353a06b84fcfcbca09a5d17525efaa4cea44f8822e81175c` |
| Query VCF | `60b36b529fd439c9c40118d78e5c24b10f883d27d2c4da009aae84d41ed98179` |
| Confident-region BED | `f004d7c702caba2a44b74d7776bfc2dbead870ab040cd61492c1695c9065a081` |
| chr20 reference FASTA | `61eba5b05ef7d9ae5310e756c1143fa48072de3856d36871bb14e57aa2435ff3` |
| R1 FASTQ | `914bd41eb9b437919ad25453f782b032caae4253a83335ab033ec21de92aa791` |
| R2 FASTQ | `f2cf2e1e008936e7f34ddada932b6ce4137f91926b29c36caaf32e36e12e318b` |
| Singleton FASTQ | `efdc182e7fc205f5cef2cd3700b60d90944ccda2f4f314806ad61ff9be2407c8` |

Large inputs and generated results are intentionally excluded from Git. The
benchmark wrapper generated a local checksum manifest alongside its outputs.

## Warnings and limitations

- NIST now identifies a newer HG002 v5.0q benchmark; v4.2.1 was selected for
  compatibility with the established GRCh38 short-read case-study resources
  and is explicitly versioned here.
- This one-megabase WGS-derived subset is a learning benchmark, not a complete
  WGS or WES performance assessment.
- FASTQ was regenerated from a public, aligned and duplicate-marked chr20 BAM;
  it is not the original instrument FASTQ. Alignment and duplicate information
  was recomputed by this pipeline.
- The public BAM lacked an `M5` reference checksum in its header.
- hap.py warned about overlapping truth records outside the evaluated chr20
  region and emitted non-fatal `IMPORT_FAIL` header-definition warnings.
- No confidence intervals or stratification by difficult genomic context were
  calculated for this small region.
- Results apply only to these versions, inputs, region and parameters. They are
  not clinical sensitivity, clinical specificity or clinical validation.
- Offline VEP annotation was subsequently completed and is reported separately
  in `docs/HG002_ANNOTATION_REPORT.md`. A related second sample, HG003, was also
  benchmarked in `docs/GIAB_HG003_BENCHMARK_REPORT.md`; an unrelated sample and
  independent reproduction remain pending.
