# Germline SNV and indel calling

## Scope

This stage demonstrates germline short-variant discovery for one unrelated WES
sample at a time. It produces an individual gVCF, genotypes that gVCF, applies
transparent SNP/indel hard filters and normalises the resulting representation.

It does not perform clinical classification or claim that every clinically
relevant variant can be detected.

## Workflow

```text
mark-duplicate BAM
  -> HaplotypeCaller -ERC GVCF
  -> GenotypeGVCFs
  -> split SNPs and indels
  -> type-specific hard filters
  -> merge
  -> bcftools norm
  -> bcftools stats
```

## Run the stage

```bash
scripts/run_variant_calling.sh \
  --samplesheet samplesheet.csv \
  --reference /path/to/GRCh38.fa \
  --intervals /path/to/exome_targets.interval_list \
  --bam-dir results/alignment/bam \
  --outdir results/variants \
  --threads 4 \
  --memory-gb 8
```

Add `--dry-run` to validate paths and inspect commands first.

## Why gVCF mode?

Reference-confidence mode records evidence at variant and non-variant sites in
a form designed for later genotyping. The current milestone genotypes each
sample independently for demonstration. A future cohort workflow can combine
gVCFs before joint genotyping without repeating read-level calling.

## Hard filters

The workflow labels records that meet these expressions; it does not delete
them.

| Type | Filter expressions |
| --- | --- |
| SNP | `QD < 2.0`, `QUAL < 30`, `SOR > 3.0`, `FS > 60`, `MQ < 40`, `MQRankSum < -12.5`, `ReadPosRankSum < -8.0` |
| Indel | `QD < 2.0`, `QUAL < 30`, `FS > 200`, `ReadPosRankSum < -20.0` |

These are documented demonstration defaults based on GATK hard-filtering
guidance. They are not universal clinical thresholds. Benchmark results must
show their effect, and assay-specific validation may require different models
or thresholds.

## Fields to understand

| Field | Meaning | Review question |
| --- | --- | --- |
| `GT` | Genotype | Is the call heterozygous, homozygous alternate or missing? |
| `DP` | Sample depth | Is depth sufficient and plausible at this locus? |
| `AD` | Reference/alternate read depths | Is allelic balance plausible? |
| `GQ` | Genotype quality | How strongly does the evidence support the genotype? |
| `QUAL` | Site-level confidence | Is site evidence strong, independent of one sample? |
| `FILTER` | Technical filter labels | Which rule was triggered, and why? |

No single field should be interpreted without local coverage, read evidence,
mapping context and the limitations of the assay.

## Outputs

```text
results/variants/
├── gvcf/<sample>.g.vcf.gz
├── raw/<sample>.raw.vcf.gz
├── filtered/<sample>.snps.filtered.vcf.gz
├── filtered/<sample>.indels.filtered.vcf.gz
├── filtered/<sample>.filtered.normalised.vcf.gz
├── metrics/<sample>.bcftools.stats.txt
└── logs/variant_calling_provenance.tsv
```

## Current limitations

- Base quality score recalibration is not yet implemented.
- Version 1 does not perform cohort joint genotyping or VQSR.
- CNVs, structural variants, repeat expansions and mitochondrial variants are
  out of scope.
- Target intervals and reference files must use compatible GRCh38 contigs.
- Benchmarking against GIAB truth calls is required before performance claims.
