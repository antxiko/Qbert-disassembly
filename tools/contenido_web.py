#!/usr/bin/env python3
"""EL CONTENIDO de la web de este cartucho: lo unico que es de este juego.

md2html.py y make_web.py son la maquinaria y no llevan dentro el nombre de
ningun juego: lo leen de aqui.

Las cifras estan medidas sobre este cartucho: CODIGO y DATOS los imprime
tools/presupuesto.py (make sanity); INSTRUCCIONES y COMENTARIOS, tools/
densidad.py (make densidad), que da tambien RUTINAS.
"""

NOMBRE = "Q*bert"
CATALOGO = "RC-746"
ANIO = 1986
REPOSITORIO = "https://github.com/antxiko/Qbert-disassembly"

CODIGO = 11743
DATOS = 21025
RUTINAS = 788
INSTRUCCIONES = 5939
COMENTARIOS = 4636


def densidad(idioma):
    """El porcentaje comentado, con la coma o el punto de cada idioma."""
    d = "%.1f" % (100.0 * COMENTARIOS / INSTRUCCIONES)
    return d.replace(".", ",") if idioma == "es" else d


PIE_LEGAL = {
    "es": "<em>Q*bert</em> lo public&oacute; Konami para MSX en 1986, con "
          "licencia del original de Gottlieb; su n&uacute;mero de "
          "cat&aacute;logo es RC-746 y son 32 KB. Todos los derechos sobre el "
          "juego siguen siendo de sus titulares. Este trabajo es de "
          "preservaci&oacute;n, estudio y documentaci&oacute;n, y la imagen del "
          "cartucho no se distribuye.",
    "en": "<em>Q*bert</em> was published by Konami for the MSX in 1986, under "
          "licence of Gottlieb's original; its catalogue number is RC-746 and "
          "it is 32 KB. All rights in the game remain with their holders. This "
          "is preservation, study and documentation work, and the cartridge "
          "image is not distributed.",
}

PORTADA = {
    "es": dict(
        titulo="Q*bert (MSX) - desensamblado comentado",
        claim="Cincuenta pir&aacute;mides de cubos que ruedan como dados, cinco "
              "en l&iacute;nea para pasar de fase, un duelo que se desempata a "
              "piedra, papel o tijera y una vida escondida. Todo dibujado desde "
              "la ROM.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "Cartucho <b>RC-746</b> de 32 KB", "<b>MSX</b>",
               "Volcado <b>bd253f32...</b>"],
        aviso="<b>Aqu&iacute; no hay ninguna captura.</b> Todas las "
              "im&aacute;genes est&aacute;n <b>dibujadas desde los bytes de la "
              "ROM</b> con las tablas del propio cartucho: los logotipos, el "
              "t&iacute;tulo, las cincuenta fases, la bonificaci&oacute;n, el "
              "duelo, Q*bert y los bichos. Nueve pantallas est&aacute;n "
              "<b>cotejadas contra openMSX</b> byte a byte, con 0 diferencias. "
              "El listado y las cifras se reproducen con <code>make</code>, y el "
              "reensamblado devuelve la ROM <b>byte a byte</b>.",
    ),
    "en": dict(
        titulo="Q*bert (MSX) - a commented disassembly",
        claim="Fifty pyramids of cubes that roll like dice, five in a row to "
              "clear a stage, a duel settled by rock, paper, scissors and a "
              "hidden life. All drawn from the ROM.",
        ficha=["Konami - <b>(c) Konami 1986</b>",
               "An <b>RC-746</b> 32 KB cartridge", "<b>MSX</b>",
               "Dump <b>bd253f32...</b>"],
        aviso="<b>Not one capture here.</b> Every picture is <b>drawn from "
              "the bytes of the ROM</b> with the cartridge's own tables: the "
              "logos, the title, the fifty stages, the bonus stage, the duel, "
              "Q*bert and the creatures. Nine screens are <b>checked against "
              "openMSX</b> byte for byte, with 0 differences. The listing and "
              "the numbers are reproducible with <code>make</code>, and "
              "reassembling gives back the ROM <b>byte for byte</b>.",
    ),
}

HALLAZGOS = {
    "es": [
        ("No hay que pintar la pir&aacute;mide: cinco en l&iacute;nea",
         "<p>Una fase se acaba con <b>cinco cubos acabados seguidos</b> en una "
         "fila, una columna o una diagonal de la cuadr&iacute;cula de 9 "
         "&times; 9 (los huecos no cortan la l&iacute;nea). Hace falta una "
         "l&iacute;nea hasta la fase 30, dos de la 31 a la 40 y tres de la 41 "
         "a la 50 (<code>0x737D</code>).</p><p>Visto en openMSX: cinco cubos "
         "marcados en la fila 4 de la fase 1 y la fase se da por acabada, y "
         "cobra el tiempo a 10 puntos el segundo.</p>"),
        ("Cada cubo es un dado",
         "<p>Los cubos no cambian de color: <b>ruedan</b>. Cada uno es uno de "
         "los 24 giros de un cubo con sus caras pintadas, y al saltarle encima "
         "rueda hacia donde vas (<code>0x72C0</code>, 24 &times; 4). El modelo "
         "est&aacute; arriba a la izquierda; un cubo est&aacute; acabado cuando "
         "ense&ntilde;a las mismas tres caras.</p><p>Medido recorriendo la "
         "tabla: cualquier giro se alcanza desde cualquier otro en cuatro "
         "saltos como mucho.</p>"),
        ("El duelo se desempata a piedra, papel o tijera",
         "<p>Con dos jugadores se juega <b>a la vez</b>: el segundo, con E, S, "
         "F, C y CTRL o con el mando 2, y cada uno con su modelo. Gana la "
         "partida el primero que hace l&iacute;nea; si se acaba el tiempo, el "
         "que m&aacute;s cubos tiene. Con empate, o si caen los dos, "
         "<b>JAN-KEN-PON</b>: abajo es papel, izquierda tijera y arriba piedra "
         "(<code>0x8B2B</code>).</p><p>Las manos salen de la ROM; el duelo "
         "sale del c&oacute;digo y no lo hemos jugado entero.</p>"),
        ("Una vida escondida",
         "<p>Si los <b>tres &uacute;ltimos saltos</b> han acabado un cubo cada "
         "uno y tienes menos de 8 vidas, sale un objeto a tu altura que cruza "
         "la pantalla de izquierda a derecha (<code>0x8FDF</code>). Tocarlo da "
         "una vida.</p><p>Visto en openMSX: el objeto sale, cruza y las vidas "
         "pasan de 2 a 3.</p>"),
        ("F5 para seguir, F1 para parar",
         "<p>En el GAME OVER, <b>F5</b> es el CONTINUE: puntuaci&oacute;n a "
         "cero, tres vidas y la misma fase (<code>0x4380</code>). <b>F1</b> "
         "pausa, pero solo mientras suena la m&uacute;sica de la fase "
         "(<code>0x6AA3</code>).</p><p>Las dos vistas en openMSX.</p>"),
        ("Quince objetos, y un mo&aacute;i",
         "<p>Por la pir&aacute;mide caen bolas que hacen cosas: la verde "
         "congela a todos, la gris los hace huir, la roja da el <b>salto "
         "largo</b> (dos filas, con el disparo) y pone a Q*bert blanco, la "
         "amarilla acelera, la tortuga frena y la azul da invencibilidad. "
         "Matan un encapuchado que te persigue, un mo&aacute;i que baja "
         "botando y seis bichos de colores que se quedan en los cubos de su "
         "color (<code>0x7628</code>).</p><p>Sale del c&oacute;digo; los "
         "dibujos, de la ROM.</p>"),
        ("La bonificaci&oacute;n: 27 cubos y PERFECT",
         "<p>Tras las fases 3, 6 y 10 de cada decena llega una fase de "
         "bonificaci&oacute;n: Q*bert no se mueve, cada diagonal gira el cubo "
         "que pisa, y al acabarlo pasa al siguiente (<code>0x789D</code>). Al "
         "final cada cubo acabado vale 100, 200, 300&hellip; y con los 27, "
         "PERFECT 5000 POINT.</p><p>Visto en openMSX tras la fase 3; el "
         "PERFECT sale del c&oacute;digo.</p>"),
        ("Un fallo de Konami: la bola verde escribe en la BIOS",
         "<p>Al coger la bola verde, <code>0x7763</code> carga "
         "<code>0x00BC</code> y escribe en <code>0x00BC</code> y "
         "<code>0x00BA</code>, que son la ROM de la BIOS: no pasa nada. Todo "
         "indica que iba a <code>0xE2BC</code>, el objeto 23.</p>"),
        ("Lo que no ejecuta nadie",
         "<p>Doce trozos de c&oacute;digo que no llama nadie: un visor de "
         "patrones de desarrollo que llena la pantalla con 0, 1, 2&hellip; "
         "(<code>0x6757</code>), copias antiguas de la lectura de teclas y, "
         "en <code>0x44A5</code>, la fase del Game Master con un bucle que no "
         "sale nunca, al que no se llega porque la variable se borra justo "
         "antes. Y al final de la ROM, la marca oculta de Konami: "
         "&#12461;&#12517;&#12540;&#12496;&#12540;&#12488;, RC-746.</p>"),
    ],
    "en": [
        ("You do not paint the pyramid: five in a row",
         "<p>A stage is cleared with <b>five finished cubes in a row</b> in a "
         "row, column or diagonal of the 9 &times; 9 grid (gaps do not break "
         "the line). One line is needed up to stage 30, two from 31 to 40 and "
         "three from 41 to 50 (<code>0x737D</code>).</p><p>Seen in openMSX: "
         "five cubes marked on row 4 of stage 1 and the stage is cleared, and "
         "the time is paid at 10 points a second.</p>"),
        ("Every cube is a die",
         "<p>The cubes do not change colour: they <b>roll</b>. Each one is one "
         "of the 24 rotations of a cube with painted faces, and jumping on it "
         "rolls it the way you go (<code>0x72C0</code>, 24 &times; 4). The "
         "model is at the top left; a cube is finished when it shows the same "
         "three faces.</p><p>Measured walking the table: any rotation is "
         "reachable from any other in four jumps at most.</p>"),
        ("The duel is settled by rock, paper, scissors",
         "<p>With two players both play <b>at once</b>: the second one with E, "
         "S, F, C and CTRL or joystick 2, each with their own model. The first "
         "to make a line wins the set; if time runs out, whoever has more "
         "cubes. With a tie, or if both fall, <b>JAN-KEN-PON</b>: down is "
         "paper, left scissors and up rock (<code>0x8B2B</code>).</p><p>The "
         "hands come from the ROM; the duel comes from the code and has not "
         "been played through.</p>"),
        ("A hidden life",
         "<p>If your <b>last three jumps</b> each finished a cube and you have "
         "fewer than 8 lives, an object appears at your height and crosses the "
         "screen from left to right (<code>0x8FDF</code>). Touching it gives a "
         "life.</p><p>Seen in openMSX: the object appears, crosses and the "
         "lives go from 2 to 3.</p>"),
        ("F5 to go on, F1 to stop",
         "<p>At GAME OVER, <b>F5</b> is the CONTINUE: score to zero, three "
         "lives and the same stage (<code>0x4380</code>). <b>F1</b> pauses, but "
         "only while the stage music is playing (<code>0x6AA3</code>).</p><p>"
         "Both seen in openMSX.</p>"),
        ("Fifteen objects, and a moai",
         "<p>Balls that do things fall down the pyramid: the green one freezes "
         "everyone, the grey one makes them run away, the red one gives the "
         "<b>long jump</b> (two rows, with the trigger) and turns Q*bert white, "
         "the yellow one speeds you up, the turtle slows you down and the "
         "blue one makes you invincible. A hooded one that chases you, a moai "
         "that bounces down and six coloured creatures that stay on cubes of "
         "their colour are the ones that kill (<code>0x7628</code>).</p><p>It "
         "comes from the code; the drawings, from the ROM.</p>"),
        ("The bonus stage: 27 cubes and PERFECT",
         "<p>After stages 3, 6 and 10 of every ten comes a bonus stage: "
         "Q*bert does not move, each diagonal rotates the cube he stands on, "
         "and when it is finished he moves on to the next (<code>0x789D</code>)."
         " At the end each finished cube is worth 100, 200, 300&hellip; and "
         "with all 27, PERFECT 5000 POINT.</p><p>Seen in openMSX after stage "
         "3; the PERFECT comes from the code.</p>"),
        ("A Konami slip: the green ball writes into the BIOS",
         "<p>When you take the green ball, <code>0x7763</code> loads "
         "<code>0x00BC</code> and writes to <code>0x00BC</code> and "
         "<code>0x00BA</code>, which are the BIOS ROM: nothing happens. "
         "Everything points to it being meant for <code>0xE2BC</code>, object "
         "23.</p>"),
        ("What nobody runs",
         "<p>Twelve pieces of code nobody calls: a development pattern viewer "
         "that fills the screen with 0, 1, 2&hellip; (<code>0x6757</code>), "
         "old copies of the key reading and, at <code>0x44A5</code>, the Game "
         "Master stage with a loop that never exits, never reached because "
         "the variable is cleared just before. And at the end of the ROM, "
         "Konami's hidden mark: "
         "&#12461;&#12517;&#12540;&#12496;&#12540;&#12488;, RC-746.</p>"),
    ],
}

# La cabecera: el rotulo del titulo, dibujado desde la ROM (tools/imagenes.py)
LOGOTIPO = "rotulo.png"
GALERIA = [
    ("titulo.png",
     "El t&iacute;tulo: el r&oacute;tulo en su marco (<code>0x4B95</code>), "
     "Q*bert en la recreativa (el RLE de <code>0xB09A</code> y el guion de "
     "<code>0x8849</code>) y los textos de <code>0x4790</code>. Cotejado "
     "contra openMSX: 0 diferencias.",
     "The title: the logo in its frame (<code>0x4B95</code>), Q*bert at the "
     "arcade machine (the RLE at <code>0xB09A</code> and the script at "
     "<code>0x8849</code>) and the texts at <code>0x4790</code>. Checked "
     "against openMSX: 0 differences."),
    ("fases.png",
     "Las 50 fases, desde sus tableros de 9 &times; 9 (<code>0x97DB</code>, "
     "81 bytes cada uno) y los cubos de su estilo (<code>0xA7FE</code>: uno "
     "para la 1-10, otro para la 11-20 y otro para la 21-50). El cubo de "
     "arriba a la izquierda es el modelo. Cotejadas la 1, la 11, la 21, la 41 "
     "y la 50: 0 diferencias.",
     "The 50 stages, from their 9 &times; 9 boards (<code>0x97DB</code>, 81 "
     "bytes each) and the cubes of their style (<code>0xA7FE</code>: one for "
     "1-10, one for 11-20 and one for 21-50). The top-left cube is the model. "
     "Stages 1, 11, 21, 41 and 50 checked: 0 differences."),
    ("fase-01.png",
     "La fase 1 recien montada, con el marcador, el tiempo y Q*bert en el "
     "primer cubo de su columna (<code>0x64C3</code>).",
     "Stage 1 just built, with the score line, the time and Q*bert on the "
     "first cube of his column (<code>0x64C3</code>)."),
    ("bonificacion.png",
     "La fase de bonificaci&oacute;n: 27 cubos (<code>0xA7AD</code>) y BONUS "
     "arriba. Cotejada tras la fase 3: 0 diferencias.",
     "The bonus stage: 27 cubes (<code>0xA7AD</code>) and BONUS at the top. "
     "Checked after stage 3: 0 differences."),
    ("duelo.png",
     "El duelo en la fase 31: los dos modelos con 1P y 2P encima, y los dos "
     "Q*bert. Cotejado: 0 diferencias.",
     "The duel on stage 31: both models with 1P and 2P above them, and both "
     "Q*berts. Checked: 0 differences."),
    ("qbert.png",
     "Q*bert: dos sprites de 16 &times; 16 superpuestos, amarillo y magenta "
     "(<code>0xACBC</code> a la izquierda, <code>0xADBC</code> a la derecha, "
     "de pie y en el aire), cayendo (<code>0xAF3C</code>) y en la fase acabada "
     "(<code>0xAEBC</code>).",
     "Q*bert: two overlaid 16 &times; 16 sprites, yellow and magenta "
     "(<code>0xACBC</code> to the left, <code>0xADBC</code> to the right, "
     "standing and in the air), falling (<code>0xAF3C</code>) and on a "
     "cleared stage (<code>0xAEBC</code>)."),
    ("qbert-segundo.png",
     "El segundo Q*bert del duelo: los mismos dibujos en azul claro "
     "(<code>0x65CB</code>).",
     "The second Q*bert of the duel: the same drawings in light blue "
     "(<code>0x65CB</code>)."),
    ("bichos.png",
     "Los quince objetos del 4 al 18 con su color de <code>0x65CB</code>, "
     "posados y en el aire: la bola gris, la verde, la amarilla, la tortuga, "
     "la roja, el que gira cubos, el mo&aacute;i, el encapuchado, los seis de "
     "colores y la bola azul.",
     "The fifteen objects 4 to 18 with their colour from <code>0x65CB</code>, "
     "landed and in the air: the grey ball, the green one, the yellow one, "
     "the turtle, the red one, the cube spinner, the moai, the hooded one, "
     "the six coloured ones and the blue ball."),
    ("moai.png",
     "Los dos juegos de dibujos del mo&aacute;i, que se alternan al saltar "
     "(<code>0xAC3C</code> y <code>0xAC7C</code>).",
     "The moai's two sets of drawings, swapped as it jumps "
     "(<code>0xAC3C</code> and <code>0xAC7C</code>)."),
    ("vida-escondida.png",
     "El objeto de la vida escondida: dos sprites, rojo y blanco "
     "(<code>0x9019</code>).",
     "The hidden life object: two sprites, red and white "
     "(<code>0x9019</code>)."),
    ("jan-ken.png",
     "El PON! del duelo, montado desde la ROM: el recuadro de "
     "<code>0x8D3D</code>, las manos y las letras de <code>0x90E3</code>. "
     "Esta no est&aacute; cotejada.",
     "The duel's PON!, built from the ROM: the frame at <code>0x8D3D</code>, "
     "the hands and the letters at <code>0x90E3</code>. This one is not "
     "checked."),
    ("manos.png",
     "Las tres manos (<code>0x8B49</code>): papel, tijera y piedra. La de la "
     "derecha es la de la izquierda reflejada (<code>0x8C5F</code>).",
     "The three hands (<code>0x8B49</code>): paper, scissors and rock. The "
     "right-hand one is the left-hand one mirrored (<code>0x8C5F</code>)."),
    ("logotipo-konami.png",
     "El logotipo de Konami que se destapa l&iacute;nea a l&iacute;nea al "
     "encender (<code>0x4982</code>, <code>0x494E</code>). Cotejado: 0 "
     "diferencias.",
     "The Konami logo uncovered line by line at power-on (<code>0x4982</code>,"
     " <code>0x494E</code>). Checked: 0 differences."),
]
