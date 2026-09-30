# The code

The listing is `src/qbert.asm`: 5,939 instructions, 4,636 of them commented
(78.1%), 788 routines (444 with their own name), no routine below 10% and no `call` target without
a name. It reassembles byte for byte.

## The framework

INIT leaves a `jp` in H.KEYI and sits in a `jr $`: **the whole game runs in
the VDP interrupt** (`0x4025`). Every frame the sound plays; the scene only
runs if the previous frame finished (`0xE005`), with interrupts enabled so the
sound is never lost.

The framework is the one in The Goonies and Yie Ar Kung-Fu II:
`tools/porta_nombres.py` finds here, by instruction signature, their script,
RLE and font routines. The sound engine and the game belong to this cartridge.

## The scenes

`0x40C5` dispatches on `0xE000` with the table at `0x40E3`:

| scene | what |
|---|---|
| 0 | the Konami logo, uncovered line by line |
| 1 | the intro: Q\*bert at the arcade machine, the title and 1PLAYER/2PLAYERS |
| 2 | the demo |
| 3 | the level menu |
| 4 | the start of a stage: LEVEL, STAGE or READY, and building it |
| 5 | the game |
| 6 | TIME OVER or GAME OVER |
| 7 | GAME OVER, with the F5 CONTINUE |
| 8 | stage cleared: the next one, or the bonus stage |

Each scene is a chain of `djnz` on its step (`0xE001`). Since `djnz` with B=0
gives 0xFF and jumps, **step 0 is the last block of the chain**: every scene
starts with the block that sets it up.

Without a game, the scene returns to `0x441E`, which checks for a key press: on
the logo or the demo it jumps to the title; on the title, the directions change
option and the trigger starts.

## The game

`0x68E6` is the game frame: the sprite table (with the planes rotating every
frame to share the flicker when there are more than four on a line), a quarter
of the name table, one of the four line checks (rows, columns and both
diagonals, one per frame), the controls of both Q\*berts, the collisions, the
movement of the 24 objects, the spinning cubes, the hidden life and, if there
is no green ball, the creatures' release, their decisions and the time.

Objects move according to their state (`0x6D35`): still, jumping left or right,
coming in from the top, falling off a side, going down to the row at `0xE29C`,
running away or falling dead. The jump follows one of the five arcs at
`0x6F9E` (normal, long and falling dead) and moves X by one and two pixels in
turn: one column of cubes every 16 steps.

When Q\*bert lands, `0x708E` spins the cube: it takes one of the ten animation
slots, paints nine tiles with the colours of the faces taken from two templates
(`0x727A`, `0x729F`) and eight frames later `0x715A` leaves the new rotation and
checks whether it now matches the model.

## The sound

Four channels of 0x20 bytes: the three of the PSG and an effects one that, when
it plays, takes over the third one's registers. Sounds 0x01 to 0x16 are
one-channel effects; from 0x17 on, three-channel tunes that use three
consecutive entries of the table at `0x52E2`. 0x56 is the pause: before playing
it saves the channels, and they come back when the pause ends.

## The code that never runs

Twelve pieces nobody reaches, declared as such in `src/qbert.entries` and
run in openMSX (see [In the emulator](IN-THE-EMULATOR.md)): a pattern viewer (`0x6757`), two copies of the key reading (`0x705E`,
`0x7068`), the VRAM read (`0x4643`), a byte swap (`0x45FD`), three duel
leftovers (`0x821A`, `0x8275`, `0x833C`) and four more. And a dead loop at
`0x44A5`: the Game Master stage checked right after being cleared.
