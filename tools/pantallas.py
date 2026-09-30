#!/usr/bin/env python3
"""Monta en Python la VRAM de cada pantalla leyendo las tablas del cartucho.

No se ejecuta el juego: cada funcion hace lo mismo que la rutina del cartucho
que se cita, con los datos de la ROM. Lo que sale se coteja byte a byte contra
los volcados de openMSX (coteja.py); las imagenes publicadas salen de aqui.

    fase(rom, n)             la fase n (1-50) recien montada: 0x61DD
    bonificacion(rom)        la fase de bonificacion: 0x7A0B + 0x61E0
    logotipo_konami(rom)     la escena 0 destapada: 0x4920 + 0x494E
    titulo(rom)              el titulo: 0x4AEA
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import ORG, b, w, rle, rle_tres_bancos, guion, literal  # noqa: E402

REGS = [0x02, 0xE2, 0x0E, 0x7F, 0x07, 0x76, 0x03, 0xE4]     # 0x46F0
NOMBRES = 0x3800
SAT = 0x3B00


def bloque(rom, a, n):
    return rom[a - ORG:a - ORG + n]


class Pantalla:
    def __init__(self, rom):
        self.rom = rom
        self.v = bytearray(0x4000)
        self.copia = bytearray(0x300)           # 0xED00-0xEFFF
        self.regs = list(REGS)

    # --- volcados a la VRAM, como 0x464D / 0x4651 / 0x4664 / 0x4675 ---
    def copia_vram(self, dst, datos):
        self.v[dst:dst + len(datos)] = datos

    def tres_bancos(self, dst, datos):
        for k in range(3):
            self.copia_vram(dst + 0x800 * k, datos)

    def rellena_tres(self, dst, n, valor):
        for k in range(3):
            self.v[dst + 0x800 * k:dst + 0x800 * k + n] = bytes([valor]) * n

    def aplica(self, escrito):
        for d, x in escrito.items():
            self.v[d & 0x3FFF] = x

    def rle3(self, a, dst):
        self.aplica(rle_tres_bancos(self.rom, a, dst)[0])

    def rle(self, a, dst=None):
        self.aplica(rle(self.rom, a, dst)[0])

    def guion_vram(self, a):
        self.aplica(guion(self.rom, a)[0])

    def guion_copia(self, a, c=0xFF):
        for d, x in guion(self.rom, a, c)[0].items():
            self.copia[d - 0xED00] = x

    def vuelca_copia(self, desde=0x20):
        """0x6246: de 0xED20 a 0x3820 (filas 1 a 23)."""
        self.v[NOMBRES + desde:NOMBRES + 0x300] = self.copia[desde:0x300]

    # --- rutinas del cartucho ---
    def monta_la_fuente(self):
        """0x47CE + 0x47B7."""
        self.rellena_tres(0x2000, 0x80, 0)
        for n in range(16):
            self.rellena_tres(8 * n, 8, n)
        self.rle3(0x47EF, 0x2080)
        self.rellena_tres(0x0080, 0x158, 0xF0)

    def graficos_de_la_fase(self, estilo):
        """0x6642."""
        tri = bloque(self.rom, 0x6286, 8)
        for i in range(72):
            self.tres_bancos(0x2200 + 8 * i, tri)
        cols = bloque(self.rom, 0x628E + 0x48 * estilo, 0x48)
        for i, c in enumerate(cols):
            self.rellena_tres(0x0200 + 8 * i, 8, c)
        for k in range(5):
            self.tres_bancos(0x2488 + 0x48 * k, bloque(self.rom, 0xB004, 0x48))
            self.tres_bancos(0x25F0 + 0x48 * k, bloque(self.rom, 0xAFBC, 0x48))
        self.tres_bancos(0x2440, bloque(self.rom, 0xB04C, 0x48))
        self.tres_bancos(0x2708, bloque(self.rom, 0xB04C, 0x48))
        self.rle3(0xB094, 0x0440)
        self.rle3(0xB097, 0x0708)
        for dst, src, n in ((0x1800, 0xACBC, 0x100), (0x1D80, 0xACBC, 0x100),
                            (0x1980, 0xAABC, 0x40), (0x1A80, 0xAAFC, 0x40),
                            (0x1C80, 0xAB3C, 0x40), (0x1CC0, 0xAB3C, 0x40),
                            (0x1B80, 0xAB7C, 0x40), (0x1E80, 0xABBC, 0x40),
                            (0x1D00, 0xABFC, 0x40), (0x1E80, 0xABBC, 0x40),
                            (0x1C00, 0xAC3C, 0x40)):
            self.copia_vram(dst, bloque(self.rom, src, n))

    def monta_el_marco(self):
        """0x7ABF."""
        self.tres_bancos(0x2758, bloque(self.rom, 0x7BA5, 0x68))
        self.rle3(0x7C0D, 0x0758)
        c = self.copia
        for i in range(32):
            c[i] = 0xEB
            c[0x2E0 + i] = 0xEB
        for f in range(22):
            c[0x20 + 32 * f] = 0xEB
            c[0x3F + 32 * f] = 0xEB
        for dst, src, n, paso in ((0x21, 0x7B41, 30, 1), (0x2C1, 0x7B5F, 30, 1),
                                  (0x41, 0x7B7D, 20, 32), (0x5E, 0x7B91, 20, 32)):
            for i in range(n):
                c[dst + paso * i] = b(self.rom, src + i)

    def corazones(self):
        """0x836A."""
        self.tres_bancos(0x27E0, bloque(self.rom, 0x8384, 16))
        self.rle3(0x837F, 0x07E0)


def estilo_de_la_fase(n):
    """0x6252: la decena de n-1."""
    d = (n - 1) // 10
    return 0 if d == 0 else (1 if d == 1 else 2)


def tablero(rom, n):
    """0x6630: los 81 bytes de la fase n (1-50)."""
    return bytearray(bloque(rom, 0x97DB + 81 * (n - 1), 81))


def caras(cubos, i):
    """0x7250: la cara de arriba y las dos de lado del cubo i."""
    return cubos[9 * i + 1], cubos[9 * i + 3], cubos[9 * i + 5]


def dibuja_el_tablero(p, tab, cubos, duelo=False):
    """0x6366 / 0x63AA sobre la copia de la tabla de nombres."""
    p.copia[:] = bytes(0x300)
    for fila in range(9):
        for col in range(9):
            k = 9 * fila + col
            a = tab[k]
            if a == 0xFF:
                continue
            a &= 0x1F
            if k > 1:                       # las casillas 0 y 1 son los modelos
                if caras(cubos, a) == caras(cubos, tab[0] & 0x1F):
                    tab[k] |= 0x40
                    a = 0x18
                elif tab[1] != 0xFF and caras(cubos, a) == caras(cubos, tab[1] & 0x1F):
                    tab[k] |= 0x20
                    a = 0x19
            base = 0x63 + 64 * fila + 3 * col
            for r in range(3):
                for c in range(3):
                    p.copia[base + 32 * r + c] = cubos[9 * a + 3 * r + c]
    if duelo:
        p.copia[0x44], p.copia[0x45] = 0x11, 0x30
        p.copia[0x47], p.copia[0x48] = 0x12, 0x30


def bcd(v):
    return int("%d" % v, 16)


def pinta_bcd(p, dst, bytes_bcd):
    """0x45E2: dos cifras por byte, la alta primero."""
    for x in bytes_bcd:
        p.v[dst] = (x >> 4) + 0x10
        p.v[dst + 1] = (x & 0x0F) + 0x10
        dst += 2


def objetos_de_salida(rom, dificultad):
    """0x6456: los 24 objetos de 8 bytes."""
    ob = [bytearray(8) for _ in range(24)]
    for i in range(24):
        ob[i][0] = b(rom, 0x64DB + 24 * dificultad + i)
        ob[i][4] = b(rom, 0x6583 + i)
        ob[i][5] = b(rom, 0x659B + i)
        ob[i][6] = b(rom, 0x65B3 + i)
        ob[i][7] = b(rom, 0x65CB + i)
    return ob


def fase(rom, n, vidas=2, tiempo=0x99, puntos=0, duelo=False, turno=0,
         objetos=None, bonus=False):
    """La fase n recien montada por 0x61DD, con el marcador de 0x4567."""
    p = Pantalla(rom)
    p.regs[7] = 0xE0
    tab = tablero(rom, n) if not bonus else bytearray(bloque(rom, 0xA7AD, 81))
    if not duelo:
        tab[1] = 0xFF
    estilo = estilo_de_la_fase(n)
    p.monta_la_fuente()
    p.graficos_de_la_fase(estilo)
    cubos = bloque(rom, 0xA7FE + 234 * estilo, 234)
    dibuja_el_tablero(p, tab, cubos, duelo)
    p.monta_el_marco()
    p.corazones()
    # el tiempo, 0x7878
    t = [0x34, 0x29, 0x2D, 0x25, 0x20, (tiempo >> 4) + 0x10, (tiempo & 15) + 0x10]
    p.copia[0x57:0x57 + 7] = bytes(t)
    p.vuelca_copia()
    if duelo:
        # el del duelo, 0x4575: fila 0 de ladrillo, 2P- y 1P- con sus vidas
        p.v[NOMBRES:NOMBRES + 32] = bytes([0xEB]) * 32
        p.guion_vram(0x4591)
        pinta_bcd(p, 0x3805, [vidas])
        pinta_bcd(p, 0x381C, [vidas])
    else:
        # el marcador, 0x4567
        p.guion_vram(0x4607)
        pinta_bcd(p, 0x3808, [bcd(n)])
        pinta_bcd(p, 0x3812, [(puntos >> 16) & 0xFF, (puntos >> 8) & 0xFF,
                              puntos & 0xFF])
        pinta_bcd(p, 0x381C, [vidas])
    if bonus:
        p.guion_vram(0x79A3)                # BONUS arriba, 0x78DC
    # los sprites: Q*bert en el primer cubo de su columna (0x64C3)
    ob = objetos_de_salida(rom, (n - 1) // 10)
    y, x = ob[0][4], ob[0][5]
    while tab[9 * ((y - 12) >> 4) + (x - 24) // 24] == 0xFF:
        y += 16
    for i in (0, 1):
        ob[i][4] = y
    if duelo:
        # 0x64B1: el segundo, desde Y=0x0C en su columna
        y, x = 0x0C, ob[2][5]
        while tab[9 * ((y - 12) >> 4) + (x - 24) // 24] == 0xFF:
            y += 16
        for i in (2, 3):
            ob[i][4] = y
    if objetos is not None:
        ob = [bytearray(objetos[8 * i:8 * i + 8]) for i in range(24)]
    p.copia_vram(SAT, sprites_turnados(ob, turno))
    # planos 19 y 20: el objeto de la vida, fuera (0x9069 + 0x907E)
    p.copia_vram(SAT + 4 * 19, bytes([0xE0, 0, 0, 0, 0xE0, 0, 0, 0]))
    # planos 21 a 25: los objetos 19 a 23 (0x69F7)
    for k in range(5):
        p.copia_vram(SAT + 4 * (21 + k), ob[19 + k][4:8])
    return p, tab


def sprites_turnados(ob, turno):
    """0x69D4: los planos 0 y 1 fijos (el segundo sprite de cada Q*bert) y
    los otros 17 en un anillo que empieza cada cuadro un puesto mas alla.
    `turno` es el puesto del primero: (0xE343) - 1 tras el cuadro."""
    fijos = ob[1][4:8] + ob[3][4:8]
    anillo = [ob[i][4:8] for i in [0, 2] + list(range(4, 19))]
    orden = [None] * 17
    for k, s in enumerate(anillo):
        orden[(turno + k) % 17] = s
    return fijos + b"".join(orden)


def logotipo_konami(rom):
    """Escena 0 al acabar de destapar: 0x4920 con los colores a 0xF0 (0x494E)."""
    p = Pantalla(rom)
    p.monta_la_fuente()
    p.rle(0x4982)
    for fila in range(6):
        for i in range(21):
            p.v[NOMBRES + 0x107 + 32 * fila + i] = 0x40 + 21 * fila + i
            p.v[0x0A00 + 8 * (21 * fila + i):0x0A00 + 8 * (21 * fila + i) + 8] = b"\xF0" * 8
    p.v[SAT] = 0xD0
    return p


def titulo(rom):
    """0x4AEA: la recreativa, el rotulo, (c)KONAMI y el menu. Se monta
    encima de la VRAM que deja el logotipo de Konami (escena 0), porque entre
    una y otra solo se borra la tabla de nombres: los tiles del logotipo que
    el RLE de 0xB09A no pisa siguen con su color 0xF0."""
    p = logotipo_konami(rom)
    p.v[NOMBRES:NOMBRES + 0x300] = bytes(0x300)
    p.regs = list(REGS)
    p.regs[7] = 0xE0
    p.monta_la_fuente()
    p.rle(0xB09A)                           # 0x8394
    ob = bytearray(bloque(rom, 0x88D8, 0x4D))
    # 0x4B40 en 0xED45: el rotulo
    hl = 0x45
    a = 0x4B95
    for k in range(8):
        cas, a = literal(rom, a)
        for i, x in enumerate(cas):
            p.copia[hl + i] = x
        hl += len(cas) + (14 if k == 6 else 9)
    # 0x8547
    p.guion_copia(0x8849)
    ob[0:2] = bytes([0x8F, 0x50])
    ob[4:6] = bytes([0x9F, 0x58])
    ob[8:10] = bytes([0x6F, 0x88])
    ob[0x24:0x26] = bytes([0x7F, 0x80])
    ob[0x28:0x2A] = bytes([0x29, 0x65])
    ob[0x2B] = 0x08                         # 0x4B08
    p.vuelca_copia()
    p.copia_vram(SAT, ob[:0x2D])
    p.guion_vram(0x4790)                    # (c)KONAMI 1986 y 1PLAYER
    p.guion_vram(0x47A9)                    # 2PLAYERS
    return p


def bonificacion(rom, n=3, **k):
    """La fase de bonificacion que sale detras de la fase n (0x79AE): su
    tablero (0xA7AD) con los cubos del estilo de esa fase y BONUS arriba."""
    return fase(rom, n, bonus=True, **k)


def graficos_del_duelo(p):
    """0x8C86 + 0x8CA1(0x3000): sprites, tiles 0x43-0x4B y los 186 del tercer
    tercio, con los 45 ultimos reflejados 45 tiles mas alla."""
    rom = p.rom
    p.rle(0x96BA)
    p.rle3(0x90A7, 0x2218)
    p.rle3(0x90DE, 0x0218)
    p.rle(0x90E3, 0x3000)
    p.rle(0x95EB, 0x1000)
    for i in range(0x168):
        x = p.v[0x3468 + i]
        p.v[0x35D0 + i] = int("{:08b}".format(x)[::-1], 2)
        p.v[0x15D0 + i] = p.v[0x1468 + i]


def jan_ken(rom, izquierda, derecha):
    """El PON! del paso 7 (0x8A36): el recuadro, las dos manos (0x8B3C con
    la de la izquierda, 0-2, y la de la derecha, 3-5) y sus rotulos."""
    p = Pantalla(rom)
    p.regs[7] = 0xE0
    p.monta_la_fuente()
    graficos_del_duelo(p)
    p.monta_el_marco()
    c = p.copia                                     # 0x7E5A
    for i in range(0x2FF):
        c[i] = 0xEB
    for f in range(18):
        for k in range(30):
            c[0x61 + 32 * f + k] = 0
    p.monta_el_marco()
    p.guion_copia(0x8D3D)                           # 0x8C7D
    p.guion_copia(0x8C2C)                           # 0x89A8
    p.guion_copia(0x8DC4)
    p.guion_copia(w(rom, 0x8B49 + 2 * izquierda))
    p.guion_copia(w(rom, 0x8B49 + 2 * (derecha + 3)))
    p.guion_copia(0x8C21)
    p.vuelca_copia()
    p.v[SAT] = 0xD0
    return p


def casillas_del_rotulo(rom):
    """Las (fila, columna) que 0x4B40 escribe desde 0xED45: el rotulo."""
    out = []
    hl = 0x45
    a = 0x4B95
    for k in range(8):
        cas, a = literal(rom, a)
        for i in range(len(cas)):
            out.append(((hl + i) // 32, (hl + i) % 32))
        hl += len(cas) + (14 if k == 6 else 9)
    return out


def visor(p):
    """0x6757, el visor de patrones que no llama nadie: cada casilla de la
    tabla de nombres con el byte bajo de su direccion (0, 1, 2... 255, tres
    veces). Enseña los 768 tiles cargados, tercio a tercio."""
    for i in range(0x300):
        p.v[NOMBRES + i] = (NOMBRES + i) & 0xFF
    return p
