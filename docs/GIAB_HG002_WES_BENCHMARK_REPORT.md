# GIAB HG002 Agilent V6 WES benchmark

Execution date: 2026-08-19
Pipeline commit at execution: `2a7ad44`
Platform: Ubuntu on WSL2, x86_64, 16 logical CPUs, 7.6 GiB RAM
Workflow: Nextflow 26.04.6
Benchmark: hap.py 0.3.15, `xcmp` engine
Truth: NIST GIAB HG002 v4.2.1, GRCh38

## Scope

This experiment evaluated an end-to-end paired-end germline WES execution
against the NIST GIAB HG002 v4.2.1 small-variant benchmark.

The public input was an HG002 Novogene WES replicate generated with the
Agilent SureSelect Human All Exon V6 design. The GRCh38 target file contained
221,602 valid intervals covering 38,227,700 bp.

The benchmark retained the full GIAB confident-region BED and supplied the
Agilent V6 targets to hap.py as a named stratification. The confident capture
stratum covered 35,059,744 bp after hap.py adjusted confidence-region
boundaries for insertion representation.

## Workflow

The completed Nextflow processes were:

1. raw and trimmed-read QC with FastQC, fastp and MultiQC;
2. BWA-MEM alignment, mate-tag calculation, coordinate sorting, duplicate
   marking, BAM validation and indexing with samtools;
3. GATK HaplotypeCaller in GVCF mode, GenotypeGVCFs, separate SNP/indel hard
   filters, merging and bcftools normalisation.

All three processes completed with exit status zero. Annotation was excluded.

## Alignment and capture metrics

| Metric | Result |
| --- | ---: |
| Primary reads mapped | 99.95% |
| Properly paired reads | 99.59% |
| Primary duplicate rate | 16.95% |
| Mean insert size | 228.5 bp |
| Alignment mismatch rate | 0.40% |
| Usable on-target alignments | 72.82% |
| Mean target depth at baseQ/mapQ >= 20 | 180.42x |
| Target bases at >= 10x | 97.02% |
| Target bases at >= 20x | 95.42% |
| Target bases at >= 30x | 93.36% |

The on-target rate uses primary, mapped, QC-passing, non-duplicate alignments.
Coverage requires both base quality and mapping quality of at least 20.

## hap.py PASS results

Only the `AgilentV6` stratification is reported. Whole-genome recall is not
meaningful for a target-restricted WES callset.

| Type | Truth | TP | FN | Query | FP | UNK | Recall | Precision | F1 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| SNP | 24,731 | 23,606 | 1,125 | 26,416 | 349 | 2,464 | 0.954511 | 0.985429 | 0.969723 |
| INDEL | 802 | 716 | 86 | 1,293 | 104 | 471 | 0.892768 | 0.873479 | 0.883018 |

`QUERY.UNK` records lie outside the confident comparison space and are not
counted as false positives.

## Reproducibility

Small summary tables are version controlled under
`benchmarks/HG002_AgilentV6/`. Large genomic inputs and outputs remain outside
Git.

| Artifact | SHA-256 |
| --- | --- |
| Normalised query VCF | `f578668e31ddb872faaa4e3bae7702d4c5efb3ce206485d274622b39c74dc43d` |
| GIAB truth VCF | `adb4d4a50048aa13353a06b84fcfcbca09a5d17525efaa4cea44f8822e81175c` |
| GIAB confident BED | `fba9a57c36ec88e5d14ea3e259c8866c7935f4998d3ec0fa2d6c3962da5b5575` |
| Agilent V6 target BED | `1a7ff7882c80531219399dbb45a5c346252a7a6253e283a307b2cb488080bbf1` |
| GRCh38 reference | `9cce8b926416dd96b152deea85188495b75f7ac8d634cc723a017067be8702b7` |
| PASS benchmark table | `bf6f8507ded08d8c8d74ba74f25f55984dafd0c4d083ff65a5c6e9e957181c89` |
| Q20 coverage table | `d6cffbf24ec6a3db746eb503b0a761842d70eb23b8d960eefb9bd8c747b7ab07` |
| On-target table | `32e5a82f1259e783c14f29940877bb7d567c5288614a557aa30a421c94b64512` |

## Limitations

- This is one public reference sample and one capture design.
- Results are specific to the recorded inputs, resources and parameters.
- This BWA-MEM/GATK workflow is not an Illumina DRAGEN workflow.
- Base-quality score recalibration and VQSR were not performed.
- Confidence intervals and difficult-region stratifications were not computed.
- CNVs, structural variants, repeat expansions and mitochondrial variants were
  outside scope.
- These are research benchmarking results, not clinical validation or
  regulatory approval.
