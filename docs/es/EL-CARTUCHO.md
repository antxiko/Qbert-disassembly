# El cartucho

32 KB sin mapeador, en las páginas 1 y 2 (`0x4000`-`0xBFFF`). INIT pone la
página 2 en la misma ranura que la 1 (`0x405E`), y escribe 1, 2 y 3 en
`0x6000`, `0x8000` y `0xA000`, las escrituras de banco de los mapeadores de
Konami, que aquí no hacen nada.

## Las cabeceras

`0x4000`: "AB" e INIT en `0x405E`. `0x4010`: la cabecera del Konami Game
Master, "CD" y RC-746, con siete campos: la variable de escena y la escena del
menú de nivel (`0xE000`, 3), la fase que elige el Game Master y cuántas hay
(`0xE114`, 50), las vidas (`0xE110`), el récord (`0xE105`), la puntuación
(`0xE10B`), un segundo marcador que el juego no lee (`0xE108`) y los bits de
modo (`0xE002`).

## El mapa de la ROM

| desde | hasta | qué |
|---|---|---|
| `0x4025` | `0x50A6` | el armazón, las escenas, el marcador, los mandos, la fuente, los logotipos y el motor de sonido |
| `0x50A6` | `0x61DD` | los datos de sonido: dos instrumentos, 93 entradas y las secuencias |
| `0x61DD` | `0x9093` | el juego: la fase, los saltos, los cubos, los bichos, el duelo, la presentación |
| `0x90A7` | `0x97DB` | los gráficos del duelo y del piedra-papel-tijera |
| `0x97DB` | `0xA7AD` | los 50 tableros de 9 × 9 |
| `0xA7AD` | `0xA7FE` | el tablero de la bonificación |
| `0xA7FE` | `0xAABC` | los cubos: 3 estilos de 26 cubos de 3 × 3 casillas |
| `0xAABC` | `0xAFBC` | los sprites de los bichos y de Q\*bert |
| `0xAFBC` | `0xB09A` | los tiles de los cubos que giran y del cubo acabado |
| `0xB09A` | `0xBFE7` | la presentación y los menús, en RLE |
| `0xBFF6` | `0xC000` | la marca oculta de Konami |

El reparto entero, byte a byte, está en `src/qbert.notes`: el código son 11.743
bytes y los datos 21.025, y no queda ninguno sin explicar.

## La RAM

| dirección | qué |
|---|---|
| `0xE000` / `0xE001` | la escena y su paso |
| `0xE002` | el modo: bit 6 partida, bit 5 duelo, bit 0 bonificación |
| `0xE003` | el contador de cuadros |
| `0xE008` / `0xE009` | el mando 1: recién pulsado y pulsado |
| `0xE010`-`0xE08F` | los cuatro canales de sonido |
| `0xE105`-`0xE107` | el récord, en BCD |
| `0xE10B`-`0xE10D` | la puntuación, en BCD |
| `0xE110` / `0xE111` | las vidas y la fase, en BCD |
| `0xE200`-`0xE2BF` | 24 objetos de 8 bytes: los dos Q\*bert (dos sprites cada uno) y los bichos |
| `0xE2C0` | los diez huecos de los cubos que giran |
| `0xE32F` / `0xE330` | el mando 2 |
| `0xEB00` | los 26 cubos del estilo de la fase |
| `0xEC00` | el tablero de 9 × 9; el bit 6 marca los cubos acabados del primero y el 5 los del segundo |
| `0xEC51` | el tiempo, en BCD |
| `0xED00`-`0xEFFF` | la copia de la tabla de nombres |

Cada objeto: estado, velocidad, estado otra vez, paso del arco, Y, X, patrón y
color. Los estados están en `0x6D35`.

## La VRAM

SCREEN 2 con los registros de `0x46F0`: nombres en `0x3800`, patrones en
`0x2000`, color en `0x0000`, atributos de sprites en `0x3B00` y patrones de
sprites en `0x1800`, con sprites de 16 × 16.

Los tiles 0 a 15 tienen el patrón a cero y el color 0x00-0x0F: cada uno es un
bloque macizo de ese color, y son las **caras** de los cubos. Los tiles
0x40-0x87 llevan todos el mismo triángulo (`0x6286`) con dos colores cada uno
(`0x628E`): son las **aristas**. Un cubo de 3 × 3 casillas es una combinación de
caras y aristas.

## Los formatos

- **El RLE de la VRAM** (`0x46A0`): 0x00 acaba, 0x01-0x7F repite el byte
  siguiente, 0x81-0xFF copia literales y 0x80 cambia de dirección.
- **El guion de texto** (`0x4685`): una dirección de la tabla de nombres y los
  caracteres; 0xFE salta a otra dirección y 0xFF acaba. Con la máscara a cero
  borra el mismo rótulo. `0x871C` es igual pero escribe en la copia de la RAM.
- **El sonido** (`0x4D2D` y `0x4E0F`): dos modos, efecto (volumen y periodo por
  paso) y música (notas con octava, duración, decaimiento e instrumento), y
  0xFE para bucles y subrutinas.

`tools/graficos.py` y `tools/sonido.py` leen los tres, y cada bloque de datos
del listado acaba exactamente donde acaba su formato.
