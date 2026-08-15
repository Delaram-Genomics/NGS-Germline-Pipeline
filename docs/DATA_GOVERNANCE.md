# Data governance

## Public repository rule

Only public, broadly consented or synthetic genomic data may be used in this
portfolio. Patient FASTQ, BAM, CRAM, VCF, phenotypes, identifiers and derived
reports must not be copied into the repository, uploaded to public services or
included in screenshots.

Pseudonymisation is not anonymisation. A numeric filename does not make a human
genome safe to publish, and genomic sequence may remain identifying when direct
identifiers have been removed.

## Approved portfolio data

The validation case study will use NIST Genome in a Bottle (GIAB) reference
data, prioritising HG002 because public benchmark calls and high-confidence
regions support objective precision/recall measurement.

Every dataset must have a recorded source URL, accession, assembly, consent/use
status and checksum before analysis.

## Data received from a laboratory

Laboratory or patient data remain out of scope unless all of the following are
documented by the responsible organisation:

- authority to transfer and process the data in the intended environment;
- compatible patient consent or another lawful basis;
- research/ethics and information-governance approvals where required;
- permitted outputs, retention period and deletion process;
- an approved secure compute and storage location;
- a named data controller/owner and escalation contact.

Possessing a copy of a file is not evidence of permission. Portfolio work must
never depend on access to confidential patient material.

## Repository safeguards

- Genomic file extensions and local configuration are ignored by Git.
- Example sample names use public reference identifiers.
- Tests generate tiny synthetic reads in temporary directories.
- Documentation reports aggregate, non-sensitive benchmark metrics only.
- Before every commit, `git status` and the staged diff are reviewed.

## Incident response

If patient data or an identifiable derivative is accidentally staged, uploaded
or shared, stop work immediately, do not copy it further, and follow the source
organisation's incident-reporting and information-governance process. Removing
a file in a later commit is not sufficient because Git history retains it.
