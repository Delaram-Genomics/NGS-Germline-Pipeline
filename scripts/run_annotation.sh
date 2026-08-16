#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/run_annotation.sh --samplesheet FILE --reference FASTA \
    --vep-cache-dir DIR --vep-cache-version N [options]

Required:
  --samplesheet FILE       CSV containing sample IDs.
  --reference FASTA        GRCh38 reference matching the called VCF.
  --vep-cache-dir DIR      Local Ensembl VEP cache directory.
  --vep-cache-version N    Explicit Ensembl cache release, for example 113.

Options:
  --vcf-dir DIR            Input normalised VCF directory
                           (default: results/variants/filtered).
  --outdir DIR             Output directory (default: results/annotation).
  --forks N                VEP worker processes (default: 4).
  --dry-run                Validate paths and print commands only.
  -h, --help               Show this help message.

The prioritisation table is a research triage aid. It does not perform ACMG/
ACGS classification, diagnosis or clinical reporting.
EOF
}

SAMPLESHEET=""
REFERENCE=""
VEP_CACHE_DIR=""
VEP_CACHE_VERSION=""
VCF_DIR="results/variants/filtered"
OUTDIR="results/annotation"
FORKS=4
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --samplesheet)
            [[ $# -ge 2 ]] || die "--samplesheet requires a value"
            SAMPLESHEET="$2"
            shift 2
            ;;
        --reference)
            [[ $# -ge 2 ]] || die "--reference requires a value"
            REFERENCE="$2"
            shift 2
            ;;
        --vep-cache-dir)
            [[ $# -ge 2 ]] || die "--vep-cache-dir requires a value"
            VEP_CACHE_DIR="$2"
            shift 2
            ;;
        --vep-cache-version)
            [[ $# -ge 2 ]] || die "--vep-cache-version requires a value"
            VEP_CACHE_VERSION="$2"
            shift 2
            ;;
        --vcf-dir)
            [[ $# -ge 2 ]] || die "--vcf-dir requires a value"
            VCF_DIR="$2"
            shift 2
            ;;
        --outdir)
            [[ $# -ge 2 ]] || die "--outdir requires a value"
            OUTDIR="$2"
            shift 2
            ;;
        --forks)
            [[ $# -ge 2 ]] || die "--forks requires a value"
            FORKS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[[ -n "${SAMPLESHEET}" ]] || die "--samplesheet is required"
[[ -n "${REFERENCE}" ]] || die "--reference is required"
[[ -n "${VEP_CACHE_DIR}" ]] || die "--vep-cache-dir is required"
[[ -n "${VEP_CACHE_VERSION}" ]] || die "--vep-cache-version is required"
[[ "${VEP_CACHE_VERSION}" =~ ^[0-9]+$ ]] || die "--vep-cache-version must be an integer"
[[ "${FORKS}" =~ ^[1-9][0-9]*$ ]] || die "--forks must be a positive integer"
[[ -s "${REFERENCE}" ]] || die "Reference FASTA missing or empty: ${REFERENCE}"
[[ -d "${VEP_CACHE_DIR}" ]] || die "VEP cache directory does not exist: ${VEP_CACHE_DIR}"

require_command python3
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --skip-file-checks

if [[ "${DRY_RUN}" != "true" ]]; then
    require_command vep
    require_command bcftools
fi

VCF_OUT_DIR="${OUTDIR}/vcf"
TABLE_DIR="${OUTDIR}/tables"
STATS_DIR="${OUTDIR}/stats"
LOG_DIR="${OUTDIR}/logs"
mkdir -p "${VCF_OUT_DIR}" "${TABLE_DIR}" "${STATS_DIR}" "${LOG_DIR}"

SAMPLE_ROWS_FILE="$(mktemp "${OUTDIR}/.sample_rows.XXXXXX")"
trap 'rm -f -- "${SAMPLE_ROWS_FILE}"' EXIT
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --skip-file-checks \
    --emit-tsv > "${SAMPLE_ROWS_FILE}"
mapfile -t SAMPLE_ROWS < "${SAMPLE_ROWS_FILE}"

log "Starting offline VEP annotation for ${#SAMPLE_ROWS[@]} sample(s)."

for row in "${SAMPLE_ROWS[@]}"; do
    IFS=$'\t' read -r sample_id _ _ <<< "${row}"
    input_vcf="${VCF_DIR}/${sample_id}.filtered.normalised.vcf.gz"
    annotated_vcf="${VCF_OUT_DIR}/${sample_id}.vep.vcf.gz"
    stats_html="${STATS_DIR}/${sample_id}.vep.summary.html"
    review_tsv="${TABLE_DIR}/${sample_id}.research_review.tsv"

    [[ -s "${input_vcf}" ]] || die "Normalised input VCF missing or empty for ${sample_id}: ${input_vcf}"

    log "${sample_id}: Ensembl VEP annotation"
    run_command vep \
        --input_file "${input_vcf}" \
        --output_file "${annotated_vcf}" \
        --format vcf \
        --vcf \
        --compress_output bgzip \
        --cache \
        --offline \
        --dir_cache "${VEP_CACHE_DIR}" \
        --cache_version "${VEP_CACHE_VERSION}" \
        --assembly GRCh38 \
        --fasta "${REFERENCE}" \
        --fork "${FORKS}" \
        --force_overwrite \
        --symbol \
        --canonical \
        --mane \
        --biotype \
        --hgvs \
        --protein \
        --numbers \
        --variant_class \
        --af \
        --af_gnomade \
        --af_gnomadg \
        --max_af \
        --clin_sig_allele 1 \
        --sift b \
        --polyphen b \
        --pick \
        --pick_order mane_select,canonical,appris,tsl,biotype,ccds,rank,length \
        --stats_file "${stats_html}"

    run_command bcftools index --tbi "${annotated_vcf}"

    log "${sample_id}: transparent research-review table"
    run_command python3 "${SCRIPT_DIR}/prioritise_variants.py" \
        --input-vcf "${annotated_vcf}" \
        --output-tsv "${review_tsv}"
done

if [[ "${DRY_RUN}" != "true" ]]; then
    {
        printf 'run_utc\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'vep\t%s\n' "$(vep --help 2>&1 | grep 'ensembl-vep' | head -n 1 | xargs)"
        printf 'vep_cache_version\t%s\n' "${VEP_CACHE_VERSION}"
        printf 'vep_cache_dir\t%s\n' "$(realpath "${VEP_CACHE_DIR}")"
        printf 'reference\t%s\n' "$(realpath "${REFERENCE}")"
        printf 'reference_sha256\t%s\n' "$(sha256sum "${REFERENCE}" | cut -d ' ' -f 1)"
    } > "${LOG_DIR}/annotation_provenance.tsv"
fi

log "Annotation completed. Review tables as research triage, not clinical classification."
