# Bounded GIAB HG003 benchmark report

Execution date: 2026-08-16  
Pipeline commit: `d7d50fbd6b186b98316e699f68eba3462e3692bb`  
Platform: Ubuntu on WSL2, x86_64, 7.6 GiB RAM  
Benchmark engine: hap.py 0.3.15 (`xcmp`)  
Truth set: NIST GIAB HG003 v4.2.1, GRCh38

## Question and scope

This experiment tested whether the bounded HG002 result generalised to a
second public GIAB individual. HG003 (NA24149) is the father of HG002, so this
is a distinct reference sample but not an unrelated replication cohort.

The source was public Illumina NovaSeq PCR-free 35x WGS-derived chr20 data from
the DeepVariant/precisionFDA case-study resources. It was not WES. The
evaluated interval was `chr20:10,000,000-11,000,000`; its intersection with the
HG003 high-confidence BED contained 140 intervals covering 975,011 bp.

## Inputs and preparation

- Reference: `GCA_000001405.15_GRCh38_no_alt_analysis_set`, chr20 sequence.
- Truth VCF: HG003 GIAB v4.2.1 GRCh38 small-variant benchmark.
- Reads in the source BAM test interval: 271,361.
- Paired FASTQ regenerated with mates: 134,846 read pairs.
- Excluded singletons retained separately: 1,420 reads.
- BAM, truth and reference declared chr20 length 64,444,167 bp.
- Truth records in the intersected confident region: 1,694.

The Nextflow workflow completed raw-read QC, preprocessing, BWA-MEM alignment,
BAM processing and GATK germline short-variant calling in 2 minutes 38 seconds.
The normalised query contained 1,964 records: 1,544 SNPs and 413 indels. Within
the confident region, 1,713 records were PASS and three carried `SNP_SOR3`.

## hap.py results

PASS metrics are the primary reported results.

| Type | Filter | Truth total | TP | FN | Query FP | Query unknown | Recall | Precision | F1 |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| SNP | PASS | 1,442 | 1,439 | 3 | 0 | 99 | 0.997920 | 1.000000 | 0.998959 |
| INDEL | PASS | 252 | 252 | 0 | 0 | 124 | 1.000000 | 1.000000 | 1.000000 |
| SNP | ALL | 1,442 | 1,442 | 0 | 0 | 102 | 1.000000 | 1.000000 | 1.000000 |
| INDEL | ALL | 252 | 252 | 0 | 0 | 124 | 1.000000 | 1.000000 | 1.000000 |

`QUERY.UNK` records are outside the confident comparison space and are not
false positives. Their fractions were 0.064369 for PASS SNPs and 0.329787 for
PASS indels. The small bounded region makes all metrics sensitive to interval
selection and does not support a claim of perfect genome-wide performance.

## Bounded comparison with HG002

| Sample | Type | PASS recall | PASS precision | PASS F1 |
| --- | --- | ---: | ---: | ---: |
| HG002 | SNP | 0.997784 | 0.999260 | 0.998522 |
| HG003 | SNP | 0.997920 | 1.000000 | 0.998959 |
| HG002 | INDEL | 0.991453 | 0.995708 | 0.993576 |
| HG003 | INDEL | 1.000000 | 1.000000 | 1.000000 |

The two runs used the same one-megabase interval, reference, reconstruction
method and pipeline settings, but sample-specific confident regions differed
slightly. The comparison demonstrates repeatable execution; it is not a
population study or evidence that HG003 is intrinsically easier.

## Reproducibility checksums

| Role | SHA-256 |
| --- | --- |
| Truth VCF | `a4f8fefa826f8d2c9457eacf6f4b2f6bfa29daef429d570ce04254c5e7b1121e` |
| Query VCF | `b3c64ce71ec0d4c893528de00eb7207ebe5310ab775a506d25aa6dfb65d6c294` |
| Confident-region BED | `aad2156492783ef657b24dd43e8a10cd487ad737b050aa0c515b89153b978feb` |
| chr20 reference FASTA | `61eba5b05ef7d9ae5310e756c1143fa48072de3856d36871bb14e57aa2435ff3` |
| R1 FASTQ | `f868c11e53d5a33ae0944ec14fe85ea588f2d5d93a1ef42a2a8a4a5bd87ffb8e` |
| R2 FASTQ | `42ce73b454639c04f06d7aa93bb779de111b61d0202697879ae0959da208daa8` |
| Singleton FASTQ | `d6d89854867c9dbe01440b704b012b6c92b764e3bd16c3520246340736bed00d` |
| hap.py summary CSV | `c2feddcd7994e6efb3387631a553bfc68e66b5e79e9eb1f14a5935e7be909971` |

Large public inputs and generated outputs remain outside Git. hap.py recorded a
local input-checksum manifest alongside its results.

## Warnings and limitations

- This is a one-megabase WGS-derived learning benchmark, not a complete WGS or
  WES performance assessment.
- FASTQ was regenerated from a public aligned and duplicate-marked BAM; it was
  not original instrument FASTQ.
- HG003 is related to HG002 and is not an unrelated external replication.
- The HG002 and HG003 confident-region masks covered slightly different bases.
- hap.py warned about overlapping truth records on chr6 outside the evaluated
  region and emitted non-fatal `IMPORT_FAIL` header-definition warnings.
- No confidence intervals or difficult-region stratification were calculated.
- Results apply only to these inputs, versions, interval and parameters. They
  are not clinical sensitivity, specificity, validation or production claims.
- An actual WES capture dataset, an unrelated public sample and independent
  reproduction remain necessary next steps.
