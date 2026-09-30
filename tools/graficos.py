#!/usr/bin/env python3
"""Los formatos graficos del cartucho, leidos desde la ROM con codigo nuestro.

  - rle(): el RLE de 0x46A6 / 0x46A0. 0x00 acaba, 0x01-0x7F repite el byte
    siguiente, 0x81-0xFF copia (n - 0x80) literales y 0x80 cambia de direccion
    con la palabra que sigue.
  - guion(): el guion de texto de 0x4685 / 0x871C: direccion, casillas, 0xFE
    salta a otra direccion y 0xFF acaba.

Todo devuelve tambien la direccion donde ACABA el dato, que es lo que fija
los limites de las directivas D del .notes.
"""
ORG = 0x4000


def b(rom, a):
    return rom[a - ORG]


def w(rom, a):
    return rom[a - ORG] | (rom[a - ORG + 1] << 8)


def rle(rom, a, destino=None):
    """Devuelve ({direccion_vram: byte}, direccion_de_fin_exclusiva).

    Con destino=None la direccion viene en los dos primeros bytes (0x46A0);
    si no, es la que se pasa (0x46A6, con HL puesto por quien llama)."""
    out = {}
    if destino is None:
        destino = w(rom, a)
        a += 2
    d = destino
    while True:
        n = b(rom, a)
        a += 1
        if n == 0:
            return out, a
        if n == 0x80:
            d = w(rom, a)
            a += 2
        elif n & 0x80:
            for _ in range(n & 0x7F):
                out[d] = b(rom, a)
                a += 1
                d += 1
        else:
            v = b(rom, a)
            a += 1
            for _ in range(n):
                out[d] = v
                d += 1


def rle_tres_bancos(rom, a, destino):
    """0x4675: el mismo guion RLE en HL, HL+0x800 y HL+0x1000."""
    out = {}
    for k in range(3):
        o, fin = rle(rom, a, destino + 0x800 * k)
        out.update(o)
    return out, fin


def guion(rom, a, c=0xFF):
    """0x4685 con C: devuelve ({direccion: casilla}, fin)."""
    out = {}
    d = w(rom, a)
    a += 2
    while True:
        v = b(rom, a)
        a += 1
        if v == 0xFF:
            return out, a
        if v == 0xFE:
            d = w(rom, a)
            a += 2
            continue
        out[d] = v & c
        d += 1


def literal(rom, a):
    """0x8724: casillas seguidas hasta 0xFF, sin direccion."""
    out = []
    while b(rom, a) != 0xFF:
        out.append(b(rom, a))
        a += 1
    return out, a + 1


LETRAS = {0x00: " ", 0x1A: "(c)", 0x1B: "<", 0x1C: ">", 0x20: "-"}


def texto(casillas):
    s = ""
    for t in casillas:
        if t in LETRAS:
            s += LETRAS[t]
        elif 0x10 <= t <= 0x19:
            s += chr(0x30 + t - 0x10)
        elif 0x21 <= t <= 0x3A:
            s += chr(t + 0x20)
        else:
            s += "{%02X}" % t
    return s


if __name__ == "__main__":
    import sys
    rom = open(sys.argv[1], "rb").read()
    for x in sys.argv[2:]:
        tipo, a = x.split(":")
        a = int(a, 16)
        if tipo == "rle":
            o, f = rle(rom, a)
        elif tipo == "rle3":
            o, f = rle(rom, a, 0)
        elif tipo == "g":
            o, f = guion(rom, a)
        print("%s 0x%04X -> fin 0x%04X, %d bytes escritos, destino %s" % (
            tipo, a, f, len(o), ("0x%04X-0x%04X" % (min(o), max(o))) if o else "-"))
