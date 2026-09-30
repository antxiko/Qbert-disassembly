"""Lo que la web cuenta del juego, atado a los bytes del cartucho.

Con el cartucho delante se lee el cartucho; sin el, se reensambla el listado
con pasmo, que da los mismos 32.768 bytes (lo comprueba `make verify`).
"""

import os
import sys
import unittest
from collections import deque

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "qbert.rom")
ORG = 0x4000


_IMAGEN = []


def rom():
    if not _IMAGEN:
        if os.path.exists(ROM):
            with open(ROM, "rb") as f:
                _IMAGEN.append(f.read())
        else:
            import subprocess
            import tempfile
            sal = os.path.join(tempfile.mkdtemp(), "qbert.bin")
            subprocess.run(["pasmo", "--bin", os.path.join(RAIZ, "src", "qbert.asm"), sal],
                           check=True, capture_output=True)
            with open(sal, "rb") as f:
                _IMAGEN.append(f.read())
    return _IMAGEN[0]


def b(r, a, n=1):
    return r[a - ORG:a - ORG + n]


class Tableros(unittest.TestCase):
    def test_cincuenta_fases_de_9x9(self):
        """0x6630: 0x97DB + 81 * fase, y la ultima acaba donde empieza la
        bonificacion."""
        self.assertEqual(0x97DB + 50 * 81, 0xA7AD)

    def test_cada_casilla_es_hueco_o_uno_de_los_24_giros(self):
        r = rom()
        for n in range(50):
            t = b(r, 0x97DB + 81 * n, 81)
            for c in t:
                self.assertTrue(c == 0xFF or c < 24, "fase %d: %02X" % (n + 1, c))

    def test_la_bonificacion_tiene_27_cubos(self):
        """0x7924 espera la cuenta 0x28: 27 cubos mas el 1 de salida."""
        t = b(rom(), 0xA7AD, 81)
        self.assertEqual(sum(1 for c in t[1:] if c != 0xFF), 27)
        self.assertEqual(b(rom(), 0x7925, 2), bytes([0xFE, 0x28]))


class Giros(unittest.TestCase):
    def tabla(self):
        r = b(rom(), 0x72C0, 96)
        return [list(r[4 * i:4 * i + 4]) for i in range(24)]

    def test_cada_direccion_es_una_permutacion(self):
        t = self.tabla()
        for k in range(4):
            self.assertEqual(sorted(t[i][k] for i in range(24)), list(range(24)))

    def test_cualquier_giro_a_cuatro_saltos_como_mucho(self):
        t = self.tabla()
        peor = 0
        for s in range(24):
            d = {s: 0}
            q = deque([s])
            while q:
                u = q.popleft()
                for v in t[u]:
                    if v not in d:
                        d[v] = d[u] + 1
                        q.append(v)
            self.assertEqual(len(d), 24)
            peor = max(peor, max(d.values()))
        self.assertEqual(peor, 4)


class CincoEnLinea(unittest.TestCase):
    def test_cinco_seguidos(self):
        """0x742F: `cp 005h` sobre la cuenta de seguidos."""
        self.assertEqual(b(rom(), 0x742F, 2), bytes([0xFE, 0x05]))

    def test_una_dos_o_tres_lineas(self):
        """0x739D `cp 031h` y 0x73A2 `cp 041h`: dos lineas desde la 31 y
        tres desde la 41."""
        r = rom()
        self.assertEqual(b(r, 0x739D, 2), bytes([0xFE, 0x31]))
        self.assertEqual(b(r, 0x73A2, 2), bytes([0xFE, 0x41]))


class Detalles(unittest.TestCase):
    def test_vidas_fase_y_umbral_de_salida(self):
        self.assertEqual(b(rom(), 0x44B8, 3), bytes([3, 1, 1]))

    def test_la_vida_extra_sube_de_cinco_en_cinco(self):
        """0x4515: `add a,005h / daa` sobre el umbral."""
        self.assertEqual(b(rom(), 0x4515, 3), bytes([0xC6, 0x05, 0x27]))

    def test_las_demostraciones_son_la_34_y_la_37(self):
        r = rom()
        self.assertEqual(b(r, 0x6B65, 2), bytes([0x3E, 0x34]))
        self.assertEqual(b(r, 0x6B71, 2), bytes([0x3E, 0x37]))

    def test_la_bola_verde_escribe_en_0x00bc(self):
        """0x7763: `ld hl,000BCh`, en la ROM de la BIOS."""
        self.assertEqual(b(rom(), 0x7763, 3), bytes([0x21, 0xBC, 0x00]))

    def test_continue_con_f5(self):
        """0x4380: fila 7 del teclado y el bit 1, que es F5."""
        self.assertEqual(b(rom(), 0x4380, 7),
                         bytes([0x3E, 0x07, 0xCD, 0x41, 0x01, 0xCB, 0x4F]))

    def test_la_marca_de_konami(self):
        r = rom()
        self.assertEqual(b(r, 0xBFF6, 10),
                         bytes([0x93, 0xBA, 0xB7, 0x99, 0xBA, 0xB2, 0x86, 0x07, 0x46, 0xAA]))


class Formatos(unittest.TestCase):
    def test_la_fuente_son_43_tiles_y_acaba_en_0x4920(self):
        import graficos
        o, fin = graficos.rle_tres_bancos(rom(), 0x47EF, 0x2080)
        self.assertEqual(fin, 0x4920)
        self.assertEqual(len([d for d in o if 0x2000 <= d < 0x2800]), 43 * 8)

    def test_el_logotipo_de_konami_son_126_tiles(self):
        import graficos
        o, fin = graficos.rle(rom(), 0x4982)
        self.assertEqual((fin, len(o)), (0x4AE4, 126 * 8))

    def test_el_sonido_se_recorre_entero(self):
        """tools/sonido.py toca los 4.407 bytes de 0x50A6-0x61DD sin un
        hueco."""
        import sonido
        L = sonido.Lector(rom())
        L.instrumentos()
        L.sonidos()
        toc = set(L.tocados)
        self.assertEqual(toc, set(range(0x50A6, 0x61DD)))

    def test_las_pantallas_se_montan(self):
        import pantallas
        r = rom()
        for n in (1, 11, 21, 31, 50):
            p, tab = pantallas.fase(r, n)
            self.assertEqual(len(p.v), 0x4000)
        pantallas.titulo(r)
        pantallas.logotipo_konami(r)
        pantallas.bonificacion(r, 3)


if __name__ == "__main__":
    unittest.main()
