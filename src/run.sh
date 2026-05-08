#!/bin/bash
# Usage: ./run.sh <input.calc>
# Runs the full pipeline: deskcalc -> assembler -> simulator

set -e
INPUT=$1
BASE=$(basename "$INPUT" .calc)

echo "=== Running desk calculator ==="
./deskcalc < "$INPUT" > "$BASE.calc.asm"
cat "$BASE.calc.asm"

echo "=== Assembling ==="
./assembler "$BASE.calc.asm" "$BASE.calc.obj"
cat "$BASE.calc.obj"

echo "=== Simulating ==="
source .env/bin/activate
python simulator-yns-no-frills.pyc "$BASE.calc.obj"
