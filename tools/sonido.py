#!/usr/bin/env python3
"""Recorre los datos de sonido tal como los lee el motor de 0x4CCC.

  - 0x52E2: una palabra por canal. Un efecto (0x01-0x16) usa una entrada; una
    musica, tres seguidas (0x4C91), y el 0x56, cuatro.
  - Cada canal arranca en modo musica (+0E=1). 0xFE 0x00 cambia de modo,
    0xFE 0xFF dir llama a una subrutina, 0xFE N dir es un bucle y 0xFF acaba.
  - Modo musica: [0xDX] [0xFX yy] [0xE8|0xEF]* [0xE0-0xE7|0xE9-0xEE] nota.
  - Modo efecto: [0x2X dd [e1 e2 si bit 3]] [0x1X] v|hi lo  (0x20 dd: silencio)
  - 0x50A4: los instrumentos (1 y 2); cada uno, trece punteros (uno por nota, del 0 al 12) a
    pasos en formato efecto acabados en 0xFF.

Devuelve que bytes toca cada cosa, para fijar los limites de las D.

Uso: sonido.py <rom>
"""
import sys

ORG = 0x4000
TABLA = 0x52E2
INSTR = 0x50A4


class Lector:
    def __init__(self, rom):
        self.rom = rom
        self.tocados = {}           # direccion -> quien

    def b(self, a):
        return self.rom[a - ORG]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def marca(self, a, n, quien):
        for i in range(n):
            self.tocados.setdefault(a + i, quien)

    def canal(self, a, quien, modo=1, visto=None):
        """Recorre un canal desde a; devuelve la direccion del 0xFF final."""
        if visto is None:
            visto = set()
        while True:
            if a in visto:
                return a
            visto.add(a)
            v = self.b(a)
            if v == 0xFF:
                self.marca(a, 1, quien)
                return a
            if v == 0xFE:
                p = self.b(a + 1)
                if p == 0x00:
                    self.marca(a, 2, quien)
                    modo ^= 1
                    a += 2
                    continue
                if p == 0xFF:
                    self.marca(a, 4, quien)
                    self.canal(self.w(a + 2), quien + "/sub", modo)
                    a += 4
                    continue
                self.marca(a, 4, quien)
                a += 4
                continue
            if modo == 1:
                a = self.evento_musica(a, quien)
            else:
                a = self.evento_efecto(a, quien)

    def evento_musica(self, a, quien):
        ini = a
        if self.b(a) & 0xF0 == 0xD0:
            a += 1
        if self.b(a) >= 0xF0:
            a += 2
        while self.b(a) in (0xE8, 0xEF):
            a += 1
        if 0xE0 <= self.b(a) <= 0xEE:
            a += 1
        a += 1                              # la nota
        self.marca(ini, a - ini, quien)
        return a

    def evento_efecto(self, a, quien):
        ini = a
        v = self.b(a)
        if v & 0xF0 == 0x20:
            a += 2
            if v == 0x20:
                self.marca(ini, a - ini, quien)
                return a
            if v & 0x08:
                a += 2
        if self.b(a) & 0xF0 == 0x10:
            a += 1
        a += 2
        self.marca(ini, a - ini, quien)
        return a

    def instrumentos(self):
        """Los que se pueden pedir con 0xE9-0xEE: su tabla y sus 12 notas."""
        out = []
        n = 1
        while True:
            p = self.w(INSTR + 2 * n)
            if p <= INSTR + 2 * n:      # la tabla acaba donde empieza la primera
                break
            out.append((n, INSTR + 2 * n, p))
            n += 1
            if INSTR + 2 * n >= min(x[2] for x in out):
                break
        for n, e, p in out:
            self.marca(e, 2, "instr%d" % n)
            # trece como mucho (notas 0 a 12), y la tabla acaba donde empieza
            # la primera de sus secuencias: el 1 tiene doce y el 2, trece
            notas = []
            for k in range(13):
                if notas and p + 2 * k >= min(notas):
                    break
                notas.append(self.w(p + 2 * k))
            self.marca(p, 2 * len(notas), "instr%d" % n)
            for k, q in enumerate(notas):
                self.canal(q, "instr%d.%d" % (n, k), modo=0)
            print("instrumento %d: %d notas" % (n, len(notas)))
        return out

    def sonidos(self):
        """Las entradas de 0x52E2, hasta donde empieza la primera secuencia."""
        ents = []
        k = 1
        tope = 0x10000
        while TABLA + 2 * k < tope:
            p = self.w(TABLA + 2 * k)
            ents.append((k, p))
            tope = min(tope, p)
            k += 1
        for k, p in ents:
            self.marca(TABLA + 2 * k, 2, "tabla")
            self.canal(p, "s%02X" % k)
        return ents


def main():
    rom = open(sys.argv[1], "rb").read()
    L = Lector(rom)
    ins = L.instrumentos()
    ents = L.sonidos()
    print("instrumentos:", ["%d@%04X->%04X" % x for x in ins])
    print("entradas de 0x52E2: 1..%d (0x%04X-0x%04X)" % (
        len(ents), TABLA + 2, TABLA + 2 * len(ents) + 2))
    ds = sorted(L.tocados)
    print("tocado: 0x%04X-0x%04X, %d bytes" % (ds[0], ds[-1] + 1, len(ds)))
    # huecos dentro del rango
    huecos = []
    a = ds[0]
    while a <= ds[-1]:
        if a not in L.tocados:
            b = a
            while b not in L.tocados:
                b += 1
            huecos.append((a, b))
            a = b
        a += 1
    for a, b in huecos:
        print("  hueco 0x%04X-0x%04X (%d): %s" % (a, b, b - a,
              rom[a - ORG:b - ORG].hex(" ")))


if __name__ == "__main__":
    main()
