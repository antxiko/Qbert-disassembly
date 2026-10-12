# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`suena_un_cuadro`, 0x4CCC, y `toca_sonido`, 0x4C4C, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- la presentación (0x20) entera, 416 cuadros;
- el menú (0x1D) entero, 757 cuadros, con su vuelta.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`toca_sonido` recibe el número en A y guarda todos los registros; `toca_sonido_en_partida` solo suena en partida. Aquí los números no llevan el bit 7: los bajos son efectos y del 0x12 en adelante hay música, de más voces cuanto más alto. Cada voz ocupa treinta y dos bytes desde 0xE010 (son cuatro) y 0xE0F0 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten otras, de minutos de duración.

## Las músicas

**La presentación** (0x20)

Lo pide `empieza_la_presentacion`; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_20.mp3?v=6e81513b"></audio>

**El menú** (0x1D)

Lo pide `menu_de_un_jugador` y `menu_del_duelo`; dura 12,6 s y vuelve a empezar en el segundo 6,3.

<audio controls preload="none" src="../audio/musica_1D.mp3?v=dcd5b772"></audio>

**La bonificación** (0x1A)

Lo pide `empieza_la_bonificacion`; dura 19,2 s y vuelve a empezar en el segundo 0,0.

<audio controls preload="none" src="../audio/musica_1A.mp3?v=c8712561"></audio>

**El paso 6 de la presentación** (0x23)

Lo pide `presentacion_paso_6`; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_23.mp3?v=6cf823c7"></audio>

**Quién gana** (0x29)

Lo pide `apunta_quien_gana`; dura 4,6 s.

<audio controls preload="none" src="../audio/musica_29.mp3?v=bd1321e4"></audio>

**Acaba el efecto** (0x2C)

Lo pide `acaba_el_efecto`; dura 1,4 s.

<audio controls preload="none" src="../audio/musica_2C.mp3?v=3dcf9979"></audio>

**Acaba la cuenta** (0x32)

Lo pide `acaba_la_cuenta`; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_32.mp3?v=5b4bdea2"></audio>

**Game over (un jugador)** (0x53)

Lo pide `musica_de_game_over`; dura 4,5 s.

<audio controls preload="none" src="../audio/musica_53.mp3?v=6bd839f1"></audio>

**Game over (el duelo)** (0x50)

Lo pide `musica_de_game_over`, con dos jugadores; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_50.mp3?v=93038d41"></audio>

**Pista 0x12 de la tabla** (0x12)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 3,6 s.

<audio controls preload="none" src="../audio/musica_12.mp3?v=f9537d2a"></audio>

**Pista 0x13 de la tabla** (0x13)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,1 s.

<audio controls preload="none" src="../audio/musica_13.mp3?v=bc59b700"></audio>

**Pista 0x1E de la tabla** (0x1E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 13,2 s y vuelve a empezar en el segundo 6,9.

<audio controls preload="none" src="../audio/musica_1E.mp3?v=765bbfa4"></audio>

**Pista 0x1F de la tabla** (0x1F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 13,2 s y vuelve a empezar en el segundo 6,9.

<audio controls preload="none" src="../audio/musica_1F.mp3?v=72f76554"></audio>

**Pista 0x21 de la tabla** (0x21)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_21.mp3?v=ba300e45"></audio>

**Pista 0x22 de la tabla** (0x22)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_22.mp3?v=678b1430"></audio>

**Pista 0x24 de la tabla** (0x24)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_24.mp3?v=0762afa6"></audio>

**Pista 0x25 de la tabla** (0x25)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_25.mp3?v=793e6cb4"></audio>

**Pista 0x26 de la tabla** (0x26)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_26.mp3?v=983d64ae"></audio>

**Pista 0x27 de la tabla** (0x27)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,4 s.

<audio controls preload="none" src="../audio/musica_27.mp3?v=0054bea7"></audio>

**Pista 0x28 de la tabla** (0x28)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_28.mp3?v=03a64f04"></audio>

**Pista 0x2B de la tabla** (0x2B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 4,6 s.

<audio controls preload="none" src="../audio/musica_2B.mp3?v=49a0e89c"></audio>

**Pista 0x3F de la tabla** (0x3F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,3 s.

<audio controls preload="none" src="../audio/musica_3F.mp3?v=579ab14d"></audio>

**Pista 0x42 de la tabla** (0x42)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_42.mp3?v=1f4b80de"></audio>

**Pista 0x45 de la tabla** (0x45)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 7,1 s.

<audio controls preload="none" src="../audio/musica_45.mp3?v=73ae9574"></audio>

**Pista 0x48 de la tabla** (0x48)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,3 s.

<audio controls preload="none" src="../audio/musica_48.mp3?v=daaa0a19"></audio>

**Pista 0x4B de la tabla** (0x4B)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 5,2 s.

<audio controls preload="none" src="../audio/musica_4B.mp3?v=f1cfd0b2"></audio>

**Pista 0x4E de la tabla** (0x4E)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,6 s.

<audio controls preload="none" src="../audio/musica_4E.mp3?v=e6dc5942"></audio>

**Pista 0x4F de la tabla** (0x4F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_4F.mp3?v=bfaac248"></audio>

**Pista 0x51 de la tabla** (0x51)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,9 s.

<audio controls preload="none" src="../audio/musica_51.mp3?v=9f2dbbcf"></audio>

**Pista 0x52 de la tabla** (0x52)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,6 s.

<audio controls preload="none" src="../audio/musica_52.mp3?v=909dbfb5"></audio>
