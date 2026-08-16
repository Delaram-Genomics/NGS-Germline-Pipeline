# Bounded HG002 offline annotation report

Execution date: 2026-08-16  
Annotation implementation commit: `da40bde5ac3d7f7d2d17259c76495f03d9a37880`  
Platform: Ubuntu on WSL2, x86_64, 7.6 GiB RAM  
Annotation engine: Ensembl VEP 116.1 with cache release 116  
Indexing engine: bcftools 1.24

## Question and scope

This experiment verified that the pipeline could annotate the normalised VCF
from the bounded public HG002 chr20 benchmark with a versioned, offline VEP
cache and produce its transparent research-review table.

The input came from the WGS-derived one-megabase learning benchmark described
in `docs/GIAB_BENCHMARK_REPORT.md`. It is not WES, a patient case, a clinical
validation or a representative genome-wide annotation assessment.

## Method

The pipeline ran VEP offline against the GRCh38 cache and the matching chr20
reference FASTA. It requested one selected transcript consequence per record,
including gene symbol, MANE/canonical status, HGVS, protein consequence,
population frequency, ClinVar significance when present, SIFT and PolyPhen.

The research-review rule is intentionally simple and auditable:

- a technically passing HIGH or MODERATE consequence with `MAX_AF <= 0.01`, or
  no reported population frequency, is labelled `REVIEW`;
- a record with a technical FILTER label is `DO_NOT_PRIORITISE`;
- all other annotated records are `LOWER_PRIORITY`.

This rule is a technical triage aid. It is not ACMG/ACGS classification and
does not use phenotype, inheritance, segregation or case-level evidence.

## Results

- Input and annotated VCF records: 1,807.
- Annotated consequence rows: 1,801.
- Star-only spanning-deletion placeholders (`ALT=*`) without VEP `CSQ`: 6;
  these were excluded from the review table and were not treated as standalone
  alternate alleles.
- `LOWER_PRIORITY`: 1,790.
- `DO_NOT_PRIORITISE`: 11.
- `REVIEW`: 0.

### Impact distribution

| Impact | Rows |
| --- | ---: |
| MODIFIER | 1,794 |
| LOW | 6 |
| MODERATE | 1 |
| HIGH | 0 |

The most common selected consequences were intronic/non-coding transcript
(762), intronic (580), downstream-gene (160), intergenic (141), upstream-gene
(112) and non-coding transcript exon (19). There were four synonymous variants
and one missense variant.

The single MODERATE record was a PASS missense variant in `SLX4IP`
(`chr20:10623102 G>A`). Its VEP `MAX_AF` was 0.1634 and no `CLIN_SIG` value was
reported, so the documented frequency rule correctly assigned
`LOWER_PRIORITY`. This is a workflow behaviour check, not an interpretation of
the variant's clinical significance.

## Reproducibility checksums

| Artifact | SHA-256 |
| --- | --- |
| Input normalised query VCF | `60b36b529fd439c9c40118d78e5c24b10f883d27d2c4da009aae84d41ed98179` |
| Annotated VCF | `6b89602d75f9b8d7af9ca844dc55490be47b1d39e47bbd3f10323df18323240a` |
| Annotated VCF tabix index | `0ff1d3d1e5ea3e74f17b19ef81aaf6011bdca4e064770e59b2fe9e1b617b0770` |
| Research-review TSV | `ce20dc4bfda96fda7dd6096ac6a4adbd791ec02d6825e50dff1e625d077fc4f2` |
| Annotation provenance TSV | `c342332467f785348781a700ef9cc0fada8fc59896ae11b076461d7723de475a` |
| chr20 reference FASTA | `61eba5b05ef7d9ae5310e756c1143fa48072de3856d36871bb14e57aa2435ff3` |

Generated VCF, index and TSV files remain outside Git. Only aggregate results,
versioned provenance and checksums are recorded here.

## Integration findings

The first real offline annotation run exposed and resolved three compatibility
issues:

1. VEP 116 uses `--clin_sig_allele 1`; `CLIN_SIG` is an output field, not the
   unsupported `--clin_sig` command-line option.
2. The isolated annotation environment must explicitly pin bcftools 1.24;
   otherwise a dependency supplied an incompatible executable with the same
   name.
3. Star-only spanning-deletion records may legitimately lack `CSQ`. The parser
   now skips only `*`/`.`-only records while still failing if a real alternate
   allele lacks annotation.

Regression tests cover all three behaviours, and the full 39-test suite passed
before the compatibility fix was merged.

## Limitations

- The source is a bounded, WGS-derived public HG002 subset, not original WES
  instrument FASTQ and not a clinical specimen.
- Only one megabase of chr20 and one public reference individual were tested.
- The `--pick` strategy reports a selected consequence and can hide relevant
  alternative transcript consequences.
- Cache-derived population and ClinVar fields depend on release 116 content;
  absence of a value is not evidence of benignity.
- The research rule does not assess phenotype fit, inheritance, segregation,
  penetrance, mechanism, literature or functional evidence.
- No ACMG/ACGS classification, diagnostic interpretation, clinical report or
  clinical performance claim is made.
- Independent reproduction and evaluation on additional public samples and
  clinically representative WES designs remain required.
