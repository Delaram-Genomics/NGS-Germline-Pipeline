#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

OUTDIR="test_data/smoke"
if [[ $# -gt 0 ]]; then
    [[ "$1" == "--outdir" && $# -eq 2 ]] || die "Usage: scripts/prepare_smoke_test.sh [--outdir DIR]"
    OUTDIR="$2"
fi

require_command python3
require_command bwa
require_command samtools
require_command gatk

python3 "${SCRIPT_DIR}/create_smoke_fixture.py" --outdir "${OUTDIR}"

reference="${OUTDIR}/synthetic.fa"
log "Indexing the synthetic reference"
bwa index "${reference}"
samtools faidx "${reference}"
gatk CreateSequenceDictionary -R "${reference}" -O "${OUTDIR}/synthetic.dict"

log "Smoke fixture ready. Run the Nextflow test command in docs/BENCHMARKING.md."
