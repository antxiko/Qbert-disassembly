#!/usr/bin/env python3
"""Las imagenes de la web, todas desde la ROM con pantallas.py.

Ni una captura: cada pantalla se monta con las tablas del cartucho y se pinta
con vram.py; las que tienen volcado de openMSX se cotejan en coteja_todo.py.

Uso: imagenes.py <rom> <directorio>
"""
import os
import sys
import zlib
import struct

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pantallas                                        # noqa: E402
import vram                                             # noqa: E402
from graficos import ORG                                # noqa: E402

PAL = vram.PALETA


# ----------------------------------------------------------------- lienzos
class Lienzo:
    def __init__(self, w, h, fondo=(0, 0, 0)):
        self.w, self.h = w, h
        self.px = bytearray(bytes(fondo) * (w * h))

    @classmethod
    def de_pantalla(cls, p, con_sprites=True):
        c = cls(256, 192)
        c.px = vram.pantalla(p.v, p.regs, con_sprites)
        return c

    def punto(self, x, y, rgb):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.px[i:i + 3] = bytes(rgb)

    def lee(self, x, y):
        i = (y * self.w + x) * 3
        return tuple(self.px[i:i + 3])

    def recorta(self, x, y, w, h):
        c = Lienzo(w, h)
        for j in range(h):
            i = ((y + j) * self.w + x) * 3
            c.px[j * w * 3:(j + 1) * w * 3] = self.px[i:i + w * 3]
        return c

    def pega(self, otro, x, y):
        for j in range(otro.h):
            if 0 <= y + j < self.h:
                i = ((y + j) * self.w + x) * 3
                self.px[i:i + otro.w * 3] = otro.px[j * otro.w * 3:(j + 1) * otro.w * 3]

    def escala(self, k):
        c = Lienzo(self.w * k, self.h * k)
        for y in range(c.h):
            fila = self.px[(y // k) * self.w * 3:(y // k + 1) * self.w * 3]
            out = bytearray()
            for x in range(self.w):
                out += fila[x * 3:x * 3 + 3] * k
            c.px[y * c.w * 3:(y + 1) * c.w * 3] = out
        return c

    def guarda(self, fn):
        raw = b"".join(b"\0" + bytes(self.px[y * self.w * 3:(y + 1) * self.w * 3])
                       for y in range(self.h))

        def trozo(t, d):
            return (struct.pack(">I", len(d)) + t + d
                    + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
        with open(fn, "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n")
            f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0)))
            f.write(trozo(b"IDAT", zlib.compress(raw, 9)))
            f.write(trozo(b"IEND", b""))


# ------------------------------------------------------------ las letras
def letra(rom, t, tinta=(255, 255, 255)):
    """Un caracter de la fuente de 0x47EF (tile t, 0x10-0x3A)."""
    import graficos
    pats, _ = graficos.rle_tres_bancos(rom, 0x47EF, 0x2080)
    c = Lienzo(8, 8)
    for y in range(8):
        v = pats.get(0x2000 + 8 * t + y, 0)
        for x in range(8):
            if v & (0x80 >> x):
                c.punto(x, y, tinta)
    return c


def texto(rom, s):
    tiles = []
    for ch in s:
        if ch.isdigit():
            tiles.append(0x10 + int(ch))
        elif ch == " ":
            tiles.append(None)
        elif ch == "-":
            tiles.append(0x20)
        else:
            tiles.append(ord(ch.upper()) - 0x20)
    c = Lienzo(8 * len(tiles), 8)
    for i, t in enumerate(tiles):
        if t is not None:
            c.pega(letra(rom, t), 8 * i, 0)
    return c


# ------------------------------------------------------------ los sprites
def sprite(rom, a, color, lienzo=None, x=0, y=0):
    """Un sprite de 16x16 de 32 bytes (cuartos: arriba-izq, abajo-izq,
    arriba-der, abajo-der) pintado con su color encima de lo que haya."""
    if lienzo is None:
        lienzo = Lienzo(16, 16)
    for q, (ox, oy) in enumerate(((0, 0), (0, 8), (8, 0), (8, 8))):
        for f in range(8):
            v = rom[a - ORG + 8 * q + f]
            for bit in range(8):
                if v & (0x80 >> bit):
                    lienzo.punto(x + ox + bit, y + oy + f, PAL[color])
    return lienzo


def figura(rom, capas, fondo=(0, 0, 0)):
    """Varios sprites superpuestos: [(direccion, color), ...], el primero
    debajo (como en el VDP, el plano de numero menor queda encima: aqui se
    pintan en orden y el ultimo es el de encima)."""
    c = Lienzo(16, 16, fondo)
    for a, col in capas:
        sprite(rom, a, col, c)
    return c


def hoja(figuras, por_fila, k=4, sep=6, fondo=(24, 24, 40)):
    filas = (len(figuras) + por_fila - 1) // por_fila
    w = por_fila * (16 + sep) + sep
    h = filas * (16 + sep) + sep
    c = Lienzo(w, h, fondo)
    for i, f in enumerate(figuras):
        c.pega(f, sep + (i % por_fila) * (16 + sep), sep + (i // por_fila) * (16 + sep))
    return c.escala(k)


# ------------------------------------------------------------------ todo
def main():
    rom = open(sys.argv[1], "rb").read()
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)

    # el logotipo de Konami: filas 8-13, columnas 7-27 de la escena 0
    k = Lienzo.de_pantalla(pantallas.logotipo_konami(rom))
    k.recorta(7 * 8 - 8, 8 * 8 - 8, 21 * 8 + 16, 6 * 8 + 16).escala(3).guarda(
        os.path.join(out, "logotipo-konami.png"))

    # el titulo y el rotulo de Q*bert (su marco: filas 2-8, columnas 5-27)
    t = pantallas.titulo(rom)
    tl = Lienzo.de_pantalla(t)
    tl.escala(3).guarda(os.path.join(out, "titulo.png"))
    # el recorte del rotulo se mide sobre las casillas que escribe 0x4B40 en
    # la copia de la tabla de nombres (desde 0xED45), no se pone a ojo
    cas = pantallas.casillas_del_rotulo(rom)
    f0, f1 = min(f for f, c in cas), max(f for f, c in cas)
    c0, c1 = min(c for f, c in cas), max(c for f, c in cas)
    # arriba sin margen: en la fila de encima esta (c)KONAMI 1986
    m = 4
    tl.recorta(c0 * 8 - m, f0 * 8, (c1 - c0 + 1) * 8 + 2 * m,
               (f1 - f0 + 1) * 8 + m).escala(3).guarda(os.path.join(out, "rotulo.png"))

    # las 50 fases
    laminas = []
    for n in range(1, 51):
        p, tab = pantallas.fase(rom, n)
        c = Lienzo.de_pantalla(p)
        c.escala(2).guarda(os.path.join(out, "fase-%02d.png" % n))
        laminas.append((n, c.recorta(16, 16, 224, 168)))
    # la lamina: diez por fila, con el numero en la fuente del cartucho
    ancho, alto = 224, 168 + 12
    L = Lienzo(10 * ancho + 11 * 8, 5 * alto + 6 * 8, (16, 16, 24))
    for i, (n, c) in enumerate(laminas):
        x = 8 + (i % 10) * (ancho + 8)
        y = 8 + (i // 10) * (alto + 8)
        L.pega(texto(rom, "%02d" % n), x, y)
        L.pega(c, x, y + 12)
    L.guarda(os.path.join(out, "fases.png"))

    # la bonificacion (detras de la fase 3) y el duelo (en la fase 31)
    p, tab = pantallas.bonificacion(rom, 3)
    Lienzo.de_pantalla(p).escala(2).guarda(os.path.join(out, "bonificacion.png"))
    p, tab = pantallas.fase(rom, 31, duelo=True)
    Lienzo.de_pantalla(p).escala(2).guarda(os.path.join(out, "duelo.png"))

    # Q*bert: dos sprites en el mismo sitio. El plano 0 (el de encima) es el
    # segundo, en magenta (13); debajo, el primero en amarillo oscuro (10).
    def qb(a1, a2, c1=10, c2=13):
        return figura(rom, [(a1, c1), (a2, c2)])
    poses = []
    for base in (0xACBC, 0xADBC):                   # izquierda y derecha
        for k4 in (0, 1, 2, 3):                     # 0x00, 0x04, 0x08, 0x0C
            poses.append(qb(base + 32 * k4, base + 0x80 + 32 * k4))
    for k4 in (0, 1):                               # cayendo por un lado
        poses.append(qb(0xAF3C + 32 * k4, 0xAF7C + 32 * k4))
    for k4 in (1, 2):                               # fase acabada
        poses.append(qb(0xAEBC + 32 * k4, 0xAEFC + 32 * k4))
    hoja(poses, 6).guarda(os.path.join(out, "qbert.png"))
    # el segundo Q*bert: los mismos dibujos, en amarillo oscuro y azul claro
    segundo = [qb(0xACBC + 32 * k4, 0xAD3C + 32 * k4, 10, 5) for k4 in (0, 1, 2, 3)]
    hoja(segundo, 4).guarda(os.path.join(out, "qbert-segundo.png"))

    # los quince objetos (4 a 18) con su color de 0x65CB; de cada uno, el
    # dibujo posado (su patron) y el del aire (patron + 4). El 0x80 tiene dos
    # juegos que se alternan (0x6739 y 0x6748)
    fuente = {0x30: 0xAABC, 0x50: 0xAAFC, 0x70: 0xAB7C, 0x80: 0xAC3C,
              0x90: 0xAB3C, 0xA0: 0xABFC}
    bichos = []
    for i in range(4, 19):
        pat = rom[0x65B3 - ORG + i]
        col = rom[0x65CB - ORG + i]
        bichos.append(figura(rom, [(fuente[pat], col)]))
        bichos.append(figura(rom, [(fuente[pat] + 32, col)]))
    hoja(bichos, 10).guarda(os.path.join(out, "bichos.png"))
    hoja([figura(rom, [(a, 10)]) for a in (0xAC3C, 0xAC5C, 0xAC7C, 0xAC9C)], 4).guarda(
        os.path.join(out, "moai.png"))
    # el objeto de la vida extra: 0xD0 rojo oscuro y 0xD4 blanco (0x9019)
    hoja([figura(rom, [(0xABBC, 6), (0xABDC, 15)])], 1, k=6).guarda(
        os.path.join(out, "vida-escondida.png"))
    # el piedra-papel-tijera (0x8A36): la pantalla del PON! y las tres manos
    # ampliadas: papel (0), tijera (1) y piedra (2)
    Lienzo.de_pantalla(pantallas.jan_ken(rom, 0, 2)).escala(2).guarda(
        os.path.join(out, "jan-ken.png"))
    M = Lienzo(56 * 3 + 16, 40, (16, 16, 24))
    for k in range(3):
        c = Lienzo.de_pantalla(pantallas.jan_ken(rom, k, k)).recorta(104, 136, 56, 40)
        M.pega(c, k * (56 + 8), 0)
    M.escala(4).guarda(os.path.join(out, "manos.png"))
    print("imagenes en", out)


if __name__ == "__main__":
    main()
