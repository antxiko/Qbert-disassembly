# The cartridge

32 KB with no mapper, in pages 1 and 2 (`0x4000`-`0xBFFF`). INIT puts page 2
in the same slot as page 1 (`0x405E`), and writes 1, 2 and 3 to `0x6000`,
`0x8000` and `0xA000`, the bank writes of Konami's mappers, which do nothing
here.

## The headers

`0x4000`: "AB" and INIT at `0x405E`. `0x4010`: the Konami Game Master header,
"CD" and RC-746, with seven fields: the scene variable and the level menu scene
(`0xE000`, 3), the stage the Game Master picks and how many there are
(`0xE114`, 50), the lives (`0xE110`), the high score (`0xE105`), the score
(`0xE10B`), a second score the game never reads (`0xE108`) and the mode bits
(`0xE002`).

## The ROM map

| from | to | what |
|---|---|---|
| `0x4025` | `0x50A6` | the framework, the scenes, the score line, the controls, the font, the logos and the sound engine |
| `0x50A6` | `0x61DD` | the sound data: two instruments, 93 entries and the sequences |
| `0x61DD` | `0x9093` | the game: the stage, the jumps, the cubes, the creatures, the duel, the intro |
| `0x90A7` | `0x97DB` | the graphics of the duel and of rock, paper, scissors |
| `0x97DB` | `0xA7AD` | the 50 boards of 9 × 9 |
| `0xA7AD` | `0xA7FE` | the bonus board |
| `0xA7FE` | `0xAABC` | the cubes: 3 styles of 26 cubes of 3 × 3 cells |
| `0xAABC` | `0xAFBC` | the sprites of the creatures and of Q\*bert |
| `0xAFBC` | `0xB09A` | the tiles of the spinning cubes and the finished cube |
| `0xB09A` | `0xBFE7` | the intro and the menus, in RLE |
| `0xBFF6` | `0xC000` | Konami's hidden mark |

The whole split, byte by byte, is in `src/qbert.notes`: the code is 11,743
bytes and the data 21,025, and not one is left unexplained.

## The RAM

| address | what |
|---|---|
| `0xE000` / `0xE001` | the scene and its step |
| `0xE002` | the mode: bit 6 game, bit 5 duel, bit 0 bonus |
| `0xE003` | the frame counter |
| `0xE008` / `0xE009` | joystick 1: just pressed and held |
| `0xE010`-`0xE08F` | the four sound channels |
| `0xE105`-`0xE107` | the high score, in BCD |
| `0xE10B`-`0xE10D` | the score, in BCD |
| `0xE110` / `0xE111` | the lives and the stage, in BCD |
| `0xE200`-`0xE2BF` | 24 objects of 8 bytes: the two Q\*berts (two sprites each) and the creatures |
| `0xE2C0` | the ten slots of the spinning cubes |
| `0xE32F` / `0xE330` | joystick 2 |
| `0xEB00` | the 26 cubes of the stage's style |
| `0xEC00` | the 9 × 9 board; bit 6 marks the first player's finished cubes and bit 5 the second's |
| `0xEC51` | the time, in BCD |
| `0xED00`-`0xEFFF` | the copy of the name table |

Each object: state, speed, state again, arc step, Y, X, pattern and colour. The
states are at `0x6D35`.

## The VRAM

SCREEN 2 with the registers at `0x46F0`: names at `0x3800`, patterns at
`0x2000`, colour at `0x0000`, sprite attributes at `0x3B00` and sprite patterns
at `0x1800`, with 16 × 16 sprites.

Tiles 0 to 15 have a blank pattern and colour 0x00-0x0F: each one is a solid
block of that colour, and they are the cubes' **faces**. Tiles 0x40-0x87 all
carry the same triangle (`0x6286`) with two colours each (`0x628E`): they are
the **edges**. A 3 × 3 cube is a combination of faces and edges.

## The formats

- **The VRAM RLE** (`0x46A0`): 0x00 ends, 0x01-0x7F repeats the next byte,
  0x81-0xFF copies literals and 0x80 changes the address.
- **The text script** (`0x4685`): a name table address and the characters; 0xFE
  jumps to another address and 0xFF ends. With the mask at zero it erases the
  same text. `0x871C` is the same but writes to the RAM copy.
- **The sound** (`0x4D2D` and `0x4E0F`): two modes, effect (volume and period
  per step) and music (notes with octave, length, decay and instrument), and
  0xFE for loops and subroutines.

`tools/graficos.py` and `tools/sonido.py` read all three, and every data block
in the listing ends exactly where its format ends.
