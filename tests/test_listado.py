"""Lo que se afirma del cartucho, comprobado contra sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Sin el
cartucho solo se comprueba lo que cae en datos.
"""

import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "qbert.rom")
ASM = os.path.join(RAIZ, "src", "qbert.asm")
ORG = 0x4000
TAM = 32768

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


class Cabecera(unittest.TestCase):
    def test_es_un_cartucho_msx_de_32k(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(len(rom), TAM)

    def test_init_es_405e(self):
        rom = lee()
        self.assertEqual(rom[2] | (rom[3] << 8), 0x405E)

    def test_solo_usa_init(self):
        """STATEMENT, DEVICE y TEXT a cero."""
        self.assertEqual(lee()[4:10], b"\x00" * 6)

    def test_la_del_game_master_es_rc_746(self):
        """"CD", 0x07 de los RC-7xx y 0x46 de RC-746."""
        self.assertEqual(lee()[0x10:0x14], b"CD\x07\x46")


class TablasDelDespachador(unittest.TestCase):
    """Las tablas pegadas detras de un `call 0x4054`.

    Ninguna entrada puede caer dentro de la tabla: la mas baja marca donde
    acaba, porque el codigo al que apunta viene justo detras.
    """

    TABLAS = {0x40E3: 9, 0x6D35: 15, 0x7328: 4, 0x7628: 15}

    def entradas(self, ini, n):
        rom = lee()
        p = ini - ORG
        return [rom[p + 2 * i] | (rom[p + 2 * i + 1] << 8) for i in range(n)]

    def test_toda_entrada_cae_dentro_del_cartucho(self):
        for ini, n in self.TABLAS.items():
            for e in self.entradas(ini, n):
                self.assertTrue(ORG <= e < ORG + TAM,
                                f"tabla 0x{ini:04X}: 0x{e:04X} se sale")

    def test_ninguna_entrada_cae_dentro_de_su_tabla(self):
        for ini, n in self.TABLAS.items():
            fin = ini + 2 * n
            for e in self.entradas(ini, n):
                self.assertFalse(ini <= e < fin,
                                 f"tabla 0x{ini:04X}: 0x{e:04X} cae dentro")

    def test_cada_tabla_cierra_donde_apunta_su_entrada_mas_baja(self):
        """Salvo la de 0x7628: detras de ella, en 0x7646, empieza una rutina
        que se llama con `call` desde otro sitio, y su entrada mas baja es
        0x76DF."""
        for ini, n in self.TABLAS.items():
            if ini == 0x7628:
                continue
            self.assertEqual(min(self.entradas(ini, n)), ini + 2 * n)
        self.assertEqual(min(self.entradas(0x7628, 15)), 0x76DF)


if __name__ == "__main__":
    unittest.main()
