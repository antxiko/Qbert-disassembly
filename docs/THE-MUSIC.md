# The music

Everything you hear here comes from running the cartridge's own sound engine (`suena_un_cuadro`, 0x4CCC, and `toca_sonido`, 0x4C4C, which hands it the channels; the interrupt calls it) on an emulated Z80, frame by frame at 60 per second, just as the game calls it. What the engine writes to the PSG is turned into sound with an AY-3-8910 (`tools/musica.py`). Each MP3 is the whole piece up to where it starts again, plus 8 seconds of the repeat fading out; those that do not repeat end where the engine ends.

## Checked against openMSX

The PSG writes have been compared frame by frame with those of openMSX (C-BIOS MSX1 japonés). In every frame the PSG ends up the same:

- the presentation (0x20), whole, 416 frames;
- the menu (0x1D), whole, 757 frames, with its repeat.

The timbre is not checked: it is a textbook AY-3-8910, not a recording of the emulator. The probes are `tools/omsx_psg.tcl` and `tools/coteja_psg.py`.

## How a piece is asked for

`toca_sonido` takes the number in A and saves all registers; `toca_sonido_en_partida` only sounds during a game. Here the numbers have no bit 7: low ones are effects and from 0x12 up there is music, with more voices the higher the number. Each voice takes thirty-two bytes from 0xE010 (there are four) and 0xE0F0 holds the copy of the PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the table» are in the track table but no routine asks for them with an `ld a`; others, minutes long, are left out.

## The tunes

**The presentation** (0x20)

Asked for by `empieza_la_presentacion`; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_20.mp3?v=6e81513b"></audio>

**The menu** (0x1D)

Asked for by `menu_de_un_jugador` y `menu_del_duelo`; lasts 12.6 s and starts again at second 6.3.

<audio controls preload="none" src="audio/musica_1D.mp3?v=dcd5b772"></audio>

**The bonus** (0x1A)

Asked for by `empieza_la_bonificacion`; lasts 19.2 s and starts again at second 0.0.

<audio controls preload="none" src="audio/musica_1A.mp3?v=c8712561"></audio>

**Presentation step 6** (0x23)

Asked for by `presentacion_paso_6`; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_23.mp3?v=6cf823c7"></audio>

**Who wins** (0x29)

Asked for by `apunta_quien_gana`; lasts 4.6 s.

<audio controls preload="none" src="audio/musica_29.mp3?v=bd1321e4"></audio>

**The effect ends** (0x2C)

Asked for by `acaba_el_efecto`; lasts 1.4 s.

<audio controls preload="none" src="audio/musica_2C.mp3?v=3dcf9979"></audio>

**The count ends** (0x32)

Asked for by `acaba_la_cuenta`; lasts 2.4 s.

<audio controls preload="none" src="audio/musica_32.mp3?v=5b4bdea2"></audio>

**Game over (one player)** (0x53)

Asked for by `musica_de_game_over`; lasts 4.5 s.

<audio controls preload="none" src="audio/musica_53.mp3?v=6bd839f1"></audio>

**Game over (the duel)** (0x50)

Asked for by `musica_de_game_over`, con dos jugadores; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_50.mp3?v=93038d41"></audio>

**Table track 0x12** (0x12)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 3.6 s.

<audio controls preload="none" src="audio/musica_12.mp3?v=f9537d2a"></audio>

**Table track 0x13** (0x13)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.1 s.

<audio controls preload="none" src="audio/musica_13.mp3?v=bc59b700"></audio>

**Table track 0x1E** (0x1E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 13.2 s and starts again at second 6.9.

<audio controls preload="none" src="audio/musica_1E.mp3?v=765bbfa4"></audio>

**Table track 0x1F** (0x1F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 13.2 s and starts again at second 6.9.

<audio controls preload="none" src="audio/musica_1F.mp3?v=72f76554"></audio>

**Table track 0x21** (0x21)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_21.mp3?v=ba300e45"></audio>

**Table track 0x22** (0x22)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_22.mp3?v=678b1430"></audio>

**Table track 0x24** (0x24)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_24.mp3?v=0762afa6"></audio>

**Table track 0x25** (0x25)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_25.mp3?v=793e6cb4"></audio>

**Table track 0x26** (0x26)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_26.mp3?v=983d64ae"></audio>

**Table track 0x27** (0x27)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.4 s.

<audio controls preload="none" src="audio/musica_27.mp3?v=0054bea7"></audio>

**Table track 0x28** (0x28)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_28.mp3?v=03a64f04"></audio>

**Table track 0x2B** (0x2B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 4.6 s.

<audio controls preload="none" src="audio/musica_2B.mp3?v=49a0e89c"></audio>

**Table track 0x3F** (0x3F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.3 s.

<audio controls preload="none" src="audio/musica_3F.mp3?v=579ab14d"></audio>

**Table track 0x42** (0x42)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.0 s.

<audio controls preload="none" src="audio/musica_42.mp3?v=1f4b80de"></audio>

**Table track 0x45** (0x45)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 7.1 s.

<audio controls preload="none" src="audio/musica_45.mp3?v=73ae9574"></audio>

**Table track 0x48** (0x48)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.3 s.

<audio controls preload="none" src="audio/musica_48.mp3?v=daaa0a19"></audio>

**Table track 0x4B** (0x4B)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 5.2 s.

<audio controls preload="none" src="audio/musica_4B.mp3?v=f1cfd0b2"></audio>

**Table track 0x4E** (0x4E)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.6 s.

<audio controls preload="none" src="audio/musica_4E.mp3?v=e6dc5942"></audio>

**Table track 0x4F** (0x4F)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_4F.mp3?v=bfaac248"></audio>

**Table track 0x51** (0x51)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.9 s.

<audio controls preload="none" src="audio/musica_51.mp3?v=9f2dbbcf"></audio>

**Table track 0x52** (0x52)

Asked for by ninguna llamada directa: está en la tabla de pistas; lasts 6.6 s.

<audio controls preload="none" src="audio/musica_52.mp3?v=909dbfb5"></audio>
