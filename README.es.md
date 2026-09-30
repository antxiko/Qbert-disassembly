# Q\*bert (MSX) — desensamblado comentado

*(Also available [in English](README.md).)*

Desensamblado comentado de ***Q\*bert*** (キューバート), Konami, 1986, cartucho
**RC-746** para **MSX1**: 32 KB sin mapeador en las páginas 1 y 2.

**La web**: https://antxiko.github.io/Qbert-disassembly/es/

| | |
|---|---|
| explicado | 100 % (11.743 bytes de código, 21.025 de datos) |
| comentado | 78,1 % de las instrucciones |
| rutinas | 444 con nombre, ninguna por debajo del 10 % |
| reensamblado | la ROM, byte a byte |
| imágenes | dibujadas desde la ROM; nueve pantallas cotejadas contra openMSX, 0 diferencias |

## Qué hay

- El listado (`src/qbert.asm`), que se genera desde el binario y las notas y
  reensambla la ROM exacta.
- Las 50 fases, la bonificación y el duelo, montados desde los tableros de
  9 × 9 y los cubos de la ROM.
- Q\*bert en todas sus poses, los quince objetos, el moái, las manos del
  piedra-papel-tijera y los logotipos.
- Cómo funciona: los cubos ruedan como dados, la fase se acaba con cinco en
  línea, el duelo se desempata a piedra, papel o tijera, hay una vida
  escondida y F5 es el CONTINUE.

## Cómo reproducirlo

Hace falta Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) y **tu propia
imagen del cartucho** como `qbert.rom` en la raíz:

```
sha256  bd253f3285b3bf31501cd34f593f35ed3b9adfc6eb44c360c6fd59f8ab2c3684
make
```

Los detalles, en [Empezar](docs/es/EMPEZAR.md).

## Aviso

El juego es de Konami; aquí solo están el análisis, los comentarios y las
herramientas. La ROM no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).
