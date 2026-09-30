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
| `0x6757` viewer over stage 1 | 0 |
| `0x6757` viewer over the title | 0 |

In both viewers the tiles each screen builds are compared; the rest are leftovers from earlier ones. The title, besides, is built on top of the Konami logo's VRAM: nine of its tiles keep the colour the logo left them.

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

## The twelve pieces nobody calls

`tools/omsx_huerfanos.tcl` runs them in a game, one per frame: at `0x40C5` it
stacks the return, jumps to the piece with the registers it needs and records
what it did. The last one is the viewer, and the emulator stays paused with it
on screen (`tools/lanza_huerfanos.sh`).

| piece | what it does |
|---|---|
| `0x640D` | with stage 0x23 it returns A=09: the minimum of the stage minus one and 9 |
| `0x45FD` | swaps 4 bytes between HL and DE |
| `0x4643` | sets up a VRAM read and leaves port 0x98 in C' |
| `0x705E` | stores joystick 2: with A=05, 0xE32F=05 and 0xE330=05 |
| `0x7068` | reads E, S, F and C: with E held, A=01 (up) |
| `0x722C` | the cube under Q\*bert against the model: not equal |
| `0x77CC` | writes 0x5A into fourteen objects in a row |
| `0x833C` | the other player is not falling (with one player there is no other) |
| `0x9032` | the life object against the second sprite: they do not touch, and it moves one pixel |
| `0x821A` | takes a life (from 2 to 1) and draws the duel score line |
| `0x8275` | makes Q\*bert fall dead: state 12 and the falling arc |
| `0x6757` | the pattern viewer |

## Running it

```
tools/lanza_vuelca.sh work/v1 "6 12" "10"
tools/lanza_fase.sh "11 0 0 3"
tools/lanza_prueba.sh tools/pruebas/vida.txt
tools/lanza_huerfanos.sh
make coteja
```
