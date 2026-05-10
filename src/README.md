# LAB-3: Systems Programming and Compilers

## Project Overview
Project 1 is a desk calculator that parses expressions (including ternary) and emits JBC assembly.
Project 2 is a two-pass assembler that relocates all data directives to the bottom of the object file.
Together they form a pipeline from high-level expressions to runnable object code in the simulator.
The object format stays plain text with one integer per line.

## Prerequisites
- gcc
- flex
- bison
- Python 3.9.x (recommended: 3.9.18 via pyenv)

Commands to install on Arch Linux:
```bash
sudo pacman -S --needed base-devel flex bison gcc
yay -S python39
```

## Recommended Python setup (pyenv)
The simulator file is `simulator-yns-no-frills.pyc`, and it expects **Python 3.9.x**.

If you use `pyenv`, this repo already includes a `.python-version` file set to `3.9.18`.
From this folder:

```bash
pyenv install 3.9.18
pyenv local 3.9.18
make venv PYTHON=python
```

If you run the simulator with the wrong Python version, you may see an error like:
`RuntimeError: Bad magic number in .pyc file`
That just means “wrong Python version”; switch to Python 3.9.18 and try again.

## Makefile Commands
Run these from the directory containing the Makefile (this folder).

```bash
make help
```

- `make help`: Print a short list of common targets + examples.
- `make all`: Alias for `make build`.
- `make build`: Build both programs (`assembler` and `deskcalc`).
- `make asm` / `make assembler`: Build the assembler (outputs `./assembler`).
- `make calc` / `make deskcalc`: Build the desk calculator (outputs `./deskcalc`).
- `make env` / `make venv`: Create a Python 3.9 virtual environment (default: `.env/`).
- `make run FILE=...`: Build + run the full pipeline for a `.calc` or `.asm` input.
- `make sim OBJ=...`: Run the simulator on an existing `.obj` file.
- `make test`: Run all tests (runs `calc-tests` + `asm-tests`).
- `make calc-tests`: Run desk calculator tests (requires venv).
- `make asm-tests`: Run assembler tests (requires venv; `test1` feeds input automatically).
- `make clean`: Remove build artifacts and generated files.

### Common examples
```bash
make build
make venv
make run FILE=test1.calc
make run FILE=test2.asm
make sim OBJ=test3.obj
make test
```

### Variables you can override
- `PYTHON` (default: `python3.9`): Interpreter used for `make venv`.
- `VENV_DIR` (default: `.env`): Virtualenv path.
- `SIM` (default: `simulator-yns-no-frills.pyc`): Simulator program.
- `FILE`: Input to `make run` (must end in `.calc` or `.asm`).
- `OBJ`: Input to `make sim` (path to a `.obj`).
- `BUILD_ASM` / `BUILD_CALC`: Build directories used by `yacc`/`lex`.

Example overrides:
```bash
make venv PYTHON=python3.9 VENV_DIR=.env
make run FILE=test1.calc SIM=simulator-yns-no-frills.pyc
```

## Folder Structure
```
tree LAB-3/
```

```
.
├── assembler
├── assembler-yns.out
├── ass.l
├── ass.y
├── build_calc
│   ├── desk-calc-project.l
│   ├── desk-calc-project.y
│   ├── lex.yy.c
│   ├── y.tab.c
│   └── y.tab.h
├── calc_test1.asm
├── calc_test1.obj
├── calc_test2.asm
├── calc_test2.obj
├── calc_test3.asm
├── calc_test3.obj
├── design_notes.txt
├── deskcalc
├── desk-calc-project.l
├── desk-calc-project.y
├── lex.yy.c
├── Makefile
├── run.sh
├── simulator-yns-no-frills.pyc
├── test1.asm
├── test1.calc
├── test1.obj
├── test2.asm
├── test2.calc
├── test2.obj
├── test3.asm
├── test3.calc
├── test3.obj
├── y.tab.c
└── y.tab.h

2 directories, 34 files
```

## Setup: Python 3.9 Virtual Environment
```bash
cd LAB-3
python3.9 -m venv .env
source .env/bin/activate
python --version        # must show 3.9.x
```

## Build: Project 2 — Assembler
```bash
cd LAB-3
yacc -d ass.y
lex ass.l
gcc y.tab.c lex.yy.c -o assembler -lfl
```

## Build: Project 1 — Desk Calculator
```bash
mkdir -p build_calc
cp desk-calc-project.l desk-calc-project.y build_calc/
cd build_calc
yacc -d desk-calc-project.y
lex desk-calc-project.l
gcc y.tab.c lex.yy.c -o ../deskcalc -lfl
cd ..
```

## Running: Full Pipeline
The pipeline is:
  desk calculator → JBC assembly → assembler → object file → simulator

```bash
# Step 1: activate venv
source .env/bin/activate

# Step 2: run desk calculator on input
./deskcalc < your_input.calc > output.asm

# Step 3: assemble
./assembler output.asm output.obj

# Step 4: simulate
python simulator-yns-no-frills.pyc output.obj
```

## Test Cases

### Project 1 — Ternary Operator Tests

Test 1 input (test1.calc):
```
x = 5
x > 3 ? 100 : 200
```

```bash
# Test 1 — true branch
./deskcalc < test1.calc > calc_test1.asm
./assembler calc_test1.asm calc_test1.obj
python simulator-yns-no-frills.pyc calc_test1.obj
# Expected output: 100
```

Test 2 input (test2.calc):
```
x = 1
x > 5 ? 100 : 200
```

```bash
# Test 2 — false branch
./deskcalc < test2.calc > calc_test2.asm
./assembler calc_test2.asm calc_test2.obj
python simulator-yns-no-frills.pyc calc_test2.obj
# Expected output: 200
```

Test 3 input (test3.calc):
```
a = 4
b = 6
a + b > 8 ? a * b : a + b
```

```bash
# Test 3 — nested arithmetic
./deskcalc < test3.calc > calc_test3.asm
./assembler calc_test3.asm calc_test3.obj
python simulator-yns-no-frills.pyc calc_test3.obj
# Expected output: 24
```

### Project 2 — Data Relocation Tests

Test 1 input (test1.asm):
```
N: .reserve 1
        .start begin
begin:  read
        istore N
        iload N
        ldc 1
        isub
        iflt exit
loop:   read
        iload sum
        iadd
        istore sum
        iload N
        ldc 1
        isub
        istore N
        iload N
        ifgt loop
        iload sum
        print
exit:   halt
sum:    .constant 10
        .end
```

```bash
# Test 1 — mixed directives (N at top, sum at bottom)
./assembler test1.asm test1.obj
python simulator-yns-no-frills.pyc test1.obj
# Input when prompted: 3 1 2 3
# Expected output: 16
```

Test 2 input (test2.asm):
```
x:      .reserve 1
y:      .constant 5
        .start main
main:   ldc 3
        istore x
        iload x
        iload y
        iadd
        print
        halt
        .end
```

```bash
# Test 2 — both directives at top
./assembler test2.asm test2.obj
python simulator-yns-no-frills.pyc test2.obj
# Expected output: 8
```

Test 3 input (test3.asm):
```
        .start main
main:   ldc 7
        istore a
        iload a
        ldc 2
        imul
        print
        halt
a:      .reserve 1
b:      .constant 3
        .end
```

```bash
# Test 3 — both directives at bottom
./assembler test3.asm test3.obj
python simulator-yns-no-frills.pyc test3.obj
# Expected output: 14
```

## Run All Tests at Once
```bash
source .env/bin/activate

echo "=== CALC TESTS ===" 
for i in 1 2 3; do
  echo "--- Test $i ---"
  ./deskcalc < test$i.calc > calc_test$i.asm
  ./assembler calc_test$i.asm calc_test$i.obj
  python simulator-yns-no-frills.pyc calc_test$i.obj
done

echo "=== ASM TESTS ==="
for i in 1 2 3; do
  echo "--- Test $i ---"
  ./assembler test$i.asm test$i.obj
  python simulator-yns-no-frills.pyc test$i.obj
done
```

## Design Notes

### Project 1 — Ternary Operator
A new ternary grammar rule was added in desk-calc-project.y using mid-rule actions so code emits in the correct order.
A global label counter generates unique labels like L0, L1 for each ternary branch.
The codegen flow is: eval expr1 → ifeq false_label → eval expr2 → istore temp → ldc 1 → ifgt end_label →
false_label: → eval expr3 → istore temp → end_label: → iload temp.
The ternary uses a reserved temp at address 1, leaving address 0 as scratch for unary minus.
The operator precedence assigns '?' and ':' as lowest precedence so arithmetic binds tighter than the ternary.
A comparison rule for '>' emits 1 or 0 so ternary conditions work with relational expressions.

### Project 2 — Data Relocation
Data directives are collected in a separate list during pass 1 without affecting the instruction counter.
After pass 1, instruction_count is used to assign each data label an address at the bottom of memory.
Pass 2 emits all instruction words first, then appends all data values at the end of the output.
The .start directive now resolves identifiers through the symbol table (and still accepts numeric entry points).
The object file format remains plain text, one integer per line, with entry point on the first line.
Labels on instruction lines are handled so source can use "label: opcode" syntax.

## Notes
- Do NOT modify simulator-yns-no-frills.pyc
- assembler-yns.out is the reference binary (may not run on all architectures)
- The .env folder is gitignored and only activates Python 3.9 locally
- Deactivate the venv anytime with: deactivate
