#!/usr/bin/env python3
"""Coteja las pantallas que monta pantallas.py contra los volcados de openMSX.

Los volcados no viajan con el repositorio (work/ no se publica). Se hacen con:
    tools/lanza_vuelca.sh work/v1 "6 12" "10"      logotipo de Konami y titulo
    tools/lanza_vuelca.sh work/v2 "23" "10 13 15.5 16"   la fase 1
    tools/lanza_fase.sh "11 0 0 3"   (y 21, 41, 50; "31 0 1 3" el duelo;
                                      "03 1 0 3" la bonificacion)
Cada volcado trae su RAM, y de ella salen el tiempo, las vidas, los objetos y
el turno de los sprites de ese cuadro.

Uso: coteja_todo.py <rom>   (sale con 1 si alguna tiene diferencias)
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import pantallas                                    # noqa: E402
import coteja                                       # noqa: E402


def lee(ruta):
    return open(ruta, "rb").read() if os.path.exists(ruta) else None


def main():
    rom = open(sys.argv[1], "rb").read()
    malas, hechas = 0, 0

    def prueba(nombre, ruta, monta):
        nonlocal malas, hechas
        v = lee(ruta + ".vram")
        if v is None:
            print("%-28s sin volcado (%s)" % (nombre, ruta))
            return
        r = lee(ruta + ".ram")
        hechas += 1
        if not coteja.resumen(nombre, coteja.diferencias(monta(r).v, v)):
            malas += 1

    def de_ram(r):
        return dict(vidas=r[0x110], tiempo=r[0xC51], turno=(r[0x343] - 1) % 17,
                    objetos=r[0x200:0x2C0])

    prueba("logotipo de Konami", "work/v1/t006", lambda r: pantallas.logotipo_konami(rom))
    prueba("titulo", "work/v1/t012", lambda r: pantallas.titulo(rom))
    prueba("fase 1", "work/v2/t023",
           lambda r: pantallas.fase(rom, 1, vidas=r[0x110], tiempo=r[0xC51],
                                    turno=(r[0x343] - 1) % 17)[0])
    for n in (11, 21, 41, 50):
        prueba("fase %d" % n, "work/fases/f%d/t03" % n,
               lambda r, n=n: pantallas.fase(rom, n, **de_ram(r))[0])
    prueba("duelo, fase 31", "work/fases/f31d/t03",
           lambda r: pantallas.fase(rom, 31, duelo=True, **de_ram(r))[0])
    prueba("bonificacion tras la 3", "work/fases/f03b/t03",
           lambda r: pantallas.bonificacion(rom, 3, **de_ram(r))[0])
    # el visor de 0x6757 (tools/omsx_huerfanos.tcl): los tiles que monta cada
    # pantalla; los de la fase y los del RLE de 0xB09A con la fuente
    import graficos
    fase_tiles = (list(range(0, 0x3B)) + list(range(0x40, 0x91))
                  + list(range(0xE1, 0xEA)) + list(range(0xEB, 0xF8)) + [0xFC, 0xFD])
    o, _ = graficos.rle(rom, 0xB09A)
    titulo_tiles = sorted(set(((d - 0x2000) % 0x800) // 8 for d in o
                              if 0x2000 <= d < 0x3800) | set(range(0x10, 0x3B)))
    for nombre, ruta, monta, tiles in (
            ("visor de 0x6757, fase 1", "work/huerfanos/t_6757_partida",
             lambda: pantallas.visor(pantallas.fase(rom, 1)[0]), fase_tiles),
            ("visor de 0x6757, titulo", "work/huerfanos/t_6757_titulo",
             lambda: pantallas.visor(pantallas.titulo(rom)), titulo_tiles)):
        v = lee(ruta + ".vram")
        if v is None:
            print("%-28s sin volcado (%s)" % (nombre, ruta))
            continue
        hechas += 1
        if not coteja.resumen(nombre, coteja.diferencias_en_tiles(monta().v, v, tiles)):
            malas += 1
    print("---- %d pantallas cotejadas, %d con diferencias" % (hechas, malas))
    return 1 if malas else 0


if __name__ == "__main__":
    sys.exit(main())
