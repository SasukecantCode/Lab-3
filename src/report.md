# Lab-3 Report (Plain-English)

## What this project is
This project is a small “text-to-program” pipeline.

You write something that looks like calculator lines (like `x = 5` and `x > 3 ? 100 : 200`).
The project turns that into:

1) **Assembly text** (a simple step-by-step instruction list)
2) **Object text** (just numbers, one per line)
3) Then it **runs** those numbers in a provided runner (the simulator) and shows the result.

So yes: it is both.
- It has a **desk calculator** part (turns calculator-style input into assembly text).
- It has an **assembler** part (turns assembly text into number-only object output).

## The big picture (one simple flow)
**.calc input** → `deskcalc` → **.asm output** → `assembler` → **.obj output** → `simulator-yns-no-frills.pyc` → final printed number

## What the key files mean

### `desk-calc-project.y`
This file describes the “shape” of the calculator language.
It says what things like numbers, `+`, `*`, `=`, parentheses, and `? :` mean and how they fit together.

In simple terms: it’s the rules for reading your calculator lines in the right order.

### `desk-calc-project.l`
This file describes how to split your input text into small pieces.
For example it recognizes:
- numbers like `123`
- names like `x` or `total`
- symbols like `+ - * / = ( ) ? :`

In simple terms: it’s the “word splitter” for the calculator input.

### `ass.y`
This file describes the rules for the assembly language that your calculator turns into.
It explains what lines like instructions and labels look like, and what is allowed.

In simple terms: it’s the rules for reading the assembly text correctly.

### `ass.l`
This file splits the assembly text into small pieces.
For example, it recognizes:
- instruction names
- label names
- numbers
- commas / newlines / punctuation that matters

In simple terms: it’s the “word splitter” for the assembly input.

### `simulator-yns-no-frills.pyc`
This is the program that **runs** the final `.obj` file.
The `.obj` file is a list of numbers. The simulator reads those numbers and acts like a tiny machine that follows them.

Why `.pyc`?
- It’s a pre-built Python file (already “packed up”), so you run it with Python.
- This project expects **Python 3.9.x** for it (this repo is set up for **3.9.18**).

Simple note about Python 3.9.18:
- This folder has a file named `.python-version` with `3.9.18` in it.
- If you use `pyenv`, it can automatically pick the right Python version for this project.

If you try to run the simulator with the wrong Python version, it won’t work (you may see an error about a “bad magic number”). The fix is simply: use Python 3.9.18.

In simple terms: it’s the “runner” that executes the number-only program.

## What gets built (the two main programs)

### `deskcalc`
Reads a `.calc` file (calculator-style lines) and prints a `.asm` file (simple instruction steps).

### `assembler`
Reads a `.asm` file and produces a `.obj` file (numbers only, one per line).

## Useful helper files
- `Makefile`: the main “build and run” command list.
- `run.sh`: a simple script that runs the calculator → assembler → simulator for a `.calc` file.
- `test1.calc`, `test2.calc`, `test3.calc`: sample calculator inputs.
- `test1.asm`, `test2.asm`, `test3.asm`: sample assembly inputs.

## How to run it (simple)
From this folder:

1) Build everything:
   - `make build`

2) Create the Python environment (needed for the simulator):
   - `make venv`

3) Run a sample calculator file:
   - `make run FILE=test1.calc`

4) Run all tests:
   - `make test`

## The essence (one sentence)
This project turns calculator-style text into a small runnable program by first translating it into assembly text, then translating that into numbers, and finally running those numbers in the simulator.
