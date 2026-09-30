# Preguntas abiertas

Lo que sale del código pero no se ha jugado, y lo que no está cerrado.

- **Dos y tres líneas.** Que desde la fase 31 hagan falta dos líneas y desde
  la 41 tres sale de `0x7391`-`0x73A6`; no se ha jugado.
- **El duelo entero.** El reparto de partidas, el choque entre los dos Q\*bert
  (`0x7646`) y el piedra-papel-tijera salen del código; la pantalla del PON!
  está montada desde la ROM pero no cotejada.
- **La fila de `0xE29C`.** Los seis bichos de colores que se quedan en un cubo
  de su color pasan a una fila de cinco objetos (19 a 23) y el 23 baja con su
  color (estado 5, `0x750D`). No se ha visto en pantalla qué dibuja esa fila.
- **La bola verde y `0x00BC`.** Que el `ld hl,000BCh` de `0x7763` quería ser
  `0xE2BC` es una suposición: el efecto que tendría no se ha probado.
- **El PERFECT.** Los 27 cubos de la bonificación y sus 5.000 puntos salen del
  código.
- **Los sonidos.** El motor y los datos están leídos enteros, pero no hay una
  lista de qué es cada uno de los 93 más allá de lo que dice el código que los
  pide (0x11 la vida extra, 0x17 la música de la fase, 0x47 la fase acabada,
  0x53 el GAME OVER, 0x56 la pausa, 0x59 el silencio…).
- **`0xE108`.** La cabecera del Game Master lo da como segundo marcador; el
  juego no lo lee ni lo escribe fuera del borrado de `0x4475`.
