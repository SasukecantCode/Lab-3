# Report 2 (Plain-English): Adding a “Relocation Table” to the Assembler Output

## What the question is asking (in simple words)
The assignment asks us to change the **assembler** so the `.obj` file contains **extra info at the top**.

That extra info is a small list called a **relocation table**.

This table is just a list of **line/position numbers** inside the object code that contain an **address** (a “where to go / where to store / where to load” number).

Why do we need that list?
Because sometimes a program gets loaded somewhere else in memory, and then the address numbers inside the program need to be shifted.
The relocation table tells the loader/simulator exactly which numbers need that shift.

## What the project used to do (before)
Before this change, the assembler wrote an object file like this:

1) **Entry point** (the line number where the program starts)
2) Then **all object code numbers**, one per line

So the simulator could read it directly.

## What the question wanted us to do (after)
After this change, the assembler must write the object file like this:

1) **Entry point**
2) **How many relocation entries there are**
3) The **relocation entries** (one per line)
4) Then the **object code numbers** (one per line)

This matches the format shown in the assignment handout.

## What we changed in this project

### 1) Assembler now prints the relocation table in the `.obj`
We updated the assembler so it:
- keeps a list of “positions that need relocation”
- prints that list into the `.obj` file right after the entry point

In plain terms: the `.obj` file got a small “header” added at the top.

### 2) We only mark the lines that hold an address
Only some instructions contain an address number (for example: “load from this label”, “store into that label”, “jump to that label”).

For those instructions, we recorded the position of the **address number** inside the output.

Important: we did **not** change how the program works.
We only added a list describing where the address numbers are.

### 3) The simulator is still the same, so we added a small wrapper
The provided simulator (`simulator-yns-no-frills.pyc`) expects the **old** `.obj` format.
If we feed it the new format directly, it gets confused.

So we added a small helper program (`sim_wrapper.py`) that:
- reads the new object file
- removes the relocation-table header
- runs the simulator using the old format

This way:
- the assembler output matches the assignment spec
- and the existing simulator can still run programs for testing

## Quick “before vs after” summary

### Before
- Output `.obj`:
  - entry point
  - object code numbers

### After
- Output `.obj`:
  - entry point
  - relocation table length
  - relocation offsets
  - object code numbers

## Final point (the essence)
The main goal was: **make the assembler output include a relocation table**.
We did that by adding extra lines at the top of the `.obj` file, listing exactly which object-code positions contain address numbers that may need shifting when the program is loaded.
