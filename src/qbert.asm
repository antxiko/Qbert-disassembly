; ==========================================================================
; Q*BERT - Konami - MSX1 - cartucho RC-746 de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l85f6h:	equ 0x085f6

; ----------------------------------------------------------------------
; DATOS cabecera_del_cartucho: "AB" y la direccion de INIT (0x405E);
;   STATEMENT, DEVICE y TEXT a cero, y los seis bytes reservados tambien
;   0x4000..0x4010  (16 bytes)
DATA_cabecera_del_cartucho:
	defw 04241h,0405eh,00000h,00000h,00000h,00000h,00000h,00000h	; 4000

; ----------------------------------------------------------------------
; DATOS cabecera_del_game_master: "CD" 07 46: el 0x07 de los RC-7xx y el 0x46
;   de RC-746
;   0x4010..0x4014  (4 bytes)
DATA_cabecera_del_game_master:
	defb 043h,044h,007h,046h	; 4010

; ----------------------------------------------------------------------
; DATOS banderas_del_game_master: 0x80: vienen todos los campos menos el del
;   bit 7
;   0x4014..0x4015  (1 bytes)
DATA_banderas_del_game_master:
	defb 080h	; 4014

; ----------------------------------------------------------------------
; DATOS punteros_del_game_master: 0xE000 y 0x03 (la variable de escena y la
;   escena del menu de nivel, donde se aplican los trucos), 0xE114 y 0x32 (la
;   fase que elige el Game Master y cuantas hay: cincuenta), 0xE110 (las
;   vidas), 0xE105 (el record), 0xE10B (la puntuacion), 0xE108 (el segundo
;   marcador, que este juego ni lee) y 0xE002 (los bits de modo)
;   0x4015..0x4025  (16 bytes)
DATA_punteros_del_game_master:
	defw 0e000h,01403h,032e1h,0e110h,0e105h,0e10bh,0e108h,0e002h	; 4015

; ======================================================================
; CODIGO 0x4025..0x40e3  (190 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL GANCHO DE H.KEYI. INIT deja aqui un `jp` y todo el juego cuelga de la interrupcion del VDP: el sonido en cada cuadro, y la escena solo si el cuadro anterior ya acabo.
; ----------------------------------------------------------------------
cada_cuadro:		; El gancho de H.KEYI: el juego ENTERO cuelga de aqui
	call 0013eh		;4025   ; BIOS RDVDP - Reads VDP status register | lee el registro de estado del VDP, que baja la peticion de interrupcion
	di			;4028   ; el sonido no puede partirse por otra interrupcion
	call suena_un_cuadro		;4029   ; el sonido va primero y con las interrupciones cortadas: no se salta un cuadro
	ld hl,0e005h		;402c   ; (0xE005) a uno: el cuadro anterior sigue a medias
	bit 0,(hl)		;402f   ; bit 0: aun sin acabar
	jr nz,L_4040		;4031   ; si sigue, este cuadro solo suena
	inc (hl)			;4033   ; se marca el cuadro como en curso
	ei			;4034   ; y se abren las interrupciones: la escena puede durar mas de un cuadro
	call lee_los_mandos		;4035   ; lee los dos mandos y el teclado
	call haz_el_cuadro		;4038   ; y hace la escena que toque
	ld a,000h		;403b   ; cuadro acabado
	ld (0e005h),a		;403d   ; y se deja libre para el siguiente
L_4040:
	call 0013eh		;4040   ; BIOS RDVDP - Reads VDP status register | si mientras tanto llego otra interrupcion (bit 7 del estado)...
	or a			;4043   ; el bit 7 del estado va al signo
	di			;4044   ; cerradas mientras suena
	call m,suena_un_cuadro		;4045   ; ...su sonido se hace ahora, para no perderlo
	ei			;4048   ; y abiertas otra vez
	ret			;4049   ; vuelta a la BIOS, que acaba la interrupcion
suma_a_a_hl:		; HL += A, con el acarreo al alto
	add a,l			;404a   ; L + A...
	ld l,a			;404b   ; ...en L
	ret nc			;404c   ; sin acarreo, ya esta
	inc h			;404d   ; con acarreo, H + 1
	ret			;404e
suma_a_a_de:		; DE += A, igual
	add a,e			;404f   ; E + A...
	ld e,a			;4050   ; ...en E
	ret nc			;4051   ; sin acarreo, ya esta
	inc d			;4052   ; con acarreo, D + 1
	ret			;4053
reparte_por_tabla:		; El `pop hl` recoge la tabla: es la direccion de retorno
	pop hl			;4054   ; la tabla va pegada detras del `call`: su direccion es la de retorno
	add a,a			;4055   ; entradas de dos bytes
	call suma_a_a_hl		;4056   ; HL = tabla + 2A
	ld e,(hl)			;4059   ; la entrada A de la tabla...
	inc hl			;405a   ; el byte alto
	ld d,(hl)			;405b
	ex de,hl			;405c   ; HL = la entrada
	jp (hl)			;405d   ; ...y alli se salta

; ----------------------------------------------------------------------
; INIT. Lo que ejecuta la BIOS al encontrar la "AB". Busca en que ranura esta el cartucho, pone la pagina 2 en esa misma ranura (el juego ocupa 0x4000-0xBFFF), engancha la interrupcion y se queda parado: todo lo demas pasa en 0x4025.
; ----------------------------------------------------------------------
INIT:		; Lo que ejecuta la BIOS al encontrar la "AB" de 0x4000
	di			;405e   ; sin interrupciones mientras se prepara todo
	call 00138h		;405f   ; BIOS RSLREG - Reads the primary slot register | RSLREG: las ranuras de las cuatro paginas
	rrca			;4062   ; la de la pagina 1, que es donde corre esto
	rrca			;4063   ; bits 2-3 del registro de ranuras: la de la pagina 1
	and 003h		;4064
	ld c,a			;4066   ; C = la ranura primaria
	ld hl,0fcc1h		;4067   ; EXPTBL: si esa ranura esta expandida (bit 7)...
	add a,l			;406a   ; EXPTBL + ranura
	ld l,a			;406b
	ld a,(hl)			;406c   ; ...se anade el bit de expansion
	and 080h		;406d   ; bit 7: expandida
	or c			;406f   ; y en C, junto a la primaria
	ld c,a			;4070   ; C = ranura y bit de expansion
	inc l			;4071   ; y en SLTTBL, cuatro bytes mas alla, la subranura de la pagina 1
	inc l			;4072
	inc l			;4073
	inc l			;4074
	ld a,(hl)			;4075   ; SLTTBL + ranura: el registro de subranuras de esa ranura
	and 00ch		;4076   ; bits 2-3: la subranura
	or c			;4078   ; junto a lo que ya habia
	ld h,080h		;4079   ; H=0x80: la pagina 2
	call 00024h		;407b   ; BIOS ENASLT - Switches to specified slot and page definitively | ENASLT: la pagina 2 pasa a la ranura del cartucho
	ld a,001h		;407e   ; 1, 2 y 3 a los registros de banco de un mapeador de Konami. En un cartucho de 32 KB sin mapeador no hacen nada: son las escrituras de la casa, las mismas en todos
	ld (06000h),a		;4080   ; 0x6000 = 1
	inc a			;4083
	ld (08000h),a		;4084   ; 0x8000 = 2
	inc a			;4087
	ld (0a000h),a		;4088   ; 0xA000 = 3
	ld hl,0fd00h		;408b   ; de 0xFD00 a 0xFEFF todo `ret`: los ganchos de la BIOS quedan mudos
	ld de,0fd01h		;408e   ; destino, uno mas alla: el `ldir` corre el 0xC9
	ld bc,00200h		;4091   ; 512 bytes
	ld (hl),0c9h		;4094   ; `ret`
	ldir		;4096   ; relleno
	ld a,0c3h		;4098   ; y en H.KEYI (0xFD9A) un `jp 0x4025`
	ld (0fd9ah),a		;409a   ; el `jp`...
	ld hl,cada_cuadro		;409d   ; ...a cada_cuadro...
	ld (0fd9bh),hl		;40a0   ; ...en 0xFD9B
	ld sp,0eaffh		;40a3   ; la pila, debajo de 0xEB00
	ld hl,0e000h		;40a6   ; borra de 0xE000 a 0xE3FF
	ld de,0e001h		;40a9   ; destino, uno mas alla: se corre el cero
	ld bc,003ffh		;40ac   ; 1.024 bytes
	ld (hl),000h		;40af   ; el cero
	ldir		;40b1   ; borrado
	ld a,001h		;40b3   ; (0xE005)=1 mientras se prepara el VDP: la interrupcion no toca escenas
	ld (0e005h),a		;40b5   ; (0xE005) = 1: la interrupcion solo suena
	call apaga_y_borra_la_vram		;40b8   ; apaga el sonido, borra la VRAM y pone los registros
	xor a			;40bb   ; y ya puede hacer escenas
	ld (0e005h),a		;40bc
	call 0013eh		;40bf   ; BIOS RDVDP - Reads VDP status register | lee el estado para no arrancar con una interrupcion pendiente
	ei			;40c2   ; a partir de aqui manda la interrupcion
el_bucle_vacio:		; INIT acaba aqui: a partir de este `jr $` todo pasa en la interrupcion
	jr el_bucle_vacio		;40c3   ; `jr $`: se queda aqui para siempre
haz_el_cuadro:		; Cuenta el cuadro y reparte la escena que toque
	ld hl,0e003h		;40c5   ; (0xE003): el contador de cuadros, que usa medio juego para ir a su ritmo
	inc (hl)			;40c8   ; un cuadro mas
	ld a,(0e002h)		;40c9   ; bit 6 de (0xE002): hay partida de verdad
	and 040h		;40cc   ; bit 6
	ld hl,045fch		;40ce   ; con partida, la escena vuelve a un `ret` y ya esta...
	jr nz,L_40D6		;40d1   ; con partida, 0x45FC
	ld hl,0441eh		;40d3   ; ...sin partida, vuelve a 0x441E, que mira si se pulsa para empezar
L_40D6:
	ld bc,(0e000h)		;40d6   ; C = escena (0xE000), B = su paso (0xE001)
	ld a,c			;40da   ; C: la escena
	cp 003h		;40db   ; la escena 3, el menu de nivel, no mira nada a la vuelta
	jr z,L_40E0		;40dd   ; la 3 salta sin apilar
	push hl			;40df   ; la vuelta se apila: el `ret` de la escena salta ahi
L_40E0:
	call reparte_por_tabla		;40e0   ; A = escena: la entrada de la tabla

; ----------------------------------------------------------------------
; DATOS tabla_de_escenas: Nueve entradas; reparte segun (0xE000): el logotipo
;   de Konami, la presentacion, la demostracion, el menu de nivel, el
;   principio de fase, la partida, el fin de partida, el record y la fase
;   acabada
;   0x40e3..0x40f5  (18 bytes)
DATA_tabla_de_escenas:
	defw 040f5h,04124h,04166h,0419fh,041ech,04291h,04307h,04377h	; 40e3
	defw 043cbh	; 40f3  -> escena_fase_acabada

; ======================================================================
; CODIGO 0x40f5..0x4275  (384 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCENA 0: EL LOGOTIPO DE KONAMI. El paso 0 lo monta apagado, el 1 lo destapa linea a linea y el 2 espera, borra y pasa a la presentacion.
; ----------------------------------------------------------------------
escena_logotipo:
	djnz L_4104		;40f5   ; paso 1: destapar
	ld a,(0e003h)		;40f7   ; una linea cada dos cuadros
	rra			;40fa   ; el bit 0 al acarreo
	ret nc			;40fb   ; los cuadros pares, nada
	call destapa_una_linea_del_logotipo		;40fc   ; pinta una linea de pixeles del logotipo; Z cuando acaba
	ret nz			;40ff   ; sin acabar, vuelve
	xor a			;4100   ; hecho: espera de 256 cuadros (0xE004=0) y al paso 2
	jp espera_a_y_sigue		;4101   ; E004=0 y al paso siguiente
L_4104:
	djnz L_4116		;4104   ; paso 2: esperar
	ld hl,0e004h		;4106   ; la espera
	dec (hl)			;4109   ; un cuadro menos
	ret nz			;410a   ; hasta cero
	call borra_la_copia_de_nombres		;410b   ; borra la copia de la tabla de nombres
	ld b,000h		;410e   ; fondo negro...
	call pon_el_fondo		;4110   ; registro 7 a 0: fondo transparente, negro
	jp escena_siguiente_con_espera_a		;4113   ; ...y a la escena 1
L_4116:
	call pon_los_registros_del_vdp		;4116   ; paso 0: registros del VDP
	call borra_la_pantalla		;4119   ; tabla de nombres a cero
	call monta_la_fuente		;411c   ; la fuente
	call monta_el_logotipo_de_konami		;411f   ; y el logotipo de KONAMI, con los colores a cero
	jr paso_siguiente		;4122   ; y al paso 1

; ----------------------------------------------------------------------
; ESCENA 1: LA PRESENTACION. Q*bert delante de la maquina recreativa (pasos 1 a 8, en 0x83DA-0x8528), el titulo (paso 9) y el cursor de 1PLAYER/2PLAYERS parpadeando (paso 10). El paso 0 la prepara.
; ----------------------------------------------------------------------
escena_presentacion:
	djnz L_4129		;4124   ; pasos 1 a 8: la presentacion, un bloque por paso
	jp presentacion_paso_1		;4126   ; paso 1
L_4129:
	djnz L_412E		;4129   ; paso 2...
	jp presentacion_paso_2		;412b   ; ...Q*bert llega a la recreativa
L_412E:
	djnz L_4133		;412e   ; paso 3...
	jp presentacion_paso_3		;4130   ; ...el bicho baja por su guion
L_4133:
	djnz L_4138		;4133   ; paso 4...
	jp presentacion_paso_4		;4135   ; ...una espera
L_4138:
	djnz L_413D		;4138   ; paso 5...
	jp presentacion_paso_5		;413a   ; ...el rotulo sube
L_413D:
	djnz L_4142		;413d   ; paso 6...
	jp presentacion_paso_6		;413f   ; ...Q*bert se vuelve
L_4142:
	djnz L_4147		;4142   ; paso 7...
	jp presentacion_paso_7		;4144   ; ...el rotulo y la maquina suben
L_4147:
	djnz L_414C		;4147   ; paso 8...
	jp presentacion_paso_8		;4149   ; ...el ultimo movimiento
L_414C:
	djnz L_4154		;414c   ; paso 9: el titulo
	call pinta_el_titulo		;414e   ; el titulo entero
	xor a			;4151   ; E004 = 0: 256 cuadros de cursor
	jr espera_a_y_sigue		;4152   ; y al paso 10
L_4154:
	djnz L_4160		;4154   ; paso 10: el cursor parpadea 256 cuadros...
	ld hl,0e004h		;4156   ; la espera
	dec (hl)			;4159   ; un cuadro menos
	jp nz,parpadea_el_cursor		;415a   ; ...y si nadie pulsa, la escena 2, la demostracion
	jp escena_siguiente		;415d   ; se acabo: a la demostracion
L_4160:
	call prepara_la_recreativa		;4160   ; paso 0: la pantalla de la recreativa, y a por el paso 1
	jp empieza_la_presentacion		;4163   ; y la musica de la presentacion

; ----------------------------------------------------------------------
; ESCENA 2: LA DEMOSTRACION. El juego de verdad, con las pulsaciones sacadas de 0x6BBF/0x6BD8. Se alternan dos: un jugador en la fase 34 y dos a la vez en la 37.
; ----------------------------------------------------------------------
escena_demostracion:
	djnz L_417C		;4166   ; paso 1: juega un cuadro
	call pulsaciones_de_la_demostracion		;4168   ; las pulsaciones grabadas
	call cuadro_de_la_demostracion		;416b   ; el cuadro de partida, el mismo que en el juego
	ld a,(0e113h)		;416e   ; (0xE113) a cero: el Q*bert de la demostracion ha caido o se acabo el guion
	or a			;4171   ; el Q*bert de la demostracion...
	ret nz			;4172   ; ...sigue: nada mas
	ld a,014h		;4173   ; sonido 0x14 y 120 cuadros de espera
	call toca_sonido		;4175   ; sonido 0x14
	ld a,078h		;4178   ; 120 cuadros de espera
	jr espera_a_y_sigue		;417a   ; y al paso 2
L_417C:
	djnz L_418F		;417c   ; paso 2: la espera
	ld hl,0e004h		;417e   ; la espera
	dec (hl)			;4181   ; un cuadro menos
	ret nz			;4182   ; hasta cero
vuelve_al_logotipo:
	xor a			;4183   ; escena 0, el logotipo, con 32 cuadros de espera
pon_escena_a:
	ld (0e000h),a		;4184   ; A = escena
	ld a,020h		;4187   ; 32 cuadros...
	ld (0e004h),a		;4189   ; ...de espera
	jp al_paso_0		;418c   ; y al paso 0 de esa escena
L_418F:
	call borra_la_pantalla		;418f   ; paso 0: pantalla en negro y a montar la demostracion
	call prepara_la_demostracion		;4192   ; la demostracion montada
	ld a,020h		;4195   ; 32 cuadros
espera_a_y_sigue:		; (0xE004)=A y al paso siguiente
	ld (0e004h),a		;4197   ; la espera
paso_siguiente:
	ld hl,0e001h		;419a   ; el paso...
	inc (hl)			;419d   ; ...mas uno
	ret			;419e

; ----------------------------------------------------------------------
; ESCENA 3: EL MENU DE NIVEL. LEVEL 1-5 con un jugador; con dos, dos niveles y la partida a 3 o a 5 duelos. Esta escena no apila vuelta: mientras se elige, 0x441E no mira los mandos.
; ----------------------------------------------------------------------
escena_menu_de_nivel:
	djnz L_41B1		;419f   ; paso 1: dibujar el menu
	ld a,(0e102h)		;41a1   ; (0xE102): uno o dos jugadores
	or a			;41a4   ; 0: un jugador
	jr z,L_41AC		;41a5
	call menu_del_duelo		;41a7   ; dos: su menu
	jr paso_siguiente		;41aa   ; y al paso 2
L_41AC:
	call menu_de_un_jugador		;41ac   ; uno: el suyo
	jr paso_siguiente		;41af   ; y al paso 2
L_41B1:
	djnz L_41D0		;41b1   ; paso 2: elegir. Los dos lectores hacen `pop hl` y vuelven de la escena mientras no se pulse el disparo
	ld a,(0e102h)		;41b3   ; uno o dos
	or a			;41b6   ; 0: un jugador
	jr z,L_41BE		;41b7
	call elige_el_duelo		;41b9   ; el del duelo; vuelve aqui solo con el disparo
	jr L_41C1		;41bc   ; ya elegido
L_41BE:
	call elige_el_nivel		;41be   ; el de un jugador; lo mismo
L_41C1:
	call empieza_en_el_nivel_elegido		;41c1   ; con el nivel ya elegido, la fase en la que se empieza
	call aplica_la_fase_del_game_master		;41c4   ; y si el Game Master pide otra, esa
	ld a,041h		;41c7   ; sonido 0x41 y 80 cuadros
	call toca_sonido		;41c9   ; la musica del nivel elegido
	ld a,050h		;41cc   ; 80 cuadros
	jr espera_a_y_sigue		;41ce   ; y al paso 3
L_41D0:
	djnz L_41E2		;41d0   ; paso 3: parpadea la opcion elegida mientras dura la espera
	ld hl,0e004h		;41d2   ; la espera
	dec (hl)			;41d5   ; un cuadro menos
	jr z,L_41E0		;41d6   ; acabada: a la partida
	ld a,(0e102h)		;41d8   ; en el duelo...
	or a			;41db   ; ...uno o dos...
	ret nz			;41dc   ; ...no parpadea nada
	jp parpadea_el_nivel_elegido		;41dd   ; con uno, parpadea el nivel
L_41E0:
	jr escena_siguiente		;41e0   ; y a la escena 4
L_41E2:
	call borra_la_pantalla		;41e2   ; paso 0: pantalla en negro, la fuente y 80 cuadros
	call monta_la_fuente		;41e5   ; la fuente
	ld a,050h		;41e8   ; 80 cuadros
	jr espera_a_y_sigue		;41ea   ; y al paso 1

; ----------------------------------------------------------------------
; ESCENA 4: EL PRINCIPIO DE FASE. El paso 0 descuenta la vida que se va a jugar y pone el rotulo (LEVEL y STAGE al empezar un nivel, READY en el duelo); el paso 1 monta la fase cuando callan el sonido y la espera.
; ----------------------------------------------------------------------
escena_principio_de_fase:
	djnz L_4224		;41ec   ; paso 1: montar
	ld hl,0e004h		;41ee   ; la espera
	ld a,(hl)			;41f1   ; si ya es cero...
	or a			;41f2   ; ...no se toca
	jr z,L_41F7		;41f3   ; cero: adelante
	dec (hl)			;41f5   ; si no, un cuadro menos
	ret nz			;41f6   ; hasta cero
L_41F7:
	ld a,(0e012h)		;41f7   ; espera a que acabe la musica del canal 1
	or a			;41fa   ; musica del canal 1 sonando...
	ret nz			;41fb   ; ...se espera
	ld a,017h		;41fc   ; sonido 0x17, la musica de la fase
	call toca_sonido		;41fe   ; la de la fase
	ld a,020h		;4201   ; 32 cuadros...
	ld (0e004h),a		;4203   ; ...de espera
	call borra_la_pantalla		;4206   ; pantalla en negro
	call monta_la_fase		;4209   ; la fase entera: tablero, cubos, bichos y marcador
	ld hl,0e113h		;420c   ; Q*bert en juego
	ld (hl),001h		;420f   ; (0xE113)=1
	ld hl,0e35ch		;4211   ; y el segundo Q*bert tambien
	ld (hl),001h		;4214   ; (0xE35C)=1
escena_siguiente:		; Siguiente escena, con 32 cuadros de espera
	ld a,020h		;4216   ; 32 cuadros
escena_siguiente_con_espera_a:
	ld (0e004h),a		;4218   ; la espera
	ld hl,0e000h		;421b   ; la escena...
	inc (hl)			;421e   ; ...mas uno
al_paso_0:
	xor a			;421f   ; y su paso...
	ld (0e001h),a		;4220   ; ...a cero
	ret			;4223   ; vuelta
L_4224:
	ld hl,0e110h		;4224   ; paso 0: una vida menos, la que se juega ahora; el marcador de vidas cuenta las de reserva
	ld a,(hl)			;4227   ; las vidas, en BCD
	sub 001h		;4228   ; menos una...
	daa			;422a   ; ...en BCD
	ld (hl),a			;422b   ; de vuelta
	ld (0e120h),a		;422c   ; y la copia del segundo jugador
	ld a,(0e002h)		;422f   ; el modo
	bit 5,a		;4232   ; bit 5 de (0xE002): el duelo
	jr z,L_424A		;4234   ; con uno, a 0x424A
	call limpia_el_marco		;4236   ; marco de ladrillo limpio
	call cabecera_del_duelo		;4239   ; la cabecera del duelo: cuantas partidas quedan
	ld de,04275h		;423c   ; READY
	call pinta_guion		;423f   ; READY en 0x39AD
L_4242:
	ld a,(0e012h)		;4242   ; y no sigue hasta que acaba su musica
	or a			;4245   ; el canal 1 aun suena...
	jr nz,L_4242		;4246   ; ...y se espera aqui, con la interrupcion tocando
	jr L_426D		;4248   ; un cuadro de espera y al paso 1
L_424A:
	ld a,(0e111h)		;424a   ; con un jugador, solo en la primera fase de cada nivel (01, 11, 21, 31 y 41)...
	and 00fh		;424d   ; las unidades de la fase
	dec a			;424f   ; menos una: cero en la 1, 11, 21...
	ld a,001h		;4250   ; A=1 sin tocar la bandera
	jr nz,L_426F		;4252   ; no es la primera del nivel: sin rotulo
	call limpia_el_marco		;4254   ; ...el rotulo: LEVEL n y STAGE nn
	ld de,0427dh		;4257   ; LEVEL
	call pinta_guion		;425a   ; en 0x390C
	call pinta_el_numero_de_nivel		;425d   ; y el numero
	ld de,04788h		;4260   ; STAGE, y el numero de fase dos casillas mas alla
	call pinta_guion		;4263   ; STAGE en 0x394C, y HL detras
	inc l			;4266   ; un espacio
	call pinta_la_fase_en_hl		;4267   ; y la fase
	call gancho_vacio		;426a   ; un `ret`: aqui no hace nada
L_426D:
	ld a,001h		;426d   ; un cuadro de espera
L_426F:
	ld (0e004h),a		;426f   ; la espera
	jp paso_siguiente		;4272   ; y al paso siguiente

; ----------------------------------------------------------------------
; DATOS rotulos_ready_y_level: Dos guiones de 0x4685: READY en 0x39AD y LEVEL
;   en 0x390C. Cada uno es la direccion de la tabla de nombres y los
;   caracteres, con 0xFF de fin
;   0x4275..0x4285  (16 bytes)
DATA_rotulos_ready_y_level:
	defb 0adh,039h,032h,025h,021h,024h,039h,0ffh	; 4275  .92%!$9.
	defb 00ch,039h,02ch,025h,036h,025h,02ch,0ffh	; 427d  .9,%6%,.

; ======================================================================
; CODIGO 0x4285..0x42f7  (114 bytes)
; ======================================================================


pinta_el_numero_de_nivel:		; El nivel elegido (0xE103, de 0 a 4) mas uno, detras de LEVEL
	ld hl,03913h		;4285   ; detras de LEVEL
	ld a,(0e103h)		;4288   ; el nivel: 0 a 4
	inc a			;428b   ; 1 a 5
	add a,010h		;428c   ; los digitos son las casillas 0x10 a 0x19
	jp 0004dh		;428e   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM

; ----------------------------------------------------------------------
; ESCENA 5: LA PARTIDA. Cada cuadro hace el paso que toque (0x6782) y luego mira si la fase se ha acabado o si Q*bert ha caido: si queda tiempo y vidas, lo vuelve a poner arriba; si no, a la escena 6.
; ----------------------------------------------------------------------
escena_partida:
	call paso_de_la_partida		;4291   ; el paso de la partida
	ld a,(0e002h)		;4294   ; el modo
	bit 5,a		;4297   ; bit 5: el duelo
	call nz,vuelve_al_duelo		;4299   ; en el duelo, el Q*bert que cae vuelve a salir
	ld a,(0e00dh)		;429c   ; (0xE00D): fase acabada, a la escena 8
	and a			;429f   ; puesta...
	ld a,008h		;42a0   ; ...escena 8...
	jp nz,pon_escena_a		;42a2   ; ...con 32 cuadros de espera
	ld a,(0e113h)		;42a5   ; (0xE113) puesto: Q*bert sigue en juego
	or a			;42a8   ; sigue en juego...
	ret nz			;42a9   ; ...nada mas
	ld a,(0ec51h)		;42aa   ; (0xEC51): el tiempo que queda, en BCD
	or a			;42ad   ; tiempo a cero: se pone de nuevo sin esperar
	jr z,vuelve_a_poner_a_qbert		;42ae
	ld a,(0e202h)		;42b0   ; con tiempo, espera a que acabe de caer: estados 4, 12 y 13 de 0xE202
	cp 004h		;42b3   ; cayendo por un lado
	ret z			;42b5   ; espera
	cp 00ch		;42b6   ; cayendo muerto hacia un lado
	ret z			;42b8   ; espera
	cp 00dh		;42b9   ; o hacia el otro
	ret z			;42bb   ; espera
vuelve_a_poner_a_qbert:
	ld a,001h		;42bc   ; Q*bert otra vez en juego, los dos
	ld (0e113h),a		;42be   ; el primero en juego
	ld (0e35ch),a		;42c1   ; y el segundo
	call quita_el_objeto_de_la_vida		;42c4   ; fuera el objeto de la vida extra
	ld hl,042f7h		;42c7   ; los dos sprites de Q*bert, arriba del todo y cayendo
	ld de,0e200h		;42ca   ; a los dos primeros objetos
	ld bc,00010h		;42cd   ; 16 bytes
	ldir		;42d0   ; copiados
	xor a			;42d2   ; sin bola verde, sin congelar y sin bichos parados
	ld (0e321h),a		;42d3   ; sin congelar
	ld (0e322h),a		;42d6   ; sin el poder de la bola roja
	ld (0e345h),a		;42d9   ; sin invencibilidad
	ld a,(0ec51h)		;42dc   ; sin tiempo: a la escena 6, TIME OVER
	or a			;42df   ; sin tiempo...
	jp z,escena_siguiente		;42e0   ; ...a la escena 6
	ld hl,0e110h		;42e3   ; sin vidas: a la escena 6, GAME OVER
	ld a,(hl)			;42e6   ; las vidas
	or a			;42e7   ; ninguna...
	jr z,L_42F4		;42e8   ; ...a la escena 6
	sub 001h		;42ea   ; una vida menos...
	daa			;42ec   ; en BCD
	ld (hl),a			;42ed   ; guardadas
	call pinta_las_vidas		;42ee   ; ...se pinta...
	jp tiempo_a_99		;42f1   ; ...y el tiempo vuelve a 99
L_42F4:
	jp z,escena_siguiente		;42f4   ; siempre: viene de un `jr z`

; ----------------------------------------------------------------------
; DATOS qbert_al_salir: Los dos objetos de Q*bert que 0x42C7 copia a 0xE200:
;   estado 3 (cayendo sobre la piramide), Y 0xE1 y X 0x7C, y los dos sprites
;   de 16x16, el 0 en color 10 y el 0x10 (patrones 16 a 19) en color 13. El
;   `jp z` de 0x42F4 va siempre -viene de un `jr z`-: el trazado entraria aqui
;   por la otra rama si no se declarase
;   0x42f7..0x4307  (16 bytes)
DATA_qbert_al_salir:
	defb 000h,000h,003h,000h,0e1h,07ch,000h,00ah	; 42f7  .....|..
	defb 000h,000h,003h,000h,0e1h,07ch,010h,00dh	; 42ff  .....|..

; ======================================================================
; CODIGO 0x4307..0x436a  (99 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCENA 6: EL FIN DE PARTIDA. El paso 0 separa el TIME OVER (quedaba vida pero no tiempo) del GAME OVER; el 1 espera la musica y, si quedan vidas, vuelve a la escena 4 con la misma fase.
; ----------------------------------------------------------------------
escena_fin_de_partida:
	djnz L_4332		;4307   ; paso 1
	call parpadea_el_marcador		;4309   ; en el duelo, el marcador de partidas parpadea
	ld a,(0e012h)		;430c   ; mientras suene la musica del canal 1...
	or a			;430f
	ret nz			;4310   ; ...se espera
	ld a,(0e110h)		;4311   ; con vidas, 256 cuadros y al paso 2
	or a			;4314
	jp nz,espera_a_y_sigue		;4315   ; A = vidas: la espera, y al paso 2
	ld a,(0e002h)		;4318   ; sin vidas: la musica del GAME OVER, 0x53 (0x50 en el duelo)...
	bit 5,a		;431b   ; el duelo
	ld a,053h		;431d   ; 0x53, la de un jugador...
	jr z,L_4323		;431f
	ld a,050h		;4321   ; ...o 0x50, la del duelo
L_4323:
	call toca_sonido		;4323   ; suena
	ld hl,00107h		;4326   ; ...escena 7, paso 1...
	ld (0e000h),hl		;4329   ; escena 7 y paso 1 de una vez
	ld de,07e8eh		;432c   ; ...y el rotulo GAME OVER / CONTINUE--F5
	jp pinta_guion		;432f   ; GAME OVER y CONTINUE--F5 en pantalla
L_4332:
	djnz L_4351		;4332   ; paso 2
vuelve_a_la_fase:		; Escena 4, paso 0, con 128 cuadros de espera: se repite la fase
	ld hl,00004h		;4334   ; escena 4...
	ld (0e000h),hl		;4337   ; ...y paso 0
	ld a,080h		;433a   ; 128 cuadros...
	ld (0e004h),a		;433c   ; ...de espera
	ret			;433f
musica_de_game_over:
	ld a,(0e002h)		;4340   ; el modo
	bit 5,a		;4343   ; el duelo
	ld a,053h		;4345   ; 0x53 con uno...
	jr z,L_434B		;4347
	ld a,050h		;4349   ; ...0x50 con dos
L_434B:
	call toca_sonido		;434b   ; suena
	jp escena_siguiente		;434e   ; y a la escena 7
L_4351:
	ld a,(0ec51h)		;4351   ; paso 0: si queda tiempo, es que no quedan vidas
	or a			;4354   ; queda...
	jr nz,musica_de_game_over		;4355   ; ...es un GAME OVER
	ld a,001h		;4357   ; TIME OVER: la pantalla del marcador
	ld (0e324h),a		;4359   ; (0xE324)=1: la cara con su sprite
	call pantalla_del_marcador		;435c   ; la pantalla del marcador
	ld de,0436ah		;435f
	call pinta_guion		;4362   ; TIME  OVER
	ld a,080h		;4365   ; 128 cuadros
	jp espera_a_y_sigue		;4367   ; y al paso 1

; ----------------------------------------------------------------------
; DATOS rotulo_time_over: Guion de 0x4685: "TIME  OVER" en 0x38CB
;   0x436a..0x4377  (13 bytes)
DATA_rotulo_time_over:
	defb 0cbh,038h,034h,029h,02dh,025h,000h,000h,02fh,036h,025h,032h,0ffh	; 436a  .84)-%../6%2.

; ======================================================================
; CODIGO 0x4377..0x44b8  (321 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESCENA 7: GAME OVER. Con un jugador, F5 durante la espera es el CONTINUE: puntuacion a cero, tres vidas y la misma fase. Sin F5, al logotipo.
; ----------------------------------------------------------------------
escena_game_over:
	djnz L_43AF		;4377   ; paso 1
	ld a,(0e002h)		;4379   ; el modo
	bit 5,a		;437c   ; el duelo...
	jr nz,L_4389		;437e   ; ...no tiene CONTINUE
	ld a,007h		;4380   ; fila 7 del teclado: el bit 1 es F5, a cero si esta pulsada
	call 00141h		;4382   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	bit 1,a		;4385   ; bit 1: F5
	jr z,continua_la_partida		;4387   ; pulsada: CONTINUE
L_4389:
	call parpadea_el_marcador		;4389   ; la cara parpadea
	ld a,(0e012h)		;438c   ; la musica del GAME OVER...
	or a			;438f
	ret nz			;4390   ; ...suena todavia
	ld a,03ch		;4391   ; 60 cuadros mas para pulsar F5
	jp espera_a_y_sigue		;4393   ; y al paso 2
continua_la_partida:
	ld hl,0e10bh		;4396   ; CONTINUE: la puntuacion a cero...
	ld de,0e10ch		;4399   ; los tres bytes de la puntuacion
	ld bc,00002h		;439c   ; 0xE10B-0xE10D: dos mas
	ld (hl),000h		;439f   ; el primero a cero...
	ldir		;43a1   ; ...y los otros dos
	ld hl,0e110h		;43a3   ; ...tres vidas...
	ld (hl),003h		;43a6   ; tres vidas
	inc hl			;43a8   ; 0xE111, la fase, tal cual
	inc hl			;43a9   ; 0xE112
	ld (hl),001h		;43aa   ; ...y el umbral de la vida extra otra vez en 10.000
	jp vuelve_a_la_fase		;43ac   ; y a jugar la misma fase
L_43AF:
	djnz L_43C0		;43af   ; paso 2: se acaba la espera...
	ld hl,0e004h		;43b1   ; la espera
	dec (hl)			;43b4   ; un cuadro menos
	ret nz			;43b5   ; hasta cero
	ld hl,0e002h		;43b6   ; ...se quita el bit de partida...
	ld a,(hl)			;43b9   ; el modo
	and 0bfh		;43ba   ; fuera el bit 6: sin partida
	ld (hl),a			;43bc   ; guardado
	jp vuelve_al_logotipo		;43bd   ; ...y al logotipo
L_43C0:
	ld a,001h		;43c0   ; paso 0: la pantalla del marcador
	ld (0e324h),a		;43c2   ; (0xE324)=1
	call pantalla_del_marcador		;43c5   ; la pantalla del marcador
	jp paso_siguiente		;43c8   ; y al paso 1

; ----------------------------------------------------------------------
; ESCENA 8: FASE ACABADA. El paso 0 devuelve la vida que se desconto al empezar, sube la fase (de la 50 vuelve a la 1) y monta la siguiente; tras la 3, la 6 y la 10 de cada decena, la fase de bonificacion.
; ----------------------------------------------------------------------
escena_fase_acabada:
	djnz L_43E6		;43cb   ; paso 1: espera y a la escena 4
	call parpadea_el_marcador		;43cd   ; la cara parpadea
	ld hl,0e004h		;43d0   ; la espera
	dec (hl)			;43d3   ; un cuadro menos
	ret nz			;43d4   ; hasta cero
	ld (hl),001h		;43d5   ; y se queda en uno
	ld a,(0e002h)		;43d7   ; el modo
	bit 5,a		;43da   ; en el duelo...
	jr nz,L_43E3		;43dc   ; ...sin esperar a la musica
	ld a,(0e012h)		;43de   ; con uno, la musica del canal 1...
	or a			;43e1
	ret nz			;43e2   ; ...aun suena
L_43E3:
	jp vuelve_a_la_fase		;43e3   ; a la escena 4: la fase siguiente
L_43E6:
	xor a			;43e6   ; paso 0
	ld (0e00dh),a		;43e7   ; (0xE00D)=0
	ld a,(0e002h)		;43ea   ; el modo
	bit 5,a		;43ed   ; el duelo
	jr nz,L_440A		;43ef   ; con un jugador...
	call mira_la_bonificacion		;43f1   ; ...quiza la fase de bonificacion, que no vuelve de aqui
	ld hl,0e110h		;43f4   ; la vida que se desconto al empezar
	ld a,(hl)			;43f7   ; las vidas...
	add a,001h		;43f8   ; ...mas una...
	daa			;43fa   ; ...en BCD
	ld (hl),a			;43fb   ; guardadas
	inc hl			;43fc   ; la fase siguiente, en BCD
	ld a,(hl)			;43fd   ; la fase...
	add a,001h		;43fe   ; ...mas una...
	daa			;4400   ; ...en BCD
	ld (hl),a			;4401   ; guardada
	cp 051h		;4402   ; despues de la 50, la 1
	jr c,L_440F		;4404   ; hasta la 50, tal cual
	ld (hl),001h		;4406   ; la 51 es la 1
	jr L_440F		;4408   ; y sigue
L_440A:
	ld a,059h		;440a   ; en el duelo, silencio
	call toca_sonido		;440c   ; sonido 0x59: silencio
L_440F:
	call carga_el_tablero_siguiente		;440f   ; el tablero de la fase nueva
	xor a			;4412   ; (0xE324)=0: la cara sin sprite
	ld (0e324h),a		;4413   ; guardado
	call pantalla_del_marcador		;4416   ; la pantalla del marcador
	ld a,080h		;4419   ; 128 cuadros
	jp espera_a_y_sigue		;441b   ; y al paso 1

; ----------------------------------------------------------------------
; LO QUE MIRA LA VUELTA DE LAS ESCENAS SIN PARTIDA. Cualquier tecla en el logotipo o la demostracion salta al titulo; en el titulo, las direcciones cambian 1PLAYER/2PLAYERS y el disparo empieza.
; ----------------------------------------------------------------------
mira_si_empiezan:
	call lee_el_puerto_1		;441e   ; el mando 1 y el teclado...
	call lee_cursores_espacio_y_select		;4421   ; encima, los cursores, el espacio y SELECT
	ld hl,0e101h		;4424   ; ...y lo que ACABA de pulsarse, en (0xE100)
	call guarda_mando_en_hl		;4427   ; (0xE101) y (0xE100)
	or a			;442a   ; nada recien pulsado...
	ret z			;442b   ; ...vuelve
	ld hl,0e004h		;442c   ; la espera a cero, y HL=0xE000
	ld (hl),000h		;442f   ; (0xE004)=0
	ld l,(hl)			;4431   ; L=0: HL=0xE000
	ld de,0e102h		;4432   ; DE: uno o dos jugadores
	ld b,(hl)			;4435   ; fuera de la escena 1, al titulo
	djnz salta_al_titulo		;4436   ; escena distinta de 1: al titulo
	inc hl			;4438   ; 0xE001: el paso
	ld b,a			;4439   ; lo pulsado, en B
	ld a,(hl)			;443a   ; el paso...
	dec hl			;443b   ; HL otra vez en 0xE000
	cp 009h		;443c   ; en la escena 1, antes del paso 9 tambien
	ld a,b			;443e   ; A = lo pulsado
	jr c,salta_al_titulo		;443f   ; antes del paso 9: al titulo
	and 030h		;4441   ; bits 4 y 5: el disparo (o el espacio)
	jr z,cambia_uno_o_dos_jugadores		;4443   ; solo direcciones: cambia la opcion
	ld a,(de)			;4445   ; (0xE102): uno o dos jugadores
	or a			;4446   ; 0: un jugador
	ld a,040h		;4447   ; 0x40: partida; 0x60: partida de dos
	jr z,L_444D		;4449   ; 0x40...
	ld a,060h		;444b   ; ...o 0x60
L_444D:
	ld (0e002h),a		;444d   ; el modo de la partida
	ld (hl),003h		;4450   ; escena 3, paso 0: el menu de nivel
	inc hl			;4452   ; 0xE001
	ld c,000h		;4453   ; paso 0
	ld (hl),c			;4455   ; guardado
	dec c			;4456   ; C=0xFF: pinta
	call pinta_la_mano		;4457   ; las dos lineas con la mano en la buena
	jp partida_nueva		;445a   ; y los datos de la partida
salta_al_titulo:
	ld (hl),001h		;445d   ; escena 1, paso 10
	inc hl			;445f   ; 0xE001
	ld (hl),00ah		;4460   ; paso 10
	ld a,059h		;4462   ; silencio
	call toca_sonido		;4464   ; silencio
	jp pinta_el_titulo		;4467   ; el titulo
cambia_uno_o_dos_jugadores:
	ld a,(de)			;446a   ; uno o dos...
	xor 001h		;446b   ; ...el otro
	ld (de),a			;446d   ; guardado
	ld a,003h		;446e   ; sonido 3, el del cursor
	call toca_sonido		;4470   ; sonido 3
	ret			;4473   ; vuelta
gancho_vacio:		; Un `ret` solo; 0x426A lo llama detras del rotulo de STAGE
	ret			;4474   ; no hace nada
partida_nueva:		; Borra de 0xE108 a 0xE4FF y pone tres vidas, fase 1 y el umbral de la vida extra
	ld hl,0e108h		;4475   ; desde 0xE108
	ld bc,003f7h		;4478   ; hasta 0xE4FF
	ld d,h			;447b   ; DE = HL...
	ld e,l			;447c
	inc e			;447d   ; ...+ 1
	ld (hl),000h		;447e   ; el cero
	ldir		;4480   ; corrido
	ld a,(0e114h)		;4482   ; (0xE114) acaba de borrarla el `ldir`: este salto no se toma nunca
	or a			;4485   ; (0xE114), siempre cero aqui
	jr nz,fase_del_game_master_muerta		;4486   ; nunca salta
pon_vidas_fase_y_umbral:		; Los tres bytes de 0x44B8 a 0xE110 (y a 0xE120 con dos jugadores)
	ld hl,044b8h		;4488   ; los tres bytes de 0x44B8 a 0xE110
	ld de,0e110h		;448b   ; a 0xE110...
	ld bc,00003h		;448e   ; ...tres bytes
	ldir		;4491   ; copiados
	ld a,(0e002h)		;4493   ; con dos jugadores, lo mismo en la copia del segundo
	and 020h		;4496   ; bit 5: dos jugadores
	ret z			;4498   ; uno: ya esta
copia_al_segundo_jugador:
	ld hl,0e110h		;4499   ; de 0xE110...
	ld de,0e120h		;449c   ; ...a 0xE120...
	ld bc,00010h		;449f   ; ...16 bytes
	ldir		;44a2   ; copiados
	ret			;44a4   ; vuelta
fase_del_game_master_muerta:
	call bcd_de_a		;44a5   ; CODIGO MUERTO: solo se llega si (0xE114) no es cero justo despues de borrarla. Y si llegara, el `jr` de 0x44B6 no sale nunca
	cp 050h		;44a8   ; como mucho, la 50
	jr c,L_44AE		;44aa   ; menos: tal cual
	ld a,050h		;44ac   ; la 50
L_44AE:
	ld (0e111h),a		;44ae   ; la fase
	ld a,001h		;44b1   ; el umbral de la vida extra...
	ld (0e112h),a		;44b3   ; ...en 10.000
	jr fase_del_game_master_muerta		;44b6   ; y otra vez: no sale

; ----------------------------------------------------------------------
; DATOS partida_recien_puesta: Los tres bytes que 0x4488 copia a 0xE110: tres
;   vidas, fase 01 y el umbral de la vida extra en 01 (10.000 puntos: es el
;   byte alto de la puntuacion)
;   0x44b8..0x44bb  (3 bytes)
DATA_partida_recien_puesta:
	defb 003h,001h,001h	; 44b8

; ======================================================================
; CODIGO 0x44bb..0x454c  (145 bytes)
; ======================================================================


aplica_la_fase_del_game_master:		; Si el Game Master escribio una fase en (0xE114), la partida empieza en ella (en BCD, y como mucho la 50)
	ld hl,0e114h		;44bb   ; la fase que escribio el Game Master
	ld a,(hl)			;44be   ; si...
	or a			;44bf   ; ...no hay...
	ret z			;44c0   ; ...nada
	ld (hl),000h		;44c1   ; se consume
	call bcd_de_a		;44c3   ; en BCD
	cp 050h		;44c6   ; como mucho...
	jr c,L_44CC		;44c8   ; ...la 50
	ld a,050h		;44ca   ; la 50
L_44CC:
	ld (0e111h),a		;44cc   ; la fase de la partida
	ld a,(0e002h)		;44cf   ; el modo
	and 020h		;44d2   ; dos jugadores...
	ret z			;44d4   ; ...no: ya esta
	jp copia_al_segundo_jugador		;44d5   ; si: tambien la del segundo
esconde_los_sprites:		; Y=0xD0 en el primer sprite: el VDP no pinta ni ese ni los de detras
	ld hl,03b00h		;44d8   ; el primer sprite
	ld a,0d0h		;44db   ; 0xD0: fin de la lista
	call 0004dh		;44dd   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	xor a			;44e0   ; A=0
	ret			;44e1   ; vuelta

; ----------------------------------------------------------------------
; SUMA PUNTOS. DE en BCD se suma a la puntuacion de 0xE10B (E a las unidades y decenas, D a las centenas y millares): 0x0010 son 10 puntos y 0x5000 son 5.000. Ni en la demostracion ni en el duelo. Cada vez que el byte alto llega al umbral de (0xE112), una vida mas y el umbral sube 5: vidas a los 10.000, 60.000, 110.000...
; ----------------------------------------------------------------------
suma_puntos:
	ld c,000h		;44e2   ; el tercer byte no se toca: C=0
	ld a,(0e002h)		;44e4   ; sin partida (demostracion), nada
	or a			;44e7   ; modo 0: la demostracion
	ret z			;44e8   ; no puntua
	bit 5,a		;44e9   ; en el duelo, tampoco
	ret nz			;44eb   ; duelo: no puntua
	ld hl,0e10bh		;44ec   ; unidades y decenas
	ld a,(hl)			;44ef   ; el byte bajo...
	add a,e			;44f0   ; ...+ E...
	daa			;44f1   ; ...en BCD
	ld (hl),a			;44f2   ; guardado
	inc l			;44f3   ; centenas y millares
	ld a,(hl)			;44f4   ; el de en medio...
	adc a,d			;44f5   ; ...+ D y el acarreo...
	daa			;44f6   ; ...en BCD
	ld (hl),a			;44f7   ; guardado
	inc hl			;44f8   ; decenas y centenas de millar
	ld a,(hl)			;44f9   ; el alto...
	adc a,c			;44fa   ; ...+ el acarreo...
	daa			;44fb   ; ...en BCD
	ld (hl),a			;44fc   ; guardado
	jr nc,mira_la_vida_extra		;44fd   ; se ha pasado de 999999
	ld bc,09999h		;44ff   ; el record se queda en 999999
	ld (0e105h),bc		;4502   ; 0xE105 y 0xE106
	ld (0e106h),bc		;4506   ; 0xE106 y 0xE107
	jp pinta_la_puntuacion		;450a   ; la puntuacion en pantalla
mira_la_vida_extra:
	ex de,hl			;450d   ; DE: el byte alto
	ld hl,0e112h		;450e   ; el umbral
	cp (hl)			;4511   ; el byte alto contra el umbral
	jr c,mira_el_record		;4512   ; no llega: al record
	ld a,(hl)			;4514   ; umbral + 5, en BCD; si se sale, 0xFF y no hay mas
	add a,005h		;4515   ; cinco mas...
	daa			;4517   ; ...en BCD
	jr nc,L_451C		;4518   ; sin pasarse...
	ld a,0ffh		;451a   ; ...o 0xFF: ya no hay mas
L_451C:
	ld (hl),a			;451c   ; el umbral nuevo
	push de			;451d   ; se guarda DE
	ld hl,0e110h		;451e   ; y la vida
	ld a,(hl)			;4521   ; las vidas...
	add a,001h		;4522   ; ...mas una...
	daa			;4524   ; ...en BCD
	ld (hl),a			;4525   ; guardadas
	ld a,011h		;4526   ; sonido 0x11, el de la vida extra
	call toca_sonido_en_partida		;4528   ; el sonido de la vida
	call pinta_las_vidas		;452b   ; en pantalla
	pop de			;452e   ; DE otra vez
mira_el_record:
	ld b,003h		;452f   ; compara la puntuacion con el record de mas a menos significativo
	ld hl,0e107h		;4531   ; el byte alto del record
	ex de,hl			;4534   ; DE el record, HL la puntuacion
	ld c,l			;4535   ; C: donde empieza la puntuacion
L_4536:
	ld a,(de)			;4536   ; cifra del record...
	sub (hl)			;4537   ; ...menos la de la puntuacion
	jr c,L_4541		;4538   ; la puntuacion es mayor: se copia
	jp nz,pinta_la_puntuacion		;453a   ; menor: solo se pinta
	dec l			;453d   ; iguales: el byte siguiente
	dec e			;453e   ; de los dos
	djnz L_4536		;453f   ; tres bytes
L_4541:
	ld l,c			;4541   ; la supera: se copia encima
	ld bc,00003h		;4542   ; los tres...
	ld e,007h		;4545   ; ...hasta 0xE107...
	lddr		;4547   ; ...de arriba abajo
	jp pinta_la_puntuacion		;4549   ; y la puntuacion en pantalla

; ----------------------------------------------------------------------
; DATOS ret_suelto: Un `ret` (0xC9) que no ejecuta nadie: detras del `jp` de
;   0x4549 y sin ninguna referencia en los 32 KB (tools/apunta_a.py)
;   0x454c..0x454d  (1 bytes)
DATA_ret_suelto:
	defb 0c9h	; 454c

; ======================================================================
; CODIGO 0x454d..0x4591  (68 bytes)
; ======================================================================


pinta_los_marcadores_del_game_over:		; HI-SCORE, REST, STAGE y 1P-SCORE, con sus numeros
	ld de,07eb0h		;454d   ; HI-SCORE, REST, STAGE- y 1P-SCORE
	call pinta_guion		;4550   ; en pantalla
	ld a,(0e002h)		;4553   ; el modo
	bit 5,a		;4556   ; el duelo...
	jr z,L_455E		;4558   ; ...no
	cpl			;455a   ; A invertido
	call pinta_la_puntuacion_en_hl		;455b   ; la puntuacion donde se quedo HL
L_455E:
	call pinta_las_vidas_del_game_over		;455e   ; las vidas
	call pinta_la_fase_del_game_over		;4561   ; la fase
	jp pinta_record_y_puntuacion		;4564   ; el record y la puntuacion
pinta_el_marcador:		; La linea de arriba: STAGE-nn SCORE-nnnnnn P-nn
	ld de,04607h		;4567   ; STAGE-, SCORE- y P-
	call pinta_guion		;456a   ; en la fila 0
	call pinta_la_fase		;456d   ; la fase
	call pinta_la_puntuacion		;4570   ; la puntuacion
	jr $+101		;4573   ; y las vidas, en 0x45D8
pinta_el_marcador_del_duelo:		; 2P- y 1P- con las vidas de cada uno
	call fila_0_de_ladrillo		;4575   ; la fila 0, toda de ladrillo
	ld de,04591h		;4578   ; 2P- y 1P-
	call pinta_guion		;457b   ; en pantalla
pinta_las_vidas_de_los_dos:
	ld hl,03805h		;457e   ; detras de 2P-...
	ld de,0e120h		;4581   ; ...las vidas del segundo
	call pinta_un_byte_bcd		;4584   ; dos cifras
	ld hl,0381ch		;4587   ; detras de 1P-...
	ld de,0e110h		;458a   ; ...las del primero
pinta_un_byte_bcd:
	ld b,001h		;458d   ; un byte
	jr $+83		;458f   ; a pinta_bcd

; ----------------------------------------------------------------------
; DATOS rotulos_2p_y_1p: Guion de 0x4685: "2P-" en 0x3802 y "1P-" en 0x3819
;   (0x20 es el guion)
;   0x4591..0x459d  (12 bytes)
DATA_rotulos_2p_y_1p:
	defb 002h,038h,012h,030h,020h,0feh	; 4591
	defb 019h,038h,011h,030h,020h,0ffh	; 4597

; ======================================================================
; CODIGO 0x459d..0x4607  (106 bytes)
; ======================================================================


pinta_record_y_puntuacion:		; En la pantalla del GAME OVER
	ld hl,03972h		;459d   ; HI-SCORE...
	ld de,0e107h		;45a0   ; ...el record, tres bytes
	call pinta_tres_bytes_bcd		;45a3   ; en pantalla
	ld hl,03932h		;45a6   ; 1P-SCORE...
pinta_la_puntuacion_en_hl:
	ld de,0e10dh		;45a9   ; ...la puntuacion
pinta_tres_bytes_bcd:
	ld b,003h		;45ac   ; tres bytes
	jr pinta_bcd		;45ae   ; seis cifras
pinta_la_puntuacion:		; Seis cifras en 0x3812
	ld hl,03812h		;45b0   ; detras de SCORE-
	ld de,0e10dh		;45b3   ; desde el byte alto
	ld b,003h		;45b6   ; tres bytes
	jr pinta_bcd		;45b8   ; seis cifras
pinta_la_fase_del_game_over:
	ld hl,038d2h		;45ba   ; detras de STAGE-, en la pantalla del marcador
pinta_la_fase_en_hl:
	ld de,0e111h		;45bd   ; la fase
	ld b,001h		;45c0   ; un byte
	jr pinta_bcd		;45c2   ; dos cifras
pinta_la_fase:		; Dos cifras en 0x3808
	ld hl,03808h		;45c4   ; detras de STAGE-
	ld de,0e111h		;45c7   ; la fase
	ld b,001h		;45ca   ; un byte
	jr pinta_bcd		;45cc   ; dos cifras
pinta_las_vidas_del_game_over:
	ld hl,039d2h		;45ce   ; detras de REST
	ld de,0e110h		;45d1   ; las vidas
	ld b,001h		;45d4   ; un byte
	jr pinta_bcd		;45d6   ; dos cifras
pinta_las_vidas:		; Dos cifras en 0x381C
	ld hl,0381ch		;45d8   ; detras de P-
	ld de,0e110h		;45db   ; las vidas
	ld b,001h		;45de   ; un byte
	jr pinta_bcd		;45e0   ; dos cifras

; ----------------------------------------------------------------------
; PINTA B BYTES EN BCD de DE hacia abajo, dos cifras por byte, en la tabla de nombres desde HL. Las cifras son las casillas 0x10 a 0x19.
; ----------------------------------------------------------------------
pinta_bcd:
	ld a,(de)			;45e2   ; la cifra alta...
	rra			;45e3   ; el nibble alto...
	rra			;45e4
	rra			;45e5
	rra			;45e6
	and 00fh		;45e7   ; ...abajo
	add a,010h		;45e9   ; ...a su casilla
	call 0004dh		;45eb   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;45ee   ; la casilla siguiente
	ld a,(de)			;45ef   ; la baja
	and 00fh		;45f0   ; el nibble bajo
	add a,010h		;45f2   ; su casilla
	call 0004dh		;45f4   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	dec de			;45f7   ; el byte de antes: el mas significativo va primero
	inc hl			;45f8   ; y la siguiente
	djnz pinta_bcd		;45f9   ; B bytes
	ret			;45fb   ; vuelta
vuelta_con_partida:		; El `ret` al que vuelven las escenas durante la partida
	ret			;45fc   ; y la escena acaba aqui
intercambia_b_bytes:		; Intercambia B bytes entre (HL) y (DE)
	ld c,(hl)			;45fd   ; CODIGO HUERFANO: nadie lo llama ni apunta aqui
	ld a,(de)			;45fe   ; el de (DE)...
	ld (hl),a			;45ff   ; ...a (HL)...
	ld a,c			;4600   ; ...y el de (HL)...
	ld (de),a			;4601   ; ...a (DE)
	inc hl			;4602   ; los dos punteros...
	inc de			;4603   ; ...avanzan
	djnz intercambia_b_bytes		;4604   ; B bytes
	ret			;4606   ; vuelta

; ----------------------------------------------------------------------
; DATOS rotulo_del_marcador: Guion de 0x4685 con la linea de arriba entera
;   desde 0x3800: STAGE-, SCORE- y P-, con el tile 0xEB (el negro del marco)
;   de separador
;   0x4607..0x462a  (35 bytes)
DATA_rotulo_del_marcador:
	defb 000h,038h,0ebh,0ebh,033h,034h,021h,027h	; 4607  .8..34!'
	defb 025h,020h,0ebh,0ebh,0ebh,0ebh,033h,023h	; 460f  % ....3#
	defb 02fh,032h,025h,020h,0ebh,0ebh,0ebh,0ebh	; 4617  /2% ....
	defb 0ebh,0ebh,0ebh,0ebh,030h,020h,0ebh,0ebh	; 461f  ....0 ..
	defb 0ebh,0ebh,0ffh	; 4627

; ======================================================================
; CODIGO 0x462a..0x46f0  (198 bytes)
; ======================================================================


borra_la_pantalla:		; Esconde los sprites y pone a cero la tabla de nombres (0x3800, 768 casillas)
	call esconde_los_sprites		;462a   ; sin sprites
	ld hl,03800h		;462d   ; la tabla de nombres...
	ld bc,00300h		;4630   ; ...768 casillas...
	xor a			;4633   ; ...a cero
	jp 00056h		;4634   ; BIOS FILVRM - Fills VRAM with value | FILVRM
prepara_escritura_de_vram:		; SETWRT en HL y el puerto de datos del VDP (el de 0x0007 de la BIOS) en C' para los `out (c)`
	ex af,af'			;4637   ; A a salvo
	call 00053h		;4638   ; BIOS SETWRT - Enables VDP to write | SETWRT
	exx			;463b   ; en los registros de reserva...
	ld a,(00007h)		;463c   ; el puerto de escritura del VDP, tal como lo dice la BIOS
	ld c,a			;463f   ; ...C = el puerto
	exx			;4640   ; y otra vez los normales
	ex af,af'			;4641   ; A de vuelta
	ret			;4642   ; vuelta
prepara_lectura_de_vram:		; La pareja de 0x4637 para leer: SETRD y el puerto de 0x0006
	call 00050h		;4643   ; BIOS SETRD - Enables VDP to read | CODIGO HUERFANO: nadie lo llama; el juego no lee la VRAM por el puerto
	exx			;4646   ; en los de reserva...
	ld a,(00006h)		;4647   ; el puerto de lectura del VDP
	ld c,a			;464a   ; ...C = el puerto
	exx			;464b   ; otra vez los normales
	ret			;464c   ; vuelta
copia_a_vram:		; BC bytes de (DE) a la VRAM en HL: LDIRVM con los punteros cambiados
	ex de,hl			;464d   ; HL el origen, DE el destino
	jp 0005ch		;464e   ; BIOS LDIRVM - Block transfers to VRAM from memory | LDIRVM
copia_a_los_tres_bancos:		; Lo mismo tres veces, a 0x800 de distancia: los tres tercios de la pantalla
	exx			;4651   ; B' = 3 tercios
	ld b,003h		;4652   ; tres tercios
copia_un_banco:
	exx			;4654   ; los normales
	push bc			;4655   ; BC y DE...
	push de			;4656   ; ...a salvo
	call copia_a_vram		;4657   ; un tercio
	ld de,00800h		;465a   ; el tercio siguiente
	add hl,de			;465d   ; HL + 0x800
	pop de			;465e   ; DE y BC...
	pop bc			;465f   ; ...otra vez
	exx			;4660   ; B' cuenta
	djnz copia_un_banco		;4661   ; tres veces
	ret			;4663   ; vuelta
rellena_los_tres_bancos:		; FILVRM de BC bytes con A, en HL, HL+0x800 y HL+0x1000
	ld d,003h		;4664   ; tres tercios
L_4666:
	push bc			;4666   ; BC...
	push de			;4667   ; ...y DE a salvo
	call 00056h		;4668   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld de,00800h		;466b   ; el tercio siguiente...
	add hl,de			;466e   ; ...0x800 mas alla
	pop de			;466f   ; DE...
	pop bc			;4670   ; ...y BC otra vez
	dec d			;4671   ; uno menos
	jr nz,L_4666		;4672   ; tres veces
	ret			;4674   ; vuelta
guion_rle_en_tres_bancos:		; El guion RLE de DE, tres veces, desde HL, HL+0x800 y HL+0x1000
	ld b,003h		;4675   ; tres tercios
L_4677:
	push bc			;4677   ; B...
	push de			;4678   ; ...y el guion a salvo
	call vuelca_el_guion_con_destino_en_hl		;4679   ; un tercio
	ld de,00800h		;467c   ; el siguiente...
	add hl,de			;467f   ; ...0x800 mas alla
	pop de			;4680   ; el guion otra vez desde el principio
	pop bc			;4681   ; y B
	djnz L_4677		;4682   ; tres veces
	ret			;4684   ; vuelta

; ----------------------------------------------------------------------
; EL GUION DE TEXTO. En DE: una direccion de la tabla de nombres y los caracteres detras; 0xFE salta a otra direccion (la que sigue) y 0xFF acaba. Cada caracter se pasa por AND C: con C=0xFF pinta, con C=0 borra el mismo rotulo en su sitio.
; ----------------------------------------------------------------------
pinta_guion:
	ld c,0ffh		;4685   ; C=0xFF: pinta
guion_nueva_direccion:
	ex de,hl			;4687   ; la direccion de destino, los dos primeros bytes
	ld e,(hl)			;4688   ; el byte bajo...
	inc hl			;4689   ; ...y el alto
	ld d,(hl)			;468a   ; HL = la direccion
	ex de,hl			;468b   ; DE sigue en el guion
	inc de			;468c   ; salta el byte alto
byte_del_guion:
	ld a,(de)			;468d   ; el caracter
	inc de			;468e   ; el siguiente
	ld b,a			;468f   ; 0xFF + 1 = 0: fin
	inc b			;4690   ; 0xFF: B = 0
	ret z			;4691   ; se acabo
	inc b			;4692   ; 0xFE + 2 = 0: otra direccion
	jr z,guion_nueva_direccion		;4693   ; 0xFE: B = 0
	and c			;4695   ; AND C: el caracter o un cero
	call 0004dh		;4696   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;4699   ; la casilla siguiente
	jr byte_del_guion		;469a   ; y el caracter siguiente
borra_guion:		; El mismo guion con C=0: pone ceros donde iba el texto
	ld c,000h		;469c   ; C=0: borra
	jr guion_nueva_direccion		;469e   ; y adelante

; ----------------------------------------------------------------------
; EL RLE DE LA VRAM. En DE: la direccion de destino y luego ordenes de un byte: 0x00 acaba, 0x01-0x7F repite el byte siguiente ese numero de veces, 0x81-0xFF copia literales (el numero menos 0x80) y 0x80 cambia de direccion con la palabra que sigue.
; ----------------------------------------------------------------------
guion_rle:
	ex de,hl			;46a0   ; la direccion, los dos primeros bytes
	ld e,(hl)			;46a1   ; el byte bajo...
	inc hl			;46a2   ; ...y el alto
	ld d,(hl)			;46a3   ; de la direccion
	ex de,hl			;46a4   ; HL = destino
	inc de			;46a5   ; DE, detras
vuelca_el_guion_con_destino_en_hl:
	call prepara_escritura_de_vram		;46a6   ; SETWRT y el puerto en C'
orden_del_rle:
	ld a,(de)			;46a9   ; la orden
	and a			;46aa   ; 0x00: fin
	ret z			;46ab   ; 0x00: se acabo
	inc de			;46ac   ; la siguiente
	ld b,a			;46ad   ; B = la orden
	and 07fh		;46ae   ; sin el bit 7...
	cp b			;46b0   ; igual: bit 7 a cero
	jr z,repite_un_byte		;46b1   ; ...es una repeticion
	and a			;46b3   ; 0x80 a secas: direccion nueva
	jr z,guion_rle		;46b4   ; 0x80: nueva direccion
	ld b,a			;46b6   ; 0x81-0xFF: tantos literales
copia_literales:
	ld a,(de)			;46b7   ; el literal
	inc de			;46b8   ; el siguiente
	exx			;46b9   ; con el puerto de C'...
	out (c),a		;46ba   ; ...al VDP
	exx			;46bc   ; los normales
	djnz copia_literales		;46bd   ; B literales
	jr orden_del_rle		;46bf   ; la orden siguiente
repite_un_byte:
	ld a,(de)			;46c1   ; el byte que se repite
	inc de			;46c2   ; detras
L_46C3:
	exx			;46c3   ; con el puerto de C'...
	out (c),a		;46c4   ; ...al VDP
	exx			;46c6   ; los normales
	djnz L_46C3		;46c7   ; B veces
	jr orden_del_rle		;46c9   ; la orden siguiente
apaga_y_borra_la_vram:		; Silencio, toda la VRAM a cero y los registros del VDP de 0x46F0
	ld a,0bfh		;46cb   ; mezclador del PSG: los seis canales cerrados
	call escribe_el_mezclador		;46cd   ; al registro 7
	ld a,059h		;46d0   ; sonido 0x59: todo en silencio
	call toca_sonido		;46d2   ; todos los canales libres
	ld hl,00000h		;46d5   ; los 16 KB de VRAM a cero
	ld bc,04000h		;46d8   ; 16 KB...
	xor a			;46db   ; ...a cero
	call 00056h		;46dc   ; BIOS FILVRM - Fills VRAM with value | FILVRM
pon_los_registros_del_vdp:
	ld hl,046f0h		;46df   ; la tabla de 0x46F0
	ld d,008h		;46e2   ; ocho registros
	ld c,000h		;46e4   ; desde el 0
L_46E6:
	ld b,(hl)			;46e6   ; WRTVDP, registro C con el valor B
	call 00047h		;46e7   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP
	inc hl			;46ea   ; el siguiente valor
	inc c			;46eb   ; el siguiente registro
	dec d			;46ec   ; ocho
	jr nz,L_46E6		;46ed   ; veces
	ret			;46ef   ; vuelta

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho: SCREEN 2 (0x02); 16 KB, pantalla
;   encendida, interrupcion y sprites de 16x16 (0xE2); nombres en 0x3800
;   (0x0E); color en 0x0000 (0x7F); patrones en 0x2000 (0x07); atributos de
;   sprites en 0x3B00 (0x76); patrones de sprites en 0x1800 (0x03); y fondo
;   azul oscuro con letra gris (0xE4)
;   0x46f0..0x46f8  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e4h	; 46f0  .....v..

; ======================================================================
; CODIGO 0x46f8..0x4788  (144 bytes)
; ======================================================================


pon_el_fondo:		; Registro 7 con B: el color del fondo
	ld c,007h		;46f8   ; registro 7
	jp 00047h		;46fa   ; BIOS WRTVDP - Writes data in the VDP-register | WRTVDP con B

; ----------------------------------------------------------------------
; LOS MANDOS, una vez por cuadro. El mando 2 va con la lectura del puerto 2 y las teclas E, S, F, C y CTRL a 0xE330/0xE32F; el mando 1, con el puerto 1, los cursores, el espacio y SELECT, a 0xE009/0xE008. El segundo byte de cada pareja es lo que ACABA de pulsarse. Los bits: 0 arriba, 1 abajo, 2 izquierda, 3 derecha, 4 y 5 los dos disparos.
; ----------------------------------------------------------------------
lee_los_mandos:
	ld e,0cfh		;46fd   ; puerto 2 del PSG (bit 6 del registro 15 a uno)
	call lee_el_puerto_en_e		;46ff   ; el puerto 2
	call lee_las_teclas_del_segundo		;4702   ; y E-S-F-C-CTRL encima
	ld hl,0e330h		;4705   ; al mando 2
	call guarda_mando_en_hl		;4708   ; a 0xE330 y 0xE32F
	call lee_el_puerto_1		;470b   ; puerto 1 y los cursores
	call lee_cursores_espacio_y_select		;470e   ; encima, los cursores, el espacio y SELECT
guarda_el_mando_1:
	ld hl,0e009h		;4711   ; el mando 1
guarda_mando_en_hl:		; (HL)=lo pulsado y (HL-1)=lo que no lo estaba en la lectura anterior
	ld c,(hl)			;4714   ; C = lo de antes
	ld (hl),a			;4715   ; lo de ahora, guardado
	xor c			;4716   ; lo de antes, invertido...
	and (hl)			;4717   ; ...y con lo de ahora: lo recien pulsado
	dec hl			;4718   ; el byte de antes
	ld (hl),a			;4719   ; lo recien pulsado
	ret			;471a   ; vuelta
lee_el_puerto_1:
	ld e,08fh		;471b   ; bit 6 a cero: el puerto 1
lee_el_puerto_en_e:		; E al registro 15 del PSG (el puerto) y el 14 leido: los seis bits, a uno lo pulsado
	ld a,00fh		;471d   ; registro 15...
	call 00093h		;471f   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,00eh		;4722   ; registro 14...
	di			;4724   ; sin interrupciones...
	call 00096h		;4725   ; BIOS RDPSG - Reads value from PSG-register | RDPSG
	ei			;4728   ; ...para leerlo
	cpl			;4729   ; los botones van a cero: se invierten
	and 03fh		;472a   ; seis bits
	ret			;472c   ; vuelta

; ----------------------------------------------------------------------
; LOS CURSORES, EL ESPACIO Y SELECT, colocados en los bits del mando: se leen las filas 8 y 7 del teclado y se reordenan a golpe de `rrca`.
; ----------------------------------------------------------------------
lee_cursores_espacio_y_select:
	push af			;472d   ; lo del puerto, a salvo
	ld a,007h		;472e   ; fila 7 del teclado
	call 00141h		;4730   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	cpl			;4733   ; pulsado a uno
	rrca			;4734   ; el bit 6 (SELECT) al bit 5
	and 020h		;4735   ; el bit 5
	ld e,a			;4737   ; en E
	ld a,008h		;4738   ; fila 8: derecha, abajo, arriba, izquierda... y el espacio en el bit 0
	call 00141h		;473a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	cpl			;473d   ; pulsado a uno
	rrca			;473e
	rrca			;473f
	ld b,a			;4740   ; B, para seguir rotando
	and 004h		;4741   ; izquierda al bit 2
	or e			;4743   ; con SELECT
	ld c,a			;4744   ; en C
	ld a,b			;4745   ; dos vueltas mas
	rrca			;4746
	rrca			;4747
	ld b,a			;4748   ; en B
	and 018h		;4749   ; derecha y espacio a los bits 3 y 4
	or c			;474b   ; con lo de antes
	ld c,a			;474c   ; en C
	ld a,b			;474d   ; una vuelta mas
	rrca			;474e   ; arriba al bit 0, abajo al 1
	and 003h		;474f   ; arriba y abajo a los bits 0 y 1
	or c			;4751   ; todo junto
	pop bc			;4752   ; y encima de lo que leyo el puerto
	or b			;4753   ; con lo del puerto
	ret			;4754   ; vuelta

; ----------------------------------------------------------------------
; LAS TECLAS DEL SEGUNDO JUGADOR: E arriba, C abajo, S izquierda y F derecha (un rombo, como las cuatro diagonales del juego), y CTRL de disparo.
; ----------------------------------------------------------------------
lee_las_teclas_del_segundo:
	push af			;4755   ; lo del puerto, a salvo
	ld b,000h		;4756   ; B: lo pulsado
	ld a,003h		;4758   ; fila 3
	call 00141h		;475a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 3 del teclado
	bit 0,a		;475d   ; bit 0: la C, abajo
	jr nz,L_4763		;475f   ; no pulsada
	set 1,b		;4761   ; abajo
L_4763:
	bit 2,a		;4763   ; bit 2: la E, arriba
	jr nz,L_4769		;4765   ; no pulsada
	set 0,b		;4767   ; arriba
L_4769:
	bit 3,a		;4769   ; bit 3: la F, derecha
	jr nz,L_476F		;476b   ; no pulsada
	set 3,b		;476d   ; derecha
L_476F:
	ld a,005h		;476f   ; fila 5
	call 00141h		;4771   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 5, bit 0: la S, izquierda
	bit 0,a		;4774   ; bit 0: la S
	jr nz,L_477A		;4776   ; no pulsada
	set 2,b		;4778   ; izquierda
L_477A:
	ld a,006h		;477a   ; fila 6
	call 00141h		;477c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 6, bit 1: CTRL, el disparo
	bit 1,a		;477f   ; bit 1: CTRL
	jr nz,L_4785		;4781   ; no pulsada
	set 4,b		;4783   ; el disparo
L_4785:
	pop af			;4785   ; lo del puerto
	or b			;4786   ; con las teclas
	ret			;4787   ; vuelta

; ----------------------------------------------------------------------
; DATOS rotulos_del_titulo: Guiones de 0x4685: "STAGE" en 0x394C; "(c)KONAMI
;   1986" en 0x382A y "1PLAYER" en 0x396C (el que empieza en 0x4790);
;   "2PLAYERS" en 0x398C (0x47A9); y en 0x47B4 los dos tiles de la mano del
;   cursor, 0x1B y 0x1C, sin direccion: los pinta 0x4B3A donde diga HL
;   0x4788..0x47b7  (47 bytes)
DATA_rotulos_del_titulo:
	defb 04ch,039h,033h,034h,021h,027h,025h,0ffh	; 4788  L934!'%.
	defb 02ah,038h,01ah,02bh,02fh,02eh,021h,02dh	; 4790  *8.+/.!-
	defb 029h,000h,011h,019h,018h,016h,0feh,06ch	; 4798  )......l
	defb 039h,011h,030h,02ch,021h,039h,025h,032h	; 47a0  9.0,!9%2
	defb 0ffh,08ch,039h,012h,030h,02ch,021h,039h	; 47a8  ..9.0,!9
	defb 025h,032h,033h,0ffh,01bh,01ch,0ffh	; 47b0

; ======================================================================
; CODIGO 0x47b7..0x47ef  (56 bytes)
; ======================================================================


monta_la_fuente:		; La fuente RLE de 0x47EF en los tres tercios desde el tile 0x10, y su color, blanco sobre transparente (0xF0)
	call limpia_la_fuente		;47b7   ; los 16 primeros tiles
	ld de,047efh		;47ba   ; la fuente de 0x47EF
	ld hl,02080h		;47bd   ; tile 0x10, el cero
	call guion_rle_en_tres_bancos		;47c0   ; en los tres tercios
	ld a,0f0h		;47c3   ; blanco sobre transparente...
	ld hl,00080h		;47c5   ; ...para los tiles 0x10 a 0x3A
	ld bc,00158h		;47c8   ; 43 tiles: 0x158 bytes
	jp rellena_los_tres_bancos		;47cb   ; en los tres tercios
limpia_la_fuente:		; Los 16 primeros tiles a cero y su color a 0x00-0x0F: el tile N queda como un bloque de color N
	ld hl,02000h		;47ce   ; los patrones de los tiles 0 a 15...
	ld bc,00080h		;47d1   ; ...128 bytes...
	xor a			;47d4   ; ...a cero...
	call rellena_los_tres_bancos		;47d5   ; patrones de los tiles 0 a 15, a cero
	ld hl,00000h		;47d8   ; el color del tile 0
	ld de,00008h		;47db   ; de 8 en 8
	ld b,010h		;47de   ; el color de cada uno es 0x0N: con el patron a cero, el tile N es un bloque macizo de color N
L_47E0:
	push bc			;47e0   ; B, a salvo
	ld bc,00008h		;47e1   ; un tile
	push hl			;47e4   ; HL a salvo
	call rellena_los_tres_bancos		;47e5   ; los tres tercios con A
	pop hl			;47e8   ; HL otra vez
	add hl,de			;47e9   ; el tile siguiente
	inc a			;47ea   ; el color siguiente
	pop bc			;47eb   ; B otra vez
	djnz L_47E0		;47ec   ; dieciseis
	ret			;47ee   ; vuelta

; ----------------------------------------------------------------------
; DATOS fuente: La fuente de 43 caracteres (tiles 0x10 a 0x3A: las cifras, el
;   (c), la mano, el guion y la A a la Z) en el RLE de 0x46A6.
;   tools/graficos.py la descomprime y acaba justo en el 0x00 de 0x491F
;   0x47ef..0x4920  (305 bytes)
DATA_fuente:
	defb 08bh,000h,01ch,022h,063h,063h,063h,022h	; 47ef  ..."ccc"
	defb 01ch,000h,018h,038h,004h,018h,0cch,07eh	; 47f7  ...8...~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 47ff  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 4807  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 480f  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 4817  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 481f  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 4827  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 482f  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 4837  .>cc?.c>
	defb 03ch,042h,099h,0a1h,0a1h,099h,042h,03ch	; 483f  <B....B<
	defb 000h,00fh,01fh,004h,0ffh,089h,00fh,000h	; 4847  ........
	defb 000h,0feh,0e0h,0e0h,0c0h,0c0h,080h,018h	; 484f  ........
	defb 000h,004h,000h,001h,07eh,004h,000h,0c1h	; 4857  ....~...
	defb 01ch,036h,063h,063h,07fh,063h,063h,000h	; 485f  .6cc.cc.
	defb 07eh,063h,063h,07eh,063h,063h,07eh,000h	; 4867  ~cc~cc~.
	defb 03eh,063h,060h,060h,060h,063h,03eh,000h	; 486f  >c```c>.
	defb 07ch,066h,063h,063h,063h,066h,07ch,000h	; 4877  |fcccf|.
	defb 07fh,060h,060h,07eh,060h,060h,07fh,000h	; 487f  .``~``..
	defb 07fh,060h,060h,07eh,060h,060h,060h,000h	; 4887  .``~```.
	defb 03eh,063h,060h,067h,063h,063h,03fh,000h	; 488f  >c`gcc?.
	defb 063h,063h,063h,07fh,063h,063h,063h,000h	; 4897  ccc.ccc.
	defb 03ch,005h,018h,083h,03ch,000h,01fh,004h	; 489f  <...<...
	defb 006h,08bh,066h,03ch,000h,063h,066h,06ch	; 48a7  ..f<.cfl
	defb 078h,07ch,06eh,067h,000h,006h,060h,093h	; 48af  x|ng..`.
	defb 07fh,000h,063h,077h,07fh,07fh,06bh,063h	; 48b7  ..cw..kc
	defb 063h,000h,063h,073h,07bh,07fh,06fh,067h	; 48bf  c.cs{.og
	defb 063h,000h,03eh,005h,063h,0a3h,03eh,000h	; 48c7  c.>.c.>.
	defb 07eh,063h,063h,063h,07eh,060h,060h,000h	; 48cf  ~ccc~``.
	defb 03eh,063h,063h,063h,06fh,066h,03dh,000h	; 48d7  >cccof=.
	defb 07eh,063h,063h,062h,07ch,066h,063h,000h	; 48df  ~ccb|fc.
	defb 03eh,063h,060h,03eh,003h,063h,03eh,000h	; 48e7  >c`>.c>.
	defb 07eh,006h,018h,001h,000h,006h,063h,082h	; 48ef  ~.....c.
	defb 03eh,000h,004h,063h,0a3h,036h,01ch,008h	; 48f7  >..c.6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 48ff  .cckk.w"
	defb 000h,00ch,018h,030h,000h,000h,000h,000h	; 4907  ...0....
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 490f  .ff~<...
	defb 000h,000h,000h,03eh,000h,03eh,000h,000h	; 4917  ...>.>..
	defb 000h	; 491f

; ======================================================================
; CODIGO 0x4920..0x4982  (98 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL LOGOTIPO DE KONAMI. Sus patrones van al segundo tercio desde el tile 0x40 con los colores a cero, y la tabla de nombres lleva seis filas de 21 tiles correlativos desde 0x3907.
; ----------------------------------------------------------------------
monta_el_logotipo_de_konami:
	ld hl,00000h		;4920   ; la cortina empieza en la linea 0, fila 0
	ld (0e00eh),hl		;4923   ; (0xE00E) y (0xE00F) a cero
	ld de,04982h		;4926   ; los patrones, con su direccion dentro del guion
	call guion_rle		;4929   ; a la VRAM
	ld hl,00a00h		;492c   ; los colores del logotipo, a cero: aun no se ve
	ld bc,003f0h		;492f   ; 126 tiles de color...
	xor a			;4932   ; ...a cero
	call 00056h		;4933   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld hl,03907h		;4936   ; fila 8, columna 7
	ld a,040h		;4939   ; tiles 0x40 en adelante, 21 por fila
	ld c,006h		;493b   ; seis filas
	ld de,0000bh		;493d   ; el salto al acabar la fila
L_4940:
	ld b,015h		;4940   ; 21 tiles
L_4942:
	call 0004dh		;4942   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;4945   ; la casilla siguiente
	inc a			;4946   ; el tile siguiente
	djnz L_4942		;4947   ; 21 veces
	add hl,de			;4949   ; 32 - 21 = 11 para bajar de fila
	dec c			;494a   ; una fila menos
	jr nz,L_4940		;494b   ; seis
	ret			;494d   ; vuelta

; ----------------------------------------------------------------------
; DESTAPA EL LOGOTIPO: una linea de pixeles cada vez. (0xE00E) es la linea dentro del tile y (0xE00F) la fila de tiles; pone 0xF0 en esa linea de los 21 tiles de la fila. Devuelve Z al acabar la sexta fila.
; ----------------------------------------------------------------------
destapa_una_linea_del_logotipo:
	ld bc,(0e00eh)		;494e   ; C: la linea; B: la fila
	ld a,0ebh		;4952   ; 0xEB + 21 por fila: A acaba en 21*fila (la primera vuelta da 0x100)
	inc b			;4954   ; una vuelta mas que la fila
L_4955:
	add a,015h		;4955   ; + 21...
	djnz L_4955		;4957   ; ...por fila
	ld l,a			;4959   ; L = 21 * fila
	ld h,b			;495a   ; H = 0
	add hl,hl			;495b   ; por 8: el tile en la tabla de color
	add hl,hl			;495c   ; por 2...
	add hl,hl			;495d   ; ...por 4...
	ld de,00a00h		;495e   ; el segundo tercio del color
	add hl,de			;4961   ; + 0x0A00
	ld a,c			;4962   ; y la linea dentro del tile
	call suma_a_a_hl		;4963   ; + la linea
	ld b,015h		;4966   ; 21 tiles
	ld de,00008h		;4968   ; de 8 en 8 bytes
	ld a,0f0h		;496b   ; blanco sobre transparente
L_496D:
	call 0004dh		;496d   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	add hl,de			;4970   ; la misma linea del tile de al lado
	djnz L_496D		;4971   ; 21 veces
	ld hl,0e00eh		;4973   ; la linea siguiente...
	ld a,(hl)			;4976   ; la linea...
	inc a			;4977   ; ...mas una...
	and 007h		;4978   ; ...de 0 a 7
	ld (hl),a			;497a   ; guardada
	ret nz			;497b   ; sin dar la vuelta, ya esta
	inc hl			;497c   ; ...y tras la octava, la fila siguiente
	inc (hl)			;497d   ; la fila siguiente
	ld a,(hl)			;497e   ; la fila
	cp 006h		;497f   ; Z en la sexta
	ret			;4981   ; vuelta: Z con la sexta

; ----------------------------------------------------------------------
; DATOS logotipo_de_konami: Los patrones del logotipo en el RLE de 0x46A0, con
;   destino 0x2A00 (tile 0x40 del segundo tercio): 126 tiles, las seis filas
;   de 21. Se descomprime hasta el 0x00 de 0x4AE3
;   0x4982..0x4ae4  (354 bytes)
DATA_logotipo_de_konami:
	defb 000h,02ah,018h,000h,002h,007h,003h,00fh	; 4982  .*......
	defb 002h,01fh,081h,03fh,008h,0ffh,002h,0f8h	; 498a  ...?....
	defb 003h,0f0h,003h,0e0h,07fh,000h,00dh,000h	; 4992  ........
	defb 087h,001h,003h,00fh,07fh,03fh,07fh,07fh	; 499a  .....?..
	defb 00ah,0ffh,082h,0fch,0f0h,003h,0c0h,002h	; 49a2  ........
	defb 080h,07fh,000h,083h,001h,003h,007h,003h	; 49aa  ........
	defb 00fh,081h,03fh,009h,0ffh,087h,0feh,0fch	; 49b2  ..?.....
	defb 0f8h,0f8h,0f0h,0f8h,0c0h,00bh,000h,002h	; 49ba  ........
	defb 001h,083h,003h,07fh,07fh,00bh,0ffh,002h	; 49c2  ........
	defb 0feh,083h,0fch,080h,080h,006h,000h,002h	; 49ca  ........
	defb 03ch,002h,078h,092h,079h,0f3h,0f7h,0ffh	; 49d2  <.x.y...
	defb 01fh,03eh,07ch,0f9h,0f3h,0e3h,0c3h,087h	; 49da  .>|.....
	defb 01fh,07fh,0f8h,0f0h,0e0h,0e0h,003h,0c0h	; 49e2  ........
	defb 084h,0f0h,0f8h,078h,078h,003h,079h,002h	; 49ea  ...xx.y.
	defb 07fh,083h,0ffh,0f7h,0f7h,003h,0e7h,002h	; 49f2  ........
	defb 00fh,003h,01eh,003h,03ch,088h,003h,007h	; 49fa  ....<...
	defb 00fh,00eh,01eh,03ch,038h,078h,005h,0e0h	; 4a02  ...<8x..
	defb 003h,0e1h,002h,07eh,083h,0feh,0f6h,0f6h	; 4a0a  ...~....
	defb 003h,0eeh,002h,00fh,088h,01fh,01dh,03dh	; 4a12  .......=
	defb 03bh,07bh,073h,0f1h,0f1h,003h,0e3h,003h	; 4a1a  ;{s.....
	defb 0c7h,002h,0e0h,003h,0c0h,003h,080h,008h	; 4a22  ........
	defb 000h,003h,01fh,003h,03fh,002h,07fh,008h	; 4a2a  ....?...
	defb 0ffh,083h,0f0h,0e0h,0e0h,003h,0c0h,002h	; 4a32  ........
	defb 080h,007h,000h,087h,007h,003h,007h,007h	; 4a3a  ........
	defb 00fh,01fh,03fh,009h,0ffh,089h,0f8h,0fch	; 4a42  ..?.....
	defb 0f8h,0f8h,0f0h,0e0h,0c0h,000h,000h,003h	; 4a4a  ........
	defb 001h,003h,003h,002h,007h,088h,0efh,0e7h	; 4a52  ........
	defb 0e7h,0c7h,0c7h,0c3h,083h,083h,003h,087h	; 4a5a  ........
	defb 003h,0c7h,092h,0e3h,0e0h,080h,080h,081h	; 4a62  ........
	defb 081h,083h,0c7h,0ffh,0feh,0fbh,0f3h,0f3h	; 4a6a  ........
	defb 0f7h,0e7h,0c7h,08fh,00fh,003h,0c7h,003h	; 4a72  ........
	defb 087h,002h,007h,002h,078h,088h,079h,0f1h	; 4a7a  ....x.y.
	defb 0f3h,0f7h,0e7h,0efh,070h,0f0h,003h,0ffh	; 4a82  ....p...
	defb 002h,081h,081h,001h,003h,0e3h,003h,0e7h	; 4a8a  ........
	defb 002h,0efh,002h,0ceh,081h,0cfh,003h,08fh	; 4a92  ........
	defb 002h,00fh,088h,0f7h,0e7h,0c7h,0cfh,08fh	; 4a9a  ........
	defb 08fh,01eh,01eh,003h,08fh,003h,01eh,002h	; 4aa2  ........
	defb 03ch,090h,007h,008h,017h,014h,017h,014h	; 4aaa  <.......
	defb 008h,007h,080h,040h,020h,0a0h,020h,0a0h	; 4ab2  ...@ . .
	defb 040h,080h,011h,000h,085h,003h,00fh,01fh	; 4aba  @.......
	defb 03fh,07fh,00bh,0ffh,086h,0fch,0f0h,0e0h	; 4ac2  ?.......
	defb 0c0h,080h,080h,07fh,000h,00ah,000h,003h	; 4aca  ........
	defb 001h,003h,003h,002h,007h,009h,0ffh,002h	; 4ad2  ........
	defb 0feh,003h,0fch,002h,0f8h,07fh,000h,009h	; 4ada  ........
	defb 000h,000h	; 4ae2

; ======================================================================
; CODIGO 0x4ae4..0x4b95  (177 bytes)
; ======================================================================


fondo_negro:
	ld b,0e0h		;4ae4   ; registro 7 a 0xE0: fondo negro
	call pon_el_fondo		;4ae6   ; al registro 7
	ret			;4ae9   ; vuelta

; ----------------------------------------------------------------------
; EL TITULO: el rotulo de Q*bert en su marco, Q*bert en la recreativa, (c)KONAMI 1986 y el menu de uno o dos jugadores. Si la presentacion ya lo ha dibujado (0xE115), solo pone los textos.
; ----------------------------------------------------------------------
pinta_el_titulo:
	call fondo_negro		;4aea   ; fondo negro
	ld hl,0e115h		;4aed   ; (0xE115): la presentacion ya lo dejo pintado
	ld a,(hl)			;4af0   ; lo lee...
	or a			;4af1   ; ...lo mira...
	ld (hl),000h		;4af2   ; ...y lo borra
	jr nz,pinta_los_textos_del_titulo		;4af4   ; pintado: solo los textos
	call borra_la_pantalla		;4af6   ; desde cero: pantalla, fuente...
	call monta_la_fuente		;4af9   ; la fuente
	call prepara_la_recreativa		;4afc   ; ...la de la recreativa...
	ld hl,0ed45h		;4aff   ; ...el rotulo en su marco, en la fila 2, columna 5...
	call pinta_el_rotulo_de_qbert		;4b02   ; en la copia de la tabla de nombres
	call sprites_del_titulo		;4b05   ; ...Q*bert y la pantalla de la recreativa...
	ld a,008h		;4b08   ; ...el color del ultimo sprite...
	ld (0e22bh),a		;4b0a   ; en color 8
	call vuelca_la_pantalla		;4b0d   ; ...la copia de la tabla de nombres a la VRAM...
	call vuelca_los_sprites_de_la_presentacion		;4b10   ; ...y los sprites
pinta_los_textos_del_titulo:
	ld de,04790h		;4b13   ; (c)KONAMI 1986 y 1PLAYER...
	call pinta_guion		;4b16   ; en pantalla
	jp pinta_guion		;4b19   ; ...y 2PLAYERS, que viene detras
parpadea_el_cursor:		; La mano aparece y desaparece cada 8 cuadros
	ld hl,0e004h		;4b1c   ; la espera: cuenta hacia abajo
	bit 3,(hl)		;4b1f   ; bit 3: cada 8 cuadros
	ld c,0ffh		;4b21   ; pinta...
	jr nz,pinta_la_mano		;4b23   ; ...o...
	inc c			;4b25   ; ...C=0: borra
pinta_la_mano:		; La mano con C en la opcion de (0xE102) y borrada en la otra
	ld hl,0396ah		;4b26   ; las dos lineas del menu
	ld de,0398ah		;4b29   ; 2PLAYERS
	ld a,(0e102h)		;4b2c   ; uno o dos
	or a			;4b2f   ; uno: la mano en 1PLAYER
	jr z,L_4B33		;4b30
	ex de,hl			;4b32   ; dos: en 2PLAYERS
L_4B33:
	push de			;4b33   ; la otra, para despues
	call pinta_la_mano_en_hl		;4b34   ; la mano en la buena
	pop hl			;4b37   ; la otra...
	ld c,000h		;4b38   ; ...borrada
pinta_la_mano_en_hl:
	ld de,047b4h		;4b3a   ; los dos tiles de la mano
	jp byte_del_guion		;4b3d   ; sin direccion
pinta_el_rotulo_de_qbert:		; Las ocho filas de 0x4B95 en la copia de la tabla de nombres, desde HL
	ld c,0ffh		;4b40   ; pinta
	ld de,04b95h		;4b42   ; la primera fila
	call casillas_en_la_copia		;4b45   ; en la copia
	ld a,009h		;4b48   ; 23 casillas y 9 de salto: filas de 32
	call suma_a_a_hl		;4b4a   ; a la fila siguiente
	ld de,04badh		;4b4d   ; la segunda
	call casillas_en_la_copia		;4b50   ; en la copia
	ld a,009h		;4b53   ; nueve mas
	call suma_a_a_hl		;4b55   ; a la fila siguiente
	ld de,04bc5h		;4b58   ; la tercera
	call casillas_en_la_copia		;4b5b   ; en la copia
	ld a,009h		;4b5e   ; nueve mas
	call suma_a_a_hl		;4b60   ; a la fila siguiente
	ld de,04bddh		;4b63   ; la cuarta
	call casillas_en_la_copia		;4b66   ; en la copia
	ld a,009h		;4b69   ; nueve mas
	call suma_a_a_hl		;4b6b   ; a la fila siguiente
	ld de,04bf5h		;4b6e   ; la quinta
	call casillas_en_la_copia		;4b71   ; en la copia
	ld a,009h		;4b74   ; nueve mas
	call suma_a_a_hl		;4b76   ; a la fila siguiente
	ld de,04c0dh		;4b79   ; la sexta
	call casillas_en_la_copia		;4b7c   ; en la copia
	ld a,009h		;4b7f   ; nueve mas
	call suma_a_a_hl		;4b81   ; a la fila siguiente
	ld de,04c25h		;4b84   ; la septima
	call casillas_en_la_copia		;4b87   ; en la copia
	ld a,00eh		;4b8a   ; la ultima fila, el pie del marco, va 5 casillas mas a la derecha
	call suma_a_a_hl		;4b8c   ; 14 mas: 5 columnas a la derecha
	ld de,04c3dh		;4b8f   ; la octava: el pie
	jp casillas_en_la_copia		;4b92   ; en la copia

; ----------------------------------------------------------------------
; DATOS rotulo_de_qbert: El rotulo Q*bert con su marco, en ocho guiones de
;   0x8724 (casillas con 0xFF de fin) que 0x4B40 pone uno por fila: siete de
;   23 casillas y la ultima, de tres, desplazada. 0x63 es el marco, 0x40 el
;   fondo, 0x70-0x88 la Q con la estrella y 0x41-0x62 "bert" y la TM
;   0x4b95..0x4c41  (172 bytes)
DATA_rotulo_de_qbert:
	defb 063h,063h,065h,066h,069h,06ah,064h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,0ffh	; 4b95  ccefijdcccccccccccccccc.
	defb 063h,070h,071h,072h,073h,074h,06fh,075h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,040h,063h,0ffh	; 4bad  cpqrstou@@@@@@@@@@@@@@c.
	defb 063h,076h,06fh,077h,040h,078h,06fh,079h,040h,041h,042h,040h,040h,040h,040h,040h,040h,040h,040h,088h,087h,040h,063h,0ffh	; 4bc5  cvow@xoy@AB@@@@@@@@..@c.
	defb 063h,07ah,06fh,07bh,040h,07ch,06fh,07dh,040h,043h,044h,045h,046h,047h,048h,049h,04ah,04bh,04ch,04dh,04eh,040h,063h,0ffh	; 4bdd  czo{@|o}@CDEFGHIJKLMN@c.
	defb 063h,07eh,06fh,07fh,080h,081h,06fh,082h,040h,043h,044h,04fh,050h,051h,052h,053h,054h,055h,056h,054h,040h,040h,063h,0ffh	; 4bf5  c~o...o.@CDOPQRSTUVT@@c.
	defb 063h,040h,083h,084h,085h,06fh,086h,040h,040h,057h,058h,059h,05ah,05bh,05ch,05dh,05eh,05fh,060h,061h,062h,040h,063h,0ffh	; 4c0d  c@...o.@@WXYZ[\]^_`ab@c.
	defb 063h,063h,063h,063h,063h,067h,068h,06bh,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,063h,0ffh	; 4c25  cccccghkccccccccccccccc.
	defb 06ch,06dh,06eh,0ffh	; 4c3d

; ======================================================================
; CODIGO 0x4c41..0x4fc3  (898 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; TOCA UN SONIDO, pero solo con partida (bit 6 de 0xE002): los efectos de la demostracion no suenan.
; ----------------------------------------------------------------------
toca_sonido_en_partida:
	di			;4c41   ; sin interrupciones
	push hl			;4c42   ; HL a salvo
	ld hl,0e002h		;4c43   ; el modo
	bit 6,(hl)		;4c46   ; bit 6: partida de verdad
	jr z,L_4C57		;4c48   ; sin ella, nada
	jr L_4C4E		;4c4a   ; con ella, como 0x4C4C
toca_sonido:		; A: el numero de sonido. Guarda todos los registros
	di			;4c4c   ; sin interrupciones: el motor no puede correr a medias
	push hl			;4c4d   ; todo a salvo
L_4C4E:
	push de			;4c4e
	push bc			;4c4f
	push af			;4c50
	call arranca_el_sonido		;4c51   ; arranca A
	pop af			;4c54   ; todo de vuelta
	pop bc			;4c55
	pop de			;4c56
L_4C57:
	pop hl			;4c57   ; HL
	ei			;4c58   ; interrupciones abiertas
	ret			;4c59   ; vuelta
arranca_el_sonido:
	cp 056h		;4c5a   ; el 0x56 es el de la pausa: antes se guardan los cuatro canales en 0xE090
	jr nz,L_4C68		;4c5c   ; no es la pausa
	ld hl,0e010h		;4c5e   ; los tres canales de musica...
	ld de,0e090h		;4c61   ; ...a 0xE090
	call copia_los_canales		;4c64   ; 0x60 bytes
	ld a,c			;4c67   ; C, que ha devuelto 0x5004
L_4C68:
	ld c,a			;4c68   ; C = el sonido
	ld hl,0e012h		;4c69   ; de 0x01 a 0x16: un efecto, un canal (el cuarto)
	ld b,001h		;4c6c   ; un canal
	ld a,c			;4c6e   ; el sonido
	cp 017h		;4c6f   ; por debajo de 0x17...
	jr c,arranca_un_efecto		;4c71   ; ...efecto
	cp 056h		;4c73   ; de 0x17 en adelante, musica: tres canales
	jr nz,L_4C78		;4c75   ; no es la pausa: tres
	inc b			;4c77   ; y el 0x56, los cuatro
L_4C78:
	inc b			;4c78   ; dos mas: tres canales
	inc b			;4c79   ; (cuatro con la pausa)
	cp 02ch		;4c7a   ; una musica calla el efecto que sonara, salvo la 0x2C
	jr z,L_4C82		;4c7c   ; la 0x2C deja sonar el efecto
	xor a			;4c7e   ; cualquier otra...
	ld (0e072h),a		;4c7f   ; ...lo corta
L_4C82:
	jr arranca_b_canales		;4c82   ; y adelante
arranca_un_efecto:
	ld l,072h		;4c84   ; HL=0xE072: el sonido del canal de efectos
	ld a,(0e052h)		;4c86   ; con la musica 0x2C o posteriores en el tercer canal, los efectos no suenan
	cp 02ch		;4c89   ; la musica 0x2C o posterior...
	ret nc			;4c8b   ; ...manda: no hay efecto
	ld a,(hl)			;4c8c   ; y un efecto solo corta a otro de numero menor o igual
	ld e,a			;4c8d   ; E = el efecto que suena
	ld a,c			;4c8e   ; el nuevo
	cp e			;4c8f   ; contra el que suena
	ret c			;4c90   ; menor: no se oye
arranca_b_canales:
	ld a,c			;4c91   ; el sonido...
	ld de,052e2h		;4c92   ; la tabla de 0x52E2: una entrada por canal, y una musica usa tres seguidas
	add a,a			;4c95   ; ...por dos...
	jr nc,L_4C99		;4c96   ; ...con acarreo
	inc d			;4c98   ; al byte alto
L_4C99:
	add a,e			;4c99   ; + 0x52E2
	ld e,a			;4c9a   ; en E
	jr nc,L_4C9E		;4c9b   ; con acarreo...
	inc d			;4c9d   ; ...al alto
L_4C9E:
	dec l			;4c9e   ; HL al +0 del canal
	dec l			;4c9f
prepara_un_canal:
	ld (hl),001h		;4ca0   ; +0: la primera nota sale ya
	inc l			;4ca2   ; +2
	inc l			;4ca3
	ld (hl),c			;4ca4   ; +2: el sonido
	inc l			;4ca5   ; +3
	ld a,(de)			;4ca6   ; +3/+4: sus datos
	ld (hl),a			;4ca7   ; el byte bajo del puntero
	inc l			;4ca8   ; +4
	inc de			;4ca9   ; el alto
	ld a,(de)			;4caa
	ld (hl),a			;4cab   ; guardado
	ld a,007h		;4cac   ; siete mas...
	add a,l			;4cae
	ld l,a			;4caf   ; ...+0x0B
	xor a			;4cb0   ; cero
	ld (hl),a			;4cb1   ; +0B: sin bucle
	ld a,003h		;4cb2   ; tres mas...
	add a,l			;4cb4
	ld l,a			;4cb5   ; ...+0x0E
	ld a,001h		;4cb6   ; uno
	ld (hl),a			;4cb8   ; +0E: modo musica
	inc l			;4cb9   ; +0x0F
	dec a			;4cba   ; cero
	ld (hl),a			;4cbb   ; guardado
	inc l			;4cbc   ; +0x10
	ld (hl),a			;4cbd   ; +0F y +10: afinado y sin instrumento
	ld a,009h		;4cbe   ; nueve mas...
	add a,l			;4cc0
	ld l,a			;4cc1   ; ...+0x19
	ld (hl),000h		;4cc2   ; +19: sin subrutina
	ld a,007h		;4cc4   ; siete mas...
	add a,l			;4cc6
	ld l,a			;4cc7   ; ...el canal siguiente
	inc de			;4cc8   ; la entrada siguiente de la tabla
	djnz prepara_un_canal		;4cc9   ; B canales
	ret			;4ccb   ; vuelta

; ----------------------------------------------------------------------
; EL SONIDO DE CADA CUADRO. Primero el mezclador; si hay que volver de la pausa, se restauran los canales de 0xE090; y luego los cuatro canales, uno detras de otro, con C en el registro de periodo de cada uno (1, 3, 5 y 7).
; ----------------------------------------------------------------------
suena_un_cuadro:
	ld a,(0e0f0h)		;4ccc   ; el mezclador tal como quedo
	call escribe_el_mezclador		;4ccf   ; al registro 7
	exx			;4cd2   ; en los de reserva...
	ld b,004h		;4cd3   ; cuatro canales de 0x20 bytes
	ld de,00020h		;4cd5   ; ...0x20 entre canal y canal
	exx			;4cd8   ; los normales
	xor a			;4cd9   ; (0xE0F3): se estan rehaciendo los registros tras la pausa
	ld (0e0f3h),a		;4cda   ; (0xE0F3)=0
	ld c,001h		;4cdd   ; C: el registro de periodo del primer canal
	ld ix,0e010h		;4cdf   ; IX: el primer canal
	ld a,(0e0f1h)		;4ce3   ; (0xE0F1): acaba la pausa
	or a			;4ce6   ; no: sigue
	jr z,L_4CF8		;4ce7
	ld a,c			;4ce9   ; A = C, que 0x5004 devuelve
	ld hl,0e090h		;4cea   ; los canales guardados vuelven a su sitio
	ld de,0e010h		;4ced   ; de 0xE090 a 0xE010
	call copia_los_canales		;4cf0   ; los canales guardados, de vuelta
	ld a,001h		;4cf3   ; (0xE0F3)=1: rehacer los registros...
	ld (0e0f3h),a		;4cf5   ; ...de los cuatro
L_4CF8:
	exx			;4cf8   ; B' y DE' listos
un_canal:
	exx			;4cf9   ; los normales
	ld a,(ix+002h)		;4cfa   ; +2 a cero: canal libre
	or a			;4cfd   ; suena algo?
	push af			;4cfe   ; la respuesta, a salvo
	call nz,avanza_el_canal		;4cff   ; si: adelante
	pop af			;4d02   ; la respuesta
	jr nz,L_4D0B		;4d03   ; sonaba: ya esta
	ld a,c			;4d05   ; libre y no es el de efectos: se deja en silencio
	cp 007h		;4d06   ; el de efectos no...
	call nz,fin_del_canal		;4d08   ; ...los demas, en silencio
L_4D0B:
	inc c			;4d0b   ; el registro de periodo...
	inc c			;4d0c   ; ...del canal siguiente
	exx			;4d0d   ; los de reserva
	add ix,de		;4d0e   ; IX al canal siguiente
	djnz un_canal		;4d10   ; cuatro
	ret			;4d12   ; vuelta
avanza_el_canal:
	ld a,(0e0f3h)		;4d13   ; tras la pausa, primero el periodo y el volumen que tenia
	or a			;4d16   ; tras la pausa?
	push af			;4d17   ; a salvo
	call nz,pon_el_periodo		;4d18   ; si: el periodo de antes
	pop af			;4d1b   ; la respuesta
	call nz,pon_el_volumen		;4d1c   ; y el volumen de antes
	ld a,(ix+00eh)		;4d1f   ; modo musica
	or a			;4d22   ; musica...
	jp nz,decae_la_nota		;4d23   ; ...su decaimiento
	ld (ix+010h),a		;4d26   ; modo efecto: sin instrumento
	dec (ix+000h)		;4d29   ; cuando se acaba la nota...
	ret nz			;4d2c   ; no se acabo la nota
lee_la_siguiente_orden:
	ld l,(ix+003h)		;4d2d   ; el puntero...
	ld h,(ix+004h)		;4d30   ; ...de los datos
	ld a,(hl)			;4d33   ; 0xFE: bucle, subrutina o cambio de modo
	cp 0feh		;4d34   ; 0xFE...
	jp z,orden_fe		;4d36   ; ...orden especial
	jp nc,fin_del_canal		;4d39   ; 0xFF: fin (o vuelta de la subrutina)
L_4D3C:
	ld a,(ix+00eh)		;4d3c   ; el modo
	or a			;4d3f   ; musica?
	ld a,(hl)			;4d40   ; la orden
	jp nz,orden_de_musica		;4d41   ; si: en su formato
orden_de_efecto:
	and 0f0h		;4d44   ; 0x2X: el tipo del sonido
	cp 020h		;4d46   ; 0x2X?
	jr nz,L_4D7D		;4d48   ; no: al ruido o a la nota
	ld a,(hl)			;4d4a   ; el tipo...
	ld (ix+005h),a		;4d4b   ; ...a +5
	inc hl			;4d4e   ; y su duracion
	ld a,(ix+010h)		;4d4f   ; con instrumento?
	or a			;4d52   ; A...
	ld a,(hl)			;4d53   ; ...la duracion
	jr nz,L_4D59		;4d54   ; con instrumento, a +14
	ld (ix+001h),a		;4d56   ; sin el, a +1
L_4D59:
	ld (ix+014h),a		;4d59   ; y siempre a +14
	inc hl			;4d5c   ; el byte siguiente
	ld a,(ix+005h)		;4d5d   ; 0x20 a secas: un silencio
	cp 020h		;4d60   ; 0x20 exacto...
	jr nz,L_4D69		;4d62   ; ...no
	dec hl			;4d64   ; un silencio: no hay nota detras
	xor a			;4d65   ; periodo...
	ld b,a			;4d66   ; ...y volumen a cero
	jr L_4D97		;4d67   ; a guardarlo
L_4D69:
	bit 3,a		;4d69   ; bit 3: la envolvente del PSG...
	jr z,L_4D7D		;4d6b   ; sin envolvente: sigue
	ld a,(hl)			;4d6d   ; ...con su periodo en los registros 12 y 11
	ld e,a			;4d6e   ; su periodo, byte bajo...
	ld a,00ch		;4d6f   ; ...al registro 12
	call 00093h		;4d71   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	inc hl			;4d74   ; el siguiente
	ld a,(hl)			;4d75   ; el alto...
	ld e,a			;4d76   ; ...en E...
	ld a,00bh		;4d77   ; ...al registro 11
	call 00093h		;4d79   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	inc hl			;4d7c   ; detras
L_4D7D:
	ld a,(hl)			;4d7d   ; 0x1X: el periodo del ruido, X por dos, al registro 6
	and 0f0h		;4d7e   ; el nibble alto
	cp 010h		;4d80   ; 0x1X?
	jr nz,nota_de_efecto		;4d82   ; no: la nota
	ld a,(hl)			;4d84   ; si: el periodo del ruido
	and 00fh		;4d85   ; X...
	add a,a			;4d87   ; ...por dos
	ld e,a			;4d88   ; en E
	ld a,006h		;4d89   ; registro 6
	call 00093h		;4d8b   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	inc hl			;4d8e   ; detras
nota_de_efecto:
	ld a,(hl)			;4d8f   ; el nibble alto es el volumen; el bajo y el byte siguiente, el periodo de 12 bits tal cual
	and 0f0h		;4d90   ; el nibble alto: el volumen
	ld b,a			;4d92   ; en B
	xor (hl)			;4d93   ; el bajo...
	ld d,a			;4d94   ; ...en D: el alto del periodo
	inc hl			;4d95   ; el siguiente
	ld e,(hl)			;4d96   ; E: el bajo del periodo
L_4D97:
	ld a,(ix+010h)		;4d97   ; con instrumento...
	or a			;4d9a   ; ...?
	jp nz,siguiente_paso_del_instrumento		;4d9b   ; si: el paso del instrumento
	call guarda_el_puntero		;4d9e   ; el puntero, detras de la nota
guarda_el_periodo:
	ex de,hl			;4da1   ; HL = el periodo
	ld (ix+015h),l		;4da2   ; a +15...
	ld (ix+016h),h		;4da5   ; ...y +16
	ld a,(0e0f3h)		;4da8   ; tras la pausa?
	or a			;4dab   ; no...
	call z,pon_el_periodo		;4dac   ; ...al PSG ya
	ld a,b			;4daf   ; el volumen, del nibble alto
	rrca			;4db0   ; el volumen...
	rrca			;4db1
	rrca			;4db2
	rrca			;4db3
	ld (ix+017h),a		;4db4   ; ...a +17
	ld a,(ix+010h)		;4db7   ; con instrumento?
	or a			;4dba   ; no...
	jr z,repone_la_duracion		;4dbb   ; ...la duracion de la nota
	ld a,(ix+014h)		;4dbd   ; si: la del paso...
	ld (ix+013h),a		;4dc0   ; ...a su cuenta
	ld a,(0e0f3h)		;4dc3   ; tras la pausa?
	or a			;4dc6   ; no...
	jp z,pon_el_volumen		;4dc7   ; ...el volumen al PSG
	ret			;4dca   ; vuelta
repone_la_duracion:
	ld a,(ix+001h)		;4dcb   ; la duracion...
	ld (ix+000h),a		;4dce   ; ...a la cuenta
	ld a,(0e0f3h)		;4dd1   ; tras la pausa?
	or a			;4dd4   ; no...
	jp z,pon_el_volumen		;4dd5   ; ...el volumen al PSG
	ret			;4dd8   ; vuelta
decae_la_nota:
	dec (ix+000h)		;4dd9   ; en modo musica, la nota se va apagando
	jp z,lee_la_siguiente_orden		;4ddc   ; acabada: la siguiente orden
	ld a,(ix+010h)		;4ddf   ; con instrumento...
	or a			;4de2   ; ...?
	jp nz,paso_del_instrumento		;4de3   ; si: el paso del instrumento
	dec (ix+00ah)		;4de6   ; cada tantos cuadros (+0C)...
	ld a,(ix+00ah)		;4de9   ; la cuenta del decaimiento...
	cp (ix+000h)		;4dec   ; ...contra la de la nota
	jr nz,L_4DF9		;4def   ; no coinciden: una menos
	ld e,a			;4df1   ; E = la cuenta
	ld a,(ix+00dh)		;4df2   ; el suelo del decaimiento
	cp e			;4df5   ; por debajo...
	jr nc,L_4DFC		;4df6   ; ...a bajar el volumen
	ret			;4df8   ; vuelta
L_4DF9:
	dec (ix+00ah)		;4df9   ; una menos
L_4DFC:
	ld a,(ix+008h)		;4dfc   ; ...el volumen baja uno, hasta 0
	dec a			;4dff   ; el volumen menos uno
	ret m			;4e00   ; negativo: ya esta en cero
	ld (ix+008h),a		;4e01   ; el actual...
	ld (ix+017h),a		;4e04   ; ...y el de salida
	ld a,(0e0f3h)		;4e07   ; tras la pausa?
	or a			;4e0a   ; no...
	jp z,pon_el_volumen		;4e0b   ; ...al PSG
	ret			;4e0e   ; vuelta

; ----------------------------------------------------------------------
; LAS ORDENES DE LA MUSICA. 0xDX: unidad de tiempo X. 0xFX: volumen X+2, y el byte siguiente el ritmo y el suelo del decaimiento. 0xE0-0xE7: octava. 0xE8: desafina (periodo + 1). 0xE9-0xEE: instrumento 1 a 6. 0xEF: sin instrumento. El resto es una nota: nibble alto de 0 a 11 (12 es silencio) y nibble bajo, cuantas unidades dura menos una.
; ----------------------------------------------------------------------
orden_de_musica:
	ld a,(hl)			;4e0f   ; la orden
	and 0f0h		;4e10   ; el nibble alto
	cp 0d0h		;4e12   ; 0xDX?
	ld a,(hl)			;4e14   ; la orden otra vez
	jr nz,L_4E1E		;4e15   ; no: sigue
	and 00fh		;4e17   ; 0xDX: la unidad de tiempo
	ld (ix+006h),a		;4e19   ; la unidad de tiempo
	inc hl			;4e1c   ; el byte siguiente
	ld a,(hl)			;4e1d   ; la orden
L_4E1E:
	cp 0f0h		;4e1e   ; 0xFX: el volumen...
	jr c,L_4E3C		;4e20   ; no es 0xFX
	and 00fh		;4e22   ; X...
	inc a			;4e24   ; ...mas dos...
	inc a			;4e25
	ld (ix+007h),a		;4e26   ; ...el volumen
	inc hl			;4e29   ; el byte siguiente
	ld a,(hl)			;4e2a   ; ...y el decaimiento
	and 0f0h		;4e2b   ; el nibble alto...
	rrca			;4e2d
	rrca			;4e2e
	rrca			;4e2f
	rrca			;4e30
	ld (ix+00ch),a		;4e31   ; ...el ritmo del decaimiento
	ld a,(hl)			;4e34   ; el bajo...
	and 00fh		;4e35
	ld (ix+00dh),a		;4e37   ; ...su suelo
	inc hl			;4e3a   ; el byte siguiente
	ld a,(hl)			;4e3b   ; la orden
L_4E3C:
	cp 0e0h		;4e3c   ; 0xEX
	jr c,nota_de_musica		;4e3e   ; no es 0xEX: una nota
	and 00fh		;4e40   ; X
	cp 008h		;4e42   ; 0xE0-0xE7: la octava
	jr c,pon_la_octava		;4e44   ; 0 a 7
	jr z,desafina		;4e46   ; 8
	cp 00fh		;4e48   ; 0xEF: fuera instrumento
	jr z,quita_el_instrumento		;4e4a   ; 15
	sub 008h		;4e4c   ; 0xE9-0xEE: instrumento 1 a 6
	ld (ix+010h),a		;4e4e   ; 9 a 14: el instrumento, de 1 a 6
	jr L_4E66		;4e51   ; y la nota que sigue
quita_el_instrumento:
	xor a			;4e53   ; cero...
	ld (ix+00fh),a		;4e54   ; ...sin desafinar...
	ld (ix+010h),a		;4e57   ; ...y sin instrumento
	inc hl			;4e5a   ; el byte siguiente
	jr orden_de_musica		;4e5b   ; y otra orden
desafina:
	ld (ix+00fh),a		;4e5d   ; +0F = 8
	inc hl			;4e60   ; el byte siguiente
	jr orden_de_musica		;4e61   ; y otra orden
pon_la_octava:
	ld (ix+009h),a		;4e63   ; la octava
L_4E66:
	inc hl			;4e66   ; el byte siguiente
	ld a,(hl)			;4e67   ; la nota
nota_de_musica:
	and 00fh		;4e68   ; la duracion: la unidad por (nibble bajo + 1)
	ld b,a			;4e6a   ; B = las unidades de mas
	ld a,(ix+006h)		;4e6b   ; la unidad
	jr z,L_4E75		;4e6e   ; ninguna de mas
L_4E70:
	add a,(ix+006h)		;4e70   ; una unidad...
	djnz L_4E70		;4e73   ; ...por cada una de mas
L_4E75:
	ld (ix+001h),a		;4e75   ; la duracion
	ld a,(hl)			;4e78   ; la nota otra vez
	call guarda_el_puntero		;4e79   ; el puntero, detras
	and 0f0h		;4e7c   ; el nibble alto: la nota
	rrca			;4e7e   ; el nibble alto...
	rrca			;4e7f
	rrca			;4e80
	rrca			;4e81
	ld b,a			;4e82   ; ...en B: la nota
	ld a,(ix+010h)		;4e83   ; con instrumento...
	or a			;4e86   ; ...?
	jr nz,arranca_el_instrumento		;4e87   ; si: su secuencia para esa nota
	ld a,b			;4e89   ; la nota
	sub 00ch		;4e8a   ; la 12 es un silencio: volumen 0
	jr z,L_4E91		;4e8c   ; la 12: volumen cero
	ld a,(ix+007h)		;4e8e   ; si no, el volumen del canal
L_4E91:
	ld (ix+008h),a		;4e91   ; el actual...
	ld (ix+017h),a		;4e94   ; ...y el de salida
	ld a,(ix+00fh)		;4e97   ; +0F no pasa de 12
	cp 00ch		;4e9a   ; por debajo de 12...
	jr c,L_4EA2		;4e9c   ; ...tal cual
	ld (ix+00fh),00ch		;4e9e   ; si no, 12
L_4EA2:
	ld e,(ix+001h)		;4ea2   ; la duracion...
	ld (ix+000h),e		;4ea5   ; ...a la cuenta
	ld a,(ix+00ch)		;4ea8   ; el ritmo del decaimiento...
	add a,e			;4eab   ; ...mas la duracion...
	ld (ix+00ah),a		;4eac   ; ...a su cuenta
	ld a,b			;4eaf   ; el periodo, de la tabla de 0x4FC3...
	ld hl,04fc3h		;4eb0   ; la tabla de periodos
	add a,l			;4eb3   ; + la nota
	ld l,a			;4eb4
	jr nc,L_4EB8		;4eb5   ; con acarreo...
	inc h			;4eb7   ; ...al alto
L_4EB8:
	ld l,(hl)			;4eb8   ; el periodo de la octava mas aguda
	ld h,000h		;4eb9   ; en HL
	ld a,(ix+009h)		;4ebb   ; la octava
	or a			;4ebe   ; 0: tal cual
	jr z,L_4EC5		;4ebf
	ld b,a			;4ec1   ; B veces
L_4EC2:
	add hl,hl			;4ec2   ; ...doblado tantas veces como diga la octava
	djnz L_4EC2		;4ec3   ; el doble: una octava mas grave
L_4EC5:
	ld (ix+015h),l		;4ec5   ; el periodo...
	ld (ix+016h),h		;4ec8   ; ...a +15/+16
	ld a,(0e0f3h)		;4ecb   ; tras la pausa?
	or a			;4ece   ; la respuesta
	push af			;4ecf   ; a salvo
	call z,pon_el_periodo		;4ed0   ; no: el periodo al PSG
	pop af			;4ed3   ; la respuesta
	jp z,pon_el_volumen		;4ed4   ; no: y el volumen
	ret			;4ed7   ; vuelta
arranca_el_instrumento:
	add a,a			;4ed8   ; la tabla de 0x50A4 empieza en el instrumento 1
	ld de,050a4h		;4ed9   ; la tabla de instrumentos, menos dos
	add a,e			;4edc   ; + el instrumento por dos
	ld e,a			;4edd   ; en E
	jr nc,L_4EE1		;4ede   ; con acarreo...
	inc d			;4ee0   ; ...al alto
L_4EE1:
	ld a,(de)			;4ee1   ; el puntero de ese instrumento...
	ld l,a			;4ee2   ; ...byte bajo...
	inc de			;4ee3   ; ...y...
	ld a,(de)			;4ee4   ; ...alto
	ld h,a			;4ee5   ; HL = sus notas
	ld a,(ix+001h)		;4ee6   ; la duracion...
	ld (ix+000h),a		;4ee9   ; ...a la cuenta
	ld a,b			;4eec   ; dentro del instrumento, la nota que toca
	add a,a			;4eed   ; la nota por dos...
	add a,l			;4eee   ; ...+ HL
	ld l,a			;4eef   ; en L
	jr nc,L_4EF3		;4ef0   ; con acarreo...
	inc h			;4ef2   ; ...al alto
L_4EF3:
	ld e,(hl)			;4ef3   ; el puntero de la secuencia de la nota...
	ld (ix+011h),e		;4ef4   ; ...a +11...
	inc hl			;4ef7   ; ...y...
	ld d,(hl)			;4ef8   ; ...el alto...
	ld (ix+012h),d		;4ef9   ; ...a +12
	ex de,hl			;4efc   ; HL = la secuencia
	ld a,(hl)			;4efd   ; su primer paso
	jp orden_de_efecto		;4efe   ; en formato de efecto
paso_del_instrumento:
	dec (ix+013h)		;4f01   ; la cuenta del paso
	ret nz			;4f04   ; sin acabar, nada
	ld l,(ix+011h)		;4f05   ; el puntero...
	ld h,(ix+012h)		;4f08   ; ...del instrumento
	ld a,(hl)			;4f0b   ; el paso siguiente
	cp 0ffh		;4f0c   ; 0xFF: se acabo el instrumento
	jr z,calla_el_instrumento		;4f0e   ; 0xFF: se acabo
	jp orden_de_efecto		;4f10   ; como un efecto
siguiente_paso_del_instrumento:
	inc hl			;4f13   ; detras del paso
	ld (ix+011h),l		;4f14   ; el puntero...
	ld (ix+012h),h		;4f17   ; ...guardado
	jp guarda_el_periodo		;4f1a   ; y el periodo
calla_el_instrumento:
	xor a			;4f1d   ; cero...
	ld (ix+005h),a		;4f1e   ; ...sin tono ni ruido...
	ld (ix+017h),a		;4f21   ; ...y sin volumen
	ld a,(0e0f3h)		;4f24   ; tras la pausa?
	or a			;4f27   ; no...
	jp z,pon_el_volumen		;4f28   ; ...el volumen al PSG
	ret			;4f2b   ; vuelta
fin_del_canal:
	ld a,(ix+019h)		;4f2c   ; con una subrutina abierta, se vuelve a ella
	or a			;4f2f   ; abierta?
	jr z,libera_el_canal		;4f30   ; no: el canal se libera
	ld (ix+004h),a		;4f32   ; el alto de la vuelta...
	ld a,(ix+018h)		;4f35   ; ...y el bajo...
	ld (ix+003h),a		;4f38   ; ...al puntero
	ld (ix+019h),000h		;4f3b   ; la subrutina, cerrada
	ld (ix+000h),001h		;4f3f   ; la orden siguiente, ya
	jp avanza_el_canal		;4f43   ; y adelante
libera_el_canal:
	ld d,(ix+002h)		;4f46   ; D = el sonido que acaba
	xor a			;4f49   ; cero:
	ld (ix+002h),a		;4f4a   ; canal libre
	ld (ix+005h),a		;4f4d   ; sin tono ni ruido
	ld (ix+00bh),a		;4f50   ; sin bucle
	ld (ix+010h),a		;4f53   ; sin instrumento
	ld (ix+017h),a		;4f56   ; sin volumen
	ld (ix+019h),a		;4f59   ; sin subrutina
	ld a,c			;4f5c   ; los canales de musica se quedan en silencio
	cp 007h		;4f5d   ; el de efectos...
	jr nc,acaba_el_efecto		;4f5f   ; ...va aparte
	ld a,(0e0f3h)		;4f61   ; tras la pausa?
	or a			;4f64   ; no...
	jp z,pon_el_volumen		;4f65   ; ...silencio al PSG
	ret			;4f68   ; vuelta
acaba_el_efecto:
	ld a,d			;4f69   ; el efecto 2 deja sonando el 0x2C
	cp 002h		;4f6a   ; era el efecto 2?
	ld a,02ch		;4f6c   ; la musica 0x2C...
	call z,toca_sonido		;4f6e   ; ...la toca
	dec c			;4f71   ; y el tercer canal recupera sus registros
	dec c			;4f72   ; C del tercer canal
	ld a,(0e0f3h)		;4f73   ; tras la pausa?
	or a			;4f76   ; no...
	call z,escribe_el_volumen		;4f77   ; ...el volumen del tercero
	ld ix,0e050h		;4f7a   ; IX: el tercer canal...
	jr escribe_el_periodo		;4f7e   ; ...su periodo al PSG
pon_el_periodo:
	ld a,(0e072h)		;4f80   ; (0xE072): hay efecto sonando
	ld e,a			;4f83   ; E = el efecto que suena
	ld a,c			;4f84   ; los dos primeros canales, siempre
	cp 005h		;4f85   ; los dos primeros canales...
	jr c,escribe_el_periodo		;4f87   ; ...siempre
	jr nz,L_4F90		;4f89   ; el tercero solo si no hay efecto
	ld a,e			;4f8b   ; el tercero...
	or a			;4f8c   ; ...con efecto sonando...
	ret nz			;4f8d   ; ...no toca el PSG
	jr escribe_el_periodo		;4f8e   ; sin efecto, si
L_4F90:
	ld a,e			;4f90   ; y el de efectos solo si lo hay, en los registros del tercero
	or a			;4f91   ; el de efectos, sin efecto...
	ret z			;4f92   ; ...nada
	dec c			;4f93   ; con efecto, los registros del tercero
	dec c			;4f94
	call escribe_el_periodo		;4f95   ; escritos
	inc c			;4f98   ; C otra vez...
	inc c			;4f99   ; ...el suyo
	ret			;4f9a   ; vuelta
escribe_el_periodo:
	ld l,(ix+015h)		;4f9b   ; el periodo...
	ld h,(ix+016h)		;4f9e   ; ...del canal
	ld a,(ix+00fh)		;4fa1   ; desafinado: el periodo + 1, la nota un pelo mas grave
	cp 008h		;4fa4   ; desafinado?
	jr nz,L_4FA9		;4fa6   ; no
	inc hl			;4fa8   ; si: uno mas
L_4FA9:
	ld a,c			;4fa9   ; registro C: el byte alto
	ld e,h			;4faa   ; el byte alto
	call 00093h		;4fab   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,c			;4fae   ; registro C-1: el bajo
	dec a			;4faf   ; registro C-1...
	ld e,l			;4fb0   ; ...el bajo
	call 00093h		;4fb1   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,(ix+010h)		;4fb4   ; con instrumento...
	or a			;4fb7   ; ...?
	ret nz			;4fb8   ; si: ya esta
	ld a,(ix+00eh)		;4fb9   ; el modo
	or a			;4fbc   ; efecto...
	ret z			;4fbd   ; ...ya esta
	ld (ix+005h),002h		;4fbe   ; modo musica sin instrumento: el tipo pasa a tono solo
	ret			;4fc2   ; vuelta

; ----------------------------------------------------------------------
; DATOS periodos_de_las_notas: Los doce semitonos de la octava mas aguda, del
;   do al si: 107, 101, 95, 90, 85, 80, 76, 71, 67, 64, 60 y 57. El resto de
;   octavas se sacan doblando el periodo
;   0x4fc3..0x4fcf  (12 bytes)
DATA_periodos_de_las_notas:
	defb 06bh,065h,05fh,05ah,055h,050h,04ch,047h,043h,040h,03ch,039h	; 4fc3  ke_ZUPLGC@<9

; ======================================================================
; CODIGO 0x4fcf..0x50a6  (215 bytes)
; ======================================================================


pon_el_volumen:
	ld a,(0e072h)		;4fcf   ; el efecto que suena
	ld e,a			;4fd2   ; en E
	ld a,c			;4fd3   ; el canal
	cp 005h		;4fd4   ; los dos primeros...
	jr c,escribe_el_volumen		;4fd6   ; ...siempre
	jr nz,L_4FDF		;4fd8   ; el de efectos: a 0x4FDF
	ld a,e			;4fda   ; el tercero con efecto...
	or a			;4fdb   ; ...sonando...
	ret nz			;4fdc   ; ...no toca el PSG
	jr escribe_el_volumen		;4fdd   ; sin efecto, si
L_4FDF:
	ld a,e			;4fdf   ; el de efectos...
	or a			;4fe0   ; ...sin efecto...
	ret z			;4fe1   ; ...nada
	dec c			;4fe2   ; con efecto, el registro del tercero
	dec c			;4fe3
escribe_el_volumen:
	call pon_el_mezclador		;4fe4   ; primero el mezclador
	ld a,c			;4fe7   ; el registro de volumen: 8, 9 o 10
	rrca			;4fe8   ; 1, 3 o 5 -> 0x80, 0x81 o 0x82...
	add a,088h		;4fe9   ; ...+ 0x88: 8, 9 o 10 (el acarreo se pierde)
	ld d,a			;4feb   ; D = el registro
	ld h,(ix+017h)		;4fec   ; el volumen
	ld a,(ix+005h)		;4fef   ; el tipo
	bit 3,a		;4ff2   ; con la envolvente del PSG, su forma al registro 13 y volumen 16
	jr z,L_4FFF		;4ff4   ; sin envolvente
	ld e,h			;4ff6   ; la forma...
	ld a,00dh		;4ff7   ; ...al registro 13
	call 00093h		;4ff9   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,010h		;4ffc   ; 16: volumen de la envolvente
	ld h,a			;4ffe   ; en H
L_4FFF:
	ld a,d			;4fff   ; el registro
	ld e,h			;5000   ; el volumen
	jp 00093h		;5001   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
copia_los_canales:		; Los 0x60 bytes de tres canales de HL a DE, y fuera la marca de pausa
	ld bc,00060h		;5004   ; 0x60 bytes
	ldir		;5007   ; copiados
	ld c,a			;5009   ; C = A
	xor a			;500a   ; cero...
	ld (0e0f1h),a		;500b   ; ...en (0xE0F1)
	ret			;500e   ; vuelta
orden_fe:
	inc hl			;500f   ; el byte de detras del 0xFE
	ld a,(hl)			;5010   ; 0xFE 0x00: cambia de modo
	or a			;5011   ; 0x00...
	jr z,cambia_de_modo		;5012   ; ...cambia de modo
	inc a			;5014   ; 0xFE 0xFF: subrutina
	jr z,llama_a_la_subrutina		;5015   ; 0xFF: subrutina
	ld a,(ix+00bh)		;5017   ; 0xFE N dir: vuelve a dir hasta N veces
	inc a			;501a   ; la vuelta que toca
	cp (hl)			;501b   ; se han dado todas?
	jr z,acaba_el_bucle		;501c   ; si: se acabo el bucle
	jp m,L_5022		;501e   ; por debajo de N, la cuenta sube
	dec a			;5021   ; si no, la cuenta se queda como estaba
L_5022:
	ld (ix+00bh),a		;5022   ; la cuenta
	inc hl			;5025   ; la direccion del bucle...
	ld a,(hl)			;5026   ; ...byte bajo...
	ld (ix+003h),a		;5027   ; ...al puntero
	inc hl			;502a   ; ...y alto
	ld a,(hl)			;502b
	ld (ix+004h),a		;502c   ; ...al puntero
	jr L_503A		;502f   ; y adelante
acaba_el_bucle:
	inc hl			;5031   ; se salta la direccion
	inc hl			;5032
	xor a			;5033   ; cuenta...
	ld (ix+00bh),a		;5034   ; ...a cero
salta_la_orden:
	call guarda_el_puntero		;5037   ; el puntero, detras
L_503A:
	inc (ix+000h)		;503a   ; la cuenta, sin acabar
	jp avanza_el_canal		;503d   ; y la orden siguiente
cambia_de_modo:
	ld a,(ix+00eh)		;5040   ; el modo
	or a			;5043   ; musica?
	jr z,L_504B		;5044   ; efecto: a musica
	dec (ix+00eh)		;5046   ; musica: a efecto
	jr L_504E		;5049   ; y adelante
L_504B:
	inc (ix+00eh)		;504b   ; a musica
L_504E:
	jr salta_la_orden		;504e   ; y adelante
llama_a_la_subrutina:
	inc hl			;5050   ; la direccion de la subrutina...
	ld e,(hl)			;5051   ; ...byte bajo...
	ld (ix+003h),e		;5052   ; ...al puntero
	inc hl			;5055   ; ...alto...
	ld d,(hl)			;5056
	ld (ix+004h),d		;5057   ; ...al puntero
	inc hl			;505a   ; la vuelta: detras de la direccion
	ld (ix+018h),l		;505b   ; la vuelta, en +18/+19
	ld (ix+019h),h		;505e   ; su byte alto
	ex de,hl			;5061   ; HL = la subrutina
	jp L_4D3C		;5062   ; y su primera orden
guarda_el_puntero:
	inc hl			;5065   ; detras
	ld (ix+003h),l		;5066   ; el puntero...
	ld (ix+004h),h		;5069   ; ...guardado
	ret			;506c   ; vuelta

; ----------------------------------------------------------------------
; EL MEZCLADOR (registro 7 del PSG). Con el tipo del canal: bit 1, su tono; bit 0, su ruido. Un bit a uno en el registro 7 CIERRA el canal, asi que se ponen a uno los que no suenan.
; ----------------------------------------------------------------------
pon_el_mezclador:
	ld a,(0e0f0h)		;506d   ; el registro 7 que hay
	ld e,a			;5070   ; en E
	ld a,(ix+005h)		;5071   ; el tipo del canal
	and 003h		;5074   ; tono y ruido
	ld d,a			;5076   ; en D
	ld a,c			;5077   ; el bit del canal: 1, 2 o 4
	cp 001h		;5078   ; el primero: bit 1
	jr z,L_507D		;507a
	dec a			;507c   ; los otros: 2 y 4
L_507D:
	ld b,a			;507d   ; B = el bit del canal
	bit 1,d		;507e   ; el tono
	call z,cierra_el_bit		;5080   ; sin tono: se cierra
	bit 1,d		;5083   ; con tono...
	call nz,abre_el_bit		;5085   ; ...se abre
	ld a,b			;5088   ; el ruido, tres bits mas arriba
	rlca			;5089   ; el bit del ruido, tres mas arriba
	rlca			;508a
	rlca			;508b
	bit 0,d		;508c   ; sin ruido...
	call z,cierra_el_bit		;508e   ; ...se cierra
	bit 0,d		;5091   ; con ruido...
	call nz,abre_el_bit		;5093   ; ...se abre
escribe_el_mezclador:
	ld (0e0f0h),a		;5096   ; guardado
	ld e,a			;5099   ; en E
	ld a,007h		;509a   ; registro 7
	jp 00093h		;509c   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
abre_el_bit:
	cpl			;509f   ; el bit, invertido...
	and e			;50a0   ; ...a cero en el registro
	ld e,a			;50a1   ; en E
	ret			;50a2   ; vuelta
cierra_el_bit:
	or e			;50a3   ; el bit a uno
	ld e,a			;50a4   ; en E
	ret			;50a5   ; vuelta

; ----------------------------------------------------------------------
; DATOS instrumentos: Los dos instrumentos que piden las ordenes 0xE9 y 0xEA:
;   0x4ED8 indexa desde 0x50A4, asi que el 1 esta en 0x50A6
;   0x50a6..0x50aa  (4 bytes)
DATA_instrumentos:
	defw 050aah,051e5h	; 50a6  -> DATA_notas_del_instrumento_1 DATA_notas_del_instrumento_2

; ----------------------------------------------------------------------
; DATOS notas_del_instrumento_1: Doce punteros, uno por nota (del do al si):
;   la tabla acaba donde empieza la primera secuencia
;   0x50aa..0x50c2  (24 bytes)
DATA_notas_del_instrumento_1:
	defw 050c2h,050c8h,050ceh,050e1h,050f2h,05100h,05111h,05122h	; 50aa
	defw 0514bh,0517ah,051a9h,051d4h	; 50ba

; ----------------------------------------------------------------------
; DATOS pasos_del_instrumento_1: Las doce secuencias del instrumento 1, en
;   formato de efecto (volumen y periodo por paso) y cada una con su 0xFF
;   0x50c2..0x51e5  (291 bytes)
DATA_pasos_del_instrumento_1:
	defb 021h,001h,010h,0a0h,000h,0ffh,021h,001h	; 50c2  !.....!.
	defb 010h,0b0h,000h,0ffh,023h,001h,010h,0cah	; 50ca  ....#...
	defb 000h,021h,004h,010h,0a0h,000h,090h,000h	; 50d2  .!......
	defb 080h,000h,070h,000h,060h,000h,0ffh,022h	; 50da  ..p.`.."
	defb 004h,090h,01ch,080h,01ch,070h,01ch,060h	; 50e2  .....p.`
	defb 01ch,050h,01ch,040h,01ch,030h,01ch,0ffh	; 50ea  .P.@.0..
	defb 023h,001h,013h,0b1h,080h,022h,001h,0a2h	; 50f2  #...."..
	defb 000h,082h,070h,063h,030h,0ffh,022h,004h	; 50fa  ..pc0.".
	defb 090h,03ch,080h,03ch,070h,03ch,060h,03ch	; 5102  .<.<p<`<
	defb 050h,03ch,040h,03ch,030h,03ch,0ffh,022h	; 510a  P<@<0<."
	defb 004h,090h,048h,080h,048h,070h,048h,060h	; 5112  ..H.HpH`
	defb 048h,050h,048h,040h,048h,030h,048h,0ffh	; 511a  HPH@H0H.
	defb 022h,001h,0b1h,000h,0a1h,00ah,0a1h,015h	; 5122  ".......
	defb 091h,020h,091h,02ah,091h,035h,081h,040h	; 512a  . .*.5.@
	defb 081h,04ah,081h,055h,081h,060h,071h,06ah	; 5132  .J.U.`qj
	defb 071h,075h,071h,080h,071h,08ah,071h,095h	; 513a  quq.q.q.
	defb 071h,0a0h,061h,0aah,061h,0b5h,051h,0c0h	; 5142  q.a.a.Q.
	defb 0ffh,022h,001h,0c2h,000h,0b2h,00ah,0b2h	; 514a  ."......
	defb 015h,0a2h,020h,0a2h,02ah,0a2h,035h,092h	; 5152  .. .*.5.
	defb 040h,092h,04ah,092h,055h,092h,060h,082h	; 515a  @.J.U.`.
	defb 06ah,082h,075h,082h,080h,082h,08ah,082h	; 5162  j.u.....
	defb 095h,072h,0a0h,072h,0aah,072h,0b5h,072h	; 516a  .r.r.r.r
	defb 0c0h,062h,0cah,062h,0d5h,052h,0e0h,0ffh	; 5172  .b.b.R..
	defb 022h,001h,0d3h,000h,0c3h,00ah,0c3h,015h	; 517a  ".......
	defb 0b3h,020h,0b3h,02ah,0b3h,035h,0a3h,040h	; 5182  . .*.5.@
	defb 0a3h,04ah,0a3h,055h,0a3h,060h,093h,06ah	; 518a  .J.U.`.j
	defb 093h,075h,093h,080h,093h,08ah,093h,095h	; 5192  .u......
	defb 083h,0a0h,083h,0aah,083h,0b5h,073h,0c0h	; 519a  ......s.
	defb 073h,0cah,063h,0d5h,053h,0e0h,0ffh,022h	; 51a2  s.c.S.."
	defb 001h,0e4h,000h,0d4h,015h,0c4h,030h,0c4h	; 51aa  ......0.
	defb 045h,0b4h,060h,0b4h,075h,0b4h,090h,0a4h	; 51b2  E.`.u...
	defb 0b0h,0a4h,0d0h,0a4h,0f0h,0a5h,010h,095h	; 51ba  ........
	defb 030h,095h,050h,094h,070h,094h,090h,094h	; 51c2  0.P.p...
	defb 0b0h,084h,0d0h,084h,0f0h,075h,010h,065h	; 51ca  .....u.e
	defb 030h,0ffh,022h,004h,090h,01bh,080h,01bh	; 51d2  0.".....
	defb 070h,01bh,060h,01bh,050h,01bh,040h,01bh	; 51da  p.`.P.@.
	defb 030h,01bh,0ffh	; 51e2

; ----------------------------------------------------------------------
; DATOS notas_del_instrumento_2: Trece punteros: este tiene tambien la nota
;   12, que sin instrumento seria un silencio
;   0x51e5..0x51ff  (26 bytes)
DATA_notas_del_instrumento_2:
	defw 051ffh,05218h,05229h,0523ah,0524dh,0525eh,0526fh,05280h	; 51e5
	defw 05291h,052a2h,052b3h,052c4h,052d5h	; 51f5

; ----------------------------------------------------------------------
; DATOS pasos_del_instrumento_2: Sus trece secuencias. La ultima acaba en
;   0x52E3, dentro de lo que seria la entrada 0 de la tabla de 0x52E2, que no
;   se usa porque los sonidos empiezan en el 1
;   0x51ff..0x52e4  (229 bytes)
DATA_pasos_del_instrumento_2:
	defb 022h,001h,090h,036h,090h,035h,022h,002h	; 51ff  "..6.5".
	defb 090h,036h,022h,004h,080h,036h,070h,036h	; 5207  .6"..6p6
	defb 060h,036h,050h,036h,040h,036h,030h,036h	; 520f  `6P6@606
	defb 0ffh,022h,004h,090h,050h,080h,050h,070h	; 5217  ."..P.Pp
	defb 050h,060h,050h,050h,050h,040h,050h,030h	; 521f  P`PPP@P0
	defb 050h,0ffh,022h,004h,090h,02fh,080h,02fh	; 5227  P.".././
	defb 070h,02fh,060h,02fh,050h,02fh,040h,02fh	; 522f  p/`/P/@/
	defb 030h,02fh,0ffh,022h,004h,090h,02dh,080h	; 5237  0/."..-.
	defb 02dh,070h,02dh,060h,02dh,050h,02dh,040h	; 523f  -p-`-P-@
	defb 02dh,030h,02dh,020h,02dh,0ffh,022h,004h	; 5247  -0- -.".
	defb 090h,02ah,080h,02ah,070h,02ah,060h,02ah	; 524f  .*.*p*`*
	defb 050h,02ah,040h,02ah,030h,02ah,0ffh,022h	; 5257  P*@*0*."
	defb 004h,090h,028h,080h,028h,070h,028h,060h	; 525f  ..(.(p(`
	defb 028h,050h,028h,040h,028h,030h,028h,0ffh	; 5267  (P(@(0(.
	defb 022h,004h,090h,026h,080h,026h,070h,026h	; 526f  "..&.&p&
	defb 060h,026h,050h,026h,040h,026h,030h,026h	; 5277  `&P&@&0&
	defb 0ffh,022h,004h,090h,024h,080h,024h,070h	; 527f  ."..$.$p
	defb 024h,060h,024h,050h,024h,040h,024h,030h	; 5287  $`$P$@$0
	defb 024h,0ffh,022h,004h,090h,022h,080h,022h	; 528f  $.".."."
	defb 070h,022h,060h,022h,050h,022h,040h,022h	; 5297  p"`"P"@"
	defb 030h,022h,0ffh,022h,004h,090h,020h,080h	; 529f  0".".. .
	defb 020h,070h,020h,060h,020h,050h,020h,040h	; 52a7   p ` P @
	defb 020h,030h,020h,0ffh,022h,004h,090h,01eh	; 52af   0 ."...
	defb 080h,01eh,070h,01eh,060h,01eh,050h,01eh	; 52b7  ..p.`.P.
	defb 040h,01eh,030h,01eh,0ffh,022h,004h,090h	; 52bf  @.0.."..
	defb 03ch,080h,03ch,070h,03ch,060h,03ch,050h	; 52c7  <.<p<`<P
	defb 03ch,040h,03ch,030h,03ch,0ffh,022h,003h	; 52cf  <@<0<.".
	defb 080h,040h,070h,040h,060h,040h,050h,040h	; 52d7  .@p@`@P@
	defb 040h,040h,030h,040h,0ffh	; 52df

; ----------------------------------------------------------------------
; DATOS tabla_de_sonidos: 93 punteros, del sonido 1 al 0x5D. Un efecto
;   (0x01-0x16) usa una entrada; una musica (de 0x17 en adelante, de tres en
;   tres) usa tres seguidas, una por canal; y el 0x56, la pausa, cuatro
;   0x52e4..0x539e  (186 bytes)
DATA_tabla_de_sonidos:
	defw 0539eh,053adh,053dch,053e7h,053f2h,053fdh,0543ah,05467h	; 52e4
	defw 05480h,054b7h,054ech,0551ch,0555ah,05566h,0551ch,05571h	; 52f4
	defw 05584h,055cbh,056a4h,061dch,056f8h,05709h,05732h,057e6h	; 5304
	defw 05845h,058ffh,059cdh,05a17h,05a43h,05a6fh,05a9dh,05ad2h	; 5314
	defw 05b01h,05b24h,05b51h,05b6ah,05b7eh,05b92h,05baeh,05bcah	; 5324
	defw 05bf0h,05c21h,05c3fh,05c8ah,05cc1h,05ce6h,05d0bh,05d14h	; 5334
	defw 061dch,05d2dh,05d3ah,05d44h,05d4eh,05d57h,05d60h,05d69h	; 5344
	defw 05d74h,05d83h,05d8eh,061dch,05d92h,05d98h,05dc3h,05dfah	; 5354
	defw 05e33h,05e6ah,05ea0h,05ec4h,05f05h,05f4ah,05f62h,05fb3h	; 5364
	defw 05fd8h,06013h,0602ah,06044h,05e3fh,05e5fh,05e97h,0605ah	; 5374
	defw 060c9h,06123h,06173h,0619eh,061b5h,061dch,05c6dh,05c7bh	; 5384
	defw 061dch,061dch,061dch,061dch,061dch	; 5394

; ----------------------------------------------------------------------
; DATOS secuencias_de_sonido: Los canales de todos los sonidos, uno detras de
;   otro. Formato en 0x4D2D (efecto) y 0x4E0F (musica); 0xFE lleva los bucles,
;   las subrutinas y el cambio de modo, y 0xFF acaba
;   0x539e..0x61dd  (3647 bytes)
DATA_secuencias_de_sonido:
	defb 0feh,000h,02ah,005h,001h,000h,090h,060h,02ah,001h,000h,0c0h,090h,040h,0ffh,0feh	; 539e  ..*....`*....@..
	defb 000h,022h,001h,060h,028h,080h,055h,080h,050h,090h,04ah,0a0h,048h,0b0h,047h,0b0h	; 53ae  .".`(.U.P.J.H.G.
	defb 048h,0b0h,047h,0b0h,049h,0b0h,048h,0b0h,04ah,0b0h,049h,0b0h,04ch,0b0h,04bh,0b0h	; 53be  H.G.I.H.J.I.L.K.
	defb 04fh,0b0h,04eh,0b0h,053h,0b0h,052h,0b0h,055h,0b0h,056h,020h,023h,0ffh,0feh,000h	; 53ce  O.N.S.R.U.V #...
	defb 022h,001h,0e0h,050h,0b0h,050h,070h,050h,0ffh,0feh,000h,022h,001h,0c0h,0a0h,0c0h	; 53de  "..P.PpP..."....
	defb 080h,0c0h,060h,0ffh,0feh,000h,022h,001h,0c0h,068h,0c0h,075h,0c0h,080h,0ffh,0feh	; 53ee  ..`..."..h.u....
	defb 000h,023h,001h,010h,0f0h,010h,0e0h,020h,020h,003h,023h,001h,010h,0d0h,040h,0b0h	; 53fe  .#.....  .#...@.
	defb 020h,090h,040h,020h,002h,023h,001h,0a0h,040h,080h,020h,020h,002h,023h,001h,090h	; 540e   .@ .#..@.  .#..
	defb 040h,070h,020h,020h,003h,023h,001h,080h,040h,060h,020h,020h,003h,023h,001h,070h	; 541e  @p  .#..@`  .#.p
	defb 040h,050h,020h,020h,003h,023h,001h,060h,040h,040h,020h,0ffh,0feh,000h,022h,001h	; 542e  @P  .#.`@@ ...".
	defb 0f3h,000h,0a0h,06dh,0e4h,0a0h,020h,002h,022h,001h,0d0h,080h,0c1h,000h,0c0h,080h	; 543e  ...m.. .".......
	defb 0c0h,082h,0b0h,084h,0a0h,086h,090h,08ah,091h,010h,080h,088h,081h,014h,070h,08ah	; 544e  ..............p.
	defb 071h,018h,060h,08ch,051h,01ch,040h,090h,0ffh,0feh,000h,022h,001h,0c0h,050h,0c0h	; 545e  q.`.Q.@...."..P.
	defb 048h,0b0h,000h,0b0h,040h,0a0h,038h,0a0h,000h,0a0h,028h,0a0h,000h,0a0h,020h,0a0h	; 546e  H...@.8...(... .
	defb 01dh,0ffh,0feh,000h,02ah,002h,001h,000h,090h,060h,02ah,00ch,005h,000h,090h,060h	; 547e  ....*....`*....`
	defb 02ah,006h,004h,000h,090h,060h,02ah,003h,002h,000h,090h,060h,02ah,004h,002h,000h	; 548e  *....`*....`*...
	defb 090h,060h,02ah,005h,002h,000h,090h,061h,02ah,006h,005h,000h,090h,060h,022h,001h	; 549e  .`*....a*....`".
	defb 070h,060h,060h,060h,050h,060h,040h,060h,0ffh,0efh,0d1h,0f9h,000h,0e1h,000h,020h	; 54ae  p```P`@`....... 
	defb 040h,050h,0fah,000h,020h,040h,050h,070h,0fbh,000h,040h,050h,070h,090h,0fch,000h	; 54be  @P.. @Pp..@Pp...
	defb 050h,070h,090h,0d3h,0f9h,066h,0b0h,0e0h,0b0h,0d4h,0f8h,066h,0e1h,0b0h,0e0h,0b0h	; 54ce  Pp...f.....f....
	defb 0f7h,066h,0e1h,0b0h,0e0h,0b0h,0d5h,0f6h,066h,0e1h,0b0h,0e0h,0b0h,0ffh,0efh,0d1h	; 54de  .f......f.......
	defb 0fbh,000h,0e1h,0b0h,090h,070h,050h,0fah,000h,090h,070h,050h,040h,0f9h,000h,070h	; 54ee  .....pP...pP@..p
	defb 050h,040h,020h,050h,040h,020h,000h,040h,020h,000h,0e2h,0b0h,0e1h,020h,000h,0e2h	; 54fe  P@ P@ .@ .... ..
	defb 0b0h,0f8h,000h,090h,070h,0f7h,000h,050h,040h,0f6h,000h,020h,000h,0ffh,0feh,000h	; 550e  ....p..P@.. ....
	defb 023h,001h,010h,0b0h,070h,0c0h,068h,0c0h,060h,0d0h,058h,0d0h,050h,0d0h,04ah,0e0h	; 551e  #...p.h.`.X.P.J.
	defb 045h,0e0h,040h,0d0h,03ah,0d0h,035h,0c0h,030h,0c0h,032h,0c0h,034h,0b0h,036h,0c0h	; 552e  E.@.:.5.0.2.4.6.
	defb 038h,0c0h,039h,0c0h,03ah,0b0h,03bh,0b0h,03ch,0b0h,03dh,0b0h,03eh,0a0h,03fh,0a0h	; 553e  8.9.:.;.<.=.>.?.
	defb 040h,0a0h,041h,0a0h,042h,0a0h,043h,0a0h,044h,090h,045h,0ffh,0feh,000h,022h,001h	; 554e  @.A.B.C.D.E...".
	defb 0b0h,060h,020h,006h,0feh,0feh,05ch,055h,0feh,000h,022h,001h,0d0h,020h,0a0h,020h	; 555e  .` ...\U..".. . 
	defb 050h,020h,0ffh,0feh,000h,022h,001h,0b0h,035h,0c0h,033h,0c0h,031h,0b0h,02fh,020h	; 556e  P ..."..5.3.1./ 
	defb 003h,0feh,003h,073h,055h,0ffh,0feh,000h,022h,001h,0c0h,080h,0c0h,060h,0c0h,040h	; 557e  ...sU..."....`.@
	defb 0c0h,075h,0c0h,055h,0c0h,035h,022h,003h,0b0h,070h,0b0h,050h,0b0h,030h,0b0h,020h	; 558e  .u.U.5"..p.P.0. 
	defb 020h,004h,022h,001h,0c0h,01fh,0c0h,01eh,0b0h,01eh,020h,003h,022h,001h,0a0h,028h	; 559e   ."....... ."..(
	defb 0b0h,029h,0c0h,028h,022h,003h,0c0h,029h,0b0h,028h,0b0h,029h,0a0h,028h,0a0h,029h	; 55ae  .).("..).(.).(.)
	defb 090h,028h,090h,029h,080h,028h,080h,029h,070h,028h,060h,029h,0ffh,0feh,000h,022h	; 55be  .(.).(.)p(`)..."
	defb 002h,0b0h,031h,0b0h,032h,0b0h,033h,0b0h,034h,0b0h,035h,0b0h,032h,0b0h,033h,0b0h	; 55ce  ..1.2.3.4.5.2.3.
	defb 034h,0b0h,035h,0b0h,036h,0b0h,033h,0b0h,034h,0b0h,035h,0b0h,036h,0b0h,037h,0b0h	; 55de  4.5.6.3.4.5.6.7.
	defb 034h,0b0h,035h,0b0h,036h,0b0h,037h,0b0h,038h,0b0h,035h,0b0h,036h,0b0h,037h,0b0h	; 55ee  4.5.6.7.8.5.6.7.
	defb 038h,0b0h,039h,0b0h,036h,0b0h,037h,0b0h,038h,0b0h,039h,0b0h,03ah,0b0h,037h,0b0h	; 55fe  8.9.6.7.8.9.:.7.
	defb 038h,0b0h,039h,0b0h,03ah,0b0h,03bh,0b0h,038h,0b0h,039h,0b0h,03ah,0b0h,03bh,0b0h	; 560e  8.9.:.;.8.9.:.;.
	defb 03ch,0b0h,039h,0b0h,03ah,0b0h,03bh,0b0h,03ch,0b0h,03dh,0b0h,03ah,0b0h,03bh,0b0h	; 561e  <.9.:.;.<.=.:.;.
	defb 03ch,0b0h,03dh,0b0h,03eh,0b0h,03bh,0b0h,03ch,0b0h,03dh,0b0h,03eh,0b0h,03fh,0b0h	; 562e  <.=.>.;.<.=.>.?.
	defb 03ch,0b0h,03dh,0b0h,03eh,0b0h,03fh,0b0h,040h,0b0h,03dh,0b0h,03eh,0b0h,03fh,0b0h	; 563e  <.=.>.?.@.=.>.?.
	defb 040h,0b0h,041h,0b0h,03eh,0b0h,03fh,0b0h,040h,0b0h,041h,0b0h,042h,0b0h,03fh,0b0h	; 564e  @.A.>.?.@.A.B.?.
	defb 040h,0b0h,041h,0b0h,042h,0b0h,043h,0b0h,040h,0b0h,041h,0b0h,042h,0b0h,043h,0b0h	; 565e  @.A.B.C.@.A.B.C.
	defb 044h,0b0h,041h,0b0h,042h,0b0h,043h,0b0h,044h,0b0h,045h,0b0h,042h,0b0h,043h,0b0h	; 566e  D.A.B.C.D.E.B.C.
	defb 044h,0b0h,045h,0b0h,046h,0b0h,043h,0b0h,044h,0b0h,045h,0b0h,046h,0b0h,047h,0b0h	; 567e  D.E.F.C.D.E.F.G.
	defb 044h,0b0h,045h,0b0h,046h,0b0h,047h,0b0h,048h,0b0h,045h,0b0h,046h,0b0h,047h,0b0h	; 568e  D.E.F.G.H.E.F.G.
	defb 048h,0b0h,049h,0b0h,046h,0ffh,0feh,000h,02ah,001h,000h,020h,080h,030h,02ah,001h	; 569e  H.I.F...*.. .0*.
	defb 000h,015h,080h,040h,02ah,001h,000h,010h,0a0h,030h,02ah,001h,000h,030h,080h,050h	; 56ae  ...@*....0*..0.P
	defb 020h,001h,02ah,001h,000h,030h,080h,030h,080h,070h,080h,020h,080h,025h,020h,003h	; 56be   .*..0.0.p. .% .
	defb 022h,001h,0b0h,080h,0b0h,0a0h,0b0h,090h,0b0h,0b0h,0a0h,0a0h,0a0h,0c0h,0a0h,0b0h	; 56ce  "...............
	defb 0a0h,0d0h,0a0h,0c0h,0a0h,0e0h,0a0h,0d0h,0a0h,0f0h,0a0h,0e0h,0a1h,000h,0a0h,0f0h	; 56de  ................
	defb 0a1h,010h,0a1h,000h,0a1h,020h,0feh,0feh,0cdh,055h,0feh,000h,022h,001h,080h,030h	; 56ee  ..... ...U.."..0
	defb 090h,032h,0a0h,050h,0b0h,052h,0a0h,070h,0b0h,073h,0ffh,0feh,000h,020h,003h,022h	; 56fe  .2.P.R.p.s... ."
	defb 001h,090h,050h,080h,06eh,090h,071h,020h,002h,022h,001h,080h,052h,070h,070h,080h	; 570e  ..P.n.q ."..Rpp.
	defb 073h,020h,001h,022h,001h,070h,050h,060h,06eh,070h,071h,022h,001h,060h,052h,050h	; 571e  s .".pP`npq".`RP
	defb 070h,060h,073h,0ffh,0efh,0d8h,0f9h,013h,0e2h,091h,0feh,0ffh,0bfh,057h,0efh,0e2h	; 572e  p`s..........W..
	defb 091h,0feh,0ffh,0bfh,057h,0efh,0f9h,013h,0e2h,051h,0e1h,000h,0c1h,000h,0c1h,000h	; 573e  ....W....Q......
	defb 021h,000h,051h,050h,020h,000h,0e2h,090h,055h,0a1h,0a0h,080h,050h,020h,081h,080h	; 574e  !.QP ...U...P ..
	defb 070h,050h,020h,001h,000h,000h,020h,050h,080h,050h,070h,050h,080h,050h,0a0h,080h	; 575e  pP ... P.PpP.P..
	defb 059h,0c2h,0e1h,000h,020h,050h,0d2h,070h,086h,070h,082h,0d8h,070h,050h,020h,0d2h	; 576e  Y... P.p.p..pP .
	defb 0a0h,0e0h,006h,0e1h,070h,086h,0d8h,05ah,050h,030h,000h,0e2h,0b0h,0e1h,000h,050h	; 577e  ....p..ZP0.....P
	defb 030h,000h,0e2h,050h,0e1h,081h,000h,071h,020h,051h,050h,050h,030h,000h,080h,020h	; 578e  0..P...q QPP0.. 
	defb 0a0h,020h,080h,020h,0a0h,020h,080h,020h,0a0h,020h,0d2h,0b0h,0e0h,006h,0e1h,080h	; 579e  . . . . . ......
	defb 092h,0d8h,058h,001h,0e2h,0a0h,0b1h,0e1h,002h,000h,000h,020h,040h,0feh,0feh,036h	; 57ae  ..X........ @..6
	defb 057h,0e1h,000h,0eah,001h,000h,022h,0efh,021h,000h,0eah,021h,0efh,0e0h,000h,0c1h	; 57be  W.....".!..!....
	defb 000h,0e2h,092h,0e1h,000h,0c0h,0d4h,0f7h,000h,0e2h,0a0h,0e1h,000h,0feh,015h,0d7h	; 57ce  ................
	defb 057h,0d8h,0c0h,0eah,000h,020h,040h,0ffh,0efh,0d8h,0fah,014h,0e3h,051h,050h,042h	; 57de  W.... @......QPB
	defb 022h,002h,0e4h,0a2h,092h,071h,0e3h,002h,000h,0e4h,0a1h,0a0h,092h,072h,052h,042h	; 57ee  "....q.......rRB
	defb 022h,001h,000h,000h,020h,040h,0feh,002h,0eah,057h,0e4h,051h,050h,092h,0e3h,001h	; 57fe  "... @...W.QP...
	defb 000h,022h,032h,022h,002h,0e4h,092h,0a1h,0a0h,0e3h,022h,052h,072h,082h,072h,052h	; 580e  ."2"......"Rr.rR
	defb 022h,0feh,002h,008h,058h,0e3h,001h,000h,042h,072h,092h,0e4h,0a1h,0a0h,0e3h,022h	; 581e  "...X...Br....."
	defb 052h,072h,0e4h,051h,050h,092h,0a2h,0b2h,0e3h,001h,0e4h,0a0h,0b1h,0e3h,002h,000h	; 582e  Rr.QP...........
	defb 000h,020h,040h,0feh,0feh,0eah,057h,0efh,0d8h,0f9h,013h,0e2h,051h,090h,0e9h,001h	; 583e  . @...W.....Q...
	defb 000h,022h,0efh,0e2h,0a1h,090h,0c1h,0e1h,050h,0c1h,050h,0e2h,052h,090h,0c0h,0dch	; 584e  ."......P.P.R...
	defb 07dh,0d8h,0f9h,033h,0e2h,0c0h,000h,020h,040h,0feh,002h,049h,058h,0e2h,001h,090h	; 585e  }..3... @..IX...
	defb 0c1h,090h,0c1h,090h,0a1h,090h,0e1h,001h,000h,0e2h,0a0h,080h,050h,005h,0e3h,0a1h	; 586e  ............P...
	defb 0a0h,0a0h,0e2h,000h,020h,051h,050h,030h,020h,0e3h,0a0h,0eah,000h,020h,050h,092h	; 587e  .... QP0 .... P.
	defb 0efh,0e2h,030h,000h,020h,000h,030h,000h,050h,030h,003h,0e3h,0b0h,0e2h,000h,000h	; 588e  ..0. .0.P0......
	defb 0feh,003h,099h,058h,0e3h,0a0h,0e2h,000h,000h,0e3h,0b0h,0e2h,000h,000h,0e3h,0a0h	; 589e  ...X............
	defb 0e2h,000h,000h,000h,020h,050h,000h,020h,050h,000h,020h,070h,000h,020h,050h,000h	; 58ae  .... P. P. p. P.
	defb 020h,050h,000h,020h,080h,000h,070h,050h,030h,000h,0e3h,0a0h,0e1h,031h,0e2h,050h	; 58be   P. ..pP0....1.P
	defb 0e1h,021h,0e2h,050h,0e1h,001h,000h,0e2h,0a0h,080h,050h,0f8h,013h,0e0h,050h,080h	; 58ce  .!.P......P...P.
	defb 050h,0a0h,050h,080h,050h,080h,050h,0a0h,050h,080h,051h,000h,0e1h,082h,022h,000h	; 58de  P.P.P.P.P.Q...".
	defb 0e2h,090h,050h,0f9h,015h,091h,050h,061h,072h,070h,070h,090h,0b0h,0feh,0feh,049h	; 58ee  ..P...Parpp....I
	defb 058h,0efh,0d4h,0f9h,014h,0e1h,050h,0e0h,050h,0feh,006h,003h,059h,0d8h,0fah,033h	; 58fe  X.....P.P...Y..3
	defb 0e1h,050h,080h,0c0h,0a0h,0c0h,0b0h,0e0h,000h,0e1h,050h,080h,0b0h,0e0h,000h,0e1h	; 590e  .P........P.....
	defb 0b0h,0a0h,081h,050h,000h,030h,0f9h,011h,0b0h,0e0h,000h,030h,0d4h,0f9h,015h,000h	; 591e  ...P.0.....0....
	defb 030h,0feh,00ah,02dh,059h,0d8h,0fah,032h,000h,0c0h,0e1h,0b0h,0c0h,0a0h,050h,080h	; 592e  0..-Y..2......P.
	defb 0a0h,0b0h,0a0h,080h,0fah,023h,0e1h,0a0h,050h,080h,0a0h,0e0h,020h,050h,0d4h,0f9h	; 593e  .....#..P... P..
	defb 014h,050h,080h,0feh,009h,04fh,059h,0d8h,0fah,023h,0e1h,0a0h,0e0h,020h,050h,0e1h	; 594e  .P...OY..#... P.
	defb 080h,0e0h,000h,030h,0e1h,080h,0b0h,0e0h,020h,0d4h,0e1h,0b0h,0e0h,002h,0d8h,0e1h	; 595e  ...0.... .......
	defb 091h,051h,0d4h,0e1h,000h,0e0h,000h,0feh,007h,071h,059h,0e1h,000h,0fah,027h,0e0h	; 596e  .Q.......qY...'.
	defb 002h,0d8h,0fah,023h,000h,0e1h,090h,050h,000h,020h,050h,0d4h,070h,084h,0d8h,0fah	; 597e  ...#...P. P.p...
	defb 015h,0e1h,071h,0d4h,0f8h,025h,0e1h,0c0h,070h,0e0h,000h,0e1h,070h,0e0h,000h,0e1h	; 598e  ..q..%..p...p...
	defb 070h,0d8h,0fah,023h,0e1h,074h,0c1h,081h,0c2h,0f9h,005h,084h,0fah,023h,0e0h,0c1h	; 599e  p..#.t.......#..
	defb 000h,080h,000h,0a0h,000h,0a0h,080h,000h,080h,0a0h,000h,0a0h,080h,050h,020h,000h	; 59ae  .............P .
	defb 050h,0e1h,080h,050h,080h,090h,0e0h,000h,020h,0e1h,090h,0feh,0feh,000h,059h,0efh	; 59be  P..P.... .....Y.
	defb 0d8h,0fbh,025h,0e4h,051h,050h,092h,0a2h,0b2h,0e3h,001h,000h,0e4h,0b2h,0a2h,082h	; 59ce  ..%.QP..........
	defb 0feh,002h,0d2h,059h,0e4h,0a1h,0a0h,0e3h,022h,052h,072h,0fah,025h,082h,072h,052h	; 59de  ...Y...."Rr.%.rR
	defb 022h,0fbh,025h,0e4h,051h,050h,092h,0e3h,002h,022h,032h,022h,002h,0e4h,092h,0e3h	; 59ee  ".%.QP..."2"....
	defb 001h,0c2h,004h,0c1h,0e4h,0a1h,0c2h,0a4h,0c1h,0e4h,051h,050h,092h,0e3h,002h,022h	; 59fe  ..........QP..."
	defb 052h,022h,002h,0e4h,092h,0feh,0feh,0d2h,059h,0efh,0d8h,0e9h,022h,011h,000h,0feh	; 5a0e  R"......Y..."...
	defb 008h,01ah,05ah,022h,011h,000h,0feh,008h,021h,05ah,021h,040h,041h,000h,000h,021h	; 5a1e  ..Z"....!Z!@A..!
	defb 021h,000h,021h,040h,041h,000h,000h,021h,021h,000h,022h,011h,000h,0feh,004h,038h	; 5a2e  !.!@A..!!."....8
	defb 05ah,0feh,0feh,01ah,05ah,0efh,0d9h,0f9h,022h,0e1h,0c1h,0a0h,0c1h,0a0h,091h,0eah	; 5a3e  Z...Z...".......
	defb 002h,0efh,070h,0c1h,070h,091h,0eah,002h,0efh,0a0h,0c1h,0a0h,091h,0eah,002h,0efh	; 5a4e  ..p.p...........
	defb 070h,0e0h,001h,0e1h,000h,0c1h,000h,0c1h,0e9h,040h,040h,040h,040h,0feh,0feh,043h	; 5a5e  p........@@@@..C
	defb 05ah,0efh,0d9h,0e9h,022h,011h,000h,0feh,006h,072h,05ah,021h,0efh,0fbh,032h,0e4h	; 5a6e  Z..."....rZ!..2.
	defb 070h,070h,090h,0b0h,0e3h,001h,000h,0e4h,042h,052h,062h,072h,092h,0a2h,0b2h,0e3h	; 5a7e  pp......BRbr....
	defb 001h,000h,0e4h,042h,052h,062h,071h,000h,070h,090h,0b0h,0feh,0feh,082h,05ah,0efh	; 5a8e  ...BRbq.p.....Z.
	defb 0d9h,0f9h,022h,0e1h,0c1h,070h,0c1h,070h,051h,0fbh,032h,0e3h,001h,0c0h,0f9h,022h	; 5a9e  .."..p.pQ.2...."
	defb 0e1h,040h,0c1h,040h,051h,0fbh,032h,0e4h,001h,0c0h,0f9h,022h,0e1h,070h,0c1h,070h	; 5aae  .@.@Q.2....".p.p
	defb 051h,0fbh,032h,0e3h,001h,0c0h,0f9h,022h,0e1h,040h,041h,0e2h,040h,0c1h,040h,0c5h	; 5abe  Q.2....".@A.@.@.
	defb 0feh,0feh,0a1h,05ah,0efh,0d9h,0f9h,014h,0e2h,051h,071h,091h,0a0h,0a0h,0e1h,030h	; 5ace  ...Z.....Qq....0
	defb 030h,0e2h,050h,050h,0e1h,030h,030h,0e2h,0a0h,0a0h,0e1h,020h,0e2h,0a0h,0e1h,031h	; 5ade  0.PP.00.... ...1
	defb 020h,0c0h,0feh,002h,0dah,05ah,0e2h,0a0h,0a0h,0e1h,030h,030h,0e2h,050h,050h,0e1h	; 5aee   ....Z....00.PP.
	defb 030h,030h,0ffh,0efh,0d9h,0fch,032h,0e4h,051h,071h,091h,0e4h,0a1h,0e3h,021h,0e4h	; 5afe  00....2.Qq....!.
	defb 051h,0e3h,021h,0e4h,0a1h,050h,051h,050h,070h,090h,0feh,002h,009h,05bh,0a1h,0e3h	; 5b0e  Q.!..PQPp....[..
	defb 021h,0e4h,051h,0e3h,021h,0ffh,0efh,0d9h,0f9h,014h,0e2h,021h,011h,001h,0e3h,0a0h	; 5b1e  !.Q.!......!....
	defb 0a0h,0e1h,010h,010h,0e3h,050h,050h,0e1h,010h,010h,0e2h,010h,020h,050h,020h,071h	; 5b2e  .....PP..... P q
	defb 050h,0c0h,0feh,002h,02dh,05bh,0e3h,0a0h,0a0h,0e1h,010h,010h,0e3h,050h,050h,0e1h	; 5b3e  P...-[.......PP.
	defb 010h,010h,0ffh,0efh,0d9h,0f9h,014h,0e2h,0a0h,0a0h,0e1h,020h,0e2h,0a0h,0e1h,031h	; 5b4e  ........... ...1
	defb 020h,0c0h,0d5h,0eah,031h,050h,040h,030h,030h,030h,035h,0ffh,0efh,0d9h,0fch,032h	; 5b5e   ...1P@0005....2
	defb 0e4h,0a1h,050h,051h,050h,070h,0d5h,0eah,051h,080h,070h,060h,060h,060h,065h,0ffh	; 5b6e  ..PQPp..Q.p```e.
	defb 0efh,0d9h,0f9h,014h,0e2h,010h,020h,050h,020h,071h,050h,0c1h,0d5h,0eah,0a0h,0a2h	; 5b7e  ...... P qP.....
	defb 0a0h,0a0h,0a5h,0ffh,0efh,0d8h,0fah,033h,0e2h,0a1h,0e1h,020h,0e2h,0a1h,0e1h,020h	; 5b8e  .......3... ... 
	defb 051h,050h,071h,050h,0e2h,0a1h,0c0h,0e1h,081h,0c0h,085h,0feh,002h,096h,05bh,0ffh	; 5b9e  QPqP..........[.
	defb 0efh,0d8h,0fbh,033h,0e4h,0a1h,0e3h,020h,0e4h,0a1h,0e3h,020h,051h,050h,071h,050h	; 5bae  ...3... ... QPqP
	defb 0e4h,051h,0c0h,0e1h,071h,0c0h,075h,0feh,002h,0b2h,05bh,0ffh,0efh,0d8h,0e9h,061h	; 5bbe  .Q..q.u...[....a
	defb 0eah,020h,0e9h,061h,0eah,020h,051h,050h,071h,050h,0e9h,062h,0eah,082h,0d4h,080h	; 5bce  . .a. QPqP.b....
	defb 080h,080h,080h,087h,0e9h,0a3h,040h,040h,043h,081h,093h,091h,043h,081h,075h,0a5h	; 5bde  ......@@C...C.u.
	defb 0a5h,0ffh,0efh,0d8h,0fbh,032h,0e1h,0c1h,050h,050h,070h,090h,0f9h,024h,021h,020h	; 5bee  .....2..PPp..$! 
	defb 0fbh,032h,0a5h,071h,0f9h,022h,070h,0fbh,032h,0a1h,0f9h,022h,0a0h,0fbh,032h,071h	; 5bfe  .2.q."p.2.."..2q
	defb 0f9h,022h,070h,0fbh,032h,0a1h,0e0h,002h,0f9h,032h,0c0h,0fch,033h,0e2h,0a1h,0f9h	; 5c0e  ."p.2....2..3...
	defb 033h,0a1h,0ffh,0efh,0d8h,0fbh,022h,0e3h,0c1h,050h,050h,070h,090h,0e4h,0a1h,0a0h	; 5c1e  3....."..PPp....
	defb 092h,072h,052h,032h,022h,001h,052h,0c0h,0fch,033h,0e5h,0a1h,0f9h,033h,0e4h,0a1h	; 5c2e  .rR2".R..3...3..
	defb 0ffh,0efh,0d8h,0c1h,0e9h,040h,040h,040h,040h,0efh,0f9h,032h,0e2h,0a1h,0a0h,0fbh	; 5c3e  .....@@@@..2....
	defb 032h,0e1h,055h,021h,0f9h,022h,020h,0fbh,032h,031h,0f9h,022h,030h,0fbh,032h,031h	; 5c4e  2.U!." .21."0.21
	defb 0f9h,022h,030h,0fbh,032h,031h,052h,0d4h,0e9h,060h,0eah,020h,050h,0a7h,0ffh,0efh	; 5c5e  ."0.21R..`. P...
	defb 0d1h,0fch,088h,0e1h,004h,074h,044h,074h,0fch,023h,0e0h,009h,0ffh,0efh,0e8h,0d1h	; 5c6e  .....tDt.#......
	defb 0fch,088h,0e1h,004h,074h,044h,074h,0fch,023h,0e0h,009h,0ffh,0feh,000h,022h,004h	; 5c7e  ....tDt.#.....".
	defb 050h,020h,060h,021h,070h,022h,080h,023h,090h,024h,0a0h,025h,0a0h,026h,0a0h,027h	; 5c8e  P `!p".#.$.%.&.'
	defb 0a0h,028h,0a0h,029h,0a0h,02ah,0a0h,02bh,0a0h,02ch,0a0h,02dh,0a0h,02eh,0a0h,02fh	; 5c9e  .(.).*.+.,.-.../
	defb 022h,002h,0a0h,030h,0a0h,031h,0a0h,032h,0a0h,033h,0a0h,034h,0a0h,035h,0a0h,036h	; 5cae  "..0.1.2.3.4.5.6
	defb 0a0h,037h,0ffh,0feh,000h,022h,005h,060h,01ah,070h,01bh,080h,01ch,090h,01dh,0a0h	; 5cbe  .7...".`.p......
	defb 01eh,0a0h,01fh,0a0h,020h,0a0h,021h,0a0h,022h,0a0h,023h,0a0h,024h,0a0h,025h,0a0h	; 5cce  .... .!.".#.$.%.
	defb 026h,0a0h,027h,0a0h,028h,0a0h,029h,0ffh,0feh,000h,022h,005h,060h,018h,070h,019h	; 5cde  &.'.(.)...".`.p.
	defb 080h,01ah,090h,01bh,0a0h,01ch,0a0h,01dh,0a0h,01eh,0a0h,01fh,0a0h,020h,0a0h,021h	; 5cee  ............. .!
	defb 0a0h,022h,0a0h,023h,0a0h,024h,0a0h,025h,0a0h,026h,0a0h,027h,0ffh,0feh,000h,022h	; 5cfe  .".#.$.%.&.'..."
	defb 002h,0f6h,000h,0f8h,000h,0ffh,0feh,000h,022h,002h,0f3h,000h,0f5h,000h,0e4h,0f0h	; 5d0e  ........".......
	defb 0d4h,0e0h,0d4h,080h,0d4h,000h,0d3h,0a0h,0d3h,050h,0d3h,000h,0d2h,0c0h,0ffh,0efh	; 5d1e  .........P......
	defb 0d5h,0e9h,050h,060h,0eah,050h,050h,054h,057h,0efh,0cah,0ffh,0efh,0d5h,0eah,000h	; 5d2e  ..P`.PPTW.......
	defb 020h,090h,090h,092h,003h,0ffh,0efh,0d5h,0eah,020h,040h,052h,090h,090h,097h,0ffh	; 5d3e   ........ @R....
	defb 0feh,000h,02ah,030h,01ah,000h,090h,01dh,0ffh,0feh,000h,02ah,030h,01ah,000h,090h	; 5d4e  ..*0.......*0...
	defb 030h,0ffh,0feh,000h,02ah,030h,01ah,000h,090h,050h,0ffh,0d5h,0eah,020h,010h,0b0h	; 5d5e  0...*0...P... ..
	defb 000h,0b0h,000h,0b0h,0b5h,0ffh,0efh,0d5h,0f8h,011h,0e0h,020h,050h,0eah,0a0h,0a0h	; 5d6e  ........... P...
	defb 0a0h,0a0h,0a0h,0a5h,0ffh,0d5h,0c0h,0eah,020h,010h,0c0h,0c0h,0c0h,0c0h,0c5h,0ffh	; 5d7e  ........ .......
	defb 0efh,0d4h,0c9h,0ffh,0efh,0d4h,0e9h,0a1h,0a7h,0ffh,0feh,000h,020h,009h,022h,001h	; 5d8e  ............ .".
	defb 090h,080h,091h,000h,080h,080h,081h,000h,080h,080h,071h,000h,070h,080h,071h,000h	; 5d9e  ..........q.p.q.
	defb 060h,080h,061h,000h,060h,080h,051h,000h,050h,080h,051h,000h,040h,080h,041h,000h	; 5dae  `.a.`.Q.P.Q.@.A.
	defb 040h,080h,020h,070h,0ffh,0feh,000h,022h,001h,0d0h,040h,000h,000h,0c0h,040h,020h	; 5dbe  @. p..."..@...@ 
	defb 002h,022h,001h,0a0h,080h,0a0h,040h,090h,080h,090h,040h,090h,080h,080h,040h,080h	; 5dce  ."....@...@...@.
	defb 080h,080h,040h,070h,080h,070h,040h,070h,080h,060h,040h,060h,080h,060h,040h,050h	; 5dde  ..@p.p@p.`@`.`@P
	defb 080h,050h,040h,050h,080h,040h,040h,040h,080h,040h,040h,0ffh,0feh,000h,022h,001h	; 5dee  .P@P.@@@.@@...".
	defb 0c0h,010h,0c0h,020h,0b0h,010h,0b0h,020h,0b0h,010h,0a0h,020h,0a0h,010h,0a0h,020h	; 5dfe  ... ... ... ... 
	defb 090h,010h,090h,020h,090h,010h,080h,020h,080h,010h,080h,020h,070h,010h,070h,020h	; 5e0e  ... ... ... p.p 
	defb 070h,010h,060h,020h,060h,010h,060h,020h,050h,010h,050h,020h,050h,010h,040h,020h	; 5e1e  p.` `.` P.P P.@ 
	defb 040h,010h,040h,020h,0ffh,0efh,0d3h,0c3h,0f7h,000h,0e1h,050h,070h,0feh,009h,039h	; 5e2e  @.@ .......Pp..9
	defb 05eh,0efh,0d3h,0f7h,000h,0e1h,090h,0a0h,0e0h,000h,020h,030h,040h,050h,070h,0feh	; 5e3e  ^......... 0@Pp.
	defb 010h,04bh,05eh,0f9h,012h,0e1h,0c3h,053h,0c3h,0feh,006h,055h,05eh,033h,033h,0c4h	; 5e4e  .K^....S...U^33.
	defb 0ffh,0efh,0d3h,0f9h,012h,0e3h,090h,0a0h,0feh,0feh,075h,05eh,0efh,0d3h,0fah,012h	; 5e5e  ..........u^....
	defb 0c3h,0e3h,05fh,050h,070h,090h,0a0h,0e2h,000h,020h,030h,040h,0e2h,053h,023h,033h	; 5e6e  .._Pp.... 0@.S#3
	defb 003h,023h,0e3h,0a3h,0e2h,003h,0e3h,093h,0e4h,0a3h,0e3h,023h,0e4h,053h,0e3h,023h	; 5e7e  .#.........#.S.#
	defb 0feh,003h,086h,05eh,0e4h,0a3h,053h,0a3h,0ffh,0efh,0d3h,0eah,0a1h,053h,0feh,0feh	; 5e8e  ...^..S......S..
	defb 0aah,05eh,0efh,0d3h,0c3h,0eah,0a3h,053h,0a3h,053h,0a3h,053h,0a3h,053h,0feh,004h	; 5e9e  .^.....S.S.S.S..
	defb 0aah,05eh,0efh,0f8h,012h,0e3h,0a3h,0e1h,033h,0e3h,053h,0e1h,033h,0feh,003h,0b3h	; 5eae  .^......3.S.3...
	defb 05eh,0e0h,0c3h,013h,013h,0ffh,0efh,0d4h,0f9h,012h,0e1h,001h,021h,051h,0feh,0ffh	; 5ebe  ^...........!Q..
	defb 0e6h,05eh,0f9h,012h,051h,0e0h,001h,0e1h,091h,051h,0feh,0ffh,0e6h,05eh,0c1h,0fah	; 5ece  .^..Q....Q...^..
	defb 012h,0e0h,051h,0f8h,012h,051h,0cdh,0ffh,0f9h,011h,020h,080h,020h,080h,020h,080h	; 5ede  ..Q..Q.... . . .
	defb 0f9h,012h,071h,0f8h,012h,070h,0f7h,012h,070h,0f9h,012h,050h,0f8h,012h,050h,0f7h	; 5eee  ..q..p..p..P..P.
	defb 012h,050h,0f6h,012h,050h,0c1h,0ffh,0efh,0d4h,0f9h,012h,0e2h,091h,0a1h,0e1h,001h	; 5efe  .P..P...........
	defb 0feh,0ffh,025h,05fh,0f8h,012h,001h,091h,051h,001h,0feh,0ffh,025h,05fh,0c1h,0f9h	; 5f0e  ..%_....Q...%_..
	defb 012h,0e0h,001h,0f7h,012h,001h,0ffh,0f8h,011h,0e2h,0a0h,0e1h,020h,0e2h,0a0h,0e1h	; 5f1e  ............ ...
	defb 020h,0e2h,0a0h,0e1h,020h,0f9h,012h,041h,0f8h,012h,040h,0f6h,012h,040h,0f9h,012h	; 5f2e   ... ..A..@..@..
	defb 000h,0f7h,012h,000h,0f6h,012h,000h,0f5h,012h,000h,0c1h,0ffh,0d4h,0e9h,041h,041h	; 5f3e  ..............AA
	defb 041h,0efh,0fbh,023h,0e3h,053h,051h,035h,025h,015h,003h,0e4h,071h,063h,053h,0c3h	; 5f4e  A..#.SQ5%...qcS.
	defb 0fch,035h,053h,0ffh,0efh,0d8h,0fah,022h,0e1h,0c1h,060h,070h,0a0h,0d4h,070h,0a0h	; 5f5e  .5S...."..`p..p.
	defb 0feh,006h,06ch,05fh,070h,060h,050h,030h,001h,0d8h,0e0h,000h,030h,000h,060h,050h	; 5f6e  ..l_p`P0....0.`P
	defb 000h,031h,0fbh,036h,051h,060h,0e1h,0a0h,0e0h,000h,0f9h,036h,001h,0fbh,036h,0e1h	; 5f7e  .1.6Q`.....6..6.
	defb 000h,0f9h,036h,001h,0fbh,036h,0e0h,000h,0f9h,036h,001h,0fbh,036h,0e1h,000h,0f9h	; 5f8e  ..6..6...6..6...
	defb 036h,001h,0c1h,0fbh,036h,0e0h,000h,0f9h,036h,001h,0fbh,036h,0e1h,000h,0e0h,000h	; 5f9e  6...6...6..6....
	defb 0f9h,036h,001h,0c5h,0ffh,0efh,0d8h,0fbh,023h,0e3h,0c1h,001h,000h,0e4h,0a2h,092h	; 5fae  .6......#.......
	defb 082h,072h,052h,042h,022h,001h,0c0h,0e3h,001h,0c0h,0e4h,001h,0c0h,0e3h,001h,0c2h	; 5fbe  .rRB"...........
	defb 0e4h,001h,0c0h,000h,0e3h,000h,0f9h,023h,001h,0ffh,0efh,0d4h,0c3h,0e9h,025h,013h	; 5fce  .......#......%.
	defb 001h,0feh,003h,0dch,05fh,023h,040h,040h,045h,0efh,0d8h,0fbh,033h,0e2h,040h,0f9h	; 5fde  ...._#@@E...3.@.
	defb 033h,041h,0fbh,033h,000h,0f9h,033h,001h,0fbh,033h,050h,0f9h,033h,051h,0fbh,033h	; 5fee  3A.3..3..3P.3Q.3
	defb 000h,0f9h,033h,001h,0c1h,0fbh,033h,060h,0f9h,033h,061h,0fah,033h,060h,0fbh,033h	; 5ffe  ..3...3`.3a.3`.3
	defb 070h,0f9h,033h,071h,0ffh,0d8h,0fah,023h,0e2h,050h,0c0h,050h,020h,0c0h,020h,050h	; 600e  p.3q...#.P.P . P
	defb 0c0h,050h,020h,0c0h,020h,051h,0c0h,0a1h,0c0h,0a1h,0c0h,0ffh,0d8h,0fbh,023h,0e4h	; 601e  .P . Q........#.
	defb 0a0h,0c0h,0a0h,0e3h,050h,0c0h,050h,0e4h,0a0h,0c0h,0a0h,0e3h,050h,0c0h,050h,0e4h	; 602e  ....P.P.....P.P.
	defb 0a1h,0c0h,0a1h,0c0h,0a1h,0ffh,0d8h,0fah,023h,0e2h,020h,0c0h,020h,000h,0c0h,000h	; 603e  ........#. . ...
	defb 020h,0c0h,020h,000h,0c0h,000h,021h,0c0h,051h,0c0h,051h,0ffh,0efh,0d6h,0fah,014h	; 604e   . ...!.Q.Q.....
	defb 0e1h,0c2h,070h,0f8h,014h,070h,0fah,014h,0e2h,070h,0e1h,000h,040h,0e2h,070h,0e1h	; 605e  ..p..p...p..@.p.
	defb 000h,040h,0d3h,0f9h,000h,070h,090h,0feh,004h,073h,060h,0d6h,0fah,014h,090h,070h	; 606e  .@...p...s`....p
	defb 050h,040h,060h,0f8h,014h,060h,0fah,014h,0e2h,090h,0e1h,020h,060h,020h,060h,090h	; 607e  P@`..`..... ` `.
	defb 0d3h,0f8h,000h,0e0h,020h,040h,0feh,004h,092h,060h,0d6h,0fah,014h,020h,000h,0e1h	; 608e  .... @...`... ..
	defb 0b0h,090h,0e2h,070h,0c0h,0e1h,070h,070h,070h,0c0h,0e2h,070h,0c0h,070h,0c0h,0e1h	; 609e  ...p..ppp..p.p..
	defb 070h,070h,070h,0c0h,0e2h,070h,0c2h,060h,070h,080h,090h,0a0h,0b0h,0fbh,023h,0e1h	; 60ae  ppp..p.`p.....#.
	defb 000h,0c0h,0e2h,070h,0c0h,0e1h,001h,0f7h,013h,000h,0ffh,0efh,0d6h,0fah,023h,0e2h	; 60be  ...p..........#.
	defb 0c2h,000h,0f8h,023h,000h,0fah,023h,000h,0f8h,023h,000h,0c1h,0fah,023h,040h,0f9h	; 60ce  ...#..#..#...#@.
	defb 013h,040h,0eah,003h,043h,0efh,0fah,023h,020h,0f9h,013h,020h,0feh,002h,0e4h,060h	; 60de  .@..C..# .. ...`
	defb 0fah,023h,090h,0f9h,013h,090h,0fah,025h,090h,0f8h,013h,090h,0eah,063h,093h,0efh	; 60ee  .#.....%.....c..
	defb 0f9h,023h,0e3h,070h,0c0h,0e1h,060h,060h,060h,0c0h,0e3h,070h,0c0h,070h,0c0h,0e1h	; 60fe  .#.p..```..p.p..
	defb 060h,060h,060h,0c0h,0e3h,070h,0c2h,0eah,060h,070h,080h,090h,0a0h,0e9h,030h,0b1h	; 610e  ```..p..`p....0.
	defb 0eah,071h,0e9h,0b5h,0ffh,0efh,0d6h,0fbh,024h,0e3h,0c2h,000h,0c0h,000h,000h,0e4h	; 611e  .q......$.......
	defb 0b0h,0c0h,0b0h,0c0h,091h,0e9h,041h,0efh,071h,0e9h,041h,0efh,0e3h,020h,0c0h,020h	; 612e  ......A.q.A.. . 
	defb 020h,000h,0c0h,000h,0c0h,0e4h,0b1h,0e9h,040h,040h,041h,0efh,0c1h,070h,0c0h,0e3h	; 613e   .......@@A..p..
	defb 070h,070h,070h,0c0h,0e4h,070h,0c0h,070h,0c0h,0e3h,070h,070h,070h,0c0h,0e4h,070h	; 614e  ppp..p.p..ppp..p
	defb 0c2h,0e3h,070h,060h,050h,040h,030h,020h,0fch,033h,000h,0c0h,0e4h,070h,0c0h,0e3h	; 615e  ..p`P@0 .3...p..
	defb 001h,0f8h,033h,000h,0ffh,0efh,0d8h,0fah,012h,0e2h,000h,0e1h,000h,0e2h,000h,030h	; 616e  ..3............0
	defb 0e1h,030h,0e2h,030h,050h,0e1h,050h,0e2h,050h,060h,070h,0a0h,0d4h,0f9h,010h,0e1h	; 617e  .0.0P.P.P`p.....
	defb 000h,030h,000h,030h,000h,030h,000h,030h,000h,0e2h,0a0h,071h,0deh,0eah,008h,0ffh	; 618e  .0.0.0.0...q....
	defb 0efh,0d8h,0fbh,024h,0e3h,001h,000h,0e4h,0a2h,092h,082h,071h,070h,070h,090h,0b0h	; 619e  ...$.......qpp..
	defb 0e3h,001h,0c0h,0dch,0e4h,000h,0ffh,0efh,0d8h,0e9h,022h,011h,000h,022h,010h,0d4h	; 61ae  ..........".."..
	defb 040h,040h,041h,0efh,0d4h,0f7h,000h,0e0h,000h,030h,000h,030h,000h,030h,000h,030h	; 61be  @@A......0.0.0.0
	defb 000h,0e1h,0a0h,071h,0d8h,0e0h,001h,0fah,033h,0c0h,0dch,0e3h,000h,0ffh,0ffh	; 61ce  ...q....3......

; ======================================================================
; CODIGO 0x61dd..0x6283  (166 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MONTA LA FASE: el tablero de 9x9 de la fase (0x97DB + 81 por fase) a 0xEC00, los graficos de los cubos segun la decena, el marco de ladrillo, los 24 objetos en su sitio de salida y el marcador. La fase de bonificacion entra por 0x61E0 con su propio tablero ya puesto.
; ----------------------------------------------------------------------
monta_la_fase:
	call carga_el_tablero		;61dd   ; el tablero de la fase (0xE111) a 0xEC00
monta_la_fase_con_el_tablero_puesto:
	call quita_el_objeto_de_la_vida		;61e0   ; fuera el objeto de la vida extra
	call tiempo_a_99		;61e3   ; el tiempo a 99
	call borra_los_objetos		;61e6   ; los 24 objetos a cero
	call esconde_los_sprites		;61e9   ; sin sprites
	call escribe_la_mascara_del_duenio		;61ec   ; en 0xE4FD, una rutina de tres bytes: `and 0x40 / ret`
	call monta_la_fuente		;61ef   ; la fuente
	call monta_los_graficos_de_la_fase		;61f2   ; los graficos de los cubos, las animaciones y los sprites
	call estilo_de_la_fase		;61f5   ; B: el estilo de cubos, 0 (fases 1-10), 1 (11-20) o 2 (21-50)
	ld hl,000eah		;61f8   ; cada estilo, 26 cubos de 9 casillas: 234 bytes
	call multiplica_hl		;61fb   ; 234 * estilo
	ld de,0a7feh		;61fe   ; desde 0xA7FE...
	add hl,de			;6201   ; + 0xA7FE
	ld de,0eb00h		;6202   ; ...a 0xEB00
	ld bc,000eah		;6205   ; 234 bytes
	ldir		;6208   ; copiados
	call dibuja_el_tablero		;620a   ; el tablero en la copia de la tabla de nombres
	call monta_el_marco		;620d   ; el marco de ladrillo
	call prepara_los_objetos		;6210   ; cada objeto en su sitio de salida, segun la dificultad
	ld a,001h		;6213   ; (0xE328): volcar una vez los sprites de los objetos 19 a 23
	ld (0e328h),a		;6215   ; (0xE328)=1
	call pon_los_sprites		;6218   ; la tabla de sprites
	call vuelca_la_pantalla		;621b   ; la copia de la tabla de nombres a la VRAM
	call monta_los_corazones		;621e   ; los corazones de los tiles 0xFC y 0xFD
	ld a,(0e002h)		;6221   ; el modo
	bit 5,a		;6224   ; el marcador: de uno o del duelo
	jr nz,L_622D		;6226   ; duelo: el suyo
	call pinta_el_marcador		;6228   ; STAGE, SCORE y P-
	jr L_6230		;622b   ; y sigue
L_622D:
	call pinta_el_marcador_del_duelo		;622d   ; 2P- y 1P-
L_6230:
	ld a,(0e002h)		;6230   ; sin bonificacion, el tiempo otra vez a 99
	rrca			;6233   ; bit 0: bonificacion
	jp nc,tiempo_a_99		;6234   ; no: tiempo a 99
	ret			;6237   ; si: su tiempo lo lleva ella
borra_los_objetos:		; 0xE200-0xE500 a cero
	ld hl,0e200h		;6238   ; desde 0xE200...
	ld de,0e201h		;623b   ; ...corriendo el cero...
	ld bc,00300h		;623e   ; ...769 bytes
	ld (hl),000h		;6241   ; el cero
	ldir		;6243   ; corrido
	ret			;6245   ; vuelta
vuelca_la_pantalla:		; La copia de 0xED20 a 0x3820: las filas 1 a 23 de la tabla de nombres
	ld hl,03820h		;6246   ; fila 1 de la tabla de nombres
	ld de,0ed20h		;6249   ; desde la fila 1 de la copia
	ld bc,002e0h		;624c   ; 23 filas
	jp copia_a_vram		;624f   ; LDIRVM
estilo_de_la_fase:		; B = 0, 1 o 2 segun la decena de la fase
	call decena_de_la_fase		;6252   ; B = la decena
	ld a,b			;6255   ; decena 0: estilo 0; 1: estilo 1; el resto, estilo 2
	ld b,000h		;6256   ; estilo 0...
	or a			;6258   ; ...si la decena es 0
	ret z			;6259   ; vuelta
	inc b			;625a   ; estilo 1...
	dec a			;625b   ; ...si es 1
	ret z			;625c   ; vuelta
	inc b			;625d   ; si no, 2
	ret			;625e   ; vuelta
decena_de_la_fase:		; B = la decena de (0xE111) - 1: 0 para las fases 1-10, 4 para las 41-50
	ld a,(0e111h)		;625f   ; la fase
	sub 001h		;6262   ; menos uno, en BCD
	daa			;6264   ; en BCD
	and 0f0h		;6265   ; la cifra alta
	rrca			;6267   ; la cifra alta...
	rrca			;6268
	rrca			;6269
	rrca			;626a
	ld b,a			;626b   ; ...en B
	ret			;626c   ; vuelta
copia_cinco_veces:		; Los 0x48 bytes de DE, cinco veces seguidas desde HL, en los tres tercios
	ld b,005h		;626d   ; cinco copias
L_626F:
	push bc			;626f   ; B...
	ld bc,00048h		;6270   ; nueve tiles
	push hl			;6273   ; ...HL...
	push de			;6274   ; ...y DE a salvo
	call copia_a_los_tres_bancos		;6275   ; los tres tercios
	pop de			;6278   ; DE...
	pop hl			;6279   ; ...HL...
	ld a,048h		;627a   ; el siguiente juego de nueve
	call suma_a_a_hl		;627c   ; nueve tiles mas alla
	pop bc			;627f   ; ...y B otra vez
	djnz L_626F		;6280   ; cinco veces
	ret			;6282   ; vuelta

; ----------------------------------------------------------------------
; DATOS tres_bytes_sueltos: 0x10, 0x20 y 0x50, que no lee nadie: ninguna
;   instruccion los carga y su direccion no aparece en los 32 KB
;   (tools/apunta_a.py)
;   0x6283..0x6286  (3 bytes)
DATA_tres_bytes_sueltos:
	defb 010h,020h,050h	; 6283

; ----------------------------------------------------------------------
; DATOS triangulo: El patron de los 72 tiles 0x40-0x87: un triangulo que llena
;   la esquina de arriba a la izquierda (0xFE, 0xFC... 0x00). Con dos colores
;   distintos, cada tile es una arista del cubo
;   0x6286..0x628e  (8 bytes)
DATA_triangulo:
	defb 0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h	; 6286  ........

; ----------------------------------------------------------------------
; DATOS colores_de_las_aristas: Tres juegos de 72 colores (0x48 bytes), uno
;   por estilo: el color de los tiles 0x40-0x87, tinta arriba a la izquierda y
;   fondo abajo a la derecha. 0x6642 los pone en 0x0200 con un RLE fabricado
;   en 0xE500 (ocho veces cada color)
;   0x628e..0x6366  (216 bytes)
DATA_colores_de_las_aristas:
	defb 007h,076h,060h,007h,076h,060h,007h,076h,060h,007h,076h,060h,007h,077h,070h,007h,077h,070h,006h,067h,070h,006h,067h,070h	; 628e  .v`.v`.v`.v`.wp.wp.gp.gp
	defb 006h,067h,070h,006h,067h,070h,007h,077h,070h,007h,077h,070h,007h,076h,060h,007h,076h,060h,007h,076h,060h,007h,076h,060h	; 62a6  .gp.gp.wp.wp.v`.v`.v`.v`
	defb 007h,077h,070h,007h,077h,070h,006h,067h,070h,006h,067h,070h,006h,067h,070h,006h,067h,070h,007h,077h,070h,007h,077h,070h	; 62be  .wp.wp.gp.gp.gp.gp.wp.wp
	defb 006h,067h,070h,004h,047h,070h,006h,067h,070h,004h,047h,070h,006h,064h,040h,004h,046h,060h,007h,076h,060h,007h,074h,040h	; 62d6  .gp.Gp.gp.Gp.d@.F`.v`.t@
	defb 007h,076h,060h,007h,074h,040h,004h,046h,060h,006h,064h,040h,006h,067h,070h,004h,047h,070h,006h,067h,070h,004h,047h,070h	; 62ee  .v`.t@.F`.d@.gp.Gp.gp.Gp
	defb 006h,064h,040h,004h,046h,060h,007h,076h,060h,007h,074h,040h,007h,076h,060h,007h,074h,040h,004h,046h,060h,006h,064h,040h	; 6306  .d@.F`.v`.t@.v`.t@.F`.d@
	defb 006h,06ch,0c0h,007h,07ch,0c0h,009h,09ch,0c0h,004h,04ch,0c0h,006h,064h,040h,004h,046h,060h,00ah,0a6h,060h,00ah,0a7h,070h	; 631e  .l..|.....L..d@.F`..`..p
	defb 00ah,0a9h,090h,00ah,0a4h,040h,007h,076h,060h,009h,094h,040h,009h,09ah,0a0h,004h,04ah,0a0h,006h,06ah,0a0h,007h,07ah,0a0h	; 6336  .....@.v`..@....J..j..z.
	defb 009h,097h,070h,007h,079h,090h,00ch,0c9h,090h,00ch,0c4h,040h,00ch,0c6h,060h,00ch,0c7h,070h,004h,049h,090h,006h,067h,070h	; 634e  ..p.y......@..`..p.I..gp

; ======================================================================
; CODIGO 0x6366..0x64db  (373 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; DIBUJA EL TABLERO en la copia de la tabla de nombres: nueve filas de nueve cubos desde la fila 3, columna 3, cada cubo de 3x3 casillas, de 3 en 3 columnas y de 2 en 2 filas. La casilla 0 es el cubo MODELO, el que hay que conseguir, y se pinta tal cual; en el duelo, tambien la 1, la del segundo.
; ----------------------------------------------------------------------
dibuja_el_tablero:
	call borra_la_copia_de_nombres		;6366   ; la copia, a cero
	ld hl,0ed63h		;6369   ; fila 3, columna 3
	ld de,0ec00h		;636c   ; desde la casilla 0
	ld a,001h		;636f   ; (0xE32D) a uno: la primera casilla es el modelo
	ld (0e32dh),a		;6371   ; guardado
	ld c,009h		;6374   ; nueve filas...
L_6376:
	ld b,009h		;6376   ; ...de nueve casillas
L_6378:
	ld a,(de)			;6378   ; la casilla
	call dibuja_un_cubo		;6379   ; su cubo
	inc de			;637c   ; la siguiente
	ld a,003h		;637d   ; tres columnas por cubo
	call suma_a_a_hl		;637f   ; tres columnas mas alla
	ld a,b			;6382   ; de la segunda casilla en adelante, ya no son modelo
	sub 008h		;6383   ; tras la segunda casilla...
	jr nz,L_638A		;6385   ; ...(no antes)...
	ld (0e32dh),a		;6387   ; ...(0xE32D) a cero
L_638A:
	djnz L_6378		;638a   ; nueve casillas
	ld a,025h		;638c   ; 27 + 37 = 64: dos filas mas abajo
	call suma_a_a_hl		;638e   ; dos filas mas abajo, a la columna 3
	dec c			;6391   ; una fila menos
	jr nz,L_6376		;6392   ; nueve
	ld a,(0e002h)		;6394   ; en el duelo...
	bit 5,a		;6397   ; el duelo?
	ret z			;6399   ; no: ya esta
	ld hl,0ed44h		;639a   ; ...1P y 2P encima de los dos modelos
	ld (hl),011h		;639d   ; "1"...
	inc hl			;639f
	ld (hl),030h		;63a0   ; ..."P"...
	inc hl			;63a2
	inc hl			;63a3
	ld (hl),012h		;63a4   ; "2"...
	inc hl			;63a6
	ld (hl),030h		;63a7   ; ..."P"
	ret			;63a9   ; vuelta
dibuja_un_cubo:		; El cubo A en HL; si ya coincide con el modelo, se marca y se pinta el cubo acabado
	cp 0ffh		;63aa   ; 0xFF: no hay cubo
	ret z			;63ac   ; hueco: nada
	and 01fh		;63ad   ; los cinco bits bajos: cual de los 24
	push hl			;63af   ; todo...
	push de			;63b0   ; ...a...
	push bc			;63b1   ; ...salvo
	ld b,a			;63b2   ; B = el cubo
	ld a,(0e32dh)		;63b3   ; el modelo, tal cual
	or a			;63b6   ; es un modelo?
	ld a,b			;63b7   ; el cubo
	jr nz,pinta_el_cubo_a		;63b8   ; si: tal cual
	xor a			;63ba   ; contra el modelo del primero
	ld (0e339h),a		;63bb   ; (0xE339)=0: el modelo del primero
	ld a,b			;63be   ; el cubo
	call coincide_con_el_modelo		;63bf   ; igual?
	jr nz,L_63CC		;63c2   ; no: el del segundo
	ld a,b			;63c4   ; coincide: bit 6 (es del primero)...
	or 040h		;63c5   ; la marca del primero
	ld (de),a			;63c7   ; en la casilla
	ld b,018h		;63c8   ; ...y se pinta el cubo 24, el acabado del primero
	jr L_63DD		;63ca   ; a pintarlo
L_63CC:
	ld a,001h		;63cc   ; contra el del segundo
	ld (0e339h),a		;63ce   ; (0xE339)=1: el del segundo
	ld a,b			;63d1   ; el cubo
	call coincide_con_el_modelo		;63d2   ; igual?
	jr nz,L_63DD		;63d5   ; no: tal cual
	ld a,b			;63d7   ; bit 5 y el cubo 25, el acabado del segundo
	or 020h		;63d8   ; la marca del segundo
	ld (de),a			;63da   ; en la casilla
	ld b,019h		;63db   ; el cubo 25
L_63DD:
	ld a,b			;63dd   ; el cubo que se pinta
pinta_el_cubo_a:
	ld b,009h		;63de   ; nueve casillas por cubo en 0xEB00
	call multiplica		;63e0   ; * 9
	ld de,0eb00h		;63e3   ; en la tabla de cubos de la fase
	call suma_a_a_de		;63e6   ; DE = sus nueve casillas
	ld c,003h		;63e9   ; tres filas de tres
L_63EB:
	ld b,003h		;63eb   ; tres
L_63ED:
	ld a,(de)			;63ed   ; la casilla...
	ld (hl),a			;63ee   ; ...a la copia
	inc de			;63ef   ; la siguiente
	inc hl			;63f0   ; al lado
	djnz L_63ED		;63f1   ; tres
	ld a,01dh		;63f3   ; 32 - 3: la fila siguiente
	call suma_a_a_hl		;63f5   ; la fila siguiente
	dec c			;63f8   ; una fila menos
	jr nz,L_63EB		;63f9   ; tres
	pop bc			;63fb   ; todo...
	pop de			;63fc   ; ...de...
	pop hl			;63fd   ; ...vuelta
	ret			;63fe   ; vuelta
borra_la_copia_de_nombres:		; 0xED00-0xEFFF a cero
	ld hl,0ed00h		;63ff   ; desde 0xED00...
	ld de,0ed01h		;6402   ; ...corriendo el cero...
	ld bc,002ffh		;6405   ; ...768 bytes
	ld (hl),000h		;6408   ; el cero
	ldir		;640a   ; corrido
	ret			;640c   ; vuelta
fase_menos_una_hasta_9:		; min((0xE111) - 1, 9) en BCD
	ld a,(0e111h)		;640d   ; CODIGO HUERFANO: nadie lo llama ni apunta aqui
	sub 001h		;6410   ; menos uno...
	daa			;6412   ; ...en BCD
	cp 00ah		;6413   ; por debajo de 10...
	ret c			;6415   ; ...tal cual
	ld a,009h		;6416   ; si no, 9
	ret			;6418   ; vuelta
fase_en_binario:		; (0xE111) - 1 en binario: el numero de la fase desde cero
	ld a,(0e111h)		;6419   ; la fase, en BCD
	ld c,000h		;641c   ; la cuenta
L_641E:
	inc c			;641e   ; cuenta hacia abajo en BCD
	sub 001h		;641f   ; menos uno...
	daa			;6421   ; ...en BCD...
	jr nz,L_641E		;6422   ; ...hasta cero
	dec c			;6424   ; menos uno
	ld a,c			;6425   ; en A
	ret			;6426   ; vuelta
bcd_de_a:		; A en binario a BCD
	or a			;6427   ; cero...
	ret z			;6428   ; ...es cero
	ld c,a			;6429   ; la cuenta
	xor a			;642a   ; desde cero
L_642B:
	add a,001h		;642b   ; uno mas...
	daa			;642d   ; ...en BCD
	dec c			;642e   ; A veces
	jr nz,L_642B		;642f
	ret			;6431   ; vuelta
multiplica:		; A = A * B (con B=0, cero)
	ld c,a			;6432   ; C = A
	ld a,b			;6433   ; B...
	or a			;6434   ; ...cero?
	ret z			;6435   ; si: cero
	xor a			;6436   ; desde cero
L_6437:
	add a,c			;6437   ; + C
	djnz L_6437		;6438   ; B veces
	ret			;643a   ; vuelta
multiplica_hl:		; HL = HL * B
	ld a,b			;643b   ; B...
	or a			;643c   ; ...cero?
	jr nz,L_6443		;643d   ; no: a multiplicar
	ld hl,00000h		;643f   ; si: cero
	ret			;6442   ; vuelta
L_6443:
	ld d,h			;6443   ; DE = HL
	ld e,l			;6444
	ld hl,00000h		;6445   ; desde cero
L_6448:
	add hl,de			;6448   ; + DE
	djnz L_6448		;6449   ; B veces
	ret			;644b   ; vuelta
divide:		; A / B: el cociente en A y el resto en B
	ld c,0ffh		;644c   ; el cociente, desde -1
L_644E:
	inc c			;644e   ; uno mas
	sub b			;644f   ; menos B
	jr nc,L_644E		;6450   ; mientras quepa
	add a,b			;6452   ; lo que sobra
	ld b,a			;6453   ; en B
	ld a,c			;6454   ; el cociente en A
	ret			;6455   ; vuelta

; ----------------------------------------------------------------------
; LOS OBJETOS EN SU SITIO DE SALIDA. Cinco tablas de 24 bytes, uno por objeto: el primer byte de cada uno sale de una de las siete filas de 0x64DB segun la dificultad (la decena de la fase; en el duelo, 5 o 6 segun el nivel), y la Y, la X, el patron y el color de 0x6583, 0x659B, 0x65B3 y 0x65CB. Luego Q*bert baja hasta el primer cubo de su columna.
; ----------------------------------------------------------------------
prepara_los_objetos:
	call decena_de_la_fase		;6456   ; la decena de la fase
	ld a,(0e002h)		;6459   ; el modo
	bit 5,a		;645c   ; el duelo?
	jr z,L_6467		;645e   ; no: la decena
	ld a,(0e103h)		;6460   ; en el duelo, 5 mas el nivel
	ld b,005h		;6463   ; 5...
	add a,b			;6465   ; ...mas el nivel...
	ld b,a			;6466   ; ...en B
L_6467:
	ld a,018h		;6467   ; 24 bytes por fila
	call multiplica		;6469   ; 24 * B
	ld hl,064dbh		;646c   ; la fila de esperas
	call suma_a_a_hl		;646f   ; de esa dificultad
	ld de,0e200h		;6472   ; al byte 0 de cada objeto
	call copia_un_byte_de_cada_objeto		;6475   ; byte 0: la espera de cada bicho
	ld hl,06583h		;6478   ; la Y...
	ld de,0e204h		;647b   ; ...al byte 4
	call copia_un_byte_de_cada_objeto		;647e   ; byte 4: la Y
	ld hl,0659bh		;6481   ; la X...
	ld de,0e205h		;6484   ; ...al byte 5
	call copia_un_byte_de_cada_objeto		;6487   ; byte 5: la X
	ld hl,065b3h		;648a   ; el patron...
	ld de,0e206h		;648d   ; ...al byte 6
	call copia_un_byte_de_cada_objeto		;6490   ; byte 6: el patron
	ld hl,065cbh		;6493   ; el color...
	ld de,0e207h		;6496   ; ...al byte 7
	call copia_un_byte_de_cada_objeto		;6499   ; byte 7: el color
	ld de,(0e204h)		;649c   ; Q*bert, hasta el primer cubo de su columna...
	call baja_hasta_un_cubo		;64a0   ; hasta que haya cubo debajo
	ld (0e204h),de		;64a3   ; la Y y la X del primero
	ld (0e20ch),de		;64a7   ; ...y su segundo sprite en el mismo sitio
	ld a,(0e002h)		;64ab   ; el modo
	bit 5,a		;64ae   ; el duelo?
	ret z			;64b0   ; no: ya esta
	ld de,(0e214h)		;64b1   ; el segundo Q*bert empieza en Y=0x0C
	ld e,00ch		;64b5   ; Y = 0x0C
	call baja_hasta_un_cubo		;64b7   ; hasta un cubo
	ld (0e214h),de		;64ba   ; el segundo...
	ld (0e21ch),de		;64be   ; ...y su otro sprite
	ret			;64c2   ; vuelta
baja_hasta_un_cubo:		; Baja E de 16 en 16 hasta que (E,D) cae en una casilla con cubo
	call casilla_debajo		;64c3   ; el cubo en (E,D)
	inc a			;64c6   ; 0xFF + 1 = 0...
	ret nz			;64c7   ; ...si no, hay cubo
	ld a,e			;64c8   ; la Y...
	add a,010h		;64c9   ; ...una fila mas abajo
	ld e,a			;64cb   ; guardada
	jr baja_hasta_un_cubo		;64cc   ; y otra vez
copia_un_byte_de_cada_objeto:		; 24 bytes de HL a DE, DE de 8 en 8
	ld b,018h		;64ce   ; 24 objetos
L_64D0:
	ld a,(hl)			;64d0   ; el byte...
	ld (de),a			;64d1   ; ...al objeto
	inc hl			;64d2   ; el siguiente de la tabla
	ld a,008h		;64d3   ; el objeto siguiente...
	call suma_a_a_de		;64d5   ; ...8 bytes mas alla
	djnz L_64D0		;64d8   ; 24
	ret			;64da   ; vuelta

; ----------------------------------------------------------------------
; DATOS esperas_de_los_objetos: Siete filas de 24 bytes (las dificultades 0-4
;   de un jugador y los dos niveles del duelo), un byte por objeto: 0x00, el
;   objeto no sale; 0xFn, sale tras n cuentas de 64 cuadros (0x7444). Los
;   cuatro primeros son los dos Q*bert
;   0x64db..0x6583  (168 bytes)
DATA_esperas_de_los_objetos:
	defb 000h,000h,000h,000h,000h,0f3h,005h,0fdh,0f7h,000h,0ffh,000h,0feh,0f8h,000h,000h,000h,000h,0fah,000h,000h,000h,000h,000h	; 64db  ........................
	defb 000h,000h,000h,000h,0f2h,0f4h,0f5h,0ffh,0f7h,000h,0fch,0feh,0f1h,0f3h,0f6h,000h,000h,000h,0fah,000h,000h,000h,000h,000h	; 64f3  ........................
	defb 000h,000h,000h,000h,0f2h,0f4h,0f6h,0f8h,0fch,000h,0fdh,0fbh,0f1h,0f3h,0f5h,0f7h,0f9h,0feh,0fah,000h,000h,000h,000h,000h	; 650b  ........................
	defb 000h,000h,000h,000h,0fbh,0ffh,0f8h,0f6h,0f4h,0f2h,0fch,0f9h,0f1h,0f3h,0f5h,0f7h,000h,000h,0fah,000h,000h,000h,000h,000h	; 6523  ........................
	defb 000h,000h,000h,000h,0f3h,0f4h,0f6h,0f2h,0f8h,0fdh,0ffh,0f9h,0f1h,0feh,0f5h,0f7h,000h,000h,0fah,000h,000h,000h,000h,000h	; 653b  ........................
	defb 000h,000h,000h,000h,000h,000h,0f5h,0f9h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 6553  ........................
	defb 000h,000h,000h,000h,000h,0f9h,0f5h,0fbh,0f7h,0f3h,000h,000h,0fdh,0f2h,0f4h,0f6h,0f8h,0feh,000h,000h,000h,000h,000h,000h	; 656b  ........................

; ----------------------------------------------------------------------
; DATOS y_de_salida: La Y de cada objeto: los dos Q*bert arriba (0x0C) y el
;   resto fuera de la pantalla (0xE0)
;   0x6583..0x659b  (24 bytes)
DATA_y_de_salida:
	defb 00ch,00ch,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; 6583  ........................

; ----------------------------------------------------------------------
; DATOS x_de_salida: La X: 0x7C el primero y 0xAC el segundo
;   0x659b..0x65b3  (24 bytes)
DATA_x_de_salida:
	defb 07ch,07ch,0ach,0ach,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 659b  ||......................

; ----------------------------------------------------------------------
; DATOS patrones_de_salida: El patron de cada sprite (el numero de su primer
;   8x8): 0x00 y 0x10 Q*bert, 0xB0 y 0xC0 el segundo, y los bichos 0x30, 0x50,
;   0x70, 0x80, 0x90 y 0xA0
;   0x65b3..0x65cb  (24 bytes)
DATA_patrones_de_salida:
	defb 000h,010h,0b0h,0c0h,030h,030h,030h,050h,030h,070h,080h,090h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,030h,0a0h,0a0h,0a0h,0a0h,0a0h	; 65b3  ....000P0p........0.....

; ----------------------------------------------------------------------
; DATOS colores_de_salida: El color de cada sprite: es lo que distingue a los
;   que comparten dibujo (los 0x30 y los 0xA0)
;   0x65cb..0x65e3  (24 bytes)
DATA_colores_de_salida:
	defb 00ah,00dh,00ah,005h,00eh,003h,00bh,003h,008h,003h,00ah,00eh,007h,006h,004h,009h,00ah,00ch,005h,000h,000h,000h,000h,000h	; 65cb  ........................

; ======================================================================
; CODIGO 0x65e3..0x6ade  (1275 bytes)
; ======================================================================


empieza_en_el_nivel_elegido:		; La fase 01, 11, 21, 31 o 41 segun (0xE103), y en el duelo 3 o 5 partidas
	call borra_los_marcadores_del_duelo		;65e3   ; ninguna partida ganada
	ld a,(0e103h)		;65e6   ; el nivel por 16: la decena en BCD
	ld b,a			;65e9   ; B = nivel
	ld a,010h		;65ea   ; 16...
	call multiplica		;65ec   ; ...por el nivel
	inc a			;65ef   ; mas uno
	ld (0e111h),a		;65f0   ; la fase: 01, 11, 21, 31 o 41
	ld a,(0e104h)		;65f3   ; (0xE104): partida a 3 o a 5
	or a			;65f6   ; 0: tres partidas
	ld a,003h		;65f7
	jr z,L_65FD		;65f9   ; ...tres
	ld a,005h		;65fb   ; cinco
L_65FD:
	ld (0ecb8h),a		;65fd   ; las partidas que quedan
carga_el_tablero_siguiente:
	ld a,(0e002h)		;6600   ; en el duelo, una fase al azar
	bit 5,a		;6603   ; el duelo?
	jr z,carga_el_tablero		;6605   ; no: la fase que toca
	ld a,r		;6607   ; R entre 6, mas 31: de la 31 a la 50
	ld b,006h		;6609   ; entre 6
	call divide		;660b   ; el cociente: 0 a 21
	add a,01fh		;660e   ; + 31
	cp 032h		;6610   ; como mucho...
	jr c,L_6616		;6612   ; ...la 50
	ld a,032h		;6614   ; la 50
L_6616:
	call bcd_de_a		;6616   ; en BCD
	ld (0e111h),a		;6619   ; la fase
carga_el_tablero:
	call tablero_de_la_fase		;661c   ; HL y BC
	ld de,0ec00h		;661f   ; los 81 bytes a 0xEC00
	ldir		;6622   ; a 0xEC00
	ld a,(0e002h)		;6624   ; el modo
	bit 5,a		;6627   ; el duelo...
	ret nz			;6629   ; ...deja el segundo modelo
	ld a,0ffh		;662a   ; con un jugador no hay segundo modelo
	ld (0ec01h),a		;662c   ; la casilla 1, hueco
	ret			;662f   ; vuelta
tablero_de_la_fase:		; HL = 0x97DB + 81 * (fase - 1), BC = 81
	call fase_en_binario		;6630   ; la fase, desde cero
	ld b,a			;6633   ; B
	ld hl,00051h		;6634   ; 81...
	call multiplica_hl		;6637   ; ...por la fase
	ld de,097dbh		;663a   ; + 0x97DB
	add hl,de			;663d   ; HL = su tablero
	ld bc,00051h		;663e   ; 81 bytes
	ret			;6641   ; vuelta

; ----------------------------------------------------------------------
; LOS GRAFICOS DE LA FASE: los 72 tiles de arista con los colores del estilo, los tiles de las diez animaciones de cubo que giran, las caras, y los patrones de sprite de Q*bert y de los bichos.
; ----------------------------------------------------------------------
monta_los_graficos_de_la_fase:
	ld hl,02200h		;6642   ; tile 0x40
	ld de,06286h		;6645   ; el triangulo
	ld b,048h		;6648   ; 72 veces el triangulo
L_664A:
	push bc			;664a   ; B...
	push hl			;664b   ; ...HL...
	push de			;664c   ; ...y DE a salvo
	ld bc,00008h		;664d   ; ocho bytes
	call copia_a_los_tres_bancos		;6650   ; en los tres tercios
	pop de			;6653   ; DE...
	pop hl			;6654   ; ...HL...
	pop bc			;6655   ; ...y B
	ld a,008h		;6656   ; el tile siguiente
	call suma_a_a_hl		;6658
	djnz L_664A		;665b   ; 72 tiles
	call estilo_de_la_fase		;665d   ; los colores del estilo
	ld hl,00048h		;6660   ; 72 bytes...
	call multiplica_hl		;6663   ; ...por el estilo
	ld de,0628eh		;6666   ; + 0x628E
	add hl,de			;6669   ; HL = los colores del estilo
	ld de,0e500h		;666a   ; el RLE, en 0xE500
	ld b,048h		;666d   ; un RLE hecho a mano en 0xE500: 8 veces cada color
L_666F:
	ld a,008h		;666f   ; 8...
	ld (de),a			;6671   ; ...veces...
	inc de			;6672
	ld a,(hl)			;6673   ; ...el color
	ld (de),a			;6674   ; guardado
	inc hl			;6675   ; el siguiente
	inc de			;6676
	djnz L_666F		;6677   ; 72 colores
	ld a,000h		;6679   ; y su 0x00 de fin
	ld (de),a			;667b   ; el 0x00 de fin
	ld de,0e500h		;667c   ; a 0x0200: el color del tile 0x40
	ld hl,00200h		;667f   ; color del tile 0x40
	call guion_rle_en_tres_bancos		;6682   ; en los tres tercios
	ld hl,02488h		;6685   ; tile 0x91: cinco juegos de nueve para los cubos que giran
	ld de,0b004h		;6688   ; los del hueco 0 a 4
	call copia_cinco_veces		;668b   ; cinco veces
	ld hl,025f0h		;668e   ; tile 0xBE: otros cinco
	ld de,0afbch		;6691   ; los del hueco 5 a 9
	call copia_cinco_veces		;6694   ; cinco veces
	ld hl,02440h		;6697   ; tile 0x88: el cubo acabado del primero
	ld de,0b04ch		;669a   ; el cubo acabado...
	ld bc,00048h		;669d   ; ...nueve tiles
	call copia_a_los_tres_bancos		;66a0   ; en los tres tercios
	ld hl,02708h		;66a3   ; tile 0xE1: el del segundo
	ld de,0b04ch		;66a6   ; el mismo dibujo...
	ld bc,00048h		;66a9   ; ...nueve tiles
	call copia_a_los_tres_bancos		;66ac   ; en los tres tercios
	ld hl,00440h		;66af   ; y sus colores
	ld de,0b094h		;66b2   ; su color, el del primero
	call guion_rle_en_tres_bancos		;66b5   ; en los tres tercios
	ld hl,00708h		;66b8   ; el del tile 0xE1
	ld de,0b097h		;66bb   ; el del segundo
	call guion_rle_en_tres_bancos		;66be   ; en los tres tercios
	ld hl,01800h		;66c1   ; los patrones de sprite de Q*bert (0x00-0x1F)...
	ld de,0acbch		;66c4   ; Q*bert a la izquierda
	ld bc,00100h		;66c7   ; 256 bytes
	call copia_a_vram		;66ca   ; LDIRVM
	ld hl,01d80h		;66cd   ; ...y los mismos para el segundo (0xB0-0xCF)
	ld de,0acbch		;66d0   ; el mismo para el segundo
	ld bc,00100h		;66d3   ; 256 bytes
	call copia_a_vram		;66d6   ; LDIRVM
	ld hl,01980h		;66d9   ; y los bichos
	ld de,0aabch		;66dc   ; las bolas, al patron 0x30
	ld bc,00040h		;66df   ; 64 bytes
	call copia_a_vram		;66e2   ; LDIRVM
	ld hl,01a80h		;66e5   ; patron 0x50
	ld de,0aafch		;66e8   ; la tortuga
	ld bc,00040h		;66eb   ; 64 bytes
	call copia_a_vram		;66ee   ; LDIRVM
	ld hl,01c80h		;66f1   ; patron 0x90
	ld de,0ab3ch		;66f4   ; el encapuchado
	ld bc,00040h		;66f7   ; 64 bytes
	call copia_a_vram		;66fa   ; LDIRVM
	ld hl,01cc0h		;66fd   ; patron 0x98
	ld de,0ab3ch		;6700   ; el mismo otra vez
	ld bc,00040h		;6703   ; 64 bytes
	call copia_a_vram		;6706   ; LDIRVM
	ld hl,01b80h		;6709   ; patron 0x70
	ld de,0ab7ch		;670c   ; el que gira cubos
	ld bc,00040h		;670f   ; 64 bytes
	call copia_a_vram		;6712   ; LDIRVM
	ld hl,01e80h		;6715   ; patron 0xD0
	ld de,0abbch		;6718   ; el objeto de la vida
	ld bc,00040h		;671b   ; 64 bytes
	call copia_a_vram		;671e   ; LDIRVM
	ld hl,01d00h		;6721   ; patron 0xA0
	ld de,0abfch		;6724   ; los seis de colores
	ld bc,00040h		;6727   ; 64 bytes
	call copia_a_vram		;672a   ; LDIRVM
	ld hl,01e80h		;672d   ; patron 0xD0 otra vez
	ld de,0abbch		;6730   ; el objeto de la vida
	ld bc,00040h		;6733   ; 64 bytes
	call copia_a_vram		;6736   ; LDIRVM
pon_el_paso_a_del_bicho_80:		; Patrones 0x80-0x87 desde 0xAC3C
	exx			;6739   ; los registros a salvo
	ld hl,01c00h		;673a   ; patron 0x80
	ld de,0ac3ch		;673d   ; el moai, paso A
	ld bc,00040h		;6740   ; 64 bytes
	call copia_a_vram		;6743   ; LDIRVM
	exx			;6746   ; los registros de vuelta
	ret			;6747   ; vuelta
pon_el_paso_b_del_bicho_80:		; Patrones 0x80-0x87 desde 0xAC7C: el otro paso de la animacion
	exx			;6748   ; los registros a salvo
	ld hl,01c00h		;6749   ; patron 0x80
	ld de,0ac7ch		;674c   ; el moai, paso B
	ld bc,00040h		;674f   ; 64 bytes
	call copia_a_vram		;6752   ; LDIRVM
	exx			;6755   ; los registros de vuelta
	ret			;6756   ; vuelta
rellena_la_tabla_de_nombres:		; Pone en cada casilla de la tabla de nombres el byte bajo de su direccion: 0, 1, 2... Un visor de patrones de desarrollo
	ld hl,03800h		;6757   ; CODIGO HUERFANO: ni el trazado ni ninguna palabra de los 32 KB llegan aqui
	ld bc,00300h		;675a   ; 768 casillas
L_675D:
	ld a,l			;675d   ; el byte bajo de la direccion
	call 0004dh		;675e   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM, casilla a casilla
	inc hl			;6761   ; la siguiente
	dec bc			;6762   ; una menos
	ld a,b			;6763   ; hasta...
	or c			;6764   ; ...cero
	jr nz,L_675D		;6765   ; 768
	ret			;6767   ; vuelta
escribe_la_mascara_del_duenio:		; Escribe en 0xE4FD `and 0x40 / ret`: 0x7341 cambia el 0x40 por 0x20 segun de quien se cuenten los cubos
	ld hl,0e4fdh		;6768   ; en 0xE4FD...
	ld (hl),0e6h		;676b   ; ...`and n`...
	inc hl			;676d
	ld (hl),040h		;676e   ; ...n = 0x40...
	inc hl			;6770
	ld (hl),0c9h		;6771   ; ...`ret`
	ret			;6773   ; vuelta
borra_los_marcadores_del_duelo:		; 0xE600-0xE610 a cero
	ld hl,0e600h		;6774   ; desde 0xE600...
	ld de,0e601h		;6777   ; ...corriendo el cero...
	ld bc,00010h		;677a   ; ...17 bytes
	ld (hl),000h		;677d   ; el cero
	ldir		;677f   ; corrido
	ret			;6781   ; vuelta

; ----------------------------------------------------------------------
; EL PASO DE LA PARTIDA, segun (0xE001). El paso 0 es el cuadro de juego normal (0x68E6). Del 1 al 4, la fase acabada: Q*bert salta de alegria, el marco cambia de color y el tiempo que sobra se cobra. Del 5 al 8, el piedra-papel-tijera del duelo. La pausa (F1) y la fase de bonificacion se miran antes.
; ----------------------------------------------------------------------
paso_de_la_partida:
	call mira_la_pausa		;6782   ; F1: pausa
	ld a,(0e327h)		;6785   ; en pausa, solo parpadea -PAUSE-
	or a			;6788   ; en pausa?
	jp nz,parpadea_la_pausa		;6789   ; si: el rotulo
	ld a,(0e002h)		;678c   ; la fase de bonificacion va por su cuenta
	bit 0,a		;678f   ; bit 0: la bonificacion
	jp nz,paso_de_la_bonificacion		;6791   ; va aparte
	djnz L_680C		;6794   ; paso 1: fase acabada
espera_la_musica_de_la_vida:
	ld a,(0e072h)		;6796   ; si suena la de la vida extra (0x11), se espera a que acabe
	cp 011h		;6799   ; el efecto 0x11...
	jr z,espera_la_musica_de_la_vida		;679b   ; ...aun suena
	ld a,047h		;679d   ; la musica de la fase acabada, 0x47
	call toca_sonido_en_partida		;679f   ; la musica 0x47
	call esconde_los_bichos		;67a2   ; fuera los bichos
	ld a,00dh		;67a5   ; Q*bert en magenta
	ld (0e20fh),a		;67a7   ; el color del segundo sprite
	ld a,(0e33ah)		;67aa   ; (0xE33A): cual de los dos acaba (el duelo)
	or a			;67ad   ; el segundo?
	ld hl,0e200h		;67ae   ; el primero
	jr z,L_67B6		;67b1
	ld hl,0e210h		;67b3   ; el segundo
L_67B6:
	ld (0e33bh),hl		;67b6   ; su objeto, en (0xE33B)
	ld hl,0e32ah		;67b9   ; diez cuadros por salto, seis saltos
	ld (hl),00ah		;67bc   ; diez cuadros por salto
	inc hl			;67be
	ld (hl),000h		;67bf   ; hacia arriba
	inc hl			;67c1
	ld (hl),006h		;67c2   ; seis saltos
	ld a,(0e33ah)		;67c4   ; el dibujo de la fase acabada en los patrones de ese Q*bert (0x00-0x1F o 0xB0-0xCF)
	or a			;67c7   ; el segundo?
	ld hl,01800h		;67c8   ; los patrones del primero
	jr z,L_67D0		;67cb
	ld hl,01d80h		;67cd   ; los del segundo
L_67D0:
	push hl			;67d0   ; a salvo
	ld de,0aebch		;67d1   ; los 0x80 bytes de 0xAEBC
	ld bc,00080h		;67d4   ; cuatro sprites
	call copia_a_vram		;67d7   ; LDIRVM
	pop hl			;67da   ; HL otra vez
	ld de,00080h		;67db   ; 0x80 mas alla
	add hl,de			;67de
	ld de,0aefch		;67df   ; los 0x80 de 0xAEFC
	ld bc,00080h		;67e2   ; cuatro sprites
	call copia_a_vram		;67e5   ; LDIRVM
	ld hl,(0e33bh)		;67e8   ; el segundo sprite, en la X del primero
	ld a,006h		;67eb   ; byte 6, el patron...
	call suma_a_a_hl		;67ed   ; ...del objeto
	ld a,(0e33ah)		;67f0   ; el segundo?
	or a			;67f3
	ld a,004h		;67f4   ; 4 o 0xB4: los patrones del dibujo nuevo
	jr z,L_67FA		;67f6   ; no: 4
	ld a,0b4h		;67f8   ; si: 0xB4
L_67FA:
	ld (hl),a			;67fa   ; el patron
	call pon_el_patron_de_arriba		;67fb   ; y el del otro sprite
	ld a,003h		;67fe   ; (0xE324)=3
	ld (0e324h),a		;6800   ; guardado
	jp espera_a_y_sigue		;6803   ; E004=3 y al paso 2
esconde_los_bichos:		; Y=0xD0 en el objeto 4: el VDP no pinta ni ese sprite ni los que van detras
	ld a,0d0h		;6806   ; Y = 0xD0...
	ld (0e224h),a		;6808   ; ...en el objeto 4, el plano 2
	ret			;680b   ; vuelta
L_680C:
	djnz L_686B		;680c   ; paso 2: los saltos de alegria
	call cubos_que_giran		;680e   ; los cubos que aun giran
	call vuelca_los_sprites_en_orden		;6811   ; los sprites
	call colores_del_marco		;6814   ; el marco cambia de color
	call vuelca_un_cuarto_de_la_pantalla		;6817   ; un cuarto de la pantalla
	ld hl,0e32ah		;681a   ; cada diez cuadros...
	dec (hl)			;681d   ; la cuenta del salto
	jr nz,mueve_uno_arriba_o_abajo		;681e   ; sin acabar: un pixel
	ld (hl),00ah		;6820   ; otros diez cuadros
	inc hl			;6822   ; ...arriba o abajo...
	ld a,(hl)			;6823   ; arriba o abajo...
	xor 001h		;6824   ; ...cambia
	ld (hl),a			;6826   ; guardado
	inc hl			;6827   ; la cuenta de saltos
	dec (hl)			;6828   ; ...y a los seis, al paso siguiente
	jp z,espera_a_y_sigue		;6829   ; el sexto: al paso 3
	or a			;682c   ; 4 o -4: el dibujo cambia con el salto
	ld a,004h		;682d   ; +4...
	jr z,L_6833		;682f   ; ...o...
	ld a,0fch		;6831   ; ...-4
L_6833:
	ld b,a			;6833   ; en B
	ld hl,(0e33bh)		;6834   ; el objeto
	ld a,006h		;6837   ; byte 6...
	call suma_a_a_hl		;6839   ; ...el patron
	ld a,b			;683c   ; + B
	add a,(hl)			;683d
	ld (hl),a			;683e   ; guardado
pon_el_patron_de_arriba:
	ld b,a			;683f   ; B = el patron
	ld hl,(0e33bh)		;6840   ; el segundo sprite, 16 patrones mas alla
	ld a,00eh		;6843   ; byte 14: el patron del segundo sprite
	call suma_a_a_hl		;6845
	ld a,b			;6848   ; el mismo...
	add a,010h		;6849   ; ...16 mas alla
	ld (hl),a			;684b   ; guardado
	ret			;684c   ; vuelta
mueve_uno_arriba_o_abajo:
	inc hl			;684d   ; arriba o abajo
	ld a,(hl)			;684e
	or a			;684f   ; abajo?
	ld a,0ffh		;6850   ; -1...
	jr z,L_6856		;6852
	ld a,001h		;6854   ; ...o +1
L_6856:
	ld b,a			;6856   ; la Y, un pixel...
	ld hl,(0e33bh)		;6857   ; el objeto
	ld a,004h		;685a   ; byte 4...
	call suma_a_a_hl		;685c   ; ...la Y
	ld a,b			;685f   ; + B
	add a,(hl)			;6860
	ld (hl),a			;6861   ; guardada
	ld b,a			;6862   ; en B
	ld a,008h		;6863   ; ...y la del segundo sprite
	call suma_a_a_hl		;6865   ; byte 12: la Y del segundo sprite
	ld a,b			;6868   ; la misma
	ld (hl),a			;6869   ; guardada
	ret			;686a   ; vuelta
L_686B:
	djnz L_6878		;686b   ; paso 3: sonido 0x14
	call colores_del_marco		;686d   ; el marco cambia de color
	ld a,014h		;6870   ; el sonido 0x14
	call toca_sonido		;6872
	jp espera_a_y_sigue		;6875   ; y al paso 4
L_6878:
	djnz L_6888		;6878   ; paso 4: el marco cambia de color mientras suena
	call colores_del_marco		;687a   ; el marco cambia de color
	call vuelca_un_cuarto_de_la_pantalla		;687d   ; un cuarto de la pantalla
	ld a,(0e012h)		;6880   ; mientras suene la musica...
	or a			;6883
	ret nz			;6884   ; ...se espera
	jp espera_a_y_sigue		;6885   ; y al paso 5
L_6888:
	djnz L_68B0		;6888   ; paso 5
	call vuelca_la_pantalla		;688a   ; la pantalla entera
	ld a,(0e002h)		;688d   ; el modo
	bit 5,a		;6890   ; el duelo?
	jr nz,L_6898		;6892   ; si: no hay tiempo que cobrar
	call cobra_el_tiempo		;6894   ; con un jugador, cobra el tiempo: 10 puntos por unidad, y vuelve hasta que se acaba
	ret nz			;6897   ; mientras quede tiempo, vuelve
L_6898:
	ld a,(0e002h)		;6898   ; el modo
	bit 5,a		;689b   ; el duelo?
	jr z,L_68A6		;689d   ; no
	ld a,(0ecb8h)		;689f   ; en el duelo, si ya no quedan partidas, se acabo
	or a			;68a2   ; ninguna?
	jp z,fin_del_duelo		;68a3   ; se acabo el duelo
L_68A6:
	xor a			;68a6   ; fase acabada: la escena 8 lo recoge
	ld (0e334h),a		;68a7   ; (0xE334)=0
	ld a,001h		;68aa   ; 1...
	ld (0e00dh),a		;68ac   ; ...en (0xE00D): fase acabada
	ret			;68af   ; vuelta
L_68B0:
	djnz L_68B5		;68b0   ; pasos 6 a 9: el piedra-papel-tijera del duelo
	jp jan_ken		;68b2   ; paso 6
L_68B5:
	djnz L_68BA		;68b5   ; paso 7...
	jp pon		;68b7   ; ...PON!
L_68BA:
	djnz L_68BF		;68ba   ; paso 8...
	jp quien_gana		;68bc   ; ...quien gana
L_68BF:
	djnz L_68C4		;68bf   ; paso 9...
	jp despues_del_jan_ken		;68c1   ; ...y despues
L_68C4:
	djnz L_68D0		;68c4   ; paso 10: silencio
	ld a,059h		;68c6   ; silencio
	call toca_sonido		;68c8
	ld a,020h		;68cb   ; 32 cuadros
	jp espera_a_y_sigue		;68cd   ; y al paso 11
L_68D0:
	djnz L_68DD		;68d0   ; paso 11: espera y pantalla en negro
	ld hl,0e004h		;68d2   ; la espera
	dec (hl)			;68d5   ; un cuadro menos
	ret nz			;68d6   ; hasta cero
	call borra_la_pantalla		;68d7   ; pantalla en negro
	jp espera_a_y_sigue		;68da   ; y al paso 12
L_68DD:
	djnz cuadro_de_juego		;68dd   ; paso 12: se acabo la partida y al logotipo
	xor a			;68df   ; sin partida
	ld (0e002h),a		;68e0   ; guardado
	jp vuelve_al_logotipo		;68e3   ; al logotipo

; ----------------------------------------------------------------------
; EL CUADRO DE JUEGO. Sprites, un cuarto de la pantalla, una de las cuatro comprobaciones del tablero, los mandos de los dos Q*bert, los choques, el movimiento de los 24 objetos y los cubos que giran. Con la bola verde (0xE321) los bichos se quedan quietos; sin ella, salen, deciden y corre el tiempo.
; ----------------------------------------------------------------------
cuadro_de_juego:
	call pon_los_sprites		;68e6   ; la tabla de sprites, con los que se turnan
	call vuelca_un_cuarto_de_la_pantalla		;68e9   ; un cuarto de la tabla de nombres a la VRAM
	call una_comprobacion_por_turno		;68ec   ; una de las cuatro comprobaciones del tablero, por turnos
	call mando_del_primero		;68ef   ; el mando del primero
	call mando_del_segundo		;68f2   ; el del segundo
	call mira_los_choques		;68f5   ; los choques de Q*bert con los objetos
	call mueve_los_objetos		;68f8   ; mueve los 24 objetos
	call cubos_que_giran		;68fb   ; los cubos que giran
	call cuenta_las_protecciones		;68fe   ; las dos protecciones de la salida
	call colores_de_qbert		;6901   ; Q*bert blanco o normal
	call parpadeo_de_la_invencibilidad		;6904   ; el parpadeo de la invencibilidad
	call vida_extra_escondida		;6907   ; el objeto de la vida extra
	ld a,(0e202h)		;690a   ; si ninguno de los dos cae (estado 4)...
	cp 004h		;690d   ; el primero cae?
	jr z,L_691B		;690f   ; si: sin choque entre los dos
	ld a,(0e212h)		;6911   ; el segundo
	cp 004h		;6914   ; cae?
	jr z,L_691B		;6916   ; si: tampoco
	call choque_entre_los_dos		;6918   ; ...el choque entre los dos Q*bert del duelo
L_691B:
	ld hl,0e321h		;691b   ; (0xE321): la congelacion de la bola verde
	ld a,(hl)			;691e   ; la congelacion
	or a			;691f   ; sin ella...
	jr z,cuadro_sin_congelar		;6920   ; ...el cuadro normal
	ld a,(0e072h)		;6922   ; mientras no suene un efecto, su tic-tac
	or a			;6925   ; sonando?
	jr nz,L_692D		;6926   ; si: no se pisa
	ld a,00dh		;6928   ; el tic-tac, 0x0D
	call toca_sonido		;692a   ; suena
L_692D:
	ld a,(0e003h)		;692d   ; una cuenta cada cuatro cuadros
	and 003h		;6930   ; cada cuatro cuadros
	ret nz			;6932
	dec (hl)			;6933   ; una cuenta menos
	ld a,(hl)			;6934   ; la cuenta
	cp 020h		;6935   ; por encima de 32...
	ret nc			;6937   ; ...nada mas
	ld a,00eh		;6938   ; el ultimo tramo, con el sonido 0x0E
	call toca_sonido		;693a   ; el aviso, 0x0E
	ld a,(hl)			;693d   ; la cuenta
	or a			;693e   ; sin acabar...
	ret nz			;693f   ; ...vuelta
	ld a,(0e329h)		;6940   ; y al acabar, si los bichos estaban huyendo, el 0x0F
	or a			;6943   ; los bichos no huian...
	ret z			;6944   ; ...nada
	ld a,00fh		;6945   ; el 0x0F
	jp toca_sonido		;6947   ; suena
cuadro_sin_congelar:
	call salen_los_bichos		;694a   ; salen los bichos que toca
	call deciden_los_bichos		;694d   ; los que estan quietos deciden hacia donde van
	jp corre_el_tiempo		;6950   ; y el tiempo
cuenta_las_protecciones:		; (0xE336) y (0xE337): los cuadros que cada Q*bert es intocable despues de entrar
	ld hl,0e336h		;6953   ; el primero
	ld a,(hl)			;6956   ; la cuenta
	or a			;6957   ; cero...
	jr z,L_695B		;6958   ; ...nada
	dec (hl)			;695a   ; una menos
L_695B:
	inc hl			;695b   ; el segundo
	ld a,(hl)			;695c   ; la cuenta
	or a			;695d   ; cero...
	jr z,L_6961		;695e   ; ...nada
	dec (hl)			;6960   ; una menos
L_6961:
	ret			;6961   ; vuelta
parpadeo_de_la_invencibilidad:		; Mientras (0xE345) o (0xE346) cuentan, el Q*bert de cada uno cambia de color cada cuatro cuadros
	ld hl,0e345h		;6962   ; el primero
	ld b,00dh		;6965   ; el color normal del primero, magenta (13)
	ld a,(hl)			;6967   ; la cuenta
	or a			;6968   ; sin invencibilidad...
	ret z			;6969   ; ...nada
	ld a,(0e003h)		;696a   ; cada cuatro cuadros
	ld c,a			;696d   ; C = el cuadro
	and 003h		;696e   ; cada cuatro...
	ret nz			;6970
	ld a,c			;6971   ; el cuadro
	bit 2,a		;6972   ; un tramo de cada dos, rojo oscuro (6)
	jr z,L_6978		;6974   ; bit 2 a cero: magenta
	ld b,006h		;6976   ; rojo oscuro
L_6978:
	dec (hl)			;6978   ; una cuenta menos
	jr nz,L_697D		;6979   ; al acabar, otra vez magenta
	ld b,00dh		;697b   ; acabada: magenta
L_697D:
	ld a,b			;697d   ; el color...
	ld (0e20fh),a		;697e   ; ...del segundo sprite del primero
	inc hl			;6981   ; el segundo jugador
	ld b,005h		;6982   ; el segundo, azul claro (5) y negro
	ld a,(hl)			;6984   ; su cuenta
	or a			;6985   ; sin invencibilidad...
	ret z			;6986   ; ...nada
	ld a,c			;6987   ; cada cuatro...
	and 003h		;6988   ; ...cuadros
	ret nz			;698a
	ld a,c			;698b   ; el cuadro
	bit 2,a		;698c   ; bit 2 a cero: azul claro
	jr z,L_6992		;698e
	ld b,000h		;6990   ; negro
L_6992:
	dec (hl)			;6992   ; una cuenta menos
	jr nz,L_6997		;6993   ; sin acabar
	ld b,005h		;6995   ; acabada: azul claro
L_6997:
	ld a,b			;6997   ; el color...
	ld (0e21fh),a		;6998   ; ...del segundo sprite del segundo
	ret			;699b   ; vuelta
colores_de_qbert:		; Blanco (15) con el poder de la bola roja (0xE322/0xE331), y si no amarillo oscuro (10)
	ld d,00ah		;699c   ; amarillo oscuro
	ld e,00fh		;699e   ; blanco
	ld a,(0e322h)		;69a0   ; el poder del primero
	or a			;69a3   ; sin el...
	ld a,d			;69a4   ; ...amarillo
	jr z,L_69A8		;69a5
	ld a,e			;69a7   ; con el, blanco
L_69A8:
	ld (0e207h),a		;69a8   ; el color del primer sprite del primero
	ld a,(0e331h)		;69ab   ; el poder del segundo
	or a			;69ae   ; sin el...
	ld a,d			;69af   ; ...amarillo
	jr z,L_69B3		;69b0
	ld a,e			;69b2   ; con el, blanco
L_69B3:
	ld (0e217h),a		;69b3   ; el color del primer sprite del segundo
	ret			;69b6   ; vuelta
vuelca_un_cuarto_de_la_pantalla:		; Cada cuadro, 160 bytes de la copia de la tabla de nombres desde la fila 2: la pantalla entera cada cuatro cuadros
	ld a,(0e003h)		;69b7   ; cual de los cuatro cuartos
	and 003h		;69ba   ; de 0 a 3
	ld b,a			;69bc   ; en B
	ld hl,000a0h		;69bd   ; 5 filas de 32
	call multiplica_hl		;69c0   ; 160 * B
	ld de,03840h		;69c3   ; desde la fila 2
	add hl,de			;69c6   ; + 0x3840: la tabla de nombres
	push hl			;69c7   ; a salvo
	ld de,0b500h		;69c8   ; 0xB500 + 0x3840 = 0xED40: su sitio en la copia
	add hl,de			;69cb   ; la copia
	ex de,hl			;69cc   ; en DE
	pop hl			;69cd   ; HL: la VRAM
	ld bc,000a0h		;69ce   ; 160 bytes
	jp copia_a_vram		;69d1   ; LDIRVM

; ----------------------------------------------------------------------
; LA TABLA DE SPRITES. Los segundos sprites de los dos Q*bert van fijos en los planos 0 y 1; el resto se copia a 0xE400 empezando cada cuadro un objeto mas alla (0xE343), para que con mas de cuatro en una linea el que no se ve cambie de un cuadro a otro.
; ----------------------------------------------------------------------
pon_los_sprites:
	ld hl,03b00h		;69d4   ; plano 0: el segundo sprite del primero
	ld de,0e20ch		;69d7   ; el segundo sprite del primero
	ld bc,00004h		;69da   ; cuatro bytes
	call copia_a_vram		;69dd   ; LDIRVM
	ld hl,03b04h		;69e0   ; plano 1: el del segundo
	ld de,0e21ch		;69e3   ; el del segundo
	ld bc,00004h		;69e6   ; cuatro bytes
	call copia_a_vram		;69e9   ; LDIRVM
	ld hl,0e328h		;69ec   ; (0xE328): una vez, los objetos 19 a 23 a los planos 21 a 25
	ld a,(hl)			;69ef   ; la bandera
	or a			;69f0   ; sin ella...
	jr z,turna_los_sprites		;69f1   ; ...a los turnos
	dec a			;69f3   ; 1...
	jr nz,L_69F7		;69f4   ; ...se borra; 2 se queda en 1
	ld (hl),a			;69f6
L_69F7:
	ld hl,03b54h		;69f7   ; el plano 21
	ld de,0e29ch		;69fa   ; el objeto 19, byte 4
	ld b,005h		;69fd   ; cinco
L_69FF:
	push hl			;69ff   ; HL...
	push de			;6a00   ; ...DE...
	push bc			;6a01   ; ...y B a salvo
	ld bc,00004h		;6a02   ; cuatro bytes
	call copia_a_vram		;6a05   ; LDIRVM
	pop bc			;6a08   ; B...
	pop de			;6a09   ; ...DE...
	pop hl			;6a0a   ; ...y HL de vuelta
	ld a,004h		;6a0b   ; el plano siguiente
	call suma_a_a_hl		;6a0d
	ld a,008h		;6a10   ; el objeto siguiente
	call suma_a_a_de		;6a12
	djnz L_69FF		;6a15   ; cinco
turna_los_sprites:
	ld hl,0e204h		;6a17   ; el primer sprite del primero
	ld a,(0e343h)		;6a1a   ; por donde se empieza este cuadro
	ld b,004h		;6a1d   ; cuatro bytes...
	call multiplica		;6a1f   ; ...por hueco
	ld de,0e400h		;6a22   ; en 0xE400...
	call suma_a_a_de		;6a25   ; ...el hueco del turno
	ld bc,00004h		;6a28   ; el primer sprite de cada Q*bert...
	ldir		;6a2b   ; copiado
	call siguiente_hueco_del_turno		;6a2d   ; el hueco siguiente
	ld hl,0e214h		;6a30   ; el primer sprite del segundo
	ld bc,00004h		;6a33   ; cuatro bytes
	ldir		;6a36   ; copiado
	call siguiente_hueco_del_turno		;6a38   ; el hueco siguiente
	ld hl,0e224h		;6a3b   ; ...y los quince de los objetos 4 a 18
	ld b,00fh		;6a3e   ; quince objetos
L_6A40:
	push bc			;6a40   ; B a salvo
	ld bc,00004h		;6a41   ; cuatro bytes
	ldir		;6a44   ; copiado
	pop bc			;6a46   ; B
	call siguiente_hueco_del_turno		;6a47   ; el hueco siguiente
	ld a,004h		;6a4a   ; el objeto siguiente...
	call suma_a_a_hl		;6a4c   ; ...8 bytes mas alla
	djnz L_6A40		;6a4f   ; quince
	call siguiente_hueco_del_turno		;6a51   ; uno mas: el turno avanza uno por cuadro
	jp vuelca_los_sprites		;6a54   ; a la VRAM
siguiente_hueco_del_turno:		; El puntero de 0xE400 da la vuelta a los 17 huecos
	exx			;6a57   ; los de reserva
	ld hl,0e343h		;6a58   ; el turno
	ld a,(hl)			;6a5b
	inc a			;6a5c   ; uno mas...
	cp 011h		;6a5d   ; ...de 0 a 16
	jr c,L_6A62		;6a5f
	xor a			;6a61   ; 17 es 0
L_6A62:
	ld (hl),a			;6a62   ; guardado
	exx			;6a63   ; los normales
	ret nz			;6a64   ; sin dar la vuelta, DE sigue
	ld de,0e400h		;6a65   ; dando la vuelta, al principio
	ret			;6a68   ; vuelta
vuelca_los_sprites:		; Los 17 de 0xE400 a los planos 2 a 18
	ld hl,03b08h		;6a69   ; el plano 2
	ld de,0e400h		;6a6c   ; desde 0xE400
	ld bc,00044h		;6a6f   ; 17 sprites
	jp copia_a_vram		;6a72   ; LDIRVM
vuelca_los_sprites_en_orden:		; Sin turnos: 19 (o 24) sprites de 0xE204 a 0x3B00 tal cual. Para la fase acabada
	ld b,013h		;6a75   ; 19 sprites
	ld hl,0e328h		;6a77   ; la bandera
	ld a,(hl)			;6a7a
	or a			;6a7b   ; sin ella...
	jr z,L_6A84		;6a7c   ; ...19
	ld b,018h		;6a7e   ; con ella, 24
	dec a			;6a80   ; 1...
	jr nz,L_6A84		;6a81   ; ...se borra
	ld (hl),a			;6a83
L_6A84:
	exx			;6a84   ; los de reserva
	ld hl,0e204h		;6a85   ; los objetos, desde el primer sprite
	ld de,03b00h		;6a88   ; al plano 0
	ld b,000h		;6a8b   ; C: el puerto
	exx			;6a8d   ; los normales
L_6A8E:
	exx			;6a8e   ; los de reserva
	ld c,004h		;6a8f   ; WRTVRM de 4 bytes
	call 0005ch		;6a91   ; BIOS LDIRVM - Block transfers to VRAM from memory | LDIRVM
	ex de,hl			;6a94   ; HL otra vez al objeto
	ld a,004h		;6a95   ; el siguiente...
	call suma_a_a_hl		;6a97
	ld a,004h		;6a9a   ; el plano siguiente...
	call suma_a_a_de		;6a9c
	exx			;6a9f   ; los normales
	djnz L_6A8E		;6aa0   ; B sprites
	ret			;6aa2   ; vuelta

; ----------------------------------------------------------------------
; LA PAUSA. F1 la pone y la quita, pero solo mientras suena la musica de la fase (sonidos 0x17-0x1C). Al pararse suena el 0x56, que antes guarda los canales; al seguir, 0xE0F1 los devuelve.
; ----------------------------------------------------------------------
mira_la_pausa:
	ld a,(0e327h)		;6aa3   ; la pausa
	or a			;6aa6   ; puesta?
	jr nz,L_6AB2		;6aa7   ; si: se puede quitar
	ld a,(0e012h)		;6aa9   ; fuera de la pausa, solo con la musica de la fase
	cp 01dh		;6aac   ; la musica 0x1D o posterior...
	ret nc			;6aae   ; ...no deja
	cp 017h		;6aaf   ; antes de la 0x17...
	ret c			;6ab1   ; ...tampoco
L_6AB2:
	ld a,006h		;6ab2   ; fila 6 del teclado
	call 00141h		;6ab4   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | SNSMAT
	ld hl,0e326h		;6ab7   ; la lectura anterior
	cp (hl)			;6aba   ; sin cambios, nada
	ret z			;6abb   ; igual: nada
	ld (hl),a			;6abc   ; guardada
	bit 5,a		;6abd   ; bit 5, F1: pulsada va a cero
	ret nz			;6abf   ; suelta: nada
	inc hl			;6ac0   ; la pausa
	ld a,(hl)			;6ac1
	xor 001h		;6ac2   ; cambia la pausa
	ld (hl),a			;6ac4   ; guardada
	ld a,001h		;6ac5   ; al volver, los canales guardados
	ld (0e0f1h),a		;6ac7   ; (0xE0F1): al quitarla, los canales vuelven
	ret z			;6aca   ; quitada: ya esta
	ld a,056h		;6acb   ; el sonido de la pausa
	jp toca_sonido		;6acd   ; puesta: el sonido 0x56
parpadea_la_pausa:		; -PAUSE- ocho cuadros si y ocho no
	ld a,(0e003h)		;6ad0   ; el cuadro
	bit 3,a		;6ad3   ; bit 3
	ld de,06adeh		;6ad5   ; -PAUSE-
	jp z,pinta_guion		;6ad8   ; a cero: se pinta
	jp borra_guion		;6adb   ; a uno: se borra

; ----------------------------------------------------------------------
; DATOS rotulo_pause: Guion de 0x4685: "-PAUSE-" en 0x394C
;   0x6ade..0x6ae8  (10 bytes)
DATA_rotulo_pause:
	defb 04ch,039h,020h,030h,021h,035h,033h,025h,020h,0ffh	; 6ade  L9 0!53% .

; ======================================================================
; CODIGO 0x6ae8..0x6b08  (32 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MARCO CAMBIA DE COLOR: cada ocho cuadros, uno de los tres juegos de colores de 0x6B08 para los tiles del marco (0xEC-0xF7).
; ----------------------------------------------------------------------
colores_del_marco:
	ld a,(0e003h)		;6ae8   ; el cuadro
	and 007h		;6aeb   ; cada ocho...
	ret nz			;6aed
	ld hl,0e324h		;6aee   ; (0xE324) cuenta 3, 2, 1
	dec (hl)			;6af1   ; uno menos
	ld a,(hl)			;6af2   ; la cuenta
	jr nz,L_6AF7		;6af3   ; sin llegar a cero
	ld (hl),003h		;6af5   ; de 3 a 1
L_6AF7:
	ld hl,06b08h		;6af7   ; su guion RLE...
	add a,a			;6afa   ; por dos
	call suma_a_a_hl		;6afb   ; la entrada de la tabla
	ld e,(hl)			;6afe   ; el puntero...
	inc hl			;6aff
	ld d,(hl)			;6b00   ; ...del guion
	ld hl,00760h		;6b01   ; ...al color del tile 0xEC
	call guion_rle_en_tres_bancos		;6b04   ; en los tres tercios
	ret			;6b07   ; vuelta

; ----------------------------------------------------------------------
; DATOS colores_del_marco_punteros: Los tres guiones de color, indexados por
;   (0xE324): 0x6B34, 0x6B21 y 0x6B0E
;   0x6b08..0x6b0e  (6 bytes)
DATA_colores_del_marco_punteros:
	defw 06b34h,06b21h,06b0eh	; 6b08  -> 0x6b34 0x6b21 DATA_colores_del_marco_rle

; ----------------------------------------------------------------------
; DATOS colores_del_marco_rle: Los tres guiones RLE, de 19 bytes y 96 de color
;   cada uno (doce tiles): el mismo dibujo con los tres colores del marco
;   rotados
;   0x6b0e..0x6b47  (57 bytes)
DATA_colores_del_marco_rle:
	defb 008h,020h,010h,030h,008h,020h,008h,040h,010h,050h,008h,040h,008h,080h,010h,090h,008h,080h,000h	; 6b0e  . .0. .@.P.@.......
	defb 008h,080h,010h,090h,008h,080h,008h,020h,010h,030h,008h,020h,008h,040h,010h,050h,008h,040h,000h	; 6b21  ....... .0. .@.P.@.
	defb 008h,040h,010h,050h,008h,040h,008h,080h,010h,090h,008h,080h,008h,020h,010h,030h,008h,020h,000h	; 6b34  .@.P.@....... .0. .

; ======================================================================
; CODIGO 0x6b47..0x6bbf  (120 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA DEMOSTRACION. Se alternan dos: un jugador en la fase 34 y dos a la vez en la 37. Q*bert juega con las pulsaciones de 0x6BBF (y el segundo con las de 0x6BD8), una cada 32 o 48 cuadros.
; ----------------------------------------------------------------------
prepara_la_demostracion:
	call monta_la_fuente		;6b47   ; la fuente
	ld hl,030ffh		;6b4a   ; la cuenta de las dos listas de pulsaciones
	ld (0e00bh),hl		;6b4d   ; las dos cuentas: 0xFF pulsaciones hechas y 0x30 cuadros
	ld (0e117h),hl		;6b50   ; las del segundo
	ld a,001h		;6b53   ; Q*bert en juego
	ld (0e113h),a		;6b55   ; Q*bert en juego
	ld hl,0e116h		;6b58   ; una vez cada una
	ld a,(hl)			;6b5b   ; la de un jugador o la de dos
	xor 001h		;6b5c
	ld (hl),a			;6b5e   ; guardado
	jr z,L_6B6C		;6b5f
	xor a			;6b61   ; un jugador, fase 34
	ld (0e002h),a		;6b62   ; modo 0: demostracion de uno
	ld a,034h		;6b65   ; la fase 34
	ld (0e111h),a		;6b67
	jr L_6B76		;6b6a   ; y sigue
L_6B6C:
	ld a,020h		;6b6c   ; dos jugadores, fase 37
	ld (0e002h),a		;6b6e   ; modo 0x20: demostracion de dos
	ld a,037h		;6b71   ; la fase 37
	ld (0e111h),a		;6b73
L_6B76:
	call tiempo_a_99		;6b76   ; el tiempo
	call carga_el_tablero		;6b79   ; el tablero
	jp monta_la_fase		;6b7c   ; y la fase entera
cuadro_de_la_demostracion:
	jp cuadro_de_juego		;6b7f   ; el cuadro de la partida
pulsaciones_de_la_demostracion:
	ld b,000h		;6b82   ; cada 32 cuadros, la siguiente del primero
	ld a,020h		;6b84   ; cada 32 cuadros
	ld hl,0e00ch		;6b86   ; su cuenta
	ld de,06bbfh		;6b89   ; su lista
	call siguiente_pulsacion		;6b8c   ; la siguiente
	ld a,(0e116h)		;6b8f   ; la de dos?
	or a			;6b92   ; no...
	ret nz			;6b93   ; ...ya esta
	ld b,001h		;6b94   ; cada 48, la del segundo
	ld a,030h		;6b96   ; cada 48 cuadros
	ld hl,0e118h		;6b98   ; su cuenta
	ld de,06bd8h		;6b9b   ; su lista
siguiente_pulsacion:
	dec (hl)			;6b9e   ; la cuenta de cuadros
	ret nz			;6b9f   ; sin acabar: nada
	ld (hl),a			;6ba0   ; otra vez
	dec hl			;6ba1   ; el numero de pulsacion...
	inc (hl)			;6ba2   ; ...mas uno
	ld a,(hl)			;6ba3
	call suma_a_a_de		;6ba4   ; en la lista
	ld a,(de)			;6ba7   ; 0xFF: se acabo la demostracion
	cp 0ffh		;6ba8   ; 0xFF...
	jr z,L_6BBA		;6baa   ; ...fin
	dec b			;6bac   ; B=1: el segundo
	jr z,L_6BB3		;6bad
	call guarda_el_mando_1		;6baf   ; como si viniera del mando 1
	ret			;6bb2   ; vuelta
L_6BB3:
	ld hl,0e330h		;6bb3   ; o del mando 2
	call guarda_mando_en_hl		;6bb6   ; al mando 2
	ret			;6bb9   ; vuelta
L_6BBA:
	xor a			;6bba   ; la demostracion...
	ld (0e113h),a		;6bbb   ; ...se acaba
	ret			;6bbe   ; vuelta

; ----------------------------------------------------------------------
; DATOS pulsaciones_de_la_demostracion: Las dos listas, acabadas en 0xFF: 24
;   pulsaciones del primero y 24 del segundo (desde 0x6BD8). Cada una es una
;   diagonal: 0x05 arriba-izquierda, 0x06 abajo-izquierda, 0x09 arriba-derecha
;   y 0x0A abajo-derecha
;   0x6bbf..0x6bf1  (50 bytes)
DATA_pulsaciones_de_la_demostracion:
	defb 00ah,006h,006h,009h,00ah,005h,00ah,006h,006h,009h,006h,009h,00ah,006h,005h,009h,006h,009h,00ah,005h,00ah,005h,006h,00ah,0ffh	; 6bbf  .........................
	defb 006h,00ah,005h,00ah,005h,006h,009h,005h,009h,005h,00ah,006h,009h,00ah,005h,006h,00ah,005h,006h,006h,009h,005h,00ah,006h,0ffh	; 6bd8  .........................

; ======================================================================
; CODIGO 0x6bf1..0x6d10  (287 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MANDO DEL PRIMERO. Si esta quieto (estado 0) y se pulsa una diagonal, salta. Con el poder de la bola roja y el disparo pulsado, el salto es largo. Al aterrizar sobre un cubo, lo gira; si ya estaba acabado, lo apunta para la vida extra.
; ----------------------------------------------------------------------
mando_del_primero:
	ld hl,0e202h		;6bf1   ; (0xE202): el estado; 0 es quieto
	ld a,(hl)			;6bf4
	or a			;6bf5   ; en el aire o cayendo...
	ret nz			;6bf6   ; ...no salta
	call diagonal_del_primero		;6bf7   ; la diagonal pulsada, y el dibujo mirando hacia alli
	ld a,b			;6bfa   ; ninguna...
	or a			;6bfb
	ret z			;6bfc   ; ...nada
	ld a,(0e009h)		;6bfd   ; con el disparo...
	bit 4,a		;6c00   ; bit 4: el disparo
	jr z,L_6C0A		;6c02   ; sin el...
	ld a,(0e322h)		;6c04   ; ...y el poder de la bola roja, salto largo
	ld (0e323h),a		;6c07   ; (0xE323)
L_6C0A:
	call bit_mas_bajo		;6c0a   ; B: una sola diagonal
salta_el_primero:
	ld hl,0e202h		;6c0d   ; el estado del primero
	call pon_el_salto		;6c10   ; estado, arco, direccion y dibujo
	xor a			;6c13   ; sin salto largo...
	ld (0e323h),a		;6c14   ; ...para el siguiente
	call casilla_debajo		;6c17   ; la casilla de destino
	and 040h		;6c1a   ; acabada por el primero: cuenta para la vida extra
	jr z,L_6C23		;6c1c   ; no: gira
	call apunta_el_salto		;6c1e   ; si: la racha
	jr L_6C26		;6c21   ; y sigue
L_6C23:
	call gira_el_cubo		;6c23   ; si no, el cubo gira
L_6C26:
	ld hl,0e201h		;6c26   ; el segundo sprite copia al primero
	ld de,0e209h		;6c29   ; al segundo sprite: estado, arco...
	ld bc,00003h		;6c2c   ; ...y los tres bytes
	ldir		;6c2f   ; copiados
	ld a,(0e206h)		;6c31   ; el patron del primero...
	add a,010h		;6c34   ; ...16 mas alla...
	ld (0e20eh),a		;6c36   ; ...en el segundo
	ret			;6c39   ; vuelta
mando_del_segundo:		; Lo mismo con el mando 2 y el objeto 0xE210, solo en el duelo
	ld a,(0e002h)		;6c3a   ; el modo
	bit 5,a		;6c3d   ; el duelo?
	ret z			;6c3f   ; no: nada
	ld hl,0e212h		;6c40   ; el estado del segundo
	ld a,(hl)			;6c43
	or a			;6c44   ; en el aire...
	ret nz			;6c45   ; ...no salta
	call diagonal_del_segundo		;6c46   ; la diagonal pulsada
	ld a,b			;6c49
	or a			;6c4a   ; ninguna...
	ret z			;6c4b   ; ...nada
	ld a,(0e330h)		;6c4c   ; su mando
	bit 4,a		;6c4f   ; el disparo
	jr z,L_6C59		;6c51   ; sin el...
	ld a,(0e331h)		;6c53   ; su poder...
	ld (0e323h),a		;6c56   ; ...a (0xE323)
L_6C59:
	call bit_mas_bajo		;6c59   ; una sola diagonal
salta_el_segundo:
	ld hl,0e212h		;6c5c   ; su estado
	call pon_el_salto		;6c5f   ; estado, arco, direccion y dibujo
	xor a			;6c62   ; sin salto largo...
	ld (0e323h),a		;6c63   ; ...para el siguiente
	call casilla_debajo		;6c66   ; la casilla de destino
	and 020h		;6c69   ; los cubos acabados por el segundo no giran
	call z,gira_el_cubo		;6c6b   ; y si no, gira
	ld hl,0e211h		;6c6e   ; al segundo sprite...
	ld de,0e219h		;6c71   ; ...estado, arco...
	ld bc,00003h		;6c74   ; ...y los tres bytes
	ldir		;6c77   ; copiados
	ld a,(0e216h)		;6c79   ; el patron...
	add a,010h		;6c7c   ; ...16 mas alla...
	ld (0e21eh),a		;6c7e   ; ...en el segundo sprite
	ret			;6c81   ; vuelta
diagonal_del_segundo:
	ld de,0e32fh		;6c82   ; su mando
	ld hl,01d80h		;6c85   ; sus patrones
	jr lee_la_diagonal		;6c88   ; y lo mismo
diagonal_del_primero:
	ld de,0e008h		;6c8a   ; el mando 1
	ld hl,01800h		;6c8d   ; los patrones del primero

; ----------------------------------------------------------------------
; LA DIAGONAL. Solo valen las cuatro combinaciones de dos direcciones, y tienen que pulsarse las dos a la vez: B sale 1 (arriba-izquierda), 2 (abajo-derecha), 4 (abajo-izquierda) u 8 (arriba-derecha), o 0. Y se pone el dibujo de Q*bert mirando hacia alli.
; ----------------------------------------------------------------------
lee_la_diagonal:
	ld b,000h		;6c90   ; ninguna
	ld a,(de)			;6c92   ; algo acaba de pulsarse...
	and 00fh		;6c93   ; direcciones recien pulsadas?
	ret z			;6c95   ; no: nada
	inc de			;6c96   ; lo que esta pulsado
	ld a,(de)			;6c97   ; ...y lo que esta pulsado
	and 00fh		;6c98   ; las direcciones...
	ret z			;6c9a
	ld b,001h		;6c9b   ; 1...
	cp 005h		;6c9d   ; 0x05: arriba-izquierda
	jr z,mira_a_la_izquierda		;6c9f
	ld b,002h		;6ca1   ; 2...
	cp 00ah		;6ca3   ; 0x0A: abajo-derecha
	jr z,mira_a_la_derecha		;6ca5
	ld b,004h		;6ca7   ; 4...
	cp 006h		;6ca9   ; 0x06: abajo-izquierda
	jr z,mira_a_la_izquierda		;6cab
	ld b,008h		;6cad   ; 8...
	cp 009h		;6caf   ; 0x09: arriba-derecha
	jr z,mira_a_la_derecha		;6cb1
	ld b,000h		;6cb3   ; ninguna diagonal
	ret			;6cb5   ; vuelta
mira_a_la_izquierda:
	ld de,0acbch		;6cb6   ; 256 bytes de patrones: los dibujos de Q*bert hacia la izquierda
	jr L_6CBE		;6cb9   ; y a copiarlos
mira_a_la_derecha:
	ld de,0adbch		;6cbb   ; los de hacia la derecha
L_6CBE:
	push bc			;6cbe   ; B a salvo
	ld bc,00100h		;6cbf   ; 256 bytes
	call copia_a_vram		;6cc2   ; LDIRVM
	pop bc			;6cc5   ; B
	ret			;6cc6   ; vuelta
bit_mas_bajo:		; B = el bit mas bajo de A
	ld a,b			;6cc7   ; A = las diagonales
	ld b,001h		;6cc8   ; desde el bit 0
L_6CCA:
	rrca			;6cca   ; el siguiente...
	ret c			;6ccb   ; ...a uno: B es el suyo
	sla b		;6ccc   ; B al siguiente
	jr L_6CCA		;6cce   ; y otra vez

; ----------------------------------------------------------------------
; PONE EL SALTO en el objeto HL: estado 1 (hacia la izquierda) o 2 (hacia la derecha), el arco de 0x6D10 (hacia arriba o hacia abajo) y el dibujo de espaldas o de frente.
; ----------------------------------------------------------------------
pon_el_salto:
	ld c,001h		;6cd0   ; estado 1
	ld a,b			;6cd2   ; las dos diagonales de la izquierda: estado 1...
	and 005h		;6cd3   ; 1 o 4?
	jr nz,L_6CD8		;6cd5   ; si: 1
	inc c			;6cd7   ; ...si no, 2
L_6CD8:
	ld (hl),c			;6cd8   ; el estado
	inc hl			;6cd9   ; el byte 3
	ld c,001h		;6cda   ; el arco: 1 hacia arriba, 3 hacia abajo
	ld a,b			;6cdc   ; la diagonal
	and 009h		;6cdd   ; 1 u 8: hacia arriba
	jr nz,L_6CE3		;6cdf
	ld c,003h		;6ce1   ; 3: hacia abajo
L_6CE3:
	call arco_del_salto		;6ce3   ; el arco
	inc hl			;6ce6   ; la Y...
	ld e,(hl)			;6ce7   ; ...en E
	inc hl			;6ce8   ; la X...
	ld d,(hl)			;6ce9   ; ...en D
	ld a,b			;6cea   ; la diagonal
	ld c,00ch		;6ceb   ; el dibujo: 0x0C (de espaldas, subiendo) o 0x04 (de frente, bajando) dentro de su grupo de 16
	and 009h		;6ced   ; hacia arriba?
	jr nz,L_6CF3		;6cef   ; si: 0x0C
	ld c,004h		;6cf1   ; no: 0x04
L_6CF3:
	inc hl			;6cf3   ; el byte 6
	ld a,(hl)			;6cf4   ; el patron...
	and 0f0h		;6cf5   ; ...su grupo de 16...
	add a,c			;6cf7   ; ...+ el dibujo
	ld (hl),a			;6cf8   ; guardado
	ret			;6cf9   ; vuelta
arco_del_salto:
	ld a,(0e323h)		;6cfa   ; con el salto largo, el arco de antes en la tabla
	or a			;6cfd   ; salto largo?
	jr z,L_6D06		;6cfe   ; no
	dec c			;6d00   ; el arco largo
	ld a,008h		;6d01   ; y su sonido, el 8
	call toca_sonido		;6d03   ; suena
L_6D06:
	ld a,c			;6d06   ; el arco
	ld de,06d10h		;6d07   ; donde empieza el arco en 0x6F9E
	call suma_a_a_de		;6d0a   ; su comienzo en 0x6F9E
	ld a,(de)			;6d0d
	ld (hl),a			;6d0e   ; en el byte 3
	ret			;6d0f   ; vuelta

; ----------------------------------------------------------------------
; DATOS arcos_de_salto: Donde empieza cada arco en la tabla de 0x6F9E: 0x00
;   (largo hacia arriba), 0x21 (normal hacia arriba), 0x32 (largo hacia abajo)
;   y 0x53 (normal hacia abajo). El largo, el de la bola roja, cruza dos filas
;   0x6d10..0x6d14  (4 bytes)
DATA_arcos_de_salto:
	defb 000h,021h,032h,053h	; 6d10

; ======================================================================
; CODIGO 0x6d14..0x6d35  (33 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; MUEVE LOS 24 OBJETOS segun su estado (el byte 2): 0 quieto, 1 y 2 saltando, 3 entrando, 4 cayendo por un lado, 5 cayendo de un disco, 6-11 huyendo, 12 y 13 cayendo muertos, 14 nada. Con la bola verde, solo los cuatro primeros: los dos Q*bert.
; ----------------------------------------------------------------------
mueve_los_objetos:
	ld hl,0e202h		;6d14   ; el estado del objeto 0
	ld b,018h		;6d17   ; 24 objetos
	ld a,(0e321h)		;6d19   ; congelados?
	or a			;6d1c
	jr z,L_6D21		;6d1d   ; congelado: solo Q*bert
	ld b,004h		;6d1f   ; si: solo 4
L_6D21:
	push hl			;6d21   ; HL...
	push bc			;6d22   ; ...y B a salvo
	ld a,(hl)			;6d23   ; el estado
	call mueve_un_objeto		;6d24   ; lo que haga
	pop bc			;6d27   ; B...
	pop hl			;6d28   ; ...y HL
	ld a,008h		;6d29   ; 8 bytes por objeto
	call suma_a_a_hl		;6d2b   ; el objeto siguiente
	djnz L_6D21		;6d2e   ; 24
	ret			;6d30   ; vuelta
mueve_un_objeto:
	push hl			;6d31   ; el estado, para la rutina
	call reparte_por_tabla		;6d32   ; HL, apilado, es el estado del objeto

; ----------------------------------------------------------------------
; DATOS estados_de_los_objetos: Quince entradas, una por estado: 0 y 14 nada
;   (0x6D53), 1, 2, 12 y 13 salto (0x6E3B), 3 entra por arriba (0x6DE7), 4 cae
;   por un lado (0x6D55), 5 baja flotando (0x6E26) y 6-11 huye (0x7017)
;   0x6d35..0x6d53  (30 bytes)
DATA_estados_de_los_objetos:
	defw 06d53h,06e3bh,06e3bh,06de7h,06d55h,06e26h,07017h,07017h	; 6d35
	defw 07017h,07017h,07017h,07017h,06e3bh,06e3bh,06d53h	; 6d45

; ======================================================================
; CODIGO 0x6d53..0x6f9e  (587 bytes)
; ======================================================================


estado_quieto:
	pop hl			;6d53   ; el HL apilado por 0x6D31, y nada mas
	ret			;6d54

; ----------------------------------------------------------------------
; ESTADO 4: CAE POR UN LADO. Baja dos pixeles por cuadro agitando los brazos; al salirse por abajo se retira, y si era uno de los Q*bert (lo dice su patron: menos de 0x21 el primero, 0xB0 o mas el segundo) pierde el poder y la velocidad y se apunta que ha caido.
; ----------------------------------------------------------------------
estado_cae_por_un_lado:
	pop hl			;6d55
	inc hl			;6d56
	inc hl			;6d57
	inc (hl)			;6d58   ; Y + 2
	inc (hl)			;6d59
	inc hl			;6d5a
	inc hl			;6d5b
	ld a,(0e003h)		;6d5c   ; cada ocho cuadros, el dibujo cambia entre 0 y 4
	and 007h		;6d5f
	jr nz,L_6D72		;6d61
	ld a,(hl)			;6d63
	and 00fh		;6d64
	or a			;6d66
	ld b,004h		;6d67
	jr z,L_6D6D		;6d69
	ld b,000h		;6d6b
L_6D6D:
	ld a,(hl)			;6d6d
	and 0f0h		;6d6e
	add a,b			;6d70
	ld (hl),a			;6d71
L_6D72:
	dec hl			;6d72   ; hasta la Y 0xC8
	dec hl			;6d73
	ld a,(hl)			;6d74
	cp 0c8h		;6d75
	ret c			;6d77
	ld (hl),0e0h		;6d78   ; fuera de la pantalla y quieto
	inc hl			;6d7a
	inc hl			;6d7b
	ld d,(hl)			;6d7c
	dec hl			;6d7d
	dec hl			;6d7e
	dec hl			;6d7f
	dec hl			;6d80
	ld (hl),000h		;6d81
	ld a,d			;6d83   ; por el patron: el primer Q*bert...
	cp 021h		;6d84
	ld b,07ch		;6d86
	ld c,a			;6d88
	ld a,000h		;6d89
	ld (0e333h),a		;6d8b
	ld a,c			;6d8e
	jr c,L_6DA3		;6d8f
	ld b,0ach		;6d91   ; ...el segundo...
	cp 0b0h		;6d93
	ld a,001h		;6d95
	ld (0e333h),a		;6d97
	ret c			;6d9a   ; ...o un bicho, que ya no vuelve
	call dibujos_de_la_izquierda_del_segundo		;6d9b   ; el segundo, con sus dibujos de la izquierda y sin poderes
	call quita_los_poderes_del_segundo		;6d9e
	jr L_6DA9		;6da1
L_6DA3:
	call dibujos_de_la_izquierda_del_primero		;6da3   ; el primero, igual
	call quita_los_poderes_del_primero		;6da6
L_6DA9:
	ld a,(0e002h)		;6da9   ; en el duelo vuelve a entrar por arriba (estado 3) en su columna
	bit 5,a		;6dac
	jr z,cae_el_de_un_jugador		;6dae
	ld (hl),003h		;6db0
	inc hl			;6db2
	inc hl			;6db3
	ld (hl),0e1h		;6db4
	inc hl			;6db6
	ld (hl),b			;6db7
	inc hl			;6db8
	ld a,(hl)			;6db9
	and 0f0h		;6dba
	ld (hl),a			;6dbc
	ld a,(0e333h)		;6dbd   ; y se apunta que ha caido
	or a			;6dc0
	ld hl,0e113h		;6dc1
	jr z,L_6DC9		;6dc4
	ld hl,0e35ch		;6dc6
L_6DC9:
	ld (hl),000h		;6dc9
	ret			;6dcb
cae_el_de_un_jugador:
	xor a			;6dcc   ; con un jugador, fuera de juego: 0x4291 le quita la vida
	ld (0e113h),a		;6dcd
	ret			;6dd0
quita_los_poderes_del_primero:		; Sin salto largo y a la velocidad normal
	xor a			;6dd1
	ld (0e322h),a		;6dd2
	ld (0e201h),a		;6dd5
	ld (0e209h),a		;6dd8
	ret			;6ddb
quita_los_poderes_del_segundo:
	xor a			;6ddc
	ld (0e331h),a		;6ddd
	ld (0e211h),a		;6de0
	ld (0e219h),a		;6de3
	ret			;6de6

; ----------------------------------------------------------------------
; ESTADO 3: ENTRA POR ARRIBA. Baja un pixel por cuadro hasta posarse en un cubo. Si es un Q*bert, queda protegido 128 cuadros; y si ninguno de los dos esta cayendo, suena el 0x14.
; ----------------------------------------------------------------------
estado_entra_por_arriba:
	pop hl			;6de7
	inc hl			;6de8
	inc hl			;6de9
	inc (hl)			;6dea   ; Y + 1
	ld a,(hl)			;6deb
	and 00fh		;6dec   ; solo se para en la altura de una fila (Y = 16n + 12)
	cp 00ch		;6dee
	ret nz			;6df0
	ld e,(hl)			;6df1
	inc hl			;6df2
	ld d,(hl)			;6df3
	inc hl			;6df4
	ld c,(hl)			;6df5
	dec hl			;6df6
	call casilla_debajo		;6df7   ; sin cubo debajo, sigue bajando
	inc a			;6dfa
	ret z			;6dfb
	dec hl			;6dfc   ; quieto
	dec hl			;6dfd
	dec hl			;6dfe
	ld (hl),000h		;6dff
	ld a,c			;6e01   ; el primero (patron por debajo de 0x20)...
	cp 020h		;6e02
	ld hl,0e336h		;6e04
	jr c,L_6E0D		;6e07
	inc hl			;6e09   ; ...o el segundo
	cp 0b0h		;6e0a
	ret c			;6e0c
L_6E0D:
	ld (hl),080h		;6e0d   ; 128 cuadros intocable
	ld a,(0e202h)		;6e0f
	cp 003h		;6e12
	ret z			;6e14
	cp 004h		;6e15
	ret z			;6e17
	ld a,(0e212h)		;6e18
	cp 003h		;6e1b
	ret z			;6e1d
	cp 004h		;6e1e
	ret z			;6e20
	ld a,014h		;6e21   ; el sonido de la llegada
	jp toca_sonido		;6e23

; ----------------------------------------------------------------------
; ESTADO 5: BAJA HASTA LA FILA DE 0xE29C. Un pixel por cuadro hasta la Y del objeto 19; alli desaparece y pide que se vuelvan a pintar los objetos 19 a 23.
; ----------------------------------------------------------------------
estado_baja_a_la_fila:
	pop hl			;6e26
	inc hl			;6e27
	inc hl			;6e28
	inc (hl)			;6e29
	ld a,(0e29ch)		;6e2a
	cp (hl)			;6e2d
	ret nz			;6e2e
retira_y_repinta_la_fila:
	ld (hl),0e0h		;6e2f
	dec hl			;6e31
	dec hl			;6e32
	ld (hl),000h		;6e33
	ld a,001h		;6e35
	ld (0e328h),a		;6e37
	ret			;6e3a

; ----------------------------------------------------------------------
; ESTADOS 1, 2, 12 Y 13: EL SALTO. Tantos pasos del arco por cuadro como diga la velocidad (el nibble bajo del byte 1, mas uno).
; ----------------------------------------------------------------------
estado_salta:
	pop hl			;6e3b
	dec hl			;6e3c   ; el byte 1: la velocidad
	ld a,(hl)			;6e3d
	and 00fh		;6e3e
	ld b,a			;6e40
	inc b			;6e41
	inc hl			;6e42
da_b_pasos:
	push hl			;6e43
	push bc			;6e44
	call un_paso_del_arco		;6e45
	pop bc			;6e48
	pop hl			;6e49
	djnz da_b_pasos		;6e4a
	ret			;6e4c

; ----------------------------------------------------------------------
; UN PASO DEL ARCO. La Y sale de la tabla de 0x6F9E y la X avanza uno y dos pixeles alternos (24 por cada 16 pasos: una columna de cubos). Con 0x80 se acaba el arco: si hay cubo debajo, se posa; si no, o si es la casilla del modelo, cae.
; ----------------------------------------------------------------------
un_paso_del_arco:
	ld a,(hl)			;6e4d   ; estado 0 o 4: nada
	or a			;6e4e
	ret z			;6e4f
	cp 004h		;6e50
	ret z			;6e52
	ld c,a			;6e53
	inc hl			;6e54   ; el byte 3: por donde va el arco
	ld a,(hl)			;6e55
	ld b,a			;6e56
	ld de,06f9eh		;6e57
	call suma_a_a_de		;6e5a
	ld a,(de)			;6e5d
	cp 080h		;6e5e   ; 0x80: fin del arco
	jr nz,avanza_el_arco		;6e60
	inc hl			;6e62
	ld a,c			;6e63   ; los que caen muertos (12 y 13) no se posan
	cp 00ch		;6e64
	jp z,cae_muerto		;6e66
	cp 00dh		;6e69
	jp z,cae_muerto		;6e6b
	inc hl			;6e6e   ; el dibujo de pie: cuatro patrones menos
	inc hl			;6e6f
	ld a,(hl)			;6e70
	sub 004h		;6e71
	ld (hl),a			;6e73
	ld c,a			;6e74
	dec hl			;6e75
	ld d,(hl)			;6e76
	dec hl			;6e77
	ld e,(hl)			;6e78
	ld a,c			;6e79   ; el golpe al posarse: el sonido 4 el primero...
	cp 021h		;6e7a
	ld a,004h		;6e7c
	jr c,L_6E87		;6e7e
	ld a,c			;6e80   ; ...el 5 el segundo, y los bichos, callados
	cp 0b0h		;6e81
	ld a,005h		;6e83
	jr c,L_6E95		;6e85
L_6E87:
	call toca_sonido		;6e87
	ld a,(0e345h)		;6e8a   ; con la invencibilidad, ademas, el 6
	or a			;6e8d
	jr z,L_6E95		;6e8e
	ld a,006h		;6e90
	call toca_sonido_en_partida		;6e92
L_6E95:
	call casilla_debajo		;6e95   ; la casilla de debajo
	ld b,a			;6e98
	ld a,c			;6e99   ; el bicho 0x90 (el que persigue) que cae en un cubo que esta girando...
	cp 090h		;6e9a
	jr c,L_6EB0		;6e9c
	cp 0a0h		;6e9e
	jr nc,L_6EB0		;6ea0
	ld a,b			;6ea2
	rlca			;6ea3
	jr nc,L_6EB0		;6ea4
	push hl			;6ea6   ; ...da 1.000 puntos y se cae
	ld de,01000h		;6ea7
	call suma_puntos		;6eaa
	pop hl			;6ead
	jr pasa_al_estado_4		;6eae
L_6EB0:
	ld a,b			;6eb0   ; sin cubo, a caer
	inc a			;6eb1
	ld a,000h		;6eb2
	jr z,cae_de_la_casilla		;6eb4
	push hl			;6eb6   ; y las dos casillas de los modelos, (Y 0x0C, X 0x1C) y (Y 0x0C, X 0x34), tampoco valen
	ld hl,01c0ch		;6eb7
	or a			;6eba
	sbc hl,de		;6ebb
	pop hl			;6ebd
	jr z,cae_de_la_casilla		;6ebe
	push hl			;6ec0
	ld hl,0340ch		;6ec1
	or a			;6ec4
	sbc hl,de		;6ec5
	pop hl			;6ec7
	jr nz,pon_el_estado		;6ec8
cae_de_la_casilla:
	call cae_por_el_borde		;6eca
pasa_al_estado_4:
	ld a,004h		;6ecd
pon_el_estado:
	dec hl			;6ecf
	dec hl			;6ed0
	ld (hl),a			;6ed1
	ret			;6ed2
avanza_el_arco:
	inc (hl)			;6ed3
	inc hl			;6ed4
	add a,(hl)			;6ed5   ; la Y, con el paso del arco
	cp 0f0h		;6ed6   ; por encima de 0xF0 se ha salido
	jr nc,L_6EFB		;6ed8
	ld (hl),a			;6eda
	inc hl			;6edb
	ld a,b			;6edc   ; la X: uno en los pasos impares y dos en los pares
	rrca			;6edd
	ld a,001h		;6ede
	jr c,L_6EE3		;6ee0
	inc a			;6ee2
L_6EE3:
	ld d,a			;6ee3
	ld a,c			;6ee4   ; hacia la izquierda en los estados 1 y 13
	cp 00dh		;6ee5
	ld a,d			;6ee7
	jr z,L_6EED		;6ee8
	dec c			;6eea
	jr nz,L_6EEF		;6eeb
L_6EED:
	neg		;6eed
L_6EEF:
	add a,(hl)			;6eef
	cp 005h		;6ef0   ; dentro de 5..0xF3
	jr c,se_sale_por_un_lado		;6ef2
	cp 0f4h		;6ef4
	jr nc,se_sale_por_un_lado		;6ef6
	ld (hl),a			;6ef8
	ret			;6ef9
se_sale_por_un_lado:
	dec hl			;6efa
L_6EFB:
	inc hl			;6efb
	inc hl			;6efc
	ld c,(hl)			;6efd
	dec hl			;6efe
	dec hl			;6eff
	dec hl			;6f00
	dec hl			;6f01
	ld (hl),004h		;6f02   ; estado 4: cae
	inc hl			;6f04
	inc hl			;6f05
cae_por_el_borde:
	ld a,c			;6f06   ; solo los que se salen por los lados (X por debajo de 0x21 o de 0xB0 en adelante)...
	cp 021h		;6f07
	jr c,L_6F13		;6f09
	cp 0b0h		;6f0b
	ret c			;6f0d
	call dibujo_de_caer_del_segundo		;6f0e   ; ...que son los Q*bert: su dibujo de caer
	jr L_6F16		;6f11
L_6F13:
	call dibujo_de_caer_del_primero		;6f13
L_6F16:
	ld a,012h		;6f16   ; y el sonido 0x12, el del grito
	jp toca_sonido_en_partida		;6f18
cae_muerto:
	inc hl			;6f1b
	inc hl			;6f1c
	ld c,(hl)			;6f1d
	dec hl			;6f1e
	dec hl			;6f1f
	jr cae_de_la_casilla		;6f20
dibujo_de_caer_del_primero:		; Los patrones 0x00-0x0F con los de 0xAF3C y 0xAF7C
	push hl			;6f22
	inc hl			;6f23
	inc hl			;6f24
	ld a,(hl)			;6f25
	and 0f0h		;6f26
	add a,004h		;6f28
	ld (hl),a			;6f2a
	ld hl,01800h		;6f2b
	ld de,0af3ch		;6f2e
	ld bc,00040h		;6f31
	call copia_a_vram		;6f34
	ld hl,01880h		;6f37
	ld de,0af7ch		;6f3a
	ld bc,00040h		;6f3d
	call copia_a_vram		;6f40
	pop hl			;6f43
	ret			;6f44
dibujo_de_caer_del_segundo:		; Los 0xB0-0xBF, igual
	push hl			;6f45
	inc hl			;6f46
	inc hl			;6f47
	ld a,(hl)			;6f48
	and 0f0h		;6f49
	add a,004h		;6f4b
	ld (hl),a			;6f4d
	ld hl,01d80h		;6f4e
	ld de,0af3ch		;6f51
	ld bc,00040h		;6f54
	call copia_a_vram		;6f57
	ld hl,01e00h		;6f5a
	ld de,0af7ch		;6f5d
	ld bc,00040h		;6f60
	call copia_a_vram		;6f63
	pop hl			;6f66
	ret			;6f67
dibujos_de_la_izquierda_del_primero:		; Los 0x00-0x0F vuelven a ser los de 0xACBC y 0xAD3C
	exx			;6f68
	ld hl,01800h		;6f69
	ld de,0acbch		;6f6c
	ld bc,00040h		;6f6f
	call copia_a_vram		;6f72
	ld hl,01880h		;6f75
	ld de,0ad3ch		;6f78
	ld bc,00040h		;6f7b
	call copia_a_vram		;6f7e
	exx			;6f81
	ret			;6f82
dibujos_de_la_izquierda_del_segundo:
	exx			;6f83
	ld hl,01d80h		;6f84
	ld de,0acbch		;6f87
	ld bc,00040h		;6f8a
	call copia_a_vram		;6f8d
	ld hl,01e00h		;6f90
	ld de,0ad3ch		;6f93
	ld bc,00040h		;6f96
	call copia_a_vram		;6f99
	exx			;6f9c
	ret			;6f9d

; ----------------------------------------------------------------------
; DATOS arcos: Los cinco arcos, pasos de Y con signo y 0x80 de fin: 0x00 salto
;   largo hacia arriba (32 pasos, dos filas), 0x21 salto hacia arriba (16
;   pasos, una fila), 0x32 salto largo hacia abajo, 0x53 salto hacia abajo y
;   0x64 el de caer muerto (un brinco y abajo)
;   0x6f9e..0x7017  (121 bytes)
DATA_arcos:
	defb 0f7h,0fdh,0fch,0ffh,0ffh,0fdh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,000h,0ffh,0ffh,0ffh	; 6f9e  ................
	defb 000h,000h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,000h	; 6fae  ................
	defb 080h,0fdh,0fah,0ffh,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,0ffh,000h,000h,000h,000h	; 6fbe  ................
	defb 001h,080h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,000h	; 6fce  ................
	defb 001h,000h,001h,001h,001h,001h,001h,000h,002h,001h,002h,001h,003h,001h,004h,002h	; 6fde  ................
	defb 005h,005h,080h,0ffh,000h,000h,000h,000h,000h,001h,000h,001h,001h,000h,002h,001h	; 6fee  ................
	defb 003h,001h,007h,080h,0fch,0ffh,0fdh,0ffh,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h	; 6ffe  ................
	defb 001h,000h,001h,001h,002h,001h,002h,001h,080h	; 700e  .........

; ======================================================================
; CODIGO 0x7017..0x727a  (611 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ESTADOS 6 A 11: HUYE. Sube cuatro pixeles y se aparta dos de lado cada 8, 4 o 2 cuadros segun el estado, hasta salirse de la pantalla.
; ----------------------------------------------------------------------
estado_huye:
	pop hl			;7017
	ld a,(hl)			;7018   ; los pares, hacia la derecha; los impares, hacia la izquierda
	ld c,000h		;7019
	rrca			;701b
	jr c,L_701F		;701c
	inc c			;701e
L_701F:
	ld a,(hl)			;701f   ; 6 y 7: cada 8 cuadros; 8 y 9: cada 4; 10 y 11: cada 2
	ld b,007h		;7020
	cp 008h		;7022
	jr c,L_702E		;7024
	ld b,003h		;7026
	cp 00ah		;7028
	jr c,L_702E		;702a
	ld b,001h		;702c
L_702E:
	inc hl			;702e
	inc hl			;702f
	dec (hl)			;7030   ; Y - 4
	dec (hl)			;7031
	dec (hl)			;7032
	dec (hl)			;7033
	ld a,(hl)			;7034
	inc hl			;7035
	cp 005h		;7036   ; al salirse, fuera
	jr c,retira_el_objeto		;7038
	cp 0b0h		;703a
	jr nc,retira_el_objeto		;703c
	ld a,(hl)			;703e
	cp 005h		;703f
	jr c,retira_el_objeto		;7041
	cp 0fah		;7043
	jr nc,retira_el_objeto		;7045
	ld a,(0e003h)		;7047   ; a su ritmo
	and b			;704a
	ret nz			;704b
	inc (hl)			;704c   ; X + 2...
	inc (hl)			;704d
	ld a,c			;704e
	or a			;704f
	ret z			;7050
	dec (hl)			;7051   ; ...o - 2
	dec (hl)			;7052
	dec (hl)			;7053
	dec (hl)			;7054
	ret			;7055
retira_el_objeto:
	dec hl			;7056
	ld (hl),0e0h		;7057
	dec hl			;7059
	dec hl			;705a
	ld (hl),000h		;705b
	ret			;705d
guarda_el_mando_2:		; Lo mismo que 0x4714 con HL=0xE330
	ld hl,0e330h		;705e   ; CODIGO HUERFANO: 0x4705 hace lo mismo llamando a 0x4714
	ld c,(hl)			;7061
	ld (hl),a			;7062
	xor c			;7063
	and (hl)			;7064
	dec hl			;7065
	ld (hl),a			;7066
	ret			;7067
teclas_del_segundo_sin_ctrl:		; Copia de 0x4755 sin la fila 6: E, S, F y C, sin el disparo
	ld b,000h		;7068   ; CODIGO HUERFANO: nadie lo llama
	ld a,003h		;706a
	call 00141h		;706c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 0,a		;706f
	jr nz,L_7075		;7071
	set 1,b		;7073
L_7075:
	bit 2,a		;7075
	jr nz,L_707B		;7077
	set 0,b		;7079
L_707B:
	bit 3,a		;707b
	jr nz,L_7081		;707d
	set 3,b		;707f
L_7081:
	ld a,005h		;7081
	call 00141h		;7083   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 0,a		;7086
	jr nz,L_708C		;7088
	set 2,b		;708a
L_708C:
	ld a,b			;708c
	ret			;708d

; ----------------------------------------------------------------------
; EL CUBO GIRA. Al posarse Q*bert, el cubo de debajo rueda en la direccion del salto: cada cubo es uno de los 24 giros de un cubo con tres caras a la vista, y la tabla de 0x72C0 dice en cual se convierte. Mientras gira ocupa uno de los diez huecos de 0xE2C0 (los cinco primeros para las diagonales 1 y 2, los otros cinco para 4 y 8), con sus nueve tiles de animacion.
; ----------------------------------------------------------------------
gira_el_cubo:
	call casilla_de_la_posicion		;708e   ; la casilla, mas uno
	inc a			;7091
	ld d,a			;7092
	ld e,b			;7093
	ld hl,0e2c0h		;7094   ; si ya esta girando, nada
	ld b,00ah		;7097
L_7099:
	cp (hl)			;7099
	ret z			;709a
	inc hl			;709b
	inc hl			;709c
	inc hl			;709d
	djnz L_7099		;709e
	ld b,005h		;70a0   ; arriba-izquierda o abajo-derecha: huecos 0 a 4...
	ld hl,0e2c0h		;70a2
	ld c,000h		;70a5
	ld a,e			;70a7
	and 003h		;70a8
	jr nz,L_70B1		;70aa
	ld hl,0e2cfh		;70ac   ; ...las otras dos: huecos 5 a 9
	ld c,005h		;70af
L_70B1:
	ld a,(hl)			;70b1
	or a			;70b2
	jr z,ocupa_el_hueco		;70b3
	inc hl			;70b5
	inc hl			;70b6
	inc hl			;70b7
	inc c			;70b8
	djnz L_70B1		;70b9
	ret			;70bb
ocupa_el_hueco:
	ld (hl),d			;70bc   ; casilla, ocho cuadros y direccion
	inc hl			;70bd
	ld (hl),008h		;70be
	inc hl			;70c0
	ld (hl),e			;70c1
	ld b,e			;70c2
	ld a,d			;70c3
	dec a			;70c4
	push af			;70c5
	push bc			;70c6
	ld hl,0ec00h		;70c7   ; la casilla, con el bit 7: esta girando
	call suma_a_a_hl		;70ca
	ld a,(hl)			;70cd
	and 01fh		;70ce
	ld d,a			;70d0
	add a,080h		;70d1
	ld (hl),a			;70d3
	ld c,b			;70d4   ; hacia arriba, la animacion ya usa las caras nuevas
	ld a,b			;70d5
	and 009h		;70d6
	ld a,d			;70d8
	jr z,L_70DF		;70d9
	call giro_siguiente		;70db
	ld d,a			;70de
L_70DF:
	ld b,009h		;70df   ; las tres caras del cubo...
	call multiplica		;70e1
	ld hl,0eb01h		;70e4
	call suma_a_a_hl		;70e7
	ld de,0e2f1h		;70ea   ; ...a 0xE2F1-0xE2F3
	ld a,(hl)			;70ed
	ld (de),a			;70ee
	inc hl			;70ef
	inc hl			;70f0
	inc de			;70f1
	ld a,(hl)			;70f2
	ld (de),a			;70f3
	inc hl			;70f4
	inc hl			;70f5
	inc de			;70f6
	ld a,(hl)			;70f7
	ld (de),a			;70f8
	pop bc			;70f9
	ld hl,0727ah		;70fa   ; la plantilla de color de la animacion, segun el grupo de huecos
	ld de,0e2f4h		;70fd
	ld a,c			;7100
	cp 005h		;7101
	jr c,rellena_la_plantilla		;7103
	ld hl,0729fh		;7105
rellena_la_plantilla:
	ld a,(hl)			;7108   ; pares (cuantos, colores); 0 acaba
	ld (de),a			;7109
	or a			;710a
	jr z,pinta_la_animacion		;710b
	inc hl			;710d
	inc de			;710e
	ld a,(hl)			;710f   ; cada nibble es 0 (negro) o una de las tres caras
	and 0f0h		;7110
	rrca			;7112
	rrca			;7113
	rrca			;7114
	rrca			;7115
	call color_de_la_plantilla		;7116
	rlca			;7119
	rlca			;711a
	rlca			;711b
	rlca			;711c
	ld b,a			;711d
	ld a,(hl)			;711e
	and 00fh		;711f
	call color_de_la_plantilla		;7121
	add a,b			;7124
	ld (de),a			;7125
	inc hl			;7126
	inc de			;7127
	jr rellena_la_plantilla		;7128
pinta_la_animacion:
	ld hl,00048h		;712a   ; el color de los nueve tiles del hueco, en los tres tercios
	ld b,c			;712d
	call multiplica_hl		;712e
	ld de,00488h		;7131
	add hl,de			;7134
	ld de,0e2f4h		;7135
	push bc			;7138
	call guion_rle_en_tres_bancos		;7139
	pop bc			;713c
	pop af			;713d
	call sitio_de_la_casilla		;713e   ; y los tiles 0x91 + 9*hueco en el sitio del cubo
	ld b,c			;7141
	ld a,009h		;7142
	call multiplica		;7144
	add a,091h		;7147
	ld c,003h		;7149
L_714B:
	ld b,003h		;714b
L_714D:
	ld (hl),a			;714d
	inc hl			;714e
	inc a			;714f
	djnz L_714D		;7150
	ld de,0001dh		;7152
	add hl,de			;7155
	dec c			;7156
	jr nz,L_714B		;7157
	ret			;7159
cubos_que_giran:		; Cada cuadro, los diez huecos: al acabar los ocho cuadros, la casilla pasa al giro nuevo y se mira si ya es como el modelo
	ld hl,0e2c0h		;715a
	ld b,00ah		;715d
L_715F:
	push hl			;715f
	push bc			;7160
	ld a,(hl)			;7161
	or a			;7162
	jr z,L_71C4		;7163
	ld c,a			;7165   ; hueco ocupado: cuenta
	inc hl			;7166
	dec (hl)			;7167
	jr nz,L_71C4		;7168
	dec hl			;716a   ; acabado: se libera
	ld (hl),000h		;716b
	inc hl			;716d
	ld a,c			;716e
	dec a			;716f
	push af			;7170
	ld de,0ec00h		;7171
	call suma_a_a_de		;7174
	ld a,(de)			;7177   ; el giro nuevo, sin el bit 7
	sub 080h		;7178
	inc hl			;717a
	ld c,(hl)			;717b
	call giro_siguiente		;717c
	ld (de),a			;717f
	ld b,a			;7180
	pop af			;7181
	call sitio_de_la_casilla		;7182
	xor a			;7185   ; como el modelo del primero...
	ld (0e339h),a		;7186
	ld a,b			;7189
	ld c,b			;718a
	call coincide_con_el_modelo		;718b
	jr nz,L_7198		;718e
	ld b,018h		;7190   ; ...cubo acabado del primero (bit 6)
	ld a,(de)			;7192
	or 040h		;7193
	ld (de),a			;7195
	jr L_71A9		;7196
L_7198:
	ld a,001h		;7198   ; como el del segundo...
	ld (0e339h),a		;719a
	ld a,c			;719d
	call coincide_con_el_modelo		;719e
	jr nz,L_71BC		;71a1
	ld b,019h		;71a3   ; ...acabado del segundo (bit 5)
	ld a,(de)			;71a5
	or 020h		;71a6
	ld (de),a			;71a8
L_71A9:
	ld a,009h		;71a9   ; sonido 9 y 300 puntos
	call toca_sonido_en_partida		;71ab
	push bc			;71ae
	push hl			;71af
	ld de,00300h		;71b0
	call suma_puntos		;71b3
	pop hl			;71b6
	pop bc			;71b7
	ld a,001h		;71b8   ; A=1: cubo acabado, para la racha de la vida extra
	jr L_71BD		;71ba
L_71BC:
	xor a			;71bc   ; A=0: girado sin acabar
L_71BD:
	call apunta_el_salto		;71bd
	ld a,b			;71c0   ; y se pinta como quede
	call dibuja_un_cubo		;71c1
L_71C4:
	pop bc			;71c4
	pop hl			;71c5
	inc hl			;71c6
	inc hl			;71c7
	inc hl			;71c8
	djnz L_715F		;71c9
	ret			;71cb
color_de_la_plantilla:		; A = (0xE2F0 + A): el nibble convertido en color
	exx			;71cc
	ld hl,0e2f0h		;71cd
	call suma_a_a_hl		;71d0
	ld a,(hl)			;71d3
	exx			;71d4
	ret			;71d5
giro_siguiente:		; A = el giro en que se convierte el cubo A al saltar en la direccion C (un bit)
	push de			;71d6   ; cuatro direcciones por giro
	push bc			;71d7
	ld b,004h		;71d8
	call multiplica		;71da
	pop bc			;71dd
	ld de,072c0h		;71de
	call suma_a_a_de		;71e1
	ld a,c			;71e4
L_71E5:
	rrca			;71e5   ; la direccion es el numero de su bit
	jr c,L_71EB		;71e6
	inc de			;71e8
	jr L_71E5		;71e9
L_71EB:
	ld a,(de)			;71eb
	pop de			;71ec
	ret			;71ed

; ----------------------------------------------------------------------
; LA CASILLA DE UNA POSICION: E es la Y y D la X de un sprite; la fila va de 16 en 16 desde 12 y la columna de 24 en 24 desde 24. A = 9 * fila + columna.
; ----------------------------------------------------------------------
casilla_de_la_posicion:
	push bc			;71ee
	push de			;71ef
	ld a,e			;71f0
	sub 00ch		;71f1
	srl a		;71f3
	srl a		;71f5
	srl a		;71f7
	srl a		;71f9
	ld b,009h		;71fb
	call multiplica		;71fd
	ld e,a			;7200
	ld a,d			;7201
	sub 018h		;7202
	ld b,018h		;7204
	call divide		;7206
	add a,e			;7209
	pop de			;720a
	pop bc			;720b
	ret			;720c
sitio_de_la_casilla:		; HL = 0xED63 + 64 * fila + 3 * columna: la esquina del cubo en la copia de la tabla de nombres
	push bc			;720d
	push de			;720e
	ld b,009h		;720f
	call divide		;7211
	ld c,b			;7214
	ld b,a			;7215
	ld hl,00040h		;7216
	call multiplica_hl		;7219
	ld a,c			;721c
	ld b,003h		;721d
	call multiplica		;721f
	call suma_a_a_hl		;7222
	ld de,0ed63h		;7225
	add hl,de			;7228
	pop de			;7229
	pop bc			;722a
	ret			;722b
casilla_y_modelo:
	call casilla_debajo		;722c   ; CODIGO HUERFANO: el cubo bajo (E,D) y, de corrido, la comparacion con el modelo de 0x722F. Nadie lo llama

; ----------------------------------------------------------------------
; COINCIDE CON EL MODELO: las tres caras del cubo A contra las del modelo del primero (casilla 0) o del segundo (casilla 1), segun (0xE339). Z si son las mismas.
; ----------------------------------------------------------------------
coincide_con_el_modelo:
	exx			;722f
	call caras_del_cubo		;7230
	ld h,a			;7233
	ld d,b			;7234
	ld e,c			;7235
	ld a,(0e339h)		;7236
	or a			;7239
	ld a,(0ec00h)		;723a
	jr z,L_7242		;723d
	ld a,(0ec01h)		;723f
L_7242:
	call caras_del_cubo		;7242
	cp h			;7245
	jr nz,fin_de_la_comparacion		;7246
	ld a,b			;7248
	cp d			;7249
	jr nz,fin_de_la_comparacion		;724a
	ld a,c			;724c
	cp e			;724d
fin_de_la_comparacion:
	exx			;724e
	ret			;724f
caras_del_cubo:		; A, B y C: los colores de la cara de arriba y las dos de lado del cubo A (las casillas 1, 3 y 5 de sus nueve)
	ld b,009h		;7250
	call multiplica		;7252
	push hl			;7255
	ld hl,0eb01h		;7256
	call suma_a_a_hl		;7259
	ld a,(hl)			;725c
	inc hl			;725d
	inc hl			;725e
	ld b,(hl)			;725f
	inc hl			;7260
	inc hl			;7261
	ld c,(hl)			;7262
	pop hl			;7263
	ret			;7264
casilla_debajo:		; A = el cubo de la casilla bajo (E,D), o 0xFF si no hay o se sale por abajo
	ld a,e			;7265
	cp 09ch		;7266
	jr c,L_726D		;7268
	ld a,0ffh		;726a
	ret			;726c
L_726D:
	call casilla_de_la_posicion		;726d
	push hl			;7270
	ld hl,0ec00h		;7271
	call suma_a_a_hl		;7274
	ld a,(hl)			;7277
	pop hl			;7278
	ret			;7279

; ----------------------------------------------------------------------
; DATOS plantilla_de_giro_1: La animacion de los huecos 0-4 (diagonales 1 y
;   2): pares (cuantos, colores) para los 72 bytes de color de sus nueve
;   tiles; cada nibble es 0 o una de las tres caras (1 arriba, 2 y 3 los
;   lados). 0x00 de fin
;   0x727a..0x729f  (37 bytes)
DATA_plantilla_de_giro_1:
	defb 001h,020h	; 727a
	defb 001h,010h	; 727c
	defb 006h,020h	; 727e
	defb 001h,000h	; 7280
	defb 007h,012h	; 7282
	defb 001h,000h	; 7284
	defb 007h,010h	; 7286
	defb 008h,020h	; 7288
	defb 003h,012h	; 728a
	defb 003h,020h	; 728c
	defb 002h,023h	; 728e
	defb 001h,010h	; 7290
	defb 002h,012h	; 7292
	defb 003h,023h	; 7294
	defb 002h,030h	; 7296
	defb 008h,020h	; 7298
	defb 008h,023h	; 729a
	defb 008h,030h	; 729c
	defb 000h	; 729e

; ----------------------------------------------------------------------
; DATOS plantilla_de_giro_2: La de los huecos 5-9 (diagonales 4 y 8)
;   0x729f..0x72c0  (33 bytes)
DATA_plantilla_de_giro_2:
	defb 003h,000h	; 729f
	defb 005h,010h	; 72a1
	defb 003h,000h	; 72a3
	defb 005h,010h	; 72a5
	defb 003h,000h	; 72a7
	defb 005h,030h	; 72a9
	defb 008h,010h	; 72ab
	defb 008h,031h	; 72ad
	defb 008h,030h	; 72af
	defb 004h,010h	; 72b1
	defb 004h,020h	; 72b3
	defb 004h,031h	; 72b5
	defb 001h,021h	; 72b7
	defb 003h,020h	; 72b9
	defb 007h,030h	; 72bb
	defb 001h,020h	; 72bd
	defb 000h	; 72bf

; ----------------------------------------------------------------------
; DATOS giros_de_los_cubos: 24 filas de cuatro: en que giro se convierte cada
;   uno al saltarle encima hacia arriba-izquierda, abajo-derecha,
;   abajo-izquierda y arriba-derecha. Son los 24 giros de un cubo: cada
;   columna es una permutacion y cualquiera se alcanza desde cualquiera en
;   cuatro saltos como mucho (medido recorriendo la tabla)
;   0x72c0..0x7320  (96 bytes)
DATA_giros_de_los_cubos:
	defb 012h,006h,001h,003h	; 72c0
	defb 013h,007h,002h,000h	; 72c4
	defb 014h,008h,003h,001h	; 72c8
	defb 015h,009h,000h,002h	; 72cc
	defb 016h,00ah,013h,009h	; 72d0
	defb 017h,00bh,006h,014h	; 72d4
	defb 000h,00ch,00ah,005h	; 72d8
	defb 001h,00dh,010h,017h	; 72dc
	defb 002h,00eh,016h,011h	; 72e0
	defb 003h,00fh,004h,00bh	; 72e4
	defb 004h,010h,014h,006h	; 72e8
	defb 005h,011h,009h,013h	; 72ec
	defb 006h,012h,00fh,00dh	; 72f0
	defb 007h,013h,00ch,00eh	; 72f4
	defb 008h,014h,00dh,00fh	; 72f8
	defb 009h,015h,00eh,00ch	; 72fc
	defb 00ah,016h,015h,007h	; 7300
	defb 00bh,017h,008h,012h	; 7304
	defb 00ch,000h,011h,016h	; 7308
	defb 00dh,001h,00bh,004h	; 730c
	defb 00eh,002h,005h,00ah	; 7310
	defb 00fh,003h,017h,010h	; 7314
	defb 010h,004h,012h,008h	; 7318
	defb 011h,005h,007h,015h	; 731c

; ======================================================================
; CODIGO 0x7320..0x7328  (8 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LAS CUATRO COMPROBACIONES DEL TABLERO, una por cuadro: las filas, las columnas y las dos diagonales de la cuadricula de 9x9. Se cuentan las lineas con cinco cubos acabados seguidos del mismo jugador (los huecos sin cubo no cortan). La fase se acaba con una linea (dos de la 31 a la 40 y tres de la 41 a la 50); no hace falta acabar todos los cubos.
; ----------------------------------------------------------------------
una_comprobacion_por_turno:
	ld a,(0e003h)		;7320   ; cual de las cuatro, segun el cuadro
	and 003h		;7323
	call reparte_por_tabla		;7325

; ----------------------------------------------------------------------
; DATOS comprobaciones: Las cuatro: filas (0x7330), columnas (0x7353),
;   diagonales de bajada (0x7369) y de subida con el recuento final (0x737D)
;   0x7328..0x7330  (8 bytes)
DATA_comprobaciones:
	defw 07330h,07353h,07369h,0737dh	; 7328  -> cuenta_las_filas cuenta_las_columnas cuenta_las_diagonales_de_bajada cuenta_las_diagonales_de_subida

; ======================================================================
; CODIGO 0x7330..0x7628  (760 bytes)
; ======================================================================


cuenta_las_filas:
	xor a			;7330   ; la cuenta de lineas, desde cero en cada vuelta de cuatro cuadros
	ld (0e320h),a		;7331
	ld hl,0e33ah		;7334   ; cada vuelta cuenta un jugador distinto
	ld a,(hl)			;7337
	xor 001h		;7338
	ld (hl),a			;733a
	ld a,040h		;733b   ; y la mascara de la rutina de 0xE4FD: bit 6 el primero, bit 5 el segundo
	jr z,L_7341		;733d
	ld a,020h		;733f
L_7341:
	ld (0e4feh),a		;7341
	ld hl,0ec00h		;7344
	ld e,009h		;7347
L_7349:
	ld bc,00901h		;7349   ; nueve casillas de una en una, nueve filas
	call cuenta_una_linea		;734c
	dec e			;734f
	jr nz,L_7349		;7350
	ret			;7352
cuenta_las_columnas:
	ld hl,0ec00h		;7353
	ld e,009h		;7356
L_7358:
	ld bc,00909h		;7358   ; nueve casillas de nueve en nueve
	call cuenta_una_linea		;735b
	ld a,l			;735e   ; y a la columna siguiente: 81 - 80
	sub 050h		;735f
	ld l,a			;7361
	jr nc,L_7365		;7362
	dec h			;7364
L_7365:
	dec e			;7365
	jr nz,L_7358		;7366
	ret			;7368
cuenta_las_diagonales_de_bajada:		; De diez en diez (abajo-derecha), desde la primera fila y desde la primera columna
	ld e,00ah		;7369
	ld hl,0ec00h		;736b
	ld bc,00901h		;736e
	call cinco_diagonales		;7371
	ld hl,0ec01h		;7374
	ld bc,00801h		;7377
	jp cuatro_diagonales		;737a
cuenta_las_diagonales_de_subida:		; De ocho en ocho (abajo-izquierda), y luego el recuento
	ld e,008h		;737d
	ld hl,0ec08h		;737f
	ld bc,00901h		;7382
	call cinco_diagonales		;7385
	ld hl,0ec04h		;7388
	ld bc,00500h		;738b
	call cuatro_diagonales		;738e
	ld b,001h		;7391   ; una linea basta...
	ld a,(0e002h)		;7393
	bit 5,a		;7396
	jr nz,L_73A7		;7398
	ld a,(0e111h)		;739a   ; ...hasta la fase 30; dos hasta la 40...
	cp 031h		;739d
	jr c,L_73A7		;739f
	inc b			;73a1
	cp 041h		;73a2   ; ...y tres de la 41 a la 50
	jr c,L_73A7		;73a4
	inc b			;73a6
L_73A7:
	ld a,(0e320h)		;73a7   ; no llega: sigue la fase
	cp b			;73aa
	ret c			;73ab
	ld a,(0e33ah)		;73ac   ; el que no ha hecho la linea...
	or a			;73af
	ld a,(0e202h)		;73b0
	ld hl,0e212h		;73b3
	jr z,L_73BE		;73b6   ; (el otro en el duelo)
	ld a,(0e212h)		;73b8
	ld hl,0e202h		;73bb
L_73BE:
	or a			;73be   ; ...si el ganador aun esta en el aire, se espera
	ret nz			;73bf
	ld a,(hl)			;73c0   ; si el otro esta quieto, pone cara de derrota (8 patrones mas alla)
	or a			;73c1
	jr nz,L_73D9		;73c2
	inc hl			;73c4
	inc hl			;73c5
	inc hl			;73c6
	inc hl			;73c7
	ld a,(hl)			;73c8
	and 0f0h		;73c9
	add a,008h		;73cb
	ld (hl),a			;73cd
	ld a,008h		;73ce
	call suma_a_a_hl		;73d0
	ld a,(hl)			;73d3
	and 0f0h		;73d4
	add a,008h		;73d6
	ld (hl),a			;73d8
L_73D9:
	ld a,(0e002h)		;73d9   ; con un jugador, al acabar una decena sube el nivel del rotulo
	bit 5,a		;73dc
	jr nz,L_73ED		;73de
	ld a,(0e111h)		;73e0
	and 00fh		;73e3
	jr nz,L_73F4		;73e5
	ld hl,0e103h		;73e7
	inc (hl)			;73ea
	jr L_73F4		;73eb
L_73ED:
	call apunta_la_partida_ganada		;73ed   ; en el duelo, se apunta la partida
	xor a			;73f0
	ld (0e00dh),a		;73f1
L_73F4:
	jp espera_a_y_sigue		;73f4   ; y al paso 1 de la partida: fase acabada
cinco_diagonales:
	ld d,005h		;73f7
L_73F9:
	call una_diagonal		;73f9
	ld a,009h		;73fc
	call suma_a_a_hl		;73fe
	dec d			;7401
	jr nz,L_73F9		;7402
	ret			;7404
cuatro_diagonales:
	ld d,004h		;7405
L_7407:
	call una_diagonal		;7407
	inc hl			;740a
	dec d			;740b
	jr nz,L_7407		;740c
	ret			;740e
una_diagonal:
	push bc			;740f
	push de			;7410
	push hl			;7411
	ld c,e			;7412
	call cuenta_una_linea		;7413
	pop hl			;7416
	pop de			;7417
	pop bc			;7418
	ld a,c			;7419   ; C=1 o 9: la linea empieza una casilla mas alla o mas abajo
	or a			;741a
	jr nz,L_741F		;741b
	inc b			;741d
	ret			;741e
L_741F:
	dec b			;741f
	ret			;7420

; ----------------------------------------------------------------------
; CUENTA UNA LINEA: B casillas desde HL, de C en C. D cuenta los acabados seguidos del jugador de turno; un cubo que no es suyo lo pone a cero y un hueco (0xFF) no. Con cinco, una linea mas en (0xE320).
; ----------------------------------------------------------------------
cuenta_una_linea:
	ld d,000h		;7421
L_7423:
	ld a,(hl)			;7423   ; 0xFF: hueco, no corta
	inc a			;7424
	jr z,casilla_siguiente		;7425
	inc d			;7427
	call 0e4fdh		;7428   ; la rutina de 0xE4FD: `and 0x40` o `and 0x20`
	jr nz,L_742E		;742b
	ld d,a			;742d   ; no es suyo: a cero
L_742E:
	ld a,d			;742e
	cp 005h		;742f   ; cinco seguidos
	jr nc,una_linea_mas		;7431
casilla_siguiente:
	ld a,c			;7433
	add a,l			;7434
	ld l,a			;7435
	jr nc,L_7439		;7436
	inc h			;7438
L_7439:
	djnz L_7423		;7439
	ret			;743b
una_linea_mas:
	ld a,(0e320h)		;743c
	inc a			;743f
	ld (0e320h),a		;7440
	ret			;7443

; ----------------------------------------------------------------------
; SALEN LOS BICHOS. Cada 64 cuadros, a cada uno de los quince le baja la espera (el nibble bajo del byte 0); al llegar a cero y si no esta ya en pantalla, entra por arriba sobre uno de los dos cubos de la cima, al azar. Despues la espera vuelve a 15: sale una y otra vez.
; ----------------------------------------------------------------------
salen_los_bichos:
	ld a,(0e003h)		;7444   ; cada 64 cuadros
	and 03fh		;7447
	ret nz			;7449
	ld hl,0e220h		;744a   ; los quince, desde el objeto 4
	ld b,00fh		;744d
L_744F:
	push hl			;744f
	call sale_un_bicho		;7450
	pop hl			;7453
	ld a,008h		;7454
	call suma_a_a_hl		;7456
	djnz L_744F		;7459
	ret			;745b
sale_un_bicho:
	ld a,(hl)			;745c   ; 0x00: este no sale en esta fase
	or a			;745d
	ret z			;745e
	and 00fh		;745f
	or a			;7461
	jr z,L_7466		;7462
	dec (hl)			;7464   ; la espera
	ret nz			;7465
L_7466:
	inc hl			;7466
	inc hl			;7467
	inc hl			;7468
	inc hl			;7469
	ld a,(hl)			;746a   ; si esta en pantalla, espera a que se vaya
	cp 0e0h		;746b
	ret nz			;746d
	ld a,b			;746e   ; la bola gris no sale mientras este el que persigue
	cp 00fh		;746f
	jr nz,L_7479		;7471
	ld a,(0e25ch)		;7473
	cp 0e0h		;7476
	ret nz			;7478
L_7479:
	ld (hl),0f0h		;7479   ; arriba del todo...
	inc hl			;747b   ; ...a la X 0x64 o 0x94 segun R
	ld (hl),064h		;747c
	ld a,r		;747e
	rrca			;7480
	jr c,L_7485		;7481
	ld (hl),094h		;7483
L_7485:
	dec hl			;7485
	dec hl			;7486
	dec hl			;7487
	ld (hl),003h		;7488   ; estado 3: entra por arriba
	dec hl			;748a
	dec hl			;748b
	ld a,(hl)			;748c   ; 0xF0 -> 0xFF: la espera vuelve a 15 cuentas
	rrc a		;748d
	rrc a		;748f
	rrc a		;7491
	rrc a		;7493
	add a,(hl)			;7495
	ld (hl),a			;7496
	ret			;7497

; ----------------------------------------------------------------------
; LOS BICHOS DECIDEN. Cada dos cuadros, los que estan quietos en pantalla gastan su pausa (el nibble alto del byte 1) y al acabarla saltan: el que persigue, hacia Q*bert; el resto, abajo a la izquierda o a la derecha al azar. Los seis de colores se quedan pegados a un cubo cuya cara de arriba es de su color, y el que gira cubos los gira al saltar.
; ----------------------------------------------------------------------
deciden_los_bichos:
	ld a,(0e003h)		;7498   ; cada dos cuadros
	and 001h		;749b
	ret nz			;749d
	ld hl,0e222h		;749e
	ld b,00fh		;74a1
L_74A3:
	push hl			;74a3
	push bc			;74a4
	call decide_un_bicho		;74a5
	pop bc			;74a8
	pop hl			;74a9
	ld a,008h		;74aa
	call suma_a_a_hl		;74ac
	djnz L_74A3		;74af
	ret			;74b1
decide_un_bicho:
	ld a,(hl)			;74b2   ; solo los que estan quietos
	or a			;74b3
	ret nz			;74b4
	inc hl			;74b5
	inc hl			;74b6
	ld a,(hl)			;74b7   ; y en pantalla
	cp 0e0h		;74b8
	ret z			;74ba
	ld a,b			;74bb   ; los seis de colores (objetos 12 a 17)...
	cp 008h		;74bc
	jr nc,L_74CB		;74be
	cp 001h		;74c0
	jr z,L_74CB		;74c2
	push hl			;74c4
	push bc			;74c5
	call mira_el_color_del_cubo		;74c6   ; ...miran el cubo en el que estan
	pop bc			;74c9
	pop hl			;74ca
L_74CB:
	dec hl			;74cb
	dec hl			;74cc
	dec hl			;74cd
	ld a,(hl)			;74ce   ; la pausa: 16 por cuadro de decision
	sub 010h		;74cf
	ld (hl),a			;74d1
	and 0f0h		;74d2
	ret nz			;74d4
	ld a,b			;74d5   ; la bola que bota se echa una pausa al azar
	cp 009h		;74d6
	jr nz,L_74E1		;74d8
	ld a,(0e003h)		;74da
	and 0f0h		;74dd
	add a,(hl)			;74df
	ld (hl),a			;74e0
L_74E1:
	inc hl			;74e1
	ld a,b			;74e2   ; el que persigue (objeto 11) va aparte
	cp 008h		;74e3
	jp z,persigue_a_qbert		;74e5
	push bc			;74e8
	ld c,b			;74e9
	ld a,c			;74ea
	cp 009h		;74eb   ; la bola que bota cambia de dibujo al saltar
	jr nz,L_74F2		;74ed
	call pon_el_paso_b_del_bicho_80		;74ef
L_74F2:
	ld b,002h		;74f2   ; abajo-derecha o...
	ld a,r		;74f4
	rrca			;74f6
	jr c,L_7503		;74f7
	ld a,c			;74f9   ; ...abajo-izquierda
	cp 009h		;74fa
	jr nz,L_7501		;74fc
	call pon_el_paso_a_del_bicho_80		;74fe
L_7501:
	ld b,004h		;7501
L_7503:
	call pon_el_salto		;7503   ; el salto
	pop af			;7506   ; el objeto 9 gira el cubo del que sale
	cp 00ah		;7507
	ret nz			;7509
	jp gira_el_cubo		;750a

; ----------------------------------------------------------------------
; LOS SEIS DE COLORES: si la cara de arriba del cubo en el que estan es de su mismo color, se quedan alli. El bicho se retira, la fila de cinco de 0xE29C corre un puesto y el objeto 23 lo recoge con su color, bajando (estado 5).
; ----------------------------------------------------------------------
mira_el_color_del_cubo:
	ld e,(hl)			;750d
	inc hl			;750e
	ld d,(hl)			;750f
	call casilla_debajo		;7510   ; el cubo de debajo; los acabados no cuentan
	cp 018h		;7513
	ret nc			;7515
	push hl			;7516
	call caras_del_cubo		;7517   ; su cara de arriba contra el color del bicho
	pop hl			;751a
	inc hl			;751b
	inc hl			;751c
	cp (hl)			;751d
	ret nz			;751e
	ld c,(hl)			;751f
	dec hl			;7520
	dec hl			;7521
	dec hl			;7522
	ld a,(hl)			;7523   ; el dibujo, 16 patrones mas alla
	add a,010h		;7524
	ld (hl),a			;7526
	ld de,0e29ch		;7527   ; la fila de cinco de 0xE29C, un puesto
	ld b,005h		;752a
L_752C:
	push hl			;752c
	push bc			;752d
	ld bc,00002h		;752e
	ldir		;7531
	pop bc			;7533
	pop hl			;7534
	ld a,006h		;7535
	call suma_a_a_de		;7537
	djnz L_752C		;753a
	ld (hl),0e0h		;753c   ; el bicho se va
	dec hl			;753e
	dec hl			;753f
	ld (hl),000h		;7540
	ld de,0e2bah		;7542   ; el objeto 23, en el estado 5...
	ld a,005h		;7545
	ld (de),a			;7547
	inc de			;7548
	inc de			;7549   ; ...16 pixeles mas arriba...
	ld a,(de)			;754a
	sub 010h		;754b
	ld (de),a			;754d
	inc de			;754e
	inc de			;754f
	inc de			;7550
	ld a,c			;7551   ; ...con el color del bicho
	ld (de),a			;7552
	ld a,002h		;7553   ; y los objetos 19 a 23 se vuelven a pintar dos veces
	ld (0e328h),a		;7555
	ret			;7558

; ----------------------------------------------------------------------
; EL QUE PERSIGUE (objeto 11): elige la diagonal que le acerca al primer Q*bert; si alli no hay cubo, cualquiera de las que tienen.
; ----------------------------------------------------------------------
persigue_a_qbert:
	inc hl			;7559
	inc hl			;755a
	ld a,(0e204h)		;755b   ; Q*bert mas abajo: diagonales de bajada (2 y 4); si no, de subida (1 y 8)
	ld e,(hl)			;755e
	cp (hl)			;755f
	ld b,006h		;7560
	jr nc,L_7566		;7562
	ld b,009h		;7564
L_7566:
	inc hl			;7566
	ld a,(0e205h)		;7567   ; Q*bert mas a la derecha: 2 y 8; si no, 1 y 4
	ld d,(hl)			;756a
	cp (hl)			;756b
	ld a,00ah		;756c
	jr nc,L_7572		;756e
	ld a,005h		;7570
L_7572:
	and b			;7572   ; la que acerca en las dos cosas
	ld c,a			;7573
	call diagonales_con_cubo		;7574   ; las que tienen cubo
	ld b,a			;7577
	and c			;7578   ; si la buena no tiene, cualquiera de las otras
	jr z,L_757C		;7579
	ld b,a			;757b
L_757C:
	ld hl,0e25ah		;757c
	call bit_mas_bajo		;757f
	jp pon_el_salto		;7582
diagonales_con_cubo:		; B: bit 0 arriba-izquierda (casilla - 10), bit 3 arriba-derecha (- 8), bit 2 abajo-izquierda (+ 8), bit 1 abajo-derecha (+ 10)
	call casilla_de_la_posicion		;7585
	sub 00ah		;7588
	ld hl,0ec00h		;758a
	call suma_a_a_hl		;758d
	ld b,000h		;7590
	ld a,(hl)			;7592
	inc a			;7593
	jr z,L_7597		;7594
	inc b			;7596
L_7597:
	inc hl			;7597
	inc hl			;7598
	ld a,(hl)			;7599
	inc a			;759a
	jr z,L_75A1		;759b
	ld a,b			;759d
	or 008h		;759e
	ld b,a			;75a0
L_75A1:
	ld de,00010h		;75a1
	add hl,de			;75a4
	ld a,(hl)			;75a5
	inc a			;75a6
	jr z,L_75AD		;75a7
	ld a,b			;75a9
	or 004h		;75aa
	ld b,a			;75ac
L_75AD:
	inc hl			;75ad
	inc hl			;75ae
	ld a,(hl)			;75af
	inc a			;75b0
	ld a,b			;75b1
	ret z			;75b2
	or 002h		;75b3
	ret			;75b5

; ----------------------------------------------------------------------
; LOS CHOQUES DE Q*BERT con los quince objetos. Mientras los bichos huyen (0xE329), no se mira nada. Un Q*bert que entra, cae o esta fuera (estados 3, 4 y 14) no choca.
; ----------------------------------------------------------------------
mira_los_choques:
	ld a,(0e329h)		;75b6   ; huyendo: se espera a que no quede ninguno en los estados 6-11
	or a			;75b9
	jr z,choques_de_los_dos		;75ba
	ld hl,0e222h		;75bc
	ld b,00fh		;75bf
L_75C1:
	ld a,(hl)			;75c1
	cp 006h		;75c2
	jr c,L_75C9		;75c4
	cp 00ch		;75c6
	ret c			;75c8
L_75C9:
	ld a,008h		;75c9
	call suma_a_a_hl		;75cb
	djnz L_75C1		;75ce
	xor a			;75d0
	ld (0e329h),a		;75d1
	ret			;75d4
choques_de_los_dos:
	ld de,(0e204h)		;75d5   ; el primero
	xor a			;75d9
	ld (0e332h),a		;75da
	ld a,(0e202h)		;75dd
	cp 003h		;75e0
	jr z,L_75EF		;75e2
	cp 004h		;75e4
	jr z,L_75EF		;75e6
	cp 00eh		;75e8
	jr z,L_75EF		;75ea
	call choca_con_los_objetos		;75ec
L_75EF:
	ld a,(0e002h)		;75ef
	bit 5,a		;75f2
	ret z			;75f4
	ld de,(0e214h)		;75f5   ; el segundo, en el duelo
	ld a,001h		;75f9
	ld (0e332h),a		;75fb
	ld a,(0e212h)		;75fe
	cp 003h		;7601
	ret z			;7603
	cp 004h		;7604
	ret z			;7606
	cp 00eh		;7607
	ret z			;7609
choca_con_los_objetos:
	ld hl,0e224h		;760a
	ld b,00fh		;760d
L_760F:
	push hl			;760f
	push bc			;7610
	call choca_con_un_objeto		;7611
	pop bc			;7614
	pop hl			;7615
	ld a,008h		;7616
	call suma_a_a_hl		;7618
	djnz L_760F		;761b
	ret			;761d
choca_con_un_objeto:
	call estan_cerca		;761e   ; a menos de 10 en Y y de 8 en X
	ret nc			;7621
	push hl			;7622
	ld a,b			;7623   ; y cada objeto hace lo suyo: la tabla va por su numero
	dec a			;7624
	call reparte_por_tabla		;7625

; ----------------------------------------------------------------------
; DATOS que_hace_cada_objeto: Quince entradas del objeto 18 al 4:
;   invencibilidad (0x76DF), los ocho enemigos que matan (0x76F0), el que gira
;   cubos (0x77D7), la bola roja (0x77A9), frenar (0x778A), acelerar (0x776E),
;   la bola verde (0x775A) y la bola gris (0x77C0)
;   0x7628..0x7646  (30 bytes)
DATA_que_hace_cada_objeto:
	defw 076dfh,076f0h,076f0h,076f0h,076f0h,076f0h,076f0h,076f0h	; 7628
	defw 076f0h,077d7h,077a9h,0778ah,0776eh,0775ah,077c0h	; 7638

; ======================================================================
; CODIGO 0x7646..0x7949  (771 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL CHOQUE DE LOS DOS Q*BERT DEL DUELO. Si uno esta en el aire y el otro no, el de tierra sale rebotado; si estan los dos quietos, los dos. Diez cuadros sin volver a mirar.
; ----------------------------------------------------------------------
choque_entre_los_dos:
	ld a,(0e002h)		;7646
	bit 5,a		;7649
	ret z			;764b
	ld hl,0e344h		;764c   ; la espera entre choques
	ld a,(hl)			;764f
	or a			;7650
	jr z,L_7655		;7651
	dec (hl)			;7653
	ret			;7654
L_7655:
	ld de,(0e204h)		;7655
	ld hl,0e214h		;7659
	call estan_cerca		;765c
	ret nc			;765f
	xor a			;7660
	ld (0e342h),a		;7661
	ld b,000h		;7664   ; B: bit 0, el primero esta en el aire; bit 1, el segundo
	ld a,(0e202h)		;7666
	or a			;7669
	jr z,L_766E		;766a
	set 0,b		;766c
L_766E:
	ld a,(0e212h)		;766e
	or a			;7671
	jr z,L_7676		;7672
	set 1,b		;7674
L_7676:
	ld a,b			;7676
	call como_viene_el_que_salta		;7677
	ld a,b			;767a
	cp 003h		;767b   ; los dos en el aire: nada
	ret z			;767d
	or a			;767e
	jr z,se_empujan_los_dos		;767f   ; los dos quietos
	cp 002h		;7681   ; el que esta en el aire empuja al otro
	jr nz,L_7687		;7683
	ld a,000h		;7685
L_7687:
	ld (0e332h),a		;7687
	jp rebota		;768a
como_viene_el_que_salta:		; (0xE338): bit 0, va hacia la derecha; bit 1, esta en la segunda mitad del arco
	ld c,000h		;768d
	cp 002h		;768f
	ld hl,0e212h		;7691
	jr z,L_7699		;7694
	ld hl,0e202h		;7696
L_7699:
	ld a,(hl)			;7699
	dec a			;769a
	jr z,L_769F		;769b
	set 0,c		;769d
L_769F:
	inc hl			;769f
	ld a,(hl)			;76a0
	cp 032h		;76a1
	jr c,L_76A7		;76a3
	set 1,c		;76a5
L_76A7:
	ld a,c			;76a7
	ld (0e338h),a		;76a8
	ret			;76ab
se_empujan_los_dos:
	ld a,00ah		;76ac
	ld (0e344h),a		;76ae
	ld a,(0e202h)		;76b1   ; hacia arriba o hacia abajo segun hacia donde miraba cada uno
	ld b,002h		;76b4
	dec a			;76b6
	jr nz,L_76BB		;76b7
	ld b,004h		;76b9
L_76BB:
	push bc			;76bb
	call salta_el_primero		;76bc
	pop bc			;76bf
	ld a,b			;76c0
	ld b,002h		;76c1
	cp 002h		;76c3
	jr nz,L_76C9		;76c5
	ld b,004h		;76c7
L_76C9:
	jp salta_el_segundo		;76c9
estan_cerca:		; Acarreo si |E - (HL)| < 10 y |D - (HL+1)| < 8
	ld a,e			;76cc
	sub (hl)			;76cd
	jr nc,L_76D2		;76ce
	neg		;76d0
L_76D2:
	cp 00ah		;76d2
	ret nc			;76d4
	inc hl			;76d5
	ld a,d			;76d6
	sub (hl)			;76d7
	jr nc,L_76DC		;76d8
	neg		;76da
L_76DC:
	cp 008h		;76dc
	ret			;76de
coge_la_invencibilidad:		; 128 cuentas de cuatro cuadros intocable (0xE345 o 0xE346), y 100 puntos
	pop hl			;76df
	call retira_con_cien_puntos		;76e0
	ld a,(0e332h)		;76e3
	ld hl,0e345h		;76e6
	or a			;76e9
	jr z,L_76ED		;76ea
	inc hl			;76ec
L_76ED:
	ld (hl),080h		;76ed
	ret			;76ef

; ----------------------------------------------------------------------
; LOS OCHO QUE MATAN. Si Q*bert es invencible, el bicho cae muerto; si acaba de entrar, no pasa nada; y si no, cae Q*bert.
; ----------------------------------------------------------------------
choca_con_un_enemigo:
	pop hl			;76f0
	ld a,(0e332h)		;76f1
	ld de,0e345h		;76f4
	or a			;76f7
	jr z,L_76FB		;76f8
	inc de			;76fa
L_76FB:
	ld a,(de)			;76fb   ; invencible
	or a			;76fc
	jr z,mira_la_proteccion		;76fd
	dec hl			;76ff
	dec hl			;7700
	dec hl			;7701
	ld a,(hl)			;7702   ; el bicho, si no esta ya cayendo muerto, cae
	cp 00ch		;7703
	ret z			;7705
	cp 00dh		;7706
	ret z			;7708
	call cae_muerto_hl		;7709
	ld a,007h		;770c
	jp toca_sonido		;770e
mira_la_proteccion:
	ld a,(0e332h)		;7711
	or a			;7714
	ld hl,0e336h		;7715
	jr z,L_771B		;7718
	inc hl			;771a
L_771B:
	ld a,(hl)			;771b   ; recien entrado: intocable
	or a			;771c
	ret nz			;771d
	ld a,(0e002h)		;771e
	bit 5,a		;7721
	jr z,L_7728		;7723
	jp cae_qbert		;7725
L_7728:
	call cae_qbert		;7728
	xor a			;772b
	ld (0e113h),a		;772c
	ret			;772f
cae_qbert:
	ld a,(0e332h)		;7730   ; el que choca, sus dos sprites
	or a			;7733
	ld hl,0e202h		;7734
	jr z,L_773C		;7737
	ld hl,0e212h		;7739
L_773C:
	call cae_muerto_hl		;773c
	ld a,007h		;773f
	call suma_a_a_hl		;7741
	ld a,b			;7744
	call pon_estado_y_arco_de_caer		;7745
	ld a,013h		;7748   ; el sonido 0x13
	jp toca_sonido		;774a
cae_muerto_hl:		; Estado 12 o 13 (hacia un lado u otro segun el cuadro) y el arco de caer, 0x64
	ld a,(0e003h)		;774d
	and 001h		;7750
	add a,00ch		;7752
	ld b,a			;7754
pon_estado_y_arco_de_caer:
	ld (hl),a			;7755
	inc hl			;7756
	ld (hl),064h		;7757
	ret			;7759

; ----------------------------------------------------------------------
; LA BOLA VERDE: 128 cuentas de cuatro cuadros con todo quieto menos los Q*bert, y el sonido 0x0D.
; ----------------------------------------------------------------------
coge_la_bola_verde:
	pop hl			;775a
	call retira_con_cien_puntos		;775b
	ld a,080h		;775e
	ld (0e321h),a		;7760
	ld hl,000bch		;7763   ; HL=0x00BC: 0x6E2F escribe en 0x00BC y 0x00BA, que son la ROM de la BIOS, y no pasa nada. Tiene toda la pinta de que iba a 0xE2BC, el objeto 23 (SUPOSICION: el `ld hl` perdio el 0xE2)
	call retira_y_repinta_la_fila		;7766
	ld a,00dh		;7769
	jp toca_sonido		;776b
coge_la_de_acelerar:		; Un paso mas del arco por cuadro, en los dos sprites
	pop hl			;776e
	call retira_con_cien_puntos		;776f
	ld a,(0e332h)		;7772
	or a			;7775
	ld hl,0e201h		;7776
	jr z,L_777E		;7779
	ld hl,0e211h		;777b
L_777E:
	inc (hl)			;777e
	ld a,008h		;777f
	call suma_a_a_hl		;7781
	inc (hl)			;7784
	ld a,00ah		;7785
	jp toca_sonido		;7787
coge_la_de_frenar:		; Un paso menos, sin bajar de uno
	pop hl			;778a
	call retira_con_cien_puntos		;778b
	ld a,(0e332h)		;778e
	or a			;7791
	ld hl,0e201h		;7792
	jr z,L_779A		;7795
	ld hl,0e211h		;7797
L_779A:
	ld a,(hl)			;779a
	or a			;779b
	ret z			;779c
	dec (hl)			;779d
	ld a,008h		;779e
	call suma_a_a_hl		;77a0
	dec (hl)			;77a3
	ld a,00bh		;77a4
	jp toca_sonido		;77a6
coge_la_bola_roja:		; El salto largo (disparo mientras se salta) y Q*bert en blanco
	pop hl			;77a9
	call retira_con_cien_puntos		;77aa
	ld a,(0e332h)		;77ad
	or a			;77b0
	ld hl,0e322h		;77b1
	jr z,L_77B9		;77b4
	ld hl,0e331h		;77b6
L_77B9:
	ld (hl),001h		;77b9
	ld a,00ah		;77bb
	jp toca_sonido		;77bd
coge_la_bola_gris:		; Todos los bichos huyen
	pop hl			;77c0
	call retira_con_cien_puntos		;77c1
	ld a,00ch		;77c4
	call toca_sonido		;77c6
	jp huyen_todos		;77c9
pon_c_en_catorce_objetos:
	ld b,00eh		;77cc   ; CODIGO HUERFANO: C en el mismo byte de catorce objetos seguidos, de 8 en 8. Nadie lo llama
L_77CE:
	ld (hl),c			;77ce
	ld a,008h		;77cf
	call suma_a_a_hl		;77d1
	djnz L_77CE		;77d4
	ret			;77d6
coge_el_que_gira_cubos:		; 100 puntos y fuera
	pop hl			;77d7
retira_con_cien_puntos:		; El objeto fuera de la pantalla y quieto, y 100 puntos
	dec hl			;77d8
	ld (hl),0e0h		;77d9
	dec hl			;77db
	dec hl			;77dc
	ld (hl),000h		;77dd
	ld de,00100h		;77df
	jp suma_puntos		;77e2

; ----------------------------------------------------------------------
; TODOS HUYEN: los trece del objeto 5 al 17 que esten en pantalla pasan a los estados 6-11, mas deprisa cuanto mas abajo esten (Y 0x30 y 0x60 de corte) y hacia el lado donde esten (X 0x80).
; ----------------------------------------------------------------------
huyen_todos:
	ld hl,0e22ch		;77e5
	ld b,00dh		;77e8
L_77EA:
	ld c,000h		;77ea
	ld a,(hl)			;77ec
	inc hl			;77ed
	cp 0e0h		;77ee   ; fuera de la pantalla: quieto
	jr z,L_7806		;77f0
	ld c,006h		;77f2   ; arriba: 6, cada 8 cuadros
	cp 030h		;77f4
	jr c,L_7800		;77f6
	inc c			;77f8   ; en medio: 8, cada 4
	inc c			;77f9
	cp 060h		;77fa
	jr c,L_7800		;77fc
	inc c			;77fe   ; abajo: 10, cada 2
	inc c			;77ff
L_7800:
	ld a,(hl)			;7800   ; en la mitad de la derecha, uno mas
	cp 080h		;7801
	jr c,L_7806		;7803
	inc c			;7805
L_7806:
	ld a,001h		;7806   ; mientras huyen no hay choques
	ld (0e329h),a		;7808
	dec hl			;780b
	dec hl			;780c
	dec hl			;780d
	ld (hl),c			;780e
	ld a,00ah		;780f
	call suma_a_a_hl		;7811
	djnz L_77EA		;7814
	ret			;7816
tiempo_a_99:
	ld hl,00099h		;7817
	ld (0ec51h),hl		;781a
	ret			;781d
corre_el_tiempo:
	call un_segundo_menos		;781e
	ld a,(0e001h)		;7821   ; y lo pinta, salvo en el piedra-papel-tijera
	cp 006h		;7824
	ret nc			;7826
	jr pinta_el_tiempo		;7827
un_segundo_menos:
	ld hl,(0ec51h)		;7829
	ld a,(0e003h)		;782c   ; cada 64 cuadros
	and 03fh		;782f
	ret nz			;7831
	call resta_uno_al_tiempo		;7832
	ld a,h			;7835   ; a cero: se acabo el tiempo
	or l			;7836
	ret nz			;7837
	push hl			;7838
	call pinta_el_tiempo		;7839
	call vuelca_la_pantalla		;783c
	ld a,035h		;783f   ; el sonido 0x35
	call toca_sonido		;7841
	call espera_un_rato		;7844
	pop hl			;7847
	ld a,(0e002h)		;7848   ; en el duelo, gana el que tenga mas cubos
	bit 5,a		;784b
	jp nz,se_acabo_el_tiempo_del_duelo		;784d
	xor a			;7850   ; con uno, Q*bert fuera: 0x4291 vera el tiempo a cero
	ld (0e113h),a		;7851
	ret			;7854
resta_uno_al_tiempo:
	ld hl,(0ec51h)		;7855
	ld a,l			;7858
	sub 001h		;7859
	daa			;785b
	ld l,a			;785c
	jr nc,L_7862		;785d
	ld hl,00000h		;785f
L_7862:
	ld (0ec51h),hl		;7862
	ex de,hl			;7865
	ld hl,00010h		;7866   ; por debajo de 10...
	or a			;7869
	sbc hl,de		;786a
	ex de,hl			;786c
	ret c			;786d
	ld a,(0e334h)		;786e
	or a			;7871
	ret nz			;7872
	ld a,010h		;7873   ; ...el aviso, 0x10
	jp toca_sonido		;7875
pinta_el_tiempo:		; TIME-nn en la fila 2, columna 23 de la copia de la tabla de nombres
	ex de,hl			;7878
	ld hl,0ed57h		;7879
	ld (hl),034h		;787c
	inc hl			;787e
	ld (hl),029h		;787f
	inc hl			;7881
	ld (hl),02dh		;7882
	inc hl			;7884
	ld (hl),025h		;7885
	inc hl			;7887
	ld (hl),020h		;7888
	ld a,e			;788a
	and 0f0h		;788b
	rrca			;788d
	rrca			;788e
	rrca			;788f
	rrca			;7890
	add a,010h		;7891
	inc hl			;7893
	ld (hl),a			;7894
	ld a,e			;7895
	and 00fh		;7896
	add a,010h		;7898
	inc hl			;789a
	ld (hl),a			;789b
	ret			;789c

; ----------------------------------------------------------------------
; LA FASE DE BONIFICACION. Q*bert se queda en cada cubo y los saltos giran el cubo en vez de moverle; al acabarlo pasa al siguiente. Al final, cada cubo acabado se cuenta en pantalla con sus puntos (100, 200, 300...), y con los 27 sale PERFECT 5000 POINT.
; ----------------------------------------------------------------------
paso_de_la_bonificacion:
	djnz L_78AE		;789d   ; paso 1: espera
	ld hl,0e004h		;789f
	dec (hl)			;78a2
	ret nz			;78a3
	ld a,019h		;78a4   ; 25 filas por destapar, cada tres cuadros
	ld (0e324h),a		;78a6
	ld a,003h		;78a9
	jp espera_a_y_sigue		;78ab
L_78AE:
	djnz L_78ED		;78ae   ; paso 2: se destapa la pantalla de arriba abajo
	ld hl,0e004h		;78b0
	dec (hl)			;78b3
	ret nz			;78b4
	ld (hl),003h		;78b5
	ld hl,0e324h		;78b7
	dec (hl)			;78ba
	jp z,empieza_la_bonificacion		;78bb
	ld a,(hl)			;78be   ; la fila que toca
	dec a			;78bf
	sub 017h		;78c0
	neg		;78c2
	ld hl,00020h		;78c4
	ld b,a			;78c7
	call multiplica_hl		;78c8
	ld de,03800h		;78cb   ; desde la copia de la tabla de nombres
	add hl,de			;78ce
	push hl			;78cf
	ld de,0b500h		;78d0
	add hl,de			;78d3
	ex de,hl			;78d4
	pop hl			;78d5
	ld bc,00020h		;78d6
	jp copia_a_vram		;78d9
empieza_la_bonificacion:
	call pinta_el_marcador		;78dc   ; el marcador, BONUS arriba y su musica, 0x1A
	ld de,079a3h		;78df
	call pinta_guion		;78e2
	ld a,01ah		;78e5
	call toca_sonido		;78e7
	jp espera_a_y_sigue		;78ea
L_78ED:
	djnz L_7901		;78ed   ; paso 3: el juego
	call pon_los_sprites		;78ef
	call vuelca_un_cuarto_de_la_pantalla		;78f2
	call tiempo_de_la_bonificacion		;78f5   ; el tiempo, de 16 en 16 cuadros
	call gira_el_cubo_de_qbert		;78f8   ; los giros del cubo de Q*bert
	call cubos_que_giran		;78fb
	jp pasa_al_siguiente_cubo		;78fe   ; y al acabarlo, el siguiente
L_7901:
	djnz $+93		;7901   ; paso 4: la cuenta
	call vuelca_la_pantalla		;7903
	ld hl,0e004h		;7906
	dec (hl)			;7909
	ret nz			;790a
	ld (hl),010h		;790b
	call cuenta_un_cubo		;790d   ; busca el siguiente cubo acabado y le pone su numero
	ld hl,0e325h		;7910
	or a			;7913
	jr nz,acaba_la_cuenta		;7914
	push hl			;7916   ; el numero por cien, en puntos
	ld d,(hl)			;7917
	ld e,000h		;7918
	call suma_puntos		;791a
	pop hl			;791d
	ld a,(hl)			;791e   ; y uno mas
	add a,001h		;791f
	daa			;7921
	ld (hl),a			;7922
	ret			;7923
acaba_la_cuenta:
	ld a,(hl)			;7924   ; 28: los 27 cubos
	cp 028h		;7925
	jr nz,L_793C		;7927
	ld de,07949h		;7929   ; PERFECT 5000 POINT
	call pinta_guion		;792c
	ld de,05000h		;792f
	call suma_puntos		;7932
	ld a,032h		;7935
	call toca_sonido		;7937
	jr L_7941		;793a
L_793C:
	ld a,059h		;793c   ; si no, silencio
	call toca_sonido		;793e
L_7941:
	ld a,001h		;7941
	ld (0e334h),a		;7943
	jp espera_a_y_sigue		;7946

; ----------------------------------------------------------------------
; DATOS rotulo_perfect: Guion de 0x4685: "PERFECT 5000 POINT" en 0x3AC7
;   0x7949..0x795e  (21 bytes)
DATA_rotulo_perfect:
	defb 0c7h,03ah,030h,025h,032h,026h,025h,023h,034h,000h,015h,010h,010h,010h,000h,030h,02fh,029h,02eh,034h,0ffh	; 7949  .:0%2&%#4......0/).4.

; ======================================================================
; CODIGO 0x795e..0x7999  (59 bytes)
; ======================================================================


L_795E:
	djnz L_796A		;795e   ; paso 5: la musica
	ld a,(0e012h)		;7960
	or a			;7963
	ret nz			;7964
	ld a,001h		;7965
	jp espera_a_y_sigue		;7967
L_796A:
	djnz L_7980		;796a   ; paso 6: cobra el tiempo que sobra
	call vuelca_un_cuarto_de_la_pantalla		;796c
	call cobra_el_tiempo		;796f
	ret nz			;7972
	xor a			;7973   ; fase acabada
	ld (0e334h),a		;7974
	ld a,001h		;7977
	ld (0e00dh),a		;7979
	ld (0e320h),a		;797c
	ret			;797f
L_7980:
	call esconde_los_sprites		;7980   ; paso 0: la pantalla entera de ladrillo y BONUS en medio
	ld hl,03800h		;7983
	ld bc,00300h		;7986
	ld a,0ebh		;7989
	call 00056h		;798b   ; BIOS FILVRM - Fills VRAM with value
	ld de,07999h		;798e
	call pinta_guion		;7991
	ld a,050h		;7994
	jp espera_a_y_sigue		;7996

; ----------------------------------------------------------------------
; DATOS rotulos_bonus: Guiones de 0x4685: " BONUS " en 0x396C y "BONUS" con
;   tres ladrillos en 0x3802 (el de 0x79A3)
;   0x7999..0x79ae  (21 bytes)
DATA_rotulos_bonus:
	defb 06ch,039h,000h,022h,02fh,02eh,035h,033h,000h,0ffh	; 7999  l9."/.53..
	defb 002h,038h,022h,02fh,02eh,035h,033h,0ebh,0ebh,0ebh,0ffh	; 79a3  .8"/.53....

; ======================================================================
; CODIGO 0x79ae..0x7b41  (403 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; TOCA BONIFICACION? Detras de las fases 3, 6 y 10 de cada decena (13, 16, 20...), el bit 0 de 0xE002 se enciende, se carga el tablero de 0xA7AD y la escena 5 corre la bonificacion. Al volver aqui se apaga y sigue la fase normal.
; ----------------------------------------------------------------------
mira_la_bonificacion:
	ld a,(0e111h)		;79ae
	sub 001h		;79b1   ; las unidades de la fase que se acaba, menos una
	daa			;79b3
	and 00fh		;79b4
	cp 002h		;79b6
	jr z,L_79C1		;79b8
	cp 005h		;79ba
	jr z,L_79C1		;79bc
	cp 009h		;79be
	ret nz			;79c0
L_79C1:
	ld hl,0e002h		;79c1
	ld a,(hl)			;79c4   ; cambia el bit 0
	xor 001h		;79c5
	ld (hl),a			;79c7
	rrca			;79c8
	ret nc			;79c9
	pop hl			;79ca   ; toca: esta llamada no vuelve a 0x43F4
	call tablero_de_bonificacion		;79cb
	call monta_la_fase_con_el_tablero_puesto		;79ce   ; el tablero de bonificacion...
	ld hl,0e000h		;79d1   ; ...y a la partida
	ld (hl),005h		;79d4
	ret			;79d6

; ----------------------------------------------------------------------
; COBRA EL TIEMPO: un segundo por llamada, 10 puntos cada uno y el sonido 0x15. NZ mientras quede; Z al acabar, con el sonido 0x16.
; ----------------------------------------------------------------------
cobra_el_tiempo:
	ld hl,(0ec51h)		;79d7
	ld a,l			;79da
	or a			;79db
	jr z,acaba_de_cobrar		;79dc
	ld a,001h		;79de
	ld (0e334h),a		;79e0
	call resta_uno_al_tiempo		;79e3
	call pinta_el_tiempo		;79e6
	ld de,00010h		;79e9
	call suma_puntos		;79ec
	ld a,(0e072h)		;79ef
	or a			;79f2
	ld a,015h		;79f3
	call z,toca_sonido		;79f5
	or a			;79f8
	ret nz			;79f9
	inc a			;79fa
	ret			;79fb
acaba_de_cobrar:
	ld a,016h		;79fc
	call toca_sonido		;79fe
	call vuelca_la_pantalla		;7a01
espera_al_efecto:
	ld a,(0e072h)		;7a04   ; hasta que calle el canal de efectos
	or a			;7a07
	jr nz,espera_al_efecto		;7a08
	ret			;7a0a
tablero_de_bonificacion:		; Los 81 bytes de 0xA7AD a 0xEC00
	ld hl,0a7adh		;7a0b
	ld de,0ec00h		;7a0e
	ld bc,00051h		;7a11
	ldir		;7a14
	ret			;7a16
tiempo_de_la_bonificacion:
	call resta_cada_16_cuadros		;7a17
	jp pinta_el_tiempo		;7a1a
resta_cada_16_cuadros:
	ld hl,(0ec51h)		;7a1d
	ld a,(0e003h)		;7a20
	and 00fh		;7a23
	ret nz			;7a25
	call resta_uno_al_tiempo		;7a26
	ld a,h			;7a29
	or l			;7a2a
	ret nz			;7a2b
acaba_el_juego_de_la_bonificacion:
	ld a,001h		;7a2c   ; la cuenta empieza en 1
	ld (0e325h),a		;7a2e
	ex de,hl			;7a31
	call espera_a_y_sigue		;7a32
	ex de,hl			;7a35
	ret			;7a36
gira_el_cubo_de_qbert:		; La diagonal pulsada gira el cubo sobre el que esta Q*bert, sin moverle
	call diagonal_del_primero		;7a37
	ld a,b			;7a3a
	or a			;7a3b
	ret z			;7a3c
	call bit_mas_bajo		;7a3d
	call posicion_de_qbert		;7a40
	call gira_el_cubo		;7a43
	ret			;7a46
pasa_al_siguiente_cubo:
	call posicion_de_qbert		;7a47
	call casilla_debajo		;7a4a   ; el cubo de Q*bert: si no esta acabado, nada
	and 040h		;7a4d
	ret z			;7a4f
	call posicion_de_qbert		;7a50
busca_el_siguiente:
	ld a,d			;7a53   ; tres columnas a la derecha...
	add a,018h		;7a54
	ld d,a			;7a56
	cp 0f0h		;7a57
	jr c,L_7A65		;7a59
	ld d,01ch		;7a5b   ; ...y al acabar la fila, la siguiente desde la primera columna
	ld a,e			;7a5d
	add a,010h		;7a5e
	ld e,a			;7a60
	cp 09ch		;7a61   ; no quedan: se acaba el juego
	jr nc,acaba_el_juego_de_la_bonificacion		;7a63
L_7A65:
	call casilla_debajo		;7a65   ; hasta dar con un cubo
	inc a			;7a68
	jr z,busca_el_siguiente		;7a69
	ld (hl),d			;7a6b   ; Q*bert alli, los dos sprites
	dec hl			;7a6c
	ld (hl),e			;7a6d
	ld hl,0e20ch		;7a6e
	ld (hl),e			;7a71
	inc hl			;7a72
	ld (hl),d			;7a73
	ret			;7a74
posicion_de_qbert:		; E = su Y, D = su X
	ld hl,0e204h		;7a75
	ld e,(hl)			;7a78
	inc hl			;7a79
	ld d,(hl)			;7a7a
	ret			;7a7b

; ----------------------------------------------------------------------
; CUENTA UN CUBO: busca en la copia de la tabla de nombres el tile 0x88 (la esquina del cubo acabado) y pone encima el numero de la cuenta y dos ceros: los puntos que da. A=1 si no queda ninguno.
; ----------------------------------------------------------------------
cuenta_un_cubo:
	ld hl,0ed63h		;7a7c
L_7A7F:
	ld a,(hl)			;7a7f
	cp 088h		;7a80
	jr z,pone_los_puntos		;7a82
	inc hl			;7a84
	ld a,l			;7a85
	ld b,020h		;7a86
	call divide		;7a88
	ld a,b			;7a8b
	cp 01eh		;7a8c
	jr c,L_7A7F		;7a8e
	ld de,00025h		;7a90
	add hl,de			;7a93   ; la fila siguiente
	push hl			;7a94
	ld de,0efa3h		;7a95   ; hasta la fila 21
	sbc hl,de		;7a98
	pop hl			;7a9a
	jr nz,L_7A7F		;7a9b
	ld a,001h		;7a9d
	ret			;7a9f
pone_los_puntos:
	ld a,(0e325h)		;7aa0   ; la cuenta en BCD: la decena (en blanco si es cero)...
	ld b,a			;7aa3
	and 0f0h		;7aa4
	rrca			;7aa6
	rrca			;7aa7
	rrca			;7aa8
	rrca			;7aa9
	or a			;7aaa
	jr z,L_7AAF		;7aab
	add a,010h		;7aad
L_7AAF:
	ld (hl),a			;7aaf
	inc hl			;7ab0
	ld a,b			;7ab1   ; ...la unidad y 00
	and 00fh		;7ab2
	add a,010h		;7ab4
	ld (hl),a			;7ab6
	inc hl			;7ab7
	ld (hl),010h		;7ab8
	inc hl			;7aba
	ld (hl),010h		;7abb
	xor a			;7abd
	ret			;7abe

; ----------------------------------------------------------------------
; EL MARCO: los 13 tiles de ladrillo y de pinchos (0xEB-0xF7) con su color, y en la copia de la tabla de nombres las filas de arriba y abajo y las columnas de los lados de ladrillo, con una fila y una columna de pinchos por dentro.
; ----------------------------------------------------------------------
monta_el_marco:
	ld hl,02758h		;7abf   ; los patrones de 0xEB a 0xF7
	ld de,07ba5h		;7ac2
	ld bc,00068h		;7ac5
	call copia_a_los_tres_bancos		;7ac8
	ld hl,00758h		;7acb   ; y sus colores
	ld de,07c0dh		;7ace
	call guion_rle_en_tres_bancos		;7ad1
	ld hl,0ed00h		;7ad4   ; la fila 0 y la 23 (0xEFE0), de ladrillo
	call fila_de_ladrillo		;7ad7
	ld hl,0efe0h		;7ada
	call fila_de_ladrillo		;7add
	ld hl,0ed20h		;7ae0   ; la columna 0 y la 31, de la fila 1 a la 22
	call columna_de_ladrillo		;7ae3
	ld hl,0ed3fh		;7ae6
	call columna_de_ladrillo		;7ae9
	ld hl,0ed21h		;7aec   ; la fila 1 de pinchos
	ld de,07b41h		;7aef
	call fila_de_pinchos		;7af2
	ld hl,0efc1h		;7af5   ; y la 22
	ld de,07b5fh		;7af8
	call fila_de_pinchos		;7afb
	ld hl,0ed41h		;7afe   ; la columna 1
	ld de,07b7dh		;7b01
	call columna_de_pinchos		;7b04
	ld hl,0ed5eh		;7b07   ; y la 30
	ld de,07b91h		;7b0a
	jp columna_de_pinchos		;7b0d
fila_de_pinchos:
	ld bc,01e01h		;7b10
	jr copia_los_pinchos		;7b13
columna_de_pinchos:
	ld bc,01420h		;7b15
copia_los_pinchos:
	ld a,(de)			;7b18
	ld (hl),a			;7b19
	inc de			;7b1a
	ld a,c			;7b1b
	call suma_a_a_hl		;7b1c
	djnz copia_los_pinchos		;7b1f
	ret			;7b21
fila_de_ladrillo:
	ld bc,020ebh		;7b22
	ld d,001h		;7b25
	jr pon_el_ladrillo		;7b27
columna_de_ladrillo:
	ld bc,016ebh		;7b29
	ld d,020h		;7b2c
pon_el_ladrillo:
	ld (hl),c			;7b2e
	ld a,d			;7b2f
	call suma_a_a_hl		;7b30
	djnz pon_el_ladrillo		;7b33
	ret			;7b35
fila_0_de_ladrillo:		; Directamente en la VRAM
	ld hl,03800h		;7b36
	ld bc,00020h		;7b39
	ld a,0ebh		;7b3c
	jp 00056h		;7b3e   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; DATOS pinchos_del_marco: Los tiles de las cuatro tiras de pinchos: 30 de la
;   fila de arriba, 30 de la de abajo y 20 de cada columna
;   0x7b41..0x7ba5  (100 bytes)
DATA_pinchos_del_marco:
	defb 000h,0ech,0edh,0f0h,0f1h,0f4h,0f5h,0ech,0edh,0f0h	; 7b41  ..........
	defb 0f1h,0f4h,0f5h,0ech,0edh,0f0h,0f1h,0f4h,0f5h,0ech	; 7b4b  ..........
	defb 0edh,0f0h,0f1h,0f4h,0f5h,0ech,0edh,0f0h,0f1h,000h	; 7b55  ..........
	defb 000h,0f2h,0f3h,0eeh,0efh,0f6h,0f7h,0f2h,0f3h,0eeh	; 7b5f  ..........
	defb 0efh,0f6h,0f7h,0f2h,0f3h,0eeh,0efh,0f6h,0f7h,0f2h	; 7b69  ..........
	defb 0f3h,0eeh,0efh,0f6h,0f7h,0f2h,0f3h,0eeh,0efh,000h	; 7b73  ..........
	defb 0f7h,0f5h,0f3h,0f1h,0efh,0edh,0f7h,0f5h,0f3h,0f1h	; 7b7d  ..........
	defb 0efh,0edh,0f7h,0f5h,0f3h,0f1h,0efh,0edh,0f7h,0f5h	; 7b87  ..........
	defb 0f6h,0f4h,0eeh,0ech,0f2h,0f0h,0f6h,0f4h,0eeh,0ech	; 7b91  ..........
	defb 0f2h,0f0h,0f6h,0f4h,0eeh,0ech,0f2h,0f0h,0f6h,0f4h	; 7b9b  ..........

; ----------------------------------------------------------------------
; DATOS patrones_del_marco: Los 13 patrones de 0xEB a 0xF7: el ladrillo y los
;   doce pinchos
;   0x7ba5..0x7c0d  (104 bytes)
DATA_patrones_del_marco:
	defb 0fbh,0ffh,0bfh,0bfh,0bfh,0ffh,0fbh,0fbh	; 7ba5  ........
	defb 03fh,01fh,00fh,007h,003h,001h,000h,000h	; 7bad  ?.......
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h	; 7bb5  ........
	defb 000h,000h,001h,003h,007h,00fh,01fh,03fh	; 7bbd  .......?
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch	; 7bc5  ........
	defb 03fh,01fh,00fh,007h,003h,001h,000h,000h	; 7bcd  ?.......
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h	; 7bd5  ........
	defb 000h,000h,001h,003h,007h,00fh,01fh,03fh	; 7bdd  .......?
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch	; 7be5  ........
	defb 03fh,01fh,00fh,007h,003h,001h,000h,000h	; 7bed  ?.......
	defb 0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h	; 7bf5  ........
	defb 000h,000h,001h,003h,007h,00fh,01fh,03fh	; 7bfd  .......?
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch	; 7c05  ........

; ----------------------------------------------------------------------
; DATOS colores_del_marco: El color de esos 13 tiles, en el RLE de 0x4675
;   0x7c0d..0x7c29  (28 bytes)
DATA_colores_del_marco:
	defb 088h,040h,000h,070h,050h,040h,000h,070h	; 7c0d  .@.pP@.p
	defb 050h,008h,020h,010h,030h,008h,020h,008h	; 7c15  P. .0. .
	defb 040h,010h,050h,008h,040h,008h,080h,010h	; 7c1d  @.P.@...
	defb 090h,008h,080h,000h	; 7c25

; ======================================================================
; CODIGO 0x7c29..0x7c8c  (99 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PANTALLA DEL MARCADOR: el marco, la cara grande de Q*bert (que parpadea) y HI-SCORE, REST, STAGE y 1P-SCORE. Con (0xE324) puesto, la cara lleva ademas un sprite encima. En la escena 7 anade GAME OVER / CONTINUE--F5.
; ----------------------------------------------------------------------
pantalla_del_marcador:
	ld a,(0e002h)		;7c29   ; en el duelo, si la pantalla ya esta, no se rehace
	bit 5,a		;7c2c
	jr z,L_7C36		;7c2e
	ld a,(0e342h)		;7c30
	or a			;7c33
	jr nz,L_7C3F		;7c34
L_7C36:
	call borra_la_pantalla		;7c36   ; en negro, y los dibujos grandes en el tercer tercio
	ld hl,03000h		;7c39
	call dibujos_grandes_en_hl		;7c3c
L_7C3F:
	call limpia_el_marco		;7c3f   ; el marco limpio
	ld a,(0e002h)		;7c42   ; en el duelo, a la pantalla del resultado
	bit 5,a		;7c45
	jr nz,$+74		;7c47
	ld a,(0e000h)		;7c49   ; en el GAME OVER no suena nada
	cp 007h		;7c4c
	jr z,L_7C5D		;7c4e
	ld a,(0e320h)		;7c50   ; si se hizo alguna linea, la musica 0x4D; si no, la 0x44
	or a			;7c53
	ld a,04dh		;7c54
	jr nz,L_7C5A		;7c56
	ld a,044h		;7c58
L_7C5A:
	call toca_sonido		;7c5a
L_7C5D:
	call pinta_la_cara		;7c5d   ; la cara
	call pinta_los_marcadores_del_game_over		;7c60   ; los numeros
	ld a,(0e324h)		;7c63
	or a			;7c66
	ret z			;7c67
	ld hl,01800h		;7c68   ; el sprite de la cara: 32 bytes de 0x97BB al patron 0
	ld de,097bbh		;7c6b
	ld bc,00020h		;7c6e
	call copia_a_vram		;7c71
	ld hl,03b00h		;7c74   ; en el plano 0
	ld de,07c8ch		;7c77
	ld bc,00005h		;7c7a
	call copia_a_vram		;7c7d
	ld a,(0e000h)		;7c80   ; y en la escena 7, el rotulo del GAME OVER
	cp 007h		;7c83
	ret nz			;7c85
	ld de,07e8eh		;7c86
	jp pinta_guion		;7c89

; ----------------------------------------------------------------------
; DATOS sprite_de_la_cara: Plano 0 en Y 0x8F y X 0x60, patron 0, color 10, y
;   0xD0 detras: no se pinta ningun otro
;   0x7c8c..0x7c91  (5 bytes)
DATA_sprite_de_la_cara:
	defb 08fh,060h,000h,00ah,0d0h	; 7c8c

; ======================================================================
; CODIGO 0x7c91..0x7d5a  (201 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL RESULTADO DEL DUELO: si quedan partidas, la musica 0x4D y nada mas; al acabar, el marcador de partidas con el ganador, 3 o 5 SET MATCH y lo que gano cada uno en cada partida.
; ----------------------------------------------------------------------
pantalla_del_duelo:
	ld a,(0ecb8h)		;7c91
	or a			;7c94
	jr z,resultado_del_duelo		;7c95
	ld a,04dh		;7c97
	jp toca_sonido		;7c99
resultado_del_duelo:
	call graficos_del_duelo		;7c9c   ; los dibujos del piedra-papel-tijera y sus sprites
	call sprites_del_duelo		;7c9f
	ld hl,0e600h		;7ca2   ; quien ha ganado mas partidas
	ld a,(hl)			;7ca5
	inc hl			;7ca6
	cp (hl)			;7ca7
	ld a,001h		;7ca8
	jr c,L_7CB4		;7caa
	ld hl,0608fh		;7cac   ; gana el primero: su Q*bert en X 0x60
	ld (0ecach),hl		;7caf
	jr L_7CBB		;7cb2
L_7CB4:
	ld hl,0908fh		;7cb4   ; gana el segundo: el suyo en X 0x90
	ld (0ecb0h),hl		;7cb7
	inc a			;7cba
L_7CBB:
	ld (0e324h),a		;7cbb   ; (0xE324): quien gana
	call vuelca_los_sprites_del_duelo		;7cbe
	call pinta_el_resultado		;7cc1
	ld de,07ed6h		;7cc4   ; --3 SET MATCH-- y las partidas
	call guion_en_la_copia		;7cc7
	ld a,(0e104h)		;7cca   ; con 5 partidas, la ultima fila baja
	or a			;7ccd
	ld hl,0ee6dh		;7cce
	jr z,L_7CD6		;7cd1
	ld hl,0eeedh		;7cd3
L_7CD6:
	ld de,07f10h		;7cd6   ; FINAL SET
	ld c,0ffh		;7cd9
	call casillas_en_la_copia		;7cdb
	ld a,(0e104h)		;7cde
	or a			;7ce1
	jr z,L_7CF0		;7ce2
	ld de,07efch		;7ce4   ; con 5, las dos filas de mas y el 5 del rotulo
	call guion_en_la_copia		;7ce7
	ld a,015h		;7cea
	ld hl,0ed8ah		;7cec
	ld (hl),a			;7cef
L_7CF0:
	ld de,0e602h		;7cf0   ; cada partida, el corazon del que la gano (0xFC o 0xFD)
	ld hl,0edebh		;7cf3
	ld b,005h		;7cf6
L_7CF8:
	ld a,(de)			;7cf8
	or a			;7cf9
	jr z,L_7D00		;7cfa
	dec a			;7cfc
	add a,0fch		;7cfd
	ld (hl),a			;7cff
L_7D00:
	ld a,040h		;7d00
	call suma_a_a_hl		;7d02
	inc de			;7d05
	djnz L_7CF8		;7d06
	jp vuelca_la_pantalla		;7d08
parpadea_el_marcador:
	ld a,(0e002h)		;7d0b   ; con uno, la cara
	bit 5,a		;7d0e
	jr nz,L_7D15		;7d10
	jp cara_cada_16_cuadros		;7d12
L_7D15:
	ld a,(0ecb8h)		;7d15   ; en el duelo, si quedan partidas, nada
	or a			;7d18
	jr z,parpadea_el_ganador		;7d19
	ld a,001h		;7d1b
	ld (0e004h),a		;7d1d
	ret			;7d20
parpadea_el_ganador:
	call vuelca_la_pantalla		;7d21
	jp parpadea_el_resultado		;7d24
cabecera_del_duelo:		; --3 SET MATCH-- (o 5) y que partida se juega: 1ST, 2ND, 3RD, 4TH o FINAL SET
	ld de,07d62h		;7d27
	call pinta_guion		;7d2a
	ld a,(0e104h)		;7d2d   ; con 5 partidas, el 5 en el rotulo
	or a			;7d30
	ld b,003h		;7d31
	jr z,L_7D3F		;7d33
	ld a,015h		;7d35
	ld hl,038cah		;7d37
	call 0004dh		;7d3a   ; BIOS WRTVRM - Writes data in VRAM
	ld b,005h		;7d3d
L_7D3F:
	ld a,(0ecb8h)		;7d3f   ; la ultima es FINAL SET
	ld de,07d9ch		;7d42
	cp 001h		;7d45
	jr z,L_7D56		;7d47
	sub b			;7d49   ; si no, la que toca: total menos las que quedan
	neg		;7d4a
	add a,a			;7d4c
	ld hl,07d5ah		;7d4d
	call suma_a_a_hl		;7d50
	ld e,(hl)			;7d53
	inc hl			;7d54
	ld d,(hl)			;7d55
L_7D56:
	call pinta_guion		;7d56
	ret			;7d59

; ----------------------------------------------------------------------
; DATOS rotulos_de_las_partidas: Cuatro punteros a 1ST, 2ND, 3RD y 4TH SET y
;   los guiones de 0x4685: "--3 SET MATCH--" en 0x38C8, los cuatro en 0x392C y
;   "FINAL SET" en 0x392B
;   0x7d5a..0x7da8  (78 bytes)
DATA_rotulos_de_las_partidas:
	defb 074h,07dh,07eh,07dh,088h,07dh,092h,07dh	; 7d5a  t}~}.}.}
	defb 0c8h,038h,020h,020h,013h,000h,033h,025h	; 7d62  .8  ..3%
	defb 034h,000h,02dh,021h,034h,023h,028h,020h	; 7d6a  4.-!4#( 
	defb 020h,0ffh,02ch,039h,011h,033h,034h,000h	; 7d72   .,9.34.
	defb 033h,025h,034h,0ffh,02ch,039h,012h,02eh	; 7d7a  3%4.,9..
	defb 024h,000h,033h,025h,034h,0ffh,02ch,039h	; 7d82  $.3%4.,9
	defb 013h,032h,024h,000h,033h,025h,034h,0ffh	; 7d8a  .2$.3%4.
	defb 02ch,039h,014h,034h,028h,000h,033h,025h	; 7d92  ,9.4(.3%
	defb 034h,0ffh,02bh,039h,026h,029h,02eh,021h	; 7d9a  4.+9&).!
	defb 02ch,000h,033h,025h,034h,0ffh	; 7da2

; ======================================================================
; CODIGO 0x7da8..0x7dca  (34 bytes)
; ======================================================================


cara_cada_16_cuadros:
	ld a,(0e003h)		;7da8
	and 00fh		;7dab
	ret nz			;7dad
pinta_la_cara:		; Una de las cuatro de 0x7DCA: dos caras (segun 0xE324) con los ojos abiertos o cerrados cada 16 cuadros
	ld a,(0e003h)		;7dae
	bit 4,a		;7db1
	ld b,000h		;7db3
	jr z,L_7DB8		;7db5
	inc b			;7db7
L_7DB8:
	ld a,(0e324h)		;7db8
	add a,a			;7dbb
	add a,b			;7dbc
	ld hl,07dcah		;7dbd
	add a,a			;7dc0
	call suma_a_a_hl		;7dc1
	ld e,(hl)			;7dc4
	inc hl			;7dc5
	ld d,(hl)			;7dc6
	jp pinta_guion		;7dc7

; ----------------------------------------------------------------------
; DATOS caras_punteros: Las cuatro caras: 0x7DD2 y 0x7DF6 (la normal, dos
;   pasos), 0x7E1A y 0x7E3A (la otra)
;   0x7dca..0x7dd2  (8 bytes)
DATA_caras_punteros:
	defw 07dd2h,07df6h,07e1ah,07e3ah	; 7dca  -> DATA_caras 0x7df6 0x7e1a 0x7e3a

; ----------------------------------------------------------------------
; DATOS caras: Guiones de 0x4685 con cuatro filas de tiles del tercer tercio
;   desde 0x3A2D: las caras grandes de Q*bert
;   0x7dd2..0x7e5a  (136 bytes)
DATA_caras:
	defb 02dh,03ah,09fh,0a0h,0b2h,0b3h,000h,000h,0feh,04dh,03ah,0a1h	; 7dd2  -:.......M:.
	defb 0b8h,0b9h,0a2h,0a5h,000h,0feh,06dh,03ah,0a3h,028h,0a4h,0b4h	; 7dde  ......m:.(..
	defb 0a6h,000h,0feh,08dh,03ah,0a7h,0a8h,0a9h,0b5h,0b6h,0b7h,0ffh	; 7dea  ....:.......
	defb 02dh,03ah,000h,000h,0e0h,0dfh,0cdh,0cch,0feh,04dh,03ah,000h	; 7df6  -:.......M:.
	defb 0d2h,0cfh,0e6h,0e5h,0ceh,0feh,06dh,03ah,000h,0d3h,0e1h,0d1h	; 7e02  ......m:....
	defb 028h,0d0h,0feh,08dh,03ah,0e4h,0e3h,0e2h,0d6h,0d5h,0d4h,0ffh	; 7e0e  (...:.......
	defb 02dh,03ah,093h,053h,041h,0feh,04dh,03ah,043h,054h,028h,042h	; 7e1a  -:.SA.M:CT(B
	defb 0feh,06ch,03ah,047h,046h,028h,045h,044h,091h,0feh,08bh,03ah	; 7e26  .l:GF(ED...:
	defb 056h,055h,04bh,04ah,049h,048h,000h,0ffh,02dh,03ah,093h,053h	; 7e32  VUKJIH..-:.S
	defb 041h,0feh,04dh,03ah,043h,054h,028h,042h,0feh,06ch,03ah,047h	; 7e3e  A.M:CT(B.l:G
	defb 046h,028h,045h,044h,000h,0feh,08bh,03ah,056h,055h,04bh,04ah	; 7e4a  F(ED...:VUKJ
	defb 049h,048h,092h,0ffh	; 7e56

; ======================================================================
; CODIGO 0x7e5a..0x7e8e  (52 bytes)
; ======================================================================


limpia_el_marco:		; El marco de ladrillo y todo lo de dentro, de la fila 3 a la 20 y de la columna 1 a la 30, a cero
	call monta_el_marco		;7e5a
	ld hl,0ed00h		;7e5d
	ld de,0ed01h		;7e60
	ld bc,002feh		;7e63
	ld (hl),0ebh		;7e66   ; todo ladrillo...
	ldir		;7e68
	ld hl,0ed61h		;7e6a   ; ...menos el hueco del medio
	ld c,012h		;7e6d
L_7E6F:
	ld b,01eh		;7e6f
L_7E71:
	ld (hl),000h		;7e71
	inc hl			;7e73
	djnz L_7E71		;7e74
	inc hl			;7e76
	inc hl			;7e77
	dec c			;7e78
	jr nz,L_7E6F		;7e79
	call esconde_los_sprites		;7e7b   ; sin sprites, y a la VRAM
	jp vuelca_la_pantalla		;7e7e
espera_un_rato:		; Dos vueltas de 65.536: una pausa de reloj, con las interrupciones corriendo
	ld b,002h		;7e81
L_7E83:
	ld hl,00000h		;7e83
L_7E86:
	dec hl			;7e86
	ld a,h			;7e87
	or l			;7e88
	jr nz,L_7E86		;7e89
	djnz L_7E83		;7e8b
	ret			;7e8d

; ----------------------------------------------------------------------
; DATOS rotulos_del_marcador: Guiones: "GAME OVER" en 0x38C8 y "CONTINUE--F5"
;   en 0x39CA; HI-SCORE, REST, STAGE- y 1P-SCORE (0x7EB0); "--3 SET MATCH--",
;   1ST SET y 2ND SET en la copia de la tabla de nombres (0x7ED6, de 0x871C);
;   3RD SET y 4TH SET (0x7EFC); y "FINAL SET" sin direccion (0x7F10, de
;   0x8724)
;   0x7e8e..0x7f1a  (140 bytes)
DATA_rotulos_del_marcador:
	defb 0c8h,038h,000h,000h,000h,027h,021h,02dh	; 7e8e  .8...'!-
	defb 025h,000h,000h,02fh,036h,025h,032h,000h	; 7e96  %../6%2.
	defb 000h,000h,0feh,0cah,039h,023h,02fh,02eh	; 7e9e  ....9#/.
	defb 034h,029h,02eh,035h,025h,020h,020h,026h	; 7ea6  4).5%  &
	defb 015h,0ffh,068h,039h,028h,029h,020h,033h	; 7eae  ..h9() 3
	defb 023h,02fh,032h,025h,0feh,0cch,039h,032h	; 7eb6  #/2%..92
	defb 025h,033h,034h,0feh,0cch,038h,033h,034h	; 7ebe  %34..834
	defb 021h,027h,025h,020h,0feh,028h,039h,011h	; 7ec6  !'% .(9.
	defb 030h,020h,033h,023h,02fh,032h,025h,0ffh	; 7ece  0 3#/2%.
	defb 088h,0edh,020h,020h,013h,000h,033h,025h	; 7ed6  ..  ..3%
	defb 034h,000h,02dh,021h,034h,023h,028h,020h	; 7ede  4.-!4#( 
	defb 020h,0feh,0edh,0edh,011h,033h,034h,000h	; 7ee6   ....34.
	defb 033h,025h,034h,0feh,02dh,0eeh,012h,02eh	; 7eee  3%4.-...
	defb 024h,000h,033h,025h,034h,0ffh,06dh,0eeh	; 7ef6  $.3%4.m.
	defb 013h,032h,024h,000h,033h,025h,034h,0feh	; 7efe  .2$.3%4.
	defb 0adh,0eeh,014h,034h,028h,000h,033h,025h	; 7f06  ...4(.3%
	defb 034h,0ffh,026h,029h,02eh,021h,02ch,000h	; 7f0e  4.&).!,.
	defb 033h,025h,034h,0ffh	; 7f16

; ======================================================================
; CODIGO 0x7f1a..0x7fcc  (178 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MENU DE UN JUGADOR: LEVEL 1 a LEVEL 5, el Q*bert del menu y su musica, 0x1D.
; ----------------------------------------------------------------------
menu_de_un_jugador:
	ld a,01dh		;7f1a
	call toca_sonido		;7f1c
	call limpia_el_marco		;7f1f
	call dibujos_del_menu		;7f22
	call pausa_de_la_animacion		;7f25
	ld de,07fcch		;7f28
	jp pinta_guion		;7f2b

; ----------------------------------------------------------------------
; ELIGE EL NIVEL. Arriba y abajo mueven la mano (dando la vuelta); el disparo elige. Mientras no se elige, el `pop hl` hace que la escena vuelva sin pasar de paso.
; ----------------------------------------------------------------------
elige_el_nivel:
	call anima_el_menu		;7f2e
	ld a,(0e008h)		;7f31   ; el disparo
	bit 4,a		;7f34
	jr nz,pinta_la_mano_del_nivel		;7f36
	call mueve_la_mano		;7f38
	call parpadea_la_mano		;7f3b
	pop hl			;7f3e   ; vuelve de la escena, no de aqui
	ret			;7f3f
parpadea_el_nivel_elegido:
	ld a,(0e003h)		;7f40
	bit 2,a		;7f43   ; cuatro cuadros el menu, cuatro sin el nivel elegido
	ld de,07fcch		;7f45
	jp z,pinta_guion		;7f48
	call linea_del_nivel		;7f4b
	inc hl			;7f4e
	inc hl			;7f4f
	ld b,008h		;7f50
borra_ocho:
	xor a			;7f52
	call 0004dh		;7f53   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;7f56
	djnz borra_ocho		;7f57
	ret			;7f59
borra_la_tabla_de_nombres:
	ld hl,03800h		;7f5a
	ld bc,00300h		;7f5d
	xor a			;7f60
	jp 00056h		;7f61   ; BIOS FILVRM - Fills VRAM with value
mueve_la_mano:
	ld hl,0e103h		;7f64
	ld a,(0e008h)		;7f67
	rrca			;7f6a   ; bit 0: arriba
	jr c,sube_la_mano		;7f6b
	rrca			;7f6d   ; bit 1: abajo
	jr c,baja_la_mano		;7f6e
	ret			;7f70
sube_la_mano:
	call sonido_del_cursor		;7f71
	ld a,(hl)			;7f74
	or a			;7f75
	jr z,L_7F7A		;7f76
	dec (hl)			;7f78
	ret			;7f79
L_7F7A:
	ld (hl),004h		;7f7a   ; de la 1 a la 5
	ret			;7f7c
baja_la_mano:
	call sonido_del_cursor		;7f7d
	ld a,(hl)			;7f80
	cp 004h		;7f81
	jr z,L_7F87		;7f83
	inc (hl)			;7f85
	ret			;7f86
L_7F87:
	ld (hl),000h		;7f87   ; de la 5 a la 1
	ret			;7f89
sonido_del_cursor:
	ld a,003h		;7f8a
	jp toca_sonido		;7f8c
parpadea_la_mano:
	call borra_las_manos		;7f8f
	ld a,(0e003h)		;7f92
	bit 3,a		;7f95
	ret z			;7f97
pinta_la_mano_del_nivel:
	call linea_del_nivel		;7f98
	ld a,01bh		;7f9b
	call 0004dh		;7f9d   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;7fa0
	ld a,01ch		;7fa1
	call 0004dh		;7fa3   ; BIOS WRTVRM - Writes data in VRAM
	ret			;7fa6
linea_del_nivel:		; HL = 0x38AA + 64 * nivel: dos filas por opcion
	ld a,(0e103h)		;7fa7
	ld b,a			;7faa
	ld hl,00040h		;7fab
	call multiplica_hl		;7fae
	ld de,038aah		;7fb1
	add hl,de			;7fb4
	ret			;7fb5
borra_las_manos:
	ld hl,038aah		;7fb6
borra_b_manos:
	ld b,005h		;7fb9
L_7FBB:
	xor a			;7fbb
	call 0004dh		;7fbc   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;7fbf
	xor a			;7fc0
	call 0004dh		;7fc1   ; BIOS WRTVRM - Writes data in VRAM
	ld a,03fh		;7fc4
	call suma_a_a_hl		;7fc6
	djnz L_7FBB		;7fc9
	ret			;7fcb

; ----------------------------------------------------------------------
; DATOS menu_de_niveles: Guion de 0x4685: LEVEL 1 a LEVEL 5, de dos en dos
;   filas desde 0x38AD
;   0x7fcc..0x7ffe  (50 bytes)
DATA_menu_de_niveles:
	defb 0adh,038h,02ch,025h,036h,025h,02ch,000h,011h,0feh	; 7fcc  .8,%6%,...
	defb 0edh,038h,02ch,025h,036h,025h,02ch,000h,012h,0feh	; 7fd6  .8,%6%,...
	defb 02dh,039h,02ch,025h,036h,025h,02ch,000h,013h,0feh	; 7fe0  -9,%6%,...
	defb 06dh,039h,02ch,025h,036h,025h,02ch,000h,014h,0feh	; 7fea  m9,%6%,...
	defb 0adh,039h,02ch,025h,036h,025h,02ch,000h,015h,0ffh	; 7ff4  .9,%6%,...

; ======================================================================
; CODIGO 0x7ffe..0x8083  (133 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL MENU DEL DUELO: LEVEL 1 o LEVEL 2 y 3 SET MATCH o 5 SET MATCH, con los dos Q*bert.
; ----------------------------------------------------------------------
menu_del_duelo:
	ld hl,00000h		;7ffe   ; ninguna partida ganada
	ld (0e600h),hl		;8001
	ld a,01dh		;8004
	call toca_sonido		;8006
	call limpia_el_marco		;8009
	call dibujos_del_menu_del_duelo		;800c
	ld de,08083h		;800f
	call pinta_guion		;8012
	call pausa_de_la_animacion		;8015
	ld hl,0e103h		;8018   ; el nivel, 0 o 1
	ld a,(hl)			;801b
	cp 002h		;801c
	ret c			;801e
	ld (hl),000h		;801f
	ret			;8021
pausa_de_la_animacion:
	ld a,00eh		;8022
	ld (0e347h),a		;8024
	ret			;8027
elige_el_duelo:
	call anima_el_segundo_del_menu		;8028
	call anima_el_menu		;802b
	call cambia_nivel_o_partidas		;802e
	call parpadean_las_manos		;8031
	ld a,(0e008h)		;8034
	bit 4,a		;8037
	jr nz,pinta_las_dos_manos		;8039
	pop hl			;803b   ; vuelve de la escena
	ret			;803c
cambia_nivel_o_partidas:
	ld hl,0e103h		;803d
	ld a,(0e008h)		;8040   ; arriba o abajo: el nivel
	ld b,a			;8043
	and 003h		;8044
	jr nz,L_804D		;8046
	ld a,b			;8048   ; izquierda o derecha: 3 o 5 partidas
	and 00ch		;8049
	ret z			;804b
	inc hl			;804c
L_804D:
	ld a,(hl)			;804d
	xor 001h		;804e
	ld (hl),a			;8050
	jp sonido_del_cursor		;8051
parpadean_las_manos:
	ld hl,038aah		;8054
	call borra_b_manos		;8057
	ld a,(0e003h)		;805a
	bit 3,a		;805d
	ret z			;805f
pinta_las_dos_manos:
	ld de,0e103h		;8060
	ld hl,038aah		;8063
	call pinta_la_mano_de_la_opcion		;8066
	inc de			;8069
	ld hl,0396ah		;806a
pinta_la_mano_de_la_opcion:
	ld a,(de)			;806d
	ld b,a			;806e
	ld a,040h		;806f
	call multiplica		;8071
	call suma_a_a_hl		;8074
	ld a,01bh		;8077
	call 0004dh		;8079   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;807c
	ld a,01ch		;807d
	call 0004dh		;807f   ; BIOS WRTVRM - Writes data in VRAM
	ret			;8082

; ----------------------------------------------------------------------
; DATOS menu_del_duelo: Guion de 0x4685: LEVEL 1, LEVEL 2, 3 SET MATCH y 5 SET
;   MATCH
;   0x8083..0x80b3  (48 bytes)
DATA_menu_del_duelo:
	defb 0adh,038h,02ch,025h,036h,025h,02ch,000h	; 8083  .8,%6%,.
	defb 011h,0feh,0edh,038h,02ch,025h,036h,025h	; 808b  ...8,%6%
	defb 02ch,000h,012h,0feh,06dh,039h,013h,000h	; 8093  ,...m9..
	defb 033h,025h,034h,000h,02dh,021h,034h,023h	; 809b  3%4.-!4#
	defb 028h,0feh,0adh,039h,015h,000h,033h,025h	; 80a3  (..9..3%
	defb 034h,000h,02dh,021h,034h,023h,028h,0ffh	; 80ab  4.-!4#(.

; ======================================================================
; CODIGO 0x80b3..0x8153  (160 bytes)
; ======================================================================


dibujos_del_menu_del_duelo:		; Los dos Q*bert del menu: el primero en X 0x50 y el segundo en X 0xA0
	call graficos_del_menu		;80b3
	call sprites_del_menu		;80b6
	ld hl,0508bh		;80b9
	ld (0ec80h),hl		;80bc
	ld de,08184h		;80bf
	call pinta_guion		;80c2
	jr L_80CD		;80c5
dibujos_del_menu:		; El de un jugador: uno solo, en X 0xA0
	call graficos_del_menu		;80c7
	call sprites_del_menu		;80ca
L_80CD:
	ld hl,0a08bh		;80cd
	ld (0ec84h),hl		;80d0
	ld de,08164h		;80d3
	call pinta_guion		;80d6
	call vuelca_17_bytes_de_sprites		;80d9
	ret			;80dc
graficos_del_menu:		; Dos RLE: patrones y colores del Q*bert grande del menu (0xBE63) y sus sprites (0xBFA5)
	ld de,0be63h		;80dd
	call guion_rle		;80e0
	ld de,0bfa5h		;80e3
	jp guion_rle		;80e6
anima_el_menu:		; Cada 14 cuadros el Q*bert cambia de postura: otro guion y un sprite que aparece y desaparece
	ld hl,0e347h		;80e9
	dec (hl)			;80ec
	ret nz			;80ed
	ld (hl),00eh		;80ee
	inc hl			;80f0
	ld a,(hl)			;80f1
	xor 001h		;80f2
	ld (hl),a			;80f4
	jr z,postura_b		;80f5
	ld de,081a4h		;80f7
	call pinta_guion		;80fa
	ld a,0e0h		;80fd
	ld (0ec8ch),a		;80ff
	jr vuelca_los_sprites_del_menu		;8102
postura_b:
	ld de,081aeh		;8104
	call pinta_guion		;8107
	ld hl,08097h		;810a
	ld (0ec8ch),hl		;810d
vuelca_los_sprites_del_menu:
	jp vuelca_17_bytes_de_sprites		;8110
anima_el_segundo_del_menu:
	ld hl,0e347h		;8113
	ld a,(hl)			;8116
	cp 00eh		;8117
	ret nz			;8119
	inc hl			;811a
	ld a,(hl)			;811b
	or a			;811c
	jr z,postura_b_del_segundo		;811d
	ld de,081b8h		;811f
	call pinta_guion		;8122
	ld a,0e0h		;8125
	ld (0ec88h),a		;8127
	jr L_8138		;812a
postura_b_del_segundo:
	ld de,081c2h		;812c
	call pinta_guion		;812f
	ld hl,07097h		;8132
	ld (0ec88h),hl		;8135
L_8138:
	jp vuelca_17_bytes_de_sprites		;8138
sprites_del_menu:		; Los 17 bytes de 0x8153 a 0xEC80
	ld hl,08153h		;813b
	ld de,0ec80h		;813e
	ld bc,00011h		;8141
	ldir		;8144
	ret			;8146
vuelca_17_bytes_de_sprites:		; 0xEC80 a la tabla de sprites
	ld hl,03b00h		;8147
	ld de,0ec80h		;814a
	ld bc,00011h		;814d
	jp copia_a_vram		;8150

; ----------------------------------------------------------------------
; DATOS sprites_del_menu: Cuatro sprites escondidos (Y 0xE0) con los patrones
;   0, 4, 8 y 12 en color 10, y 0xD0 de fin
;   0x8153..0x8164  (17 bytes)
DATA_sprites_del_menu:
	defb 0e0h,000h,000h,00ah	; 8153
	defb 0e0h,000h,004h,00ah	; 8157
	defb 0e0h,000h,008h,00ah	; 815b
	defb 0e0h,000h,00ch,00ah	; 815f
	defb 0d0h	; 8163

; ----------------------------------------------------------------------
; DATOS posturas_del_menu: Guiones de 0x4685 con las posturas de los Q*bert
;   del menu en el tercer tercio: 0x8164 y 0x8184 los cuerpos, 0x81A4-0x81C2
;   los trozos que cambian
;   0x8164..0x81cc  (104 bytes)
DATA_posturas_del_menu:
	defb 031h,03ah,000h,054h,067h,066h,000h,0feh	; 8164  1:.Tgf..
	defb 051h,03ah,059h,058h,057h,056h,055h,0feh	; 816c  Q:YXWVU.
	defb 071h,03ah,063h,05ch,05ch,05bh,05ah,0feh	; 8174  q:c\\[Z.
	defb 091h,03ah,064h,065h,060h,05fh,05eh,0ffh	; 817c  .:de`_^.
	defb 02ah,03ah,000h,052h,053h,040h,000h,0feh	; 8184  *:.RS@..
	defb 04ah,03ah,041h,042h,043h,044h,045h,0feh	; 818c  J:ABCDE.
	defb 06ah,03ah,046h,047h,048h,048h,04fh,0feh	; 8194  j:FGHHO.
	defb 08ah,03ah,04ah,04bh,04ch,051h,050h,0ffh	; 819c  .:JKLQP.
	defb 071h,03ah,063h,05ch,0feh,091h,03ah,064h	; 81a4  q:c\..:d
	defb 065h,0ffh,071h,03ah,05dh,05ch,0feh,091h	; 81ac  e.q:]\..
	defb 03ah,062h,061h,0ffh,06dh,03ah,048h,04fh	; 81b4  :ba.m:HO
	defb 0feh,08dh,03ah,051h,050h,0ffh,06dh,03ah	; 81bc  ..:QP.m:
	defb 048h,049h,0feh,08dh,03ah,04dh,04eh,0ffh	; 81c4  HI..:MN.

; ======================================================================
; CODIGO 0x81cc..0x837f  (435 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL DUELO: CUANDO CAE UNO. Si le quedan vidas, pierde una y vuelve a entrar; si no, se queda fuera (estado 14). Con los dos fuera, se acaba la partida y gana el que tenga mas cubos.
; ----------------------------------------------------------------------
vuelve_al_duelo:
	ld hl,0e000h		;81cc   ; solo en la partida y en su paso 0
	ld a,(hl)			;81cf
	cp 005h		;81d0
	ret nz			;81d2
	inc hl			;81d3
	ld a,(hl)			;81d4
	or a			;81d5
	ret nz			;81d6
	ld a,(0e202h)		;81d7   ; el primero fuera...
	cp 00eh		;81da
	jr nz,L_81E3		;81dc
	ld hl,0e212h		;81de
	jr L_81ED		;81e1
L_81E3:
	ld a,(0e212h)		;81e3   ; ...o el segundo
	cp 00eh		;81e6
	jr nz,cae_uno_del_duelo		;81e8
	ld hl,0e202h		;81ea
L_81ED:
	ld a,(hl)			;81ed   ; y el otro
	or a			;81ee
	jr z,otro_esta_quieto		;81ef
	cp 00eh		;81f1
	jr z,ronda_sin_nadie		;81f3
cae_uno_del_duelo:
	ld hl,0e113h		;81f5   ; el primero
	ld a,(hl)			;81f8
	or a			;81f9
	jr z,L_8204		;81fa
	ld hl,0e35ch		;81fc   ; o el segundo
	ld a,(hl)			;81ff
	or a			;8200
	ret nz			;8201
	ld a,001h		;8202
L_8204:
	ld (0e333h),a		;8204   ; de quien se trata
	inc (hl)			;8207
	call vidas_del_de_turno		;8208   ; le quedan vidas
	jr nz,quita_una_vida_del_duelo		;820b
	call objeto_del_de_turno		;820d   ; sin vidas: fuera, sus dos sprites
	ld (hl),00eh		;8210
	ld a,008h		;8212
	call suma_a_a_hl		;8214
	ld (hl),00eh		;8217
	ret			;8219
mira_si_queda_alguien:
	ld a,(0e110h)		;821a   ; CODIGO HUERFANO: nadie salta aqui. Si a alguno le quedan vidas, a quitarle una; si no, a la ronda sin nadie
	or a			;821d
	jr nz,quita_una_vida_del_duelo		;821e
	ld a,(0e120h)		;8220
	or a			;8223
	jr nz,quita_una_vida_del_duelo		;8224
ronda_sin_nadie:
	ld a,001h		;8226   ; se acabo la partida por caidas
	ld (0e342h),a		;8228
	ld (0e32dh),a		;822b
	call sonido_y_pausa		;822e
	jp z,resultado_de_la_partida		;8231
quita_una_vida_del_duelo:
	call vidas_del_de_turno		;8234
	jr z,otro_esta_quieto		;8237
	dec (hl)			;8239
	jp pinta_las_vidas_de_los_dos		;823a
otro_esta_quieto:
	call sonido_y_pausa		;823d
	jr gana_la_ronda		;8240
sonido_y_pausa:		; El sonido 0x35 y la pausa de 0x7E81
	push bc			;8242
	ld a,035h		;8243
	call toca_sonido		;8245
	call espera_un_rato		;8248
	pop bc			;824b
	ret			;824c

; ----------------------------------------------------------------------
; EL REBOTE: B, la diagonal hacia la que sale despedido el Q*bert de (0xE332), segun (0xE338).
; ----------------------------------------------------------------------
rebota:
	ld b,000h		;824d
	ld a,(0e338h)		;824f
	or a			;8252
	jr nz,L_8257		;8253
	set 0,b		;8255
L_8257:
	dec a			;8257
	jr nz,L_825C		;8258
	set 3,b		;825a
L_825C:
	dec a			;825c
	jr nz,L_8261		;825d
	set 2,b		;825f
L_8261:
	dec a			;8261
	jr nz,L_8266		;8262
	set 1,b		;8264
L_8266:
	ld a,00ah		;8266
	ld (0e344h),a		;8268
	ld a,(0e332h)		;826b
	or a			;826e
	jp z,salta_el_primero		;826f
	jp salta_el_segundo		;8272
vuelve_a_entrar:
	ld a,(0e332h)		;8275   ; CODIGO HUERFANO: pone al Q*bert de (0xE332) arriba otra vez, con sus dos sprites. Nadie lo llama
	or a			;8278
	ld de,0e202h		;8279
	ld h,000h		;827c
	jr z,L_8285		;827e
	ld de,0e212h		;8280
	ld h,0b0h		;8283
L_8285:
	ld a,(de)			;8285
	cp 003h		;8286
	ret nc			;8288
	ld a,(0e338h)		;8289
	add a,00ch		;828c
	ld b,a			;828e
	ld (de),a			;828f
	inc de			;8290
	ld a,064h		;8291
	ld (de),a			;8293
	inc de			;8294
	inc de			;8295
	inc de			;8296
	ld a,h			;8297
	ld (de),a			;8298
	ld a,004h		;8299
	call suma_a_a_de		;829b
	ld a,b			;829e
	ld (de),a			;829f
	inc de			;82a0
	ld a,064h		;82a1
	ld (de),a			;82a3
	inc de			;82a4
	inc de			;82a5
	inc de			;82a6
	ld a,h			;82a7
	add a,010h		;82a8
	ld (de),a			;82aa
	ret			;82ab
gana_la_ronda:
	ld a,(0e333h)		;82ac
	ld b,a			;82af
	push bc			;82b0
	call pinta_las_vidas_de_los_dos		;82b1
	pop bc			;82b4
gana_el_de_b:
	ld a,b			;82b5
	xor 001h		;82b6
	ld (0e33ah),a		;82b8
apunta_la_partida_ganada:		; Vidas otra vez para los dos y una partida mas para el de (0xE33A)
	call pon_vidas_fase_y_umbral		;82bb   ; las vidas de los dos, otra vez
	ld a,(0e33ah)		;82be
	ld hl,0e600h		;82c1   ; una partida mas para el ganador
	ld b,001h		;82c4
	or a			;82c6
	jr z,L_82CB		;82c7
	inc hl			;82c9
	inc b			;82ca
L_82CB:
	inc (hl)			;82cb
	call apunta_la_partida		;82cc
	ld hl,0ecb8h		;82cf   ; queda una menos
	dec (hl)			;82d2
	jp z,se_acabaron_las_partidas		;82d3
	ld a,001h		;82d6   ; quedan: la siguiente
	ld (0e00dh),a		;82d8
	ret			;82db
se_acabaron_las_partidas:
	ld a,(0e320h)		;82dc
	or a			;82df
	ret nz			;82e0
fin_del_duelo:
	ld hl,0e000h		;82e1   ; escena 6, con la musica del final
	ld (hl),006h		;82e4
	jp musica_de_game_over		;82e6
se_acabo_el_tiempo_del_duelo:
	pop hl			;82e9
	call cuenta_los_cubos_de_los_dos		;82ea   ; quien tiene mas cubos
	pop hl			;82ed
	ld a,001h		;82ee
	ld (0e342h),a		;82f0
	jp resultado_de_la_partida		;82f3   ; a la pantalla del resultado
cuenta_los_cubos_de_los_dos:		; (0xE349) los del primero y (0xE34A) los del segundo; B: 1 si gana el primero, 0 si el segundo, y Z si empatan
	ld hl,0e349h		;82f6
	ld c,040h		;82f9
	call cuenta_los_cubos_de_c		;82fb
	ld a,(hl)			;82fe
	inc hl			;82ff
	push af			;8300
	ld c,020h		;8301
	call cuenta_los_cubos_de_c		;8303
	pop af			;8306
	cp (hl)			;8307
	ret z			;8308
	ld b,001h		;8309
	ret nc			;830b
	dec b			;830c
	ret			;830d
cuenta_los_cubos_de_c:		; Las 79 casillas del tablero (sin los dos modelos) con los bits 6 y 5 iguales a C
	ld (hl),000h		;830e
	ld de,0ec02h		;8310
	ld b,04fh		;8313
L_8315:
	ld a,(de)			;8315
	and 060h		;8316
	cp c			;8318
	jr nz,L_831C		;8319
	inc (hl)			;831b
L_831C:
	inc de			;831c
	djnz L_8315		;831d
	ret			;831f
vidas_del_de_turno:		; HL = 0xE110 o 0xE120 segun (0xE333), y Z si no le quedan
	ld a,(0e333h)		;8320
	ld b,a			;8323
	or a			;8324
	ld hl,0e110h		;8325
	jr z,L_832D		;8328
	ld hl,0e120h		;832a
L_832D:
	ld a,(hl)			;832d
	or a			;832e
	ret			;832f
objeto_del_de_turno:		; HL = 0xE202 o 0xE212
	ld a,(0e333h)		;8330
	ld hl,0e202h		;8333
	or a			;8336
	ret z			;8337
	ld hl,0e212h		;8338
	ret			;833b
cae_el_otro:
	call cambia_de_turno		;833c   ; CODIGO HUERFANO: Z si el OTRO jugador esta cayendo (estado 4); el `call` de dentro cambia (0xE333) dos veces
	call objeto_del_de_turno		;833f
	ld a,(hl)			;8342
	cp 004h		;8343
cambia_de_turno:
	push af			;8345
	ld a,(0e333h)		;8346
	xor 001h		;8349
	ld (0e333h),a		;834b
	pop af			;834e
	ret			;834f
apunta_la_partida:		; En 0xE602 y siguientes, quien gano cada partida (1 o 2)
	ld hl,0e602h		;8350
	ld a,(0e104h)		;8353
	ld c,003h		;8356
	or a			;8358
	jr z,L_835D		;8359
	ld c,005h		;835b
L_835D:
	ld a,(0ecb8h)		;835d
	sub c			;8360
	jr nc,L_8365		;8361
	neg		;8363
L_8365:
	call suma_a_a_hl		;8365
	ld (hl),b			;8368
	ret			;8369
monta_los_corazones:		; Los tiles 0xFC y 0xFD: un corazon magenta y otro cian, las marcas de partida ganada
	ld hl,027e0h		;836a
	ld de,08384h		;836d
	ld bc,00010h		;8370
	call copia_a_los_tres_bancos		;8373
	ld hl,007e0h		;8376
	ld de,0837fh		;8379
	jp guion_rle_en_tres_bancos		;837c

; ----------------------------------------------------------------------
; DATOS color_de_los_corazones: RLE de 0x4675: ocho 0xD0 (magenta) y ocho 0x70
;   (cian)
;   0x837f..0x8384  (5 bytes)
DATA_color_de_los_corazones:
	defb 008h,0d0h,008h,070h,000h	; 837f

; ----------------------------------------------------------------------
; DATOS corazones: Los dos patrones: el mismo corazon dos veces
;   0x8384..0x8394  (16 bytes)
DATA_corazones:
	defb 000h,066h,0ffh,0ffh,0ffh,07eh,03ch,018h	; 8384  .f...~<.
	defb 000h,066h,0ffh,0ffh,0ffh,07eh,03ch,018h	; 838c  .f...~<.

; ======================================================================
; CODIGO 0x8394..0x85f9  (613 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA PANTALLA DE LA RECREATIVA: sus graficos (un RLE de 6.560 bytes que llena patrones y colores de los tres tercios desde 0x0200), los objetos a cero y los sprites de salida.
; ----------------------------------------------------------------------
prepara_la_recreativa:
	call borra_la_tabla_de_nombres		;8394
	ld de,0b09ah		;8397   ; el RLE de 0xB09A
	call guion_rle		;839a
	call borra_los_objetos		;839d
	call borra_la_copia_de_nombres		;83a0
	ld hl,088d8h		;83a3   ; 0x4D bytes a 0xE200: los 0x2D de la tabla de 0x88D8 y 0x20 del codigo que va detras (0x8905), que nadie usa: 0x8735 solo vuelca los 0x2D primeros
	ld de,0e200h		;83a6
	ld bc,0004dh		;83a9
	ldir		;83ac
	ret			;83ae
empieza_la_presentacion:
	ld a,020h		;83af   ; la musica de la presentacion, 0x20
	call toca_sonido		;83b1
	ld de,08741h		;83b4   ; la recreativa y Q*bert en la copia de la tabla de nombres
	call guion_en_la_copia		;83b7
	ld hl,0508fh		;83ba   ; los sprites de Q*bert delante de la maquina
	ld (0e200h),hl		;83bd
	ld hl,0589fh		;83c0
	ld (0e204h),hl		;83c3
	ld hl,0886fh		;83c6
	ld (0e208h),hl		;83c9
	ld hl,0807fh		;83cc
	ld (0e20ch),hl		;83cf
	call vuelca_los_sprites_de_la_presentacion		;83d2
	ld a,080h		;83d5
	jp espera_a_y_sigue		;83d7
presentacion_paso_1:		; La pantalla de la recreativa se anima mientras dura la espera
	call vuelca_la_pantalla		;83da
	call anima_la_recreativa		;83dd
	ld hl,0e004h		;83e0
	dec (hl)			;83e3
	ret nz			;83e4
	ld hl,08d00h		;83e5   ; el sprite 4 aparece arriba
	ld (0e210h),hl		;83e8
	jp espera_a_y_sigue		;83eb
presentacion_paso_2:		; Cuando calla la musica, el sprite 4 baja hasta la Y 0x75
	call vuelca_la_pantalla		;83ee
	call anima_la_recreativa		;83f1
	ld a,(0e012h)		;83f4
	or a			;83f7
	ret nz			;83f8
	call anima_el_bicho_de_la_presentacion		;83f9
	ld hl,0e210h		;83fc
	inc (hl)			;83ff
	inc (hl)			;8400
	inc (hl)			;8401
	ld a,(hl)			;8402
	cp 075h		;8403
	ret c			;8405
	ld a,001h		;8406   ; el sonido 1 y el primer guion de movimiento
	call toca_sonido		;8408
	ld a,001h		;840b
	ld (0e33dh),a		;840d
	ld hl,l85f6h		;8410
	ld (0e33eh),hl		;8413
	jp espera_a_y_sigue		;8416
presentacion_paso_3:		; El sprite 4 sigue el guion de 0x85F9; al acabar, el sonido 2 y Q*bert cambia de postura
	call anima_el_bicho_de_la_presentacion		;8419
	call vuelca_la_pantalla		;841c
	ld a,(0e032h)		;841f
	or a			;8422
	jr z,L_8428		;8423
	call anima_la_recreativa		;8425
L_8428:
	ld de,0e210h		;8428
	call mueve_por_guion		;842b
	ld a,(0e33dh)		;842e
	cp 080h		;8431
	ret nz			;8433
	ld a,(0e012h)		;8434
	or a			;8437
	ret nz			;8438
	ld a,002h		;8439
	call toca_sonido		;843b
	ld hl,0809fh		;843e
	ld (0e21ch),hl		;8441
	ld de,087c3h		;8444
	call guion_en_la_copia		;8447
	call vuelca_la_pantalla		;844a
	call vuelca_los_sprites_de_la_presentacion		;844d
	ld a,060h		;8450
	jp espera_a_y_sigue		;8452
presentacion_paso_4:
	ld hl,0e004h		;8455
	dec (hl)			;8458
	ret nz			;8459
	ld a,013h		;845a
	jp espera_a_y_sigue		;845c
presentacion_paso_5:		; El rotulo de Q*bert sube fila a fila hasta su sitio
	call vuelca_la_pantalla		;845f
	ld hl,0e004h		;8462
	dec (hl)			;8465
	ld a,(hl)			;8466
	jr z,rotulo_en_su_sitio		;8467
	sub 012h		;8469   ; la fila que toca
	neg		;846b
	ld b,a			;846d
	ld hl,00020h		;846e
	call multiplica_hl		;8471
	ld de,0ec05h		;8474
	add hl,de			;8477
	call borra_una_fila		;8478   ; se borra la de debajo...
	call pinta_el_rotulo_de_qbert		;847b   ; ...y el rotulo se pinta una fila mas arriba
	ld a,(0e004h)		;847e
	ld de,086d6h		;8481
	dec a			;8484
	jr z,pinta_el_guion_de		;8485
	ld de,086d0h		;8487
	dec a			;848a
	jr z,pinta_el_guion_de		;848b
	dec a			;848d
	ret nz			;848e
	ld a,0e0h		;848f
	ld (0e208h),a		;8491
	jp vuelca_los_sprites_de_la_presentacion		;8494
pinta_el_guion_de:
	jp guion_en_la_copia		;8497
rotulo_en_su_sitio:
	ld a,02fh		;849a   ; el sonido 0x2F
	call toca_sonido		;849c
	ld de,0880fh		;849f
	call guion_en_la_copia		;84a2
	call vuelca_la_pantalla		;84a5
	ld a,0e0h		;84a8
	ld (0e21ch),a		;84aa
	call vuelca_los_sprites_de_la_presentacion		;84ad
	ld a,050h		;84b0
	jp espera_a_y_sigue		;84b2
presentacion_paso_6:
	ld hl,0e004h		;84b5
	dec (hl)			;84b8
	ret nz			;84b9
	ld de,086d6h		;84ba
	call borra_guion_en_la_copia		;84bd
	ld de,086f6h		;84c0
	call guion_en_la_copia		;84c3
	ld hl,0ee25h		;84c6
	call pinta_el_rotulo_de_qbert		;84c9
	ld de,086d0h		;84cc
	call guion_en_la_copia		;84cf
	ld hl,0886fh		;84d2
	ld (0e208h),hl		;84d5
	call vuelca_los_sprites_de_la_presentacion		;84d8
	ld a,023h		;84db   ; el sonido 0x23
	call toca_sonido		;84dd
	ld a,008h		;84e0
	jp espera_a_y_sigue		;84e2
presentacion_paso_7:		; El rotulo y lo de detras suben otra vez, ahora de dos en dos filas
	call vuelca_la_pantalla		;84e5
	ld hl,0e004h		;84e8
	dec (hl)			;84eb
	jr z,presentacion_paso_8_prepara		;84ec
	ld b,(hl)			;84ee
	ld hl,00020h		;84ef
	call multiplica_hl		;84f2
	ld de,0ee05h		;84f5
	add hl,de			;84f8
	call borra_una_fila		;84f9
	call borra_una_fila		;84fc
	ld de,0fee0h		;84ff
	add hl,de			;8502
	push hl			;8503
	ld de,086f6h		;8504
	call guion_en_la_copia		;8507
	pop hl			;850a
	jp pinta_el_rotulo_de_qbert		;850b
presentacion_paso_8_prepara:
	call sprites_del_titulo		;850e
	call vuelca_la_pantalla		;8511
	ld a,001h		;8514
	ld (0e33dh),a		;8516   ; el segundo guion de movimiento, para el sprite de 0xE228
	ld hl,08618h		;8519
	ld (0e33eh),hl		;851c
	ld hl,000f6h		;851f
	ld (0e228h),hl		;8522
	jp espera_a_y_sigue		;8525
presentacion_paso_8:
	call vuelca_los_sprites_de_la_presentacion		;8528
	ld de,0e228h		;852b
	call mueve_por_guion		;852e
	ld a,(0e33dh)		;8531
	cp 080h		;8534
	ret nz			;8536
	ld a,008h		;8537   ; al acabar: el titulo ya esta pintado (0xE115) y al paso 9
	ld (0e22bh),a		;8539
	call vuelca_los_sprites_de_la_presentacion		;853c
	ld a,001h		;853f
	ld (0e115h),a		;8541
	jp espera_a_y_sigue		;8544
sprites_del_titulo:		; Q*bert y la pantalla de la recreativa como quedan en el titulo
	ld de,08849h		;8547
	call guion_en_la_copia		;854a
	ld hl,0508fh		;854d
	ld (0e200h),hl		;8550
	ld hl,0589fh		;8553
	ld (0e204h),hl		;8556
	ld hl,0886fh		;8559
	ld (0e208h),hl		;855c
	ld hl,0807fh		;855f
	ld (0e224h),hl		;8562
	ld hl,06529h		;8565
	ld (0e228h),hl		;8568
	ret			;856b
borra_una_fila:		; 32 bytes a cero desde HL
	ld d,h			;856c
	ld e,l			;856d
	inc de			;856e
	ld (hl),000h		;856f
	ld bc,00020h		;8571
	ldir		;8574
	ret			;8576
anima_la_recreativa:		; Cada 16 cuadros, uno de los tres dibujos de la pantalla de la maquina (0x8631)
	ld a,(0e003h)		;8577
	and 00fh		;857a
	ret nz			;857c
	ld hl,0e324h		;857d
	ld a,(hl)			;8580
	inc (hl)			;8581
	cp 002h		;8582
	jr nz,L_8588		;8584
	ld (hl),000h		;8586
L_8588:
	add a,a			;8588
	ld hl,08631h		;8589
	call suma_a_a_hl		;858c
	ld e,(hl)			;858f
	inc hl			;8590
	ld d,(hl)			;8591
	call guion_en_la_copia		;8592
	ret			;8595

; ----------------------------------------------------------------------
; MUEVE POR GUION el sprite de DE: el guion (0xE33E) son ternas (cuadros, suma a Y, suma a X) y 0x80 lo acaba. (0xE33D) cuenta los cuadros de la terna y vale 0x80 al acabar.
; ----------------------------------------------------------------------
mueve_por_guion:
	ld hl,0e33dh		;8596
	ld a,(hl)			;8599
	cp 080h		;859a
	ret z			;859c
	dec (hl)			;859d   ; la terna siguiente
	ld hl,(0e33eh)		;859e
	jr nz,suma_la_terna		;85a1
	ld a,003h		;85a3
	call suma_a_a_hl		;85a5
	ld (0e33eh),hl		;85a8
	ld a,(hl)			;85ab
	ld (0e33dh),a		;85ac
	ret			;85af
suma_la_terna:
	inc hl			;85b0
	ld a,(de)			;85b1
	add a,(hl)			;85b2
	ld (de),a			;85b3
	inc hl			;85b4
	inc de			;85b5
	ld a,(de)			;85b6
	add a,(hl)			;85b7
	ld (de),a			;85b8
	cp 0fch		;85b9   ; si se sale por abajo, desaparece
	ret c			;85bb
	ld a,0e0h		;85bc
	ld (0e210h),a		;85be
	jp anima_el_bicho_de_la_presentacion		;85c1
anima_el_bicho_de_la_presentacion:		; Cada 16 cuadros cambia de dibujo (0x10, 0x1C, 0x28, 0x34) y su segundo sprite le sigue
	ld a,(0e003h)		;85c4
	and 00fh		;85c7
	jr nz,L_85DA		;85c9
	ld hl,0e212h		;85cb
	ld a,(hl)			;85ce
	cp 034h		;85cf
	jr nz,L_85D7		;85d1
	ld (hl),010h		;85d3
	jr L_85DA		;85d5
L_85D7:
	add a,00ch		;85d7
	ld (hl),a			;85d9
L_85DA:
	ld hl,0e210h		;85da
	ld de,0e214h		;85dd
	ld bc,00002h		;85e0
	ldir		;85e3
	ld a,(hl)			;85e5
	add a,004h		;85e6
	ld (de),a			;85e8
	inc hl			;85e9
	inc hl			;85ea
	inc de			;85eb
	inc de			;85ec
	ld bc,00002h		;85ed
	ldir		;85f0
	ld a,(hl)			;85f2
	add a,004h		;85f3
	ld (de),a			;85f5
L_85F6:
	jp vuelca_los_sprites_de_la_presentacion		;85f6

; ----------------------------------------------------------------------
; DATOS guion_de_movimiento_1: Ternas (cuadros, Y, X) con 0x80 de fin (el de
;   0x861A). 0x8410 apunta tres bytes antes, a 0x85F6: 0x8596 suma tres antes
;   de leer
;   0x85f9..0x861b  (34 bytes)
DATA_guion_de_movimiento_1:
	defb 008h,0feh,002h	; 85f9
	defb 008h,0ffh,002h	; 85fc
	defb 008h,000h,002h	; 85ff
	defb 008h,001h,002h	; 8602
	defb 008h,002h,001h	; 8605
	defb 010h,003h,001h	; 8608
	defb 008h,0feh,001h	; 860b
	defb 008h,0ffh,001h	; 860e
	defb 008h,000h,001h	; 8611
	defb 008h,001h,001h	; 8614
	defb 008h,002h,001h	; 8617
	defb 080h	; 861a

; ----------------------------------------------------------------------
; DATOS guion_de_movimiento_2: El segundo, igual; 0x8519 apunta a 0x8618
;   0x861b..0x8631  (22 bytes)
DATA_guion_de_movimiento_2:
	defb 010h,002h,003h	; 861b
	defb 008h,003h,003h	; 861e
	defb 008h,002h,001h	; 8621
	defb 008h,0feh,001h	; 8624
	defb 008h,0ffh,001h	; 8627
	defb 008h,000h,001h	; 862a
	defb 008h,001h,001h	; 862d
	defb 080h	; 8630

; ----------------------------------------------------------------------
; DATOS pantallas_de_la_recreativa: Tres punteros a los tres dibujos de la
;   pantalla de la maquina
;   0x8631..0x8637  (6 bytes)
DATA_pantallas_de_la_recreativa:
	defw 08637h,0866ah,0869dh	; 8631  -> DATA_guiones_de_la_presentacion 0x866a 0x869d

; ----------------------------------------------------------------------
; DATOS guiones_de_la_presentacion: Guiones de 0x871C (en la copia de la tabla
;   de nombres): los tres dibujos de la pantalla de la maquina (0x8637, 0x866A
;   y 0x869D) y los trozos del rotulo que sube (0x86D0, 0x86D6 y 0x86F6)
;   0x8637..0x871c  (229 bytes)
DATA_guiones_de_la_presentacion:
	defb 0eeh,0eeh,098h,099h,0feh,00eh,0efh,011h	; 8637  ........
	defb 012h,0feh,0d4h,0eeh,0a0h,08dh,0feh,0f4h	; 863f  ........
	defb 0eeh,08eh,08fh,0feh,02fh,0efh,021h,0b0h	; 8647  ..../.!.
	defb 0feh,04fh,0efh,0abh,0afh,0feh,090h,0efh	; 864f  .O......
	defb 08dh,07bh,060h,08fh,0feh,0b0h,0efh,08ah	; 8657  .{`.....
	defb 089h,08eh,078h,0feh,0d0h,0efh,0a4h,095h	; 865f  ..x.....
	defb 094h,023h,0ffh,0eeh,0eeh,09ah,09bh,0feh	; 8667  .#......
	defb 00eh,0efh,013h,014h,0feh,0d4h,0eeh,0a0h	; 866f  ........
	defb 0adh,0feh,0f4h,0eeh,0aeh,0afh,0feh,02fh	; 8677  ......./
	defb 0efh,0adh,098h,0feh,04fh,0efh,0a2h,0a6h	; 867f  ....O...
	defb 0feh,090h,0efh,08dh,07bh,059h,08fh,0feh	; 8687  ....{Y..
	defb 0b0h,0efh,02ah,088h,05ah,07ah,0feh,0d0h	; 868f  ..*.Zz..
	defb 0efh,024h,02fh,087h,023h,0ffh,0eeh,0eeh	; 8697  .$/.#...
	defb 09ch,09dh,0feh,00eh,0efh,015h,016h,0feh	; 869f  ........
	defb 0d4h,0eeh,0a5h,0a6h,0feh,0f4h,0eeh,0a7h	; 86a7  ........
	defb 0a8h,0feh,02fh,0efh,0a7h,034h,0feh,04fh	; 86af  ../..4.O
	defb 0efh,0ach,0a5h,0feh,090h,0efh,08dh,07bh	; 86b7  .......{
	defb 059h,08fh,0feh,0b0h,0efh,02ah,088h,090h	; 86bf  Y....*..
	defb 079h,0feh,0d0h,0efh,024h,02fh,093h,0a3h	; 86c7  y...$/..
	defb 0ffh,00ah,0efh,0b5h,0b6h,0b7h,0ffh,005h	; 86cf  ........
	defb 0efh,0b1h,0b1h,0b1h,0b1h,0b1h,0b2h,0b3h	; 86d7  ........
	defb 0b4h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h	; 86df  ........
	defb 0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h	; 86e7  ........
	defb 0feh,02ah,0efh,0b5h,0b6h,0b7h,0ffh,0cbh	; 86ef  .*......
	defb 0eeh,092h,097h,09fh,09fh,09eh,095h,094h	; 86f7  ........
	defb 0feh,0ebh,0eeh,091h,096h,044h,098h,099h	; 86ff  .....D..
	defb 090h,093h,0feh,00bh,0efh,00ch,017h,002h	; 8707  ........
	defb 011h,012h,058h,007h,0feh,02ah,0efh,003h	; 870f  ..X..*..
	defb 00fh,018h,020h,020h,0ffh	; 8717

; ======================================================================
; CODIGO 0x871c..0x8741  (37 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL GUION EN LA COPIA DE LA TABLA DE NOMBRES: el mismo formato que 0x4685, pero escribiendo en la RAM (la direccion es de 0xED00 en adelante).
; ----------------------------------------------------------------------
guion_en_la_copia:
	ld c,0ffh		;871c
guion_en_la_copia_direccion:
	ex de,hl			;871e
	ld e,(hl)			;871f
	inc hl			;8720
	ld d,(hl)			;8721
	ex de,hl			;8722
	inc de			;8723
casillas_en_la_copia:		; Sin direccion: desde HL, hasta el 0xFF
	ld a,(de)			;8724
	inc de			;8725
	ld b,a			;8726
	inc b			;8727
	ret z			;8728
	inc b			;8729
	jr z,guion_en_la_copia_direccion		;872a
	and c			;872c
	ld (hl),a			;872d
	inc hl			;872e
	jr casillas_en_la_copia		;872f
borra_guion_en_la_copia:
	ld c,000h		;8731
	jr guion_en_la_copia_direccion		;8733
vuelca_los_sprites_de_la_presentacion:		; Los 0x2D bytes de 0xE200 a la tabla de sprites: once sprites y el 0xD0
	ld hl,03b00h		;8735
	ld de,0e200h		;8738
	ld bc,0002dh		;873b
	jp copia_a_vram		;873e

; ----------------------------------------------------------------------
; DATOS dibujos_de_la_presentacion: Guiones de 0x871C: la recreativa con
;   Q*bert (0x8741), sus cambios de postura (0x87C3 y 0x880F) y como queda en
;   el titulo (0x8849)
;   0x8741..0x88d8  (407 bytes)
DATA_dibujos_de_la_presentacion:
	defb 0cbh,0eeh,092h,097h,09fh,09fh,09eh,095h	; 8741  ........
	defb 094h,000h,0a1h,0a0h,08dh,0a2h,0feh,0ebh	; 8749  ........
	defb 0eeh,091h,096h,044h,098h,099h,090h,093h	; 8751  ...D....
	defb 000h,0a3h,08eh,08fh,0a4h,0feh,00bh,0efh	; 8759  ........
	defb 00ch,017h,002h,011h,012h,058h,096h,06ah	; 8761  .....X.j
	defb 037h,032h,031h,000h,0feh,02ah,0efh,003h	; 8769  721..*..
	defb 00fh,018h,020h,020h,021h,0b0h,033h,05dh	; 8771  ..  !.3]
	defb 069h,0feh,04ah,0efh,00bh,00dh,01ch,01dh	; 8779  i.J.....
	defb 01fh,0abh,0afh,033h,05ch,05eh,036h,0feh	; 8781  ...3\^6.
	defb 06bh,0efh,00eh,019h,01eh,01bh,0aeh,0aah	; 8789  k.......
	defb 033h,05bh,05fh,068h,0feh,08ah,0efh,009h	; 8791  3[_h....
	defb 005h,002h,000h,000h,083h,08dh,07bh,060h	; 8799  ......{`
	defb 08fh,082h,0feh,0abh,0efh,004h,005h,010h	; 87a1  ........
	defb 000h,027h,08ah,089h,08eh,078h,026h,0feh	; 87a9  .'...x&.
	defb 0cfh,0efh,025h,0a4h,095h,094h,023h,022h	; 87b1  ..%...#"
	defb 0feh,0f0h,0efh,02bh,02ch,02dh,02eh,008h	; 87b9  ...+,-..
	defb 00ah,0ffh,0d4h,0eeh,0a9h,0aah,0feh,0f4h	; 87c1  ........
	defb 0eeh,0abh,0ach,0feh,010h,0efh,057h,097h	; 87c9  ......W.
	defb 06bh,06ch,032h,031h,0feh,02fh,0efh,021h	; 87d1  kl21./.!
	defb 038h,039h,03ah,06dh,06eh,0feh,04fh,0efh	; 87d9  89:mn.O.
	defb 0a9h,03bh,03ch,033h,03dh,06fh,0feh,06fh	; 87e1  .;<3=o.o
	defb 0efh,0a8h,042h,041h,040h,03fh,066h,067h	; 87e9  ..BA@?fg
	defb 03eh,0feh,08fh,0efh,084h,08bh,07ch,07dh	; 87f1  >.....|}
	defb 08ch,086h,035h,0feh,0afh,0efh,027h,02ah	; 87f9  ..5...'*
	defb 029h,028h,028h,026h,0feh,0cfh,0efh,025h	; 8801  )((&...%
	defb 024h,02fh,030h,023h,022h,0ffh,02fh,0efh	; 8809  $/0#"./.
	defb 021h,09fh,09ah,071h,063h,043h,0feh,04fh	; 8811  !..qcC.O
	defb 0efh,0a1h,0a0h,061h,062h,070h,044h,0feh	; 8819  ...abpD.
	defb 06fh,0efh,09ch,045h,064h,065h,046h,047h	; 8821  o..EdeFG
	defb 000h,000h,0feh,08fh,0efh,085h,091h,080h	; 8829  ........
	defb 081h,092h,0b8h,000h,000h,0feh,0afh,0efh	; 8831  ........
	defb 027h,02ah,029h,028h,028h,026h,0feh,0cfh	; 8839  '*)((&..
	defb 0efh,025h,024h,02fh,030h,023h,022h,0ffh	; 8841  .%$/0#".
	defb 0cbh,0eeh,092h,097h,09fh,09fh,09eh,095h	; 8849  ........
	defb 094h,000h,0a1h,089h,08ah,0a2h,0feh,0ebh	; 8851  ........
	defb 0eeh,091h,096h,044h,09ah,09bh,090h,093h	; 8859  ...D....
	defb 000h,0a3h,08bh,08ch,0a4h,0feh,00bh,0efh	; 8861  ........
	defb 00ch,017h,002h,013h,014h,056h,099h,072h	; 8869  .....V.r
	defb 048h,032h,031h,000h,0feh,02ah,0efh,003h	; 8871  H21..*..
	defb 00fh,018h,020h,020h,09dh,049h,04ah,04bh	; 8879  ..  .IJK
	defb 04ch,04dh,04eh,000h,0feh,04ah,0efh,00bh	; 8881  LMN..J..
	defb 00dh,01ch,01dh,01fh,09eh,033h,04fh,055h	; 8889  .....3OU
	defb 033h,074h,073h,000h,0feh,06bh,0efh,00eh	; 8891  3ts..k..
	defb 019h,01eh,01bh,09bh,050h,051h,052h,053h	; 8899  ....PQRS
	defb 075h,054h,000h,0feh,08ah,0efh,009h,005h	; 88a1  uT......
	defb 002h,000h,000h,085h,091h,07eh,07fh,092h	; 88a9  .....~..
	defb 0b8h,000h,000h,0feh,0abh,0efh,004h,005h	; 88b1  ........
	defb 010h,000h,027h,02ah,029h,028h,028h,026h	; 88b9  ..'*)((&
	defb 000h,000h,0feh,0cfh,0efh,025h,024h,02fh	; 88c1  .....%$/
	defb 030h,023h,022h,000h,000h,0feh,0f0h,0efh	; 88c9  0#".....
	defb 02bh,02ch,02dh,02eh,008h,00ah,0ffh	; 88d1

; ----------------------------------------------------------------------
; DATOS sprites_de_la_presentacion: Once sprites de salida (Y, X, patron,
;   color) y el 0xD0 de fin: 45 bytes
;   0x88d8..0x8905  (45 bytes)
DATA_sprites_de_la_presentacion:
	defb 0e0h,000h,000h,007h	; 88d8
	defb 0e0h,000h,004h,005h	; 88dc
	defb 0e0h,000h,008h,007h	; 88e0
	defb 0e0h,000h,00ch,007h	; 88e4
	defb 0e0h,000h,010h,007h	; 88e8
	defb 0e0h,000h,014h,004h	; 88ec
	defb 0e0h,000h,018h,005h	; 88f0
	defb 0e0h,000h,040h,00ah	; 88f4
	defb 0e0h,000h,044h,007h	; 88f8
	defb 0e0h,000h,048h,007h	; 88fc
	defb 0e0h,000h,04ch,00ah	; 8900
	defb 0d0h	; 8904

; ======================================================================
; CODIGO 0x8905..0x8b49  (580 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; EL FIN DE UNA PARTIDA DEL DUELO. Los dos cubos acabados con cuantos tiene cada uno. Por tiempo (TIME OUT!), gana el que mas cubos tiene (1P WIN! o 2P WIN!); si empatan (DRAWN GAME) o se acabo porque cayeron los dos, se juega al piedra-papel-tijera.
; ----------------------------------------------------------------------
resultado_de_la_partida:
	xor a			;8905
	ld (0e358h),a		;8906
	call borra_la_pantalla		;8909
	call graficos_del_duelo		;890c   ; los dibujos del piedra-papel-tijera
	call limpia_el_marco		;890f
	call dibujo_del_jan_ken		;8912
	call prepara_el_piedra_papel_tijera		;8915
	ld de,08f83h		;8918
	call guion_en_la_copia		;891b
	ld a,(0e32dh)		;891e   ; (0xE32D): acabo por caidas
	or a			;8921
	jr nz,a_piedra_papel_tijera		;8922
	ld de,08f77h		;8924   ; TIME OUT!
	call guion_en_la_copia		;8927
	ld hl,0e349h		;892a   ; cuantos cubos tiene cada uno
	ld a,(hl)			;892d
	inc hl			;892e
	cp (hl)			;892f
	jr nz,L_8938		;8930
	ld de,08f83h		;8932   ; empate: DRAWN GAME
	xor a			;8935
	jr L_8943		;8936
L_8938:
	ld de,08f90h		;8938   ; mas el primero: 1P WIN!
	ld a,001h		;893b
	jr nc,L_8943		;893d
	ld de,08f9dh		;893f   ; mas el segundo: 2P WIN!
	inc a			;8942
L_8943:
	ld (0e324h),a		;8943
	call guion_en_la_copia		;8946
	call pinta_los_dos_cubos		;8949   ; los dos cubos acabados...
	ld hl,0ee4ah		;894c   ; ...y las dos cuentas
	ld (hl),03ah		;894f
	inc hl			;8951
	ld a,(0e34ah)		;8952
	call pinta_dos_cifras		;8955
	ld hl,0ee56h		;8958
	ld (hl),03ah		;895b
	inc hl			;895d
	ld a,(0e349h)		;895e
	call pinta_dos_cifras		;8961
	call vuelca_la_pantalla		;8964
	ld a,(0e324h)		;8967   ; con ganador, al paso 8
	ld c,a			;896a
	or a			;896b
	jr z,a_piedra_papel_tijera		;896c
	ld a,008h		;896e
	ld (0e001h),a		;8970
	push bc			;8973
	call sprites_del_duelo		;8974
	pop bc			;8977
	ld a,c			;8978
	dec a			;8979
	jp z,gana_el_primero		;897a
	jp gana_el_segundo		;897d
a_piedra_papel_tijera:
	ld a,038h		;8980   ; el sonido 0x38
	call toca_sonido		;8982
manos_por_defecto:
	ld hl,0e340h		;8985   ; si nadie pulsa, una mano al azar para cada uno (R y el contador de cuadros)
	ld a,r		;8988
	call mano_al_azar		;898a
	inc hl			;898d
	ld a,(0e003h)		;898e
	call mano_al_azar		;8991
	ld a,006h		;8994   ; al paso 6 con 128 cuadros
	ld (0e001h),a		;8996
	ld a,080h		;8999
	ld (0e004h),a		;899b
	jp vuelca_la_pantalla		;899e
mano_al_azar:		; A & 3, salvo el 3
	and 003h		;89a1
	cp 003h		;89a3
	ret z			;89a5
	ld (hl),a			;89a6
	ret			;89a7
prepara_el_piedra_papel_tijera:		; El recuadro de ladrillo, los sprites y los dos Q*bert
	ld de,08c2ch		;89a8
	call guion_en_la_copia		;89ab
	call sprites_del_duelo		;89ae
	ld hl,0488bh		;89b1
	ld (0ec80h),hl		;89b4
	ld hl,0a88bh		;89b7
	ld (0ec84h),hl		;89ba
	ld hl,00001h		;89bd
	ld (0e359h),hl		;89c0
	jp vuelca_los_sprites_del_duelo		;89c3

; ----------------------------------------------------------------------
; PASO 6: JAN-KEN. LET'S PLAY JAN-KEN y JAN-KEN! con las manos parpadeando mientras suena la musica; cada jugador elige con su mando: abajo papel, izquierda tijera, arriba piedra.
; ----------------------------------------------------------------------
jan_ken:
	ld hl,0e004h		;89c6
	ld a,(hl)			;89c9
	or a			;89ca
	jr z,L_89DE		;89cb
	dec (hl)			;89cd
	ret nz			;89ce
	ld hl,0e358h		;89cf   ; dos musicas alternas: 0x26 y 0x4A
	bit 0,(hl)		;89d2
	ld a,026h		;89d4
	jr z,L_89DA		;89d6
	ld a,04ah		;89d8
L_89DA:
	inc (hl)			;89da
	call toca_sonido		;89db
L_89DE:
	call borra_el_recuadro		;89de   ; el recuadro limpio
	ld de,08c01h		;89e1
	call guion_en_la_copia		;89e4
	ld de,08c16h		;89e7
	call guion_en_la_copia		;89ea
	call parpadean_las_manos_del_jan_ken		;89ed
	call vuelca_la_pantalla		;89f0
	call vuelca_los_sprites_del_duelo		;89f3
	ld hl,0e340h		;89f6   ; la mano del segundo, de su mando
	ld a,(0e330h)		;89f9
	call mano_del_mando		;89fc
	inc hl			;89ff   ; la del primero, del suyo
	ld a,(0e009h)		;8a00
	call mano_del_mando		;8a03
	ld a,(0e012h)		;8a06   ; hasta que acaba la musica
	or a			;8a09
	ret nz			;8a0a
	ld a,03bh		;8a0b   ; el sonido 0x3B y PON!
	call toca_sonido		;8a0d
	ld de,08d80h		;8a10
	call guion_en_la_copia		;8a13
	ld de,08c21h		;8a16
	call guion_en_la_copia		;8a19
	call sprites_del_duelo		;8a1c
	ld hl,0488dh		;8a1f
	ld (0ec90h),hl		;8a22
	ld hl,0a88dh		;8a25
	ld (0ec94h),hl		;8a28
	call vuelca_los_sprites_del_duelo		;8a2b
	call vuelca_la_pantalla		;8a2e
	ld a,040h		;8a31
	jp espera_a_y_sigue		;8a33
pon:		; Paso 7: las dos manos a la vista
	ld a,(0e012h)		;8a36
	or a			;8a39
	ret nz			;8a3a
	ld a,03eh		;8a3b   ; el sonido 0x3E
	call toca_sonido		;8a3d
	ld de,08dc4h		;8a40
	call guion_en_la_copia		;8a43
	call sprites_del_duelo		;8a46
	ld hl,0488dh		;8a49
	ld (0ec90h),hl		;8a4c
	ld h,0a8h		;8a4f
	ld (0ec94h),hl		;8a51
	ld hl,0987fh		;8a54
	ld (0ec98h),hl		;8a57
	ld hl,0688fh		;8a5a
	ld (0ec9ch),hl		;8a5d
	ld l,09fh		;8a60
	ld (0eca0h),hl		;8a62
	ld hl,0888fh		;8a65
	ld (0eca4h),hl		;8a68
	ld l,09fh		;8a6b
	ld (0eca8h),hl		;8a6d
	ld a,(0e340h)		;8a70
	call pinta_una_mano		;8a73
	ld a,(0e341h)		;8a76
	add a,003h		;8a79
	call pinta_una_mano		;8a7b
	call vuelca_la_pantalla		;8a7e
	call vuelca_los_sprites_del_duelo		;8a81
	ld a,080h		;8a84
	jp espera_a_y_sigue		;8a86
quien_gana:		; Paso 8: la mano A+1 (modulo 3) gana a la A: tijera a papel, piedra a tijera y papel a piedra
	ld a,(0e012h)		;8a89
	or a			;8a8c
	ret nz			;8a8d
	call sprites_del_duelo		;8a8e
	ld hl,0e340h		;8a91
	ld c,000h		;8a94
	ld a,(hl)			;8a96
	inc hl			;8a97
	ld b,(hl)			;8a98
	cp b			;8a99   ; iguales: otra vez
	jr z,otra_vez_jan_ken		;8a9a
	inc c			;8a9c   ; si la del primero es la siguiente a la del segundo, gana el primero
	inc a			;8a9d
	cp 003h		;8a9e
	jr nz,L_8AA3		;8aa0
	xor a			;8aa2
L_8AA3:
	cp b			;8aa3
	jr z,gana_el_primero		;8aa4
	inc c			;8aa6
gana_el_segundo:
	ld hl,0908fh		;8aa7
	ld (0ecb0h),hl		;8aaa
	jr apunta_quien_gana		;8aad
gana_el_primero:
	ld hl,0608fh		;8aaf
	ld (0ecach),hl		;8ab2
apunta_quien_gana:
	ld a,c			;8ab5
	ld (0e324h),a		;8ab6
	ld de,08dc4h		;8ab9
	call borra_guion_en_la_copia		;8abc
	ld de,08c2ch		;8abf
	call guion_en_la_copia		;8ac2
	call pinta_el_resultado		;8ac5
	ld a,029h		;8ac8   ; el sonido 0x29
	call toca_sonido		;8aca
	ld a,000h		;8acd
	jp espera_a_y_sigue		;8acf
otra_vez_jan_ken:
	ld de,08dc4h		;8ad2
	call borra_guion_en_la_copia		;8ad5
	call dibujo_del_jan_ken		;8ad8
	call prepara_el_piedra_papel_tijera		;8adb
	jp manos_por_defecto		;8ade
despues_del_jan_ken:		; Paso 9: la partida se la lleva el ganador
	call parpadea_el_resultado		;8ae1
	call vuelca_la_pantalla		;8ae4
	call vuelca_los_sprites_del_duelo		;8ae7
	ld a,(0e012h)		;8aea
	or a			;8aed
	ret nz			;8aee
	xor a			;8aef
	ld (0e32dh),a		;8af0
	ld a,(0e342h)		;8af3   ; con la partida acabada, el ganador se apunta la partida
	or a			;8af6
	jr z,L_8B03		;8af7
	ld a,(0e324h)		;8af9
	dec a			;8afc
	xor 001h		;8afd
	ld b,a			;8aff
	jp gana_el_de_b		;8b00
L_8B03:
	ld a,(0e324h)		;8b03   ; si no, el de (0xE332) sale rebotado y se vuelve al tablero
	dec a			;8b06
	xor 001h		;8b07
	ld (0e332h),a		;8b09
	call borra_la_pantalla		;8b0c
	call monta_la_fuente		;8b0f
	call monta_los_graficos_de_la_fase		;8b12
	call dibuja_el_tablero		;8b15
	call monta_el_marco		;8b18
	call vuelca_la_pantalla		;8b1b
	call rebota		;8b1e
	ld a,017h		;8b21
	call toca_sonido		;8b23
	xor a			;8b26
	ld (0e001h),a		;8b27
	ret			;8b2a
mano_del_mando:		; Abajo, papel (0); izquierda, tijera (1); arriba, piedra (2). Sin pulsar, la que habia
	ld b,000h		;8b2b
	bit 1,a		;8b2d
	jr nz,L_8B3A		;8b2f
	inc b			;8b31
	bit 2,a		;8b32
	jr nz,L_8B3A		;8b34
	inc b			;8b36
	bit 0,a		;8b37
	ret z			;8b39
L_8B3A:
	ld (hl),b			;8b3a
	ret			;8b3b
pinta_una_mano:		; Una de las seis de 0x8B49: las tres de cada lado
	add a,a			;8b3c
	ld hl,08b49h		;8b3d
	call suma_a_a_hl		;8b40
	ld e,(hl)			;8b43
	inc hl			;8b44
	ld d,(hl)			;8b45
	jp guion_en_la_copia		;8b46

; ----------------------------------------------------------------------
; DATOS manos: Seis punteros a los dibujos de las tres manos (papel, tijera y
;   piedra), a la izquierda (0x8E2B, 0x8E35, 0x8E3F) y a la derecha (0x8E49,
;   0x8E53, 0x8E5D)
;   0x8b49..0x8b55  (12 bytes)
DATA_manos:
	defw 08e2bh,08e35h,08e3fh,08e49h,08e53h,08e5dh	; 8b49

; ======================================================================
; CODIGO 0x8b55..0x8b7f  (42 bytes)
; ======================================================================


parpadea_el_resultado:
	ld a,(0e003h)		;8b55
	and 00fh		;8b58
	ret nz			;8b5a
pinta_el_resultado:
	ld a,(0e003h)		;8b5b
	bit 4,a		;8b5e
	ld b,000h		;8b60
	jr z,L_8B65		;8b62
	inc b			;8b64
L_8B65:
	ld a,(0e324h)		;8b65
	dec a			;8b68
	add a,a			;8b69
	add a,b			;8b6a
	push af			;8b6b
	call pinta_de_la_tabla		;8b6c
	pop af			;8b6f
	add a,004h		;8b70
pinta_de_la_tabla:
	ld hl,08b7fh		;8b72
	add a,a			;8b75
	call suma_a_a_hl		;8b76
	ld e,(hl)			;8b79
	inc hl			;8b7a
	ld d,(hl)			;8b7b
	jp guion_en_la_copia		;8b7c

; ----------------------------------------------------------------------
; DATOS caras_del_resultado: Ocho punteros: la cara de cada Q*bert ganando y
;   perdiendo, con los ojos abiertos y cerrados (0x8E67-0x8F57)
;   0x8b7f..0x8b8f  (16 bytes)
DATA_caras_del_resultado:
	defw 08e67h,08e87h,08ea7h,08ecbh,08eefh,08f13h,08f37h,08f57h	; 8b7f

; ======================================================================
; CODIGO 0x8b8f..0x8bbf  (48 bytes)
; ======================================================================


parpadean_las_manos_del_jan_ken:
	ld hl,0e359h		;8b8f
	dec (hl)			;8b92
	ret nz			;8b93
	ld (hl),018h		;8b94
	inc hl			;8b96
	ld a,(hl)			;8b97
	xor 001h		;8b98
	ld (hl),a			;8b9a
	jr nz,L_8BAC		;8b9b
	ld de,08bbfh		;8b9d
	call guion_en_la_copia		;8ba0
	ld a,0e0h		;8ba3
	ld (0ec88h),a		;8ba5
	ld (0ec8ch),a		;8ba8
	ret			;8bab
L_8BAC:
	ld de,08be0h		;8bac
	call guion_en_la_copia		;8baf
	ld hl,06897h		;8bb2
	ld (0ec88h),hl		;8bb5
	ld hl,08897h		;8bb8
	ld (0ec8ch),hl		;8bbb
	ret			;8bbe

; ----------------------------------------------------------------------
; DATOS rotulos_del_jan_ken: Guiones de 0x871C: las manos escondidas (0x8BBF)
;   y a la vista (0x8BE0), "LET'S PLAY JAN-KEN" (0x8C01), "JAN-KEN!" (0x8C16),
;   " PON!" (0x8C21) y el ladrillo del recuadro (0x8C2C)
;   0x8bbf..0x8c3a  (123 bytes)
DATA_rotulos_del_jan_ken:
	defb 04ch,0efh,059h,058h,000h,000h,000h,000h	; 8bbf  L.YX....
	defb 022h,023h,0feh,06ch,0efh,05eh,05dh,000h	; 8bc7  "#.l.^].
	defb 000h,000h,000h,027h,028h,0feh,08ch,0efh	; 8bcf  ...'(...
	defb 062h,061h,000h,000h,000h,000h,02bh,02ch	; 8bd7  ba....+,
	defb 0ffh,04ch,0efh,059h,066h,000h,000h,000h	; 8bdf  .L.Yf...
	defb 000h,030h,023h,0feh,06ch,0efh,05eh,067h	; 8be7  .0#.l.^g
	defb 000h,000h,000h,000h,031h,028h,0feh,08ch	; 8bef  ....1(..
	defb 0efh,069h,068h,000h,000h,000h,000h,032h	; 8bf7  .ih....2
	defb 033h,0ffh,047h,0eeh,02ch,025h,034h,038h	; 8bff  3.G.,%48
	defb 033h,000h,030h,02ch,021h,039h,000h,02ah	; 8c07  3.0,!9.*
	defb 021h,02eh,020h,02bh,025h,02eh,0ffh,0adh	; 8c0f  !. +%...
	defb 0eeh,02ah,021h,02eh,020h,02bh,025h,02eh	; 8c17  .*!. +%.
	defb 04ah,0ffh,0adh,0eeh,000h,030h,02fh,02eh	; 8c1f  J....0/.
	defb 04bh,000h,000h,000h,0ffh,0aeh,0efh,0ebh	; 8c27  K.......
	defb 0ebh,0ebh,0ebh,0feh,0ceh,0efh,0ebh,0ebh	; 8c2f  ........
	defb 0ebh,0ebh,0ffh	; 8c37

; ======================================================================
; CODIGO 0x8c3a..0x8d16  (220 bytes)
; ======================================================================


borra_el_recuadro:		; Cuatro filas de 18 casillas desde 0xEE26
	ld hl,0ee26h		;8c3a
	ld c,004h		;8c3d
L_8C3F:
	ld b,012h		;8c3f
L_8C41:
	ld (hl),000h		;8c41
	inc hl			;8c43
	djnz L_8C41		;8c44
	ld a,00eh		;8c46
	call suma_a_a_hl		;8c48
	dec c			;8c4b
	jr nz,L_8C3F		;8c4c
	ret			;8c4e
copia_de_vram_a_vram:		; BC bytes de la VRAM en HL a la VRAM en DE, uno a uno con RDVRM y WRTVRM
	call 0004ah		;8c4f   ; BIOS RDVRM - Reads the content of VRAM
	ex de,hl			;8c52
	call 0004dh		;8c53   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;8c56
	inc hl			;8c57
	inc de			;8c58
	dec bc			;8c59
	ld a,b			;8c5a
	or c			;8c5b
	jr nz,copia_de_vram_a_vram		;8c5c
	ret			;8c5e
copia_de_vram_en_espejo:		; Lo mismo dando la vuelta a cada byte: el dibujo, reflejado
	call 0004ah		;8c5f   ; BIOS RDVRM - Reads the content of VRAM
	call da_la_vuelta_al_byte		;8c62
	ex de,hl			;8c65
	call 0004dh		;8c66   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;8c69
	inc hl			;8c6a
	inc de			;8c6b
	dec bc			;8c6c
	ld a,b			;8c6d
	or c			;8c6e
	jr nz,copia_de_vram_en_espejo		;8c6f
	ret			;8c71
da_la_vuelta_al_byte:
	push bc			;8c72
	ld c,a			;8c73
	ld b,008h		;8c74
L_8C76:
	rr c		;8c76
	rla			;8c78
	djnz L_8C76		;8c79
	pop bc			;8c7b
	ret			;8c7c
dibujo_del_jan_ken:
	ld de,08d3dh		;8c7d
	call guion_en_la_copia		;8c80
	jp vuelca_la_pantalla		;8c83

; ----------------------------------------------------------------------
; LOS GRAFICOS DEL DUELO: los sprites (0x96BA), nueve tiles desde el 0x43 (0x90A7 y 0x90DE) y los 186 tiles del tercer tercio (0x90E3 y 0x95EB). Los 45 ultimos se copian reflejados 45 tiles mas alla: las manos de la derecha son las de la izquierda dadas la vuelta.
; ----------------------------------------------------------------------
graficos_del_duelo:
	ld de,096bah		;8c86
	call guion_rle		;8c89
	ld hl,02218h		;8c8c
	ld de,090a7h		;8c8f
	call guion_rle_en_tres_bancos		;8c92
	ld hl,00218h		;8c95
	ld de,090deh		;8c98
	call guion_rle_en_tres_bancos		;8c9b
	ld hl,03000h		;8c9e
dibujos_grandes_en_hl:
	push hl			;8ca1
	ld de,090e3h		;8ca2   ; los patrones
	call vuelca_el_guion_con_destino_en_hl		;8ca5
	pop hl			;8ca8
	push hl			;8ca9
	ld de,0e000h		;8caa
	add hl,de			;8cad
	ld de,095ebh		;8cae   ; y los colores, 0x2000 antes (0xE000 = -0x2000)
	call vuelca_el_guion_con_destino_en_hl		;8cb1
	pop hl			;8cb4
	ld de,00468h		;8cb5   ; desde el tile 0x8D...
	add hl,de			;8cb8
	push hl			;8cb9
	ld de,00168h		;8cba   ; ...al 0xBA, reflejados
	add hl,de			;8cbd
	ex de,hl			;8cbe
	pop hl			;8cbf
	push de			;8cc0
	push hl			;8cc1
	ld bc,00168h		;8cc2
	call copia_de_vram_en_espejo		;8cc5
	pop hl			;8cc8   ; y sus colores, tal cual
	ld de,0e000h		;8cc9
	add hl,de			;8ccc
	pop de			;8ccd
	push hl			;8cce
	ld hl,0e000h		;8ccf
	add hl,de			;8cd2
	ex de,hl			;8cd3
	pop hl			;8cd4
	ld bc,00168h		;8cd5
	call copia_de_vram_a_vram		;8cd8
	ret			;8cdb
sprites_del_duelo:		; Los 0x35 bytes de 0x8FAA a 0xEC80
	ld hl,08faah		;8cdc
	ld de,0ec80h		;8cdf
	ld bc,00035h		;8ce2
	ldir		;8ce5
	ret			;8ce7
vuelca_los_sprites_del_duelo:
	ld hl,03b00h		;8ce8
	ld de,0ec80h		;8ceb
	ld bc,00035h		;8cee
	jp copia_a_vram		;8cf1
pinta_los_dos_cubos:		; El cubo acabado del segundo a la izquierda (0xEE27) y el del primero a la derecha (0xEE33)
	ld hl,0ee27h		;8cf4
	ld de,08d1fh		;8cf7
	call pinta_3x3		;8cfa
	ld hl,0ee33h		;8cfd
	ld de,08d16h		;8d00
pinta_3x3:
	ld c,003h		;8d03
L_8D05:
	ld b,003h		;8d05
L_8D07:
	ld a,(de)			;8d07
	ld (hl),a			;8d08
	inc hl			;8d09
	inc de			;8d0a
	djnz L_8D07		;8d0b
	ld a,01dh		;8d0d
	call suma_a_a_hl		;8d0f
	dec c			;8d12
	jr nz,L_8D05		;8d13
	ret			;8d15

; ----------------------------------------------------------------------
; DATOS cubos_acabados: Los nueve tiles del cubo acabado del primero
;   (0x88-0x90) y los del segundo (0xE1-0xE9)
;   0x8d16..0x8d28  (18 bytes)
DATA_cubos_acabados:
	defb 088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h	; 8d16  .........
	defb 0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h	; 8d1f  .........

; ======================================================================
; CODIGO 0x8d28..0x8d3d  (21 bytes)
; ======================================================================


pinta_dos_cifras:		; A en binario, en dos cifras
	call bcd_de_a		;8d28
	ld b,a			;8d2b
	and 0f0h		;8d2c
	rrca			;8d2e
	rrca			;8d2f
	rrca			;8d30
	rrca			;8d31
	add a,010h		;8d32
	ld (hl),a			;8d34
	ld a,b			;8d35
	and 00fh		;8d36
	add a,010h		;8d38
	inc hl			;8d3a
	ld (hl),a			;8d3b
	ret			;8d3c

; ----------------------------------------------------------------------
; DATOS dibujos_del_duelo: Guiones de 0x871C: el recuadro del
;   piedra-papel-tijera (0x8D3D), las manos (0x8D80, 0x8DC4 y las seis de
;   0x8E2B), las caras del resultado (0x8E67-0x8F57), "TIME OUT!" (0x8F77),
;   "DRAWN GAME" (0x8F83), "1P WIN!" (0x8F90) y "2P WIN!" (0x8F9D)
;   0x8d3d..0x8faa  (621 bytes)
DATA_dibujos_del_duelo:
	defb 02ah,0efh,083h,082h,057h,000h,000h,000h	; 8d3d  *...W...
	defb 000h,000h,000h,021h,04ch,04dh,000h,0feh	; 8d45  ...!LM..
	defb 049h,0efh,05ch,05bh,05ah,059h,058h,000h	; 8d4d  I.\[ZYX.
	defb 000h,000h,000h,022h,023h,024h,025h,026h	; 8d55  ..."#$%&
	defb 0feh,069h,0efh,060h,05fh,05eh,05eh,05dh	; 8d5d  .i.`_^^]
	defb 000h,000h,000h,000h,027h,028h,028h,029h	; 8d65  ....'(()
	defb 02ah,0feh,089h,0efh,065h,064h,063h,062h	; 8d6d  *...edcb
	defb 061h,000h,000h,000h,000h,02bh,02ch,02dh	; 8d75  a....+,-
	defb 02eh,02fh,0ffh,02ah,0efh,085h,084h,057h	; 8d7d  ./.*...W
	defb 000h,000h,000h,000h,000h,000h,021h,04eh	; 8d85  ......!N
	defb 04fh,0feh,049h,0efh,000h,06dh,06ch,06bh	; 8d8d  O.I..mlk
	defb 06ah,000h,000h,000h,000h,034h,035h,036h	; 8d95  j....456
	defb 037h,000h,0feh,069h,0efh,086h,070h,06fh	; 8d9d  7..i..po
	defb 05eh,06eh,000h,000h,000h,000h,038h,028h	; 8da5  ^n....8(
	defb 039h,03ah,050h,0feh,088h,0efh,088h,087h	; 8dad  9:P.....
	defb 073h,072h,071h,000h,000h,000h,000h,000h	; 8db5  srq.....
	defb 000h,03bh,03ch,03dh,051h,052h,0ffh,0b5h	; 8dbd  .;<=QR..
	defb 0eeh,046h,047h,0feh,0d4h,0eeh,046h,048h	; 8dc5  .FG...FH
	defb 049h,0feh,0f3h,0eeh,043h,044h,045h,0feh	; 8dcd  I...CDE.
	defb 012h,0efh,001h,0feh,02ah,0efh,085h,084h	; 8dd5  ....*...
	defb 057h,000h,006h,0bch,08fh,005h,076h,021h	; 8ddd  W.....v!
	defb 04eh,04fh,0feh,049h,0efh,000h,06dh,06ch	; 8de5  NO.I..ml
	defb 074h,06ah,008h,00dh,00eh,007h,034h,03eh	; 8ded  tj....4>
	defb 036h,037h,000h,0feh,069h,0efh,086h,070h	; 8df5  67..i..p
	defb 06fh,075h,06eh,000h,000h,000h,000h,040h	; 8dfd  oun....@
	defb 03fh,039h,03ah,050h,0feh,088h,0efh,088h	; 8e05  ?9:P....
	defb 087h,073h,072h,071h,009h,000h,000h,000h	; 8e0d  .srq....
	defb 000h,00ah,03bh,03ch,03dh,051h,052h,0feh	; 8e15  ..;<=QR.
	defb 0aeh,0efh,0bdh,00bh,00ch,090h,0feh,0ceh	; 8e1d  ........
	defb 0efh,08dh,08eh,0bbh,0bah,0ffh,06eh,0efh	; 8e25  ......n.
	defb 014h,015h,0feh,08eh,0efh,016h,017h,0ffh	; 8e2d  ........
	defb 06eh,0efh,00fh,010h,0feh,08eh,0efh,011h	; 8e35  n.......
	defb 012h,0ffh,06eh,0efh,00fh,010h,0feh,08eh	; 8e3d  ..n.....
	defb 0efh,011h,013h,0ffh,070h,0efh,01eh,01dh	; 8e45  ....p...
	defb 0feh,090h,0efh,020h,01fh,0ffh,070h,0efh	; 8e4d  ... ..p.
	defb 019h,018h,0feh,090h,0efh,01bh,01ah,0ffh	; 8e55  ........
	defb 070h,0efh,019h,018h,0feh,090h,0efh,01ch	; 8e5d  p.......
	defb 01ah,0ffh,02ah,0efh,077h,089h,0c0h,0feh	; 8e65  ..*.w...
	defb 049h,0efh,078h,05eh,08ah,079h,0feh,068h	; 8e6d  I.x^.y.h
	defb 0efh,0beh,07ah,07bh,05eh,07ch,07dh,0feh	; 8e75  ..z{^|}.
	defb 088h,0efh,000h,07eh,07fh,080h,081h,08bh	; 8e7d  ...~....
	defb 08ch,0ffh,02ah,0efh,077h,089h,0c0h,0feh	; 8e85  ..*.w...
	defb 049h,0efh,078h,05eh,08ah,079h,0feh,068h	; 8e8d  I.x^.y.h
	defb 0efh,000h,07ah,07bh,05eh,07ch,07dh,0feh	; 8e95  ..z{^|}.
	defb 088h,0efh,0bfh,07eh,07fh,080h,081h,08bh	; 8e9d  ...~....
	defb 08ch,0ffh,028h,0efh,000h,000h,0d8h,0d7h	; 8ea5  ..(.....
	defb 0c2h,0c1h,0feh,048h,0efh,000h,0c7h,0c4h	; 8ead  ...H....
	defb 0deh,0ddh,0c3h,0feh,068h,0efh,000h,0c8h	; 8eb5  ....h...
	defb 0d9h,0c6h,05eh,0c5h,0feh,088h,0efh,0dch	; 8ebd  ..^.....
	defb 0dbh,0dah,0cbh,0cah,0c9h,0ffh,028h,0efh	; 8ec5  ......(.
	defb 094h,095h,0aah,0abh,000h,000h,0feh,048h	; 8ecd  .......H
	defb 0efh,096h,0b0h,0b1h,097h,09ah,000h,0feh	; 8ed5  ........
	defb 068h,0efh,098h,05eh,099h,0ach,09bh,000h	; 8edd  h..^....
	defb 0feh,088h,0efh,09ch,09dh,09eh,0adh,0aeh	; 8ee5  ........
	defb 0afh,0ffh,032h,0efh,09fh,0a0h,0b2h,0b3h	; 8eed  ..2.....
	defb 000h,000h,0feh,052h,0efh,0a1h,0b8h,0b9h	; 8ef5  ...R....
	defb 0a2h,0a5h,000h,0feh,072h,0efh,0a3h,028h	; 8efd  ....r..(
	defb 0a4h,0b4h,0a6h,000h,0feh,092h,0efh,0a7h	; 8f05  ........
	defb 0a8h,0a9h,0b5h,0b6h,0b7h,0ffh,032h,0efh	; 8f0d  ......2.
	defb 000h,000h,0e0h,0dfh,0cdh,0cch,0feh,052h	; 8f15  .......R
	defb 0efh,000h,0d2h,0cfh,0e6h,0e5h,0ceh,0feh	; 8f1d  ........
	defb 072h,0efh,000h,0d3h,0e1h,0d1h,028h,0d0h	; 8f25  r.....(.
	defb 0feh,092h,0efh,0e4h,0e3h,0e2h,0d6h,0d5h	; 8f2d  ........
	defb 0d4h,0ffh,033h,0efh,093h,053h,041h,0feh	; 8f35  ..3..SA.
	defb 053h,0efh,043h,054h,028h,042h,0feh,072h	; 8f3d  S.CT(B.r
	defb 0efh,047h,046h,028h,045h,044h,091h,0feh	; 8f45  .GF(ED..
	defb 091h,0efh,056h,055h,04bh,04ah,049h,048h	; 8f4d  ..VUKJIH
	defb 000h,0ffh,033h,0efh,093h,053h,041h,0feh	; 8f55  ..3..SA.
	defb 053h,0efh,043h,054h,028h,042h,0feh,072h	; 8f5d  S.CT(B.r
	defb 0efh,047h,046h,028h,045h,044h,000h,0feh	; 8f65  .GF(ED..
	defb 091h,0efh,056h,055h,04bh,04ah,049h,048h	; 8f6d  ..VUKJIH
	defb 092h,0ffh,08ch,0edh,034h,029h,02dh,025h	; 8f75  ....4)-%
	defb 000h,02fh,035h,034h,04bh,0ffh,0cbh,0edh	; 8f7d  ./54K...
	defb 024h,032h,021h,037h,02eh,000h,027h,021h	; 8f85  $2!7..'!
	defb 02dh,025h,0ffh,0cbh,0edh,000h,000h,011h	; 8f8d  -%......
	defb 030h,000h,037h,029h,02eh,04bh,000h,0ffh	; 8f95  0.7).K..
	defb 0cbh,0edh,000h,000h,012h,030h,000h,037h	; 8f9d  .....0.7
	defb 029h,02eh,04bh,000h,0ffh	; 8fa5

; ----------------------------------------------------------------------
; DATOS sprites_del_duelo: Trece sprites (Y, X, patron, color) y el 0xD0 de
;   fin: 53 bytes
;   0x8faa..0x8fdf  (53 bytes)
DATA_sprites_del_duelo:
	defb 0e0h,000h,000h,00ah	; 8faa
	defb 0e0h,000h,004h,00ah	; 8fae
	defb 0e0h,000h,008h,00ah	; 8fb2
	defb 0e0h,000h,00ch,00ah	; 8fb6
	defb 0e0h,000h,010h,00ah	; 8fba
	defb 0e0h,000h,014h,00ah	; 8fbe
	defb 0e0h,000h,018h,005h	; 8fc2
	defb 0e0h,000h,01ch,007h	; 8fc6
	defb 0e0h,000h,020h,007h	; 8fca
	defb 0e0h,000h,024h,007h	; 8fce
	defb 0e0h,000h,028h,007h	; 8fd2
	defb 0e0h,000h,02ch,00ah	; 8fd6
	defb 0e0h,000h,030h,00ah	; 8fda
	defb 0d0h	; 8fde

; ======================================================================
; CODIGO 0x8fdf..0x9019  (58 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; LA VIDA EXTRA ESCONDIDA. Con un jugador, si los tres ultimos saltos de Q*bert han acabado un cubo cada uno, y tiene menos de 8 vidas, sale un objeto a la altura de Q*bert (una vez, hasta que se monta otra fase o Q*bert vuelve a salir) que cruza la pantalla de izquierda a derecha. Tocarlo da una vida, con su sonido, 0x11.
; ----------------------------------------------------------------------
vida_extra_escondida:
	ld a,(0e002h)		;8fdf
	bit 5,a		;8fe2
	ret nz			;8fe4
	ld a,(0e34bh)		;8fe5   ; (0xE34B): 0 sin salir, 1 cruzando, 2 ya salio
	dec a			;8fe8
	jr z,$+56		;8fe9
	dec a			;8feb
	ret z			;8fec
	ld a,(0e110h)		;8fed   ; con 8 vidas o mas, nada
	cp 008h		;8ff0
	ret nc			;8ff2
	ld hl,0e34dh		;8ff3   ; los tres ultimos saltos: 1, 1 y 1
	ld b,003h		;8ff6
	ld a,001h		;8ff8
L_8FFA:
	cp (hl)			;8ffa
	ret nz			;8ffb
	inc hl			;8ffc
	djnz L_8FFA		;8ffd
	ld a,001h		;8fff   ; sale
	ld (0e34bh),a		;9001
	ld hl,09019h		;9004   ; sus dos sprites, de 0x9019
	ld de,0e350h		;9007
	ld bc,00008h		;900a
	ldir		;900d
	ld a,(0e204h)		;900f   ; a la altura de Q*bert
	ld (0e350h),a		;9012
	ld (0e354h),a		;9015
	ret			;9018

; ----------------------------------------------------------------------
; DATOS objeto_de_la_vida: Sus dos sprites: el patron 0xD0 en rojo oscuro (6)
;   y el 0xD4 en blanco (15), en X 0
;   0x9019..0x9021  (8 bytes)
DATA_objeto_de_la_vida:
	defb 000h,000h,0d0h,006h	; 9019
	defb 000h,000h,0d4h,00fh	; 901d

; ======================================================================
; CODIGO 0x9021..0x90a7  (134 bytes)
; ======================================================================


cruza_el_objeto:
	ld de,(0e204h)		;9021   ; si toca a Q*bert...
	ld hl,0e350h		;9025
	call estan_cerca		;9028
	jr nc,avanza_el_objeto		;902b
	ld hl,0e110h		;902d   ; ...una vida
	jr da_la_vida		;9030
toca_el_segundo_sprite:
	ld de,(0e20ch)		;9032   ; CODIGO HUERFANO: la misma prueba con 0xE20C, el segundo sprite de Q*bert, que no llama nadie
	ld hl,0e350h		;9036
	call estan_cerca		;9039
	jr nc,avanza_el_objeto		;903c
	ld hl,0e110h		;903e
da_la_vida:
	inc (hl)			;9041
	ld a,(0e002h)		;9042   ; el marcador, de uno o del duelo
	bit 5,a		;9045
	jr nz,L_904E		;9047
	call pinta_el_marcador		;9049
	jr L_9051		;904c
L_904E:
	call pinta_el_marcador_del_duelo		;904e
L_9051:
	ld a,011h		;9051   ; el sonido 0x11
	call toca_sonido		;9053
	jr se_acabo_el_objeto		;9056
avanza_el_objeto:
	call vuelca_el_objeto		;9058
	ld hl,0e351h		;905b   ; un pixel a la derecha los dos sprites
	inc (hl)			;905e
	ld hl,0e355h		;905f
	inc (hl)			;9062
	ld a,(hl)			;9063   ; al llegar a 0xFE, se acabo
	cp 0feh		;9064
	ret c			;9066
	jr se_acabo_el_objeto		;9067
quita_el_objeto_de_la_vida:		; Fuera de la pantalla y la racha a cero
	ld a,0e0h		;9069
	ld (0e350h),a		;906b
	ld (0e354h),a		;906e
	ld hl,0e34bh		;9071
	ld de,0e34ch		;9074
	ld bc,00004h		;9077
	ld (hl),000h		;907a
	ldir		;907c
vuelca_el_objeto:		; Sus dos sprites a los planos 19 y 20
	ld hl,03b4ch		;907e
	ld de,0e350h		;9081
	ld bc,00008h		;9084
	jp copia_a_vram		;9087
se_acabo_el_objeto:
	call quita_el_objeto_de_la_vida		;908a
	ld a,002h		;908d
	ld (0e34bh),a		;908f
	ret			;9092
apunta_el_salto:		; Guarda A en la racha de tres (0xE34D-0xE34F), dando la vuelta: 1 cubo acabado, 0 girado sin acabar, 0x40 salto sobre un cubo ya acabado
	exx			;9093
	ld b,a			;9094
	ld hl,0e34ch		;9095
	ld a,(hl)			;9098
	inc (hl)			;9099
	cp 002h		;909a
	jr nz,L_90A0		;909c
	ld (hl),000h		;909e
L_90A0:
	inc hl			;90a0
	call suma_a_a_hl		;90a1
	ld (hl),b			;90a4
	exx			;90a5
	ret			;90a6

; ----------------------------------------------------------------------
; DATOS duelo_tiles_43: RLE de 0x4675 para los tiles 0x43-0x4B de los tres
;   tercios (72 bytes): el ladrillo y las letras grandes del recuadro del
;   duelo. Lo pone 0x8C8C
;   0x90a7..0x90de  (55 bytes)
DATA_duelo_tiles_43:
	defb 005h,000h,08eh,001h,003h,007h,00fh,01fh	; 90a7  ........
	defb 03fh,07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h	; 90af  ?.......
	defb 080h,00ah,000h,083h,001h,003h,007h,005h	; 90b7  ........
	defb 000h,08eh,080h,0c0h,0e0h,00fh,01fh,03fh	; 90bf  .......?
	defb 07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h	; 90c7  ........
	defb 008h,000h,002h,054h,004h,000h,087h,00ch	; 90cf  ...T....
	defb 01ch,018h,010h,000h,060h,060h,000h	; 90d7

; ----------------------------------------------------------------------
; DATOS duelo_color_43: Su color: un RLE de cinco bytes
;   0x90de..0x90e3  (5 bytes)
DATA_duelo_color_43:
	defb 038h,050h,010h,0f0h,000h	; 90de

; ----------------------------------------------------------------------
; DATOS duelo_dibujos: RLE de 0x46A6 con destino 0x3000: 186 tiles del tercer
;   tercio (1.488 bytes), las manos del piedra-papel-tijera y las caras
;   grandes de Q*bert. Los 45 ultimos se copian reflejados (0x8C5F)
;   0x90e3..0x95eb  (1288 bytes)
DATA_duelo_dibujos:
	defb 008h,000h,005h,000h,083h,001h,003h,007h	; 90e3  ........
	defb 00ah,003h,006h,000h,002h,0ffh,00ch,000h	; 90eb  ........
	defb 082h,0c3h,0f7h,006h,000h,082h,003h,00fh	; 90f3  ........
	defb 008h,0ffh,089h,001h,007h,00fh,01fh,03fh	; 90fb  .......?
	defb 07fh,07fh,0ffh,000h,003h,003h,003h,001h	; 9103  ........
	defb 081h,000h,004h,0c0h,003h,080h,005h,000h	; 910b  ........
	defb 083h,040h,038h,00fh,005h,000h,089h,003h	; 9113  .@8.....
	defb 006h,0e0h,000h,000h,007h,01fh,060h,080h	; 911b  ......`.
	defb 004h,000h,083h,080h,0f1h,001h,006h,000h	; 9123  ........
	defb 086h,080h,0dfh,0ffh,0fbh,0f7h,0f6h,004h	; 912b  ........
	defb 000h,002h,080h,095h,040h,0e0h,0f6h,0f9h	; 9133  ....@...
	defb 0f5h,04eh,036h,038h,000h,000h,0f8h,0bch	; 913b  .N68....
	defb 0cch,0f0h,038h,018h,000h,000h,060h,080h	; 9143  ..8...`.
	defb 080h,007h,000h,08eh,080h,0dfh,0ffh,0ffh	; 914b  ........
	defb 0feh,0f1h,000h,000h,060h,0e0h,0c0h,000h	; 9153  ....`...
	defb 0c0h,0e0h,003h,0ffh,096h,0feh,077h,03bh	; 915b  ......w;
	defb 01dh,00ch,0f8h,09ch,0ech,0f0h,038h,098h	; 9163  ......8.
	defb 0c0h,0c0h,000h,000h,001h,0fbh,0ffh,0dfh	; 916b  ........
	defb 0efh,06fh,0ffh,003h,000h,002h,001h,095h	; 9173  .o......
	defb 002h,007h,06fh,09fh,0afh,072h,06ch,01ch	; 917b  ..o..rl.
	defb 000h,000h,01fh,03dh,033h,00fh,01ch,018h	; 9183  ...=3...
	defb 000h,000h,006h,001h,001h,007h,000h,08eh	; 918b  ........
	defb 001h,0fbh,0ffh,0ffh,07fh,08fh,000h,000h	; 9193  ........
	defb 006h,007h,003h,000h,003h,007h,003h,0ffh	; 919b  ........
	defb 097h,07fh,0eeh,0dch,0b8h,030h,01fh,039h	; 91a3  .....0.9
	defb 037h,00fh,01ch,019h,003h,003h,000h,003h	; 91ab  7.......
	defb 00fh,03fh,07fh,07fh,0ffh,0ffh,001h,001h	; 91b3  .?......
	defb 003h,003h,083h,00fh,03fh,07fh,004h,0fbh	; 91bb  ....?...
	defb 084h,0ffh,0efh,0e7h,0f8h,004h,0bfh,084h	; 91c3  ........
	defb 0ffh,0efh,08fh,07fh,003h,0e0h,082h,0f0h	; 91cb  ........
	defb 0f8h,003h,0fch,002h,000h,08bh,006h,00fh	; 91d3  ........
	defb 01fh,01fh,03fh,03eh,07bh,073h,0f7h,0f7h	; 91db  ..?>{s..
	defb 067h,003h,007h,008h,0ffh,098h,0feh,0beh	; 91e3  g.......
	defb 0deh,0bch,07bh,077h,0b7h,0cfh,07eh,0feh	; 91eb  ..{w..~.
	defb 0fch,0fch,0f8h,0f8h,0f0h,0f0h,003h,003h	; 91f3  ........
	defb 001h,001h,007h,03fh,059h,037h,004h,0ffh	; 91fb  ...?Y7..
	defb 084h,07fh,09fh,0e3h,0fch,005h,0ffh,08eh	; 9203  ........
	defb 0f3h,0efh,007h,0ffh,0ffh,0fbh,0fbh,0fch	; 920b  ........
	defb 0ffh,0edh,0f6h,0e0h,0c0h,080h,003h,000h	; 9213  ........
	defb 0a2h,080h,0c0h,001h,039h,03bh,07bh,073h	; 921b  ....9;{s
	defb 07bh,07fh,07fh,03bh,01bh,007h,007h,003h	; 9223  {..;....
	defb 00bh,01dh,01dh,066h,09fh,0ffh,03fh,03fh	; 922b  ...f..??
	defb 01fh,00fh,007h,0ffh,07fh,0bfh,0bfh,0dfh	; 9233  ........
	defb 0dfh,0c7h,080h,003h,001h,005h,003h,002h	; 923b  ........
	defb 0ffh,004h,0dfh,008h,0ffh,002h,0fdh,002h	; 9243  ........
	defb 0e0h,002h,0f0h,002h,0f8h,002h,0fch,003h	; 924b  ........
	defb 003h,08ah,00bh,03dh,07dh,071h,000h,0feh	; 9253  ...=}q..
	defb 0efh,0f7h,0f9h,0feh,003h,0ffh,085h,0feh	; 925b  ........
	defb 07fh,0bfh,0bfh,07fh,004h,0ffh,002h,07fh	; 9263  ........
	defb 085h,03fh,00fh,003h,014h,02fh,004h,0ffh	; 926b  .?.../..
	defb 084h,0f8h,0e7h,019h,0d7h,003h,0ffh,083h	; 9273  ........
	defb 0fdh,03eh,0feh,004h,0ffh,004h,0bbh,002h	; 927b  .>......
	defb 0ffh,002h,0dfh,082h,0ffh,0dfh,004h,0ffh	; 9283  ........
	defb 088h,003h,083h,083h,08bh,0cdh,0cdh,0c1h	; 928b  ........
	defb 0c0h,005h,000h,086h,0c0h,0f8h,0feh,000h	; 9293  ........
	defb 080h,080h,003h,0c0h,002h,0e0h,002h,000h	; 929b  ........
	defb 086h,005h,007h,003h,003h,007h,00fh,003h	; 92a3  ........
	defb 0e0h,002h,0c0h,083h,080h,000h,0c0h,003h	; 92ab  ........
	defb 0ffh,081h,0f1h,003h,0feh,086h,0deh,00fh	; 92b3  ........
	defb 09fh,0ffh,07fh,07fh,003h,0ffh,002h,000h	; 92bb  ........
	defb 081h,001h,003h,000h,084h,001h,003h,0c0h	; 92c3  ........
	defb 080h,006h,000h,002h,0efh,086h,0f7h,0f8h	; 92cb  ........
	defb 0f8h,0e0h,018h,0fch,006h,0ffh,081h,0f4h	; 92d3  ........
	defb 003h,0ffh,089h,0efh,0dfh,03fh,007h,060h	; 92db  .....?.`
	defb 0f3h,000h,0f8h,0feh,005h,0ffh,002h,000h	; 92e3  ........
	defb 003h,080h,003h,0c0h,084h,000h,0e0h,0f8h	; 92eb  ........
	defb 0feh,004h,0ffh,002h,000h,004h,080h,002h	; 92f3  ........
	defb 0c0h,004h,000h,086h,080h,0c0h,0e0h,0f0h	; 92fb  ........
	defb 0f8h,0fch,004h,0ffh,089h,00fh,000h,080h	; 9303  ........
	defb 080h,0c0h,0c0h,0f8h,0fch,0f8h,006h,000h	; 930b  ........
	defb 084h,00fh,003h,00fh,07fh,007h,0ffh,09ah	; 9313  ........
	defb 01fh,00fh,01fh,07fh,0ffh,0fch,0e0h,0ffh	; 931b  ........
	defb 000h,001h,003h,007h,01fh,03fh,01fh,000h	; 9323  .....?..
	defb 000h,0c0h,0f0h,0fch,0feh,0feh,0ffh,0ffh	; 932b  ........
	defb 080h,080h,003h,0c0h,083h,0f0h,0fch,0feh	; 9333  ........
	defb 004h,0dfh,084h,0ffh,0f7h,0e7h,01fh,004h	; 933b  ........
	defb 0fdh,084h,0ffh,0f7h,0f1h,0feh,003h,007h	; 9343  ........
	defb 082h,00fh,01fh,003h,03fh,002h,000h,08bh	; 934b  ....?...
	defb 060h,0f0h,0f8h,0f8h,0fch,07ch,0deh,0ceh	; 9353  `....|..
	defb 0efh,0efh,0e6h,003h,0e0h,008h,0ffh,098h	; 935b  ........
	defb 07fh,07dh,07bh,03dh,0deh,0eeh,0edh,0f3h	; 9363  .}{=....
	defb 07eh,07fh,03fh,03fh,01fh,01fh,00fh,00fh	; 936b  ~.??....
	defb 0c0h,0c0h,080h,080h,0e0h,0fch,09ah,0ech	; 9373  ........
	defb 004h,0ffh,084h,0feh,0f9h,0c7h,03fh,005h	; 937b  ......?.
	defb 0ffh,08eh,0cfh,0f7h,0e0h,0ffh,0ffh,0dfh	; 9383  ........
	defb 0dfh,03fh,0ffh,0b7h,06fh,007h,003h,001h	; 938b  .?..o...
	defb 003h,000h,0a2h,001h,003h,080h,09ch,0dch	; 9393  ........
	defb 0deh,0ceh,0deh,0feh,0feh,0dch,0d8h,0e0h	; 939b  ........
	defb 0e0h,0c0h,0d0h,0b8h,0b8h,066h,0f9h,0ffh	; 93a3  .....f..
	defb 0fch,0fch,0f8h,0f0h,0e0h,0ffh,0feh,0fdh	; 93ab  ........
	defb 0fdh,0fbh,0fbh,0e3h,001h,003h,080h,005h	; 93b3  ........
	defb 0c0h,002h,0ffh,004h,0fbh,008h,0ffh,002h	; 93bb  ........
	defb 0bfh,002h,007h,002h,00fh,002h,01fh,002h	; 93c3  ........
	defb 03fh,003h,0c0h,08ah,0d0h,0bch,0beh,08eh	; 93cb  ?.......
	defb 000h,07fh,0f7h,0efh,09fh,07fh,003h,0ffh	; 93d3  ........
	defb 085h,07fh,0feh,0fdh,0fdh,0feh,004h,0ffh	; 93db  ........
	defb 002h,0feh,085h,0fch,0f0h,0c0h,028h,0f4h	; 93e3  ......(.
	defb 004h,0ffh,084h,01fh,0e7h,098h,0ebh,003h	; 93eb  ........
	defb 0ffh,083h,0bfh,07ch,07fh,004h,0ffh,004h	; 93f3  ...|....
	defb 0ddh,002h,0ffh,002h,0fbh,082h,0ffh,0fbh	; 93fb  ........
	defb 004h,0ffh,088h,00fh,007h,01bh,03dh,07ch	; 9403  ......=|
	defb 0f8h,0f0h,0e0h,005h,000h,086h,003h,01fh	; 940b  ........
	defb 07fh,000h,001h,001h,003h,003h,002h,007h	; 9413  ........
	defb 002h,000h,086h,0a0h,0e0h,0c0h,0c0h,0e0h	; 941b  ........
	defb 0f0h,003h,007h,002h,003h,083h,001h,000h	; 9423  ........
	defb 003h,003h,0ffh,081h,08fh,003h,07fh,086h	; 942b  ........
	defb 07bh,0f0h,0f9h,0ffh,0feh,0feh,003h,0ffh	; 9433  {.......
	defb 002h,000h,081h,080h,003h,000h,084h,080h	; 943b  ........
	defb 0c0h,003h,001h,006h,000h,002h,0f7h,086h	; 9443  ........
	defb 0efh,01fh,01fh,007h,018h,03fh,006h,0ffh	; 944b  .....?..
	defb 081h,02fh,003h,0ffh,089h,0f7h,0fbh,0fch	; 9453  ./......
	defb 0e0h,006h,0cfh,000h,0e0h,080h,007h,000h	; 945b  ........
	defb 003h,001h,003h,003h,084h,000h,0f8h,0e0h	; 9463  ........
	defb 080h,004h,0ffh,002h,000h,004h,001h,002h	; 946b  ........
	defb 003h,004h,000h,086h,001h,003h,007h,0f0h	; 9473  ........
	defb 0e0h,0c0h,004h,0ffh,089h,0f0h,000h,001h	; 947b  ........
	defb 001h,003h,003h,01fh,03fh,01fh,006h,000h	; 9483  ....?...
	defb 084h,00fh,03fh,00fh,001h,007h,0ffh,092h	; 948b  ..?.....
	defb 0f8h,00fh,007h,001h,0ffh,03fh,007h,000h	; 9493  .....?..
	defb 000h,080h,0c0h,0e0h,0f8h,0fch,0f8h,000h	; 949b  ........
	defb 007h,001h,003h,0bfh,08bh,0ffh,0fbh,0fbh	; 94a3  ........
	defb 080h,0f0h,0ffh,00fh,0bfh,000h,0fbh,0fbh	; 94ab  ........
	defb 004h,000h,08ch,0f0h,0feh,00fh,001h,0ffh	; 94b3  ........
	defb 0feh,001h,003h,0ffh,0f0h,01fh,07fh,003h	; 94bb  ........
	defb 000h,08dh,090h,004h,062h,033h,030h,010h	; 94c3  ....b30.
	defb 000h,04ch,006h,026h,000h,030h,030h,006h	; 94cb  .L.&.00.
	defb 000h,002h,001h,004h,000h,09ch,040h,0e0h	; 94d3  ......@.
	defb 0f1h,0f3h,000h,000h,003h,01fh,07fh,0ffh	; 94db  ........
	defb 0ffh,0cfh,0fbh,077h,077h,06fh,02fh,02fh	; 94e3  ...wwo//
	defb 01fh,01fh,0e7h,0efh,09fh,07eh,0fch,0f9h	; 94eb  .....~..
	defb 0f7h,0cfh,005h,01fh,002h,00fh,085h,007h	; 94f3  ........
	defb 0ffh,0ffh,0feh,0feh,004h,0fdh,006h,000h	; 94fb  ........
	defb 002h,080h,090h,060h,0e0h,010h,0b0h,0e0h	; 9503  ...`....
	defb 0c0h,0c0h,080h,007h,003h,001h,000h,007h	; 950b  ........
	defb 01fh,073h,0afh,004h,0ffh,085h,07fh,08fh	; 9513  .s......
	defb 0f0h,0ffh,0feh,003h,0ffh,082h,0fch,083h	; 951b  ........
	defb 006h,000h,09ch,040h,0e0h,0f1h,0f3h,000h	; 9523  ...@....
	defb 000h,003h,01fh,07fh,0ffh,0ffh,0cfh,0fbh	; 952b  ........
	defb 077h,077h,06fh,02fh,02fh,01fh,01fh,0e7h	; 9533  wwo//...
	defb 0efh,09fh,07eh,0fch,0f9h,0f7h,0cfh,005h	; 953b  ..~.....
	defb 01fh,002h,00fh,085h,007h,0ffh,0ffh,0feh	; 9543  ........
	defb 0feh,004h,0fdh,006h,000h,002h,080h,090h	; 954b  ........
	defb 060h,0e0h,010h,0b0h,0e0h,0c0h,0c0h,080h	; 9553  `.......
	defb 007h,003h,001h,000h,007h,01fh,073h,0afh	; 955b  ......s.
	defb 004h,0ffh,085h,07fh,08fh,0f0h,0ffh,0feh	; 9563  ........
	defb 003h,0ffh,082h,0fch,083h,004h,000h,086h	; 956b  ........
	defb 007h,001h,000h,0ffh,0ffh,09fh,003h,000h	; 9573  ........
	defb 003h,080h,002h,0c0h,094h,0bch,07eh,0ffh	; 957b  ......~.
	defb 0ffh,00eh,01fh,03fh,03eh,01ch,07ch,083h	; 9583  ...?>.|.
	defb 03fh,0ffh,0ffh,07fh,007h,040h,0dch,03eh	; 958b  ?....@.>
	defb 007h,004h,0ffh,003h,000h,092h,080h,0f0h	; 9593  ........
	defb 0f0h,0e0h,080h,087h,0c0h,05fh,03fh,0bfh	; 959b  ....._?.
	defb 0dch,0e3h,0ffh,00fh,07fh,078h,0dfh,00fh	; 95a3  .....x..
	defb 003h,0ffh,002h,000h,082h,0f8h,0feh,003h	; 95ab  ........
	defb 0ffh,081h,09fh,003h,000h,003h,080h,002h	; 95b3  ........
	defb 0c0h,094h,0bch,07eh,0ffh,0ffh,0f1h,0e0h	; 95bb  ...~....
	defb 0c0h,0c1h,0e3h,07ch,083h,03fh,0ffh,0ffh	; 95c3  ...|.?..
	defb 07fh,007h,040h,0dch,0c0h,0f8h,004h,0ffh	; 95cb  ..@.....
	defb 003h,000h,092h,080h,0f0h,0f0h,0e0h,080h	; 95d3  ........
	defb 087h,037h,05fh,03fh,0bfh,0dch,0e3h,0ffh	; 95db  .7_?....
	defb 00fh,07fh,087h,0dfh,00fh,003h,0ffh,000h	; 95e3  ........

; ----------------------------------------------------------------------
; DATOS duelo_dibujos_color: El color de esos 186 tiles, a 0x1000
;   0x95eb..0x96ba  (207 bytes)
DATA_duelo_dibujos_color:
	defb 008h,010h,008h,050h,018h,060h,010h,070h	; 95eb  ...P.`.p
	defb 018h,040h,081h,0d0h,007h,040h,010h,0f4h	; 95f3  .@...@..
	defb 058h,074h,008h,0d4h,081h,044h,03fh,0d4h	; 95fb  Xt...D?.
	defb 07fh,0d0h,00bh,0d0h,081h,0ddh,07fh,0d0h	; 9603  ........
	defb 04fh,0d0h,007h,0dah,004h,0a0h,005h,0d0h	; 960b  O.......
	defb 007h,0dah,005h,0a0h,00ah,0d0h,004h,0dah	; 9613  ........
	defb 005h,0d0h,003h,0a0h,00ah,0d0h,00bh,0dah	; 961b  ........
	defb 081h,0d0h,003h,0dah,003h,0d0h,081h,000h	; 9623  ........
	defb 004h,0a0h,004h,0d0h,07fh,050h,07fh,050h	; 962b  .....P.P
	defb 05bh,050h,007h,0a5h,004h,0a0h,005h,050h	; 9633  [P.....P
	defb 003h,0a5h,004h,050h,005h,0a0h,00ah,050h	; 963b  ...P...P
	defb 003h,0a5h,006h,050h,003h,0a0h,00ah,050h	; 9643  ...P...P
	defb 004h,0a5h,008h,050h,003h,0a5h,004h,050h	; 964b  ...P...P
	defb 081h,080h,003h,0a0h,004h,050h,090h,074h	; 9653  .....P.t
	defb 070h,070h,050h,040h,000h,070h,050h,074h	; 965b  ppP@.pPt
	defb 074h,070h,075h,040h,070h,070h,050h,006h	; 9663  tpu@ppP.
	defb 070h,002h,074h,002h,040h,086h,074h,054h	; 966b  p.t.@.tT
	defb 040h,040h,074h,054h,010h,070h,008h,0a0h	; 9673  @@tT.p..
	defb 058h,050h,05ah,0d0h,003h,0a5h,006h,050h	; 967b  XPZ....P
	defb 002h,0a0h,007h,050h,005h,0a5h,007h,050h	; 9683  ...P...P
	defb 002h,0a0h,002h,0a5h,004h,050h,004h,0a0h	; 968b  .....P..
	defb 005h,050h,081h,085h,008h,050h,081h,085h	; 9693  .P...P..
	defb 007h,050h,005h,0dah,004h,0d0h,002h,0a0h	; 969b  .P......
	defb 007h,0d0h,005h,0dah,007h,0d0h,002h,0a0h	; 96a3  ........
	defb 006h,0dah,004h,0a0h,005h,0d0h,081h,0d8h	; 96ab  ........
	defb 008h,0d0h,081h,0d8h,005h,0d0h,000h	; 96b3

; ----------------------------------------------------------------------
; DATOS duelo_sprites: RLE de 0x46A0 con destino 0x1800: los patrones de 13
;   sprites del duelo (416 bytes)
;   0x96ba..0x97ba  (256 bytes)
DATA_duelo_sprites:
	defb 000h,018h,008h,000h,091h,038h,01ch,00ch	; 96ba  .....8..
	defb 008h,003h,003h,001h,000h,000h,004h,00ch	; 96c2  ........
	defb 00ch,008h,000h,018h,030h,020h,004h,000h	; 96ca  ....0 ..
	defb 003h,080h,089h,000h,020h,030h,030h,010h	; 96d2  .... 00.
	defb 000h,018h,00ch,004h,004h,000h,003h,001h	; 96da  ........
	defb 008h,000h,087h,01ch,038h,030h,010h,0c0h	; 96e2  ....80..
	defb 0c0h,080h,00ch,000h,084h,060h,0e0h,0e0h	; 96ea  .....`..
	defb 0c0h,02ch,000h,084h,006h,007h,007h,003h	; 96f2  .,......
	defb 009h,000h,002h,001h,002h,000h,08fh,003h	; 96fa  ........
	defb 007h,006h,004h,004h,01ch,038h,038h,030h	; 9702  .....880
	defb 010h,020h,0e0h,0c0h,0c0h,080h,005h,000h	; 970a  . ......
	defb 08bh,020h,038h,01ch,01ch,00ch,008h,004h	; 9712  . 8.....
	defb 007h,003h,003h,001h,00dh,000h,002h,080h	; 971a  ........
	defb 002h,000h,08fh,0c0h,0e0h,060h,020h,00fh	; 9722  .....` .
	defb 01fh,03fh,07fh,0feh,0fch,0f8h,0f0h,0e0h	; 972a  .?......
	defb 0c0h,080h,005h,000h,083h,0e0h,0c0h,080h	; 9732  ........
	defb 011h,000h,002h,001h,003h,003h,003h,007h	; 973a  ........
	defb 004h,00fh,087h,01eh,038h,070h,0e0h,0c0h	; 9742  ....8p..
	defb 080h,080h,009h,000h,081h,00fh,003h,00ch	; 974a  ........
	defb 003h,006h,002h,003h,002h,001h,00eh,000h	; 9752  ........
	defb 002h,080h,08ch,0c0h,0e0h,070h,038h,01eh	; 975a  .....p8.
	defb 07bh,01bh,00eh,0c7h,063h,021h,001h,009h	; 9762  {...c!..
	defb 000h,002h,0c0h,084h,080h,000h,080h,080h	; 976a  ........
	defb 003h,0c0h,003h,060h,004h,030h,009h,000h	; 9772  ...`.0..
	defb 002h,001h,085h,003h,007h,00eh,01ch,078h	; 977a  .......x
	defb 004h,030h,003h,060h,003h,0c0h,002h,080h	; 9782  .0.`....
	defb 004h,000h,002h,0c0h,08bh,040h,000h,030h	; 978a  .....@.0
	defb 03ch,01eh,00eh,00eh,006h,000h,001h,001h	; 9792  <.......
	defb 00eh,000h,085h,0e0h,0f0h,0f0h,070h,030h	; 979a  ......p0
	defb 00bh,000h,092h,007h,00fh,00fh,00eh,00ch	; 97a2  ........
	defb 003h,003h,002h,000h,00ch,03ch,078h,070h	; 97aa  .....<xp
	defb 070h,060h,000h,080h,080h,003h,000h,000h	; 97b2  p`......

; ----------------------------------------------------------------------
; DATOS cero_suelto: Un 0x00 detras del fin del RLE de 0x96BA, que no lee
;   nadie
;   0x97ba..0x97bb  (1 bytes)
DATA_cero_suelto:
	defb 000h	; 97ba

; ----------------------------------------------------------------------
; DATOS patron_de_la_cara: Un sprite de 16x16 (32 bytes) que 0x7C68 pone en el
;   patron 0 para la cara grande del marcador
;   0x97bb..0x97db  (32 bytes)
DATA_patron_de_la_cara:
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 97bb  ........
	defb 000h,000h,000h,007h,00fh,00fh,00eh,00ch	; 97c3  ........
	defb 003h,003h,002h,000h,00ch,03ch,078h,070h	; 97cb  .....<xp
	defb 070h,060h,000h,080h,080h,000h,000h,000h	; 97d3  p`......

; ----------------------------------------------------------------------
; DATOS tableros: Las 50 fases, 81 bytes cada una: la cuadricula de 9x9 fila a
;   fila. 0xFF es hueco; cualquier otro, el giro de ese cubo (0 a 23). La
;   casilla 0 es el modelo que hay que conseguir, y en las fases 31-50, que
;   son las del duelo, la 1 es el modelo del segundo
;   0x97db..0xa7ad  (4050 bytes)
DATA_tableros:
	defb 000h,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh	; 97db  .........
	defb 0ffh,0ffh,0ffh,011h,0ffh,013h,0ffh,0ffh,0ffh	; 97e4  .........
	defb 0ffh,0ffh,004h,0ffh,005h,0ffh,007h,0ffh,0ffh	; 97ed  .........
	defb 0ffh,007h,0ffh,008h,0ffh,009h,0ffh,00ah,0ffh	; 97f6  .........
	defb 00bh,0ffh,006h,0ffh,005h,0ffh,006h,0ffh,005h	; 97ff  .........
	defb 0ffh,010h,0ffh,011h,0ffh,012h,0ffh,013h,0ffh	; 9808  .........
	defb 0ffh,0ffh,014h,0ffh,015h,0ffh,016h,0ffh,0ffh	; 9811  .........
	defb 0ffh,0ffh,0ffh,017h,0ffh,004h,0ffh,0ffh,0ffh	; 981a  .........
	defb 0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh	; 9823  .........
	defb 00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 982c  .........
	defb 0ffh,0ffh,0ffh,0ffh,014h,0ffh,0ffh,0ffh,0ffh	; 9835  .........
	defb 0ffh,0ffh,0ffh,006h,0ffh,013h,0ffh,0ffh,0ffh	; 983e  .........
	defb 002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh,002h	; 9847  .........
	defb 0ffh,007h,0ffh,008h,0ffh,003h,0ffh,002h,0ffh	; 9850  .........
	defb 002h,0ffh,012h,0ffh,013h,0ffh,014h,0ffh,015h	; 9859  .........
	defb 0ffh,002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh	; 9862  .........
	defb 002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh,006h	; 986b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9874  .........
	defb 013h,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh	; 987d  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,00ah,0ffh,0ffh,0ffh	; 9886  .........
	defb 0ffh,0ffh,003h,0ffh,0ffh,0ffh,005h,0ffh,0ffh	; 988f  .........
	defb 0ffh,001h,0ffh,00ah,0ffh,002h,0ffh,00ah,0ffh	; 9898  .........
	defb 001h,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,00eh	; 98a1  .........
	defb 0ffh,00ah,0ffh,001h,0ffh,011h,0ffh,001h,0ffh	; 98aa  .........
	defb 0ffh,0ffh,000h,0ffh,0ffh,0ffh,000h,0ffh,0ffh	; 98b3  .........
	defb 0ffh,0ffh,0ffh,00ah,0ffh,001h,0ffh,0ffh,0ffh	; 98bc  .........
	defb 0ffh,0ffh,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh	; 98c5  .........
	defb 002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 98ce  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 98d7  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 98e0  .........
	defb 0ffh,0ffh,009h,0ffh,009h,0ffh,008h,0ffh,0ffh	; 98e9  .........
	defb 0ffh,004h,0ffh,005h,0ffh,006h,0ffh,007h,0ffh	; 98f2  .........
	defb 008h,0ffh,009h,0ffh,00ah,0ffh,00bh,0ffh,008h	; 98fb  .........
	defb 0ffh,009h,0ffh,009h,0ffh,00bh,0ffh,010h,0ffh	; 9904  .........
	defb 0ffh,0ffh,011h,0ffh,012h,0ffh,013h,0ffh,0ffh	; 990d  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9916  .........
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 991f  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9928  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9931  .........
	defb 0ffh,0ffh,0ffh,0ffh,006h,0ffh,0ffh,0ffh,0ffh	; 993a  .........
	defb 0ffh,0ffh,0ffh,00ah,0ffh,00ah,0ffh,0ffh,0ffh	; 9943  .........
	defb 0ffh,0ffh,00bh,0ffh,00bh,0ffh,00bh,0ffh,0ffh	; 994c  .........
	defb 0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh	; 9955  .........
	defb 006h,0ffh,005h,0ffh,00bh,0ffh,004h,0ffh,005h	; 995e  .........
	defb 0ffh,00bh,0ffh,006h,0ffh,00ah,0ffh,00bh,0ffh	; 9967  .........
	defb 001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9970  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9979  .........
	defb 0ffh,011h,0ffh,011h,0ffh,004h,0ffh,005h,0ffh	; 9982  .........
	defb 0ffh,0ffh,006h,0ffh,007h,0ffh,008h,0ffh,0ffh	; 998b  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,00ah,0ffh,0ffh,0ffh	; 9994  .........
	defb 0ffh,0ffh,00bh,0ffh,015h,0ffh,005h,0ffh,0ffh	; 999d  .........
	defb 0ffh,016h,0ffh,005h,0ffh,010h,0ffh,011h,0ffh	; 99a6  .........
	defb 012h,0ffh,013h,0ffh,014h,0ffh,015h,0ffh,016h	; 99af  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 99b8  .........
	defb 002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h	; 99c1  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh	; 99ca  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,004h	; 99d3  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,009h,0ffh	; 99dc  .........
	defb 0ffh,0ffh,0ffh,0ffh,013h,0ffh,011h,0ffh,005h	; 99e5  .........
	defb 0ffh,0ffh,0ffh,016h,0ffh,011h,0ffh,00ah,0ffh	; 99ee  .........
	defb 0ffh,0ffh,005h,0ffh,014h,0ffh,012h,0ffh,006h	; 99f7  .........
	defb 0ffh,013h,0ffh,017h,0ffh,012h,0ffh,00bh,0ffh	; 9a00  .........
	defb 004h,0ffh,014h,0ffh,015h,0ffh,005h,0ffh,007h	; 9a09  .........
	defb 003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a12  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a1b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a24  .........
	defb 0ffh,0ffh,0ffh,0ffh,008h,0ffh,009h,0ffh,011h	; 9a2d  .........
	defb 0ffh,0ffh,0ffh,007h,0ffh,00ah,0ffh,010h,0ffh	; 9a36  .........
	defb 0ffh,0ffh,006h,0ffh,00bh,0ffh,011h,0ffh,0ffh	; 9a3f  .........
	defb 0ffh,005h,0ffh,006h,0ffh,012h,0ffh,0ffh,0ffh	; 9a48  .........
	defb 004h,0ffh,004h,0ffh,013h,0ffh,0ffh,0ffh,0ffh	; 9a51  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a5a  .........
	defb 004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a63  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a6c  .........
	defb 0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,014h,0ffh	; 9a75  .........
	defb 0ffh,0ffh,009h,0ffh,0ffh,0ffh,014h,0ffh,0ffh	; 9a7e  .........
	defb 0ffh,007h,0ffh,00ch,0ffh,00fh,0ffh,015h,0ffh	; 9a87  .........
	defb 0ffh,0ffh,008h,0ffh,00eh,0ffh,012h,0ffh,0ffh	; 9a90  .........
	defb 0ffh,006h,0ffh,00dh,0ffh,008h,0ffh,009h,0ffh	; 9a99  .........
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,013h,0ffh,0ffh	; 9aa2  .........
	defb 0ffh,00ch,0ffh,0ffh,0ffh,0ffh,0ffh,00dh,0ffh	; 9aab  .........
	defb 005h,0ffh,0ffh,0ffh,006h,0ffh,0ffh,0ffh,0ffh	; 9ab4  .........
	defb 0ffh,0ffh,0ffh,007h,0ffh,008h,0ffh,0ffh,0ffh	; 9abd  .........
	defb 0ffh,0ffh,009h,0ffh,007h,0ffh,008h,0ffh,0ffh	; 9ac6  .........
	defb 0ffh,00ch,0ffh,00dh,0ffh,00eh,0ffh,00fh,0ffh	; 9acf  .........
	defb 00ch,0ffh,009h,0ffh,012h,0ffh,013h,0ffh,014h	; 9ad8  .........
	defb 0ffh,0ffh,0ffh,015h,0ffh,014h,0ffh,0ffh,0ffh	; 9ae1  .........
	defb 0ffh,0ffh,001h,0ffh,002h,0ffh,003h,0ffh,0ffh	; 9aea  .........
	defb 0ffh,0ffh,0ffh,006h,0ffh,009h,0ffh,0ffh,0ffh	; 9af3  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9afc  .........
	defb 002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b05  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,004h,0ffh	; 9b0e  .........
	defb 0ffh,0ffh,0ffh,0ffh,012h,0ffh,010h,0ffh,0ffh	; 9b17  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh,006h,0ffh	; 9b20  .........
	defb 0ffh,0ffh,005h,0ffh,016h,0ffh,014h,0ffh,0ffh	; 9b29  .........
	defb 0ffh,011h,0ffh,017h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b32  .........
	defb 0ffh,0ffh,013h,0ffh,015h,0ffh,003h,0ffh,0ffh	; 9b3b  .........
	defb 0ffh,009h,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b44  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b4d  .........
	defb 003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b56  .........
	defb 0ffh,0ffh,009h,0ffh,007h,0ffh,00ch,0ffh,002h	; 9b5f  .........
	defb 0ffh,0ffh,0ffh,004h,0ffh,012h,0ffh,010h,0ffh	; 9b68  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,0ffh	; 9b71  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh	; 9b7a  .........
	defb 0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh	; 9b83  .........
	defb 0ffh,0ffh,0ffh,007h,0ffh,00ch,0ffh,006h,0ffh	; 9b8c  .........
	defb 0ffh,0ffh,005h,0ffh,011h,0ffh,008h,0ffh,00ah	; 9b95  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b9e  .........
	defb 004h,0ffh,0ffh,0ffh,008h,0ffh,000h,0ffh,00ch	; 9ba7  .........
	defb 0ffh,0ffh,0ffh,011h,0ffh,000h,0ffh,003h,0ffh	; 9bb0  .........
	defb 0ffh,0ffh,001h,0ffh,006h,0ffh,005h,0ffh,00fh	; 9bb9  .........
	defb 0ffh,002h,0ffh,003h,0ffh,006h,0ffh,00eh,0ffh	; 9bc2  .........
	defb 00dh,0ffh,013h,0ffh,009h,0ffh,001h,0ffh,00ah	; 9bcb  .........
	defb 0ffh,00dh,0ffh,006h,0ffh,009h,0ffh,002h,0ffh	; 9bd4  .........
	defb 015h,0ffh,009h,0ffh,000h,0ffh,012h,0ffh,007h	; 9bdd  .........
	defb 0ffh,008h,0ffh,014h,0ffh,007h,0ffh,003h,0ffh	; 9be6  .........
	defb 00ah,0ffh,016h,0ffh,015h,0ffh,00ch,0ffh,005h	; 9bef  .........
	defb 005h,0ffh,0ffh,002h,0ffh,0ffh,0ffh,004h,0ffh	; 9bf8  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c01  .........
	defb 0ffh,008h,0ffh,010h,0ffh,00eh,0ffh,006h,0ffh	; 9c0a  .........
	defb 00dh,0ffh,012h,0ffh,001h,0ffh,0ffh,0ffh,00bh	; 9c13  .........
	defb 0ffh,012h,0ffh,014h,0ffh,000h,0ffh,0ffh,0ffh	; 9c1c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,013h	; 9c25  .........
	defb 0ffh,017h,0ffh,014h,0ffh,0ffh,0ffh,003h,0ffh	; 9c2e  .........
	defb 00ch,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,002h	; 9c37  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,007h,0ffh,013h,0ffh	; 9c40  .........
	defb 006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c49  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c52  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c5b  .........
	defb 0ffh,007h,0ffh,002h,0ffh,00ah,0ffh,004h,0ffh	; 9c64  .........
	defb 005h,0ffh,009h,0ffh,00dh,0ffh,00ch,0ffh,001h	; 9c6d  .........
	defb 0ffh,003h,0ffh,00bh,0ffh,010h,0ffh,002h,0ffh	; 9c76  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c7f  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c88  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c91  .........
	defb 007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh	; 9c9a  .........
	defb 0ffh,0ffh,006h,0ffh,00dh,0ffh,001h,0ffh,006h	; 9ca3  .........
	defb 0ffh,0ffh,0ffh,003h,0ffh,011h,0ffh,00fh,0ffh	; 9cac  .........
	defb 0ffh,0ffh,008h,0ffh,010h,0ffh,00bh,0ffh,004h	; 9cb5  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh	; 9cbe  .........
	defb 0ffh,0ffh,0ffh,0ffh,002h,0ffh,000h,0ffh,0ffh	; 9cc7  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh	; 9cd0  .........
	defb 0ffh,0ffh,0ffh,0ffh,005h,0ffh,00eh,0ffh,0ffh	; 9cd9  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh	; 9ce2  .........
	defb 008h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9ceb  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9cf4  .........
	defb 0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9cfd  .........
	defb 002h,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d06  .........
	defb 0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d0f  .........
	defb 00ah,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d18  .........
	defb 0ffh,004h,0ffh,013h,0ffh,009h,0ffh,003h,0ffh	; 9d21  .........
	defb 007h,0ffh,00fh,0ffh,00eh,0ffh,010h,0ffh,00eh	; 9d2a  .........
	defb 0ffh,002h,0ffh,001h,0ffh,00ch,0ffh,005h,0ffh	; 9d33  .........
	defb 009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d3c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d45  .........
	defb 0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d4e  .........
	defb 0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d57  .........
	defb 0ffh,00bh,0ffh,006h,0ffh,0ffh,0ffh,003h,0ffh	; 9d60  .........
	defb 005h,0ffh,000h,0ffh,008h,0ffh,001h,0ffh,004h	; 9d69  .........
	defb 0ffh,00dh,0ffh,00eh,0ffh,00ch,0ffh,00ah,0ffh	; 9d72  .........
	defb 0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d7b  .........
	defb 0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d84  .........
	defb 00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d8d  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d96  .........
	defb 0ffh,007h,0ffh,00ch,0ffh,002h,0ffh,00dh,0ffh	; 9d9f  .........
	defb 0ffh,0ffh,004h,0ffh,009h,0ffh,00eh,0ffh,0ffh	; 9da8  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,001h,0ffh	; 9db1  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,0ffh	; 9dba  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00dh,0ffh,00bh,0ffh	; 9dc3  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh	; 9dcc  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,006h,0ffh	; 9dd5  .........
	defb 00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9dde  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh	; 9de7  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh	; 9df0  .........
	defb 0ffh,008h,0ffh,005h,0ffh,0ffh,0ffh,001h,0ffh	; 9df9  .........
	defb 000h,0ffh,002h,0ffh,009h,0ffh,00ah,0ffh,007h	; 9e02  .........
	defb 0ffh,006h,0ffh,000h,0ffh,0ffh,0ffh,003h,0ffh	; 9e0b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e14  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e1d  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e26  .........
	defb 00ch,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh	; 9e2f  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh	; 9e38  .........
	defb 0ffh,0ffh,0ffh,0ffh,012h,0ffh,00fh,0ffh,0ffh	; 9e41  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,00dh,0ffh	; 9e4a  .........
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,001h,0ffh,005h	; 9e53  .........
	defb 0ffh,000h,0ffh,017h,0ffh,0ffh,0ffh,007h,0ffh	; 9e5c  .........
	defb 00bh,0ffh,002h,0ffh,014h,0ffh,0ffh,0ffh,013h	; 9e65  .........
	defb 0ffh,00eh,0ffh,011h,0ffh,016h,0ffh,001h,0ffh	; 9e6e  .........
	defb 015h,0ffh,004h,0ffh,009h,0ffh,010h,0ffh,0ffh	; 9e77  .........
	defb 00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e80  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e89  .........
	defb 0ffh,00eh,0ffh,001h,0ffh,011h,0ffh,006h,0ffh	; 9e92  .........
	defb 005h,0ffh,013h,0ffh,0ffh,0ffh,003h,0ffh,00bh	; 9e9b  .........
	defb 0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh	; 9ea4  .........
	defb 016h,0ffh,004h,0ffh,0ffh,0ffh,012h,0ffh,009h	; 9ead  .........
	defb 0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,015h,0ffh	; 9eb6  .........
	defb 010h,0ffh,000h,0ffh,011h,0ffh,002h,0ffh,017h	; 9ebf  .........
	defb 0ffh,014h,0ffh,00ch,0ffh,012h,0ffh,007h,0ffh	; 9ec8  .........
	defb 00eh,0ffh,001h,0ffh,0ffh,0ffh,004h,0ffh,0ffh	; 9ed1  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9eda  .........
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,002h,0ffh,0ffh	; 9ee3  .........
	defb 0ffh,0ffh,0ffh,010h,0ffh,011h,0ffh,0ffh,0ffh	; 9eec  .........
	defb 00ch,0ffh,003h,0ffh,012h,0ffh,00bh,0ffh,006h	; 9ef5  .........
	defb 0ffh,0ffh,0ffh,013h,0ffh,00fh,0ffh,0ffh,0ffh	; 9efe  .........
	defb 005h,0ffh,00ah,0ffh,0ffh,0ffh,008h,0ffh,00dh	; 9f07  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f10  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f19  .........
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f22  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f2b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f34  .........
	defb 0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh	; 9f3d  .........
	defb 006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h	; 9f46  .........
	defb 0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh	; 9f4f  .........
	defb 00bh,0ffh,001h,0ffh,0ffh,0ffh,005h,0ffh,00ah	; 9f58  .........
	defb 0ffh,011h,0ffh,00eh,0ffh,000h,0ffh,012h,0ffh	; 9f61  .........
	defb 009h,0ffh,007h,0ffh,013h,0ffh,003h,0ffh,00ch	; 9f6a  .........
	defb 010h,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh	; 9f73  .........
	defb 0ffh,0ffh,0ffh,00bh,0ffh,006h,0ffh,0ffh,0ffh	; 9f7c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f85  .........
	defb 0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh	; 9f8e  .........
	defb 008h,0ffh,00dh,0ffh,0ffh,0ffh,001h,0ffh,00fh	; 9f97  .........
	defb 0ffh,013h,0ffh,011h,0ffh,012h,0ffh,00ch,0ffh	; 9fa0  .........
	defb 0ffh,0ffh,00ah,0ffh,014h,0ffh,007h,0ffh,0ffh	; 9fa9  .........
	defb 0ffh,0ffh,0ffh,005h,0ffh,003h,0ffh,0ffh,0ffh	; 9fb2  .........
	defb 0ffh,0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh,0ffh	; 9fbb  .........
	defb 011h,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh	; 9fc4  .........
	defb 0ffh,0ffh,0ffh,008h,0ffh,003h,0ffh,0ffh,0ffh	; 9fcd  .........
	defb 0ffh,0ffh,002h,0ffh,0ffh,0ffh,00eh,0ffh,0ffh	; 9fd6  .........
	defb 0ffh,006h,0ffh,013h,0ffh,010h,0ffh,005h,0ffh	; 9fdf  .........
	defb 00ah,0ffh,00fh,0ffh,0ffh,0ffh,001h,0ffh,009h	; 9fe8  .........
	defb 0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh	; 9ff1  .........
	defb 00dh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,000h	; 9ffa  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a003  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a00c  .........
	defb 012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a015  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a01e  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a027  .........
	defb 0ffh,005h,0ffh,00fh,0ffh,009h,0ffh,0ffh,0ffh	; a030  .........
	defb 00ah,0ffh,0ffh,0ffh,001h,0ffh,007h,0ffh,0ffh	; a039  .........
	defb 0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh	; a042  .........
	defb 00ch,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,00bh	; a04b  .........
	defb 0ffh,008h,0ffh,010h,0ffh,00dh,0ffh,0ffh,0ffh	; a054  .........
	defb 006h,0ffh,00eh,0ffh,004h,0ffh,0ffh,0ffh,0ffh	; a05d  .........
	defb 013h,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh	; a066  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh	; a06f  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,008h	; a078  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh	; a081  .........
	defb 0ffh,0ffh,0ffh,0ffh,009h,0ffh,00eh,0ffh,002h	; a08a  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,00dh,0ffh,0ffh,0ffh	; a093  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,006h	; a09c  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh	; a0a5  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh	; a0ae  .........
	defb 014h,0ffh,0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh	; a0b7  .........
	defb 0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh,0ffh,0ffh	; a0c0  .........
	defb 0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a0c9  .........
	defb 0ffh,00bh,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh	; a0d2  .........
	defb 003h,0ffh,008h,0ffh,0ffh,0ffh,007h,0ffh,0ffh	; a0db  .........
	defb 0ffh,011h,0ffh,001h,0ffh,0ffh,0ffh,00dh,0ffh	; a0e4  .........
	defb 0ffh,0ffh,009h,0ffh,006h,0ffh,0ffh,0ffh,004h	; a0ed  .........
	defb 0ffh,0ffh,0ffh,00ch,0ffh,010h,0ffh,00ah,0ffh	; a0f6  .........
	defb 0ffh,0ffh,0ffh,0ffh,012h,0ffh,0ffh,0ffh,0ffh	; a0ff  .........
	defb 015h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a108  .........
	defb 0ffh,0ffh,0ffh,002h,0ffh,006h,0ffh,0ffh,0ffh	; a111  .........
	defb 0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,0ffh	; a11a  .........
	defb 0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a123  .........
	defb 0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a12c  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,0ffh,0ffh,003h,0ffh	; a135  .........
	defb 0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh	; a13e  .........
	defb 0ffh,007h,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh	; a147  .........
	defb 0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a150  .........
	defb 006h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a159  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,0ffh	; a162  .........
	defb 0ffh,003h,0ffh,00dh,0ffh,002h,0ffh,00ch,0ffh	; a16b  .........
	defb 0ffh,0ffh,013h,0ffh,007h,0ffh,005h,0ffh,00bh	; a174  .........
	defb 0ffh,0ffh,0ffh,014h,0ffh,008h,0ffh,003h,0ffh	; a17d  .........
	defb 0ffh,0ffh,004h,0ffh,00fh,0ffh,011h,0ffh,0ffh	; a186  .........
	defb 0ffh,00eh,0ffh,009h,0ffh,015h,0ffh,009h,0ffh	; a18f  .........
	defb 0ffh,0ffh,017h,0ffh,000h,0ffh,00ah,0ffh,016h	; a198  .........
	defb 0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,012h,0ffh	; a1a1  .........
	defb 007h,002h,0ffh,0ffh,00dh,0ffh,003h,0ffh,0ffh	; a1aa  .........
	defb 0ffh,0ffh,0ffh,00ch,0ffh,00eh,0ffh,013h,0ffh	; a1b3  .........
	defb 0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,0ffh	; a1bc  .........
	defb 0ffh,011h,0ffh,001h,0ffh,008h,0ffh,00ah,0ffh	; a1c5  .........
	defb 0ffh,0ffh,012h,0ffh,010h,0ffh,005h,0ffh,0ffh	; a1ce  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,012h,0ffh,0ffh,0ffh	; a1d7  .........
	defb 0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh	; a1e0  .........
	defb 0ffh,0ffh,0ffh,00fh,0ffh,006h,0ffh,014h,0ffh	; a1e9  .........
	defb 0ffh,0ffh,00ah,0ffh,005h,0ffh,00bh,0ffh,0ffh	; a1f2  .........
	defb 008h,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a1fb  .........
	defb 0ffh,0ffh,0ffh,0ffh,002h,0ffh,00ch,0ffh,0ffh	; a204  .........
	defb 0ffh,009h,0ffh,016h,0ffh,00ah,0ffh,015h,0ffh	; a20d  .........
	defb 00eh,0ffh,013h,0ffh,001h,0ffh,010h,0ffh,004h	; a216  .........
	defb 0ffh,007h,0ffh,017h,0ffh,004h,0ffh,000h,0ffh	; a21f  .........
	defb 0ffh,0ffh,001h,0ffh,00dh,0ffh,012h,0ffh,0ffh	; a228  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,006h,0ffh	; a231  .........
	defb 0ffh,0ffh,00fh,0ffh,005h,0ffh,014h,0ffh,0ffh	; a23a  .........
	defb 0ffh,0ffh,0ffh,011h,0ffh,00bh,0ffh,0ffh,0ffh	; a243  .........
	defb 009h,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a24c  .........
	defb 0ffh,0ffh,0ffh,0ffh,007h,0ffh,011h,0ffh,0ffh	; a255  .........
	defb 0ffh,0ffh,0ffh,00fh,0ffh,00dh,0ffh,000h,0ffh	; a25e  .........
	defb 0ffh,0ffh,014h,0ffh,010h,0ffh,00ah,0ffh,0ffh	; a267  .........
	defb 0ffh,002h,0ffh,005h,0ffh,000h,0ffh,00ch,0ffh	; a270  .........
	defb 0ffh,0ffh,00bh,0ffh,001h,0ffh,012h,0ffh,0ffh	; a279  .........
	defb 0ffh,00eh,0ffh,013h,0ffh,008h,0ffh,0ffh,0ffh	; a282  .........
	defb 0ffh,0ffh,003h,0ffh,006h,0ffh,0ffh,0ffh,0ffh	; a28b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a294  .........
	defb 00ah,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h	; a29d  .........
	defb 0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,010h,0ffh	; a2a6  .........
	defb 0ffh,0ffh,016h,0ffh,003h,0ffh,013h,0ffh,015h	; a2af  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,000h,0ffh,0ffh,0ffh	; a2b8  .........
	defb 0ffh,0ffh,014h,0ffh,008h,0ffh,007h,0ffh,001h	; a2c1  .........
	defb 0ffh,0ffh,0ffh,012h,0ffh,002h,0ffh,002h,0ffh	; a2ca  .........
	defb 0ffh,0ffh,006h,0ffh,016h,0ffh,003h,0ffh,004h	; a2d3  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh	; a2dc  .........
	defb 0ffh,0ffh,0ffh,0ffh,003h,0ffh,004h,0ffh,0ffh	; a2e5  .........
	defb 00bh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a2ee  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,002h,0ffh,0ffh,0ffh	; a2f7  .........
	defb 0ffh,0ffh,004h,0ffh,0ffh,0ffh,00fh,0ffh,0ffh	; a300  .........
	defb 0ffh,008h,0ffh,011h,0ffh,00ch,0ffh,00ah,0ffh	; a309  .........
	defb 00eh,0ffh,000h,0ffh,013h,0ffh,016h,0ffh,003h	; a312  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,002h,0ffh,0ffh,0ffh	; a31b  .........
	defb 007h,0ffh,00dh,0ffh,015h,0ffh,005h,0ffh,003h	; a324  .........
	defb 0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh	; a32d  .........
	defb 017h,0ffh,002h,0ffh,012h,0ffh,009h,0ffh,004h	; a336  .........
	defb 00ch,007h,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh	; a33f  .........
	defb 0ffh,0ffh,0ffh,00eh,0ffh,00bh,0ffh,0ffh,0ffh	; a348  .........
	defb 0ffh,0ffh,003h,0ffh,015h,0ffh,011h,0ffh,0ffh	; a351  .........
	defb 0ffh,006h,0ffh,009h,0ffh,002h,0ffh,004h,0ffh	; a35a  .........
	defb 0ffh,0ffh,013h,0ffh,005h,0ffh,004h,0ffh,0ffh	; a363  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,016h,0ffh,0ffh,0ffh	; a36c  .........
	defb 0ffh,0ffh,017h,0ffh,000h,0ffh,003h,0ffh,0ffh	; a375  .........
	defb 0ffh,00fh,0ffh,014h,0ffh,00dh,0ffh,008h,0ffh	; a37e  .........
	defb 008h,0ffh,00ah,0ffh,002h,0ffh,010h,0ffh,012h	; a387  .........
	defb 00dh,008h,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh	; a390  .........
	defb 0ffh,0ffh,0ffh,00ch,0ffh,007h,0ffh,0ffh,0ffh	; a399  .........
	defb 0ffh,0ffh,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh	; a3a2  .........
	defb 0ffh,0ffh,0ffh,00eh,0ffh,013h,0ffh,0ffh,0ffh	; a3ab  .........
	defb 0ffh,0ffh,014h,0ffh,00bh,0ffh,004h,0ffh,0ffh	; a3b4  .........
	defb 0ffh,005h,0ffh,002h,0ffh,000h,0ffh,009h,0ffh	; a3bd  .........
	defb 007h,0ffh,002h,0ffh,011h,0ffh,016h,0ffh,010h	; a3c6  .........
	defb 0ffh,015h,0ffh,00fh,0ffh,017h,0ffh,003h,0ffh	; a3cf  .........
	defb 00ah,0ffh,0ffh,0ffh,006h,0ffh,0ffh,0ffh,012h	; a3d8  .........
	defb 00eh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a3e1  .........
	defb 0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh	; a3ea  .........
	defb 0ffh,00ah,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh	; a3f3  .........
	defb 0ffh,0ffh,00fh,0ffh,013h,0ffh,0ffh,0ffh,0ffh	; a3fc  .........
	defb 0ffh,00bh,0ffh,006h,0ffh,00ch,0ffh,002h,0ffh	; a405  .........
	defb 001h,0ffh,012h,0ffh,011h,0ffh,008h,0ffh,0ffh	; a40e  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,007h,0ffh	; a417  .........
	defb 0ffh,0ffh,0ffh,0ffh,003h,0ffh,010h,0ffh,0ffh	; a420  .........
	defb 0ffh,0ffh,0ffh,005h,0ffh,008h,0ffh,0ffh,0ffh	; a429  .........
	defb 00fh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a432  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a43b  .........
	defb 0ffh,004h,0ffh,00ch,0ffh,007h,0ffh,003h,0ffh	; a444  .........
	defb 0ffh,0ffh,005h,0ffh,010h,0ffh,00eh,0ffh,0ffh	; a44d  .........
	defb 0ffh,0ffh,0ffh,001h,0ffh,009h,0ffh,0ffh,0ffh	; a456  .........
	defb 0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh	; a45f  .........
	defb 0ffh,0ffh,0ffh,00bh,0ffh,00dh,0ffh,0ffh,0ffh	; a468  .........
	defb 0ffh,0ffh,011h,0ffh,006h,0ffh,002h,0ffh,0ffh	; a471  .........
	defb 0ffh,005h,0ffh,013h,0ffh,008h,0ffh,012h,0ffh	; a47a  .........
	defb 010h,00bh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh	; a483  .........
	defb 0ffh,0ffh,0ffh,008h,0ffh,005h,0ffh,0ffh,0ffh	; a48c  .........
	defb 0ffh,0ffh,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh	; a495  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,007h,0ffh,0ffh,0ffh	; a49e  .........
	defb 0ffh,0ffh,00ah,0ffh,00dh,0ffh,003h,0ffh,0ffh	; a4a7  .........
	defb 0ffh,005h,0ffh,004h,0ffh,00fh,0ffh,009h,0ffh	; a4b0  .........
	defb 005h,0ffh,00ch,0ffh,011h,0ffh,008h,0ffh,001h	; a4b9  .........
	defb 0ffh,006h,0ffh,00eh,0ffh,002h,0ffh,00ah,0ffh	; a4c2  .........
	defb 0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh	; a4cb  .........
	defb 011h,00ch,0ffh,005h,0ffh,013h,0ffh,0ffh,0ffh	; a4d4  .........
	defb 0ffh,0ffh,0ffh,0ffh,015h,0ffh,002h,0ffh,0ffh	; a4dd  .........
	defb 0ffh,017h,0ffh,010h,0ffh,014h,0ffh,0ffh,0ffh	; a4e6  .........
	defb 0ffh,0ffh,003h,0ffh,012h,0ffh,008h,0ffh,0ffh	; a4ef  .........
	defb 0ffh,007h,0ffh,013h,0ffh,002h,0ffh,016h,0ffh	; a4f8  .........
	defb 0ffh,0ffh,001h,0ffh,006h,0ffh,012h,0ffh,004h	; a501  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh,014h,0ffh	; a50a  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh	; a513  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a51c  .........
	defb 012h,00dh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh	; a525  .........
	defb 0ffh,0ffh,0ffh,002h,0ffh,009h,0ffh,003h,0ffh	; a52e  .........
	defb 0ffh,0ffh,007h,0ffh,010h,0ffh,00eh,0ffh,0ffh	; a537  .........
	defb 0ffh,002h,0ffh,013h,0ffh,000h,0ffh,0ffh,0ffh	; a540  .........
	defb 0ffh,0ffh,00fh,0ffh,003h,0ffh,001h,0ffh,00bh	; a549  .........
	defb 0ffh,0ffh,0ffh,004h,0ffh,00ch,0ffh,006h,0ffh	; a552  .........
	defb 0ffh,0ffh,00ah,0ffh,002h,0ffh,001h,0ffh,0ffh	; a55b  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh	; a564  .........
	defb 0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,0ffh	; a56d  .........
	defb 013h,00eh,0ffh,0ffh,010h,0ffh,0ffh,0ffh,016h	; a576  .........
	defb 0ffh,0ffh,0ffh,00dh,0ffh,003h,0ffh,014h,0ffh	; a57f  .........
	defb 001h,0ffh,00ah,0ffh,0ffh,0ffh,007h,0ffh,009h	; a588  .........
	defb 0ffh,005h,0ffh,001h,0ffh,004h,0ffh,0ffh,0ffh	; a591  .........
	defb 012h,0ffh,0ffh,0ffh,006h,0ffh,012h,0ffh,002h	; a59a  .........
	defb 0ffh,011h,0ffh,003h,0ffh,002h,0ffh,007h,0ffh	; a5a3  .........
	defb 015h,0ffh,00bh,0ffh,00fh,0ffh,000h,0ffh,0ffh	; a5ac  .........
	defb 0ffh,004h,0ffh,000h,0ffh,0ffh,0ffh,008h,0ffh	; a5b5  .........
	defb 005h,0ffh,0ffh,0ffh,00ch,0ffh,017h,0ffh,006h	; a5be  .........
	defb 014h,00fh,0ffh,0ffh,010h,0ffh,001h,0ffh,0ffh	; a5c7  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,017h,0ffh,007h,0ffh	; a5d0  .........
	defb 0ffh,0ffh,003h,0ffh,007h,0ffh,011h,0ffh,00bh	; a5d9  .........
	defb 0ffh,013h,0ffh,002h,0ffh,000h,0ffh,004h,0ffh	; a5e2  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh	; a5eb  .........
	defb 0ffh,00eh,0ffh,002h,0ffh,001h,0ffh,005h,0ffh	; a5f4  .........
	defb 00ah,0ffh,012h,0ffh,008h,0ffh,016h,0ffh,004h	; a5fd  .........
	defb 0ffh,000h,0ffh,000h,0ffh,015h,0ffh,0ffh,0ffh	; a606  .........
	defb 005h,0ffh,00ch,0ffh,011h,0ffh,008h,0ffh,0ffh	; a60f  .........
	defb 015h,010h,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh	; a618  .........
	defb 0ffh,0ffh,0ffh,009h,0ffh,002h,0ffh,0ffh,0ffh	; a621  .........
	defb 0ffh,0ffh,00ch,0ffh,0ffh,0ffh,00ah,0ffh,0ffh	; a62a  .........
	defb 0ffh,001h,0ffh,011h,0ffh,0ffh,0ffh,00dh,0ffh	; a633  .........
	defb 009h,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,006h	; a63c  .........
	defb 0ffh,00bh,0ffh,0ffh,0ffh,003h,0ffh,016h,0ffh	; a645  .........
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,013h,0ffh,0ffh	; a64e  .........
	defb 0ffh,0ffh,0ffh,012h,0ffh,000h,0ffh,00eh,0ffh	; a657  .........
	defb 0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,00fh	; a660  .........
	defb 016h,011h,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh	; a669  .........
	defb 0ffh,0ffh,0ffh,008h,0ffh,010h,0ffh,0ffh,0ffh	; a672  .........
	defb 0ffh,0ffh,00fh,0ffh,00dh,0ffh,004h,0ffh,0ffh	; a67b  .........
	defb 0ffh,00ah,0ffh,006h,0ffh,013h,0ffh,00bh,0ffh	; a684  .........
	defb 0ffh,0ffh,003h,0ffh,000h,0ffh,015h,0ffh,0ffh	; a68d  .........
	defb 0ffh,0ffh,0ffh,012h,0ffh,009h,0ffh,0ffh,0ffh	; a696  .........
	defb 0ffh,0ffh,014h,0ffh,017h,0ffh,002h,0ffh,0ffh	; a69f  .........
	defb 0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh	; a6a8  .........
	defb 0ffh,0ffh,00ch,0ffh,005h,0ffh,010h,0ffh,0ffh	; a6b1  .........
	defb 017h,012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a6ba  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,013h,0ffh	; a6c3  .........
	defb 0ffh,0ffh,001h,0ffh,005h,0ffh,008h,0ffh,000h	; a6cc  .........
	defb 0ffh,0ffh,0ffh,00ch,0ffh,003h,0ffh,009h,0ffh	; a6d5  .........
	defb 009h,0ffh,007h,0ffh,00ah,0ffh,002h,0ffh,0ffh	; a6de  .........
	defb 0ffh,008h,0ffh,004h,0ffh,00dh,0ffh,0ffh,0ffh	; a6e7  .........
	defb 0ffh,0ffh,009h,0ffh,006h,0ffh,00bh,0ffh,0ffh	; a6f0  .........
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a6f9  .........
	defb 0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh	; a702  .........
	defb 001h,013h,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh	; a70b  .........
	defb 0ffh,0ffh,0ffh,004h,0ffh,00ch,0ffh,0ffh,0ffh	; a714  .........
	defb 0ffh,0ffh,007h,0ffh,015h,0ffh,009h,0ffh,0ffh	; a71d  .........
	defb 0ffh,00eh,0ffh,014h,0ffh,010h,0ffh,002h,0ffh	; a726  .........
	defb 00ah,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,006h	; a72f  .........
	defb 0ffh,006h,0ffh,014h,0ffh,00dh,0ffh,00eh,0ffh	; a738  .........
	defb 0ffh,0ffh,00bh,0ffh,003h,0ffh,00fh,0ffh,0ffh	; a741  .........
	defb 0ffh,0ffh,0ffh,004h,0ffh,012h,0ffh,0ffh,0ffh	; a74a  .........
	defb 0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh	; a753  .........
	defb 000h,014h,0ffh,0ffh,00dh,0ffh,0ffh,0ffh,0ffh	; a75c  .........
	defb 0ffh,0ffh,0ffh,00fh,0ffh,008h,0ffh,0ffh,0ffh	; a765  .........
	defb 0ffh,0ffh,00ah,0ffh,001h,0ffh,004h,0ffh,0ffh	; a76e  .........
	defb 0ffh,0ffh,0ffh,006h,0ffh,00ah,0ffh,0ffh,0ffh	; a777  .........
	defb 002h,0ffh,007h,0ffh,00eh,0ffh,00bh,0ffh,006h	; a780  .........
	defb 0ffh,0ffh,0ffh,004h,0ffh,009h,0ffh,0ffh,0ffh	; a789  .........
	defb 0ffh,0ffh,005h,0ffh,00ch,0ffh,003h,0ffh,0ffh	; a792  .........
	defb 0ffh,0ffh,0ffh,010h,0ffh,011h,0ffh,0ffh,0ffh	; a79b  .........
	defb 0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh	; a7a4  .........

; ----------------------------------------------------------------------
; DATOS tablero_de_bonificacion: Los 81 bytes de la fase de bonificacion: 27
;   cubos y el modelo 0
;   0xa7ad..0xa7fe  (81 bytes)
DATA_tablero_de_bonificacion:
	defb 000h,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh	; a7ad  .........
	defb 0ffh,0ffh,0ffh,007h,0ffh,00ah,0ffh,0ffh,0ffh	; a7b6  .........
	defb 0ffh,0ffh,004h,0ffh,005h,0ffh,006h,0ffh,0ffh	; a7bf  .........
	defb 0ffh,007h,0ffh,008h,0ffh,009h,0ffh,00ah,0ffh	; a7c8  .........
	defb 00bh,0ffh,005h,0ffh,012h,0ffh,007h,0ffh,010h	; a7d1  .........
	defb 0ffh,010h,0ffh,011h,0ffh,012h,0ffh,013h,0ffh	; a7da  .........
	defb 004h,0ffh,00bh,0ffh,0ffh,0ffh,00ah,0ffh,004h	; a7e3  .........
	defb 0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,006h,0ffh	; a7ec  .........
	defb 007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h	; a7f5  .........

; ----------------------------------------------------------------------
; DATOS cubos: Tres estilos (fases 1-10, 11-20 y 21-50) de 26 cubos de 3x3
;   casillas, 234 bytes cada uno. Los 24 primeros son los giros: triangulos de
;   arista (0x40-0x87) y caras macizas (los tiles 0-15, que son su propio
;   color); el 24 es el cubo acabado del primero (0x88-0x90) y el 25 el del
;   segundo (0xE1-0xE9)
;   0xa7fe..0xaabc  (702 bytes)
DATA_cubos:
	defb 040h,007h,041h,007h,007h,006h,007h,007h,042h	; a7fe  @.A.....B
	defb 043h,007h,044h,007h,007h,006h,007h,007h,045h	; a807  C.D.....E
	defb 046h,007h,047h,007h,007h,006h,007h,007h,048h	; a810  F.G.....H
	defb 049h,007h,04ah,007h,007h,006h,007h,007h,04bh	; a819  I.J.....K
	defb 04ch,007h,04dh,006h,006h,007h,006h,006h,04eh	; a822  L.M.....N
	defb 04fh,007h,050h,006h,006h,007h,006h,006h,051h	; a82b  O.P.....Q
	defb 052h,006h,053h,007h,007h,007h,007h,007h,054h	; a834  R.S.....T
	defb 055h,006h,056h,007h,007h,007h,007h,007h,057h	; a83d  U.V.....W
	defb 058h,006h,059h,007h,007h,007h,007h,007h,05ah	; a846  X.Y.....Z
	defb 05bh,006h,05ch,007h,007h,007h,007h,007h,05dh	; a84f  [.\.....]
	defb 05eh,007h,05fh,006h,006h,007h,006h,006h,060h	; a858  ^._.....`
	defb 061h,007h,062h,006h,006h,007h,006h,006h,063h	; a861  a.b.....c
	defb 064h,007h,065h,007h,007h,006h,007h,007h,066h	; a86a  d.e.....f
	defb 067h,007h,068h,007h,007h,006h,007h,007h,069h	; a873  g.h.....i
	defb 06ah,007h,06bh,007h,007h,006h,007h,007h,06ch	; a87c  j.k.....l
	defb 06dh,007h,06eh,007h,007h,006h,007h,007h,06fh	; a885  m.n.....o
	defb 070h,007h,071h,006h,006h,007h,006h,006h,072h	; a88e  p.q.....r
	defb 073h,007h,074h,006h,006h,007h,006h,006h,075h	; a897  s.t.....u
	defb 076h,006h,077h,007h,007h,007h,007h,007h,078h	; a8a0  v.w.....x
	defb 079h,006h,07ah,007h,007h,007h,007h,007h,07bh	; a8a9  y.z.....{
	defb 07ch,006h,07dh,007h,007h,007h,007h,007h,07eh	; a8b2  |.}.....~
	defb 07fh,006h,080h,007h,007h,007h,007h,007h,081h	; a8bb  .........
	defb 082h,007h,083h,006h,006h,007h,006h,006h,084h	; a8c4  .........
	defb 085h,007h,086h,006h,006h,007h,006h,006h,087h	; a8cd  .........
	defb 088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h	; a8d6  .........
	defb 0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h	; a8df  .........
	defb 040h,006h,041h,004h,004h,007h,004h,004h,042h	; a8e8  @.A.....B
	defb 043h,004h,044h,006h,006h,007h,006h,006h,045h	; a8f1  C.D.....E
	defb 046h,006h,047h,004h,004h,007h,004h,004h,048h	; a8fa  F.G.....H
	defb 049h,004h,04ah,006h,006h,007h,006h,006h,04bh	; a903  I.J.....K
	defb 04ch,006h,04dh,007h,007h,004h,007h,007h,04eh	; a90c  L.M.....N
	defb 04fh,004h,050h,007h,007h,006h,007h,007h,051h	; a915  O.P.....Q
	defb 052h,007h,053h,004h,004h,006h,004h,004h,054h	; a91e  R.S.....T
	defb 055h,007h,056h,006h,006h,004h,006h,006h,057h	; a927  U.V.....W
	defb 058h,007h,059h,004h,004h,006h,004h,004h,05ah	; a930  X.Y.....Z
	defb 05bh,007h,05ch,006h,006h,004h,006h,006h,05dh	; a939  [.\.....]
	defb 05eh,004h,05fh,007h,007h,006h,007h,007h,060h	; a942  ^._.....`
	defb 061h,006h,062h,007h,007h,004h,007h,007h,063h	; a94b  a.b.....c
	defb 064h,006h,065h,004h,004h,007h,004h,004h,066h	; a954  d.e.....f
	defb 067h,004h,068h,006h,006h,007h,006h,006h,069h	; a95d  g.h.....i
	defb 06ah,006h,06bh,004h,004h,007h,004h,004h,06ch	; a966  j.k.....l
	defb 06dh,004h,06eh,006h,006h,007h,006h,006h,06fh	; a96f  m.n.....o
	defb 070h,006h,071h,007h,007h,004h,007h,007h,072h	; a978  p.q.....r
	defb 073h,004h,074h,007h,007h,006h,007h,007h,075h	; a981  s.t.....u
	defb 076h,007h,077h,004h,004h,006h,004h,004h,078h	; a98a  v.w.....x
	defb 079h,007h,07ah,006h,006h,004h,006h,006h,07bh	; a993  y.z.....{
	defb 07ch,007h,07dh,004h,004h,006h,004h,004h,07eh	; a99c  |.}.....~
	defb 07fh,007h,080h,006h,006h,004h,006h,006h,081h	; a9a5  .........
	defb 082h,004h,083h,007h,007h,006h,007h,007h,084h	; a9ae  .........
	defb 085h,006h,086h,007h,007h,004h,007h,007h,087h	; a9b7  .........
	defb 088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h	; a9c0  .........
	defb 0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h	; a9c9  .........
	defb 040h,006h,041h,004h,004h,00ch,004h,004h,042h	; a9d2  @.A.....B
	defb 043h,007h,044h,006h,006h,00ch,006h,006h,045h	; a9db  C.D.....E
	defb 046h,009h,047h,007h,007h,00ch,007h,007h,048h	; a9e4  F.G.....H
	defb 049h,004h,04ah,009h,009h,00ch,009h,009h,04bh	; a9ed  I.J.....K
	defb 04ch,006h,04dh,00ah,00ah,004h,00ah,00ah,04eh	; a9f6  L.M.....N
	defb 04fh,004h,050h,00ch,00ch,006h,00ch,00ch,051h	; a9ff  O.P.....Q
	defb 052h,00ah,053h,004h,004h,006h,004h,004h,054h	; aa08  R.S.....T
	defb 055h,00ah,056h,006h,006h,007h,006h,006h,057h	; aa11  U.V.....W
	defb 058h,00ah,059h,007h,007h,009h,007h,007h,05ah	; aa1a  X.Y.....Z
	defb 05bh,00ah,05ch,009h,009h,004h,009h,009h,05dh	; aa23  [.\.....]
	defb 05eh,007h,05fh,00ah,00ah,006h,00ah,00ah,060h	; aa2c  ^._.....`
	defb 061h,009h,062h,00ch,00ch,004h,00ch,00ch,063h	; aa35  a.b.....c
	defb 064h,009h,065h,004h,004h,00ah,004h,004h,066h	; aa3e  d.e.....f
	defb 067h,004h,068h,006h,006h,00ah,006h,006h,069h	; aa47  g.h.....i
	defb 06ah,006h,06bh,007h,007h,00ah,007h,007h,06ch	; aa50  j.k.....l
	defb 06dh,007h,06eh,009h,009h,00ah,009h,009h,06fh	; aa59  m.n.....o
	defb 070h,009h,071h,00ah,00ah,007h,00ah,00ah,072h	; aa62  p.q.....r
	defb 073h,007h,074h,00ch,00ch,009h,00ch,00ch,075h	; aa6b  s.t.....u
	defb 076h,00ch,077h,004h,004h,009h,004h,004h,078h	; aa74  v.w.....x
	defb 079h,00ch,07ah,006h,006h,004h,006h,006h,07bh	; aa7d  y.z.....{
	defb 07ch,00ch,07dh,007h,007h,006h,007h,007h,07eh	; aa86  |.}.....~
	defb 07fh,00ch,080h,009h,009h,007h,009h,009h,081h	; aa8f  .........
	defb 082h,004h,083h,00ah,00ah,009h,00ah,00ah,084h	; aa98  .........
	defb 085h,006h,086h,00ch,00ch,007h,00ch,00ch,087h	; aaa1  .........
	defb 088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h	; aaaa  .........
	defb 0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h	; aab3  .........

; ----------------------------------------------------------------------
; DATOS sprites_de_los_bichos: Dieciseis sprites de 16x16 en parejas: 0x30 las
;   bolas (0xAABC), 0x50 (0xAAFC), 0x90 el que persigue (0xAB3C, tambien en
;   0x98), 0x70 el que gira cubos (0xAB7C), 0xD0 el objeto de la vida
;   (0xABBC), 0xA0 los seis de colores (0xABFC) y los dos pasos de la bola que
;   bota, 0x80 (0xAC3C y 0xAC7C)
;   0xaabc..0xacbc  (512 bytes)
DATA_sprites_de_los_bichos:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,01fh,073h,0fdh,0ffh,078h	; aabc  ............s..x
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0e0h,0f8h,0ceh,0bfh,0ffh,01eh	; aacc  ................
	defb 000h,000h,000h,000h,000h,000h,003h,00fh,01dh,01dh,03dh,03fh,03fh,03eh,03eh,01ch	; aadc  ..........=??>>.
	defb 000h,000h,000h,000h,000h,000h,0c0h,0f0h,0b8h,0b8h,0bch,0fch,0fch,07ch,07ch,038h	; aaec  .............||8
	defb 000h,003h,00dh,00dh,00dh,077h,0f8h,0b7h,08ah,02fh,02ah,02fh,017h,038h,03bh,07ch	; aafc  .....w.../*/.8;|
	defb 000h,0c0h,0b0h,0b0h,0b0h,0eeh,01fh,0edh,051h,0f4h,054h,0f4h,0e8h,01ch,0dch,03eh	; ab0c  ........Q.T....>
	defb 003h,00dh,08dh,0cdh,0e7h,078h,037h,00ah,02fh,022h,01dh,03dh,03ah,01dh,00ch,003h	; ab1c  .....x7./".=:...
	defb 0c0h,0b0h,0b1h,0b3h,0e7h,01eh,0ech,050h,0f4h,044h,0b8h,0bch,05ch,0b8h,030h,0c0h	; ab2c  .......P.D..\.0.
	defb 001h,003h,007h,00fh,00fh,01bh,01dh,01fh,03fh,07fh,07fh,0dfh,03fh,03fh,07fh,00fh	; ab3c  ........?...??..
	defb 080h,0c0h,0e0h,0f0h,0f0h,0d8h,0b8h,0f8h,0fch,0feh,0feh,0fbh,0fch,0fch,0feh,0f0h	; ab4c  ................
	defb 003h,007h,00fh,01bh,09dh,0dfh,0ffh,07fh,07fh,03fh,067h,05bh,03dh,03dh,03bh,018h	; ab5c  .........?g[==;.
	defb 0c0h,0e0h,0f0h,0d8h,0b9h,0fbh,0ffh,0feh,0feh,0fch,0e6h,0dah,0bch,0bch,0dch,018h	; ab6c  ................
	defb 002h,007h,00fh,01fh,01fh,033h,03dh,07fh,0ffh,0ffh,0bfh,03fh,03fh,07fh,07fh,00fh	; ab7c  .....3=....??...
	defb 040h,0e0h,0f0h,0f8h,0f8h,0cch,0bch,0feh,0ffh,0ffh,0fdh,0fch,0fch,0feh,0feh,0f0h	; ab8c  @...............
	defb 002h,00fh,03fh,033h,09dh,0dfh,0ffh,0ffh,07fh,03fh,067h,05bh,03dh,03dh,038h,018h	; ab9c  ..?3.....?g[==8.
	defb 040h,0f0h,0fch,0cch,0b9h,0fbh,0ffh,0ffh,0feh,0fch,0e6h,0dah,0bch,0bch,0dch,018h	; abac  @...............
	defb 000h,000h,040h,060h,070h,06fh,01fh,07fh,0ffh,00fh,067h,036h,036h,06fh,003h,000h	; abbc  ..@`po....g66o..
	defb 000h,000h,000h,000h,000h,000h,000h,080h,0c0h,0f1h,03fh,00fh,007h,006h,0c8h,000h	; abcc  ..........?.....
	defb 000h,000h,080h,080h,080h,080h,000h,000h,000h,000h,080h,0c0h,0c0h,080h,000h,000h	; abdc  ................
	defb 000h,000h,000h,000h,000h,070h,07ch,03eh,00eh,000h,000h,0c0h,0f0h,030h,000h,000h	; abec  .....p|>.....0..
	defb 000h,001h,003h,003h,006h,006h,02fh,07fh,02fh,01fh,01fh,01fh,03fh,03fh,067h,05ah	; abfc  .....././...??gZ
	defb 078h,0fch,0feh,03eh,0beh,064h,0d4h,0c8h,0f8h,0f4h,0feh,0e4h,0f0h,0f0h,018h,0ech	; ac0c  x..>.d..........
	defb 01eh,03fh,07fh,07ch,07dh,026h,02bh,013h,01fh,02fh,07fh,027h,00fh,00fh,018h,037h	; ac1c  .?.|}&+../.'...7
	defb 000h,080h,0c0h,0c0h,060h,060h,0f4h,0feh,0f4h,0f8h,0f8h,0f8h,0fch,0fch,0e6h,05ah	; ac2c  ....``.........Z
	defb 007h,00fh,00fh,01fh,020h,00ch,00dh,01bh,01bh,037h,037h,00fh,01fh,003h,01dh,03fh	; ac3c  .... ....77....?
	defb 0f0h,0f8h,0fch,0fch,038h,074h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f8h,0f0h,0e0h	; ac4c  ....8t..........
	defb 007h,00fh,01fh,03fh,020h,00ch,019h,01bh,037h,077h,00fh,013h,011h,021h,023h,03fh	; ac5c  ...? ...7w...!#?
	defb 0f0h,0f8h,0fch,0fch,038h,074h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f8h,0f0h,0e0h	; ac6c  ....8t..........
	defb 00fh,01fh,03fh,03fh,01ch,02eh,02fh,02fh,02fh,02fh,02fh,02fh,02fh,01fh,00fh,007h	; ac7c  ..??..///////...
	defb 0e0h,0f0h,0f0h,0f8h,004h,030h,0b0h,0d8h,0d8h,0ech,0ech,0f0h,0f8h,0c0h,0b8h,0fch	; ac8c  .....0..........
	defb 00fh,01fh,03fh,03fh,01ch,02eh,02fh,02fh,02fh,02fh,02fh,02fh,02fh,01fh,00fh,007h	; ac9c  ..??..///////...
	defb 0e0h,0f0h,0f8h,0fch,004h,030h,098h,0d8h,0ech,0eeh,0f0h,0c8h,088h,084h,0c4h,0fch	; acac  .....0..........

; ----------------------------------------------------------------------
; DATOS qbert_a_la_izquierda: Ocho sprites: Q*bert mirando a la izquierda, de
;   frente y de espaldas, de pie y en el aire, en sus dos capas (patrones
;   0x00-0x0F la primera, 0x10-0x1F la segunda)
;   0xacbc..0xadbc  (256 bytes)
DATA_qbert_a_la_izquierda:
	defb 003h,00ch,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,039h,0f7h	; acbc  ..............9.
	defb 080h,040h,030h,010h,00ch,004h,000h,002h,002h,000h,000h,000h,002h,002h,0c1h,0e0h	; accc  .@0.............
	defb 003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0eeh,077h,03bh,019h	; acdc  .............w;.
	defb 080h,040h,030h,010h,00ch,008h,000h,000h,000h,000h,006h,004h,006h,002h,081h,080h	; acec  .@0.............
	defb 003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,010h,07eh	; acfc  ...............~
	defb 080h,0e0h,020h,030h,018h,018h,018h,008h,00ch,00ch,00ch,006h,006h,003h,001h,0f0h	; ad0c  .. 0............
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,080h,0c0h,0c0h,078h,019h	; ad1c  ..............x.
	defb 0c0h,040h,030h,030h,010h,018h,008h,008h,00ch,00ch,004h,006h,006h,002h,003h,081h	; ad2c  .@00............
	defb 000h,003h,03fh,07fh,07fh,0ffh,0dbh,0dbh,0dbh,0ffh,0ffh,07fh,07fh,03fh,006h,000h	; ad3c  ..?..........?..
	defb 000h,080h,0c0h,0e0h,0f0h,0f8h,0f8h,0fch,0fch,0deh,0eeh,0ech,0f0h,0fch,02eh,003h	; ad4c  ................
	defb 000h,00fh,03fh,07fh,05bh,0dbh,0dbh,0ffh,0ffh,0ffh,0ffh,07fh,011h,008h,004h,000h	; ad5c  ..?.[...........
	defb 000h,080h,0c0h,0e0h,0f0h,0f7h,0efh,0ffh,0feh,0fch,0f0h,0f8h,0f8h,0f4h,04eh,003h	; ad6c  ..............N.
	defb 000h,00fh,01fh,03fh,03fh,03fh,07fh,07fh,0ffh,0efh,0efh,05fh,03fh,03fh,00fh,000h	; ad7c  ...???....._??..
	defb 040h,000h,0d0h,0c8h,0e0h,0e4h,0e4h,0f4h,0f2h,0f2h,0f2h,0f8h,0d8h,0dch,0eeh,003h	; ad8c  @...............
	defb 003h,00fh,01fh,03fh,0bfh,0dfh,0efh,0ffh,07fh,03fh,04fh,07fh,03fh,01fh,007h,000h	; ad9c  ...?.....?O.?...
	defb 000h,0a0h,0c0h,0c8h,0e8h,0e4h,0f4h,0f4h,0f2h,0f2h,0fah,0f8h,0d8h,0dch,0ech,006h	; adac  ................

; ----------------------------------------------------------------------
; DATOS qbert_a_la_derecha: Los mismos ocho mirando a la derecha
;   0xadbc..0xaebc  (256 bytes)
DATA_qbert_a_la_derecha:
	defb 001h,002h,00ch,008h,030h,020h,000h,040h,040h,000h,000h,000h,040h,040h,083h,007h	; adbc  ....0 .@@...@@..
	defb 0c0h,030h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,09ch,0efh	; adcc  .0..............
	defb 001h,002h,00ch,008h,030h,010h,000h,000h,000h,000h,060h,020h,060h,040h,081h,001h	; addc  ....0.....` `@..
	defb 0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,077h,0eeh,0dch,098h	; adec  ............w...
	defb 001h,007h,004h,00ch,018h,018h,018h,010h,030h,030h,030h,060h,060h,0c0h,080h,00fh	; adfc  ........000``...
	defb 0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,008h,07eh	; ae0c  ...............~
	defb 003h,002h,00ch,00ch,008h,018h,010h,010h,030h,030h,020h,060h,060h,040h,0c0h,081h	; ae1c  ........00 ``@..
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,003h,003h,01eh,098h	; ae2c  ................
	defb 000h,001h,003h,007h,00fh,01fh,01fh,03fh,03fh,07bh,077h,037h,00fh,03fh,074h,0c0h	; ae3c  .......??{w7.?t.
	defb 000h,0c0h,0fch,0feh,0feh,0ffh,0dbh,0dbh,0dbh,0ffh,0ffh,0feh,0feh,0fch,060h,000h	; ae4c  ..............`.
	defb 000h,001h,003h,007h,00fh,0efh,0f7h,0ffh,07fh,03fh,00fh,01fh,01fh,02fh,072h,0c0h	; ae5c  .........?.../r.
	defb 000h,0f0h,0fch,0feh,0dah,0dbh,0dbh,0ffh,0ffh,0ffh,0ffh,0feh,088h,010h,020h,000h	; ae6c  .............. .
	defb 002h,000h,00bh,013h,007h,027h,027h,02fh,04fh,04fh,04fh,01fh,01bh,03bh,077h,0c0h	; ae7c  .....''/OOO..;w.
	defb 000h,0f0h,0f8h,0fch,0fch,0fch,0feh,0feh,0ffh,0f7h,0f7h,0fah,0fch,0fch,0f0h,000h	; ae8c  ................
	defb 000h,005h,003h,013h,017h,027h,02fh,02fh,04fh,04fh,05fh,01fh,01bh,03bh,037h,060h	; ae9c  .....'//OO_..;7`
	defb 0c0h,0f0h,0f8h,0fch,0fdh,0fbh,0f7h,0ffh,0feh,0fch,0f2h,0feh,0fch,0f8h,0e0h,000h	; aeac  ................

; ----------------------------------------------------------------------
; DATOS qbert_fase_acabada: Q*bert en la fase acabada: 0x67C4 copia 0x80 bytes
;   desde aqui y otros 0x80 desde 0xAEFC, que se pisan con este y con los de
;   caer
;   0xaebc..0xaf3c  (128 bytes)
DATA_qbert_fase_acabada:
	defb 001h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,01ch,07eh	; aebc  ...............~
	defb 080h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,038h,07eh	; aecc  ..............8~
	defb 001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,030h,078h,078h,078h,078h,030h	; aedc  ..........0xxxx0
	defb 080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00ch,01eh,01eh,01eh,01eh,00ch	; aeec  ................
	defb 000h,000h,00fh,01fh,03fh,03dh,07dh,0fdh,0bfh,0ddh,0deh,03fh,03fh,01fh,003h,000h	; aefc  ....?=}....??...
	defb 000h,000h,0f0h,0f8h,0fch,0bch,0beh,0bfh,0fdh,0bbh,07bh,0fch,0fch,0f8h,0c0h,000h	; af0c  ..........{.....
	defb 000h,00fh,01fh,03dh,07dh,07fh,0b8h,0d8h,0dch,03fh,04fh,007h,007h,007h,003h,000h	; af1c  ...=}....?O.....
	defb 000h,0f0h,0f8h,0bch,0beh,0feh,01dh,01bh,03bh,03bh,0fch,0f2h,0e0h,0e0h,0c0h,000h	; af2c  ........;;......

; ----------------------------------------------------------------------
; DATOS qbert_cayendo: Q*bert cayendo por un lado: 0x6F22 copia 0x40 de 0xAF3C
;   y 0x40 de 0xAF7C
;   0xaf3c..0xafbc  (128 bytes)
DATA_qbert_cayendo:
	defb 001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,060h,0f0h,0f0h,0f8h,078h,030h	; af3c  ..........`...x0
	defb 080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,006h,00fh,00fh,01fh,01eh,00ch	; af4c  ................
	defb 001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,020h,078h,0f8h	; af5c  ............. x.
	defb 080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,004h,01eh,01fh	; af6c  ................
	defb 000h,007h,08dh,0ddh,0dfh,0fch,078h,070h,030h,033h,01fh,00fh,00fh,007h,003h,000h	; af7c  ......xp03......
	defb 000h,0e0h,0b1h,0bbh,0fbh,03fh,01eh,00eh,00ch,0cch,0f8h,0f0h,0f0h,0e0h,0c0h,000h	; af8c  .....?..........
	defb 000h,007h,00fh,01dh,01fh,03ch,078h,0f3h,0bfh,0bfh,0dfh,05fh,03fh,01fh,003h,000h	; af9c  .....<x...._?...
	defb 000h,0e0h,0f0h,0b8h,0f8h,03ch,01eh,0cfh,0fdh,0fdh,0fbh,0fah,0fch,0f8h,0c0h,000h	; afac  .....<..........

; ----------------------------------------------------------------------
; DATOS tiles_de_giro_b: Nueve tiles (72 bytes) que 0x626D copia cinco veces
;   desde el tile 0xBE: los huecos 5 a 9 de los cubos que giran
;   0xafbc..0xb004  (72 bytes)
DATA_tiles_de_giro_b:
	defb 0ffh,081h,081h,01fh,01fh,01fh,01fh,03fh	; afbc  .......?
	defb 0ffh,081h,081h,0ffh,0ffh,0ffh,0ffh,0ffh	; afc4  ........
	defb 0ffh,081h,081h,0c0h,0e0h,0f0h,0f8h,0fch	; afcc  ........
	defb 03fh,03fh,03fh,03fh,07fh,07fh,07fh,07fh	; afd4  ????....
	defb 001h,001h,001h,001h,001h,003h,003h,003h	; afdc  ........
	defb 0feh,0ffh,0ffh,0feh,0feh,0feh,0feh,0fch	; afe4  ........
	defb 07fh,0ffh,0ffh,0ffh,0ffh,03fh,00fh,003h	; afec  .....?..
	defb 003h,003h,007h,007h,0ffh,0ffh,0ffh,0ffh	; aff4  ........
	defb 0fch,0fch,0fch,0f8h,0f8h,0f8h,0f8h,0f0h	; affc  ........

; ----------------------------------------------------------------------
; DATOS tiles_de_giro_a: Los otros nueve, cinco veces desde el tile 0x91: los
;   huecos 0 a 4
;   0xb004..0xb04c  (72 bytes)
DATA_tiles_de_giro_a:
	defb 000h,001h,003h,003h,007h,007h,00fh,00fh	; b004  ........
	defb 0ffh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h	; b00c  ....?...
	defb 000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch	; b014  ........
	defb 01fh,01fh,03fh,03fh,07fh,07fh,0ffh,0ffh	; b01c  ..??....
	defb 003h,001h,000h,0ffh,0ffh,0ffh,0feh,0feh	; b024  ........
	defb 0feh,0ffh,0ffh,080h,000h,000h,0feh,0feh	; b02c  ........
	defb 07fh,03fh,01fh,00fh,007h,003h,001h,000h	; b034  .?......
	defb 0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h	; b03c  ........
	defb 0feh,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h	; b044  ........

; ----------------------------------------------------------------------
; DATOS cubo_acabado: Los nueve patrones del cubo acabado, dos veces: en el
;   tile 0x88 (el del primero) y en el 0xE1 (el del segundo)
;   0xb04c..0xb094  (72 bytes)
DATA_cubo_acabado:
	defb 000h,001h,003h,006h,00ch,018h,030h,060h	; b04c  ......0`
	defb 000h,0ffh,0ffh,000h,000h,000h,000h,001h	; b054  ........
	defb 000h,0feh,0feh,01eh,036h,066h,0c6h,086h	; b05c  ....6f..
	defb 07fh,07fh,060h,060h,060h,060h,060h,060h	; b064  ..``````
	defb 0ffh,0ffh,003h,003h,003h,003h,003h,003h	; b06c  ........
	defb 006h,006h,006h,006h,006h,006h,006h,006h	; b074  ........
	defb 060h,060h,060h,060h,060h,060h,07fh,07fh	; b07c  ``````..
	defb 003h,003h,003h,003h,003h,003h,0ffh,0ffh	; b084  ........
	defb 006h,00ch,018h,030h,060h,0c0h,080h,000h	; b08c  ...0`...

; ----------------------------------------------------------------------
; DATOS cubo_acabado_color_1: Su color en el tile 0x88, RLE de tres bytes
;   0xb094..0xb097  (3 bytes)
DATA_cubo_acabado_color_1:
	defb 048h,0d0h,000h	; b094

; ----------------------------------------------------------------------
; DATOS cubo_acabado_color_2: Y en el tile 0xE1
;   0xb097..0xb09a  (3 bytes)
DATA_cubo_acabado_color_2:
	defb 048h,050h,000h	; b097

; ----------------------------------------------------------------------
; DATOS graficos_de_la_recreativa: RLE de 0x46A0 de 6.560 bytes con destino
;   0x0200 y saltos de direccion: patrones y colores de la presentacion (la
;   maquina recreativa, su pantalla, el rotulo de Q*bert) en los tres tercios
;   0xb09a..0xbe63  (3529 bytes)
DATA_graficos_de_la_recreativa:
	defb 000h,022h,00bh,0ffh,087h,0fch,0f8h,0f8h,0fch,0feh,0f0h,080h,006h,000h,008h,0feh	; b09a  ."..............
	defb 008h,000h,082h,0ffh,0c0h,004h,000h,08fh,060h,0f0h,0ffh,0ffh,03fh,01fh,00fh,00fh	; b0aa  ........`...?...
	defb 007h,006h,0feh,0f0h,0c0h,080h,080h,003h,001h,085h,01fh,003h,000h,000h,0c0h,003h	; b0ba  ................
	defb 0e0h,089h,0ffh,0feh,0f8h,070h,070h,038h,03ch,01ch,0e3h,003h,001h,002h,000h,002h	; b0ca  .....pp8<.......
	defb 001h,082h,0e3h,080h,006h,000h,089h,0fch,0f0h,0e0h,060h,070h,07ch,07ch,0fch,001h	; b0da  ..........`p||..
	defb 004h,000h,003h,001h,081h,0ffh,004h,00fh,003h,0ffh,081h,0f0h,006h,0f8h,081h,0f0h	; b0ea  ................
	defb 007h,006h,081h,00eh,003h,000h,004h,001h,004h,000h,004h,0ffh,084h,0feh,01ch,01ch	; b0fa  ................
	defb 03ch,003h,0fch,082h,07ch,03ch,008h,001h,082h,080h,0e3h,006h,0ffh,008h,0fch,084h	; b10a  <...|<..........
	defb 0feh,0fch,0fch,0f8h,004h,0ffh,003h,000h,087h,080h,0c0h,0f0h,0feh,0ffh,0f0h,060h	; b11a  ...............`
	defb 004h,000h,087h,003h,0ffh,00fh,01fh,01fh,03fh,07fh,003h,0ffh,002h,000h,002h,080h	; b12a  ........?.......
	defb 085h,0c0h,0f0h,0fch,0ffh,038h,004h,000h,08ch,001h,007h,0ffh,03ch,038h,070h,060h	; b13a  .....8......<8p`
	defb 0e0h,0f0h,0fch,0ffh,001h,005h,000h,081h,001h,003h,0ffh,08ah,07fh,03fh,03fh,07fh	; b14a  .............??.
	defb 0ffh,0ffh,0fch,0fch,0feh,0feh,004h,0ffh,005h,000h,08dh,080h,0e0h,0ffh,0c7h,007h	; b15a  ................
	defb 007h,00fh,00fh,01fh,07fh,0ffh,0fbh,000h,003h,0bfh,081h,000h,003h,0fbh,092h,000h	; b16a  ................
	defb 0bfh,0c0h,0f0h,0f8h,0fch,0feh,0fbh,000h,0bfh,001h,007h,00fh,01fh,03fh,0fbh,00fh	; b17a  .............?..
	defb 07fh,006h,0ffh,002h,03fh,002h,01fh,002h,00fh,084h,007h,0e0h,0e0h,0f8h,005h,0ffh	; b18a  ....?...........
	defb 081h,0fbh,007h,0ffh,082h,0fbh,0f8h,006h,0ffh,082h,007h,01fh,005h,0ffh,082h,0feh	; b19a  ................
	defb 003h,007h,000h,002h,0ffh,081h,03fh,005h,000h,083h,0fch,0f8h,0e0h,005h,000h,00bh	; b1aa  ......?.........
	defb 0ffh,003h,0feh,002h,0fch,081h,080h,00bh,000h,002h,001h,002h,003h,082h,01ch,07fh	; b1ba  ................
	defb 006h,0ffh,002h,000h,002h,080h,002h,0c0h,002h,0e0h,083h,0ffh,07fh,07fh,003h,03fh	; b1ca  ...............?
	defb 002h,01fh,002h,0fch,006h,0f8h,081h,003h,004h,007h,003h,00fh,081h,0e0h,004h,0f0h	; b1da  ................
	defb 003h,0f8h,002h,01fh,006h,00fh,007h,0f8h,081h,0fch,004h,00fh,004h,007h,005h,0f8h	; b1ea  ................
	defb 003h,0f0h,007h,00fh,081h,01fh,003h,0fch,003h,0feh,002h,0ffh,003h,003h,002h,001h	; b1fa  ................
	defb 003h,000h,08ch,0ffh,0f3h,0e0h,0e0h,0f8h,0f8h,0fch,07ch,0f0h,0e0h,0e0h,060h,004h	; b20a  ..........|...`.
	defb 000h,003h,01fh,003h,03fh,002h,07fh,088h,080h,0c0h,0e0h,0f0h,0f8h,0feh,0ffh,0ffh	; b21a  ....?...........
	defb 006h,000h,083h,080h,0f0h,018h,009h,000h,08bh,001h,003h,007h,00fh,03fh,03fh,02eh	; b22a  .............??.
	defb 0e4h,0eah,0eah,0eeh,003h,0ffh,081h,0f8h,004h,0feh,083h,0f1h,0c1h,001h,080h,000h	; b23a  ................
	defb 002h,07fh,0f4h,07fh,0f4h,01ah,0f4h,002h,040h,098h,070h,050h,040h,040h,070h,050h	; b24a  ........@.pP@@pP
	defb 040h,040h,070h,085h,084h,080h,087h,084h,040h,040h,070h,085h,084h,080h,087h,085h	; b25a  @@p.....@@p.....
	defb 040h,080h,007h,087h,089h,080h,087h,085h,084h,080h,087h,085h,084h,080h,006h,087h	; b26a  @...............
	defb 081h,040h,007h,088h,081h,040h,007h,080h,081h,084h,027h,080h,07fh,0f8h,046h,0f8h	; b27a  .@...@....'...F.
	defb 003h,0f4h,080h,000h,02ah,00bh,0ffh,087h,0fch,0f8h,0f8h,0fch,0feh,0f0h,080h,006h	; b28a  ....*...........
	defb 000h,008h,0feh,008h,000h,082h,0ffh,0c0h,004h,000h,08fh,060h,0f0h,0ffh,0ffh,03fh	; b29a  ...........`...?
	defb 01fh,00fh,00fh,007h,006h,0feh,0f0h,0c0h,080h,080h,003h,001h,085h,01fh,003h,000h	; b2aa  ................
	defb 000h,0c0h,003h,0e0h,089h,0ffh,0feh,0f8h,070h,070h,038h,03ch,01ch,0e3h,003h,001h	; b2ba  ........pp8<....
	defb 002h,000h,002h,001h,082h,0e3h,080h,006h,000h,089h,0fch,0f0h,0e0h,060h,070h,07ch	; b2ca  .............`p|
	defb 07ch,0fch,001h,004h,000h,003h,001h,081h,0ffh,004h,00fh,003h,0ffh,081h,0f0h,006h	; b2da  |...............
	defb 0f8h,081h,0f0h,007h,006h,081h,00eh,003h,000h,004h,001h,004h,000h,004h,0ffh,084h	; b2ea  ................
	defb 0feh,01ch,01ch,03ch,003h,0fch,082h,07ch,03ch,008h,001h,082h,080h,0e3h,006h,0ffh	; b2fa  ...<...|<.......
	defb 008h,0fch,084h,0feh,0fch,0fch,0f8h,004h,0ffh,003h,000h,087h,080h,0c0h,0f0h,0feh	; b30a  ................
	defb 0ffh,0f0h,060h,004h,000h,087h,003h,0ffh,00fh,01fh,01fh,03fh,07fh,003h,0ffh,002h	; b31a  ..`........?....
	defb 000h,002h,080h,085h,0c0h,0f0h,0fch,0ffh,038h,004h,000h,08ch,001h,007h,0ffh,03ch	; b32a  ........8......<
	defb 038h,070h,060h,0e0h,0f0h,0fch,0ffh,001h,005h,000h,081h,001h,003h,0ffh,08ah,07fh	; b33a  8p`.............
	defb 03fh,03fh,07fh,0ffh,0ffh,0fch,0fch,0feh,0feh,004h,0ffh,005h,000h,08dh,080h,0e0h	; b34a  ??..............
	defb 0ffh,0c7h,007h,007h,00fh,00fh,01fh,07fh,0ffh,0fbh,000h,003h,0bfh,081h,000h,003h	; b35a  ................
	defb 0fbh,092h,000h,0bfh,0c0h,0f0h,0f8h,0fch,0feh,0fbh,000h,0bfh,001h,007h,00fh,01fh	; b36a  ................
	defb 03fh,0fbh,00fh,07fh,006h,0ffh,002h,03fh,002h,01fh,002h,00fh,084h,007h,0e0h,0e0h	; b37a  ?......?........
	defb 0f8h,005h,0ffh,081h,0fbh,007h,0ffh,082h,0fbh,0f8h,006h,0ffh,082h,007h,01fh,005h	; b38a  ................
	defb 0ffh,082h,0feh,003h,007h,000h,002h,0ffh,081h,03fh,005h,000h,083h,0fch,0f8h,0e0h	; b39a  .........?......
	defb 005h,000h,00bh,0ffh,003h,0feh,002h,0fch,081h,080h,00bh,000h,002h,001h,002h,003h	; b3aa  ................
	defb 082h,01ch,07fh,006h,0ffh,002h,000h,002h,080h,002h,0c0h,002h,0e0h,083h,0ffh,07fh	; b3ba  ................
	defb 07fh,003h,03fh,002h,01fh,002h,0fch,006h,0f8h,081h,003h,004h,007h,003h,00fh,081h	; b3ca  ..?.............
	defb 0e0h,004h,0f0h,003h,0f8h,002h,01fh,006h,00fh,007h,0f8h,081h,0fch,004h,00fh,004h	; b3da  ................
	defb 007h,005h,0f8h,003h,0f0h,007h,00fh,081h,01fh,003h,0fch,003h,0feh,002h,0ffh,003h	; b3ea  ................
	defb 003h,002h,001h,003h,000h,08ch,0ffh,0f3h,0e0h,0e0h,0f8h,0f8h,0fch,07ch,0f0h,0e0h	; b3fa  .............|..
	defb 0e0h,060h,004h,000h,003h,01fh,003h,03fh,002h,07fh,088h,080h,0c0h,0e0h,0f0h,0f8h	; b40a  .`.....?........
	defb 0feh,0ffh,0ffh,006h,000h,083h,080h,0f0h,018h,009h,000h,08bh,001h,003h,007h,00fh	; b41a  ................
	defb 03fh,03fh,02eh,0e4h,0eah,0eah,0eeh,003h,0ffh,081h,0f8h,004h,0feh,0bah,0f1h,0c1h	; b42a  ??..............
	defb 001h,03fh,07fh,0fdh,0fch,0fch,0f8h,080h,0c0h,0fch,0feh,0ffh,0ffh,07fh,003h,007h	; b43a  .?..............
	defb 00fh,0f0h,0f8h,0f8h,0f9h,07fh,03fh,001h,003h,00fh,007h,0c3h,0ffh,0feh,0fch,0c0h	; b44a  ......?.........
	defb 000h,0fch,0feh,09fh,08fh,087h,0a3h,0b3h,0bbh,0f8h,0f0h,0f0h,0f8h,07fh,03fh,001h	; b45a  ..............?.
	defb 003h,0bfh,03fh,03fh,07fh,0feh,0fch,0c0h,005h,000h,004h,080h,008h,0bfh,088h,000h	; b46a  ..??............
	defb 003h,00fh,01fh,03fh,03fh,0bfh,0bfh,008h,07ch,082h,0e0h,0f8h,006h,0fch,002h,0ffh	; b47a  ...??...|.......
	defb 086h,000h,003h,001h,001h,000h,000h,008h,0f0h,0bah,01fh,07fh,0ffh,0fch,0f8h,0f8h	; b48a  ................
	defb 0f0h,0f0h,000h,001h,002h,004h,008h,010h,020h,041h,000h,080h,0e0h,050h,028h,054h	; b49a  ........ A...P(T
	defb 08ah,005h,000h,000h,07fh,060h,050h,048h,047h,044h,000h,000h,0f0h,018h,014h,014h	; b4aa  .....`PHGD......
	defb 0fch,014h,000h,001h,007h,00ah,014h,02ah,051h,0a0h,000h,080h,040h,020h,010h,008h	; b4ba  .......*Q...@ ..
	defb 004h,082h,0ffh,0ffh,003h,000h,085h,053h,000h,04ch,0ffh,0ffh,003h,000h,085h,053h	; b4ca  .......S.L.....S
	defb 000h,04ch,03fh,07fh,006h,0ffh,003h,000h,081h,001h,004h,003h,003h,000h,081h,080h	; b4da  .L?.............
	defb 004h,0c0h,002h,003h,081h,001h,005h,000h,002h,0c0h,081h,080h,005h,000h,0c2h,03fh	; b4ea  ...............?
	defb 07fh,0ffh,0f8h,0fbh,0f8h,0fbh,0fbh,0fch,0feh,087h,077h,087h,077h,0f7h,0f7h,0cbh	; b4fa  ..........w.w...
	defb 082h,082h,0c7h,07fh,03fh,001h,003h,017h,007h,007h,00fh,0feh,0fch,0c0h,000h,03fh	; b50a  ....?..........?
	defb 07fh,0f0h,0e0h,0e3h,0e7h,0f7h,0fch,0fch,0feh,03fh,01fh,09fh,09fh,01fh,03fh,0fch	; b51a  .........?....?.
	defb 0ffh,0fch,0fch,07fh,03fh,001h,003h,07fh,0ffh,07fh,07fh,0feh,0fch,0c0h,000h,0fch	; b52a  ....?...........
	defb 0feh,006h,0bfh,090h,0f8h,0f0h,0f0h,0f8h,07fh,03fh,001h,003h,0bfh,03fh,03fh,07fh	; b53a  .........?...??.
	defb 0feh,0fch,0c0h,000h,080h,000h,00ah,07fh,0f4h,07fh,0f4h,01ah,0f4h,002h,040h,098h	; b54a  ..............@.
	defb 070h,050h,040h,040h,070h,050h,040h,040h,070h,085h,084h,080h,087h,084h,040h,040h	; b55a  pP@@pP@@p.....@@
	defb 070h,085h,084h,080h,087h,085h,040h,080h,007h,087h,089h,080h,087h,085h,084h,080h	; b56a  p.....@.........
	defb 087h,085h,084h,080h,006h,087h,081h,040h,007h,088h,081h,040h,007h,080h,081h,084h	; b57a  .......@...@....
	defb 027h,080h,07fh,0f8h,046h,0f8h,003h,0f4h,002h,0f0h,006h,0f8h,004h,0f0h,008h,0f8h	; b58a  '...F...........
	defb 004h,0f0h,003h,0f8h,007h,0f0h,00ah,0f8h,004h,0f0h,004h,0f8h,004h,0f0h,008h,040h	; b59a  ...............@
	defb 008h,054h,006h,050h,002h,054h,010h,050h,003h,075h,005h,050h,008h,074h,002h,075h	; b5aa  .T.P.T.P.u.P.t.u
	defb 005h,070h,081h,074h,030h,0a4h,003h,075h,005h,0a0h,003h,075h,004h,0a0h,081h,0a4h	; b5ba  .p.t0..u...u....
	defb 02bh,0f0h,005h,0fch,002h,0f0h,00ah,0fch,004h,0f0h,004h,0fch,006h,0f0h,006h,0fdh	; b5ca  +...............
	defb 002h,0f0h,00ah,0fdh,004h,0f0h,004h,0fdh,006h,0f0h,00ah,0f4h,004h,0f0h,004h,0f4h	; b5da  ................
	defb 004h,0f0h,080h,000h,030h,010h,000h,008h,0ffh,006h,000h,08ah,01fh,03fh,03fh,01fh	; b5ea  ....0........??.
	defb 00fh,007h,003h,001h,000h,000h,007h,0ffh,081h,07fh,005h,080h,003h,000h,002h,07ch	; b5fa  ...............|
	defb 006h,0fch,006h,0ffh,006h,000h,08ch,003h,001h,000h,000h,0e0h,0feh,0ffh,0feh,0f8h	; b60a  ................
	defb 080h,000h,000h,003h,03fh,085h,01fh,00fh,007h,003h,000h,008h,0bfh,084h,00fh,083h	; b61a  ....?...........
	defb 0e0h,0fch,004h,0ffh,085h,07fh,01fh,00fh,003h,001h,003h,000h,003h,0bfh,085h,03fh	; b62a  ...............?
	defb 01fh,007h,0f1h,07eh,005h,000h,093h,080h,0c0h,0e0h,0feh,041h,020h,010h,008h,004h	; b63a  ...~.......A ...
	defb 002h,001h,003h,005h,08ah,054h,028h,050h,0e0h,080h,004h,044h,084h,07fh,024h,01fh	; b64a  .....T(P...D..$.
	defb 000h,004h,014h,094h,0f4h,00ch,0fch,000h,0c0h,0a0h,051h,02ah,014h,00ah,007h,001h	; b65a  ..........Q*....
	defb 07fh,082h,004h,008h,010h,020h,040h,080h,00ch,0f0h,099h,0f8h,0feh,07fh,03fh,0fch	; b66a  ..... @.......?.
	defb 07fh,01fh,007h,001h,03fh,01fh,007h,01fh,07fh,0ffh,0fch,0f8h,0f8h,0f0h,0f0h,024h	; b67a  ....?..........$
	defb 0ffh,0ffh,000h,0ffh,003h,000h,002h,0f0h,088h,0f8h,07ch,01ch,0f0h,001h,001h,000h	; b68a  ..........|.....
	defb 0ffh,003h,0f8h,088h,0ffh,0c4h,0f8h,01fh,01fh,0e0h,0ffh,0ffh,004h,000h,081h,0ffh	; b69a  ................
	defb 003h,0fch,090h,0ffh,025h,05bh,0e8h,000h,0b3h,000h,000h,0ffh,0b7h,000h,0f8h,0feh	; b6aa  ....%[..........
	defb 085h,000h,000h,003h,0ffh,002h,0e0h,005h,000h,085h,0c0h,000h,03fh,0ffh,0c0h,003h	; b6ba  ............?...
	defb 000h,002h,0ffh,083h,0fch,0ffh,003h,004h,000h,002h,007h,006h,000h,002h,0feh,08eh	; b6ca  ................
	defb 0c0h,003h,01fh,0feh,0fch,0f0h,07fh,07fh,000h,080h,0e0h,07fh,03fh,00fh,00bh,0ffh	; b6da  ............?...
	defb 083h,001h,00fh,003h,003h,0ffh,082h,07fh,00fh,003h,000h,002h,0ffh,088h,007h,07fh	; b6ea  ................
	defb 080h,0f8h,007h,007h,000h,000h,004h,0ffh,098h,000h,0ffh,000h,000h,080h,0e0h,0f0h	; b6fa  ................
	defb 0fch,0ffh,0ffh,000h,000h,01fh,001h,001h,01fh,0e0h,0ffh,000h,000h,0ffh,0ffh,000h	; b70a  ................
	defb 000h,003h,03fh,085h,0ffh,000h,000h,0ffh,0ffh,003h,0fch,083h,0ffh,0c0h,080h,006h	; b71a  ..?.............
	defb 000h,084h,007h,001h,006h,008h,004h,000h,008h,0ffh,085h,003h,007h,00fh,00fh,03fh	; b72a  ...............?
	defb 003h,0ffh,085h,0fch,0f8h,0f0h,0e0h,080h,004h,000h,007h,080h,004h,000h,096h,0c0h	; b73a  ................
	defb 0e0h,0f0h,0f8h,01fh,01fh,03fh,03fh,07fh,079h,079h,07bh,0ffh,0e7h,0fbh,0ffh,0e7h	; b74a  .....??.yy{.....
	defb 0e7h,0efh,0e7h,0feh,0feh,006h,0ffh,002h,0f9h,004h,0ffh,083h,0f9h,0f6h,0e7h,007h	; b75a  ................
	defb 0ffh,081h,0f7h,007h,0ffh,003h,0c0h,002h,080h,003h,000h,006h,0ffh,002h,0feh,003h	; b76a  ................
	defb 0ffh,08ch,07fh,0bfh,0bfh,0dfh,0efh,0ffh,08fh,070h,06fh,0b7h,0dbh,0ffh,004h,07fh	; b77a  .........po.....
	defb 088h,07eh,07dh,07dh,07eh,0bfh,000h,080h,080h,006h,0c0h,002h,080h,002h,000h,09bh	; b78a  .~}}~...........
	defb 080h,0e0h,0fch,0bfh,0dfh,03fh,0dfh,0e7h,0fbh,0fdh,0feh,0fdh,0fbh,0fch,0fbh,0e7h	; b79a  .....?..........
	defb 0dfh,0bfh,07fh,0ffh,0feh,000h,0e0h,0f0h,0cch,0b8h,0e6h,005h,000h,088h,080h,0c0h	; b7aa  ................
	defb 0e0h,00fh,01fh,09fh,0bfh,0bfh,003h,07fh,004h,0ffh,002h,0fdh,081h,0feh,006h,0ffh	; b7ba  ................
	defb 088h,07fh,08fh,0f7h,0f0h,0f8h,0f9h,0fdh,0fch,003h,0feh,002h,000h,083h,0c0h,0e0h	; b7ca  ................
	defb 0f0h,003h,0f8h,002h,000h,086h,0c0h,0f0h,078h,07ch,03ch,03eh,003h,0f3h,082h,0fbh	; b7da  ........x|<>....
	defb 0f3h,005h,0ffh,08bh,03fh,0dfh,0e7h,0fbh,0fdh,0feh,0c7h,083h,080h,0c0h,0f0h,003h	; b7ea  ....?...........
	defb 0ffh,085h,0e3h,0c1h,001h,003h,00fh,005h,0ffh,08eh,0fch,0fbh,0e7h,0dfh,0bfh,07fh	; b7fa  ................
	defb 0feh,0feh,0fch,0fch,0f8h,0f0h,0e0h,080h,003h,0cfh,085h,0dfh,0cfh,00eh,006h,000h	; b80a  ................
	defb 005h,080h,083h,001h,003h,007h,005h,080h,083h,003h,007h,00fh,005h,080h,002h,000h	; b81a  ................
	defb 089h,001h,0feh,0feh,0ffh,0ffh,0fdh,0f9h,0f9h,0f1h,003h,0e1h,002h,0f3h,081h,0f7h	; b82a  ................
	defb 003h,0ffh,002h,0feh,004h,0fch,007h,0feh,002h,0ffh,091h,0f1h,0f9h,0f9h,0fbh,0ffh	; b83a  ................
	defb 0fch,0fch,0feh,01fh,01fh,03fh,03fh,07fh,07fh,0ffh,07fh,07fh,006h,03fh,08ch,07fh	; b84a  .....??......?..
	defb 0feh,0feh,0ffh,0ffh,0f1h,083h,007h,00fh,0feh,0fch,0fch,004h,0f8h,084h,0fch,07fh	; b85a  ................
	defb 03fh,03fh,004h,01fh,08bh,03fh,0c3h,0e1h,021h,010h,098h,0deh,0e3h,0f3h,0fch,0feh	; b86a  ??...?..!.......
	defb 006h,0ffh,082h,03fh,07fh,006h,0ffh,002h,0e0h,098h,0c0h,098h,043h,081h,000h,0ffh	; b87a  ...?........C...
	defb 003h,00fh,003h,007h,00fh,03fh,0ffh,0feh,080h,080h,000h,0c0h,040h,060h,070h,078h	; b88a  .....?......@`px
	defb 0fch,0fch,004h,0feh,0a7h,07fh,03fh,000h,000h,0fch,0cfh,0c0h,0e0h,0e0h,0f0h,000h	; b89a  ......?.........
	defb 000h,0e0h,0fch,0ffh,0ffh,0feh,0feh,000h,000h,080h,0c0h,0c0h,0e0h,0f0h,0fch,0feh	; b8aa  ................
	defb 0ffh,07fh,0bfh,0dfh,0efh,0f7h,0f7h,080h,000h,080h,0c0h,0c0h,004h,0e0h,002h,0c0h	; b8ba  ................
	defb 002h,080h,083h,0c0h,0e0h,0e0h,003h,0fbh,005h,0fdh,083h,0f8h,071h,0feh,003h,0ffh	; b8ca  ............q...
	defb 002h,07fh,085h,0c0h,0e0h,0f0h,0f8h,0feh,003h,0ffh,0ach,03eh,00fh,01fh,01fh,03fh	; b8da  ...........>...?
	defb 07fh,0ffh,0feh,078h,0f0h,0f0h,0e0h,0e0h,0c1h,0c3h,081h,083h,007h,01fh,0efh,0f3h	; b8ea  ...x............
	defb 0cdh,0b9h,0e6h,007h,007h,003h,001h,001h,000h,000h,070h,000h,0c0h,0f0h,0f8h,0fch	; b8fa  ..........p.....
	defb 0fch,0feh,0cfh,0e0h,0c0h,0c0h,080h,004h,000h,081h,0e0h,004h,0c0h,084h,0e0h,0f0h	; b90a  ................
	defb 0f8h,0e0h,003h,0c0h,004h,080h,004h,0ffh,002h,0fbh,083h,039h,001h,07fh,004h,0bfh	; b91a  ...........9....
	defb 002h,03fh,081h,01eh,005h,0ffh,086h,0efh,0dfh,000h,0ffh,07fh,07fh,003h,0bfh,085h	; b92a  .?..............
	defb 00fh,000h,0ffh,0feh,0feh,003h,0fdh,09dh,0f0h,000h,0ffh,03fh,04fh,0b0h,0bfh,0bfh	; b93a  ...........?O...
	defb 00fh,000h,0ffh,0fch,0f0h,001h,0fdh,0fdh,0f0h,000h,078h,0f0h,0e0h,0c0h,080h,000h	; b94a  ..........x.....
	defb 0f0h,0fch,007h,003h,001h,003h,000h,092h,00fh,03fh,03fh,01fh,00fh,003h,000h,000h	; b95a  .........??.....
	defb 00fh,03fh,07fh,03fh,00fh,007h,003h,001h,00fh,03fh,005h,0ffh,083h,0feh,0f0h,0fch	; b96a  .?.?.....?......
	defb 004h,0ffh,084h,0feh,0fch,0fch,078h,004h,001h,089h,00fh,003h,000h,000h,003h,007h	; b97a  ......x.........
	defb 00fh,01fh,03fh,003h,0ffh,083h,000h,07fh,00fh,003h,000h,091h,001h,003h,0bfh,0dfh	; b98a  ..?.............
	defb 0efh,0f7h,0f9h,0feh,07fh,03ch,0feh,0fdh,0fdh,0fbh,0fbh,0efh,080h,004h,0ffh,0b9h	; b99a  .....<..........
	defb 0f7h,07bh,03ch,00fh,000h,01fh,03fh,07fh,0ffh,0ffh,0feh,0fch,0f0h,07fh,0feh,0feh	; b9aa  .{<...?.........
	defb 0fdh,0fbh,0f7h,0f6h,0e0h,0f0h,0f0h,0f8h,0fch,0feh,0ffh,07fh,07fh,0feh,0ffh,01fh	; b9ba  ................
	defb 00fh,087h,0c7h,0e7h,03ch,07fh,0ffh,0f8h,0f0h,0e1h,0e3h,0e7h,03ch,03fh,01fh,0f0h	; b9ca  ....<.......<?..
	defb 0f8h,003h,0fch,0fch,0ffh,0c0h,080h,0ffh,01fh,003h,0fch,081h,000h,003h,0ffh,091h	; b9da  ................
	defb 003h,0e0h,03fh,03fh,0ffh,07ch,07ch,007h,01fh,03fh,07fh,0ffh,0ffh,07ch,07ch,007h	; b9ea  ..??.||..?...||.
	defb 07fh,004h,0ffh,08dh,003h,007h,00fh,00fh,01fh,03fh,0ffh,0ffh,003h,007h,00fh,01fh	; b9fa  .........?......
	defb 07fh,003h,0ffh,083h,0fch,01fh,07fh,003h,0ffh,002h,0feh,0a0h,001h,0ffh,000h,007h	; ba0a  ................
	defb 00fh,033h,01dh,067h,07fh,0c0h,0ffh,007h,00fh,033h,01dh,067h,0ffh,0fch,085h,003h	; ba1a  .3.g.....3.g....
	defb 007h,00fh,0e0h,01fh,01eh,00fh,00fh,007h,0f8h,0fch,003h,001h,004h,000h,089h,001h	; ba2a  ................
	defb 003h,007h,00fh,00fh,01fh,03fh,03fh,0c0h,003h,0bfh,093h,000h,0ffh,000h,000h,0ffh	; ba3a  .....??.........
	defb 0feh,007h,03fh,03fh,07fh,07fh,03eh,0ffh,001h,0ffh,0e7h,0fch,003h,001h,003h,0ffh	; ba4a  ..??..>.........
	defb 08ah,01eh,0ffh,007h,0f8h,0f0h,01fh,01fh,00eh,000h,000h,003h,0ffh,0a7h,07fh,0c0h	; ba5a  ................
	defb 080h,07fh,07fh,0ffh,0ffh,0dfh,03fh,080h,080h,07fh,07fh,0f8h,0feh,085h,070h,0ffh	; ba6a  ......?.......p.
	defb 0ffh,080h,01fh,0ffh,080h,0ffh,007h,00fh,033h,01dh,067h,000h,0ffh,000h,000h,0ffh	; ba7a  ........3.g.....
	defb 0feh,003h,00fh,07fh,080h,003h,07fh,002h,0bfh,0a1h,0dfh,001h,003h,007h,007h,0f0h	; ba8a  ................
	defb 0e0h,01eh,01ch,007h,003h,0ffh,0ffh,000h,0ffh,000h,0e7h,0f8h,0feh,085h,0c0h,000h	; ba9a  ................
	defb 0ffh,0feh,00fh,092h,0ffh,0feh,003h,007h,007h,00fh,00fh,004h,0ffh,08eh,0dfh,0bfh	; baaa  ................
	defb 07fh,07fh,003h,007h,00fh,00fh,01fh,01fh,080h,0ffh,0fbh,000h,003h,0bfh,08eh,000h	; baba  ................
	defb 0fbh,0fbh,0ffh,03fh,03fh,01fh,01fh,00fh,00fh,007h,0e0h,0e0h,0f8h,005h,0ffh,082h	; baca  ...??...........
	defb 007h,01fh,005h,0ffh,082h,0feh,003h,007h,000h,002h,0ffh,081h,03fh,005h,000h,083h	; bada  ............?...
	defb 0fch,0f8h,0e0h,005h,000h,088h,0feh,0fch,0f0h,0e0h,0c0h,080h,0f0h,0fch,080h,000h	; baea  ................
	defb 010h,038h,040h,028h,050h,01bh,054h,003h,050h,002h,054h,007h,040h,081h,050h,030h	; bafa  .8@(P.T.P.T.@.P0
	defb 0a4h,00dh,074h,002h,075h,002h,074h,004h,075h,003h,054h,002h,075h,005h,070h,086h	; bb0a  ..t.u.t.u.T.u.p.
	defb 074h,075h,0f5h,0e5h,074h,074h,003h,075h,002h,050h,003h,054h,088h,074h,0e7h,0e7h	; bb1a  tu..tt.u.P.T.t..
	defb 040h,040h,050h,050h,0f0h,003h,0f5h,082h,0feh,0e4h,003h,074h,003h,0e5h,002h,040h	; bb2a  @@PP.......t...@
	defb 086h,0a0h,090h,090h,0eeh,075h,075h,005h,0a4h,086h,055h,0f7h,0f7h,040h,040h,0a4h	; bb3a  .....uu...U..@@.
	defb 003h,050h,082h,0f0h,075h,007h,0f0h,081h,050h,003h,0fch,004h,0f0h,083h,050h,0c0h	; bb4a  .P..u...P.....P.
	defb 0ech,00eh,0e0h,002h,020h,003h,0c2h,003h,0c0h,002h,020h,003h,0c2h,003h,0c0h,018h	; bb5a  .... ..... .....
	defb 0c2h,002h,0c0h,002h,0ech,081h,0e5h,003h,050h,005h,0ceh,003h,050h,004h,0c2h,081h	; bb6a  ........P...P...
	defb 0e5h,003h,050h,002h,052h,002h,0f2h,081h,0e5h,003h,050h,004h,0ceh,004h,0c0h,002h	; bb7a  ..P.R.....P.....
	defb 0fch,002h,0e0h,081h,0c0h,003h,020h,010h,0f0h,030h,0d0h,081h,0ddh,07fh,0d0h,065h	; bb8a  ...... ..0.....e
	defb 0d0h,003h,0fdh,005h,040h,003h,0d0h,005h,040h,003h,0d0h,007h,040h,081h,0d0h,068h	; bb9a  ....@...@...@..h
	defb 0dah,004h,0a0h,004h,0dah,002h,0d0h,005h,0dah,004h,0d0h,085h,0a0h,0d0h,0a0h,0d0h	; bbaa  ................
	defb 0a0h,006h,0d0h,002h,0dah,003h,0d0h,005h,0dah,002h,0d0h,004h,0dah,004h,0d0h,004h	; bbba  ................
	defb 0a0h,083h,0d0h,0dah,0dah,007h,0d0h,081h,0a0h,00bh,0d0h,004h,0a0h,081h,0dah,007h	; bbca  ................
	defb 0d0h,081h,0a0h,007h,0dah,003h,0a0h,006h,0d0h,005h,0dah,009h,0d0h,003h,0dah,00bh	; bbda  ................
	defb 0d0h,004h,0a0h,006h,0d0h,081h,0dah,01ch,0dch,002h,0d0h,002h,0dch,006h,0d0h,002h	; bbea  ................
	defb 0dch,007h,0d0h,081h,0dch,006h,0d0h,002h,0dch,006h,0d0h,002h,0dch,006h,0d0h,002h	; bbfa  ................
	defb 0dch,006h,0d0h,002h,0dch,006h,0d0h,002h,020h,006h,0d0h,002h,020h,006h,0d0h,002h	; bc0a  ........ ... ...
	defb 020h,006h,0d0h,002h,020h,006h,0d0h,002h,020h,007h,0d0h,081h,0d2h,003h,0dch,083h	; bc1a   ... ... .......
	defb 0d2h,0c2h,0c2h,005h,0dch,002h,0d2h,004h,0dch,002h,0c2h,003h,0d2h,002h,0dch,006h	; bc2a  ................
	defb 0d0h,082h,0d2h,0dch,006h,0d0h,082h,0d2h,0cch,006h,0d0h,082h,0d2h,0dch,005h,0dah	; bc3a  ................
	defb 003h,0dch,081h,0dah,005h,0d0h,082h,0d2h,0dch,006h,0dah,002h,0dch,081h,0d0h,006h	; bc4a  ................
	defb 0dah,083h,0dch,0d0h,0d0h,005h,0dah,003h,0dch,002h,0edh,081h,0dch,003h,020h,002h	; bc5a  .............. .
	defb 0dch,08bh,0edh,0feh,0c0h,020h,020h,0c2h,0d0h,0d0h,0d5h,0edh,0dch,003h,0c0h,002h	; bc6a  .....  .........
	defb 050h,006h,0d5h,002h,050h,006h,0d5h,005h,0d0h,003h,0d5h,003h,0a5h,005h,0d5h,081h	; bc7a  P...P...........
	defb 050h,005h,0d5h,002h,0dah,085h,0d7h,0feh,0feh,0d4h,0d7h,003h,0d5h,085h,0d7h,0fdh	; bc8a  P...............
	defb 0eah,0d4h,0d7h,003h,0d5h,002h,040h,08eh,0a4h,0d0h,0d0h,0d5h,0fdh,0d7h,0d0h,0d4h	; bc9a  ......@.........
	defb 0d5h,0d5h,0fdh,0edh,0d7h,0d7h,005h,0d0h,088h,0d5h,0d7h,0d7h,0d0h,0d4h,0d5h,0d5h	; bcaa  ................
	defb 0fdh,004h,0d0h,003h,045h,08fh,0ffh,0edh,0d7h,0d7h,0d0h,0d4h,0d5h,0d5h,0feh,0feh	; bcba  ....E...........
	defb 075h,075h,0dch,0fdh,0fdh,004h,0d0h,084h,050h,0dch,0edh,0edh,003h,0d0h,002h,070h	; bcca  uu......P......p
	defb 004h,0d5h,082h,0fdh,0edh,004h,0d7h,089h,0d0h,0d5h,0fdh,0edh,0d7h,0d7h,040h,040h	; bcda  ..............@@
	defb 0a4h,003h,0d0h,087h,0fdh,0d7h,0d0h,0fdh,0eeh,0d4h,0d7h,003h,0d5h,081h,000h,003h	; bcea  ................
	defb 045h,087h,0ffh,0edh,0d7h,0d7h,0d5h,0fdh,0dah,006h,0d0h,089h,0d4h,0d5h,0d5h,0fdh	; bcfa  E...............
	defb 0edh,0d7h,0d7h,0d0h,0d4h,003h,05fh,002h,0e7h,090h,075h,040h,040h,0a4h,040h,040h	; bd0a  ......_...u@@.@@
	defb 055h,0fdh,0d7h,075h,0fdh,0eah,0d4h,0a7h,0d5h,0a5h,005h,0d5h,002h,0d0h,002h,0d7h	; bd1a  U..u............
	defb 005h,0d0h,095h,0d5h,0fdh,0d5h,040h,040h,070h,050h,040h,040h,070h,050h,080h,080h	; bd2a  ......@@pP@@pP..
	defb 087h,085h,084h,080h,087h,085h,084h,080h,006h,087h,081h,084h,00fh,080h,002h,088h	; bd3a  ................
	defb 00eh,080h,006h,0d0h,002h,020h,080h,000h,018h,084h,01fh,00fh,007h,001h,00dh,000h	; bd4a  ..... ..........
	defb 088h,080h,0e0h,0fch,07fh,03fh,00fh,003h,001h,00bh,000h,08ah,080h,0c0h,0e0h,070h	; bd5a  .....?.........p
	defb 038h,01ch,00eh,007h,003h,001h,003h,000h,082h,001h,003h,009h,007h,088h,087h,0c7h	; bd6a  8...............
	defb 0e7h,07fh,0e0h,0f8h,07ch,03ch,00ch,01ch,020h,000h,002h,01ch,081h,018h,01eh,000h	; bd7a  ....|<.. .......
	defb 087h,080h,060h,030h,018h,00ch,006h,003h,020h,000h,0a7h,001h,003h,006h,00ch,018h	; bd8a  ..`0.... .......
	defb 030h,060h,080h,000h,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,07fh,03fh,01fh,00fh	; bd9a  0`.......?...?..
	defb 007h,003h,001h,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0fch,0f8h,0f0h,0e0h	; bdaa  ................
	defb 0c0h,080h,014h,000h,081h,008h,009h,00ch,081h,004h,00fh,000h,082h,03fh,01fh,00eh	; bdba  .............?..
	defb 000h,082h,0f8h,0fch,003h,000h,00bh,07fh,005h,000h,00bh,0f0h,006h,000h,08bh,001h	; bdca  ................
	defb 003h,007h,00fh,01fh,03fh,01fh,00fh,007h,003h,001h,004h,000h,08dh,0c0h,0e0h,0f0h	; bdda  ....?...........
	defb 0f8h,0fch,0feh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,009h,000h,087h,0c0h,0e0h,070h	; bdea  ...............p
	defb 038h,01ch,00eh,007h,012h,000h,087h,001h,007h,00eh,01ch,038h,070h,0e0h,009h,000h	; bdfa  8..........8p...
	defb 081h,080h,010h,000h,082h,00fh,01fh,00eh,000h,082h,0fch,0f8h,01eh,000h,081h,002h	; be0a  ................
	defb 00ah,006h,081h,004h,006h,000h,00bh,03fh,005h,000h,00bh,0f8h,003h,000h,084h,0c0h	; be1a  .......?........
	defb 0e0h,070h,030h,00bh,000h,081h,01ch,003h,00eh,081h,006h,01ah,000h,009h,01ch,017h	; be2a  .p0.............
	defb 000h,083h,01ch,018h,010h,00dh,000h,002h,001h,002h,003h,002h,007h,083h,0ffh,07fh	; be3a  ................
	defb 03fh,003h,01fh,083h,03eh,038h,070h,003h,000h,002h,080h,002h,0c0h,083h,0feh,0fch	; be4a  ?...>8p.........
	defb 0f8h,003h,0f0h,084h,0f8h,038h,00ch,000h,000h	; be5a  .....8...

; ----------------------------------------------------------------------
; DATOS graficos_del_menu: RLE de 0x46A0: el Q*bert grande de los menus de
;   nivel, patrones y colores del tercer tercio (640 bytes)
;   0xbe63..0xbfa5  (322 bytes)
DATA_graficos_del_menu:
	defb 000h,032h,090h,000h,0c0h,0f0h,0fch,0feh,0feh,0ffh,0ffh,000h,000h,060h,0f0h,0f8h	; be63  .2...........`..
	defb 0f8h,0fch,07ch,003h,007h,082h,00fh,01fh,003h,03fh,004h,0fdh,084h,0ffh,0f7h,0f1h	; be73  ..|......?......
	defb 0feh,004h,0dfh,09ch,0ffh,0f7h,0e7h,01fh,080h,080h,0c0h,0c0h,0e0h,0e0h,0f0h,0f8h	; be83  ................
	defb 07eh,07fh,03fh,03fh,01fh,01fh,00fh,00fh,07fh,07dh,07bh,03dh,0deh,0eeh,0edh,0f3h	; be93  ~.??.....}{=....
	defb 008h,0ffh,08bh,0d8h,0dch,0ech,0ech,0e8h,0d0h,0b8h,0b8h,007h,003h,001h,003h,000h	; bea3  ................
	defb 08ah,001h,003h,0ffh,0ffh,0dfh,0dfh,03fh,0ffh,0b7h,06fh,005h,0ffh,0a3h,0cfh,0f7h	; beb3  .......?..o.....
	defb 0e0h,0ffh,0feh,0fdh,0fdh,0fbh,0fbh,0e3h,001h,066h,0f9h,0ffh,0fch,0fch,0f8h,0f0h	; bec3  .........f......
	defb 0e0h,0d8h,0dch,0ech,0ech,0e8h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,080h,0e0h,0fch,09ah	; bed3  ................
	defb 0ech,004h,0ffh,086h,0feh,0f9h,0c7h,03fh,000h,000h,003h,001h,003h,003h,083h,000h	; bee3  .......?........
	defb 0e0h,080h,005h,0ffh,090h,000h,003h,00fh,03fh,07fh,07fh,0ffh,0ffh,000h,000h,006h	; bef3  ........?.......
	defb 00fh,01fh,01fh,03fh,03eh,003h,0e0h,082h,0f0h,0f8h,003h,0fch,004h,0bfh,084h,0ffh	; bf03  ...?>...........
	defb 0efh,08fh,07fh,004h,0fbh,09ch,0ffh,0efh,0e7h,0f8h,001h,001h,003h,003h,007h,007h	; bf13  ................
	defb 00fh,01fh,07eh,0feh,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0feh,0beh,0deh,0bch,07bh,077h	; bf23  ..~...........{w
	defb 0b7h,0cfh,008h,0ffh,08bh,01bh,03bh,037h,037h,017h,00bh,01dh,01dh,0e0h,0c0h,080h	; bf33  ......;77.......
	defb 003h,000h,08ah,080h,0c0h,0ffh,0ffh,0fbh,0fbh,0fch,0ffh,0edh,0f6h,005h,0ffh,0a3h	; bf43  ................
	defb 0f3h,0efh,007h,0ffh,07fh,0bfh,0bfh,0dfh,0dfh,0c7h,080h,066h,09fh,0ffh,03fh,03fh	; bf53  ...........f..??
	defb 01fh,00fh,007h,01bh,03bh,037h,037h,017h,00fh,007h,007h,003h,003h,001h,001h,007h	; bf63  ....;77.........
	defb 03fh,059h,037h,004h,0ffh,086h,07fh,09fh,0e3h,0fch,000h,000h,003h,080h,003h,0c0h	; bf73  ?Y7.............
	defb 083h,000h,0f8h,0feh,005h,0ffh,080h,000h,012h,07fh,050h,011h,050h,004h,0a0h,005h	; bf83  ..........P.P...
	defb 050h,002h,0a5h,005h,050h,07fh,0d0h,013h,0d0h,002h,0a0h,005h,0d0h,002h,0dah,005h	; bf93  P...P...........
	defb 0d0h,000h	; bfa3

; ----------------------------------------------------------------------
; DATOS patrones_del_menu: RLE de 0x46A0 con destino 0x1800: cuatro sprites
;   del menu (128 bytes)
;   0xbfa5..0xbfe7  (66 bytes)
DATA_patrones_del_menu:
	defb 000h,018h,008h,000h,091h,038h,01ch,00ch	; bfa5  .....8..
	defb 008h,003h,003h,001h,000h,000h,004h,00ch	; bfad  ........
	defb 00ch,008h,000h,018h,030h,020h,004h,000h	; bfb5  ....0 ..
	defb 003h,080h,089h,000h,020h,030h,030h,010h	; bfbd  .... 00.
	defb 000h,018h,00ch,004h,004h,000h,003h,001h	; bfc5  ........
	defb 008h,000h,087h,01ch,038h,030h,010h,0c0h	; bfcd  ....80..
	defb 0c0h,080h,00ch,000h,084h,060h,0e0h,0e0h	; bfd5  .....`..
	defb 0c0h,02ch,000h,085h,006h,007h,007h,003h	; bfdd  .,......
	defb 000h,000h	; bfe5

; ----------------------------------------------------------------------
; DATOS relleno: Un 0x00 y catorce 0xFF hasta la marca
;   0xbfe7..0xbff6  (15 bytes)
DATA_relleno:
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfe7  ...............

; ----------------------------------------------------------------------
; DATOS marca_de_konami: La marca oculta de Konami: el titulo en katakana AL
;   REVES, siete caracteres (0x86 0xB2 0xBA 0x99 0xBA 0xB7 0x93 leidos de
;   atras adelante: キューバート, Q*bert), su longitud (7), el RC en BCD (0x46) y
;   0xAA. Nadie la lee: tools/marca_konami.py
;   0xbff6..0xc000  (10 bytes)
DATA_marca_de_konami:
	defb 093h,0bah,0b7h,099h,0bah,0b2h,086h,007h,046h,0aah	; bff6  ........F.
