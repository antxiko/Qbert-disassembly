# In the emulator

The pictures are built from the ROM, not captured. openMSX is used for two
things: to **check** those pictures against the real VRAM and to **test** what
the code says about the game.

Everything with openMSX and the `C-BIOS_MSX1_JP` machine, one emulator at a
time.

## The check

`tools/omsx_vuelca.tcl` dumps the VRAM, the RAM from `0xE000` to `0xFFFF` and
the VDP registers at the given seconds, pressing space where needed.
`tools/omsx_fase.tcl` starts the game on any stage: it writes the stage to
`0xE111` at the `call monta_la_fase` at `0x4209`, only once, and dumps a few
seconds later.

`tools/coteja_todo.py` builds each screen with `tools/pantallas.py` and
compares it with its dump: the whole name table, the pattern and colour of
every tile in use, the visible sprites and their patterns. The time, the
lives, the objects and the sprite turn of that frame come from the dump's RAM.

| screen | differences |
|---|---|
| Konami logo | 0 |
| title | 0 |
| stage 1 | 0 |
| stage 11 | 0 |
| stage 21 | 0 |
| stage 41 | 0 |
| stage 50 | 0 |
| duel, stage 31 | 0 |
| bonus after stage 3 | 0 |

Two measurement traps. The sprite table is written at the start of the frame
and the objects move afterwards: a dump taken mid-frame has the RAM's Y one step
ahead of the VRAM's. And the copy of the name table is sent a quarter at a
time, one per frame: a digit of the time can be one frame behind.

## The tests

`tools/omsx_prueba.tcl` reads a list of timed orders (write a byte, press a
key, dump) and `tools/lanza_prueba.sh` runs it. The five in `tools/pruebas/`:

| test | what is done | what happens |
|---|---|---|
| `linea.txt` | on stage 1, five cubes on row 4 marked as finished | stage cleared (game steps 2, 4 and 5) and the time is paid: 430 points for 43 seconds |
| `vida.txt` | the streak of three set to 1, 1, 1 | the object appears at Q\*bert's Y, crosses, and the lives go from 2 to 3 |
| `continue.txt` | no lives and the time at 1 | GAME OVER; with F5, the game again with two lives in reserve |
| `pausa.txt` | F1 twice | the time stays at 99 until the second F1 |
| `bonus.txt` | stage 3 and stage cleared | bit 0 of the mode turns on and the bonus stage starts |

## Running it

```
tools/lanza_vuelca.sh work/v1 "6 12" "10"
tools/lanza_fase.sh "11 0 0 3"
tools/lanza_prueba.sh tools/pruebas/vida.txt
make coteja
```
