# Empezar

Para reproducir este desensamblado hace falta Python 3, GNU make y
[Pasmo](https://pasmo.speccy.org/). La imagen del cartucho **no viaja en este
repositorio**: cada cual pone la suya.

```
qbert.rom    32.768 bytes
sha256       bd253f3285b3bf31501cd34f593f35ed3b9adfc6eb44c360c6fd59f8ab2c3684
```

Con el fichero en la raíz del repositorio:

```
make            # listado, verificación, coherencia y tests
```

## Qué hace cada paso

| orden | qué hace |
|---|---|
| `make comprueba` | comprueba el sha256 de la ROM |
| `make listado` | traza el flujo y genera `src/qbert.asm` desde el binario y las notas |
| `make verify` | reensambla el listado y compara el sha256 con el de la ROM |
| `make sanity` | comprueba que ningún dato sale como código y que no queda un byte sin asignar |
| `make test` | los tests |
| `make densidad` | cuántas instrucciones llevan comentario, rutina a rutina |
| `make imagenes` | dibuja las imágenes de la web desde la ROM |
| `make coteja` | coteja esas pantallas con los volcados de openMSX |
| `make web` | genera las páginas HTML y comprueba los enlaces |

`make verify` es el que decide: tiene que acabar con `OK: reproducible byte a
byte`.

## Dónde está cada cosa

| fichero | qué es |
|---|---|
| `src/qbert.notes` | los nombres, los comentarios y los bloques de datos, anclados a dirección |
| `src/qbert.entries` | los puntos de entrada que el trazado no puede deducir, cada uno con su porqué |
| `src/qbert.nocode` | las zonas que no son código aunque el trazado pueda entrar |
| `src/qbert.asm` | el listado comentado, generado |
| `tools/z80trace.py`, `tools/mkasm.py` | el trazador y el generador del listado |
| `tools/graficos.py` | los dos formatos del cartucho: el RLE de la VRAM y los guiones de texto |
| `tools/sonido.py` | recorre los datos de sonido tal como los lee el motor |
| `tools/pantallas.py`, `tools/imagenes.py` | montan cada pantalla desde las tablas y la pintan |
| `tools/coteja.py`, `tools/coteja_todo.py` | el cotejo con los volcados de openMSX |
| `tools/omsx_*.tcl`, `tools/lanza_*.sh` | las sondas de openMSX: ver [En el emulador](EN-EL-EMULADOR.md) |

Las páginas: [El juego](EL-JUEGO.md), [El cartucho](EL-CARTUCHO.md),
[El código](EL-CODIGO.md), [Hallazgos](HALLAZGOS.md),
[En el emulador](EN-EL-EMULADOR.md) y [Preguntas abiertas](PREGUNTAS-ABIERTAS.md).
