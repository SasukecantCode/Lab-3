.NOTPARALLEL:
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash

.PHONY: help all build env venv asm assembler calc deskcalc run sim test calc-tests asm-tests clean

PYTHON ?= python3.9
VENV_DIR ?= .env
SIM ?= simulator-yns-no-frills.pyc
PYENV_PY39 ?= $(HOME)/.pyenv/versions/3.9.18/bin/python

BUILD_ASM ?= build_asm
BUILD_CALC ?= build_calc

help:
	@echo "Targets:"; \
	echo "  make build            Build assembler + deskcalc"; \
	echo "  make asm|assembler     Build assembler"; \
	echo "  make calc|deskcalc     Build desk calculator"; \
	echo "  make run FILE=...       Run pipeline for .calc or .asm"; \
	echo "  make test              Run all tests (requires venv)"; \
	echo "  make venv              Create Python 3.9 venv in $(VENV_DIR)/"; \
	echo "  make clean             Remove build artifacts"; \
	echo; \
	echo "Examples:"; \
	echo "  make build"; \
	echo "  make run FILE=test1.calc"; \
	echo "  make run FILE=test2.asm";

all: build

build: assembler deskcalc

env: venv

venv:
	@py="$(PYTHON)"; \
	if [ "$(PYTHON)" = "python3.9" ] && [ -x "$(PYENV_PY39)" ]; then py="$(PYENV_PY39)"; fi; \
	if [ ! -x "$$py" ] && ! command -v "$$py" >/dev/null 2>&1; then \
	  if [ -x "$(PYENV_PY39)" ]; then py="$(PYENV_PY39)"; \
	  elif command -v python3.9 >/dev/null 2>&1; then py=python3.9; \
	  elif command -v python >/dev/null 2>&1; then py=python; fi; \
	fi; \
	if [ ! -x "$$py" ] && ! command -v "$$py" >/dev/null 2>&1; then \
	  echo "Missing Python interpreter (tried '$(PYTHON)' and common fallbacks)."; \
	  echo "This project needs Python 3.9.x to run simulator-yns-no-frills.pyc."; \
	  echo "If you use pyenv: pyenv install 3.9.18 && pyenv local 3.9.18"; \
	  exit 1; \
	fi; \
	ver=$$("$$py" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")'); \
	if [ "$$ver" != "3.9" ]; then \
	  echo "Wrong Python version: $$py is Python $$ver (need 3.9.x)."; \
	  echo "If you use pyenv: pyenv install 3.9.18 && pyenv local 3.9.18"; \
	  exit 1; \
	fi; \
	"$$py" -m venv $(VENV_DIR)

asm: assembler

assembler: ass.l ass.y
	@mkdir -p $(BUILD_ASM)
	@cp -f ass.l ass.y $(BUILD_ASM)/
	cd $(BUILD_ASM) && yacc -d ass.y
	cd $(BUILD_ASM) && lex ass.l
	cd $(BUILD_ASM) && (gcc y.tab.c lex.yy.c -o ../assembler -lfl || gcc y.tab.c lex.yy.c -o ../assembler -ll)

calc: deskcalc

deskcalc: desk-calc-project.l desk-calc-project.y
	@mkdir -p $(BUILD_CALC)
	@cp -f desk-calc-project.l desk-calc-project.y $(BUILD_CALC)/
	cd $(BUILD_CALC) && yacc -d desk-calc-project.y
	cd $(BUILD_CALC) && lex desk-calc-project.l
	cd $(BUILD_CALC) && (gcc y.tab.c lex.yy.c -o ../deskcalc -lfl || gcc y.tab.c lex.yy.c -o ../deskcalc -ll)

%.calc.asm: %.calc deskcalc
	./deskcalc < $< > $@

%.calc.obj: %.calc.asm assembler
	./assembler $< $@

%.asm.obj: %.asm assembler
	./assembler $< $@

sim:
	@if [ -z "$(OBJ)" ]; then echo "Usage: make sim OBJ=path/to/file.obj"; exit 2; fi
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then echo "Missing $(VENV_DIR). Run 'make venv' first."; exit 1; fi
	@OBJ="$(OBJ)"; \
	$(VENV_DIR)/bin/python $(SIM) "$$OBJ"

run: build
	@if [ -z "$(FILE)" ]; then echo "Usage: make run FILE=path/to/input.calc|input.asm"; exit 2; fi
	@if [ ! -f "$(FILE)" ]; then echo "Missing input file: $(FILE)"; exit 2; fi
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then echo "Missing $(VENV_DIR). Run 'make venv' first."; exit 1; fi
	@FILE="$(FILE)"; \
	base="$$(basename "$$FILE")"; base="$${base%.*}"; \
	case "$$FILE" in \
	  *.calc) \
	    ./deskcalc < "$$FILE" > "$$base.calc.asm"; \
	    ./assembler "$$base.calc.asm" "$$base.calc.obj"; \
	    $(VENV_DIR)/bin/python $(SIM) "$$base.calc.obj" ;; \
	  *.asm) \
	    ./assembler "$$FILE" "$$base.asm.obj"; \
	    $(VENV_DIR)/bin/python $(SIM) "$$base.asm.obj" ;; \
	  *) \
	    echo "Unknown input type: $$FILE (expected .calc or .asm)"; exit 2 ;; \
	esac

test: calc-tests asm-tests

calc-tests: build
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then echo "Missing $(VENV_DIR). Run 'make venv' first."; exit 1; fi
	@pass=0; fail=0; \
	for t in 1 2 3; do \
	  in="test$$t.calc"; asm="calc_test$$t.asm"; obj="calc_test$$t.obj"; \
	  echo "== calc test$$t =="; \
	  ./deskcalc < "$$in" > "$$asm"; \
	  ./assembler "$$asm" "$$obj"; \
	  exp=""; \
	  out=$$($(VENV_DIR)/bin/python $(SIM) "$$obj" | tr -d '\r' | sed -E 's/Enter integer:[[:space:]]*//g' | sed -E 's/^[[:space:]]+|[[:space:]]+$$//g' | grep -E '^-?[0-9]+$$' | tail -n 1 || true); \
	  case $$t in \
	    1) exp="100" ;; \
	    2) exp="200" ;; \
	    3) exp="24" ;; \
	  esac; \
	  if [ "$$out" = "$$exp" ]; then echo "PASS: calc test$$t"; pass=$$((pass+1)); else echo "FAIL: calc test$$t (got '$$out', expected '$$exp')"; fail=$$((fail+1)); fi; \
	done; \
	echo "Calc Passed: $$pass, Failed: $$fail"; \
	if [ $$fail -ne 0 ]; then exit 1; fi

asm-tests: build
	@if [ ! -f "$(VENV_DIR)/bin/activate" ]; then echo "Missing $(VENV_DIR). Run 'make venv' first."; exit 1; fi
	@pass=0; fail=0; \
	echo "== asm test1 (requires input) =="; \
	./assembler test1.asm test1.obj; \
	out=$$(printf "3\n1\n2\n3\n" | $(VENV_DIR)/bin/python $(SIM) test1.obj | tr -d '\r' | sed -E 's/Enter integer:[[:space:]]*//g' | sed -E 's/^[[:space:]]+|[[:space:]]+$$//g' | grep -E '^-?[0-9]+$$' | tail -n 1 || true); \
	if [ "$$out" = "16" ]; then echo "PASS: asm test1"; pass=$$((pass+1)); else echo "FAIL: asm test1 (got '$$out', expected '16')"; fail=$$((fail+1)); fi; \
	echo "== asm test2 =="; \
	./assembler test2.asm test2.obj; \
	out=$$($(VENV_DIR)/bin/python $(SIM) test2.obj | tr -d '\r' | sed -E 's/Enter integer:[[:space:]]*//g' | sed -E 's/^[[:space:]]+|[[:space:]]+$$//g' | grep -E '^-?[0-9]+$$' | tail -n 1 || true); \
	if [ "$$out" = "8" ]; then echo "PASS: asm test2"; pass=$$((pass+1)); else echo "FAIL: asm test2 (got '$$out', expected '8')"; fail=$$((fail+1)); fi; \
	echo "== asm test3 =="; \
	./assembler test3.asm test3.obj; \
	out=$$($(VENV_DIR)/bin/python $(SIM) test3.obj | tr -d '\r' | sed -E 's/Enter integer:[[:space:]]*//g' | sed -E 's/^[[:space:]]+|[[:space:]]+$$//g' | grep -E '^-?[0-9]+$$' | tail -n 1 || true); \
	if [ "$$out" = "14" ]; then echo "PASS: asm test3"; pass=$$((pass+1)); else echo "FAIL: asm test3 (got '$$out', expected '14')"; fail=$$((fail+1)); fi; \
	echo "Asm Passed: $$pass, Failed: $$fail"; \
	if [ $$fail -ne 0 ]; then exit 1; fi

clean:
	rm -rf $(BUILD_ASM) $(BUILD_CALC)
	rm -f assembler deskcalc *.obj *.calc.asm *.calc.obj *.asm.obj calc_test*.asm calc_test*.obj
