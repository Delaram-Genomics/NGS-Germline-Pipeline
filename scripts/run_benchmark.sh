#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/run_benchmark.sh --truth VCF.GZ --query VCF.GZ \
    --confident-regions BED --reference FASTA --output-prefix PREFIX [options]

Required:
  --truth VCF.GZ          GIAB truth calls matching sample and assembly.
  --query VCF.GZ          Pipeline callset for the same sample.
  --confident-regions BED GIAB benchmark regions matching the truth release.
  --reference FASTA       Exact reference compatible with both callsets.
  --output-prefix PREFIX  Prefix for hap.py outputs.

Options:
  --threads N             Worker threads (default: 4).
  --engine NAME           hap.py engine (default: xcmp).
  --dry-run               Validate inputs and print commands only.
  -h, --help              Show help.
EOF
}

TRUTH=""
QUERY=""
CONFIDENT_REGIONS=""
REFERENCE=""
OUTPUT_PREFIX=""
THREADS=4
ENGINE="xcmp"
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --truth) TRUTH="${2:-}"; shift 2 ;;
        --query) QUERY="${2:-}"; shift 2 ;;
        --confident-regions) CONFIDENT_REGIONS="${2:-}"; shift 2 ;;
        --reference) REFERENCE="${2:-}"; shift 2 ;;
        --output-prefix) OUTPUT_PREFIX="${2:-}"; shift 2 ;;
        --threads) THREADS="${2:-}"; shift 2 ;;
        --engine) ENGINE="${2:-}"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown argument: $1" ;;
    esac
done

[[ -n "${TRUTH}" ]] || die "--truth is required"
[[ -n "${QUERY}" ]] || die "--query is required"
[[ -n "${CONFIDENT_REGIONS}" ]] || die "--confident-regions is required"
[[ -n "${REFERENCE}" ]] || die "--reference is required"
[[ -n "${OUTPUT_PREFIX}" ]] || die "--output-prefix is required"
[[ "${THREADS}" =~ ^[1-9][0-9]*$ ]] || die "--threads must be a positive integer"

for path in "${TRUTH}" "${QUERY}" "${CONFIDENT_REGIONS}" "${REFERENCE}"; do
    [[ -s "${path}" ]] || die "Benchmark input missing or empty: ${path}"
done

if [[ "${DRY_RUN}" != "true" ]]; then
    require_command hap.py
fi

mkdir -p "$(dirname -- "${OUTPUT_PREFIX}")"

run_command hap.py \
    "${TRUTH}" \
    "${QUERY}" \
    -f "${CONFIDENT_REGIONS}" \
    -r "${REFERENCE}" \
    -o "${OUTPUT_PREFIX}" \
    --engine "${ENGINE}" \
    --threads "${THREADS}"

if [[ "${DRY_RUN}" != "true" ]]; then
    manifest="${OUTPUT_PREFIX}.input_checksums.tsv"
    {
        printf 'role\tpath\tsha256\n'
        printf 'truth\t%s\t%s\n' "$(realpath "${TRUTH}")" "$(sha256sum "${TRUTH}" | cut -d ' ' -f 1)"
        printf 'query\t%s\t%s\n' "$(realpath "${QUERY}")" "$(sha256sum "${QUERY}" | cut -d ' ' -f 1)"
        printf 'confident_regions\t%s\t%s\n' "$(realpath "${CONFIDENT_REGIONS}")" "$(sha256sum "${CONFIDENT_REGIONS}" | cut -d ' ' -f 1)"
        printf 'reference\t%s\t%s\n' "$(realpath "${REFERENCE}")" "$(sha256sum "${REFERENCE}" | cut -d ' ' -f 1)"
    } > "${manifest}"
fi

log "Benchmark complete. Interpret SNP and INDEL metrics separately."
