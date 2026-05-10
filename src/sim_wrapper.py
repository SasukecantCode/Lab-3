#!/usr/bin/env python3
"""Run the provided simulator on an object file that may include a relocation table.

Why this exists:
- The assignment spec wants the assembler to output:
    entry point
    relocation table length
    relocation offsets...
    object code words...
- The provided `simulator-yns-no-frills.pyc` expects the *legacy* format:
    entry point
    object code words...

This wrapper converts the new format to the legacy format *only for simulation*.
It does not change the assembler output file on disk.
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from typing import List, Tuple


def _read_int_lines(path: str) -> List[int]:
    with open(path, "r", encoding="utf-8") as f:
        lines = [ln.strip() for ln in f.readlines() if ln.strip() != ""]
    try:
        return [int(x) for x in lines]
    except ValueError as e:
        raise SystemExit(f"Object file contains a non-integer line: {path}") from e


def _split_new_format(values: List[int]) -> Tuple[int, List[int]]:
    """Return (entry_point, code_words).

    Detects the new format if it looks valid; otherwise treats input as legacy format.
    """
    if len(values) < 2:
        raise SystemExit("Object file is too short.")

    entry = values[0]
    n = values[1]

    # Try to parse as new format.
    if n >= 0 and 2 + n <= len(values):
        reloc = values[2 : 2 + n]
        code = values[2 + n :]

        # Validate relocation offsets: sorted, unique, and within code.
        if code and all(r >= 0 for r in reloc):
            sorted_unique = sorted(set(reloc))
            if sorted_unique == reloc and all(r < len(code) for r in reloc):
                return entry, code

    # Fallback: legacy format (entry + code)
    return entry, values[1:]


def main(argv: List[str]) -> int:
    if len(argv) != 3:
        print("Usage: python sim_wrapper.py simulator-yns-no-frills.pyc input.obj", file=sys.stderr)
        return 2

    sim_pyc = argv[1]
    obj_path = argv[2]

    values = _read_int_lines(obj_path)
    entry, code = _split_new_format(values)

    # Write legacy temp file (entry + code only)
    with tempfile.TemporaryDirectory(prefix="lab3_sim_") as td:
        legacy_path = os.path.join(td, "legacy.obj")
        with open(legacy_path, "w", encoding="utf-8") as f:
            f.write(f"{entry}\n")
            for w in code:
                f.write(f"{w}\n")

        proc = subprocess.run([sys.executable, sim_pyc, legacy_path])
        return int(proc.returncode)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
