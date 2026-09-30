# Open questions

What comes from the code but has not been played, and what is not settled.

- **Two and three lines.** That two lines are needed from stage 31 and three
  from 41 comes from `0x7391`-`0x73A6`; it has not been played.
- **The whole duel.** The sets, the collision between the two Q\*berts
  (`0x7646`) and rock, paper, scissors come from the code; the PON! screen is
  built from the ROM but not checked.
- **The row at `0xE29C`.** The six coloured creatures that stay on a cube of
  their colour move into a row of five objects (19 to 23) and object 23 comes
  down with their colour (state 5, `0x750D`). What that row draws on screen has
  not been seen.
- **The green ball and `0x00BC`.** That the `ld hl,000BCh` at `0x7763` was meant
  to be `0xE2BC` is an assumption: the effect it would have has not been
  tested.
- **The PERFECT.** The 27 bonus cubes and their 5,000 points come from the code.
- **The sounds.** The engine and the data are read in full, but there is no list
  of what each of the 93 is beyond what the code that asks for it says (0x11 the
  extra life, 0x17 the stage tune, 0x47 stage cleared, 0x53 GAME OVER, 0x56 the
  pause, 0x59 silence…).
- **`0xE108`.** The Game Master header gives it as a second score; the game
  neither reads nor writes it outside the clearing at `0x4475`.
