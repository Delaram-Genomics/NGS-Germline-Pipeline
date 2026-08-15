#!/usr/bin/env python3
"""Create a tiny deterministic, non-human FASTQ fixture for workflow smoke tests."""

from __future__ import annotations

import argparse
import gzip
import random
from pathlib import Path


def reverse_complement(sequence: str) -> str:
    return sequence.translate(str.maketrans("ACGT", "TGCA"))[::-1]


def write_fastq(path: Path, reads: list[tuple[str, str]]) -> None:
    with gzip.open(path, "wt", encoding="ascii") as handle:
        for name, sequence in reads:
            handle.write(f"@{name}\n{sequence}\n+\n{'I' * len(sequence)}\n")


def create_fixture(outdir: Path) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    rng = random.Random(20260816)
    reference = "".join(rng.choice("ACGT") for _ in range(800))
    variant_pos = 401  # one-based
    reference_allele = reference[variant_pos - 1]
    alternate_allele = next(base for base in "ACGT" if base != reference_allele)

    reference_path = outdir / "synthetic.fa"
    reference_path.write_text(f">synthetic_chr\n{reference}\n", encoding="ascii")

    r1_reads: list[tuple[str, str]] = []
    r2_reads: list[tuple[str, str]] = []
    read_length = 100
    fragment_length = 240
    for index in range(30):
        start = 300 + (index % 20)
        fragment = list(reference[start : start + fragment_length])
        variant_offset = (variant_pos - 1) - start
        if index % 2 == 0 and 0 <= variant_offset < len(fragment):
            fragment[variant_offset] = alternate_allele
        fragment_sequence = "".join(fragment)
        r1_reads.append((f"synthetic_{index + 1}/1", fragment_sequence[:read_length]))
        r2_reads.append((f"synthetic_{index + 1}/2", reverse_complement(fragment_sequence[-read_length:])))

    r1_path = outdir / "SYNTH001_R1.fastq.gz"
    r2_path = outdir / "SYNTH001_R2.fastq.gz"
    write_fastq(r1_path, r1_reads)
    write_fastq(r2_path, r2_reads)

    (outdir / "samplesheet.csv").write_text(
        "sample_id,fastq_r1,fastq_r2\n"
        f"SYNTH001,{r1_path.resolve()},{r2_path.resolve()}\n",
        encoding="utf-8",
    )
    (outdir / "targets.bed").write_text("synthetic_chr\t250\t650\n", encoding="ascii")
    (outdir / "expected_variant.txt").write_text(
        f"synthetic_chr\t{variant_pos}\t{reference_allele}\t{alternate_allele}\n",
        encoding="ascii",
    )
    (outdir / "README.txt").write_text(
        "This deterministic synthetic fixture contains no human or patient data.\n"
        "It is designed only to test workflow wiring and failure handling; it is\n"
        "not an analytical accuracy benchmark.\n",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--outdir", required=True, type=Path)
    args = parser.parse_args()
    create_fixture(args.outdir.resolve())
    print(f"WROTE: synthetic smoke-test fixture to {args.outdir.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
