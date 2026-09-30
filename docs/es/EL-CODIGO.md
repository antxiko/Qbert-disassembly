# El código

El listado es `src/qbert.asm`: 5.939 instrucciones, 4.636 con comentario
(78,1 %), 444 rutinas con nombre, ninguna rutina por debajo del 10 % y ningún
destino de `call` sin nombre. Reensambla byte a byte.

## El armazón

INIT deja un `jp` en H.KEYI y se queda en un `jr $`: **todo el juego corre en
la interrupción** del VDP (`0x4025`). En cada cuadro suena el sonido; la escena
solo corre si el cuadro anterior acabó (`0xE005`), con las interrupciones
abiertas para que el sonido no se pierda.

El armazón es el de The Goonies y Yie Ar Kung-Fu II: `tools/porta_nombres.py`
encuentra aquí, por firma de instrucciones, sus rutinas de guion, de RLE y de
fuente. El motor de sonido y el juego son de este cartucho.

## Las escenas

`0x40C5` reparte por `0xE000` con la tabla de `0x40E3`:

| escena | qué |
|---|---|
| 0 | el logotipo de Konami, que se destapa línea a línea |
| 1 | la presentación: Q\*bert en la recreativa, el título y 1PLAYER/2PLAYERS |
| 2 | la demostración |
| 3 | el menú de nivel |
| 4 | el principio de fase: LEVEL, STAGE o READY, y el montaje |
| 5 | la partida |
| 6 | TIME OVER o GAME OVER |
| 7 | GAME OVER, con el CONTINUE de F5 |
| 8 | fase acabada: la siguiente, o la bonificación |

Cada escena es una cadena de `djnz` sobre su paso (`0xE001`). Como `djnz`
con B=0 da 0xFF y salta, **el paso 0 es el último bloque de la cadena**: cada
escena empieza por el bloque que la prepara.

Sin partida, la escena vuelve a `0x441E`, que mira si se pulsa algo: en el
logotipo o la demostración salta al título; en el título, las direcciones
cambian de opción y el disparo empieza.

## La partida

`0x68E6` es el cuadro de juego: la tabla de sprites (con los planos rotando
cada cuadro para repartir el parpadeo cuando hay más de cuatro en una línea),
un cuarto de la tabla de nombres, una de las cuatro comprobaciones de línea
(filas, columnas y las dos diagonales, una por cuadro), los mandos de los dos
Q\*bert, los choques, el movimiento de los 24 objetos, los cubos que giran, la
vida escondida, y, si no hay bola verde, la salida de los bichos, sus
decisiones y el tiempo.

Los objetos se mueven según su estado (`0x6D35`): quieto, saltando a la
izquierda o a la derecha, entrando por arriba, cayendo por un lado, bajando a
la fila de `0xE29C`, huyendo o cayendo muerto. El salto sigue uno de los cinco
arcos de `0x6F9E` (normal, largo y el de caer muerto) y avanza la X uno y dos
píxeles alternos: una columna de cubos cada 16 pasos.

Al posarse Q\*bert, `0x708E` hace girar el cubo: toma uno de los diez huecos de
animación, pinta nueve tiles con los colores de las caras sacados de dos
plantillas (`0x727A`, `0x729F`) y ocho cuadros después `0x715A` deja el giro
nuevo y mira si ya es como el modelo.

## El sonido

Cuatro canales de 0x20 bytes: los tres del PSG y uno de efectos que, cuando
suena, se queda con los registros del tercero. Los sonidos del 0x01 al 0x16 son
efectos de un canal; de 0x17 en adelante, músicas de tres canales que usan tres
entradas seguidas de la tabla de `0x52E2`. El 0x56 es la pausa: antes de sonar
guarda los canales, y al quitar la pausa vuelven.

## El código que no se ejecuta

Doce trozos a los que no llega nadie, declarados como tales en
`src/qbert.entries`: un visor de patrones (`0x6757`), dos copias de la lectura
de teclas (`0x705E`, `0x7068`), la lectura de VRAM (`0x4643`), un intercambio
de bytes (`0x45FD`), tres restos del duelo (`0x821A`, `0x8275`, `0x833C`)
y otros cuatro. Y un bucle muerto en `0x44A5`: la fase del Game Master
comprobada justo después de borrarla.
