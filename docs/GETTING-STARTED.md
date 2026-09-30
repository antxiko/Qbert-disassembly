# Getting started

To reproduce this disassembly you need Python 3, GNU make and
[Pasmo](https://pasmo.speccy.org/). The cartridge image **does not travel in
this repository**: bring your own.

```
qbert.rom    32,768 bytes
sha256       bd253f3285b3bf31501cd34f593f35ed3b9adfc6eb44c360c6fd59f8ab2c3684
```

With the file at the root of the repository:

```
make            # listing, verification, consistency and tests
```

## What each step does

| command | what it does |
|---|---|
| `make comprueba` | checks the ROM's sha256 |
| `make listado` | traces the flow and generates `src/qbert.asm` from the binary and the notes |
| `make verify` | reassembles the listing and compares its sha256 with the ROM's |
| `make sanity` | checks that no data comes out as code and that no byte is left unassigned |
| `make test` | the tests |
| `make densidad` | how many instructions carry a comment, routine by routine |
| `make imagenes` | draws the web's pictures from the ROM |
| `make coteja` | checks those screens against the openMSX dumps |
| `make web` | generates the HTML pages and checks the links |

`make verify` is the one that decides: it has to end with `OK: reproducible
byte a byte`.

## Where everything is

| file | what it is |
|---|---|
| `src/qbert.notes` | the names, comments and data blocks, anchored to addresses |
| `src/qbert.entries` | the entry points the trace cannot deduce, each with its reason |
| `src/qbert.nocode` | the areas that are not code even if the trace could enter them |
| `src/qbert.asm` | the commented listing, generated |
| `tools/z80trace.py`, `tools/mkasm.py` | the tracer and the listing generator |
| `tools/graficos.py` | the cartridge's two formats: the VRAM RLE and the text scripts |
| `tools/sonido.py` | walks the sound data the way the engine reads it |
| `tools/pantallas.py`, `tools/imagenes.py` | build every screen from the tables and paint it |
| `tools/coteja.py`, `tools/coteja_todo.py` | the check against the openMSX dumps |
| `tools/omsx_*.tcl`, `tools/lanza_*.sh` | the openMSX probes: see [In the emulator](IN-THE-EMULATOR.md) |

The pages: [The game](THE-GAME.md), [The cartridge](THE-CARTRIDGE.md),
[The code](THE-CODE.md), [Findings](FINDINGS.md),
[In the emulator](IN-THE-EMULATOR.md) and [Open questions](OPEN-QUESTIONS.md).
