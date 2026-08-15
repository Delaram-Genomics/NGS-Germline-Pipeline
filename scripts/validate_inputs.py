#!/usr/bin/env python3
"""Validate a paired-end germline FASTQ samplesheet."""

from __future__ import annotations

import argparse
import csv
import gzip
import re
import sys
from dataclasses import dataclass
from pathlib import Path


REQUIRED_COLUMNS = ("sample_id", "fastq_r1", "fastq_r2")
SAMPLE_ID_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
FASTQ_SUFFIXES = (".fastq.gz", ".fq.gz")


class ValidationError(ValueError):
    """Raised when an input cannot be accepted safely."""


@dataclass(frozen=True)
class Sample:
    sample_id: str
    fastq_r1: Path
    fastq_r2: Path


def _normalise_path(raw_path: str, base_dir: Path) -> Path:
    path = Path(raw_path).expanduser()
    return path if path.is_absolute() else (base_dir / path).resolve()


def read_samplesheet(samplesheet: Path) -> list[Sample]:
    """Parse and structurally validate a CSV samplesheet."""
    if not samplesheet.is_file():
        raise ValidationError(f"Samplesheet does not exist: {samplesheet}")

    with samplesheet.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise ValidationError("Samplesheet is empty.")

        missing = [name for name in REQUIRED_COLUMNS if name not in reader.fieldnames]
        extra = [name for name in reader.fieldnames if name not in REQUIRED_COLUMNS]
        if missing:
            raise ValidationError(f"Missing required column(s): {', '.join(missing)}")
        if extra:
            raise ValidationError(f"Unexpected column(s): {', '.join(extra)}")

        samples: list[Sample] = []
        seen_ids: set[str] = set()
        for row_number, row in enumerate(reader, start=2):
            sample_id = (row.get("sample_id") or "").strip()
            r1_raw = (row.get("fastq_r1") or "").strip()
            r2_raw = (row.get("fastq_r2") or "").strip()

            if not sample_id or not r1_raw or not r2_raw:
                raise ValidationError(f"Row {row_number} contains an empty required value.")
            if not SAMPLE_ID_PATTERN.fullmatch(sample_id):
                raise ValidationError(
                    f"Invalid sample_id '{sample_id}' on row {row_number}; use letters, "
                    "numbers, '.', '_' or '-'."
                )
            if sample_id in seen_ids:
                raise ValidationError(f"Duplicate sample_id on row {row_number}: {sample_id}")
            seen_ids.add(sample_id)

            r1 = _normalise_path(r1_raw, samplesheet.parent)
            r2 = _normalise_path(r2_raw, samplesheet.parent)
            if r1 == r2:
                raise ValidationError(f"R1 and R2 are identical for sample {sample_id}.")
            samples.append(Sample(sample_id, r1, r2))

    if not samples:
        raise ValidationError("Samplesheet contains a header but no samples.")
    return samples


def _check_gzip(path: Path) -> None:
    try:
        with gzip.open(path, "rb") as handle:
            handle.read(1)
    except (OSError, EOFError) as exc:
        raise ValidationError(f"File is not a readable gzip stream: {path}") from exc


def validate_files(samples: list[Sample], check_gzip: bool = True) -> None:
    """Validate existence, suffix, size and gzip integrity."""
    for sample in samples:
        for read_name, path in (("R1", sample.fastq_r1), ("R2", sample.fastq_r2)):
            if not str(path).endswith(FASTQ_SUFFIXES):
                raise ValidationError(
                    f"{read_name} for {sample.sample_id} must end in .fastq.gz or .fq.gz: {path}"
                )
            if not path.is_file():
                raise ValidationError(f"{read_name} file does not exist for {sample.sample_id}: {path}")
            if not path.stat().st_size:
                raise ValidationError(f"{read_name} file is empty for {sample.sample_id}: {path}")
            if check_gzip:
                _check_gzip(path)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Validate a paired-end FASTQ samplesheet before pipeline execution."
    )
    parser.add_argument("--samplesheet", required=True, type=Path, help="CSV samplesheet path")
    parser.add_argument(
        "--skip-file-checks",
        action="store_true",
        help="Validate CSV structure only; useful for reviewing a template.",
    )
    parser.add_argument(
        "--skip-gzip-check",
        action="store_true",
        help="Check paths and sizes but do not open each gzip stream.",
    )
    parser.add_argument(
        "--emit-tsv",
        action="store_true",
        help="Print validated samples as tab-separated rows for pipeline scripts.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        samples = read_samplesheet(args.samplesheet.resolve())
        if not args.skip_file_checks:
            validate_files(samples, check_gzip=not args.skip_gzip_check)
    except ValidationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if args.emit_tsv:
        for sample in samples:
            print(f"{sample.sample_id}\t{sample.fastq_r1}\t{sample.fastq_r2}")
    else:
        print(f"VALID: {len(samples)} sample(s) passed input validation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
