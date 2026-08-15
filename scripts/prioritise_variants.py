#!/usr/bin/env python3
"""Create a transparent research-review table from a VEP-annotated VCF."""

from __future__ import annotations

import argparse
import csv
import gzip
import re
import sys
from pathlib import Path
from typing import TextIO


class AnnotationError(ValueError):
    """Raised when an annotated VCF cannot be interpreted safely."""


OUTPUT_FIELDS = (
    "chrom",
    "pos",
    "ref",
    "alt",
    "filter",
    "symbol",
    "gene",
    "consequence",
    "impact",
    "feature",
    "biotype",
    "hgvsc",
    "hgvsp",
    "canonical",
    "mane_select",
    "clin_sig",
    "max_af",
    "sift",
    "polyphen",
    "research_review_flag",
    "review_reason",
)


def _open_text(path: Path) -> TextIO:
    if path.suffix == ".gz":
        return gzip.open(path, "rt", encoding="utf-8")
    return path.open("r", encoding="utf-8")


def _parse_csq_fields(header_line: str) -> list[str]:
    match = re.search(r'Format: ([^">]+)', header_line)
    if not match:
        raise AnnotationError("VEP CSQ header does not contain a parseable Format declaration.")
    fields = match.group(1).strip().split("|")
    if "Allele" not in fields or "Consequence" not in fields:
        raise AnnotationError("VEP CSQ header is missing Allele or Consequence fields.")
    return fields


def _parse_float(value: str) -> float | None:
    if value in {"", ".", "-"}:
        return None
    candidates = []
    for item in value.replace("&", ",").split(","):
        try:
            candidates.append(float(item))
        except ValueError:
            continue
    return max(candidates) if candidates else None


def _review_decision(annotation: dict[str, str], filter_value: str) -> tuple[str, str]:
    if filter_value not in {"PASS", "."}:
        return "DO_NOT_PRIORITISE", "variant has a technical FILTER label"

    impact = annotation.get("IMPACT", "").upper()
    max_af = _parse_float(annotation.get("MAX_AF", ""))
    rare_or_unreported = max_af is None or max_af <= 0.01

    if impact in {"HIGH", "MODERATE"} and rare_or_unreported:
        frequency_reason = "population frequency not reported" if max_af is None else "MAX_AF <= 0.01"
        return "REVIEW", f"PASS; {impact} consequence; {frequency_reason}"
    return "LOWER_PRIORITY", "does not meet the documented technical review rule"


def parse_annotated_vcf(input_vcf: Path) -> list[dict[str, str]]:
    if not input_vcf.is_file():
        raise AnnotationError(f"Annotated VCF does not exist: {input_vcf}")

    csq_fields: list[str] | None = None
    records: list[dict[str, str]] = []

    with _open_text(input_vcf) as handle:
        for line_number, line in enumerate(handle, start=1):
            if line.startswith("##INFO=<ID=CSQ"):
                csq_fields = _parse_csq_fields(line)
                continue
            if line.startswith("#"):
                continue
            if csq_fields is None:
                raise AnnotationError("No VEP CSQ header was found before variant records.")

            columns = line.rstrip("\n").split("\t")
            if len(columns) < 8:
                raise AnnotationError(f"Malformed VCF record on line {line_number}.")
            chrom, pos, _identifier, ref, alts, _qual, filter_value, info = columns[:8]
            info_items = {}
            for item in info.split(";"):
                key, separator, value = item.partition("=")
                if separator:
                    info_items[key] = value
            if "CSQ" not in info_items:
                raise AnnotationError(f"Variant on line {line_number} has no CSQ annotation.")

            for raw_annotation in info_items["CSQ"].split(","):
                values = raw_annotation.split("|")
                values.extend([""] * (len(csq_fields) - len(values)))
                annotation = dict(zip(csq_fields, values, strict=False))
                allele = annotation.get("Allele", "")
                matching_alt = allele if allele in alts.split(",") else alts
                review_flag, reason = _review_decision(annotation, filter_value)
                records.append(
                    {
                        "chrom": chrom,
                        "pos": pos,
                        "ref": ref,
                        "alt": matching_alt,
                        "filter": filter_value,
                        "symbol": annotation.get("SYMBOL", ""),
                        "gene": annotation.get("Gene", ""),
                        "consequence": annotation.get("Consequence", ""),
                        "impact": annotation.get("IMPACT", ""),
                        "feature": annotation.get("Feature", ""),
                        "biotype": annotation.get("BIOTYPE", ""),
                        "hgvsc": annotation.get("HGVSc", ""),
                        "hgvsp": annotation.get("HGVSp", ""),
                        "canonical": annotation.get("CANONICAL", ""),
                        "mane_select": annotation.get("MANE_SELECT", ""),
                        "clin_sig": annotation.get("CLIN_SIG", ""),
                        "max_af": annotation.get("MAX_AF", ""),
                        "sift": annotation.get("SIFT", ""),
                        "polyphen": annotation.get("PolyPhen", ""),
                        "research_review_flag": review_flag,
                        "review_reason": reason,
                    }
                )

    if csq_fields is None:
        raise AnnotationError("Annotated VCF does not contain a VEP CSQ header.")
    return records


def write_tsv(records: list[dict[str, str]], output_tsv: Path) -> None:
    output_tsv.parent.mkdir(parents=True, exist_ok=True)
    with output_tsv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=OUTPUT_FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create a non-clinical research review table from VEP CSQ annotations."
    )
    parser.add_argument("--input-vcf", required=True, type=Path)
    parser.add_argument("--output-tsv", required=True, type=Path)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        records = parse_annotated_vcf(args.input_vcf)
        write_tsv(records, args.output_tsv)
    except AnnotationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    print(f"WROTE: {len(records)} annotated consequence row(s) to {args.output_tsv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
