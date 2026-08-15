# Quality model and limitations

## Intended use

This project is an educational and portfolio implementation of a germline
short-variant workflow. It is intended to demonstrate reproducible analysis,
quality-control reasoning and safe documentation practices using non-sensitive
test data.

It must not be used to make a diagnosis, issue a patient report, or replace an
accredited laboratory process.

## Quality principles

The project adopts engineering practices that are relevant to regulated
laboratories without claiming accreditation:

1. **Defined scope** - assay type, reference build and variant classes are
   stated explicitly.
2. **Input control** - metadata, pairing, filenames and file integrity are
   validated before analysis.
3. **Traceability** - software, parameters, reference resources and commands
   will be recorded with each run.
4. **QC evidence** - raw-read, alignment, contamination and variant metrics
   will be retained and reviewed against documented thresholds.
5. **Change control** - work is developed through branches, tests and reviewed
   pull requests.
6. **Data protection** - no patient data, identifiers or sensitive paths are
   committed to the public repository.
7. **Human review** - technical annotation and prioritisation remain separate
   from expert variant classification and clinical reporting.

## Validation ladder

| Level | Evidence | Status |
| --- | --- | --- |
| 1. Static | Syntax checks, configuration validation, unit tests | Implemented for input, QC and alignment stages |
| 2. Functional | End-to-end run on a small public test dataset | Planned |
| 3. Accuracy | Comparison with a GIAB truth set using hap.py | Planned |
| 4. Reproducibility | Repeated run with pinned environments and checksums | Planned |
| 5. Operational | Failure tests, resource profiling and documented recovery | Planned |
| 6. Clinical | Formal verification/validation in an accredited QMS | Out of scope |

## Known limitations

- The initial version supports one unrelated paired-end WES sample per row.
- The initial caller targets SNVs and small indels only.
- GRCh38 resource compatibility must be checked; files from different genome
  builds or contig naming conventions must not be mixed.
- Hard-filter values cannot be treated as universal clinical thresholds.
- Variant annotation changes as external databases and transcripts change.
- Absence of a called variant is not evidence that a clinically relevant
  variant is absent; coverage, difficult regions and unsupported variant
  classes must be considered.
