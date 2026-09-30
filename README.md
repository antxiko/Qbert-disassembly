# Q\*bert (MSX) — a commented disassembly

*(También disponible [en castellano](README.es.md).)*

A commented disassembly of ***Q\*bert*** (キューバート), Konami, 1986, cartridge
**RC-746** for the **MSX**: 32 KB with no mapper in pages 1 and 2.

**The website**: https://antxiko.github.io/Qbert-disassembly/

| | |
|---|---|
| explained | 100% (11,743 bytes of code, 21,025 of data) |
| commented | 78.1% of the instructions |
| routines | 788 (444 with their own name), none below 10% |
| reassembly | the ROM, byte for byte |
| pictures | drawn from the ROM; nine screens checked against openMSX, 0 differences |

## What is here

- The listing (`src/qbert.asm`), generated from the binary and the notes, which
  reassembles the exact ROM.
- The 50 stages, the bonus stage and the duel, built from the ROM's 9 × 9
  boards and cubes.
- Q\*bert in all his poses, the fifteen objects, the moai, the rock, paper,
  scissors hands and the logos.
- How it works: the cubes roll like dice, a stage ends with five in a row, the
  duel is settled by rock, paper, scissors, there is a hidden life and F5 is the
  CONTINUE.

## How to reproduce it

You need Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) and **your own
image of the cartridge** as `qbert.rom` at the root:

```
sha256  bd253f3285b3bf31501cd34f593f35ed3b9adfc6eb44c360c6fd59f8ab2c3684
make
```

The details, in [Getting started](docs/GETTING-STARTED.md).

## Notice

The game belongs to Konami; only the analysis, the comments and the tools are
here. The ROM is not distributed. See [LEGAL-NOTICE.md](LEGAL-NOTICE.md).
