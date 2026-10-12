#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `toca_sonido` (0x4C4C, A = numero; `toca_sonido_en_partida`,
0x4C41, solo suena en partida) y corre `suena_un_cuadro` (0x4CCC), que la
interrupcion llama cada cuadro. Cuatro voces de 32 bytes desde 0xE010; la copia
del registro 7 del PSG, en 0xE0F0. El cartucho es de 32 KB, sin mapper.
Uso:  musica.py registros 0x20 [cuadros] | mp3 0x20 f.mp3 | todas docs/audio
      musica.py barrido 0x00 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x20, "La presentación", "The presentation",
      "`empieza_la_presentacion`"),
    P(0x1D, "El menú", "The menu", "`menu_de_un_jugador` y `menu_del_duelo`"),
    P(0x1A, "La bonificación", "The bonus", "`empieza_la_bonificacion`"),
    P(0x23, "El paso 6 de la presentación", "Presentation step 6",
      "`presentacion_paso_6`"),
    P(0x29, "Quién gana", "Who wins", "`apunta_quien_gana`"),
    P(0x2C, "Acaba el efecto", "The effect ends", "`acaba_el_efecto`"),
    P(0x32, "Acaba la cuenta", "The count ends", "`acaba_la_cuenta`"),
    P(0x53, "Game over (un jugador)", "Game over (one player)",
      "`musica_de_game_over`"),
    P(0x50, "Game over (el duelo)", "Game over (the duel)",
      "`musica_de_game_over`, con dos jugadores"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x12, 0x13, 0x1E, 0x1F, 0x21, 0x22, 0x24, 0x25, 0x26, 0x27,
               0x28, 0x2B, 0x3F, 0x42, 0x45, 0x48, 0x4B, 0x4E, 0x4F, 0x51,
               0x52)]

PAGINA = motor_musica.pagina_basica(
    "`suena_un_cuadro`, 0x4CCC, y `toca_sonido`, 0x4C4C, que le reparte los "
    "canales; lo llama la interrupción",
    "`suena_un_cuadro`, 0x4CCC, and `toca_sonido`, 0x4C4C, which hands it the "
    "channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("la presentación (0x20) entera, 416 cuadros",
      "the presentation (0x20), whole, 416 frames"),
     ("el menú (0x1D) entero, 757 cuadros, con su vuelta",
      "the menu (0x1D), whole, 757 frames, with its repeat")],
    [("Cómo se pide una pieza",
      "`toca_sonido` recibe el número en A y guarda todos los registros; "
      "`toca_sonido_en_partida` solo suena en partida. Aquí los números no "
      "llevan el bit 7: los bajos son efectos y del 0x12 en adelante hay "
      "música, de más voces cuanto más alto. Cada voz ocupa treinta y dos "
      "bytes desde 0xE010 (son cuatro) y 0xE0F0 guarda la copia del "
      "mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la "
      "tabla» están en la tabla de pistas pero ninguna rutina las pide con "
      "un `ld a`; se omiten otras, de minutos de duración.",
      "How a piece is asked for",
      "`toca_sonido` takes the number in A and saves all registers; "
      "`toca_sonido_en_partida` only sounds during a game. Here the numbers "
      "have no bit 7: low ones are effects and from 0x12 up there is music, "
      "with more voices the higher the number. Each voice takes thirty-two "
      "bytes from 0xE010 (there are four) and 0xE0F0 holds the copy of the "
      "PSG mixer, which start-up leaves at 0xB8. The tracks marked «in the "
      "table» are in the track table but no routine asks for them with an "
      "`ld a`; others, minutes long, are left out.")])

CFG = dict(rom="qbert.rom", org=0x4000, frame=0x4CCC, pide=0x4C4C,
           ram=(0xE010, 0xE0F4), ram0=[(0xE0F0, 0xB8)],
           excluye=[0xE019, 0xE039, 0xE059, 0xE079], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x20, 416, None), (0x1D, 757, 379)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
