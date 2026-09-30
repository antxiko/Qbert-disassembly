# En el emulador

Las imágenes se montan desde la ROM, no se capturan. openMSX sirve para dos
cosas: **cotejar** esas imágenes con la VRAM de verdad y **probar** lo que dice
el código de la partida.

Todo con openMSX y la máquina `C-BIOS_MSX1_JP`, un emulador cada vez.

## El cotejo

`tools/omsx_vuelca.tcl` vuelca la VRAM, la RAM de `0xE000` a `0xFFFF` y los
registros del VDP en los segundos que se le digan, pulsando espacio donde haga
falta. `tools/omsx_fase.tcl` arranca la partida en la fase que se quiera:
escribe la fase en `0xE111` en el `call monta_la_fase` de `0x4209`, una sola
vez, y vuelca unos segundos después.

`tools/coteja_todo.py` monta cada pantalla con `tools/pantallas.py` y la
compara con su volcado: la tabla de nombres entera, el patrón y el color de
cada tile que se usa, los sprites que se ven y sus patrones. De la RAM del
volcado salen el tiempo, las vidas, los objetos y el turno de los sprites de
ese cuadro.

| pantalla | diferencias |
|---|---|
| logotipo de Konami | 0 |
| título | 0 |
| fase 1 | 0 |
| fase 11 | 0 |
| fase 21 | 0 |
| fase 41 | 0 |
| fase 50 | 0 |
| duelo, fase 31 | 0 |
| bonificación tras la 3 | 0 |
| visor de `0x6757` sobre la fase 1 | 0 |
| visor de `0x6757` sobre el título | 0 |

En los dos visores se comparan los tiles que monta cada pantalla; los demás son restos de las anteriores. El título, además, se monta encima de la VRAM del logotipo de Konami: nueve de sus tiles conservan el color que les dejó el logotipo.

Dos trampas de medida. La tabla de sprites se escribe al principio del cuadro
y los objetos se mueven después: un volcado tomado a mitad de cuadro tiene la Y
de la RAM un paso por delante de la de la VRAM. Y la copia de la tabla de
nombres se vuelca por cuartos, uno por cuadro: una cifra del tiempo puede ir un
cuadro por detrás.

## Las pruebas

`tools/omsx_prueba.tcl` lee una lista de órdenes a tiempo (escribir un byte,
pulsar una tecla, volcar) y `tools/lanza_prueba.sh` la corre. Las cinco que
hay en `tools/pruebas/`:

| prueba | qué se hace | qué pasa |
|---|---|---|
| `linea.txt` | en la fase 1, cinco cubos de la fila 4 marcados como acabados | fase acabada (pasos 2, 4 y 5 de la partida) y el tiempo se cobra: 430 puntos por 43 segundos |
| `vida.txt` | la racha de tres a 1, 1, 1 | sale el objeto en la Y de Q\*bert, cruza, y las vidas pasan de 2 a 3 |
| `continue.txt` | sin vidas y con el tiempo a 1 | GAME OVER; con F5, otra vez la partida con dos vidas de reserva |
| `pausa.txt` | F1 dos veces | el tiempo se queda en 99 hasta el segundo F1 |
| `bonus.txt` | fase 3 y fase acabada | el bit 0 del modo se enciende y empieza la bonificación |

## Los doce trozos que no llama nadie

`tools/omsx_huerfanos.tcl` los ejecuta en una partida, uno por cuadro: en
`0x40C5` apila la vuelta, salta al trozo con los registros que necesita y
apunta lo que ha hecho. El último es el visor, y el emulador se queda en pausa
con él en pantalla (`tools/lanza_huerfanos.sh`).

| trozo | qué hace |
|---|---|
| `0x640D` | con la fase 0x23 devuelve A=09: el mínimo entre la fase menos uno y 9 |
| `0x45FD` | intercambia 4 bytes entre HL y DE |
| `0x4643` | prepara la lectura de VRAM y deja en C' el puerto 0x98 |
| `0x705E` | guarda el mando 2: con A=05, 0xE32F=05 y 0xE330=05 |
| `0x7068` | lee E, S, F y C: con la E pulsada, A=01 (arriba) |
| `0x722C` | el cubo bajo Q\*bert contra el modelo: no es igual |
| `0x77CC` | escribe 0x5A en catorce objetos seguidos |
| `0x833C` | el otro jugador no está cayendo (con un jugador no hay otro) |
| `0x9032` | el objeto de la vida contra el segundo sprite: no se tocan, y avanza un píxel |
| `0x821A` | quita una vida (de 2 a 1) y pinta el marcador del duelo |
| `0x8275` | pone a Q\*bert a caer muerto: estado 12 y el arco de caer |
| `0x6757` | el visor de patrones |

## Lanzarlo

```
tools/lanza_vuelca.sh work/v1 "6 12" "10"
tools/lanza_fase.sh "11 0 0 3"
tools/lanza_prueba.sh tools/pruebas/vida.txt
tools/lanza_huerfanos.sh
make coteja
```
