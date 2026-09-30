#!/usr/bin/env python3
"""Coteja una pantalla montada desde la ROM (pantallas.py) contra un volcado
de VRAM de openMSX, byte a byte.

Se compara lo que se VE: la tabla de nombres entera; de cada tercio, el patron
y el color de los tiles que su tabla de nombres usa; los sprites que el VDP
pinta (hasta el primer 0xD0) y sus patrones. Lo que queda en la VRAM de
pantallas anteriores y no se usa no cuenta.

Uso como modulo: diferencias(montada, volcado, filas=range(24), sprites=True)
"""
NOMBRES, SAT, SPR = 0x3800, 0x3B00, 0x1800


def diferencias(a, v, filas=range(24), sprites=True, sin_sat=False):
    """Lista de (que, direccion, nuestro, volcado)."""
    out = []
    for f in filas:
        for c in range(32):
            d = NOMBRES + 32 * f + c
            if a[d] != v[d]:
                out.append(("nombre", d, a[d], v[d]))
    usados = {}
    for f in filas:
        for c in range(32):
            usados.setdefault(f // 8, set()).add(v[NOMBRES + 32 * f + c])
    for banco, tiles in usados.items():
        for t in sorted(tiles):
            for base, que in ((0x2000, "patron"), (0x0000, "color")):
                d = base + 0x800 * banco + 8 * t
                for i in range(8):
                    if a[d + i] != v[d + i]:
                        out.append((que, d + i, a[d + i], v[d + i]))
    if sprites:
        for plano in range(32):
            d = SAT + 4 * plano
            if v[d] == 0xD0:
                break
            if not sin_sat:
                for i in range(4):
                    if a[d + i] != v[d + i]:
                        out.append(("sprite", d + i, a[d + i], v[d + i]))
            if v[d] >= 0xC0 and v[d] != 0xFF and v[d] < 0xE0:
                continue
            pat = v[d + 2] & 0xFC
            for i in range(32):
                q = SPR + 8 * pat + i
                if a[q] != v[q]:
                    out.append(("sprite_patron", q, a[q], v[q]))
    return out


def resumen(nombre, difs):
    if not difs:
        print("%-28s 0 diferencias" % nombre)
        return True
    tipos = {}
    for t, *_ in difs:
        tipos[t] = tipos.get(t, 0) + 1
    print("%-28s %d diferencias: %s" % (nombre, len(difs), tipos))
    for t, d, x, y in difs[:12]:
        print("    %-14s 0x%04X  nuestro %02X  volcado %02X" % (t, d, x, y))
    return False
