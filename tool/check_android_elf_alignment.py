#!/usr/bin/env python3
"""Fail when a 64-bit APK library is not compatible with 16 KB pages."""

from __future__ import annotations

import argparse
import struct
import sys
import zipfile
from pathlib import Path

ELF_MAGIC = b"\x7fELF"
ELFCLASS64 = 2
ELFDATA2LSB = 1
PT_LOAD = 1
MIN_ALIGNMENT = 16 * 1024


def load_alignments(data: bytes, name: str) -> list[int]:
    if len(data) < 64 or data[:4] != ELF_MAGIC:
        raise ValueError(f"{name}: not an ELF file")
    if data[4] != ELFCLASS64:
        return []
    if data[5] != ELFDATA2LSB:
        raise ValueError(f"{name}: unsupported ELF byte order")

    program_offset = struct.unpack_from("<Q", data, 32)[0]
    entry_size = struct.unpack_from("<H", data, 54)[0]
    entry_count = struct.unpack_from("<H", data, 56)[0]
    alignments: list[int] = []
    for index in range(entry_count):
        offset = program_offset + index * entry_size
        if offset + entry_size > len(data):
            raise ValueError(f"{name}: truncated program header table")
        if struct.unpack_from("<I", data, offset)[0] == PT_LOAD:
            alignments.append(struct.unpack_from("<Q", data, offset + 48)[0])
    return alignments


def apk_library_data_offset(apk, member: zipfile.ZipInfo) -> int:
    apk.seek(member.header_offset)
    header = apk.read(30)
    if len(header) != 30 or header[:4] != b"PK\x03\x04":
        raise ValueError(f"{member.filename}: invalid local ZIP header")
    name_size, extra_size = struct.unpack_from("<HH", header, 26)
    return member.header_offset + 30 + name_size + extra_size


def check_apk(path: Path) -> list[str]:
    failures: list[str] = []
    checked = 0
    with path.open("rb") as apk, zipfile.ZipFile(apk) as archive:
        for member in archive.infolist():
            if not member.filename.startswith("lib/") or not member.filename.endswith(".so"):
                continue
            data = archive.read(member)
            alignments = load_alignments(data, member.filename)
            if not alignments:
                continue
            checked += 1
            too_small = [value for value in alignments if value < MIN_ALIGNMENT]
            if too_small:
                rendered = ", ".join(hex(value) for value in too_small)
                failures.append(f"{member.filename}: PT_LOAD alignment {rendered}")
            if member.compress_type == zipfile.ZIP_STORED:
                data_offset = apk_library_data_offset(apk, member)
                if data_offset % MIN_ALIGNMENT:
                    failures.append(
                        f"{member.filename}: APK data offset {data_offset:#x} is not 16 KB aligned"
                    )
    if checked == 0:
        failures.append("APK contains no 64-bit native libraries")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path, help="APK to inspect")
    args = parser.parse_args()
    if not args.apk.is_file():
        parser.error(f"APK does not exist: {args.apk}")

    try:
        failures = check_apk(args.apk)
    except (OSError, ValueError, zipfile.BadZipFile) as error:
        print(f"ELF alignment check failed: {error}", file=sys.stderr)
        return 1
    if failures:
        print("ELF alignment check failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1
    print(f"16 KB ELF and APK alignment verified: {args.apk}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
