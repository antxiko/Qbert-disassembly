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
	di			;4028
	call suena_un_cuadro		;4029   ; el sonido va primero y con las interrupciones cortadas: no se salta un cuadro
	ld hl,0e005h		;402c   ; (0xE005) a uno: el cuadro anterior sigue a medias
	bit 0,(hl)		;402f
	jr nz,L_4040		;4031   ; si sigue, este cuadro solo suena
	inc (hl)			;4033   ; se marca el cuadro como en curso
	ei			;4034   ; y se abren las interrupciones: la escena puede durar mas de un cuadro
	call lee_los_mandos		;4035   ; lee los dos mandos y el teclado
	call haz_el_cuadro		;4038   ; y hace la escena que toque
	ld a,000h		;403b   ; cuadro acabado
	ld (0e005h),a		;403d
L_4040:
	call 0013eh		;4040   ; BIOS RDVDP - Reads VDP status register | si mientras tanto llego otra interrupcion (bit 7 del estado)...
	or a			;4043
	di			;4044
	call m,suena_un_cuadro		;4045   ; ...su sonido se hace ahora, para no perderlo
	ei			;4048
	ret			;4049
suma_a_a_hl:		; HL += A, con el acarreo al alto
	add a,l			;404a
	ld l,a			;404b
	ret nc			;404c
	inc h			;404d
	ret			;404e
suma_a_a_de:		; DE += A, igual
	add a,e			;404f
	ld e,a			;4050
	ret nc			;4051
	inc d			;4052
	ret			;4053
reparte_por_tabla:		; El `pop hl` recoge la tabla: es la direccion de retorno
	pop hl			;4054   ; la tabla va pegada detras del `call`: su direccion es la de retorno
	add a,a			;4055   ; entradas de dos bytes
	call suma_a_a_hl		;4056
	ld e,(hl)			;4059   ; la entrada A de la tabla...
	inc hl			;405a
	ld d,(hl)			;405b
	ex de,hl			;405c
	jp (hl)			;405d   ; ...y alli se salta

; ----------------------------------------------------------------------
; INIT. Lo que ejecuta la BIOS al encontrar la "AB". Busca en que ranura esta el cartucho, pone la pagina 2 en esa misma ranura (el juego ocupa 0x4000-0xBFFF), engancha la interrupcion y se queda parado: todo lo demas pasa en 0x4025.
; ----------------------------------------------------------------------
INIT:		; Lo que ejecuta la BIOS al encontrar la "AB" de 0x4000
	di			;405e
	call 00138h		;405f   ; BIOS RSLREG - Reads the primary slot register | RSLREG: las ranuras de las cuatro paginas
	rrca			;4062   ; la de la pagina 1, que es donde corre esto
	rrca			;4063
	and 003h		;4064
	ld c,a			;4066
	ld hl,0fcc1h		;4067   ; EXPTBL: si esa ranura esta expandida (bit 7)...
	add a,l			;406a
	ld l,a			;406b
	ld a,(hl)			;406c   ; ...se anade el bit de expansion
	and 080h		;406d
	or c			;406f
	ld c,a			;4070
	inc l			;4071   ; y en SLTTBL, cuatro bytes mas alla, la subranura de la pagina 1
	inc l			;4072
	inc l			;4073
	inc l			;4074
	ld a,(hl)			;4075
	and 00ch		;4076   ; bits 2-3: la subranura
	or c			;4078
	ld h,080h		;4079   ; H=0x80: la pagina 2
	call 00024h		;407b   ; BIOS ENASLT - Switches to specified slot and page definitively | ENASLT: la pagina 2 pasa a la ranura del cartucho
	ld a,001h		;407e   ; 1, 2 y 3 a los registros de banco de un mapeador de Konami. En un cartucho de 32 KB sin mapeador no hacen nada: son las escrituras de la casa, las mismas en todos
	ld (06000h),a		;4080
	inc a			;4083
	ld (08000h),a		;4084
	inc a			;4087
	ld (0a000h),a		;4088
	ld hl,0fd00h		;408b   ; de 0xFD00 a 0xFEFF todo `ret`: los ganchos de la BIOS quedan mudos
	ld de,0fd01h		;408e
	ld bc,00200h		;4091
	ld (hl),0c9h		;4094
	ldir		;4096
	ld a,0c3h		;4098   ; y en H.KEYI (0xFD9A) un `jp 0x4025`
	ld (0fd9ah),a		;409a
	ld hl,cada_cuadro		;409d
	ld (0fd9bh),hl		;40a0
	ld sp,0eaffh		;40a3   ; la pila, debajo de 0xEB00
	ld hl,0e000h		;40a6   ; borra de 0xE000 a 0xE3FF
	ld de,0e001h		;40a9
	ld bc,003ffh		;40ac
	ld (hl),000h		;40af
	ldir		;40b1
	ld a,001h		;40b3   ; (0xE005)=1 mientras se prepara el VDP: la interrupcion no toca escenas
	ld (0e005h),a		;40b5
	call apaga_y_borra_la_vram		;40b8   ; apaga el sonido, borra la VRAM y pone los registros
	xor a			;40bb
	ld (0e005h),a		;40bc
	call 0013eh		;40bf   ; BIOS RDVDP - Reads VDP status register | lee el estado para no arrancar con una interrupcion pendiente
	ei			;40c2
el_bucle_vacio:		; INIT acaba aqui: a partir de este `jr $` todo pasa en la interrupcion
	jr el_bucle_vacio		;40c3
haz_el_cuadro:		; Cuenta el cuadro y reparte la escena que toque
	ld hl,0e003h		;40c5   ; (0xE003): el contador de cuadros, que usa medio juego para ir a su ritmo
	inc (hl)			;40c8
	ld a,(0e002h)		;40c9   ; bit 6 de (0xE002): hay partida de verdad
	and 040h		;40cc
	ld hl,045fch		;40ce   ; con partida, la escena vuelve a un `ret` y ya esta...
	jr nz,L_40D6		;40d1
	ld hl,0441eh		;40d3   ; ...sin partida, vuelve a 0x441E, que mira si se pulsa para empezar
L_40D6:
	ld bc,(0e000h)		;40d6   ; C = escena (0xE000), B = su paso (0xE001)
	ld a,c			;40da
	cp 003h		;40db   ; la escena 3, el menu de nivel, no mira nada a la vuelta
	jr z,L_40E0		;40dd
	push hl			;40df   ; la vuelta se apila: el `ret` de la escena salta ahi
L_40E0:
	call reparte_por_tabla		;40e0

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
	rra			;40fa
	ret nc			;40fb
	call destapa_una_linea_del_logotipo		;40fc   ; pinta una linea de pixeles del logotipo; Z cuando acaba
	ret nz			;40ff
	xor a			;4100   ; hecho: espera de 256 cuadros (0xE004=0) y al paso 2
	jp espera_a_y_sigue		;4101
L_4104:
	djnz L_4116		;4104   ; paso 2: esperar
	ld hl,0e004h		;4106
	dec (hl)			;4109
	ret nz			;410a
	call borra_la_copia_de_nombres		;410b   ; borra la copia de la tabla de nombres
	ld b,000h		;410e   ; fondo negro...
	call pon_el_fondo		;4110
	jp escena_siguiente_con_espera_a		;4113   ; ...y a la escena 1
L_4116:
	call pon_los_registros_del_vdp		;4116   ; paso 0: registros del VDP
	call borra_la_pantalla		;4119   ; tabla de nombres a cero
	call monta_la_fuente		;411c   ; la fuente
	call monta_el_logotipo_de_konami		;411f   ; y el logotipo de KONAMI, con los colores a cero
	jr paso_siguiente		;4122

; ----------------------------------------------------------------------
; ESCENA 1: LA PRESENTACION. Q*bert delante de la maquina recreativa (pasos 1 a 8, en 0x83DA-0x8528), el titulo (paso 9) y el cursor de 1PLAYER/2PLAYERS parpadeando (paso 10). El paso 0 la prepara.
; ----------------------------------------------------------------------
escena_presentacion:
	djnz L_4129		;4124   ; pasos 1 a 8: la presentacion, un bloque por paso
	jp L_83DA		;4126
L_4129:
	djnz L_412E		;4129
	jp L_83EE		;412b
L_412E:
	djnz L_4133		;412e
	jp L_8419		;4130
L_4133:
	djnz L_4138		;4133
	jp L_8455		;4135
L_4138:
	djnz L_413D		;4138
	jp L_845F		;413a
L_413D:
	djnz L_4142		;413d
	jp L_84B5		;413f
L_4142:
	djnz L_4147		;4142
	jp L_84E5		;4144
L_4147:
	djnz L_414C		;4147
	jp L_8528		;4149
L_414C:
	djnz L_4154		;414c   ; paso 9: el titulo
	call pinta_el_titulo		;414e
	xor a			;4151
	jr espera_a_y_sigue		;4152
L_4154:
	djnz L_4160		;4154   ; paso 10: el cursor parpadea 256 cuadros...
	ld hl,0e004h		;4156
	dec (hl)			;4159
	jp nz,parpadea_el_cursor		;415a   ; ...y si nadie pulsa, la escena 2, la demostracion
	jp escena_siguiente		;415d
L_4160:
	call L_8394		;4160   ; paso 0: la pantalla de la recreativa, y a por el paso 1
	jp L_83AF		;4163

; ----------------------------------------------------------------------
; ESCENA 2: LA DEMOSTRACION. El juego de verdad, con las pulsaciones sacadas de 0x6BBF/0x6BD8. Se alternan dos: un jugador en la fase 34 y dos a la vez en la 37.
; ----------------------------------------------------------------------
escena_demostracion:
	djnz L_417C		;4166   ; paso 1: juega un cuadro
	call L_6B82		;4168   ; las pulsaciones grabadas
	call L_6B7F		;416b   ; el cuadro de partida, el mismo que en el juego
	ld a,(0e113h)		;416e   ; (0xE113) a cero: el Q*bert de la demostracion ha caido o se acabo el guion
	or a			;4171
	ret nz			;4172
	ld a,014h		;4173   ; sonido 0x14 y 120 cuadros de espera
	call toca_sonido		;4175
	ld a,078h		;4178
	jr espera_a_y_sigue		;417a
L_417C:
	djnz L_418F		;417c   ; paso 2: la espera
	ld hl,0e004h		;417e
	dec (hl)			;4181
	ret nz			;4182
vuelve_al_logotipo:
	xor a			;4183   ; escena 0, el logotipo, con 32 cuadros de espera
pon_escena_a:
	ld (0e000h),a		;4184
	ld a,020h		;4187
	ld (0e004h),a		;4189
	jp al_paso_0		;418c
L_418F:
	call borra_la_pantalla		;418f   ; paso 0: pantalla en negro y a montar la demostracion
	call L_6B47		;4192
	ld a,020h		;4195
espera_a_y_sigue:		; (0xE004)=A y al paso siguiente
	ld (0e004h),a		;4197
paso_siguiente:
	ld hl,0e001h		;419a
	inc (hl)			;419d
	ret			;419e

; ----------------------------------------------------------------------
; ESCENA 3: EL MENU DE NIVEL. LEVEL 1-5 con un jugador; con dos, dos niveles y la partida a 3 o a 5 duelos. Esta escena no apila vuelta: mientras se elige, 0x441E no mira los mandos.
; ----------------------------------------------------------------------
escena_menu_de_nivel:
	djnz L_41B1		;419f   ; paso 1: dibujar el menu
	ld a,(0e102h)		;41a1   ; (0xE102): uno o dos jugadores
	or a			;41a4
	jr z,L_41AC		;41a5
	call L_7FFE		;41a7
	jr paso_siguiente		;41aa
L_41AC:
	call L_7F1A		;41ac
	jr paso_siguiente		;41af
L_41B1:
	djnz L_41D0		;41b1   ; paso 2: elegir. Los dos lectores hacen `pop hl` y vuelven de la escena mientras no se pulse el disparo
	ld a,(0e102h)		;41b3
	or a			;41b6
	jr z,L_41BE		;41b7
	call L_8028		;41b9
	jr L_41C1		;41bc
L_41BE:
	call L_7F2E		;41be
L_41C1:
	call empieza_en_el_nivel_elegido		;41c1   ; con el nivel ya elegido, la fase en la que se empieza
	call aplica_la_fase_del_game_master		;41c4   ; y si el Game Master pide otra, esa
	ld a,041h		;41c7   ; sonido 0x41 y 80 cuadros
	call toca_sonido		;41c9
	ld a,050h		;41cc
	jr espera_a_y_sigue		;41ce
L_41D0:
	djnz L_41E2		;41d0   ; paso 3: parpadea la opcion elegida mientras dura la espera
	ld hl,0e004h		;41d2
	dec (hl)			;41d5
	jr z,L_41E0		;41d6
	ld a,(0e102h)		;41d8
	or a			;41db
	ret nz			;41dc
	jp L_7F40		;41dd
L_41E0:
	jr escena_siguiente		;41e0   ; y a la escena 4
L_41E2:
	call borra_la_pantalla		;41e2   ; paso 0: pantalla en negro, la fuente y 80 cuadros
	call monta_la_fuente		;41e5
	ld a,050h		;41e8
	jr espera_a_y_sigue		;41ea

; ----------------------------------------------------------------------
; ESCENA 4: EL PRINCIPIO DE FASE. El paso 0 descuenta la vida que se va a jugar y pone el rotulo (LEVEL y STAGE al empezar un nivel, READY en el duelo); el paso 1 monta la fase cuando callan el sonido y la espera.
; ----------------------------------------------------------------------
escena_principio_de_fase:
	djnz L_4224		;41ec   ; paso 1: montar
	ld hl,0e004h		;41ee
	ld a,(hl)			;41f1
	or a			;41f2
	jr z,L_41F7		;41f3
	dec (hl)			;41f5
	ret nz			;41f6
L_41F7:
	ld a,(0e012h)		;41f7   ; espera a que acabe la musica del canal 1
	or a			;41fa
	ret nz			;41fb
	ld a,017h		;41fc   ; sonido 0x17, la musica de la fase
	call toca_sonido		;41fe
	ld a,020h		;4201
	ld (0e004h),a		;4203
	call borra_la_pantalla		;4206
	call monta_la_fase		;4209   ; la fase entera: tablero, cubos, bichos y marcador
	ld hl,0e113h		;420c   ; Q*bert en juego
	ld (hl),001h		;420f
	ld hl,0e35ch		;4211   ; y el segundo Q*bert tambien
	ld (hl),001h		;4214
escena_siguiente:		; Siguiente escena, con 32 cuadros de espera
	ld a,020h		;4216
escena_siguiente_con_espera_a:
	ld (0e004h),a		;4218
	ld hl,0e000h		;421b
	inc (hl)			;421e
al_paso_0:
	xor a			;421f
	ld (0e001h),a		;4220
	ret			;4223
L_4224:
	ld hl,0e110h		;4224   ; paso 0: una vida menos, la que se juega ahora; el marcador de vidas cuenta las de reserva
	ld a,(hl)			;4227
	sub 001h		;4228
	daa			;422a
	ld (hl),a			;422b
	ld (0e120h),a		;422c   ; y la copia del segundo jugador
	ld a,(0e002h)		;422f
	bit 5,a		;4232   ; bit 5 de (0xE002): el duelo
	jr z,L_424A		;4234
	call L_7E5A		;4236   ; marco de ladrillo limpio
	call L_7D27		;4239   ; la cabecera del duelo: cuantas partidas quedan
	ld de,04275h		;423c   ; READY
	call pinta_guion		;423f
L_4242:
	ld a,(0e012h)		;4242   ; y no sigue hasta que acaba su musica
	or a			;4245
	jr nz,L_4242		;4246
	jr L_426D		;4248
L_424A:
	ld a,(0e111h)		;424a   ; con un jugador, solo en la primera fase de cada nivel (01, 11, 21, 31 y 41)...
	and 00fh		;424d
	dec a			;424f
	ld a,001h		;4250
	jr nz,L_426F		;4252
	call L_7E5A		;4254   ; ...el rotulo: LEVEL n y STAGE nn
	ld de,0427dh		;4257
	call pinta_guion		;425a
	call pinta_el_numero_de_nivel		;425d
	ld de,04788h		;4260   ; STAGE, y el numero de fase dos casillas mas alla
	call pinta_guion		;4263
	inc l			;4266
	call pinta_la_fase_en_hl		;4267
	call gancho_vacio		;426a
L_426D:
	ld a,001h		;426d
L_426F:
	ld (0e004h),a		;426f
	jp paso_siguiente		;4272

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
	ld hl,03913h		;4285
	ld a,(0e103h)		;4288
	inc a			;428b
	add a,010h		;428c   ; los digitos son las casillas 0x10 a 0x19
	jp 0004dh		;428e   ; BIOS WRTVRM - Writes data in VRAM

; ----------------------------------------------------------------------
; ESCENA 5: LA PARTIDA. Cada cuadro hace el paso que toque (0x6782) y luego mira si la fase se ha acabado o si Q*bert ha caido: si queda tiempo y vidas, lo vuelve a poner arriba; si no, a la escena 6.
; ----------------------------------------------------------------------
escena_partida:
	call L_6782		;4291   ; el paso de la partida
	ld a,(0e002h)		;4294
	bit 5,a		;4297
	call nz,L_81CC		;4299   ; en el duelo, el Q*bert que cae vuelve a salir
	ld a,(0e00dh)		;429c   ; (0xE00D): fase acabada, a la escena 8
	and a			;429f
	ld a,008h		;42a0
	jp nz,pon_escena_a		;42a2
	ld a,(0e113h)		;42a5   ; (0xE113) puesto: Q*bert sigue en juego
	or a			;42a8
	ret nz			;42a9
	ld a,(0ec51h)		;42aa   ; (0xEC51): el tiempo que queda, en BCD
	or a			;42ad
	jr z,vuelve_a_poner_a_qbert		;42ae
	ld a,(0e202h)		;42b0   ; con tiempo, espera a que acabe de caer: estados 4, 12 y 13 de 0xE202
	cp 004h		;42b3
	ret z			;42b5
	cp 00ch		;42b6
	ret z			;42b8
	cp 00dh		;42b9
	ret z			;42bb
vuelve_a_poner_a_qbert:
	ld a,001h		;42bc   ; Q*bert otra vez en juego, los dos
	ld (0e113h),a		;42be
	ld (0e35ch),a		;42c1
	call L_9069		;42c4   ; fuera el objeto de la vida extra
	ld hl,042f7h		;42c7   ; los dos sprites de Q*bert, arriba del todo y cayendo
	ld de,0e200h		;42ca
	ld bc,00010h		;42cd
	ldir		;42d0
	xor a			;42d2   ; sin bola verde, sin congelar y sin bichos parados
	ld (0e321h),a		;42d3
	ld (0e322h),a		;42d6
	ld (0e345h),a		;42d9
	ld a,(0ec51h)		;42dc   ; sin tiempo: a la escena 6, TIME OVER
	or a			;42df
	jp z,escena_siguiente		;42e0
	ld hl,0e110h		;42e3   ; sin vidas: a la escena 6, GAME OVER
	ld a,(hl)			;42e6
	or a			;42e7
	jr z,L_42F4		;42e8
	sub 001h		;42ea   ; una vida menos...
	daa			;42ec
	ld (hl),a			;42ed
	call pinta_las_vidas		;42ee   ; ...se pinta...
	jp L_7817		;42f1   ; ...y el tiempo vuelve a 99
L_42F4:
	jp z,escena_siguiente		;42f4

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
	call L_7D0B		;4309   ; en el duelo, el marcador de partidas parpadea
	ld a,(0e012h)		;430c
	or a			;430f
	ret nz			;4310
	ld a,(0e110h)		;4311   ; con vidas, 256 cuadros y al paso 2
	or a			;4314
	jp nz,espera_a_y_sigue		;4315
	ld a,(0e002h)		;4318   ; sin vidas: la musica del GAME OVER, 0x53 (0x50 en el duelo)...
	bit 5,a		;431b
	ld a,053h		;431d
	jr z,L_4323		;431f
	ld a,050h		;4321
L_4323:
	call toca_sonido		;4323
	ld hl,00107h		;4326   ; ...escena 7, paso 1...
	ld (0e000h),hl		;4329
	ld de,07e8eh		;432c   ; ...y el rotulo GAME OVER / CONTINUE--F5
	jp pinta_guion		;432f
L_4332:
	djnz L_4351		;4332   ; paso 2
vuelve_a_la_fase:		; Escena 4, paso 0, con 128 cuadros de espera: se repite la fase
	ld hl,00004h		;4334
	ld (0e000h),hl		;4337
	ld a,080h		;433a
	ld (0e004h),a		;433c
	ret			;433f
musica_de_game_over:
	ld a,(0e002h)		;4340
	bit 5,a		;4343
	ld a,053h		;4345
	jr z,L_434B		;4347
	ld a,050h		;4349
L_434B:
	call toca_sonido		;434b
	jp escena_siguiente		;434e
L_4351:
	ld a,(0ec51h)		;4351   ; paso 0: si queda tiempo, es que no quedan vidas
	or a			;4354
	jr nz,musica_de_game_over		;4355
	ld a,001h		;4357   ; TIME OVER: la pantalla del marcador
	ld (0e324h),a		;4359
	call L_7C29		;435c
	ld de,0436ah		;435f
	call pinta_guion		;4362
	ld a,080h		;4365
	jp espera_a_y_sigue		;4367

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
	ld a,(0e002h)		;4379
	bit 5,a		;437c
	jr nz,L_4389		;437e
	ld a,007h		;4380   ; fila 7 del teclado: el bit 1 es F5, a cero si esta pulsada
	call 00141h		;4382   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	bit 1,a		;4385
	jr z,continua_la_partida		;4387
L_4389:
	call L_7D0B		;4389
	ld a,(0e012h)		;438c
	or a			;438f
	ret nz			;4390
	ld a,03ch		;4391
	jp espera_a_y_sigue		;4393
continua_la_partida:
	ld hl,0e10bh		;4396   ; CONTINUE: la puntuacion a cero...
	ld de,0e10ch		;4399
	ld bc,00002h		;439c
	ld (hl),000h		;439f
	ldir		;43a1
	ld hl,0e110h		;43a3   ; ...tres vidas...
	ld (hl),003h		;43a6
	inc hl			;43a8
	inc hl			;43a9
	ld (hl),001h		;43aa   ; ...y el umbral de la vida extra otra vez en 10.000
	jp vuelve_a_la_fase		;43ac
L_43AF:
	djnz L_43C0		;43af   ; paso 2: se acaba la espera...
	ld hl,0e004h		;43b1
	dec (hl)			;43b4
	ret nz			;43b5
	ld hl,0e002h		;43b6   ; ...se quita el bit de partida...
	ld a,(hl)			;43b9
	and 0bfh		;43ba
	ld (hl),a			;43bc
	jp vuelve_al_logotipo		;43bd   ; ...y al logotipo
L_43C0:
	ld a,001h		;43c0   ; paso 0: la pantalla del marcador
	ld (0e324h),a		;43c2
	call L_7C29		;43c5
	jp paso_siguiente		;43c8

; ----------------------------------------------------------------------
; ESCENA 8: FASE ACABADA. El paso 0 devuelve la vida que se desconto al empezar, sube la fase (de la 50 vuelve a la 1) y monta la siguiente; tras la 3, la 6 y la 10 de cada decena, la fase de bonificacion.
; ----------------------------------------------------------------------
escena_fase_acabada:
	djnz L_43E6		;43cb   ; paso 1: espera y a la escena 4
	call L_7D0B		;43cd
	ld hl,0e004h		;43d0
	dec (hl)			;43d3
	ret nz			;43d4
	ld (hl),001h		;43d5
	ld a,(0e002h)		;43d7
	bit 5,a		;43da
	jr nz,L_43E3		;43dc
	ld a,(0e012h)		;43de
	or a			;43e1
	ret nz			;43e2
L_43E3:
	jp vuelve_a_la_fase		;43e3
L_43E6:
	xor a			;43e6   ; paso 0
	ld (0e00dh),a		;43e7
	ld a,(0e002h)		;43ea
	bit 5,a		;43ed
	jr nz,L_440A		;43ef   ; con un jugador...
	call L_79AE		;43f1   ; ...quiza la fase de bonificacion, que no vuelve de aqui
	ld hl,0e110h		;43f4   ; la vida que se desconto al empezar
	ld a,(hl)			;43f7
	add a,001h		;43f8
	daa			;43fa
	ld (hl),a			;43fb
	inc hl			;43fc   ; la fase siguiente, en BCD
	ld a,(hl)			;43fd
	add a,001h		;43fe
	daa			;4400
	ld (hl),a			;4401
	cp 051h		;4402   ; despues de la 50, la 1
	jr c,L_440F		;4404
	ld (hl),001h		;4406
	jr L_440F		;4408
L_440A:
	ld a,059h		;440a   ; en el duelo, silencio
	call toca_sonido		;440c
L_440F:
	call carga_el_tablero_siguiente		;440f   ; el tablero de la fase nueva
	xor a			;4412
	ld (0e324h),a		;4413
	call L_7C29		;4416
	ld a,080h		;4419
	jp espera_a_y_sigue		;441b

; ----------------------------------------------------------------------
; LO QUE MIRA LA VUELTA DE LAS ESCENAS SIN PARTIDA. Cualquier tecla en el logotipo o la demostracion salta al titulo; en el titulo, las direcciones cambian 1PLAYER/2PLAYERS y el disparo empieza.
; ----------------------------------------------------------------------
mira_si_empiezan:
	call lee_el_puerto_1		;441e   ; el mando 1 y el teclado...
	call lee_cursores_espacio_y_select		;4421
	ld hl,0e101h		;4424   ; ...y lo que ACABA de pulsarse, en (0xE100)
	call guarda_mando_en_hl		;4427
	or a			;442a
	ret z			;442b
	ld hl,0e004h		;442c   ; la espera a cero, y HL=0xE000
	ld (hl),000h		;442f
	ld l,(hl)			;4431
	ld de,0e102h		;4432
	ld b,(hl)			;4435   ; fuera de la escena 1, al titulo
	djnz salta_al_titulo		;4436
	inc hl			;4438
	ld b,a			;4439
	ld a,(hl)			;443a
	dec hl			;443b
	cp 009h		;443c   ; en la escena 1, antes del paso 9 tambien
	ld a,b			;443e
	jr c,salta_al_titulo		;443f
	and 030h		;4441   ; bits 4 y 5: el disparo (o el espacio)
	jr z,cambia_uno_o_dos_jugadores		;4443
	ld a,(de)			;4445   ; (0xE102): uno o dos jugadores
	or a			;4446
	ld a,040h		;4447   ; 0x40: partida; 0x60: partida de dos
	jr z,L_444D		;4449
	ld a,060h		;444b
L_444D:
	ld (0e002h),a		;444d
	ld (hl),003h		;4450   ; escena 3, paso 0: el menu de nivel
	inc hl			;4452
	ld c,000h		;4453
	ld (hl),c			;4455
	dec c			;4456
	call pinta_la_mano		;4457   ; las dos lineas con la mano en la buena
	jp partida_nueva		;445a
salta_al_titulo:
	ld (hl),001h		;445d   ; escena 1, paso 10
	inc hl			;445f
	ld (hl),00ah		;4460
	ld a,059h		;4462   ; silencio
	call toca_sonido		;4464
	jp pinta_el_titulo		;4467
cambia_uno_o_dos_jugadores:
	ld a,(de)			;446a
	xor 001h		;446b
	ld (de),a			;446d
	ld a,003h		;446e   ; sonido 3, el del cursor
	call toca_sonido		;4470
	ret			;4473
gancho_vacio:		; Un `ret` solo; 0x426A lo llama detras del rotulo de STAGE
	ret			;4474
partida_nueva:		; Borra de 0xE108 a 0xE4FF y pone tres vidas, fase 1 y el umbral de la vida extra
	ld hl,0e108h		;4475
	ld bc,003f7h		;4478
	ld d,h			;447b
	ld e,l			;447c
	inc e			;447d
	ld (hl),000h		;447e
	ldir		;4480
	ld a,(0e114h)		;4482   ; (0xE114) acaba de borrarla el `ldir`: este salto no se toma nunca
	or a			;4485
	jr nz,fase_del_game_master_muerta		;4486
L_4488:
	ld hl,044b8h		;4488   ; los tres bytes de 0x44B8 a 0xE110
	ld de,0e110h		;448b
	ld bc,00003h		;448e
	ldir		;4491
	ld a,(0e002h)		;4493   ; con dos jugadores, lo mismo en la copia del segundo
	and 020h		;4496
	ret z			;4498
copia_al_segundo_jugador:
	ld hl,0e110h		;4499
	ld de,0e120h		;449c
	ld bc,00010h		;449f
	ldir		;44a2
	ret			;44a4
fase_del_game_master_muerta:
	call bcd_de_a		;44a5   ; CODIGO MUERTO: solo se llega si (0xE114) no es cero justo despues de borrarla. Y si llegara, el `jr` de 0x44B6 no sale nunca
	cp 050h		;44a8
	jr c,L_44AE		;44aa
	ld a,050h		;44ac
L_44AE:
	ld (0e111h),a		;44ae
	ld a,001h		;44b1
	ld (0e112h),a		;44b3
	jr fase_del_game_master_muerta		;44b6

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
	ld hl,0e114h		;44bb
	ld a,(hl)			;44be
	or a			;44bf
	ret z			;44c0
	ld (hl),000h		;44c1
	call bcd_de_a		;44c3
	cp 050h		;44c6
	jr c,L_44CC		;44c8
	ld a,050h		;44ca
L_44CC:
	ld (0e111h),a		;44cc
	ld a,(0e002h)		;44cf
	and 020h		;44d2
	ret z			;44d4
	jp copia_al_segundo_jugador		;44d5
esconde_los_sprites:		; Y=0xD0 en el primer sprite: el VDP no pinta ni ese ni los de detras
	ld hl,03b00h		;44d8
	ld a,0d0h		;44db
	call 0004dh		;44dd   ; BIOS WRTVRM - Writes data in VRAM
	xor a			;44e0
	ret			;44e1

; ----------------------------------------------------------------------
; SUMA PUNTOS. DE en BCD se suma a la puntuacion de 0xE10B (E a las unidades y decenas, D a las centenas y millares): 0x0010 son 10 puntos y 0x5000 son 5.000. Ni en la demostracion ni en el duelo. Cada vez que el byte alto llega al umbral de (0xE112), una vida mas y el umbral sube 5: vidas a los 10.000, 60.000, 110.000...
; ----------------------------------------------------------------------
suma_puntos:
	ld c,000h		;44e2
	ld a,(0e002h)		;44e4   ; sin partida (demostracion), nada
	or a			;44e7
	ret z			;44e8
	bit 5,a		;44e9   ; en el duelo, tampoco
	ret nz			;44eb
	ld hl,0e10bh		;44ec
	ld a,(hl)			;44ef
	add a,e			;44f0
	daa			;44f1
	ld (hl),a			;44f2
	inc l			;44f3
	ld a,(hl)			;44f4
	adc a,d			;44f5
	daa			;44f6
	ld (hl),a			;44f7
	inc hl			;44f8
	ld a,(hl)			;44f9
	adc a,c			;44fa
	daa			;44fb
	ld (hl),a			;44fc
	jr nc,mira_la_vida_extra		;44fd   ; se ha pasado de 999999
	ld bc,09999h		;44ff   ; el record se queda en 999999
	ld (0e105h),bc		;4502
	ld (0e106h),bc		;4506
	jp pinta_la_puntuacion		;450a
mira_la_vida_extra:
	ex de,hl			;450d
	ld hl,0e112h		;450e
	cp (hl)			;4511   ; el byte alto contra el umbral
	jr c,mira_el_record		;4512
	ld a,(hl)			;4514   ; umbral + 5, en BCD; si se sale, 0xFF y no hay mas
	add a,005h		;4515
	daa			;4517
	jr nc,L_451C		;4518
	ld a,0ffh		;451a
L_451C:
	ld (hl),a			;451c
	push de			;451d
	ld hl,0e110h		;451e   ; y la vida
	ld a,(hl)			;4521
	add a,001h		;4522
	daa			;4524
	ld (hl),a			;4525
	ld a,011h		;4526   ; sonido 0x11, el de la vida extra
	call toca_sonido_en_partida		;4528
	call pinta_las_vidas		;452b
	pop de			;452e
mira_el_record:
	ld b,003h		;452f   ; compara la puntuacion con el record de mas a menos significativo
	ld hl,0e107h		;4531
	ex de,hl			;4534
	ld c,l			;4535
L_4536:
	ld a,(de)			;4536
	sub (hl)			;4537
	jr c,L_4541		;4538
	jp nz,pinta_la_puntuacion		;453a
	dec l			;453d
	dec e			;453e
	djnz L_4536		;453f
L_4541:
	ld l,c			;4541   ; la supera: se copia encima
	ld bc,00003h		;4542
	ld e,007h		;4545
	lddr		;4547
	jp pinta_la_puntuacion		;4549

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
	ld de,07eb0h		;454d
	call pinta_guion		;4550
	ld a,(0e002h)		;4553
	bit 5,a		;4556
	jr z,L_455E		;4558
	cpl			;455a
	call pinta_la_puntuacion_en_hl		;455b
L_455E:
	call pinta_las_vidas_del_game_over		;455e
	call pinta_la_fase_del_game_over		;4561
	jp pinta_record_y_puntuacion		;4564
pinta_el_marcador:		; La linea de arriba: STAGE-nn SCORE-nnnnnn P-nn
	ld de,04607h		;4567
	call pinta_guion		;456a
	call pinta_la_fase		;456d   ; la fase
	call pinta_la_puntuacion		;4570   ; la puntuacion
	jr $+101		;4573   ; y las vidas, en 0x45D8
pinta_el_marcador_del_duelo:		; 2P- y 1P- con las vidas de cada uno
	call L_7B36		;4575
	ld de,04591h		;4578
	call pinta_guion		;457b
pinta_las_vidas_de_los_dos:
	ld hl,03805h		;457e
	ld de,0e120h		;4581
	call L_458D		;4584
	ld hl,0381ch		;4587
	ld de,0e110h		;458a
L_458D:
	ld b,001h		;458d
	jr $+83		;458f

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
	ld hl,03972h		;459d
	ld de,0e107h		;45a0
	call pinta_tres_bytes_bcd		;45a3
	ld hl,03932h		;45a6
pinta_la_puntuacion_en_hl:
	ld de,0e10dh		;45a9
pinta_tres_bytes_bcd:
	ld b,003h		;45ac
	jr pinta_bcd		;45ae
pinta_la_puntuacion:		; Seis cifras en 0x3812
	ld hl,03812h		;45b0
	ld de,0e10dh		;45b3
	ld b,003h		;45b6
	jr pinta_bcd		;45b8
pinta_la_fase_del_game_over:
	ld hl,038d2h		;45ba
pinta_la_fase_en_hl:
	ld de,0e111h		;45bd
	ld b,001h		;45c0
	jr pinta_bcd		;45c2
pinta_la_fase:		; Dos cifras en 0x3808
	ld hl,03808h		;45c4
	ld de,0e111h		;45c7
	ld b,001h		;45ca
	jr pinta_bcd		;45cc
pinta_las_vidas_del_game_over:
	ld hl,039d2h		;45ce
	ld de,0e110h		;45d1
	ld b,001h		;45d4
	jr pinta_bcd		;45d6
pinta_las_vidas:		; Dos cifras en 0x381C
	ld hl,0381ch		;45d8
	ld de,0e110h		;45db
	ld b,001h		;45de
	jr pinta_bcd		;45e0

; ----------------------------------------------------------------------
; PINTA B BYTES EN BCD de DE hacia abajo, dos cifras por byte, en la tabla de nombres desde HL. Las cifras son las casillas 0x10 a 0x19.
; ----------------------------------------------------------------------
pinta_bcd:
	ld a,(de)			;45e2   ; la cifra alta...
	rra			;45e3
	rra			;45e4
	rra			;45e5
	rra			;45e6
	and 00fh		;45e7
	add a,010h		;45e9   ; ...a su casilla
	call 0004dh		;45eb   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;45ee
	ld a,(de)			;45ef   ; la baja
	and 00fh		;45f0
	add a,010h		;45f2
	call 0004dh		;45f4   ; BIOS WRTVRM - Writes data in VRAM
	dec de			;45f7   ; el byte de antes: el mas significativo va primero
	inc hl			;45f8
	djnz pinta_bcd		;45f9
	ret			;45fb
vuelta_con_partida:		; El `ret` al que vuelven las escenas durante la partida
	ret			;45fc
intercambia_b_bytes:		; Intercambia B bytes entre (HL) y (DE)
	ld c,(hl)			;45fd   ; CODIGO HUERFANO: nadie lo llama ni apunta aqui
	ld a,(de)			;45fe
	ld (hl),a			;45ff
	ld a,c			;4600
	ld (de),a			;4601
	inc hl			;4602
	inc de			;4603
	djnz intercambia_b_bytes		;4604
	ret			;4606

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
	call esconde_los_sprites		;462a
	ld hl,03800h		;462d
	ld bc,00300h		;4630
	xor a			;4633
	jp 00056h		;4634   ; BIOS FILVRM - Fills VRAM with value | FILVRM
prepara_escritura_de_vram:		; SETWRT en HL y el puerto de datos del VDP (el de 0x0007 de la BIOS) en C' para los `out (c)`
	ex af,af'			;4637
	call 00053h		;4638   ; BIOS SETWRT - Enables VDP to write | SETWRT
	exx			;463b
	ld a,(00007h)		;463c   ; el puerto de escritura del VDP, tal como lo dice la BIOS
	ld c,a			;463f
	exx			;4640
	ex af,af'			;4641
	ret			;4642
prepara_lectura_de_vram:		; La pareja de 0x4637 para leer: SETRD y el puerto de 0x0006
	call 00050h		;4643   ; BIOS SETRD - Enables VDP to read | CODIGO HUERFANO: nadie lo llama; el juego no lee la VRAM por el puerto
	exx			;4646
	ld a,(00006h)		;4647   ; el puerto de lectura del VDP
	ld c,a			;464a
	exx			;464b
	ret			;464c
copia_a_vram:		; BC bytes de (DE) a la VRAM en HL: LDIRVM con los punteros cambiados
	ex de,hl			;464d
	jp 0005ch		;464e   ; BIOS LDIRVM - Block transfers to VRAM from memory
copia_a_los_tres_bancos:		; Lo mismo tres veces, a 0x800 de distancia: los tres tercios de la pantalla
	exx			;4651
	ld b,003h		;4652   ; tres tercios
copia_un_banco:
	exx			;4654
	push bc			;4655
	push de			;4656
	call copia_a_vram		;4657
	ld de,00800h		;465a   ; el tercio siguiente
	add hl,de			;465d
	pop de			;465e
	pop bc			;465f
	exx			;4660
	djnz copia_un_banco		;4661
	ret			;4663
rellena_los_tres_bancos:		; FILVRM de BC bytes con A, en HL, HL+0x800 y HL+0x1000
	ld d,003h		;4664
L_4666:
	push bc			;4666
	push de			;4667
	call 00056h		;4668   ; BIOS FILVRM - Fills VRAM with value | FILVRM
	ld de,00800h		;466b
	add hl,de			;466e
	pop de			;466f
	pop bc			;4670
	dec d			;4671
	jr nz,L_4666		;4672
	ret			;4674
guion_rle_en_tres_bancos:		; El guion RLE de DE, tres veces, desde HL, HL+0x800 y HL+0x1000
	ld b,003h		;4675
L_4677:
	push bc			;4677
	push de			;4678
	call vuelca_el_guion_con_destino_en_hl		;4679
	ld de,00800h		;467c
	add hl,de			;467f
	pop de			;4680
	pop bc			;4681
	djnz L_4677		;4682
	ret			;4684

; ----------------------------------------------------------------------
; EL GUION DE TEXTO. En DE: una direccion de la tabla de nombres y los caracteres detras; 0xFE salta a otra direccion (la que sigue) y 0xFF acaba. Cada caracter se pasa por AND C: con C=0xFF pinta, con C=0 borra el mismo rotulo en su sitio.
; ----------------------------------------------------------------------
pinta_guion:
	ld c,0ffh		;4685   ; C=0xFF: pinta
guion_nueva_direccion:
	ex de,hl			;4687   ; la direccion de destino, los dos primeros bytes
	ld e,(hl)			;4688
	inc hl			;4689
	ld d,(hl)			;468a
	ex de,hl			;468b
	inc de			;468c
byte_del_guion:
	ld a,(de)			;468d
	inc de			;468e
	ld b,a			;468f   ; 0xFF + 1 = 0: fin
	inc b			;4690
	ret z			;4691
	inc b			;4692   ; 0xFE + 2 = 0: otra direccion
	jr z,guion_nueva_direccion		;4693
	and c			;4695   ; AND C: el caracter o un cero
	call 0004dh		;4696   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM
	inc hl			;4699
	jr byte_del_guion		;469a
borra_guion:		; El mismo guion con C=0: pone ceros donde iba el texto
	ld c,000h		;469c
	jr guion_nueva_direccion		;469e

; ----------------------------------------------------------------------
; EL RLE DE LA VRAM. En DE: la direccion de destino y luego ordenes de un byte: 0x00 acaba, 0x01-0x7F repite el byte siguiente ese numero de veces, 0x81-0xFF copia literales (el numero menos 0x80) y 0x80 cambia de direccion con la palabra que sigue.
; ----------------------------------------------------------------------
guion_rle:
	ex de,hl			;46a0   ; la direccion, los dos primeros bytes
	ld e,(hl)			;46a1
	inc hl			;46a2
	ld d,(hl)			;46a3
	ex de,hl			;46a4
	inc de			;46a5
vuelca_el_guion_con_destino_en_hl:
	call prepara_escritura_de_vram		;46a6
orden_del_rle:
	ld a,(de)			;46a9
	and a			;46aa   ; 0x00: fin
	ret z			;46ab
	inc de			;46ac
	ld b,a			;46ad
	and 07fh		;46ae   ; sin el bit 7...
	cp b			;46b0
	jr z,repite_un_byte		;46b1   ; ...es una repeticion
	and a			;46b3   ; 0x80 a secas: direccion nueva
	jr z,guion_rle		;46b4
	ld b,a			;46b6   ; 0x81-0xFF: tantos literales
copia_literales:
	ld a,(de)			;46b7
	inc de			;46b8
	exx			;46b9
	out (c),a		;46ba
	exx			;46bc
	djnz copia_literales		;46bd
	jr orden_del_rle		;46bf
repite_un_byte:
	ld a,(de)			;46c1
	inc de			;46c2
L_46C3:
	exx			;46c3
	out (c),a		;46c4
	exx			;46c6
	djnz L_46C3		;46c7
	jr orden_del_rle		;46c9
apaga_y_borra_la_vram:		; Silencio, toda la VRAM a cero y los registros del VDP de 0x46F0
	ld a,0bfh		;46cb   ; mezclador del PSG: los seis canales cerrados
	call escribe_el_mezclador		;46cd
	ld a,059h		;46d0   ; sonido 0x59: todo en silencio
	call toca_sonido		;46d2
	ld hl,00000h		;46d5   ; los 16 KB de VRAM a cero
	ld bc,04000h		;46d8
	xor a			;46db
	call 00056h		;46dc   ; BIOS FILVRM - Fills VRAM with value
pon_los_registros_del_vdp:
	ld hl,046f0h		;46df
	ld d,008h		;46e2
	ld c,000h		;46e4
L_46E6:
	ld b,(hl)			;46e6   ; WRTVDP, registro C con el valor B
	call 00047h		;46e7   ; BIOS WRTVDP - Writes data in the VDP-register
	inc hl			;46ea
	inc c			;46eb
	dec d			;46ec
	jr nz,L_46E6		;46ed
	ret			;46ef

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
	ld c,007h		;46f8
	jp 00047h		;46fa   ; BIOS WRTVDP - Writes data in the VDP-register

; ----------------------------------------------------------------------
; LOS MANDOS, una vez por cuadro. El mando 2 va con la lectura del puerto 2 y las teclas E, S, F, C y CTRL a 0xE330/0xE32F; el mando 1, con el puerto 1, los cursores, el espacio y SELECT, a 0xE009/0xE008. El segundo byte de cada pareja es lo que ACABA de pulsarse. Los bits: 0 arriba, 1 abajo, 2 izquierda, 3 derecha, 4 y 5 los dos disparos.
; ----------------------------------------------------------------------
lee_los_mandos:
	ld e,0cfh		;46fd   ; puerto 2 del PSG (bit 6 del registro 15 a uno)
	call lee_el_puerto_en_e		;46ff
	call lee_las_teclas_del_segundo		;4702   ; y E-S-F-C-CTRL encima
	ld hl,0e330h		;4705   ; al mando 2
	call guarda_mando_en_hl		;4708
	call lee_el_puerto_1		;470b   ; puerto 1 y los cursores
	call lee_cursores_espacio_y_select		;470e
guarda_el_mando_1:
	ld hl,0e009h		;4711
guarda_mando_en_hl:		; (HL)=lo pulsado y (HL-1)=lo que no lo estaba en la lectura anterior
	ld c,(hl)			;4714
	ld (hl),a			;4715
	xor c			;4716   ; lo de antes, invertido...
	and (hl)			;4717   ; ...y con lo de ahora: lo recien pulsado
	dec hl			;4718
	ld (hl),a			;4719
	ret			;471a
lee_el_puerto_1:
	ld e,08fh		;471b
lee_el_puerto_en_e:		; E al registro 15 del PSG (el puerto) y el 14 leido: los seis bits, a uno lo pulsado
	ld a,00fh		;471d
	call 00093h		;471f   ; BIOS WRTPSG - Writes data to PSG-register | WRTPSG
	ld a,00eh		;4722
	di			;4724
	call 00096h		;4725   ; BIOS RDPSG - Reads value from PSG-register | RDPSG
	ei			;4728
	cpl			;4729   ; los botones van a cero: se invierten
	and 03fh		;472a
	ret			;472c

; ----------------------------------------------------------------------
; LOS CURSORES, EL ESPACIO Y SELECT, colocados en los bits del mando: se leen las filas 8 y 7 del teclado y se reordenan a golpe de `rrca`.
; ----------------------------------------------------------------------
lee_cursores_espacio_y_select:
	push af			;472d
	ld a,007h		;472e   ; fila 7 del teclado
	call 00141h		;4730   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4733
	rrca			;4734   ; el bit 6 (SELECT) al bit 5
	and 020h		;4735
	ld e,a			;4737
	ld a,008h		;4738   ; fila 8: derecha, abajo, arriba, izquierda... y el espacio en el bit 0
	call 00141h		;473a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;473d
	rrca			;473e
	rrca			;473f
	ld b,a			;4740
	and 004h		;4741   ; izquierda al bit 2
	or e			;4743
	ld c,a			;4744
	ld a,b			;4745
	rrca			;4746
	rrca			;4747
	ld b,a			;4748
	and 018h		;4749   ; derecha y espacio a los bits 3 y 4
	or c			;474b
	ld c,a			;474c
	ld a,b			;474d
	rrca			;474e
	and 003h		;474f   ; arriba y abajo a los bits 0 y 1
	or c			;4751
	pop bc			;4752   ; y encima de lo que leyo el puerto
	or b			;4753
	ret			;4754

; ----------------------------------------------------------------------
; LAS TECLAS DEL SEGUNDO JUGADOR: E arriba, C abajo, S izquierda y F derecha (un rombo, como las cuatro diagonales del juego), y CTRL de disparo.
; ----------------------------------------------------------------------
lee_las_teclas_del_segundo:
	push af			;4755
	ld b,000h		;4756
	ld a,003h		;4758
	call 00141h		;475a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 3 del teclado
	bit 0,a		;475d   ; bit 0: la C, abajo
	jr nz,L_4763		;475f
	set 1,b		;4761
L_4763:
	bit 2,a		;4763   ; bit 2: la E, arriba
	jr nz,L_4769		;4765
	set 0,b		;4767
L_4769:
	bit 3,a		;4769   ; bit 3: la F, derecha
	jr nz,L_476F		;476b
	set 3,b		;476d
L_476F:
	ld a,005h		;476f
	call 00141h		;4771   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 5, bit 0: la S, izquierda
	bit 0,a		;4774
	jr nz,L_477A		;4776
	set 2,b		;4778
L_477A:
	ld a,006h		;477a
	call 00141h		;477c   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix | fila 6, bit 1: CTRL, el disparo
	bit 1,a		;477f
	jr nz,L_4785		;4781
	set 4,b		;4783
L_4785:
	pop af			;4785
	or b			;4786
	ret			;4787

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
	call limpia_la_fuente		;47b7
	ld de,047efh		;47ba
	ld hl,02080h		;47bd   ; tile 0x10, el cero
	call guion_rle_en_tres_bancos		;47c0
	ld a,0f0h		;47c3   ; blanco sobre transparente...
	ld hl,00080h		;47c5   ; ...para los tiles 0x10 a 0x3A
	ld bc,00158h		;47c8
	jp rellena_los_tres_bancos		;47cb
limpia_la_fuente:		; Los 16 primeros tiles a cero y su color a 0x00-0x0F: el tile N queda como un bloque de color N
	ld hl,02000h		;47ce
	ld bc,00080h		;47d1
	xor a			;47d4
	call rellena_los_tres_bancos		;47d5   ; patrones de los tiles 0 a 15, a cero
	ld hl,00000h		;47d8
	ld de,00008h		;47db
	ld b,010h		;47de   ; el color de cada uno es 0x0N: con el patron a cero, el tile N es un bloque macizo de color N
L_47E0:
	push bc			;47e0
	ld bc,00008h		;47e1
	push hl			;47e4
	call rellena_los_tres_bancos		;47e5
	pop hl			;47e8
	add hl,de			;47e9
	inc a			;47ea
	pop bc			;47eb
	djnz L_47E0		;47ec
	ret			;47ee

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
	ld (0e00eh),hl		;4923
	ld de,04982h		;4926   ; los patrones, con su direccion dentro del guion
	call guion_rle		;4929
	ld hl,00a00h		;492c   ; los colores del logotipo, a cero: aun no se ve
	ld bc,003f0h		;492f
	xor a			;4932
	call 00056h		;4933   ; BIOS FILVRM - Fills VRAM with value
	ld hl,03907h		;4936   ; fila 8, columna 7
	ld a,040h		;4939   ; tiles 0x40 en adelante, 21 por fila
	ld c,006h		;493b
	ld de,0000bh		;493d
L_4940:
	ld b,015h		;4940
L_4942:
	call 0004dh		;4942   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;4945
	inc a			;4946
	djnz L_4942		;4947
	add hl,de			;4949   ; 32 - 21 = 11 para bajar de fila
	dec c			;494a
	jr nz,L_4940		;494b
	ret			;494d

; ----------------------------------------------------------------------
; DESTAPA EL LOGOTIPO: una linea de pixeles cada vez. (0xE00E) es la linea dentro del tile y (0xE00F) la fila de tiles; pone 0xF0 en esa linea de los 21 tiles de la fila. Devuelve Z al acabar la sexta fila.
; ----------------------------------------------------------------------
destapa_una_linea_del_logotipo:
	ld bc,(0e00eh)		;494e
	ld a,0ebh		;4952   ; 0xEB + 21 por fila: A acaba en 21*fila (la primera vuelta da 0x100)
	inc b			;4954
L_4955:
	add a,015h		;4955
	djnz L_4955		;4957
	ld l,a			;4959
	ld h,b			;495a
	add hl,hl			;495b   ; por 8: el tile en la tabla de color
	add hl,hl			;495c
	add hl,hl			;495d
	ld de,00a00h		;495e   ; el segundo tercio del color
	add hl,de			;4961
	ld a,c			;4962   ; y la linea dentro del tile
	call suma_a_a_hl		;4963
	ld b,015h		;4966
	ld de,00008h		;4968
	ld a,0f0h		;496b   ; blanco sobre transparente
L_496D:
	call 0004dh		;496d   ; BIOS WRTVRM - Writes data in VRAM
	add hl,de			;4970
	djnz L_496D		;4971
	ld hl,0e00eh		;4973   ; la linea siguiente...
	ld a,(hl)			;4976
	inc a			;4977
	and 007h		;4978
	ld (hl),a			;497a
	ret nz			;497b
	inc hl			;497c   ; ...y tras la octava, la fila siguiente
	inc (hl)			;497d
	ld a,(hl)			;497e
	cp 006h		;497f   ; Z en la sexta
	ret			;4981

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
	call pon_el_fondo		;4ae6
	ret			;4ae9

; ----------------------------------------------------------------------
; EL TITULO: el rotulo de Q*bert en su marco, Q*bert en la recreativa, (c)KONAMI 1986 y el menu de uno o dos jugadores. Si la presentacion ya lo ha dibujado (0xE115), solo pone los textos.
; ----------------------------------------------------------------------
pinta_el_titulo:
	call fondo_negro		;4aea
	ld hl,0e115h		;4aed
	ld a,(hl)			;4af0
	or a			;4af1
	ld (hl),000h		;4af2
	jr nz,pinta_los_textos_del_titulo		;4af4
	call borra_la_pantalla		;4af6   ; desde cero: pantalla, fuente...
	call monta_la_fuente		;4af9
	call L_8394		;4afc   ; ...la de la recreativa...
	ld hl,0ed45h		;4aff   ; ...el rotulo en su marco, en la fila 2, columna 5...
	call pinta_el_rotulo_de_qbert		;4b02
	call L_8547		;4b05   ; ...Q*bert y la pantalla de la recreativa...
	ld a,008h		;4b08   ; ...el color del ultimo sprite...
	ld (0e22bh),a		;4b0a
	call vuelca_la_pantalla		;4b0d   ; ...la copia de la tabla de nombres a la VRAM...
	call L_8735		;4b10   ; ...y los sprites
pinta_los_textos_del_titulo:
	ld de,04790h		;4b13   ; (c)KONAMI 1986 y 1PLAYER...
	call pinta_guion		;4b16
	jp pinta_guion		;4b19   ; ...y 2PLAYERS, que viene detras
parpadea_el_cursor:		; La mano aparece y desaparece cada 8 cuadros
	ld hl,0e004h		;4b1c
	bit 3,(hl)		;4b1f
	ld c,0ffh		;4b21
	jr nz,pinta_la_mano		;4b23
	inc c			;4b25
pinta_la_mano:		; La mano con C en la opcion de (0xE102) y borrada en la otra
	ld hl,0396ah		;4b26   ; las dos lineas del menu
	ld de,0398ah		;4b29
	ld a,(0e102h)		;4b2c
	or a			;4b2f
	jr z,L_4B33		;4b30
	ex de,hl			;4b32
L_4B33:
	push de			;4b33
	call pinta_la_mano_en_hl		;4b34
	pop hl			;4b37
	ld c,000h		;4b38
pinta_la_mano_en_hl:
	ld de,047b4h		;4b3a
	jp byte_del_guion		;4b3d
pinta_el_rotulo_de_qbert:		; Las ocho filas de 0x4B95 en la copia de la tabla de nombres, desde HL
	ld c,0ffh		;4b40
	ld de,04b95h		;4b42
	call L_8724		;4b45
	ld a,009h		;4b48   ; 23 casillas y 9 de salto: filas de 32
	call suma_a_a_hl		;4b4a
	ld de,04badh		;4b4d
	call L_8724		;4b50
	ld a,009h		;4b53
	call suma_a_a_hl		;4b55
	ld de,04bc5h		;4b58
	call L_8724		;4b5b
	ld a,009h		;4b5e
	call suma_a_a_hl		;4b60
	ld de,04bddh		;4b63
	call L_8724		;4b66
	ld a,009h		;4b69
	call suma_a_a_hl		;4b6b
	ld de,04bf5h		;4b6e
	call L_8724		;4b71
	ld a,009h		;4b74
	call suma_a_a_hl		;4b76
	ld de,04c0dh		;4b79
	call L_8724		;4b7c
	ld a,009h		;4b7f
	call suma_a_a_hl		;4b81
	ld de,04c25h		;4b84
	call L_8724		;4b87
	ld a,00eh		;4b8a   ; la ultima fila, el pie del marco, va 5 casillas mas a la derecha
	call suma_a_a_hl		;4b8c
	ld de,04c3dh		;4b8f
	jp L_8724		;4b92

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
	di			;4c41
	push hl			;4c42
	ld hl,0e002h		;4c43
	bit 6,(hl)		;4c46
	jr z,L_4C57		;4c48
	jr L_4C4E		;4c4a
toca_sonido:		; A: el numero de sonido. Guarda todos los registros
	di			;4c4c
	push hl			;4c4d
L_4C4E:
	push de			;4c4e
	push bc			;4c4f
	push af			;4c50
	call arranca_el_sonido		;4c51
	pop af			;4c54
	pop bc			;4c55
	pop de			;4c56
L_4C57:
	pop hl			;4c57
	ei			;4c58
	ret			;4c59
arranca_el_sonido:
	cp 056h		;4c5a   ; el 0x56 es el de la pausa: antes se guardan los cuatro canales en 0xE090
	jr nz,L_4C68		;4c5c
	ld hl,0e010h		;4c5e
	ld de,0e090h		;4c61
	call copia_los_canales		;4c64
	ld a,c			;4c67
L_4C68:
	ld c,a			;4c68
	ld hl,0e012h		;4c69   ; de 0x01 a 0x16: un efecto, un canal (el cuarto)
	ld b,001h		;4c6c
	ld a,c			;4c6e
	cp 017h		;4c6f
	jr c,arranca_un_efecto		;4c71
	cp 056h		;4c73   ; de 0x17 en adelante, musica: tres canales
	jr nz,L_4C78		;4c75
	inc b			;4c77   ; y el 0x56, los cuatro
L_4C78:
	inc b			;4c78
	inc b			;4c79
	cp 02ch		;4c7a   ; una musica calla el efecto que sonara, salvo la 0x2C
	jr z,L_4C82		;4c7c
	xor a			;4c7e
	ld (0e072h),a		;4c7f
L_4C82:
	jr arranca_b_canales		;4c82
arranca_un_efecto:
	ld l,072h		;4c84   ; HL=0xE072: el sonido del canal de efectos
	ld a,(0e052h)		;4c86   ; con la musica 0x2C o posteriores en el tercer canal, los efectos no suenan
	cp 02ch		;4c89
	ret nc			;4c8b
	ld a,(hl)			;4c8c   ; y un efecto solo corta a otro de numero menor o igual
	ld e,a			;4c8d
	ld a,c			;4c8e
	cp e			;4c8f
	ret c			;4c90
arranca_b_canales:
	ld a,c			;4c91
	ld de,052e2h		;4c92   ; la tabla de 0x52E2: una entrada por canal, y una musica usa tres seguidas
	add a,a			;4c95
	jr nc,L_4C99		;4c96
	inc d			;4c98
L_4C99:
	add a,e			;4c99
	ld e,a			;4c9a
	jr nc,L_4C9E		;4c9b
	inc d			;4c9d
L_4C9E:
	dec l			;4c9e
	dec l			;4c9f
prepara_un_canal:
	ld (hl),001h		;4ca0   ; +0: la primera nota sale ya
	inc l			;4ca2
	inc l			;4ca3
	ld (hl),c			;4ca4   ; +2: el sonido
	inc l			;4ca5
	ld a,(de)			;4ca6   ; +3/+4: sus datos
	ld (hl),a			;4ca7
	inc l			;4ca8
	inc de			;4ca9
	ld a,(de)			;4caa
	ld (hl),a			;4cab
	ld a,007h		;4cac
	add a,l			;4cae
	ld l,a			;4caf
	xor a			;4cb0
	ld (hl),a			;4cb1   ; +0B: sin bucle
	ld a,003h		;4cb2
	add a,l			;4cb4
	ld l,a			;4cb5
	ld a,001h		;4cb6
	ld (hl),a			;4cb8   ; +0E: modo musica
	inc l			;4cb9
	dec a			;4cba
	ld (hl),a			;4cbb
	inc l			;4cbc
	ld (hl),a			;4cbd   ; +0F y +10: afinado y sin instrumento
	ld a,009h		;4cbe
	add a,l			;4cc0
	ld l,a			;4cc1
	ld (hl),000h		;4cc2   ; +19: sin subrutina
	ld a,007h		;4cc4
	add a,l			;4cc6
	ld l,a			;4cc7
	inc de			;4cc8
	djnz prepara_un_canal		;4cc9
	ret			;4ccb

; ----------------------------------------------------------------------
; EL SONIDO DE CADA CUADRO. Primero el mezclador; si hay que volver de la pausa, se restauran los canales de 0xE090; y luego los cuatro canales, uno detras de otro, con C en el registro de periodo de cada uno (1, 3, 5 y 7).
; ----------------------------------------------------------------------
suena_un_cuadro:
	ld a,(0e0f0h)		;4ccc   ; el mezclador tal como quedo
	call escribe_el_mezclador		;4ccf
	exx			;4cd2
	ld b,004h		;4cd3   ; cuatro canales de 0x20 bytes
	ld de,00020h		;4cd5
	exx			;4cd8
	xor a			;4cd9   ; (0xE0F3): se estan rehaciendo los registros tras la pausa
	ld (0e0f3h),a		;4cda
	ld c,001h		;4cdd
	ld ix,0e010h		;4cdf
	ld a,(0e0f1h)		;4ce3   ; (0xE0F1): acaba la pausa
	or a			;4ce6
	jr z,L_4CF8		;4ce7
	ld a,c			;4ce9
	ld hl,0e090h		;4cea   ; los canales guardados vuelven a su sitio
	ld de,0e010h		;4ced
	call copia_los_canales		;4cf0
	ld a,001h		;4cf3
	ld (0e0f3h),a		;4cf5
L_4CF8:
	exx			;4cf8
un_canal:
	exx			;4cf9
	ld a,(ix+002h)		;4cfa   ; +2 a cero: canal libre
	or a			;4cfd
	push af			;4cfe
	call nz,avanza_el_canal		;4cff
	pop af			;4d02
	jr nz,L_4D0B		;4d03
	ld a,c			;4d05   ; libre y no es el de efectos: se deja en silencio
	cp 007h		;4d06
	call nz,fin_del_canal		;4d08
L_4D0B:
	inc c			;4d0b
	inc c			;4d0c
	exx			;4d0d
	add ix,de		;4d0e
	djnz un_canal		;4d10
	ret			;4d12
avanza_el_canal:
	ld a,(0e0f3h)		;4d13   ; tras la pausa, primero el periodo y el volumen que tenia
	or a			;4d16
	push af			;4d17
	call nz,pon_el_periodo		;4d18
	pop af			;4d1b
	call nz,pon_el_volumen		;4d1c
	ld a,(ix+00eh)		;4d1f   ; modo musica
	or a			;4d22
	jp nz,decae_la_nota		;4d23
	ld (ix+010h),a		;4d26   ; modo efecto: sin instrumento
	dec (ix+000h)		;4d29   ; cuando se acaba la nota...
	ret nz			;4d2c
lee_la_siguiente_orden:
	ld l,(ix+003h)		;4d2d
	ld h,(ix+004h)		;4d30
	ld a,(hl)			;4d33   ; 0xFE: bucle, subrutina o cambio de modo
	cp 0feh		;4d34
	jp z,orden_fe		;4d36
	jp nc,fin_del_canal		;4d39   ; 0xFF: fin (o vuelta de la subrutina)
L_4D3C:
	ld a,(ix+00eh)		;4d3c
	or a			;4d3f
	ld a,(hl)			;4d40
	jp nz,orden_de_musica		;4d41
orden_de_efecto:
	and 0f0h		;4d44   ; 0x2X: el tipo del sonido
	cp 020h		;4d46
	jr nz,L_4D7D		;4d48
	ld a,(hl)			;4d4a
	ld (ix+005h),a		;4d4b
	inc hl			;4d4e   ; y su duracion
	ld a,(ix+010h)		;4d4f
	or a			;4d52
	ld a,(hl)			;4d53
	jr nz,L_4D59		;4d54
	ld (ix+001h),a		;4d56
L_4D59:
	ld (ix+014h),a		;4d59
	inc hl			;4d5c
	ld a,(ix+005h)		;4d5d   ; 0x20 a secas: un silencio
	cp 020h		;4d60
	jr nz,L_4D69		;4d62
	dec hl			;4d64
	xor a			;4d65
	ld b,a			;4d66
	jr L_4D97		;4d67
L_4D69:
	bit 3,a		;4d69   ; bit 3: la envolvente del PSG...
	jr z,L_4D7D		;4d6b
	ld a,(hl)			;4d6d   ; ...con su periodo en los registros 12 y 11
	ld e,a			;4d6e
	ld a,00ch		;4d6f
	call 00093h		;4d71   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4d74
	ld a,(hl)			;4d75
	ld e,a			;4d76
	ld a,00bh		;4d77
	call 00093h		;4d79   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4d7c
L_4D7D:
	ld a,(hl)			;4d7d   ; 0x1X: el periodo del ruido, X por dos, al registro 6
	and 0f0h		;4d7e
	cp 010h		;4d80
	jr nz,nota_de_efecto		;4d82
	ld a,(hl)			;4d84
	and 00fh		;4d85
	add a,a			;4d87
	ld e,a			;4d88
	ld a,006h		;4d89
	call 00093h		;4d8b   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;4d8e
nota_de_efecto:
	ld a,(hl)			;4d8f   ; el nibble alto es el volumen; el bajo y el byte siguiente, el periodo de 12 bits tal cual
	and 0f0h		;4d90
	ld b,a			;4d92
	xor (hl)			;4d93
	ld d,a			;4d94
	inc hl			;4d95
	ld e,(hl)			;4d96
L_4D97:
	ld a,(ix+010h)		;4d97
	or a			;4d9a
	jp nz,siguiente_paso_del_instrumento		;4d9b
	call guarda_el_puntero		;4d9e
guarda_el_periodo:
	ex de,hl			;4da1
	ld (ix+015h),l		;4da2
	ld (ix+016h),h		;4da5
	ld a,(0e0f3h)		;4da8
	or a			;4dab
	call z,pon_el_periodo		;4dac
	ld a,b			;4daf   ; el volumen, del nibble alto
	rrca			;4db0
	rrca			;4db1
	rrca			;4db2
	rrca			;4db3
	ld (ix+017h),a		;4db4
	ld a,(ix+010h)		;4db7
	or a			;4dba
	jr z,repone_la_duracion		;4dbb
	ld a,(ix+014h)		;4dbd
	ld (ix+013h),a		;4dc0
	ld a,(0e0f3h)		;4dc3
	or a			;4dc6
	jp z,pon_el_volumen		;4dc7
	ret			;4dca
repone_la_duracion:
	ld a,(ix+001h)		;4dcb
	ld (ix+000h),a		;4dce
	ld a,(0e0f3h)		;4dd1
	or a			;4dd4
	jp z,pon_el_volumen		;4dd5
	ret			;4dd8
decae_la_nota:
	dec (ix+000h)		;4dd9   ; en modo musica, la nota se va apagando
	jp z,lee_la_siguiente_orden		;4ddc
	ld a,(ix+010h)		;4ddf
	or a			;4de2
	jp nz,paso_del_instrumento		;4de3
	dec (ix+00ah)		;4de6   ; cada tantos cuadros (+0C)...
	ld a,(ix+00ah)		;4de9
	cp (ix+000h)		;4dec
	jr nz,L_4DF9		;4def
	ld e,a			;4df1
	ld a,(ix+00dh)		;4df2
	cp e			;4df5
	jr nc,L_4DFC		;4df6
	ret			;4df8
L_4DF9:
	dec (ix+00ah)		;4df9
L_4DFC:
	ld a,(ix+008h)		;4dfc   ; ...el volumen baja uno, hasta 0
	dec a			;4dff
	ret m			;4e00
	ld (ix+008h),a		;4e01
	ld (ix+017h),a		;4e04
	ld a,(0e0f3h)		;4e07
	or a			;4e0a
	jp z,pon_el_volumen		;4e0b
	ret			;4e0e

; ----------------------------------------------------------------------
; LAS ORDENES DE LA MUSICA. 0xDX: unidad de tiempo X. 0xFX: volumen X+2, y el byte siguiente el ritmo y el suelo del decaimiento. 0xE0-0xE7: octava. 0xE8: desafina (periodo + 1). 0xE9-0xEE: instrumento 1 a 6. 0xEF: sin instrumento. El resto es una nota: nibble alto de 0 a 11 (12 es silencio) y nibble bajo, cuantas unidades dura menos una.
; ----------------------------------------------------------------------
orden_de_musica:
	ld a,(hl)			;4e0f
	and 0f0h		;4e10
	cp 0d0h		;4e12
	ld a,(hl)			;4e14
	jr nz,L_4E1E		;4e15
	and 00fh		;4e17   ; 0xDX: la unidad de tiempo
	ld (ix+006h),a		;4e19
	inc hl			;4e1c
	ld a,(hl)			;4e1d
L_4E1E:
	cp 0f0h		;4e1e   ; 0xFX: el volumen...
	jr c,L_4E3C		;4e20
	and 00fh		;4e22
	inc a			;4e24
	inc a			;4e25
	ld (ix+007h),a		;4e26
	inc hl			;4e29
	ld a,(hl)			;4e2a   ; ...y el decaimiento
	and 0f0h		;4e2b
	rrca			;4e2d
	rrca			;4e2e
	rrca			;4e2f
	rrca			;4e30
	ld (ix+00ch),a		;4e31
	ld a,(hl)			;4e34
	and 00fh		;4e35
	ld (ix+00dh),a		;4e37
	inc hl			;4e3a
	ld a,(hl)			;4e3b
L_4E3C:
	cp 0e0h		;4e3c   ; 0xEX
	jr c,nota_de_musica		;4e3e
	and 00fh		;4e40
	cp 008h		;4e42   ; 0xE0-0xE7: la octava
	jr c,pon_la_octava		;4e44
	jr z,desafina		;4e46
	cp 00fh		;4e48   ; 0xEF: fuera instrumento
	jr z,quita_el_instrumento		;4e4a
	sub 008h		;4e4c   ; 0xE9-0xEE: instrumento 1 a 6
	ld (ix+010h),a		;4e4e
	jr L_4E66		;4e51
quita_el_instrumento:
	xor a			;4e53
	ld (ix+00fh),a		;4e54
	ld (ix+010h),a		;4e57
	inc hl			;4e5a
	jr orden_de_musica		;4e5b
desafina:
	ld (ix+00fh),a		;4e5d
	inc hl			;4e60
	jr orden_de_musica		;4e61
pon_la_octava:
	ld (ix+009h),a		;4e63
L_4E66:
	inc hl			;4e66
	ld a,(hl)			;4e67
nota_de_musica:
	and 00fh		;4e68   ; la duracion: la unidad por (nibble bajo + 1)
	ld b,a			;4e6a
	ld a,(ix+006h)		;4e6b
	jr z,L_4E75		;4e6e
L_4E70:
	add a,(ix+006h)		;4e70
	djnz L_4E70		;4e73
L_4E75:
	ld (ix+001h),a		;4e75
	ld a,(hl)			;4e78
	call guarda_el_puntero		;4e79
	and 0f0h		;4e7c   ; el nibble alto: la nota
	rrca			;4e7e
	rrca			;4e7f
	rrca			;4e80
	rrca			;4e81
	ld b,a			;4e82
	ld a,(ix+010h)		;4e83
	or a			;4e86
	jr nz,arranca_el_instrumento		;4e87
	ld a,b			;4e89
	sub 00ch		;4e8a   ; la 12 es un silencio: volumen 0
	jr z,L_4E91		;4e8c
	ld a,(ix+007h)		;4e8e
L_4E91:
	ld (ix+008h),a		;4e91
	ld (ix+017h),a		;4e94
	ld a,(ix+00fh)		;4e97   ; +0F no pasa de 12
	cp 00ch		;4e9a
	jr c,L_4EA2		;4e9c
	ld (ix+00fh),00ch		;4e9e
L_4EA2:
	ld e,(ix+001h)		;4ea2
	ld (ix+000h),e		;4ea5
	ld a,(ix+00ch)		;4ea8
	add a,e			;4eab
	ld (ix+00ah),a		;4eac
	ld a,b			;4eaf   ; el periodo, de la tabla de 0x4FC3...
	ld hl,04fc3h		;4eb0
	add a,l			;4eb3
	ld l,a			;4eb4
	jr nc,L_4EB8		;4eb5
	inc h			;4eb7
L_4EB8:
	ld l,(hl)			;4eb8
	ld h,000h		;4eb9
	ld a,(ix+009h)		;4ebb
	or a			;4ebe
	jr z,L_4EC5		;4ebf
	ld b,a			;4ec1
L_4EC2:
	add hl,hl			;4ec2   ; ...doblado tantas veces como diga la octava
	djnz L_4EC2		;4ec3
L_4EC5:
	ld (ix+015h),l		;4ec5
	ld (ix+016h),h		;4ec8
	ld a,(0e0f3h)		;4ecb
	or a			;4ece
	push af			;4ecf
	call z,pon_el_periodo		;4ed0
	pop af			;4ed3
	jp z,pon_el_volumen		;4ed4
	ret			;4ed7
arranca_el_instrumento:
	add a,a			;4ed8   ; la tabla de 0x50A4 empieza en el instrumento 1
	ld de,050a4h		;4ed9
	add a,e			;4edc
	ld e,a			;4edd
	jr nc,L_4EE1		;4ede
	inc d			;4ee0
L_4EE1:
	ld a,(de)			;4ee1
	ld l,a			;4ee2
	inc de			;4ee3
	ld a,(de)			;4ee4
	ld h,a			;4ee5
	ld a,(ix+001h)		;4ee6
	ld (ix+000h),a		;4ee9
	ld a,b			;4eec   ; dentro del instrumento, la nota que toca
	add a,a			;4eed
	add a,l			;4eee
	ld l,a			;4eef
	jr nc,L_4EF3		;4ef0
	inc h			;4ef2
L_4EF3:
	ld e,(hl)			;4ef3
	ld (ix+011h),e		;4ef4
	inc hl			;4ef7
	ld d,(hl)			;4ef8
	ld (ix+012h),d		;4ef9
	ex de,hl			;4efc
	ld a,(hl)			;4efd
	jp orden_de_efecto		;4efe
paso_del_instrumento:
	dec (ix+013h)		;4f01
	ret nz			;4f04
	ld l,(ix+011h)		;4f05
	ld h,(ix+012h)		;4f08
	ld a,(hl)			;4f0b
	cp 0ffh		;4f0c   ; 0xFF: se acabo el instrumento
	jr z,calla_el_instrumento		;4f0e
	jp orden_de_efecto		;4f10
siguiente_paso_del_instrumento:
	inc hl			;4f13
	ld (ix+011h),l		;4f14
	ld (ix+012h),h		;4f17
	jp guarda_el_periodo		;4f1a
calla_el_instrumento:
	xor a			;4f1d
	ld (ix+005h),a		;4f1e
	ld (ix+017h),a		;4f21
	ld a,(0e0f3h)		;4f24
	or a			;4f27
	jp z,pon_el_volumen		;4f28
	ret			;4f2b
fin_del_canal:
	ld a,(ix+019h)		;4f2c   ; con una subrutina abierta, se vuelve a ella
	or a			;4f2f
	jr z,libera_el_canal		;4f30
	ld (ix+004h),a		;4f32
	ld a,(ix+018h)		;4f35
	ld (ix+003h),a		;4f38
	ld (ix+019h),000h		;4f3b
	ld (ix+000h),001h		;4f3f
	jp avanza_el_canal		;4f43
libera_el_canal:
	ld d,(ix+002h)		;4f46
	xor a			;4f49
	ld (ix+002h),a		;4f4a
	ld (ix+005h),a		;4f4d
	ld (ix+00bh),a		;4f50
	ld (ix+010h),a		;4f53
	ld (ix+017h),a		;4f56
	ld (ix+019h),a		;4f59
	ld a,c			;4f5c   ; los canales de musica se quedan en silencio
	cp 007h		;4f5d
	jr nc,acaba_el_efecto		;4f5f
	ld a,(0e0f3h)		;4f61
	or a			;4f64
	jp z,pon_el_volumen		;4f65
	ret			;4f68
acaba_el_efecto:
	ld a,d			;4f69   ; el efecto 2 deja sonando el 0x2C
	cp 002h		;4f6a
	ld a,02ch		;4f6c
	call z,toca_sonido		;4f6e
	dec c			;4f71   ; y el tercer canal recupera sus registros
	dec c			;4f72
	ld a,(0e0f3h)		;4f73
	or a			;4f76
	call z,escribe_el_volumen		;4f77
	ld ix,0e050h		;4f7a
	jr escribe_el_periodo		;4f7e
pon_el_periodo:
	ld a,(0e072h)		;4f80   ; (0xE072): hay efecto sonando
	ld e,a			;4f83
	ld a,c			;4f84   ; los dos primeros canales, siempre
	cp 005h		;4f85
	jr c,escribe_el_periodo		;4f87
	jr nz,L_4F90		;4f89   ; el tercero solo si no hay efecto
	ld a,e			;4f8b
	or a			;4f8c
	ret nz			;4f8d
	jr escribe_el_periodo		;4f8e
L_4F90:
	ld a,e			;4f90   ; y el de efectos solo si lo hay, en los registros del tercero
	or a			;4f91
	ret z			;4f92
	dec c			;4f93
	dec c			;4f94
	call escribe_el_periodo		;4f95
	inc c			;4f98
	inc c			;4f99
	ret			;4f9a
escribe_el_periodo:
	ld l,(ix+015h)		;4f9b
	ld h,(ix+016h)		;4f9e
	ld a,(ix+00fh)		;4fa1   ; desafinado: el periodo + 1, la nota un pelo mas grave
	cp 008h		;4fa4
	jr nz,L_4FA9		;4fa6
	inc hl			;4fa8
L_4FA9:
	ld a,c			;4fa9   ; registro C: el byte alto
	ld e,h			;4faa
	call 00093h		;4fab   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;4fae   ; registro C-1: el bajo
	dec a			;4faf
	ld e,l			;4fb0
	call 00093h		;4fb1   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,(ix+010h)		;4fb4
	or a			;4fb7
	ret nz			;4fb8
	ld a,(ix+00eh)		;4fb9
	or a			;4fbc
	ret z			;4fbd
	ld (ix+005h),002h		;4fbe   ; modo musica sin instrumento: el tipo pasa a tono solo
	ret			;4fc2

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
	ld a,(0e072h)		;4fcf
	ld e,a			;4fd2
	ld a,c			;4fd3
	cp 005h		;4fd4
	jr c,escribe_el_volumen		;4fd6
	jr nz,L_4FDF		;4fd8
	ld a,e			;4fda
	or a			;4fdb
	ret nz			;4fdc
	jr escribe_el_volumen		;4fdd
L_4FDF:
	ld a,e			;4fdf
	or a			;4fe0
	ret z			;4fe1
	dec c			;4fe2
	dec c			;4fe3
escribe_el_volumen:
	call pon_el_mezclador		;4fe4   ; primero el mezclador
	ld a,c			;4fe7   ; el registro de volumen: 8, 9 o 10
	rrca			;4fe8
	add a,088h		;4fe9
	ld d,a			;4feb
	ld h,(ix+017h)		;4fec
	ld a,(ix+005h)		;4fef
	bit 3,a		;4ff2   ; con la envolvente del PSG, su forma al registro 13 y volumen 16
	jr z,L_4FFF		;4ff4
	ld e,h			;4ff6
	ld a,00dh		;4ff7
	call 00093h		;4ff9   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,010h		;4ffc
	ld h,a			;4ffe
L_4FFF:
	ld a,d			;4fff
	ld e,h			;5000
	jp 00093h		;5001   ; BIOS WRTPSG - Writes data to PSG-register
copia_los_canales:		; Los 0x60 bytes de tres canales de HL a DE, y fuera la marca de pausa
	ld bc,00060h		;5004
	ldir		;5007
	ld c,a			;5009
	xor a			;500a
	ld (0e0f1h),a		;500b
	ret			;500e
orden_fe:
	inc hl			;500f
	ld a,(hl)			;5010   ; 0xFE 0x00: cambia de modo
	or a			;5011
	jr z,cambia_de_modo		;5012
	inc a			;5014   ; 0xFE 0xFF: subrutina
	jr z,llama_a_la_subrutina		;5015
	ld a,(ix+00bh)		;5017   ; 0xFE N dir: vuelve a dir hasta N veces
	inc a			;501a
	cp (hl)			;501b
	jr z,acaba_el_bucle		;501c
	jp m,L_5022		;501e
	dec a			;5021
L_5022:
	ld (ix+00bh),a		;5022
	inc hl			;5025
	ld a,(hl)			;5026
	ld (ix+003h),a		;5027
	inc hl			;502a
	ld a,(hl)			;502b
	ld (ix+004h),a		;502c
	jr L_503A		;502f
acaba_el_bucle:
	inc hl			;5031
	inc hl			;5032
	xor a			;5033
	ld (ix+00bh),a		;5034
salta_la_orden:
	call guarda_el_puntero		;5037
L_503A:
	inc (ix+000h)		;503a
	jp avanza_el_canal		;503d
cambia_de_modo:
	ld a,(ix+00eh)		;5040
	or a			;5043
	jr z,L_504B		;5044
	dec (ix+00eh)		;5046
	jr L_504E		;5049
L_504B:
	inc (ix+00eh)		;504b
L_504E:
	jr salta_la_orden		;504e
llama_a_la_subrutina:
	inc hl			;5050
	ld e,(hl)			;5051
	ld (ix+003h),e		;5052
	inc hl			;5055
	ld d,(hl)			;5056
	ld (ix+004h),d		;5057
	inc hl			;505a
	ld (ix+018h),l		;505b   ; la vuelta, en +18/+19
	ld (ix+019h),h		;505e
	ex de,hl			;5061
	jp L_4D3C		;5062
guarda_el_puntero:
	inc hl			;5065
	ld (ix+003h),l		;5066
	ld (ix+004h),h		;5069
	ret			;506c

; ----------------------------------------------------------------------
; EL MEZCLADOR (registro 7 del PSG). Con el tipo del canal: bit 1, su tono; bit 0, su ruido. Un bit a uno en el registro 7 CIERRA el canal, asi que se ponen a uno los que no suenan.
; ----------------------------------------------------------------------
pon_el_mezclador:
	ld a,(0e0f0h)		;506d
	ld e,a			;5070
	ld a,(ix+005h)		;5071
	and 003h		;5074
	ld d,a			;5076
	ld a,c			;5077   ; el bit del canal: 1, 2 o 4
	cp 001h		;5078
	jr z,L_507D		;507a
	dec a			;507c
L_507D:
	ld b,a			;507d
	bit 1,d		;507e   ; el tono
	call z,cierra_el_bit		;5080
	bit 1,d		;5083
	call nz,abre_el_bit		;5085
	ld a,b			;5088   ; el ruido, tres bits mas arriba
	rlca			;5089
	rlca			;508a
	rlca			;508b
	bit 0,d		;508c
	call z,cierra_el_bit		;508e
	bit 0,d		;5091
	call nz,abre_el_bit		;5093
escribe_el_mezclador:
	ld (0e0f0h),a		;5096
	ld e,a			;5099
	ld a,007h		;509a
	jp 00093h		;509c   ; BIOS WRTPSG - Writes data to PSG-register
abre_el_bit:
	cpl			;509f
	and e			;50a0
	ld e,a			;50a1
	ret			;50a2
cierra_el_bit:
	or e			;50a3
	ld e,a			;50a4
	ret			;50a5

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
	call L_9069		;61e0   ; fuera el objeto de la vida extra
	call L_7817		;61e3   ; el tiempo a 99
	call borra_los_objetos		;61e6   ; los 24 objetos a cero
	call esconde_los_sprites		;61e9
	call escribe_la_mascara_del_duenio		;61ec   ; en 0xE4FD, una rutina de tres bytes: `and 0x40 / ret`
	call monta_la_fuente		;61ef
	call monta_los_graficos_de_la_fase		;61f2   ; los graficos de los cubos, las animaciones y los sprites
	call estilo_de_la_fase		;61f5   ; B: el estilo de cubos, 0 (fases 1-10), 1 (11-20) o 2 (21-50)
	ld hl,000eah		;61f8   ; cada estilo, 26 cubos de 9 casillas: 234 bytes
	call multiplica_hl		;61fb
	ld de,0a7feh		;61fe   ; desde 0xA7FE...
	add hl,de			;6201
	ld de,0eb00h		;6202   ; ...a 0xEB00
	ld bc,000eah		;6205
	ldir		;6208
	call dibuja_el_tablero		;620a   ; el tablero en la copia de la tabla de nombres
	call L_7ABF		;620d   ; el marco de ladrillo
	call prepara_los_objetos		;6210   ; cada objeto en su sitio de salida, segun la dificultad
	ld a,001h		;6213   ; (0xE328): volcar una vez los sprites de los objetos 19 a 23
	ld (0e328h),a		;6215
	call L_69D4		;6218
	call vuelca_la_pantalla		;621b   ; la copia de la tabla de nombres a la VRAM
	call L_836A		;621e   ; los corazones de los tiles 0xFC y 0xFD
	ld a,(0e002h)		;6221
	bit 5,a		;6224   ; el marcador: de uno o del duelo
	jr nz,L_622D		;6226
	call pinta_el_marcador		;6228
	jr L_6230		;622b
L_622D:
	call pinta_el_marcador_del_duelo		;622d
L_6230:
	ld a,(0e002h)		;6230   ; sin bonificacion, el tiempo otra vez a 99
	rrca			;6233
	jp nc,L_7817		;6234
	ret			;6237
borra_los_objetos:		; 0xE200-0xE500 a cero
	ld hl,0e200h		;6238
	ld de,0e201h		;623b
	ld bc,00300h		;623e
	ld (hl),000h		;6241
	ldir		;6243
	ret			;6245
vuelca_la_pantalla:		; La copia de 0xED20 a 0x3820: las filas 1 a 23 de la tabla de nombres
	ld hl,03820h		;6246
	ld de,0ed20h		;6249
	ld bc,002e0h		;624c
	jp copia_a_vram		;624f
estilo_de_la_fase:		; B = 0, 1 o 2 segun la decena de la fase
	call decena_de_la_fase		;6252
	ld a,b			;6255   ; decena 0: estilo 0; 1: estilo 1; el resto, estilo 2
	ld b,000h		;6256
	or a			;6258
	ret z			;6259
	inc b			;625a
	dec a			;625b
	ret z			;625c
	inc b			;625d
	ret			;625e
decena_de_la_fase:		; B = la decena de (0xE111) - 1: 0 para las fases 1-10, 4 para las 41-50
	ld a,(0e111h)		;625f
	sub 001h		;6262   ; menos uno, en BCD
	daa			;6264
	and 0f0h		;6265   ; la cifra alta
	rrca			;6267
	rrca			;6268
	rrca			;6269
	rrca			;626a
	ld b,a			;626b
	ret			;626c
copia_cinco_veces:		; Los 0x48 bytes de DE, cinco veces seguidas desde HL, en los tres tercios
	ld b,005h		;626d
L_626F:
	push bc			;626f
	ld bc,00048h		;6270   ; nueve tiles
	push hl			;6273
	push de			;6274
	call copia_a_los_tres_bancos		;6275
	pop de			;6278
	pop hl			;6279
	ld a,048h		;627a   ; el siguiente juego de nueve
	call suma_a_a_hl		;627c
	pop bc			;627f
	djnz L_626F		;6280
	ret			;6282

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
	call borra_la_copia_de_nombres		;6366
	ld hl,0ed63h		;6369   ; fila 3, columna 3
	ld de,0ec00h		;636c
	ld a,001h		;636f   ; (0xE32D) a uno: la primera casilla es el modelo
	ld (0e32dh),a		;6371
	ld c,009h		;6374   ; nueve filas...
L_6376:
	ld b,009h		;6376   ; ...de nueve casillas
L_6378:
	ld a,(de)			;6378
	call dibuja_un_cubo		;6379
	inc de			;637c
	ld a,003h		;637d   ; tres columnas por cubo
	call suma_a_a_hl		;637f
	ld a,b			;6382   ; de la segunda casilla en adelante, ya no son modelo
	sub 008h		;6383
	jr nz,L_638A		;6385
	ld (0e32dh),a		;6387
L_638A:
	djnz L_6378		;638a
	ld a,025h		;638c   ; 27 + 37 = 64: dos filas mas abajo
	call suma_a_a_hl		;638e
	dec c			;6391
	jr nz,L_6376		;6392
	ld a,(0e002h)		;6394   ; en el duelo...
	bit 5,a		;6397
	ret z			;6399
	ld hl,0ed44h		;639a   ; ...1P y 2P encima de los dos modelos
	ld (hl),011h		;639d
	inc hl			;639f
	ld (hl),030h		;63a0
	inc hl			;63a2
	inc hl			;63a3
	ld (hl),012h		;63a4
	inc hl			;63a6
	ld (hl),030h		;63a7
	ret			;63a9
dibuja_un_cubo:		; El cubo A en HL; si ya coincide con el modelo, se marca y se pinta el cubo acabado
	cp 0ffh		;63aa   ; 0xFF: no hay cubo
	ret z			;63ac
	and 01fh		;63ad   ; los cinco bits bajos: cual de los 24
	push hl			;63af
	push de			;63b0
	push bc			;63b1
	ld b,a			;63b2
	ld a,(0e32dh)		;63b3   ; el modelo, tal cual
	or a			;63b6
	ld a,b			;63b7
	jr nz,pinta_el_cubo_a		;63b8
	xor a			;63ba   ; contra el modelo del primero
	ld (0e339h),a		;63bb
	ld a,b			;63be
	call L_722F		;63bf
	jr nz,L_63CC		;63c2
	ld a,b			;63c4   ; coincide: bit 6 (es del primero)...
	or 040h		;63c5
	ld (de),a			;63c7
	ld b,018h		;63c8   ; ...y se pinta el cubo 24, el acabado del primero
	jr L_63DD		;63ca
L_63CC:
	ld a,001h		;63cc   ; contra el del segundo
	ld (0e339h),a		;63ce
	ld a,b			;63d1
	call L_722F		;63d2
	jr nz,L_63DD		;63d5
	ld a,b			;63d7   ; bit 5 y el cubo 25, el acabado del segundo
	or 020h		;63d8
	ld (de),a			;63da
	ld b,019h		;63db
L_63DD:
	ld a,b			;63dd
pinta_el_cubo_a:
	ld b,009h		;63de   ; nueve casillas por cubo en 0xEB00
	call multiplica		;63e0
	ld de,0eb00h		;63e3
	call suma_a_a_de		;63e6
	ld c,003h		;63e9   ; tres filas de tres
L_63EB:
	ld b,003h		;63eb
L_63ED:
	ld a,(de)			;63ed
	ld (hl),a			;63ee
	inc de			;63ef
	inc hl			;63f0
	djnz L_63ED		;63f1
	ld a,01dh		;63f3   ; 32 - 3: la fila siguiente
	call suma_a_a_hl		;63f5
	dec c			;63f8
	jr nz,L_63EB		;63f9
	pop bc			;63fb
	pop de			;63fc
	pop hl			;63fd
	ret			;63fe
borra_la_copia_de_nombres:		; 0xED00-0xEFFF a cero
	ld hl,0ed00h		;63ff
	ld de,0ed01h		;6402
	ld bc,002ffh		;6405
	ld (hl),000h		;6408
	ldir		;640a
	ret			;640c
fase_menos_una_hasta_9:		; min((0xE111) - 1, 9) en BCD
	ld a,(0e111h)		;640d   ; CODIGO HUERFANO: nadie lo llama ni apunta aqui
	sub 001h		;6410
	daa			;6412
	cp 00ah		;6413
	ret c			;6415
	ld a,009h		;6416
	ret			;6418
fase_en_binario:		; (0xE111) - 1 en binario: el numero de la fase desde cero
	ld a,(0e111h)		;6419
	ld c,000h		;641c
L_641E:
	inc c			;641e   ; cuenta hacia abajo en BCD
	sub 001h		;641f
	daa			;6421
	jr nz,L_641E		;6422
	dec c			;6424
	ld a,c			;6425
	ret			;6426
bcd_de_a:		; A en binario a BCD
	or a			;6427
	ret z			;6428
	ld c,a			;6429
	xor a			;642a
L_642B:
	add a,001h		;642b
	daa			;642d
	dec c			;642e
	jr nz,L_642B		;642f
	ret			;6431
multiplica:		; A = A * B (con B=0, cero)
	ld c,a			;6432
	ld a,b			;6433
	or a			;6434
	ret z			;6435
	xor a			;6436
L_6437:
	add a,c			;6437
	djnz L_6437		;6438
	ret			;643a
multiplica_hl:		; HL = HL * B
	ld a,b			;643b
	or a			;643c
	jr nz,L_6443		;643d
	ld hl,00000h		;643f
	ret			;6442
L_6443:
	ld d,h			;6443
	ld e,l			;6444
	ld hl,00000h		;6445
L_6448:
	add hl,de			;6448
	djnz L_6448		;6449
	ret			;644b
divide:		; A / B: el cociente en A y el resto en B
	ld c,0ffh		;644c
L_644E:
	inc c			;644e
	sub b			;644f
	jr nc,L_644E		;6450
	add a,b			;6452
	ld b,a			;6453
	ld a,c			;6454
	ret			;6455

; ----------------------------------------------------------------------
; LOS OBJETOS EN SU SITIO DE SALIDA. Cinco tablas de 24 bytes, uno por objeto: el primer byte de cada uno sale de una de las siete filas de 0x64DB segun la dificultad (la decena de la fase; en el duelo, 5 o 6 segun el nivel), y la Y, la X, el patron y el color de 0x6583, 0x659B, 0x65B3 y 0x65CB. Luego Q*bert baja hasta el primer cubo de su columna.
; ----------------------------------------------------------------------
prepara_los_objetos:
	call decena_de_la_fase		;6456   ; la decena de la fase
	ld a,(0e002h)		;6459
	bit 5,a		;645c
	jr z,L_6467		;645e
	ld a,(0e103h)		;6460   ; en el duelo, 5 mas el nivel
	ld b,005h		;6463
	add a,b			;6465
	ld b,a			;6466
L_6467:
	ld a,018h		;6467   ; 24 bytes por fila
	call multiplica		;6469
	ld hl,064dbh		;646c
	call suma_a_a_hl		;646f
	ld de,0e200h		;6472
	call copia_un_byte_de_cada_objeto		;6475   ; byte 0: la espera de cada bicho
	ld hl,06583h		;6478
	ld de,0e204h		;647b
	call copia_un_byte_de_cada_objeto		;647e   ; byte 4: la Y
	ld hl,0659bh		;6481
	ld de,0e205h		;6484
	call copia_un_byte_de_cada_objeto		;6487   ; byte 5: la X
	ld hl,065b3h		;648a
	ld de,0e206h		;648d
	call copia_un_byte_de_cada_objeto		;6490   ; byte 6: el patron
	ld hl,065cbh		;6493
	ld de,0e207h		;6496
	call copia_un_byte_de_cada_objeto		;6499   ; byte 7: el color
	ld de,(0e204h)		;649c   ; Q*bert, hasta el primer cubo de su columna...
	call baja_hasta_un_cubo		;64a0
	ld (0e204h),de		;64a3
	ld (0e20ch),de		;64a7   ; ...y su segundo sprite en el mismo sitio
	ld a,(0e002h)		;64ab
	bit 5,a		;64ae
	ret z			;64b0
	ld de,(0e214h)		;64b1   ; el segundo Q*bert empieza en Y=0x0C
	ld e,00ch		;64b5
	call baja_hasta_un_cubo		;64b7
	ld (0e214h),de		;64ba
	ld (0e21ch),de		;64be
	ret			;64c2
baja_hasta_un_cubo:		; Baja E de 16 en 16 hasta que (E,D) cae en una casilla con cubo
	call L_7265		;64c3
	inc a			;64c6
	ret nz			;64c7
	ld a,e			;64c8
	add a,010h		;64c9
	ld e,a			;64cb
	jr baja_hasta_un_cubo		;64cc
copia_un_byte_de_cada_objeto:		; 24 bytes de HL a DE, DE de 8 en 8
	ld b,018h		;64ce
L_64D0:
	ld a,(hl)			;64d0
	ld (de),a			;64d1
	inc hl			;64d2
	ld a,008h		;64d3
	call suma_a_a_de		;64d5
	djnz L_64D0		;64d8
	ret			;64da

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
	call borra_los_marcadores_del_duelo		;65e3
	ld a,(0e103h)		;65e6   ; el nivel por 16: la decena en BCD
	ld b,a			;65e9
	ld a,010h		;65ea
	call multiplica		;65ec
	inc a			;65ef   ; mas uno
	ld (0e111h),a		;65f0
	ld a,(0e104h)		;65f3   ; (0xE104): partida a 3 o a 5
	or a			;65f6
	ld a,003h		;65f7
	jr z,L_65FD		;65f9
	ld a,005h		;65fb
L_65FD:
	ld (0ecb8h),a		;65fd
carga_el_tablero_siguiente:
	ld a,(0e002h)		;6600   ; en el duelo, una fase al azar
	bit 5,a		;6603
	jr z,carga_el_tablero		;6605
	ld a,r		;6607   ; R entre 6, mas 31: de la 31 a la 50
	ld b,006h		;6609
	call divide		;660b
	add a,01fh		;660e
	cp 032h		;6610
	jr c,L_6616		;6612
	ld a,032h		;6614
L_6616:
	call bcd_de_a		;6616
	ld (0e111h),a		;6619
carga_el_tablero:
	call tablero_de_la_fase		;661c
	ld de,0ec00h		;661f   ; los 81 bytes a 0xEC00
	ldir		;6622
	ld a,(0e002h)		;6624
	bit 5,a		;6627
	ret nz			;6629
	ld a,0ffh		;662a   ; con un jugador no hay segundo modelo
	ld (0ec01h),a		;662c
	ret			;662f
tablero_de_la_fase:		; HL = 0x97DB + 81 * (fase - 1), BC = 81
	call fase_en_binario		;6630
	ld b,a			;6633
	ld hl,00051h		;6634
	call multiplica_hl		;6637
	ld de,097dbh		;663a
	add hl,de			;663d
	ld bc,00051h		;663e
	ret			;6641

; ----------------------------------------------------------------------
; LOS GRAFICOS DE LA FASE: los 72 tiles de arista con los colores del estilo, los tiles de las diez animaciones de cubo que giran, las caras, y los patrones de sprite de Q*bert y de los bichos.
; ----------------------------------------------------------------------
monta_los_graficos_de_la_fase:
	ld hl,02200h		;6642   ; tile 0x40
	ld de,06286h		;6645
	ld b,048h		;6648   ; 72 veces el triangulo
L_664A:
	push bc			;664a
	push hl			;664b
	push de			;664c
	ld bc,00008h		;664d
	call copia_a_los_tres_bancos		;6650
	pop de			;6653
	pop hl			;6654
	pop bc			;6655
	ld a,008h		;6656
	call suma_a_a_hl		;6658
	djnz L_664A		;665b
	call estilo_de_la_fase		;665d   ; los colores del estilo
	ld hl,00048h		;6660
	call multiplica_hl		;6663
	ld de,0628eh		;6666
	add hl,de			;6669
	ld de,0e500h		;666a
	ld b,048h		;666d   ; un RLE hecho a mano en 0xE500: 8 veces cada color
L_666F:
	ld a,008h		;666f
	ld (de),a			;6671
	inc de			;6672
	ld a,(hl)			;6673
	ld (de),a			;6674
	inc hl			;6675
	inc de			;6676
	djnz L_666F		;6677
	ld a,000h		;6679   ; y su 0x00 de fin
	ld (de),a			;667b
	ld de,0e500h		;667c   ; a 0x0200: el color del tile 0x40
	ld hl,00200h		;667f
	call guion_rle_en_tres_bancos		;6682
	ld hl,02488h		;6685   ; tile 0x91: cinco juegos de nueve para los cubos que giran
	ld de,0b004h		;6688
	call copia_cinco_veces		;668b
	ld hl,025f0h		;668e   ; tile 0xBE: otros cinco
	ld de,0afbch		;6691
	call copia_cinco_veces		;6694
	ld hl,02440h		;6697   ; tile 0x88: el cubo acabado del primero
	ld de,0b04ch		;669a
	ld bc,00048h		;669d
	call copia_a_los_tres_bancos		;66a0
	ld hl,02708h		;66a3   ; tile 0xE1: el del segundo
	ld de,0b04ch		;66a6
	ld bc,00048h		;66a9
	call copia_a_los_tres_bancos		;66ac
	ld hl,00440h		;66af   ; y sus colores
	ld de,0b094h		;66b2
	call guion_rle_en_tres_bancos		;66b5
	ld hl,00708h		;66b8
	ld de,0b097h		;66bb
	call guion_rle_en_tres_bancos		;66be
	ld hl,01800h		;66c1   ; los patrones de sprite de Q*bert (0x00-0x1F)...
	ld de,0acbch		;66c4
	ld bc,00100h		;66c7
	call copia_a_vram		;66ca
	ld hl,01d80h		;66cd   ; ...y los mismos para el segundo (0xB0-0xCF)
	ld de,0acbch		;66d0
	ld bc,00100h		;66d3
	call copia_a_vram		;66d6
	ld hl,01980h		;66d9   ; y los bichos
	ld de,0aabch		;66dc
	ld bc,00040h		;66df
	call copia_a_vram		;66e2
	ld hl,01a80h		;66e5
	ld de,0aafch		;66e8
	ld bc,00040h		;66eb
	call copia_a_vram		;66ee
	ld hl,01c80h		;66f1
	ld de,0ab3ch		;66f4
	ld bc,00040h		;66f7
	call copia_a_vram		;66fa
	ld hl,01cc0h		;66fd
	ld de,0ab3ch		;6700
	ld bc,00040h		;6703
	call copia_a_vram		;6706
	ld hl,01b80h		;6709
	ld de,0ab7ch		;670c
	ld bc,00040h		;670f
	call copia_a_vram		;6712
	ld hl,01e80h		;6715
	ld de,0abbch		;6718
	ld bc,00040h		;671b
	call copia_a_vram		;671e
	ld hl,01d00h		;6721
	ld de,0abfch		;6724
	ld bc,00040h		;6727
	call copia_a_vram		;672a
	ld hl,01e80h		;672d
	ld de,0abbch		;6730
	ld bc,00040h		;6733
	call copia_a_vram		;6736
pon_el_paso_a_del_bicho_80:		; Patrones 0x80-0x87 desde 0xAC3C
	exx			;6739
	ld hl,01c00h		;673a
	ld de,0ac3ch		;673d
	ld bc,00040h		;6740
	call copia_a_vram		;6743
	exx			;6746
	ret			;6747
pon_el_paso_b_del_bicho_80:		; Patrones 0x80-0x87 desde 0xAC7C: el otro paso de la animacion
	exx			;6748
	ld hl,01c00h		;6749
	ld de,0ac7ch		;674c
	ld bc,00040h		;674f
	call copia_a_vram		;6752
	exx			;6755
	ret			;6756
rellena_la_tabla_de_nombres:		; Pone en cada casilla de la tabla de nombres el byte bajo de su direccion: 0, 1, 2... Un visor de patrones de desarrollo
	ld hl,03800h		;6757   ; CODIGO HUERFANO: ni el trazado ni ninguna palabra de los 32 KB llegan aqui
	ld bc,00300h		;675a
L_675D:
	ld a,l			;675d
	call 0004dh		;675e   ; BIOS WRTVRM - Writes data in VRAM | WRTVRM, casilla a casilla
	inc hl			;6761
	dec bc			;6762
	ld a,b			;6763
	or c			;6764
	jr nz,L_675D		;6765
	ret			;6767
escribe_la_mascara_del_duenio:		; Escribe en 0xE4FD `and 0x40 / ret`: 0x7341 cambia el 0x40 por 0x20 segun de quien se cuenten los cubos
	ld hl,0e4fdh		;6768
	ld (hl),0e6h		;676b
	inc hl			;676d
	ld (hl),040h		;676e
	inc hl			;6770
	ld (hl),0c9h		;6771
	ret			;6773
borra_los_marcadores_del_duelo:		; 0xE600-0xE610 a cero
	ld hl,0e600h		;6774
	ld de,0e601h		;6777
	ld bc,00010h		;677a
	ld (hl),000h		;677d
	ldir		;677f
	ret			;6781
L_6782:
	call L_6AA3		;6782
	ld a,(0e327h)		;6785
	or a			;6788
	jp nz,L_6AD0		;6789
	ld a,(0e002h)		;678c
	bit 0,a		;678f
	jp nz,L_789D		;6791
	djnz L_680C		;6794
L_6796:
	ld a,(0e072h)		;6796
	cp 011h		;6799
	jr z,L_6796		;679b
	ld a,047h		;679d
	call toca_sonido_en_partida		;679f
	call L_6806		;67a2
	ld a,00dh		;67a5
	ld (0e20fh),a		;67a7
	ld a,(0e33ah)		;67aa
	or a			;67ad
	ld hl,0e200h		;67ae
	jr z,L_67B6		;67b1
	ld hl,0e210h		;67b3
L_67B6:
	ld (0e33bh),hl		;67b6
	ld hl,0e32ah		;67b9
	ld (hl),00ah		;67bc
	inc hl			;67be
	ld (hl),000h		;67bf
	inc hl			;67c1
	ld (hl),006h		;67c2
	ld a,(0e33ah)		;67c4
	or a			;67c7
	ld hl,01800h		;67c8
	jr z,L_67D0		;67cb
	ld hl,01d80h		;67cd
L_67D0:
	push hl			;67d0
	ld de,0aebch		;67d1
	ld bc,00080h		;67d4
	call copia_a_vram		;67d7
	pop hl			;67da
	ld de,00080h		;67db
	add hl,de			;67de
	ld de,0aefch		;67df
	ld bc,00080h		;67e2
	call copia_a_vram		;67e5
	ld hl,(0e33bh)		;67e8
	ld a,006h		;67eb
	call suma_a_a_hl		;67ed
	ld a,(0e33ah)		;67f0
	or a			;67f3
	ld a,004h		;67f4
	jr z,L_67FA		;67f6
	ld a,0b4h		;67f8
L_67FA:
	ld (hl),a			;67fa
	call L_683F		;67fb
	ld a,003h		;67fe
	ld (0e324h),a		;6800
	jp espera_a_y_sigue		;6803
L_6806:
	ld a,0d0h		;6806
	ld (0e224h),a		;6808
	ret			;680b
L_680C:
	djnz L_686B		;680c
	call L_715A		;680e
	call L_6A75		;6811
	call L_6AE8		;6814
	call L_69B7		;6817
	ld hl,0e32ah		;681a
	dec (hl)			;681d
	jr nz,L_684D		;681e
	ld (hl),00ah		;6820
	inc hl			;6822
	ld a,(hl)			;6823
	xor 001h		;6824
	ld (hl),a			;6826
	inc hl			;6827
	dec (hl)			;6828
	jp z,espera_a_y_sigue		;6829
	or a			;682c
	ld a,004h		;682d
	jr z,L_6833		;682f
	ld a,0fch		;6831
L_6833:
	ld b,a			;6833
	ld hl,(0e33bh)		;6834
	ld a,006h		;6837
	call suma_a_a_hl		;6839
	ld a,b			;683c
	add a,(hl)			;683d
	ld (hl),a			;683e
L_683F:
	ld b,a			;683f
	ld hl,(0e33bh)		;6840
	ld a,00eh		;6843
	call suma_a_a_hl		;6845
	ld a,b			;6848
	add a,010h		;6849
	ld (hl),a			;684b
	ret			;684c
L_684D:
	inc hl			;684d
	ld a,(hl)			;684e
	or a			;684f
	ld a,0ffh		;6850
	jr z,L_6856		;6852
	ld a,001h		;6854
L_6856:
	ld b,a			;6856
	ld hl,(0e33bh)		;6857
	ld a,004h		;685a
	call suma_a_a_hl		;685c
	ld a,b			;685f
	add a,(hl)			;6860
	ld (hl),a			;6861
	ld b,a			;6862
	ld a,008h		;6863
	call suma_a_a_hl		;6865
	ld a,b			;6868
	ld (hl),a			;6869
	ret			;686a
L_686B:
	djnz L_6878		;686b
	call L_6AE8		;686d
	ld a,014h		;6870
	call toca_sonido		;6872
	jp espera_a_y_sigue		;6875
L_6878:
	djnz L_6888		;6878
	call L_6AE8		;687a
	call L_69B7		;687d
	ld a,(0e012h)		;6880
	or a			;6883
	ret nz			;6884
	jp espera_a_y_sigue		;6885
L_6888:
	djnz L_68B0		;6888
	call vuelca_la_pantalla		;688a
	ld a,(0e002h)		;688d
	bit 5,a		;6890
	jr nz,L_6898		;6892
	call L_79D7		;6894
	ret nz			;6897
L_6898:
	ld a,(0e002h)		;6898
	bit 5,a		;689b
	jr z,L_68A6		;689d
	ld a,(0ecb8h)		;689f
	or a			;68a2
	jp z,L_82E1		;68a3
L_68A6:
	xor a			;68a6
	ld (0e334h),a		;68a7
	ld a,001h		;68aa
	ld (0e00dh),a		;68ac
	ret			;68af
L_68B0:
	djnz L_68B5		;68b0
	jp L_89C6		;68b2
L_68B5:
	djnz L_68BA		;68b5
	jp L_8A36		;68b7
L_68BA:
	djnz L_68BF		;68ba
	jp L_8A89		;68bc
L_68BF:
	djnz L_68C4		;68bf
	jp L_8AE1		;68c1
L_68C4:
	djnz L_68D0		;68c4
	ld a,059h		;68c6
	call toca_sonido		;68c8
	ld a,020h		;68cb
	jp espera_a_y_sigue		;68cd
L_68D0:
	djnz L_68DD		;68d0
	ld hl,0e004h		;68d2
	dec (hl)			;68d5
	ret nz			;68d6
	call borra_la_pantalla		;68d7
	jp espera_a_y_sigue		;68da
L_68DD:
	djnz L_68E6		;68dd
	xor a			;68df
	ld (0e002h),a		;68e0
	jp vuelve_al_logotipo		;68e3
L_68E6:
	call L_69D4		;68e6
	call L_69B7		;68e9
	call L_7320		;68ec
	call L_6BF1		;68ef
	call L_6C3A		;68f2
	call L_75B6		;68f5
	call L_6D14		;68f8
	call L_715A		;68fb
	call L_6953		;68fe
	call L_699C		;6901
	call L_6962		;6904
	call L_8FDF		;6907
	ld a,(0e202h)		;690a
	cp 004h		;690d
	jr z,L_691B		;690f
	ld a,(0e212h)		;6911
	cp 004h		;6914
	jr z,L_691B		;6916
	call L_7646		;6918
L_691B:
	ld hl,0e321h		;691b
	ld a,(hl)			;691e
	or a			;691f
	jr z,L_694A		;6920
	ld a,(0e072h)		;6922
	or a			;6925
	jr nz,L_692D		;6926
	ld a,00dh		;6928
	call toca_sonido		;692a
L_692D:
	ld a,(0e003h)		;692d
	and 003h		;6930
	ret nz			;6932
	dec (hl)			;6933
	ld a,(hl)			;6934
	cp 020h		;6935
	ret nc			;6937
	ld a,00eh		;6938
	call toca_sonido		;693a
	ld a,(hl)			;693d
	or a			;693e
	ret nz			;693f
	ld a,(0e329h)		;6940
	or a			;6943
	ret z			;6944
	ld a,00fh		;6945
	jp toca_sonido		;6947
L_694A:
	call L_7444		;694a
	call L_7498		;694d
	jp L_781E		;6950
L_6953:
	ld hl,0e336h		;6953
	ld a,(hl)			;6956
	or a			;6957
	jr z,L_695B		;6958
	dec (hl)			;695a
L_695B:
	inc hl			;695b
	ld a,(hl)			;695c
	or a			;695d
	jr z,L_6961		;695e
	dec (hl)			;6960
L_6961:
	ret			;6961
L_6962:
	ld hl,0e345h		;6962
	ld b,00dh		;6965
	ld a,(hl)			;6967
	or a			;6968
	ret z			;6969
	ld a,(0e003h)		;696a
	ld c,a			;696d
	and 003h		;696e
	ret nz			;6970
	ld a,c			;6971
	bit 2,a		;6972
	jr z,L_6978		;6974
	ld b,006h		;6976
L_6978:
	dec (hl)			;6978
	jr nz,L_697D		;6979
	ld b,00dh		;697b
L_697D:
	ld a,b			;697d
	ld (0e20fh),a		;697e
	inc hl			;6981
	ld b,005h		;6982
	ld a,(hl)			;6984
	or a			;6985
	ret z			;6986
	ld a,c			;6987
	and 003h		;6988
	ret nz			;698a
	ld a,c			;698b
	bit 2,a		;698c
	jr z,L_6992		;698e
	ld b,000h		;6990
L_6992:
	dec (hl)			;6992
	jr nz,L_6997		;6993
	ld b,005h		;6995
L_6997:
	ld a,b			;6997
	ld (0e21fh),a		;6998
	ret			;699b
L_699C:
	ld d,00ah		;699c
	ld e,00fh		;699e
	ld a,(0e322h)		;69a0
	or a			;69a3
	ld a,d			;69a4
	jr z,L_69A8		;69a5
	ld a,e			;69a7
L_69A8:
	ld (0e207h),a		;69a8
	ld a,(0e331h)		;69ab
	or a			;69ae
	ld a,d			;69af
	jr z,L_69B3		;69b0
	ld a,e			;69b2
L_69B3:
	ld (0e217h),a		;69b3
	ret			;69b6
L_69B7:
	ld a,(0e003h)		;69b7
	and 003h		;69ba
	ld b,a			;69bc
	ld hl,000a0h		;69bd
	call multiplica_hl		;69c0
	ld de,03840h		;69c3
	add hl,de			;69c6
	push hl			;69c7
	ld de,0b500h		;69c8
	add hl,de			;69cb
	ex de,hl			;69cc
	pop hl			;69cd
	ld bc,000a0h		;69ce
	jp copia_a_vram		;69d1
L_69D4:
	ld hl,03b00h		;69d4
	ld de,0e20ch		;69d7
	ld bc,00004h		;69da
	call copia_a_vram		;69dd
	ld hl,03b04h		;69e0
	ld de,0e21ch		;69e3
	ld bc,00004h		;69e6
	call copia_a_vram		;69e9
	ld hl,0e328h		;69ec
	ld a,(hl)			;69ef
	or a			;69f0
	jr z,L_6A17		;69f1
	dec a			;69f3
	jr nz,L_69F7		;69f4
	ld (hl),a			;69f6
L_69F7:
	ld hl,03b54h		;69f7
	ld de,0e29ch		;69fa
	ld b,005h		;69fd
L_69FF:
	push hl			;69ff
	push de			;6a00
	push bc			;6a01
	ld bc,00004h		;6a02
	call copia_a_vram		;6a05
	pop bc			;6a08
	pop de			;6a09
	pop hl			;6a0a
	ld a,004h		;6a0b
	call suma_a_a_hl		;6a0d
	ld a,008h		;6a10
	call suma_a_a_de		;6a12
	djnz L_69FF		;6a15
L_6A17:
	ld hl,0e204h		;6a17
	ld a,(0e343h)		;6a1a
	ld b,004h		;6a1d
	call multiplica		;6a1f
	ld de,0e400h		;6a22
	call suma_a_a_de		;6a25
	ld bc,00004h		;6a28
	ldir		;6a2b
	call L_6A57		;6a2d
	ld hl,0e214h		;6a30
	ld bc,00004h		;6a33
	ldir		;6a36
	call L_6A57		;6a38
	ld hl,0e224h		;6a3b
	ld b,00fh		;6a3e
L_6A40:
	push bc			;6a40
	ld bc,00004h		;6a41
	ldir		;6a44
	pop bc			;6a46
	call L_6A57		;6a47
	ld a,004h		;6a4a
	call suma_a_a_hl		;6a4c
	djnz L_6A40		;6a4f
	call L_6A57		;6a51
	jp L_6A69		;6a54
L_6A57:
	exx			;6a57
	ld hl,0e343h		;6a58
	ld a,(hl)			;6a5b
	inc a			;6a5c
	cp 011h		;6a5d
	jr c,L_6A62		;6a5f
	xor a			;6a61
L_6A62:
	ld (hl),a			;6a62
	exx			;6a63
	ret nz			;6a64
	ld de,0e400h		;6a65
	ret			;6a68
L_6A69:
	ld hl,03b08h		;6a69
	ld de,0e400h		;6a6c
	ld bc,00044h		;6a6f
	jp copia_a_vram		;6a72
L_6A75:
	ld b,013h		;6a75
	ld hl,0e328h		;6a77
	ld a,(hl)			;6a7a
	or a			;6a7b
	jr z,L_6A84		;6a7c
	ld b,018h		;6a7e
	dec a			;6a80
	jr nz,L_6A84		;6a81
	ld (hl),a			;6a83
L_6A84:
	exx			;6a84
	ld hl,0e204h		;6a85
	ld de,03b00h		;6a88
	ld b,000h		;6a8b
	exx			;6a8d
L_6A8E:
	exx			;6a8e
	ld c,004h		;6a8f
	call 0005ch		;6a91   ; BIOS LDIRVM - Block transfers to VRAM from memory
	ex de,hl			;6a94
	ld a,004h		;6a95
	call suma_a_a_hl		;6a97
	ld a,004h		;6a9a
	call suma_a_a_de		;6a9c
	exx			;6a9f
	djnz L_6A8E		;6aa0
	ret			;6aa2
L_6AA3:
	ld a,(0e327h)		;6aa3
	or a			;6aa6
	jr nz,L_6AB2		;6aa7
	ld a,(0e012h)		;6aa9
	cp 01dh		;6aac
	ret nc			;6aae
	cp 017h		;6aaf
	ret c			;6ab1
L_6AB2:
	ld a,006h		;6ab2
	call 00141h		;6ab4   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	ld hl,0e326h		;6ab7
	cp (hl)			;6aba
	ret z			;6abb
	ld (hl),a			;6abc
	bit 5,a		;6abd
	ret nz			;6abf
	inc hl			;6ac0
	ld a,(hl)			;6ac1
	xor 001h		;6ac2
	ld (hl),a			;6ac4
	ld a,001h		;6ac5
	ld (0e0f1h),a		;6ac7
	ret z			;6aca
	ld a,056h		;6acb
	jp toca_sonido		;6acd
L_6AD0:
	ld a,(0e003h)		;6ad0
	bit 3,a		;6ad3
	ld de,06adeh		;6ad5
	jp z,pinta_guion		;6ad8
	jp borra_guion		;6adb

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6ade..0x6ae8  (10 bytes)
DATA_6ADE:
	defb 04ch,039h,020h,030h,021h,035h,033h,025h,020h,0ffh	; 6ade  L9 0!53% .

; ======================================================================
; CODIGO 0x6ae8..0x6b08  (32 bytes)
; ======================================================================


L_6AE8:
	ld a,(0e003h)		;6ae8
	and 007h		;6aeb
	ret nz			;6aed
	ld hl,0e324h		;6aee
	dec (hl)			;6af1
	ld a,(hl)			;6af2
	jr nz,L_6AF7		;6af3
	ld (hl),003h		;6af5
L_6AF7:
	ld hl,06b08h		;6af7
	add a,a			;6afa
	call suma_a_a_hl		;6afb
	ld e,(hl)			;6afe
	inc hl			;6aff
	ld d,(hl)			;6b00
	ld hl,00760h		;6b01
	call guion_rle_en_tres_bancos		;6b04
	ret			;6b07

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6b08..0x6b47  (63 bytes)
DATA_6B08:
	defb 034h,06bh,021h,06bh,00eh,06bh,008h,020h,010h,030h,008h,020h,008h,040h,010h,050h	; 6b08  4k!k.k. .0. .@.P
	defb 008h,040h,008h,080h,010h,090h,008h,080h,000h,008h,080h,010h,090h,008h,080h,008h	; 6b18  .@..............
	defb 020h,010h,030h,008h,020h,008h,040h,010h,050h,008h,040h,000h,008h,040h,010h,050h	; 6b28   .0. .@.P.@..@.P
	defb 008h,040h,008h,080h,010h,090h,008h,080h,008h,020h,010h,030h,008h,020h,000h	; 6b38  .@....... .0. .

; ======================================================================
; CODIGO 0x6b47..0x6bbf  (120 bytes)
; ======================================================================


L_6B47:
	call monta_la_fuente		;6b47
	ld hl,030ffh		;6b4a
	ld (0e00bh),hl		;6b4d
	ld (0e117h),hl		;6b50
	ld a,001h		;6b53
	ld (0e113h),a		;6b55
	ld hl,0e116h		;6b58
	ld a,(hl)			;6b5b
	xor 001h		;6b5c
	ld (hl),a			;6b5e
	jr z,L_6B6C		;6b5f
	xor a			;6b61
	ld (0e002h),a		;6b62
	ld a,034h		;6b65
	ld (0e111h),a		;6b67
	jr L_6B76		;6b6a
L_6B6C:
	ld a,020h		;6b6c
	ld (0e002h),a		;6b6e
	ld a,037h		;6b71
	ld (0e111h),a		;6b73
L_6B76:
	call L_7817		;6b76
	call carga_el_tablero		;6b79
	jp monta_la_fase		;6b7c
L_6B7F:
	jp L_68E6		;6b7f
L_6B82:
	ld b,000h		;6b82
	ld a,020h		;6b84
	ld hl,0e00ch		;6b86
	ld de,06bbfh		;6b89
	call L_6B9E		;6b8c
	ld a,(0e116h)		;6b8f
	or a			;6b92
	ret nz			;6b93
	ld b,001h		;6b94
	ld a,030h		;6b96
	ld hl,0e118h		;6b98
	ld de,06bd8h		;6b9b
L_6B9E:
	dec (hl)			;6b9e
	ret nz			;6b9f
	ld (hl),a			;6ba0
	dec hl			;6ba1
	inc (hl)			;6ba2
	ld a,(hl)			;6ba3
	call suma_a_a_de		;6ba4
	ld a,(de)			;6ba7
	cp 0ffh		;6ba8
	jr z,L_6BBA		;6baa
	dec b			;6bac
	jr z,L_6BB3		;6bad
	call guarda_el_mando_1		;6baf
	ret			;6bb2
L_6BB3:
	ld hl,0e330h		;6bb3
	call guarda_mando_en_hl		;6bb6
	ret			;6bb9
L_6BBA:
	xor a			;6bba
	ld (0e113h),a		;6bbb
	ret			;6bbe

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6bbf..0x6bf1  (50 bytes)
DATA_6BBF:
	defb 00ah,006h,006h,009h,00ah,005h,00ah,006h,006h,009h,006h,009h,00ah,006h,005h,009h	; 6bbf  ................
	defb 006h,009h,00ah,005h,00ah,005h,006h,00ah,0ffh,006h,00ah,005h,00ah,005h,006h,009h	; 6bcf  ................
	defb 005h,009h,005h,00ah,006h,009h,00ah,005h,006h,00ah,005h,006h,006h,009h,005h,00ah	; 6bdf  ................
	defb 006h,0ffh	; 6bef

; ======================================================================
; CODIGO 0x6bf1..0x6d10  (287 bytes)
; ======================================================================


L_6BF1:
	ld hl,0e202h		;6bf1
	ld a,(hl)			;6bf4
	or a			;6bf5
	ret nz			;6bf6
	call L_6C8A		;6bf7
	ld a,b			;6bfa
	or a			;6bfb
	ret z			;6bfc
	ld a,(0e009h)		;6bfd
	bit 4,a		;6c00
	jr z,L_6C0A		;6c02
	ld a,(0e322h)		;6c04
	ld (0e323h),a		;6c07
L_6C0A:
	call L_6CC7		;6c0a
L_6C0D:
	ld hl,0e202h		;6c0d
	call L_6CD0		;6c10
	xor a			;6c13
	ld (0e323h),a		;6c14
	call L_7265		;6c17
	and 040h		;6c1a
	jr z,L_6C23		;6c1c
	call L_9093		;6c1e
	jr L_6C26		;6c21
L_6C23:
	call L_708E		;6c23
L_6C26:
	ld hl,0e201h		;6c26
	ld de,0e209h		;6c29
	ld bc,00003h		;6c2c
	ldir		;6c2f
	ld a,(0e206h)		;6c31
	add a,010h		;6c34
	ld (0e20eh),a		;6c36
	ret			;6c39
L_6C3A:
	ld a,(0e002h)		;6c3a
	bit 5,a		;6c3d
	ret z			;6c3f
	ld hl,0e212h		;6c40
	ld a,(hl)			;6c43
	or a			;6c44
	ret nz			;6c45
	call L_6C82		;6c46
	ld a,b			;6c49
	or a			;6c4a
	ret z			;6c4b
	ld a,(0e330h)		;6c4c
	bit 4,a		;6c4f
	jr z,L_6C59		;6c51
	ld a,(0e331h)		;6c53
	ld (0e323h),a		;6c56
L_6C59:
	call L_6CC7		;6c59
L_6C5C:
	ld hl,0e212h		;6c5c
	call L_6CD0		;6c5f
	xor a			;6c62
	ld (0e323h),a		;6c63
	call L_7265		;6c66
	and 020h		;6c69
	call z,L_708E		;6c6b
	ld hl,0e211h		;6c6e
	ld de,0e219h		;6c71
	ld bc,00003h		;6c74
	ldir		;6c77
	ld a,(0e216h)		;6c79
	add a,010h		;6c7c
	ld (0e21eh),a		;6c7e
	ret			;6c81
L_6C82:
	ld de,0e32fh		;6c82
	ld hl,01d80h		;6c85
	jr L_6C90		;6c88
L_6C8A:
	ld de,0e008h		;6c8a
	ld hl,01800h		;6c8d
L_6C90:
	ld b,000h		;6c90
	ld a,(de)			;6c92
	and 00fh		;6c93
	ret z			;6c95
	inc de			;6c96
	ld a,(de)			;6c97
	and 00fh		;6c98
	ret z			;6c9a
	ld b,001h		;6c9b
	cp 005h		;6c9d
	jr z,L_6CB6		;6c9f
	ld b,002h		;6ca1
	cp 00ah		;6ca3
	jr z,L_6CBB		;6ca5
	ld b,004h		;6ca7
	cp 006h		;6ca9
	jr z,L_6CB6		;6cab
	ld b,008h		;6cad
	cp 009h		;6caf
	jr z,L_6CBB		;6cb1
	ld b,000h		;6cb3
	ret			;6cb5
L_6CB6:
	ld de,0acbch		;6cb6
	jr L_6CBE		;6cb9
L_6CBB:
	ld de,0adbch		;6cbb
L_6CBE:
	push bc			;6cbe
	ld bc,00100h		;6cbf
	call copia_a_vram		;6cc2
	pop bc			;6cc5
	ret			;6cc6
L_6CC7:
	ld a,b			;6cc7
	ld b,001h		;6cc8
L_6CCA:
	rrca			;6cca
	ret c			;6ccb
	sla b		;6ccc
	jr L_6CCA		;6cce
L_6CD0:
	ld c,001h		;6cd0
	ld a,b			;6cd2
	and 005h		;6cd3
	jr nz,L_6CD8		;6cd5
	inc c			;6cd7
L_6CD8:
	ld (hl),c			;6cd8
	inc hl			;6cd9
	ld c,001h		;6cda
	ld a,b			;6cdc
	and 009h		;6cdd
	jr nz,L_6CE3		;6cdf
	ld c,003h		;6ce1
L_6CE3:
	call L_6CFA		;6ce3
	inc hl			;6ce6
	ld e,(hl)			;6ce7
	inc hl			;6ce8
	ld d,(hl)			;6ce9
	ld a,b			;6cea
	ld c,00ch		;6ceb
	and 009h		;6ced
	jr nz,L_6CF3		;6cef
	ld c,004h		;6cf1
L_6CF3:
	inc hl			;6cf3
	ld a,(hl)			;6cf4
	and 0f0h		;6cf5
	add a,c			;6cf7
	ld (hl),a			;6cf8
	ret			;6cf9
L_6CFA:
	ld a,(0e323h)		;6cfa
	or a			;6cfd
	jr z,L_6D06		;6cfe
	dec c			;6d00
	ld a,008h		;6d01
	call toca_sonido		;6d03
L_6D06:
	ld a,c			;6d06
	ld de,06d10h		;6d07
	call suma_a_a_de		;6d0a
	ld a,(de)			;6d0d
	ld (hl),a			;6d0e
	ret			;6d0f

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6d10..0x6d14  (4 bytes)
DATA_6D10:
	defb 000h,021h,032h,053h	; 6d10

; ======================================================================
; CODIGO 0x6d14..0x6d35  (33 bytes)
; ======================================================================


L_6D14:
	ld hl,0e202h		;6d14
	ld b,018h		;6d17
	ld a,(0e321h)		;6d19
	or a			;6d1c
	jr z,L_6D21		;6d1d
	ld b,004h		;6d1f
L_6D21:
	push hl			;6d21
	push bc			;6d22
	ld a,(hl)			;6d23
	call L_6D31		;6d24
	pop bc			;6d27
	pop hl			;6d28
	ld a,008h		;6d29
	call suma_a_a_hl		;6d2b
	djnz L_6D21		;6d2e
	ret			;6d30
L_6D31:
	push hl			;6d31
	call reparte_por_tabla		;6d32

; ----------------------------------------------------------------------
; DATOS sin identificar  0x6d35..0x6d53  (30 bytes)
DATA_6D35:
	defb 053h,06dh,03bh,06eh,03bh,06eh,0e7h,06dh,055h,06dh,026h,06eh,017h,070h,017h,070h	; 6d35  Sm;n;n.mUm&n.p.p
	defb 017h,070h,017h,070h,017h,070h,017h,070h,03bh,06eh,03bh,06eh,053h,06dh	; 6d45  .p.p.p.p;n;nSm

; ======================================================================
; CODIGO 0x6d53..0x6f9e  (587 bytes)
; ======================================================================


L_6D53:
	pop hl			;6d53
	ret			;6d54
L_6D55:
	pop hl			;6d55
	inc hl			;6d56
	inc hl			;6d57
	inc (hl)			;6d58
	inc (hl)			;6d59
	inc hl			;6d5a
	inc hl			;6d5b
	ld a,(0e003h)		;6d5c
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
	dec hl			;6d72
	dec hl			;6d73
	ld a,(hl)			;6d74
	cp 0c8h		;6d75
	ret c			;6d77
	ld (hl),0e0h		;6d78
	inc hl			;6d7a
	inc hl			;6d7b
	ld d,(hl)			;6d7c
	dec hl			;6d7d
	dec hl			;6d7e
	dec hl			;6d7f
	dec hl			;6d80
	ld (hl),000h		;6d81
	ld a,d			;6d83
	cp 021h		;6d84
	ld b,07ch		;6d86
	ld c,a			;6d88
	ld a,000h		;6d89
	ld (0e333h),a		;6d8b
	ld a,c			;6d8e
	jr c,L_6DA3		;6d8f
	ld b,0ach		;6d91
	cp 0b0h		;6d93
	ld a,001h		;6d95
	ld (0e333h),a		;6d97
	ret c			;6d9a
	call L_6F83		;6d9b
	call L_6DDC		;6d9e
	jr L_6DA9		;6da1
L_6DA3:
	call L_6F68		;6da3
	call L_6DD1		;6da6
L_6DA9:
	ld a,(0e002h)		;6da9
	bit 5,a		;6dac
	jr z,L_6DCC		;6dae
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
	ld a,(0e333h)		;6dbd
	or a			;6dc0
	ld hl,0e113h		;6dc1
	jr z,L_6DC9		;6dc4
	ld hl,0e35ch		;6dc6
L_6DC9:
	ld (hl),000h		;6dc9
	ret			;6dcb
L_6DCC:
	xor a			;6dcc
	ld (0e113h),a		;6dcd
	ret			;6dd0
L_6DD1:
	xor a			;6dd1
	ld (0e322h),a		;6dd2
	ld (0e201h),a		;6dd5
	ld (0e209h),a		;6dd8
	ret			;6ddb
L_6DDC:
	xor a			;6ddc
	ld (0e331h),a		;6ddd
	ld (0e211h),a		;6de0
	ld (0e219h),a		;6de3
	ret			;6de6
L_6DE7:
	pop hl			;6de7
	inc hl			;6de8
	inc hl			;6de9
	inc (hl)			;6dea
	ld a,(hl)			;6deb
	and 00fh		;6dec
	cp 00ch		;6dee
	ret nz			;6df0
	ld e,(hl)			;6df1
	inc hl			;6df2
	ld d,(hl)			;6df3
	inc hl			;6df4
	ld c,(hl)			;6df5
	dec hl			;6df6
	call L_7265		;6df7
	inc a			;6dfa
	ret z			;6dfb
	dec hl			;6dfc
	dec hl			;6dfd
	dec hl			;6dfe
	ld (hl),000h		;6dff
	ld a,c			;6e01
	cp 020h		;6e02
	ld hl,0e336h		;6e04
	jr c,L_6E0D		;6e07
	inc hl			;6e09
	cp 0b0h		;6e0a
	ret c			;6e0c
L_6E0D:
	ld (hl),080h		;6e0d
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
	ld a,014h		;6e21
	jp toca_sonido		;6e23
L_6E26:
	pop hl			;6e26
	inc hl			;6e27
	inc hl			;6e28
	inc (hl)			;6e29
	ld a,(0e29ch)		;6e2a
	cp (hl)			;6e2d
	ret nz			;6e2e
L_6E2F:
	ld (hl),0e0h		;6e2f
	dec hl			;6e31
	dec hl			;6e32
	ld (hl),000h		;6e33
	ld a,001h		;6e35
	ld (0e328h),a		;6e37
	ret			;6e3a
L_6E3B:
	pop hl			;6e3b
	dec hl			;6e3c
	ld a,(hl)			;6e3d
	and 00fh		;6e3e
	ld b,a			;6e40
	inc b			;6e41
	inc hl			;6e42
L_6E43:
	push hl			;6e43
	push bc			;6e44
	call L_6E4D		;6e45
	pop bc			;6e48
	pop hl			;6e49
	djnz L_6E43		;6e4a
	ret			;6e4c
L_6E4D:
	ld a,(hl)			;6e4d
	or a			;6e4e
	ret z			;6e4f
	cp 004h		;6e50
	ret z			;6e52
	ld c,a			;6e53
	inc hl			;6e54
	ld a,(hl)			;6e55
	ld b,a			;6e56
	ld de,06f9eh		;6e57
	call suma_a_a_de		;6e5a
	ld a,(de)			;6e5d
	cp 080h		;6e5e
	jr nz,L_6ED3		;6e60
	inc hl			;6e62
	ld a,c			;6e63
	cp 00ch		;6e64
	jp z,L_6F1B		;6e66
	cp 00dh		;6e69
	jp z,L_6F1B		;6e6b
	inc hl			;6e6e
	inc hl			;6e6f
	ld a,(hl)			;6e70
	sub 004h		;6e71
	ld (hl),a			;6e73
	ld c,a			;6e74
	dec hl			;6e75
	ld d,(hl)			;6e76
	dec hl			;6e77
	ld e,(hl)			;6e78
	ld a,c			;6e79
	cp 021h		;6e7a
	ld a,004h		;6e7c
	jr c,L_6E87		;6e7e
	ld a,c			;6e80
	cp 0b0h		;6e81
	ld a,005h		;6e83
	jr c,L_6E95		;6e85
L_6E87:
	call toca_sonido		;6e87
	ld a,(0e345h)		;6e8a
	or a			;6e8d
	jr z,L_6E95		;6e8e
	ld a,006h		;6e90
	call toca_sonido_en_partida		;6e92
L_6E95:
	call L_7265		;6e95
	ld b,a			;6e98
	ld a,c			;6e99
	cp 090h		;6e9a
	jr c,L_6EB0		;6e9c
	cp 0a0h		;6e9e
	jr nc,L_6EB0		;6ea0
	ld a,b			;6ea2
	rlca			;6ea3
	jr nc,L_6EB0		;6ea4
	push hl			;6ea6
	ld de,01000h		;6ea7
	call suma_puntos		;6eaa
	pop hl			;6ead
	jr L_6ECD		;6eae
L_6EB0:
	ld a,b			;6eb0
	inc a			;6eb1
	ld a,000h		;6eb2
	jr z,L_6ECA		;6eb4
	push hl			;6eb6
	ld hl,01c0ch		;6eb7
	or a			;6eba
	sbc hl,de		;6ebb
	pop hl			;6ebd
	jr z,L_6ECA		;6ebe
	push hl			;6ec0
	ld hl,0340ch		;6ec1
	or a			;6ec4
	sbc hl,de		;6ec5
	pop hl			;6ec7
	jr nz,L_6ECF		;6ec8
L_6ECA:
	call L_6F06		;6eca
L_6ECD:
	ld a,004h		;6ecd
L_6ECF:
	dec hl			;6ecf
	dec hl			;6ed0
	ld (hl),a			;6ed1
	ret			;6ed2
L_6ED3:
	inc (hl)			;6ed3
	inc hl			;6ed4
	add a,(hl)			;6ed5
	cp 0f0h		;6ed6
	jr nc,L_6EFB		;6ed8
	ld (hl),a			;6eda
	inc hl			;6edb
	ld a,b			;6edc
	rrca			;6edd
	ld a,001h		;6ede
	jr c,L_6EE3		;6ee0
	inc a			;6ee2
L_6EE3:
	ld d,a			;6ee3
	ld a,c			;6ee4
	cp 00dh		;6ee5
	ld a,d			;6ee7
	jr z,L_6EED		;6ee8
	dec c			;6eea
	jr nz,L_6EEF		;6eeb
L_6EED:
	neg		;6eed
L_6EEF:
	add a,(hl)			;6eef
	cp 005h		;6ef0
	jr c,L_6EFA		;6ef2
	cp 0f4h		;6ef4
	jr nc,L_6EFA		;6ef6
	ld (hl),a			;6ef8
	ret			;6ef9
L_6EFA:
	dec hl			;6efa
L_6EFB:
	inc hl			;6efb
	inc hl			;6efc
	ld c,(hl)			;6efd
	dec hl			;6efe
	dec hl			;6eff
	dec hl			;6f00
	dec hl			;6f01
	ld (hl),004h		;6f02
	inc hl			;6f04
	inc hl			;6f05
L_6F06:
	ld a,c			;6f06
	cp 021h		;6f07
	jr c,L_6F13		;6f09
	cp 0b0h		;6f0b
	ret c			;6f0d
	call L_6F45		;6f0e
	jr L_6F16		;6f11
L_6F13:
	call L_6F22		;6f13
L_6F16:
	ld a,012h		;6f16
	jp toca_sonido_en_partida		;6f18
L_6F1B:
	inc hl			;6f1b
	inc hl			;6f1c
	ld c,(hl)			;6f1d
	dec hl			;6f1e
	dec hl			;6f1f
	jr L_6ECA		;6f20
L_6F22:
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
L_6F45:
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
L_6F68:
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
L_6F83:
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
; DATOS sin identificar  0x6f9e..0x7017  (121 bytes)
DATA_6F9E:
	defb 0f7h,0fdh,0fch,0ffh,0ffh,0fdh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,000h,0ffh,0ffh,0ffh	; 6f9e  ................
	defb 000h,000h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,000h	; 6fae  ................
	defb 080h,0fdh,0fah,0ffh,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,0ffh,000h,000h,000h,000h	; 6fbe  ................
	defb 001h,080h,0ffh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,000h	; 6fce  ................
	defb 001h,000h,001h,001h,001h,001h,001h,000h,002h,001h,002h,001h,003h,001h,004h,002h	; 6fde  ................
	defb 005h,005h,080h,0ffh,000h,000h,000h,000h,000h,001h,000h,001h,001h,000h,002h,001h	; 6fee  ................
	defb 003h,001h,007h,080h,0fch,0ffh,0fdh,0ffh,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h	; 6ffe  ................
	defb 001h,000h,001h,001h,002h,001h,002h,001h,080h	; 700e  .........

; ======================================================================
; CODIGO 0x7017..0x705e  (71 bytes)
; ======================================================================


L_7017:
	pop hl			;7017
	ld a,(hl)			;7018
	ld c,000h		;7019
	rrca			;701b
	jr c,L_701F		;701c
	inc c			;701e
L_701F:
	ld a,(hl)			;701f
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
	dec (hl)			;7030
	dec (hl)			;7031
	dec (hl)			;7032
	dec (hl)			;7033
	ld a,(hl)			;7034
	inc hl			;7035
	cp 005h		;7036
	jr c,L_7056		;7038
	cp 0b0h		;703a
	jr nc,L_7056		;703c
	ld a,(hl)			;703e
	cp 005h		;703f
	jr c,L_7056		;7041
	cp 0fah		;7043
	jr nc,L_7056		;7045
	ld a,(0e003h)		;7047
	and b			;704a
	ret nz			;704b
	inc (hl)			;704c
	inc (hl)			;704d
	ld a,c			;704e
	or a			;704f
	ret z			;7050
	dec (hl)			;7051
	dec (hl)			;7052
	dec (hl)			;7053
	dec (hl)			;7054
	ret			;7055
L_7056:
	dec hl			;7056
	ld (hl),0e0h		;7057
	dec hl			;7059
	dec hl			;705a
	ld (hl),000h		;705b
	ret			;705d

; ----------------------------------------------------------------------
; DATOS sin identificar  0x705e..0x708e  (48 bytes)
DATA_705E:
	defb 021h,030h,0e3h,04eh,077h,0a9h,0a6h,02bh,077h,0c9h,006h,000h,03eh,003h,0cdh,041h	; 705e  !0.Nw..+w...>..A
	defb 001h,0cbh,047h,020h,002h,0cbh,0c8h,0cbh,057h,020h,002h,0cbh,0c0h,0cbh,05fh,020h	; 706e  ..G ....W ...._ 
	defb 002h,0cbh,0d8h,03eh,005h,0cdh,041h,001h,0cbh,047h,020h,002h,0cbh,0d0h,078h,0c9h	; 707e  ...>..A..G ...x.

; ======================================================================
; CODIGO 0x708e..0x722c  (414 bytes)
; ======================================================================


L_708E:
	call L_71EE		;708e
	inc a			;7091
	ld d,a			;7092
	ld e,b			;7093
	ld hl,0e2c0h		;7094
	ld b,00ah		;7097
L_7099:
	cp (hl)			;7099
	ret z			;709a
	inc hl			;709b
	inc hl			;709c
	inc hl			;709d
	djnz L_7099		;709e
	ld b,005h		;70a0
	ld hl,0e2c0h		;70a2
	ld c,000h		;70a5
	ld a,e			;70a7
	and 003h		;70a8
	jr nz,L_70B1		;70aa
	ld hl,0e2cfh		;70ac
	ld c,005h		;70af
L_70B1:
	ld a,(hl)			;70b1
	or a			;70b2
	jr z,L_70BC		;70b3
	inc hl			;70b5
	inc hl			;70b6
	inc hl			;70b7
	inc c			;70b8
	djnz L_70B1		;70b9
	ret			;70bb
L_70BC:
	ld (hl),d			;70bc
	inc hl			;70bd
	ld (hl),008h		;70be
	inc hl			;70c0
	ld (hl),e			;70c1
	ld b,e			;70c2
	ld a,d			;70c3
	dec a			;70c4
	push af			;70c5
	push bc			;70c6
	ld hl,0ec00h		;70c7
	call suma_a_a_hl		;70ca
	ld a,(hl)			;70cd
	and 01fh		;70ce
	ld d,a			;70d0
	add a,080h		;70d1
	ld (hl),a			;70d3
	ld c,b			;70d4
	ld a,b			;70d5
	and 009h		;70d6
	ld a,d			;70d8
	jr z,L_70DF		;70d9
	call L_71D6		;70db
	ld d,a			;70de
L_70DF:
	ld b,009h		;70df
	call multiplica		;70e1
	ld hl,0eb01h		;70e4
	call suma_a_a_hl		;70e7
	ld de,0e2f1h		;70ea
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
	ld hl,0727ah		;70fa
	ld de,0e2f4h		;70fd
	ld a,c			;7100
	cp 005h		;7101
	jr c,L_7108		;7103
	ld hl,0729fh		;7105
L_7108:
	ld a,(hl)			;7108
	ld (de),a			;7109
	or a			;710a
	jr z,L_712A		;710b
	inc hl			;710d
	inc de			;710e
	ld a,(hl)			;710f
	and 0f0h		;7110
	rrca			;7112
	rrca			;7113
	rrca			;7114
	rrca			;7115
	call L_71CC		;7116
	rlca			;7119
	rlca			;711a
	rlca			;711b
	rlca			;711c
	ld b,a			;711d
	ld a,(hl)			;711e
	and 00fh		;711f
	call L_71CC		;7121
	add a,b			;7124
	ld (de),a			;7125
	inc hl			;7126
	inc de			;7127
	jr L_7108		;7128
L_712A:
	ld hl,00048h		;712a
	ld b,c			;712d
	call multiplica_hl		;712e
	ld de,00488h		;7131
	add hl,de			;7134
	ld de,0e2f4h		;7135
	push bc			;7138
	call guion_rle_en_tres_bancos		;7139
	pop bc			;713c
	pop af			;713d
	call L_720D		;713e
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
L_715A:
	ld hl,0e2c0h		;715a
	ld b,00ah		;715d
L_715F:
	push hl			;715f
	push bc			;7160
	ld a,(hl)			;7161
	or a			;7162
	jr z,L_71C4		;7163
	ld c,a			;7165
	inc hl			;7166
	dec (hl)			;7167
	jr nz,L_71C4		;7168
	dec hl			;716a
	ld (hl),000h		;716b
	inc hl			;716d
	ld a,c			;716e
	dec a			;716f
	push af			;7170
	ld de,0ec00h		;7171
	call suma_a_a_de		;7174
	ld a,(de)			;7177
	sub 080h		;7178
	inc hl			;717a
	ld c,(hl)			;717b
	call L_71D6		;717c
	ld (de),a			;717f
	ld b,a			;7180
	pop af			;7181
	call L_720D		;7182
	xor a			;7185
	ld (0e339h),a		;7186
	ld a,b			;7189
	ld c,b			;718a
	call L_722F		;718b
	jr nz,L_7198		;718e
	ld b,018h		;7190
	ld a,(de)			;7192
	or 040h		;7193
	ld (de),a			;7195
	jr L_71A9		;7196
L_7198:
	ld a,001h		;7198
	ld (0e339h),a		;719a
	ld a,c			;719d
	call L_722F		;719e
	jr nz,L_71BC		;71a1
	ld b,019h		;71a3
	ld a,(de)			;71a5
	or 020h		;71a6
	ld (de),a			;71a8
L_71A9:
	ld a,009h		;71a9
	call toca_sonido_en_partida		;71ab
	push bc			;71ae
	push hl			;71af
	ld de,00300h		;71b0
	call suma_puntos		;71b3
	pop hl			;71b6
	pop bc			;71b7
	ld a,001h		;71b8
	jr L_71BD		;71ba
L_71BC:
	xor a			;71bc
L_71BD:
	call L_9093		;71bd
	ld a,b			;71c0
	call dibuja_un_cubo		;71c1
L_71C4:
	pop bc			;71c4
	pop hl			;71c5
	inc hl			;71c6
	inc hl			;71c7
	inc hl			;71c8
	djnz L_715F		;71c9
	ret			;71cb
L_71CC:
	exx			;71cc
	ld hl,0e2f0h		;71cd
	call suma_a_a_hl		;71d0
	ld a,(hl)			;71d3
	exx			;71d4
	ret			;71d5
L_71D6:
	push de			;71d6
	push bc			;71d7
	ld b,004h		;71d8
	call multiplica		;71da
	pop bc			;71dd
	ld de,072c0h		;71de
	call suma_a_a_de		;71e1
	ld a,c			;71e4
L_71E5:
	rrca			;71e5
	jr c,L_71EB		;71e6
	inc de			;71e8
	jr L_71E5		;71e9
L_71EB:
	ld a,(de)			;71eb
	pop de			;71ec
	ret			;71ed
L_71EE:
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
L_720D:
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

; ----------------------------------------------------------------------
; DATOS sin identificar  0x722c..0x722f  (3 bytes)
DATA_722C:
	defb 0cdh,065h,072h	; 722c

; ======================================================================
; CODIGO 0x722f..0x727a  (75 bytes)
; ======================================================================


L_722F:
	exx			;722f
	call L_7250		;7230
	ld h,a			;7233
	ld d,b			;7234
	ld e,c			;7235
	ld a,(0e339h)		;7236
	or a			;7239
	ld a,(0ec00h)		;723a
	jr z,L_7242		;723d
	ld a,(0ec01h)		;723f
L_7242:
	call L_7250		;7242
	cp h			;7245
	jr nz,L_724E		;7246
	ld a,b			;7248
	cp d			;7249
	jr nz,L_724E		;724a
	ld a,c			;724c
	cp e			;724d
L_724E:
	exx			;724e
	ret			;724f
L_7250:
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
L_7265:
	ld a,e			;7265
	cp 09ch		;7266
	jr c,L_726D		;7268
	ld a,0ffh		;726a
	ret			;726c
L_726D:
	call L_71EE		;726d
	push hl			;7270
	ld hl,0ec00h		;7271
	call suma_a_a_hl		;7274
	ld a,(hl)			;7277
	pop hl			;7278
	ret			;7279

; ----------------------------------------------------------------------
; DATOS sin identificar  0x727a..0x7320  (166 bytes)
DATA_727A:
	defb 001h,020h,001h,010h,006h,020h,001h,000h,007h,012h,001h,000h,007h,010h,008h,020h	; 727a  . ... ......... 
	defb 003h,012h,003h,020h,002h,023h,001h,010h,002h,012h,003h,023h,002h,030h,008h,020h	; 728a  ... .#.....#.0. 
	defb 008h,023h,008h,030h,000h,003h,000h,005h,010h,003h,000h,005h,010h,003h,000h,005h	; 729a  .#.0............
	defb 030h,008h,010h,008h,031h,008h,030h,004h,010h,004h,020h,004h,031h,001h,021h,003h	; 72aa  0...1.0... .1.!.
	defb 020h,007h,030h,001h,020h,000h,012h,006h,001h,003h,013h,007h,002h,000h,014h,008h	; 72ba   .0. ...........
	defb 003h,001h,015h,009h,000h,002h,016h,00ah,013h,009h,017h,00bh,006h,014h,000h,00ch	; 72ca  ................
	defb 00ah,005h,001h,00dh,010h,017h,002h,00eh,016h,011h,003h,00fh,004h,00bh,004h,010h	; 72da  ................
	defb 014h,006h,005h,011h,009h,013h,006h,012h,00fh,00dh,007h,013h,00ch,00eh,008h,014h	; 72ea  ................
	defb 00dh,00fh,009h,015h,00eh,00ch,00ah,016h,015h,007h,00bh,017h,008h,012h,00ch,000h	; 72fa  ................
	defb 011h,016h,00dh,001h,00bh,004h,00eh,002h,005h,00ah,00fh,003h,017h,010h,010h,004h	; 730a  ................
	defb 012h,008h,011h,005h,007h,015h	; 731a

; ======================================================================
; CODIGO 0x7320..0x7328  (8 bytes)
; ======================================================================


L_7320:
	ld a,(0e003h)		;7320
	and 003h		;7323
	call reparte_por_tabla		;7325

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7328..0x7330  (8 bytes)
DATA_7328:
	defb 030h,073h,053h,073h,069h,073h,07dh,073h	; 7328  0sSsis}s

; ======================================================================
; CODIGO 0x7330..0x7628  (760 bytes)
; ======================================================================


L_7330:
	xor a			;7330
	ld (0e320h),a		;7331
	ld hl,0e33ah		;7334
	ld a,(hl)			;7337
	xor 001h		;7338
	ld (hl),a			;733a
	ld a,040h		;733b
	jr z,L_7341		;733d
	ld a,020h		;733f
L_7341:
	ld (0e4feh),a		;7341
	ld hl,0ec00h		;7344
	ld e,009h		;7347
L_7349:
	ld bc,00901h		;7349
	call L_7421		;734c
	dec e			;734f
	jr nz,L_7349		;7350
	ret			;7352
L_7353:
	ld hl,0ec00h		;7353
	ld e,009h		;7356
L_7358:
	ld bc,00909h		;7358
	call L_7421		;735b
	ld a,l			;735e
	sub 050h		;735f
	ld l,a			;7361
	jr nc,L_7365		;7362
	dec h			;7364
L_7365:
	dec e			;7365
	jr nz,L_7358		;7366
	ret			;7368
L_7369:
	ld e,00ah		;7369
	ld hl,0ec00h		;736b
	ld bc,00901h		;736e
	call L_73F7		;7371
	ld hl,0ec01h		;7374
	ld bc,00801h		;7377
	jp L_7405		;737a
L_737D:
	ld e,008h		;737d
	ld hl,0ec08h		;737f
	ld bc,00901h		;7382
	call L_73F7		;7385
	ld hl,0ec04h		;7388
	ld bc,00500h		;738b
	call L_7405		;738e
	ld b,001h		;7391
	ld a,(0e002h)		;7393
	bit 5,a		;7396
	jr nz,L_73A7		;7398
	ld a,(0e111h)		;739a
	cp 031h		;739d
	jr c,L_73A7		;739f
	inc b			;73a1
	cp 041h		;73a2
	jr c,L_73A7		;73a4
	inc b			;73a6
L_73A7:
	ld a,(0e320h)		;73a7
	cp b			;73aa
	ret c			;73ab
	ld a,(0e33ah)		;73ac
	or a			;73af
	ld a,(0e202h)		;73b0
	ld hl,0e212h		;73b3
	jr z,L_73BE		;73b6
	ld a,(0e212h)		;73b8
	ld hl,0e202h		;73bb
L_73BE:
	or a			;73be
	ret nz			;73bf
	ld a,(hl)			;73c0
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
	ld a,(0e002h)		;73d9
	bit 5,a		;73dc
	jr nz,L_73ED		;73de
	ld a,(0e111h)		;73e0
	and 00fh		;73e3
	jr nz,L_73F4		;73e5
	ld hl,0e103h		;73e7
	inc (hl)			;73ea
	jr L_73F4		;73eb
L_73ED:
	call L_82BB		;73ed
	xor a			;73f0
	ld (0e00dh),a		;73f1
L_73F4:
	jp espera_a_y_sigue		;73f4
L_73F7:
	ld d,005h		;73f7
L_73F9:
	call L_740F		;73f9
	ld a,009h		;73fc
	call suma_a_a_hl		;73fe
	dec d			;7401
	jr nz,L_73F9		;7402
	ret			;7404
L_7405:
	ld d,004h		;7405
L_7407:
	call L_740F		;7407
	inc hl			;740a
	dec d			;740b
	jr nz,L_7407		;740c
	ret			;740e
L_740F:
	push bc			;740f
	push de			;7410
	push hl			;7411
	ld c,e			;7412
	call L_7421		;7413
	pop hl			;7416
	pop de			;7417
	pop bc			;7418
	ld a,c			;7419
	or a			;741a
	jr nz,L_741F		;741b
	inc b			;741d
	ret			;741e
L_741F:
	dec b			;741f
	ret			;7420
L_7421:
	ld d,000h		;7421
L_7423:
	ld a,(hl)			;7423
	inc a			;7424
	jr z,L_7433		;7425
	inc d			;7427
	call 0e4fdh		;7428
	jr nz,L_742E		;742b
	ld d,a			;742d
L_742E:
	ld a,d			;742e
	cp 005h		;742f
	jr nc,L_743C		;7431
L_7433:
	ld a,c			;7433
	add a,l			;7434
	ld l,a			;7435
	jr nc,L_7439		;7436
	inc h			;7438
L_7439:
	djnz L_7423		;7439
	ret			;743b
L_743C:
	ld a,(0e320h)		;743c
	inc a			;743f
	ld (0e320h),a		;7440
	ret			;7443
L_7444:
	ld a,(0e003h)		;7444
	and 03fh		;7447
	ret nz			;7449
	ld hl,0e220h		;744a
	ld b,00fh		;744d
L_744F:
	push hl			;744f
	call L_745C		;7450
	pop hl			;7453
	ld a,008h		;7454
	call suma_a_a_hl		;7456
	djnz L_744F		;7459
	ret			;745b
L_745C:
	ld a,(hl)			;745c
	or a			;745d
	ret z			;745e
	and 00fh		;745f
	or a			;7461
	jr z,L_7466		;7462
	dec (hl)			;7464
	ret nz			;7465
L_7466:
	inc hl			;7466
	inc hl			;7467
	inc hl			;7468
	inc hl			;7469
	ld a,(hl)			;746a
	cp 0e0h		;746b
	ret nz			;746d
	ld a,b			;746e
	cp 00fh		;746f
	jr nz,L_7479		;7471
	ld a,(0e25ch)		;7473
	cp 0e0h		;7476
	ret nz			;7478
L_7479:
	ld (hl),0f0h		;7479
	inc hl			;747b
	ld (hl),064h		;747c
	ld a,r		;747e
	rrca			;7480
	jr c,L_7485		;7481
	ld (hl),094h		;7483
L_7485:
	dec hl			;7485
	dec hl			;7486
	dec hl			;7487
	ld (hl),003h		;7488
	dec hl			;748a
	dec hl			;748b
	ld a,(hl)			;748c
	rrc a		;748d
	rrc a		;748f
	rrc a		;7491
	rrc a		;7493
	add a,(hl)			;7495
	ld (hl),a			;7496
	ret			;7497
L_7498:
	ld a,(0e003h)		;7498
	and 001h		;749b
	ret nz			;749d
	ld hl,0e222h		;749e
	ld b,00fh		;74a1
L_74A3:
	push hl			;74a3
	push bc			;74a4
	call L_74B2		;74a5
	pop bc			;74a8
	pop hl			;74a9
	ld a,008h		;74aa
	call suma_a_a_hl		;74ac
	djnz L_74A3		;74af
	ret			;74b1
L_74B2:
	ld a,(hl)			;74b2
	or a			;74b3
	ret nz			;74b4
	inc hl			;74b5
	inc hl			;74b6
	ld a,(hl)			;74b7
	cp 0e0h		;74b8
	ret z			;74ba
	ld a,b			;74bb
	cp 008h		;74bc
	jr nc,L_74CB		;74be
	cp 001h		;74c0
	jr z,L_74CB		;74c2
	push hl			;74c4
	push bc			;74c5
	call L_750D		;74c6
	pop bc			;74c9
	pop hl			;74ca
L_74CB:
	dec hl			;74cb
	dec hl			;74cc
	dec hl			;74cd
	ld a,(hl)			;74ce
	sub 010h		;74cf
	ld (hl),a			;74d1
	and 0f0h		;74d2
	ret nz			;74d4
	ld a,b			;74d5
	cp 009h		;74d6
	jr nz,L_74E1		;74d8
	ld a,(0e003h)		;74da
	and 0f0h		;74dd
	add a,(hl)			;74df
	ld (hl),a			;74e0
L_74E1:
	inc hl			;74e1
	ld a,b			;74e2
	cp 008h		;74e3
	jp z,L_7559		;74e5
	push bc			;74e8
	ld c,b			;74e9
	ld a,c			;74ea
	cp 009h		;74eb
	jr nz,L_74F2		;74ed
	call pon_el_paso_b_del_bicho_80		;74ef
L_74F2:
	ld b,002h		;74f2
	ld a,r		;74f4
	rrca			;74f6
	jr c,L_7503		;74f7
	ld a,c			;74f9
	cp 009h		;74fa
	jr nz,L_7501		;74fc
	call pon_el_paso_a_del_bicho_80		;74fe
L_7501:
	ld b,004h		;7501
L_7503:
	call L_6CD0		;7503
	pop af			;7506
	cp 00ah		;7507
	ret nz			;7509
	jp L_708E		;750a
L_750D:
	ld e,(hl)			;750d
	inc hl			;750e
	ld d,(hl)			;750f
	call L_7265		;7510
	cp 018h		;7513
	ret nc			;7515
	push hl			;7516
	call L_7250		;7517
	pop hl			;751a
	inc hl			;751b
	inc hl			;751c
	cp (hl)			;751d
	ret nz			;751e
	ld c,(hl)			;751f
	dec hl			;7520
	dec hl			;7521
	dec hl			;7522
	ld a,(hl)			;7523
	add a,010h		;7524
	ld (hl),a			;7526
	ld de,0e29ch		;7527
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
	ld (hl),0e0h		;753c
	dec hl			;753e
	dec hl			;753f
	ld (hl),000h		;7540
	ld de,0e2bah		;7542
	ld a,005h		;7545
	ld (de),a			;7547
	inc de			;7548
	inc de			;7549
	ld a,(de)			;754a
	sub 010h		;754b
	ld (de),a			;754d
	inc de			;754e
	inc de			;754f
	inc de			;7550
	ld a,c			;7551
	ld (de),a			;7552
	ld a,002h		;7553
	ld (0e328h),a		;7555
	ret			;7558
L_7559:
	inc hl			;7559
	inc hl			;755a
	ld a,(0e204h)		;755b
	ld e,(hl)			;755e
	cp (hl)			;755f
	ld b,006h		;7560
	jr nc,L_7566		;7562
	ld b,009h		;7564
L_7566:
	inc hl			;7566
	ld a,(0e205h)		;7567
	ld d,(hl)			;756a
	cp (hl)			;756b
	ld a,00ah		;756c
	jr nc,L_7572		;756e
	ld a,005h		;7570
L_7572:
	and b			;7572
	ld c,a			;7573
	call L_7585		;7574
	ld b,a			;7577
	and c			;7578
	jr z,L_757C		;7579
	ld b,a			;757b
L_757C:
	ld hl,0e25ah		;757c
	call L_6CC7		;757f
	jp L_6CD0		;7582
L_7585:
	call L_71EE		;7585
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
L_75B6:
	ld a,(0e329h)		;75b6
	or a			;75b9
	jr z,L_75D5		;75ba
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
L_75D5:
	ld de,(0e204h)		;75d5
	xor a			;75d9
	ld (0e332h),a		;75da
	ld a,(0e202h)		;75dd
	cp 003h		;75e0
	jr z,L_75EF		;75e2
	cp 004h		;75e4
	jr z,L_75EF		;75e6
	cp 00eh		;75e8
	jr z,L_75EF		;75ea
	call L_760A		;75ec
L_75EF:
	ld a,(0e002h)		;75ef
	bit 5,a		;75f2
	ret z			;75f4
	ld de,(0e214h)		;75f5
	ld a,001h		;75f9
	ld (0e332h),a		;75fb
	ld a,(0e212h)		;75fe
	cp 003h		;7601
	ret z			;7603
	cp 004h		;7604
	ret z			;7606
	cp 00eh		;7607
	ret z			;7609
L_760A:
	ld hl,0e224h		;760a
	ld b,00fh		;760d
L_760F:
	push hl			;760f
	push bc			;7610
	call L_761E		;7611
	pop bc			;7614
	pop hl			;7615
	ld a,008h		;7616
	call suma_a_a_hl		;7618
	djnz L_760F		;761b
	ret			;761d
L_761E:
	call L_76CC		;761e
	ret nc			;7621
	push hl			;7622
	ld a,b			;7623
	dec a			;7624
	call reparte_por_tabla		;7625

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7628..0x7646  (30 bytes)
DATA_7628:
	defb 0dfh,076h,0f0h,076h,0f0h,076h,0f0h,076h,0f0h,076h,0f0h,076h,0f0h,076h,0f0h,076h	; 7628  .v.v.v.v.v.v.v.v
	defb 0f0h,076h,0d7h,077h,0a9h,077h,08ah,077h,06eh,077h,05ah,077h,0c0h,077h	; 7638  .v.w.w.wnwZw.w

; ======================================================================
; CODIGO 0x7646..0x77cc  (390 bytes)
; ======================================================================


L_7646:
	ld a,(0e002h)		;7646
	bit 5,a		;7649
	ret z			;764b
	ld hl,0e344h		;764c
	ld a,(hl)			;764f
	or a			;7650
	jr z,L_7655		;7651
	dec (hl)			;7653
	ret			;7654
L_7655:
	ld de,(0e204h)		;7655
	ld hl,0e214h		;7659
	call L_76CC		;765c
	ret nc			;765f
	xor a			;7660
	ld (0e342h),a		;7661
	ld b,000h		;7664
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
	call L_768D		;7677
	ld a,b			;767a
	cp 003h		;767b
	ret z			;767d
	or a			;767e
	jr z,L_76AC		;767f
	cp 002h		;7681
	jr nz,L_7687		;7683
	ld a,000h		;7685
L_7687:
	ld (0e332h),a		;7687
	jp L_824D		;768a
L_768D:
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
L_76AC:
	ld a,00ah		;76ac
	ld (0e344h),a		;76ae
	ld a,(0e202h)		;76b1
	ld b,002h		;76b4
	dec a			;76b6
	jr nz,L_76BB		;76b7
	ld b,004h		;76b9
L_76BB:
	push bc			;76bb
	call L_6C0D		;76bc
	pop bc			;76bf
	ld a,b			;76c0
	ld b,002h		;76c1
	cp 002h		;76c3
	jr nz,L_76C9		;76c5
	ld b,004h		;76c7
L_76C9:
	jp L_6C5C		;76c9
L_76CC:
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
L_76DF:
	pop hl			;76df
	call L_77D8		;76e0
	ld a,(0e332h)		;76e3
	ld hl,0e345h		;76e6
	or a			;76e9
	jr z,L_76ED		;76ea
	inc hl			;76ec
L_76ED:
	ld (hl),080h		;76ed
	ret			;76ef
L_76F0:
	pop hl			;76f0
	ld a,(0e332h)		;76f1
	ld de,0e345h		;76f4
	or a			;76f7
	jr z,L_76FB		;76f8
	inc de			;76fa
L_76FB:
	ld a,(de)			;76fb
	or a			;76fc
	jr z,L_7711		;76fd
	dec hl			;76ff
	dec hl			;7700
	dec hl			;7701
	ld a,(hl)			;7702
	cp 00ch		;7703
	ret z			;7705
	cp 00dh		;7706
	ret z			;7708
	call L_774D		;7709
	ld a,007h		;770c
	jp toca_sonido		;770e
L_7711:
	ld a,(0e332h)		;7711
	or a			;7714
	ld hl,0e336h		;7715
	jr z,L_771B		;7718
	inc hl			;771a
L_771B:
	ld a,(hl)			;771b
	or a			;771c
	ret nz			;771d
	ld a,(0e002h)		;771e
	bit 5,a		;7721
	jr z,L_7728		;7723
	jp L_7730		;7725
L_7728:
	call L_7730		;7728
	xor a			;772b
	ld (0e113h),a		;772c
	ret			;772f
L_7730:
	ld a,(0e332h)		;7730
	or a			;7733
	ld hl,0e202h		;7734
	jr z,L_773C		;7737
	ld hl,0e212h		;7739
L_773C:
	call L_774D		;773c
	ld a,007h		;773f
	call suma_a_a_hl		;7741
	ld a,b			;7744
	call L_7755		;7745
	ld a,013h		;7748
	jp toca_sonido		;774a
L_774D:
	ld a,(0e003h)		;774d
	and 001h		;7750
	add a,00ch		;7752
	ld b,a			;7754
L_7755:
	ld (hl),a			;7755
	inc hl			;7756
	ld (hl),064h		;7757
	ret			;7759
L_775A:
	pop hl			;775a
	call L_77D8		;775b
	ld a,080h		;775e
	ld (0e321h),a		;7760
	ld hl,000bch		;7763
	call L_6E2F		;7766
	ld a,00dh		;7769
	jp toca_sonido		;776b
L_776E:
	pop hl			;776e
	call L_77D8		;776f
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
L_778A:
	pop hl			;778a
	call L_77D8		;778b
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
L_77A9:
	pop hl			;77a9
	call L_77D8		;77aa
	ld a,(0e332h)		;77ad
	or a			;77b0
	ld hl,0e322h		;77b1
	jr z,L_77B9		;77b4
	ld hl,0e331h		;77b6
L_77B9:
	ld (hl),001h		;77b9
	ld a,00ah		;77bb
	jp toca_sonido		;77bd
L_77C0:
	pop hl			;77c0
	call L_77D8		;77c1
	ld a,00ch		;77c4
	call toca_sonido		;77c6
	jp L_77E5		;77c9

; ----------------------------------------------------------------------
; DATOS sin identificar  0x77cc..0x77d7  (11 bytes)
DATA_77CC:
	defb 006h,00eh,071h,03eh,008h,0cdh,04ah,040h,010h,0f8h,0c9h	; 77cc  ..q>..J@...

; ======================================================================
; CODIGO 0x77d7..0x7949  (370 bytes)
; ======================================================================


L_77D7:
	pop hl			;77d7
L_77D8:
	dec hl			;77d8
	ld (hl),0e0h		;77d9
	dec hl			;77db
	dec hl			;77dc
	ld (hl),000h		;77dd
	ld de,00100h		;77df
	jp suma_puntos		;77e2
L_77E5:
	ld hl,0e22ch		;77e5
	ld b,00dh		;77e8
L_77EA:
	ld c,000h		;77ea
	ld a,(hl)			;77ec
	inc hl			;77ed
	cp 0e0h		;77ee
	jr z,L_7806		;77f0
	ld c,006h		;77f2
	cp 030h		;77f4
	jr c,L_7800		;77f6
	inc c			;77f8
	inc c			;77f9
	cp 060h		;77fa
	jr c,L_7800		;77fc
	inc c			;77fe
	inc c			;77ff
L_7800:
	ld a,(hl)			;7800
	cp 080h		;7801
	jr c,L_7806		;7803
	inc c			;7805
L_7806:
	ld a,001h		;7806
	ld (0e329h),a		;7808
	dec hl			;780b
	dec hl			;780c
	dec hl			;780d
	ld (hl),c			;780e
	ld a,00ah		;780f
	call suma_a_a_hl		;7811
	djnz L_77EA		;7814
	ret			;7816
L_7817:
	ld hl,00099h		;7817
	ld (0ec51h),hl		;781a
	ret			;781d
L_781E:
	call L_7829		;781e
	ld a,(0e001h)		;7821
	cp 006h		;7824
	ret nc			;7826
	jr L_7878		;7827
L_7829:
	ld hl,(0ec51h)		;7829
	ld a,(0e003h)		;782c
	and 03fh		;782f
	ret nz			;7831
	call L_7855		;7832
	ld a,h			;7835
	or l			;7836
	ret nz			;7837
	push hl			;7838
	call L_7878		;7839
	call vuelca_la_pantalla		;783c
	ld a,035h		;783f
	call toca_sonido		;7841
	call L_7E81		;7844
	pop hl			;7847
	ld a,(0e002h)		;7848
	bit 5,a		;784b
	jp nz,L_82E9		;784d
	xor a			;7850
	ld (0e113h),a		;7851
	ret			;7854
L_7855:
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
	ld hl,00010h		;7866
	or a			;7869
	sbc hl,de		;786a
	ex de,hl			;786c
	ret c			;786d
	ld a,(0e334h)		;786e
	or a			;7871
	ret nz			;7872
	ld a,010h		;7873
	jp toca_sonido		;7875
L_7878:
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
L_789D:
	djnz L_78AE		;789d
	ld hl,0e004h		;789f
	dec (hl)			;78a2
	ret nz			;78a3
	ld a,019h		;78a4
	ld (0e324h),a		;78a6
	ld a,003h		;78a9
	jp espera_a_y_sigue		;78ab
L_78AE:
	djnz L_78ED		;78ae
	ld hl,0e004h		;78b0
	dec (hl)			;78b3
	ret nz			;78b4
	ld (hl),003h		;78b5
	ld hl,0e324h		;78b7
	dec (hl)			;78ba
	jp z,L_78DC		;78bb
	ld a,(hl)			;78be
	dec a			;78bf
	sub 017h		;78c0
	neg		;78c2
	ld hl,00020h		;78c4
	ld b,a			;78c7
	call multiplica_hl		;78c8
	ld de,03800h		;78cb
	add hl,de			;78ce
	push hl			;78cf
	ld de,0b500h		;78d0
	add hl,de			;78d3
	ex de,hl			;78d4
	pop hl			;78d5
	ld bc,00020h		;78d6
	jp copia_a_vram		;78d9
L_78DC:
	call pinta_el_marcador		;78dc
	ld de,079a3h		;78df
	call pinta_guion		;78e2
	ld a,01ah		;78e5
	call toca_sonido		;78e7
	jp espera_a_y_sigue		;78ea
L_78ED:
	djnz L_7901		;78ed
	call L_69D4		;78ef
	call L_69B7		;78f2
	call L_7A17		;78f5
	call L_7A37		;78f8
	call L_715A		;78fb
	jp L_7A47		;78fe
L_7901:
	djnz $+93		;7901
	call vuelca_la_pantalla		;7903
	ld hl,0e004h		;7906
	dec (hl)			;7909
	ret nz			;790a
	ld (hl),010h		;790b
	call L_7A7C		;790d
	ld hl,0e325h		;7910
	or a			;7913
	jr nz,L_7924		;7914
	push hl			;7916
	ld d,(hl)			;7917
	ld e,000h		;7918
	call suma_puntos		;791a
	pop hl			;791d
	ld a,(hl)			;791e
	add a,001h		;791f
	daa			;7921
	ld (hl),a			;7922
	ret			;7923
L_7924:
	ld a,(hl)			;7924
	cp 028h		;7925
	jr nz,L_793C		;7927
	ld de,07949h		;7929
	call pinta_guion		;792c
	ld de,05000h		;792f
	call suma_puntos		;7932
	ld a,032h		;7935
	call toca_sonido		;7937
	jr L_7941		;793a
L_793C:
	ld a,059h		;793c
	call toca_sonido		;793e
L_7941:
	ld a,001h		;7941
	ld (0e334h),a		;7943
	jp espera_a_y_sigue		;7946

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7949..0x795e  (21 bytes)
DATA_7949:
	defb 0c7h,03ah,030h,025h,032h,026h,025h,023h,034h,000h,015h,010h,010h,010h,000h,030h	; 7949  .:0%2&%#4......0
	defb 02fh,029h,02eh,034h,0ffh	; 7959

; ======================================================================
; CODIGO 0x795e..0x7999  (59 bytes)
; ======================================================================


L_795E:
	djnz L_796A		;795e
	ld a,(0e012h)		;7960
	or a			;7963
	ret nz			;7964
	ld a,001h		;7965
	jp espera_a_y_sigue		;7967
L_796A:
	djnz L_7980		;796a
	call L_69B7		;796c
	call L_79D7		;796f
	ret nz			;7972
	xor a			;7973
	ld (0e334h),a		;7974
	ld a,001h		;7977
	ld (0e00dh),a		;7979
	ld (0e320h),a		;797c
	ret			;797f
L_7980:
	call esconde_los_sprites		;7980
	ld hl,03800h		;7983
	ld bc,00300h		;7986
	ld a,0ebh		;7989
	call 00056h		;798b   ; BIOS FILVRM - Fills VRAM with value
	ld de,07999h		;798e
	call pinta_guion		;7991
	ld a,050h		;7994
	jp espera_a_y_sigue		;7996

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7999..0x79ae  (21 bytes)
DATA_7999:
	defb 06ch,039h,000h,022h,02fh,02eh,035h,033h,000h,0ffh,002h,038h,022h,02fh,02eh,035h	; 7999  l9."/.53...8"/.5
	defb 033h,0ebh,0ebh,0ebh,0ffh	; 79a9

; ======================================================================
; CODIGO 0x79ae..0x7b41  (403 bytes)
; ======================================================================


L_79AE:
	ld a,(0e111h)		;79ae
	sub 001h		;79b1
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
	ld a,(hl)			;79c4
	xor 001h		;79c5
	ld (hl),a			;79c7
	rrca			;79c8
	ret nc			;79c9
	pop hl			;79ca
	call L_7A0B		;79cb
	call monta_la_fase_con_el_tablero_puesto		;79ce
	ld hl,0e000h		;79d1
	ld (hl),005h		;79d4
	ret			;79d6
L_79D7:
	ld hl,(0ec51h)		;79d7
	ld a,l			;79da
	or a			;79db
	jr z,L_79FC		;79dc
	ld a,001h		;79de
	ld (0e334h),a		;79e0
	call L_7855		;79e3
	call L_7878		;79e6
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
L_79FC:
	ld a,016h		;79fc
	call toca_sonido		;79fe
	call vuelca_la_pantalla		;7a01
L_7A04:
	ld a,(0e072h)		;7a04
	or a			;7a07
	jr nz,L_7A04		;7a08
	ret			;7a0a
L_7A0B:
	ld hl,0a7adh		;7a0b
	ld de,0ec00h		;7a0e
	ld bc,00051h		;7a11
	ldir		;7a14
	ret			;7a16
L_7A17:
	call L_7A1D		;7a17
	jp L_7878		;7a1a
L_7A1D:
	ld hl,(0ec51h)		;7a1d
	ld a,(0e003h)		;7a20
	and 00fh		;7a23
	ret nz			;7a25
	call L_7855		;7a26
	ld a,h			;7a29
	or l			;7a2a
	ret nz			;7a2b
L_7A2C:
	ld a,001h		;7a2c
	ld (0e325h),a		;7a2e
	ex de,hl			;7a31
	call espera_a_y_sigue		;7a32
	ex de,hl			;7a35
	ret			;7a36
L_7A37:
	call L_6C8A		;7a37
	ld a,b			;7a3a
	or a			;7a3b
	ret z			;7a3c
	call L_6CC7		;7a3d
	call L_7A75		;7a40
	call L_708E		;7a43
	ret			;7a46
L_7A47:
	call L_7A75		;7a47
	call L_7265		;7a4a
	and 040h		;7a4d
	ret z			;7a4f
	call L_7A75		;7a50
L_7A53:
	ld a,d			;7a53
	add a,018h		;7a54
	ld d,a			;7a56
	cp 0f0h		;7a57
	jr c,L_7A65		;7a59
	ld d,01ch		;7a5b
	ld a,e			;7a5d
	add a,010h		;7a5e
	ld e,a			;7a60
	cp 09ch		;7a61
	jr nc,L_7A2C		;7a63
L_7A65:
	call L_7265		;7a65
	inc a			;7a68
	jr z,L_7A53		;7a69
	ld (hl),d			;7a6b
	dec hl			;7a6c
	ld (hl),e			;7a6d
	ld hl,0e20ch		;7a6e
	ld (hl),e			;7a71
	inc hl			;7a72
	ld (hl),d			;7a73
	ret			;7a74
L_7A75:
	ld hl,0e204h		;7a75
	ld e,(hl)			;7a78
	inc hl			;7a79
	ld d,(hl)			;7a7a
	ret			;7a7b
L_7A7C:
	ld hl,0ed63h		;7a7c
L_7A7F:
	ld a,(hl)			;7a7f
	cp 088h		;7a80
	jr z,L_7AA0		;7a82
	inc hl			;7a84
	ld a,l			;7a85
	ld b,020h		;7a86
	call divide		;7a88
	ld a,b			;7a8b
	cp 01eh		;7a8c
	jr c,L_7A7F		;7a8e
	ld de,00025h		;7a90
	add hl,de			;7a93
	push hl			;7a94
	ld de,0efa3h		;7a95
	sbc hl,de		;7a98
	pop hl			;7a9a
	jr nz,L_7A7F		;7a9b
	ld a,001h		;7a9d
	ret			;7a9f
L_7AA0:
	ld a,(0e325h)		;7aa0
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
	ld a,b			;7ab1
	and 00fh		;7ab2
	add a,010h		;7ab4
	ld (hl),a			;7ab6
	inc hl			;7ab7
	ld (hl),010h		;7ab8
	inc hl			;7aba
	ld (hl),010h		;7abb
	xor a			;7abd
	ret			;7abe
L_7ABF:
	ld hl,02758h		;7abf
	ld de,07ba5h		;7ac2
	ld bc,00068h		;7ac5
	call copia_a_los_tres_bancos		;7ac8
	ld hl,00758h		;7acb
	ld de,07c0dh		;7ace
	call guion_rle_en_tres_bancos		;7ad1
	ld hl,0ed00h		;7ad4
	call L_7B22		;7ad7
	ld hl,0efe0h		;7ada
	call L_7B22		;7add
	ld hl,0ed20h		;7ae0
	call L_7B29		;7ae3
	ld hl,0ed3fh		;7ae6
	call L_7B29		;7ae9
	ld hl,0ed21h		;7aec
	ld de,07b41h		;7aef
	call L_7B10		;7af2
	ld hl,0efc1h		;7af5
	ld de,07b5fh		;7af8
	call L_7B10		;7afb
	ld hl,0ed41h		;7afe
	ld de,07b7dh		;7b01
	call L_7B15		;7b04
	ld hl,0ed5eh		;7b07
	ld de,07b91h		;7b0a
	jp L_7B15		;7b0d
L_7B10:
	ld bc,01e01h		;7b10
	jr L_7B18		;7b13
L_7B15:
	ld bc,01420h		;7b15
L_7B18:
	ld a,(de)			;7b18
	ld (hl),a			;7b19
	inc de			;7b1a
	ld a,c			;7b1b
	call suma_a_a_hl		;7b1c
	djnz L_7B18		;7b1f
	ret			;7b21
L_7B22:
	ld bc,020ebh		;7b22
	ld d,001h		;7b25
	jr L_7B2E		;7b27
L_7B29:
	ld bc,016ebh		;7b29
	ld d,020h		;7b2c
L_7B2E:
	ld (hl),c			;7b2e
	ld a,d			;7b2f
	call suma_a_a_hl		;7b30
	djnz L_7B2E		;7b33
	ret			;7b35
L_7B36:
	ld hl,03800h		;7b36
	ld bc,00020h		;7b39
	ld a,0ebh		;7b3c
	jp 00056h		;7b3e   ; BIOS FILVRM - Fills VRAM with value

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7b41..0x7c29  (232 bytes)
DATA_7B41:
	defb 000h,0ech,0edh,0f0h,0f1h,0f4h,0f5h,0ech,0edh,0f0h,0f1h,0f4h,0f5h,0ech,0edh,0f0h	; 7b41  ................
	defb 0f1h,0f4h,0f5h,0ech,0edh,0f0h,0f1h,0f4h,0f5h,0ech,0edh,0f0h,0f1h,000h,000h,0f2h	; 7b51  ................
	defb 0f3h,0eeh,0efh,0f6h,0f7h,0f2h,0f3h,0eeh,0efh,0f6h,0f7h,0f2h,0f3h,0eeh,0efh,0f6h	; 7b61  ................
	defb 0f7h,0f2h,0f3h,0eeh,0efh,0f6h,0f7h,0f2h,0f3h,0eeh,0efh,000h,0f7h,0f5h,0f3h,0f1h	; 7b71  ................
	defb 0efh,0edh,0f7h,0f5h,0f3h,0f1h,0efh,0edh,0f7h,0f5h,0f3h,0f1h,0efh,0edh,0f7h,0f5h	; 7b81  ................
	defb 0f6h,0f4h,0eeh,0ech,0f2h,0f0h,0f6h,0f4h,0eeh,0ech,0f2h,0f0h,0f6h,0f4h,0eeh,0ech	; 7b91  ................
	defb 0f2h,0f0h,0f6h,0f4h,0fbh,0ffh,0bfh,0bfh,0bfh,0ffh,0fbh,0fbh,03fh,01fh,00fh,007h	; 7ba1  ............?...
	defb 003h,001h,000h,000h,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,000h,001h,003h	; 7bb1  ................
	defb 007h,00fh,01fh,03fh,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,03fh,01fh,00fh,007h	; 7bc1  ...?........?...
	defb 003h,001h,000h,000h,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,000h,001h,003h	; 7bd1  ................
	defb 007h,00fh,01fh,03fh,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,03fh,01fh,00fh,007h	; 7be1  ...?........?...
	defb 003h,001h,000h,000h,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,000h,000h,000h,001h,003h	; 7bf1  ................
	defb 007h,00fh,01fh,03fh,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,088h,040h,000h,070h	; 7c01  ...?.........@.p
	defb 050h,040h,000h,070h,050h,008h,020h,010h,030h,008h,020h,008h,040h,010h,050h,008h	; 7c11  P@.pP. .0. .@.P.
	defb 040h,008h,080h,010h,090h,008h,080h,000h	; 7c21  @.......

; ======================================================================
; CODIGO 0x7c29..0x7c8c  (99 bytes)
; ======================================================================


L_7C29:
	ld a,(0e002h)		;7c29
	bit 5,a		;7c2c
	jr z,L_7C36		;7c2e
	ld a,(0e342h)		;7c30
	or a			;7c33
	jr nz,L_7C3F		;7c34
L_7C36:
	call borra_la_pantalla		;7c36
	ld hl,03000h		;7c39
	call L_8CA1		;7c3c
L_7C3F:
	call L_7E5A		;7c3f
	ld a,(0e002h)		;7c42
	bit 5,a		;7c45
	jr nz,$+74		;7c47
	ld a,(0e000h)		;7c49
	cp 007h		;7c4c
	jr z,L_7C5D		;7c4e
	ld a,(0e320h)		;7c50
	or a			;7c53
	ld a,04dh		;7c54
	jr nz,L_7C5A		;7c56
	ld a,044h		;7c58
L_7C5A:
	call toca_sonido		;7c5a
L_7C5D:
	call L_7DAE		;7c5d
	call pinta_los_marcadores_del_game_over		;7c60
	ld a,(0e324h)		;7c63
	or a			;7c66
	ret z			;7c67
	ld hl,01800h		;7c68
	ld de,097bbh		;7c6b
	ld bc,00020h		;7c6e
	call copia_a_vram		;7c71
	ld hl,03b00h		;7c74
	ld de,07c8ch		;7c77
	ld bc,00005h		;7c7a
	call copia_a_vram		;7c7d
	ld a,(0e000h)		;7c80
	cp 007h		;7c83
	ret nz			;7c85
	ld de,07e8eh		;7c86
	jp pinta_guion		;7c89

; ----------------------------------------------------------------------
; DATOS sin identificar  0x7c8c..0x7c91  (5 bytes)
DATA_7C8C:
	defb 08fh,060h,000h,00ah,0d0h	; 7c8c

; ======================================================================
; CODIGO 0x7c91..0x7d5a  (201 bytes)
; ======================================================================


L_7C91:
	ld a,(0ecb8h)		;7c91
	or a			;7c94
	jr z,L_7C9C		;7c95
	ld a,04dh		;7c97
	jp toca_sonido		;7c99
L_7C9C:
	call L_8C86		;7c9c
	call L_8CDC		;7c9f
	ld hl,0e600h		;7ca2
	ld a,(hl)			;7ca5
	inc hl			;7ca6
	cp (hl)			;7ca7
	ld a,001h		;7ca8
	jr c,L_7CB4		;7caa
	ld hl,0608fh		;7cac
	ld (0ecach),hl		;7caf
	jr L_7CBB		;7cb2
L_7CB4:
	ld hl,0908fh		;7cb4
	ld (0ecb0h),hl		;7cb7
	inc a			;7cba
L_7CBB:
	ld (0e324h),a		;7cbb
	call L_8CE8		;7cbe
	call L_8B5B		;7cc1
	ld de,07ed6h		;7cc4
	call L_871C		;7cc7
	ld a,(0e104h)		;7cca
	or a			;7ccd
	ld hl,0ee6dh		;7cce
	jr z,L_7CD6		;7cd1
	ld hl,0eeedh		;7cd3
L_7CD6:
	ld de,07f10h		;7cd6
	ld c,0ffh		;7cd9
	call L_8724		;7cdb
	ld a,(0e104h)		;7cde
	or a			;7ce1
	jr z,L_7CF0		;7ce2
	ld de,07efch		;7ce4
	call L_871C		;7ce7
	ld a,015h		;7cea
	ld hl,0ed8ah		;7cec
	ld (hl),a			;7cef
L_7CF0:
	ld de,0e602h		;7cf0
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
L_7D0B:
	ld a,(0e002h)		;7d0b
	bit 5,a		;7d0e
	jr nz,L_7D15		;7d10
	jp L_7DA8		;7d12
L_7D15:
	ld a,(0ecb8h)		;7d15
	or a			;7d18
	jr z,L_7D21		;7d19
	ld a,001h		;7d1b
	ld (0e004h),a		;7d1d
	ret			;7d20
L_7D21:
	call vuelca_la_pantalla		;7d21
	jp L_8B55		;7d24
L_7D27:
	ld de,07d62h		;7d27
	call pinta_guion		;7d2a
	ld a,(0e104h)		;7d2d
	or a			;7d30
	ld b,003h		;7d31
	jr z,L_7D3F		;7d33
	ld a,015h		;7d35
	ld hl,038cah		;7d37
	call 0004dh		;7d3a   ; BIOS WRTVRM - Writes data in VRAM
	ld b,005h		;7d3d
L_7D3F:
	ld a,(0ecb8h)		;7d3f
	ld de,07d9ch		;7d42
	cp 001h		;7d45
	jr z,L_7D56		;7d47
	sub b			;7d49
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
; DATOS sin identificar  0x7d5a..0x7da8  (78 bytes)
DATA_7D5A:
	defb 074h,07dh,07eh,07dh,088h,07dh,092h,07dh,0c8h,038h,020h,020h,013h,000h,033h,025h	; 7d5a  t}~}.}.}.8  ..3%
	defb 034h,000h,02dh,021h,034h,023h,028h,020h,020h,0ffh,02ch,039h,011h,033h,034h,000h	; 7d6a  4.-!4#(  .,9.34.
	defb 033h,025h,034h,0ffh,02ch,039h,012h,02eh,024h,000h,033h,025h,034h,0ffh,02ch,039h	; 7d7a  3%4.,9..$.3%4.,9
	defb 013h,032h,024h,000h,033h,025h,034h,0ffh,02ch,039h,014h,034h,028h,000h,033h,025h	; 7d8a  .2$.3%4.,9.4(.3%
	defb 034h,0ffh,02bh,039h,026h,029h,02eh,021h,02ch,000h,033h,025h,034h,0ffh	; 7d9a  4.+9&).!,.3%4.

; ======================================================================
; CODIGO 0x7da8..0x7dca  (34 bytes)
; ======================================================================


L_7DA8:
	ld a,(0e003h)		;7da8
	and 00fh		;7dab
	ret nz			;7dad
L_7DAE:
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
; DATOS sin identificar  0x7dca..0x7e5a  (144 bytes)
DATA_7DCA:
	defb 0d2h,07dh,0f6h,07dh,01ah,07eh,03ah,07eh,02dh,03ah,09fh,0a0h,0b2h,0b3h,000h,000h	; 7dca  .}.}.~:~-:......
	defb 0feh,04dh,03ah,0a1h,0b8h,0b9h,0a2h,0a5h,000h,0feh,06dh,03ah,0a3h,028h,0a4h,0b4h	; 7dda  .M:.......m:.(..
	defb 0a6h,000h,0feh,08dh,03ah,0a7h,0a8h,0a9h,0b5h,0b6h,0b7h,0ffh,02dh,03ah,000h,000h	; 7dea  ....:.......-:..
	defb 0e0h,0dfh,0cdh,0cch,0feh,04dh,03ah,000h,0d2h,0cfh,0e6h,0e5h,0ceh,0feh,06dh,03ah	; 7dfa  .....M:.......m:
	defb 000h,0d3h,0e1h,0d1h,028h,0d0h,0feh,08dh,03ah,0e4h,0e3h,0e2h,0d6h,0d5h,0d4h,0ffh	; 7e0a  ....(...:.......
	defb 02dh,03ah,093h,053h,041h,0feh,04dh,03ah,043h,054h,028h,042h,0feh,06ch,03ah,047h	; 7e1a  -:.SA.M:CT(B.l:G
	defb 046h,028h,045h,044h,091h,0feh,08bh,03ah,056h,055h,04bh,04ah,049h,048h,000h,0ffh	; 7e2a  F(ED...:VUKJIH..
	defb 02dh,03ah,093h,053h,041h,0feh,04dh,03ah,043h,054h,028h,042h,0feh,06ch,03ah,047h	; 7e3a  -:.SA.M:CT(B.l:G
	defb 046h,028h,045h,044h,000h,0feh,08bh,03ah,056h,055h,04bh,04ah,049h,048h,092h,0ffh	; 7e4a  F(ED...:VUKJIH..

; ======================================================================
; CODIGO 0x7e5a..0x7e8e  (52 bytes)
; ======================================================================


L_7E5A:
	call L_7ABF		;7e5a
	ld hl,0ed00h		;7e5d
	ld de,0ed01h		;7e60
	ld bc,002feh		;7e63
	ld (hl),0ebh		;7e66
	ldir		;7e68
	ld hl,0ed61h		;7e6a
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
	call esconde_los_sprites		;7e7b
	jp vuelca_la_pantalla		;7e7e
L_7E81:
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
; DATOS sin identificar  0x7e8e..0x7f1a  (140 bytes)
DATA_7E8E:
	defb 0c8h,038h,000h,000h,000h,027h,021h,02dh,025h,000h,000h,02fh,036h,025h,032h,000h	; 7e8e  .8...'!-%../6%2.
	defb 000h,000h,0feh,0cah,039h,023h,02fh,02eh,034h,029h,02eh,035h,025h,020h,020h,026h	; 7e9e  ....9#/.4).5%  &
	defb 015h,0ffh,068h,039h,028h,029h,020h,033h,023h,02fh,032h,025h,0feh,0cch,039h,032h	; 7eae  ..h9() 3#/2%..92
	defb 025h,033h,034h,0feh,0cch,038h,033h,034h,021h,027h,025h,020h,0feh,028h,039h,011h	; 7ebe  %34..834!'% .(9.
	defb 030h,020h,033h,023h,02fh,032h,025h,0ffh,088h,0edh,020h,020h,013h,000h,033h,025h	; 7ece  0 3#/2%...  ..3%
	defb 034h,000h,02dh,021h,034h,023h,028h,020h,020h,0feh,0edh,0edh,011h,033h,034h,000h	; 7ede  4.-!4#(  ....34.
	defb 033h,025h,034h,0feh,02dh,0eeh,012h,02eh,024h,000h,033h,025h,034h,0ffh,06dh,0eeh	; 7eee  3%4.-...$.3%4.m.
	defb 013h,032h,024h,000h,033h,025h,034h,0feh,0adh,0eeh,014h,034h,028h,000h,033h,025h	; 7efe  .2$.3%4....4(.3%
	defb 034h,0ffh,026h,029h,02eh,021h,02ch,000h,033h,025h,034h,0ffh	; 7f0e  4.&).!,.3%4.

; ======================================================================
; CODIGO 0x7f1a..0x7fcc  (178 bytes)
; ======================================================================


L_7F1A:
	ld a,01dh		;7f1a
	call toca_sonido		;7f1c
	call L_7E5A		;7f1f
	call L_80C7		;7f22
	call L_8022		;7f25
	ld de,07fcch		;7f28
	jp pinta_guion		;7f2b
L_7F2E:
	call L_80E9		;7f2e
	ld a,(0e008h)		;7f31
	bit 4,a		;7f34
	jr nz,L_7F98		;7f36
	call L_7F64		;7f38
	call L_7F8F		;7f3b
	pop hl			;7f3e
	ret			;7f3f
L_7F40:
	ld a,(0e003h)		;7f40
	bit 2,a		;7f43
	ld de,07fcch		;7f45
	jp z,pinta_guion		;7f48
	call L_7FA7		;7f4b
	inc hl			;7f4e
	inc hl			;7f4f
	ld b,008h		;7f50
L_7F52:
	xor a			;7f52
	call 0004dh		;7f53   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;7f56
	djnz L_7F52		;7f57
	ret			;7f59
L_7F5A:
	ld hl,03800h		;7f5a
	ld bc,00300h		;7f5d
	xor a			;7f60
	jp 00056h		;7f61   ; BIOS FILVRM - Fills VRAM with value
L_7F64:
	ld hl,0e103h		;7f64
	ld a,(0e008h)		;7f67
	rrca			;7f6a
	jr c,L_7F71		;7f6b
	rrca			;7f6d
	jr c,L_7F7D		;7f6e
	ret			;7f70
L_7F71:
	call L_7F8A		;7f71
	ld a,(hl)			;7f74
	or a			;7f75
	jr z,L_7F7A		;7f76
	dec (hl)			;7f78
	ret			;7f79
L_7F7A:
	ld (hl),004h		;7f7a
	ret			;7f7c
L_7F7D:
	call L_7F8A		;7f7d
	ld a,(hl)			;7f80
	cp 004h		;7f81
	jr z,L_7F87		;7f83
	inc (hl)			;7f85
	ret			;7f86
L_7F87:
	ld (hl),000h		;7f87
	ret			;7f89
L_7F8A:
	ld a,003h		;7f8a
	jp toca_sonido		;7f8c
L_7F8F:
	call L_7FB6		;7f8f
	ld a,(0e003h)		;7f92
	bit 3,a		;7f95
	ret z			;7f97
L_7F98:
	call L_7FA7		;7f98
	ld a,01bh		;7f9b
	call 0004dh		;7f9d   ; BIOS WRTVRM - Writes data in VRAM
	inc hl			;7fa0
	ld a,01ch		;7fa1
	call 0004dh		;7fa3   ; BIOS WRTVRM - Writes data in VRAM
	ret			;7fa6
L_7FA7:
	ld a,(0e103h)		;7fa7
	ld b,a			;7faa
	ld hl,00040h		;7fab
	call multiplica_hl		;7fae
	ld de,038aah		;7fb1
	add hl,de			;7fb4
	ret			;7fb5
L_7FB6:
	ld hl,038aah		;7fb6
L_7FB9:
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
; DATOS sin identificar  0x7fcc..0x7ffe  (50 bytes)
DATA_7FCC:
	defb 0adh,038h,02ch,025h,036h,025h,02ch,000h,011h,0feh,0edh,038h,02ch,025h,036h,025h	; 7fcc  .8,%6%,....8,%6%
	defb 02ch,000h,012h,0feh,02dh,039h,02ch,025h,036h,025h,02ch,000h,013h,0feh,06dh,039h	; 7fdc  ,...-9,%6%,...m9
	defb 02ch,025h,036h,025h,02ch,000h,014h,0feh,0adh,039h,02ch,025h,036h,025h,02ch,000h	; 7fec  ,%6%,....9,%6%,.
	defb 015h,0ffh	; 7ffc

; ======================================================================
; CODIGO 0x7ffe..0x8083  (133 bytes)
; ======================================================================


L_7FFE:
	ld hl,00000h		;7ffe
	ld (0e600h),hl		;8001
	ld a,01dh		;8004
	call toca_sonido		;8006
	call L_7E5A		;8009
	call L_80B3		;800c
	ld de,08083h		;800f
	call pinta_guion		;8012
	call L_8022		;8015
	ld hl,0e103h		;8018
	ld a,(hl)			;801b
	cp 002h		;801c
	ret c			;801e
	ld (hl),000h		;801f
	ret			;8021
L_8022:
	ld a,00eh		;8022
	ld (0e347h),a		;8024
	ret			;8027
L_8028:
	call L_8113		;8028
	call L_80E9		;802b
	call L_803D		;802e
	call L_8054		;8031
	ld a,(0e008h)		;8034
	bit 4,a		;8037
	jr nz,L_8060		;8039
	pop hl			;803b
	ret			;803c
L_803D:
	ld hl,0e103h		;803d
	ld a,(0e008h)		;8040
	ld b,a			;8043
	and 003h		;8044
	jr nz,L_804D		;8046
	ld a,b			;8048
	and 00ch		;8049
	ret z			;804b
	inc hl			;804c
L_804D:
	ld a,(hl)			;804d
	xor 001h		;804e
	ld (hl),a			;8050
	jp L_7F8A		;8051
L_8054:
	ld hl,038aah		;8054
	call L_7FB9		;8057
	ld a,(0e003h)		;805a
	bit 3,a		;805d
	ret z			;805f
L_8060:
	ld de,0e103h		;8060
	ld hl,038aah		;8063
	call L_806D		;8066
	inc de			;8069
	ld hl,0396ah		;806a
L_806D:
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
; DATOS sin identificar  0x8083..0x80b3  (48 bytes)
DATA_8083:
	defb 0adh,038h,02ch,025h,036h,025h,02ch,000h,011h,0feh,0edh,038h,02ch,025h,036h,025h	; 8083  .8,%6%,....8,%6%
	defb 02ch,000h,012h,0feh,06dh,039h,013h,000h,033h,025h,034h,000h,02dh,021h,034h,023h	; 8093  ,...m9..3%4.-!4#
	defb 028h,0feh,0adh,039h,015h,000h,033h,025h,034h,000h,02dh,021h,034h,023h,028h,0ffh	; 80a3  (..9..3%4.-!4#(.

; ======================================================================
; CODIGO 0x80b3..0x8153  (160 bytes)
; ======================================================================


L_80B3:
	call L_80DD		;80b3
	call L_813B		;80b6
	ld hl,0508bh		;80b9
	ld (0ec80h),hl		;80bc
	ld de,08184h		;80bf
	call pinta_guion		;80c2
	jr L_80CD		;80c5
L_80C7:
	call L_80DD		;80c7
	call L_813B		;80ca
L_80CD:
	ld hl,0a08bh		;80cd
	ld (0ec84h),hl		;80d0
	ld de,08164h		;80d3
	call pinta_guion		;80d6
	call L_8147		;80d9
	ret			;80dc
L_80DD:
	ld de,0be63h		;80dd
	call guion_rle		;80e0
	ld de,0bfa5h		;80e3
	jp guion_rle		;80e6
L_80E9:
	ld hl,0e347h		;80e9
	dec (hl)			;80ec
	ret nz			;80ed
	ld (hl),00eh		;80ee
	inc hl			;80f0
	ld a,(hl)			;80f1
	xor 001h		;80f2
	ld (hl),a			;80f4
	jr z,L_8104		;80f5
	ld de,081a4h		;80f7
	call pinta_guion		;80fa
	ld a,0e0h		;80fd
	ld (0ec8ch),a		;80ff
	jr L_8110		;8102
L_8104:
	ld de,081aeh		;8104
	call pinta_guion		;8107
	ld hl,08097h		;810a
	ld (0ec8ch),hl		;810d
L_8110:
	jp L_8147		;8110
L_8113:
	ld hl,0e347h		;8113
	ld a,(hl)			;8116
	cp 00eh		;8117
	ret nz			;8119
	inc hl			;811a
	ld a,(hl)			;811b
	or a			;811c
	jr z,L_812C		;811d
	ld de,081b8h		;811f
	call pinta_guion		;8122
	ld a,0e0h		;8125
	ld (0ec88h),a		;8127
	jr L_8138		;812a
L_812C:
	ld de,081c2h		;812c
	call pinta_guion		;812f
	ld hl,07097h		;8132
	ld (0ec88h),hl		;8135
L_8138:
	jp L_8147		;8138
L_813B:
	ld hl,08153h		;813b
	ld de,0ec80h		;813e
	ld bc,00011h		;8141
	ldir		;8144
	ret			;8146
L_8147:
	ld hl,03b00h		;8147
	ld de,0ec80h		;814a
	ld bc,00011h		;814d
	jp copia_a_vram		;8150

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8153..0x81cc  (121 bytes)
DATA_8153:
	defb 0e0h,000h,000h,00ah,0e0h,000h,004h,00ah,0e0h,000h,008h,00ah,0e0h,000h,00ch,00ah	; 8153  ................
	defb 0d0h,031h,03ah,000h,054h,067h,066h,000h,0feh,051h,03ah,059h,058h,057h,056h,055h	; 8163  .1:.Tgf..Q:YXWVU
	defb 0feh,071h,03ah,063h,05ch,05ch,05bh,05ah,0feh,091h,03ah,064h,065h,060h,05fh,05eh	; 8173  .q:c\\[Z..:de`_^
	defb 0ffh,02ah,03ah,000h,052h,053h,040h,000h,0feh,04ah,03ah,041h,042h,043h,044h,045h	; 8183  .*:.RS@..J:ABCDE
	defb 0feh,06ah,03ah,046h,047h,048h,048h,04fh,0feh,08ah,03ah,04ah,04bh,04ch,051h,050h	; 8193  .j:FGHHO..:JKLQP
	defb 0ffh,071h,03ah,063h,05ch,0feh,091h,03ah,064h,065h,0ffh,071h,03ah,05dh,05ch,0feh	; 81a3  .q:c\..:de.q:]\.
	defb 091h,03ah,062h,061h,0ffh,06dh,03ah,048h,04fh,0feh,08dh,03ah,051h,050h,0ffh,06dh	; 81b3  .:ba.m:HO..:QP.m
	defb 03ah,048h,049h,0feh,08dh,03ah,04dh,04eh,0ffh	; 81c3  :HI..:MN.

; ======================================================================
; CODIGO 0x81cc..0x821a  (78 bytes)
; ======================================================================


L_81CC:
	ld hl,0e000h		;81cc
	ld a,(hl)			;81cf
	cp 005h		;81d0
	ret nz			;81d2
	inc hl			;81d3
	ld a,(hl)			;81d4
	or a			;81d5
	ret nz			;81d6
	ld a,(0e202h)		;81d7
	cp 00eh		;81da
	jr nz,L_81E3		;81dc
	ld hl,0e212h		;81de
	jr L_81ED		;81e1
L_81E3:
	ld a,(0e212h)		;81e3
	cp 00eh		;81e6
	jr nz,L_81F5		;81e8
	ld hl,0e202h		;81ea
L_81ED:
	ld a,(hl)			;81ed
	or a			;81ee
	jr z,$+78		;81ef
	cp 00eh		;81f1
	jr z,$+51		;81f3
L_81F5:
	ld hl,0e113h		;81f5
	ld a,(hl)			;81f8
	or a			;81f9
	jr z,L_8204		;81fa
	ld hl,0e35ch		;81fc
	ld a,(hl)			;81ff
	or a			;8200
	ret nz			;8201
	ld a,001h		;8202
L_8204:
	ld (0e333h),a		;8204
	inc (hl)			;8207
	call L_8320		;8208
	jr nz,$+41		;820b
	call L_8330		;820d
	ld (hl),00eh		;8210
	ld a,008h		;8212
	call suma_a_a_hl		;8214
	ld (hl),00eh		;8217
	ret			;8219

; ----------------------------------------------------------------------
; DATOS sin identificar  0x821a..0x8226  (12 bytes)
DATA_821A:
	defb 03ah,010h,0e1h,0b7h,020h,014h,03ah,020h,0e1h,0b7h,020h,00eh	; 821a  :... .: .. .

; ======================================================================
; CODIGO 0x8226..0x8275  (79 bytes)
; ======================================================================


L_8226:
	ld a,001h		;8226
	ld (0e342h),a		;8228
	ld (0e32dh),a		;822b
	call L_8242		;822e
	jp z,L_8905		;8231
L_8234:
	call L_8320		;8234
	jr z,L_823D		;8237
	dec (hl)			;8239
	jp pinta_las_vidas_de_los_dos		;823a
L_823D:
	call L_8242		;823d
	jr $+108		;8240
L_8242:
	push bc			;8242
	ld a,035h		;8243
	call toca_sonido		;8245
	call L_7E81		;8248
	pop bc			;824b
	ret			;824c
L_824D:
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
	jp z,L_6C0D		;826f
	jp L_6C5C		;8272

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8275..0x82ac  (55 bytes)
DATA_8275:
	defb 03ah,032h,0e3h,0b7h,011h,002h,0e2h,026h,000h,028h,005h,011h,012h,0e2h,026h,0b0h	; 8275  :2.....&.(....&.
	defb 01ah,0feh,003h,0d0h,03ah,038h,0e3h,0c6h,00ch,047h,012h,013h,03eh,064h,012h,013h	; 8285  ....:8...G..>d..
	defb 013h,013h,07ch,012h,03eh,004h,0cdh,04fh,040h,078h,012h,013h,03eh,064h,012h,013h	; 8295  ..|.>..O@x..>d..
	defb 013h,013h,07ch,0c6h,010h,012h,0c9h	; 82a5

; ======================================================================
; CODIGO 0x82ac..0x833c  (144 bytes)
; ======================================================================


L_82AC:
	ld a,(0e333h)		;82ac
	ld b,a			;82af
	push bc			;82b0
	call pinta_las_vidas_de_los_dos		;82b1
	pop bc			;82b4
L_82B5:
	ld a,b			;82b5
	xor 001h		;82b6
	ld (0e33ah),a		;82b8
L_82BB:
	call L_4488		;82bb
	ld a,(0e33ah)		;82be
	ld hl,0e600h		;82c1
	ld b,001h		;82c4
	or a			;82c6
	jr z,L_82CB		;82c7
	inc hl			;82c9
	inc b			;82ca
L_82CB:
	inc (hl)			;82cb
	call L_8350		;82cc
	ld hl,0ecb8h		;82cf
	dec (hl)			;82d2
	jp z,L_82DC		;82d3
	ld a,001h		;82d6
	ld (0e00dh),a		;82d8
	ret			;82db
L_82DC:
	ld a,(0e320h)		;82dc
	or a			;82df
	ret nz			;82e0
L_82E1:
	ld hl,0e000h		;82e1
	ld (hl),006h		;82e4
	jp musica_de_game_over		;82e6
L_82E9:
	pop hl			;82e9
	call L_82F6		;82ea
	pop hl			;82ed
	ld a,001h		;82ee
	ld (0e342h),a		;82f0
	jp L_8905		;82f3
L_82F6:
	ld hl,0e349h		;82f6
	ld c,040h		;82f9
	call L_830E		;82fb
	ld a,(hl)			;82fe
	inc hl			;82ff
	push af			;8300
	ld c,020h		;8301
	call L_830E		;8303
	pop af			;8306
	cp (hl)			;8307
	ret z			;8308
	ld b,001h		;8309
	ret nc			;830b
	dec b			;830c
	ret			;830d
L_830E:
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
L_8320:
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
L_8330:
	ld a,(0e333h)		;8330
	ld hl,0e202h		;8333
	or a			;8336
	ret z			;8337
	ld hl,0e212h		;8338
	ret			;833b

; ----------------------------------------------------------------------
; DATOS sin identificar  0x833c..0x8350  (20 bytes)
DATA_833C:
	defb 0cdh,045h,083h,0cdh,030h,083h,07eh,0feh,004h,0f5h,03ah,033h,0e3h,0eeh,001h,032h	; 833c  .E..0.~...:3...2
	defb 033h,0e3h,0f1h,0c9h	; 834c

; ======================================================================
; CODIGO 0x8350..0x837f  (47 bytes)
; ======================================================================


L_8350:
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
L_836A:
	ld hl,027e0h		;836a
	ld de,08384h		;836d
	ld bc,00010h		;8370
	call copia_a_los_tres_bancos		;8373
	ld hl,007e0h		;8376
	ld de,0837fh		;8379
	jp guion_rle_en_tres_bancos		;837c

; ----------------------------------------------------------------------
; DATOS sin identificar  0x837f..0x8394  (21 bytes)
DATA_837F:
	defb 008h,0d0h,008h,070h,000h,000h,066h,0ffh,0ffh,0ffh,07eh,03ch,018h,000h,066h,0ffh	; 837f  ...p..f...~<..f.
	defb 0ffh,0ffh,07eh,03ch,018h	; 838f

; ======================================================================
; CODIGO 0x8394..0x85f9  (613 bytes)
; ======================================================================


L_8394:
	call L_7F5A		;8394
	ld de,0b09ah		;8397
	call guion_rle		;839a
	call borra_los_objetos		;839d
	call borra_la_copia_de_nombres		;83a0
	ld hl,088d8h		;83a3
	ld de,0e200h		;83a6
	ld bc,0004dh		;83a9
	ldir		;83ac
	ret			;83ae
L_83AF:
	ld a,020h		;83af
	call toca_sonido		;83b1
	ld de,08741h		;83b4
	call L_871C		;83b7
	ld hl,0508fh		;83ba
	ld (0e200h),hl		;83bd
	ld hl,0589fh		;83c0
	ld (0e204h),hl		;83c3
	ld hl,0886fh		;83c6
	ld (0e208h),hl		;83c9
	ld hl,0807fh		;83cc
	ld (0e20ch),hl		;83cf
	call L_8735		;83d2
	ld a,080h		;83d5
	jp espera_a_y_sigue		;83d7
L_83DA:
	call vuelca_la_pantalla		;83da
	call L_8577		;83dd
	ld hl,0e004h		;83e0
	dec (hl)			;83e3
	ret nz			;83e4
	ld hl,08d00h		;83e5
	ld (0e210h),hl		;83e8
	jp espera_a_y_sigue		;83eb
L_83EE:
	call vuelca_la_pantalla		;83ee
	call L_8577		;83f1
	ld a,(0e012h)		;83f4
	or a			;83f7
	ret nz			;83f8
	call L_85C4		;83f9
	ld hl,0e210h		;83fc
	inc (hl)			;83ff
	inc (hl)			;8400
	inc (hl)			;8401
	ld a,(hl)			;8402
	cp 075h		;8403
	ret c			;8405
	ld a,001h		;8406
	call toca_sonido		;8408
	ld a,001h		;840b
	ld (0e33dh),a		;840d
	ld hl,l85f6h		;8410
	ld (0e33eh),hl		;8413
	jp espera_a_y_sigue		;8416
L_8419:
	call L_85C4		;8419
	call vuelca_la_pantalla		;841c
	ld a,(0e032h)		;841f
	or a			;8422
	jr z,L_8428		;8423
	call L_8577		;8425
L_8428:
	ld de,0e210h		;8428
	call L_8596		;842b
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
	call L_871C		;8447
	call vuelca_la_pantalla		;844a
	call L_8735		;844d
	ld a,060h		;8450
	jp espera_a_y_sigue		;8452
L_8455:
	ld hl,0e004h		;8455
	dec (hl)			;8458
	ret nz			;8459
	ld a,013h		;845a
	jp espera_a_y_sigue		;845c
L_845F:
	call vuelca_la_pantalla		;845f
	ld hl,0e004h		;8462
	dec (hl)			;8465
	ld a,(hl)			;8466
	jr z,L_849A		;8467
	sub 012h		;8469
	neg		;846b
	ld b,a			;846d
	ld hl,00020h		;846e
	call multiplica_hl		;8471
	ld de,0ec05h		;8474
	add hl,de			;8477
	call L_856C		;8478
	call pinta_el_rotulo_de_qbert		;847b
	ld a,(0e004h)		;847e
	ld de,086d6h		;8481
	dec a			;8484
	jr z,L_8497		;8485
	ld de,086d0h		;8487
	dec a			;848a
	jr z,L_8497		;848b
	dec a			;848d
	ret nz			;848e
	ld a,0e0h		;848f
	ld (0e208h),a		;8491
	jp L_8735		;8494
L_8497:
	jp L_871C		;8497
L_849A:
	ld a,02fh		;849a
	call toca_sonido		;849c
	ld de,0880fh		;849f
	call L_871C		;84a2
	call vuelca_la_pantalla		;84a5
	ld a,0e0h		;84a8
	ld (0e21ch),a		;84aa
	call L_8735		;84ad
	ld a,050h		;84b0
	jp espera_a_y_sigue		;84b2
L_84B5:
	ld hl,0e004h		;84b5
	dec (hl)			;84b8
	ret nz			;84b9
	ld de,086d6h		;84ba
	call L_8731		;84bd
	ld de,086f6h		;84c0
	call L_871C		;84c3
	ld hl,0ee25h		;84c6
	call pinta_el_rotulo_de_qbert		;84c9
	ld de,086d0h		;84cc
	call L_871C		;84cf
	ld hl,0886fh		;84d2
	ld (0e208h),hl		;84d5
	call L_8735		;84d8
	ld a,023h		;84db
	call toca_sonido		;84dd
	ld a,008h		;84e0
	jp espera_a_y_sigue		;84e2
L_84E5:
	call vuelca_la_pantalla		;84e5
	ld hl,0e004h		;84e8
	dec (hl)			;84eb
	jr z,L_850E		;84ec
	ld b,(hl)			;84ee
	ld hl,00020h		;84ef
	call multiplica_hl		;84f2
	ld de,0ee05h		;84f5
	add hl,de			;84f8
	call L_856C		;84f9
	call L_856C		;84fc
	ld de,0fee0h		;84ff
	add hl,de			;8502
	push hl			;8503
	ld de,086f6h		;8504
	call L_871C		;8507
	pop hl			;850a
	jp pinta_el_rotulo_de_qbert		;850b
L_850E:
	call L_8547		;850e
	call vuelca_la_pantalla		;8511
	ld a,001h		;8514
	ld (0e33dh),a		;8516
	ld hl,08618h		;8519
	ld (0e33eh),hl		;851c
	ld hl,000f6h		;851f
	ld (0e228h),hl		;8522
	jp espera_a_y_sigue		;8525
L_8528:
	call L_8735		;8528
	ld de,0e228h		;852b
	call L_8596		;852e
	ld a,(0e33dh)		;8531
	cp 080h		;8534
	ret nz			;8536
	ld a,008h		;8537
	ld (0e22bh),a		;8539
	call L_8735		;853c
	ld a,001h		;853f
	ld (0e115h),a		;8541
	jp espera_a_y_sigue		;8544
L_8547:
	ld de,08849h		;8547
	call L_871C		;854a
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
L_856C:
	ld d,h			;856c
	ld e,l			;856d
	inc de			;856e
	ld (hl),000h		;856f
	ld bc,00020h		;8571
	ldir		;8574
	ret			;8576
L_8577:
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
	call L_871C		;8592
	ret			;8595
L_8596:
	ld hl,0e33dh		;8596
	ld a,(hl)			;8599
	cp 080h		;859a
	ret z			;859c
	dec (hl)			;859d
	ld hl,(0e33eh)		;859e
	jr nz,L_85B0		;85a1
	ld a,003h		;85a3
	call suma_a_a_hl		;85a5
	ld (0e33eh),hl		;85a8
	ld a,(hl)			;85ab
	ld (0e33dh),a		;85ac
	ret			;85af
L_85B0:
	inc hl			;85b0
	ld a,(de)			;85b1
	add a,(hl)			;85b2
	ld (de),a			;85b3
	inc hl			;85b4
	inc de			;85b5
	ld a,(de)			;85b6
	add a,(hl)			;85b7
	ld (de),a			;85b8
	cp 0fch		;85b9
	ret c			;85bb
	ld a,0e0h		;85bc
	ld (0e210h),a		;85be
	jp L_85C4		;85c1
L_85C4:
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
	jp L_8735		;85f6

; ----------------------------------------------------------------------
; DATOS sin identificar  0x85f9..0x871c  (291 bytes)
DATA_85F9:
	defb 008h,0feh,002h,008h,0ffh,002h,008h,000h,002h,008h,001h,002h,008h,002h,001h,010h	; 85f9  ................
	defb 003h,001h,008h,0feh,001h,008h,0ffh,001h,008h,000h,001h,008h,001h,001h,008h,002h	; 8609  ................
	defb 001h,080h,010h,002h,003h,008h,003h,003h,008h,002h,001h,008h,0feh,001h,008h,0ffh	; 8619  ................
	defb 001h,008h,000h,001h,008h,001h,001h,080h,037h,086h,06ah,086h,09dh,086h,0eeh,0eeh	; 8629  ........7.j.....
	defb 098h,099h,0feh,00eh,0efh,011h,012h,0feh,0d4h,0eeh,0a0h,08dh,0feh,0f4h,0eeh,08eh	; 8639  ................
	defb 08fh,0feh,02fh,0efh,021h,0b0h,0feh,04fh,0efh,0abh,0afh,0feh,090h,0efh,08dh,07bh	; 8649  ../.!..O.......{
	defb 060h,08fh,0feh,0b0h,0efh,08ah,089h,08eh,078h,0feh,0d0h,0efh,0a4h,095h,094h,023h	; 8659  `.......x......#
	defb 0ffh,0eeh,0eeh,09ah,09bh,0feh,00eh,0efh,013h,014h,0feh,0d4h,0eeh,0a0h,0adh,0feh	; 8669  ................
	defb 0f4h,0eeh,0aeh,0afh,0feh,02fh,0efh,0adh,098h,0feh,04fh,0efh,0a2h,0a6h,0feh,090h	; 8679  ...../....O.....
	defb 0efh,08dh,07bh,059h,08fh,0feh,0b0h,0efh,02ah,088h,05ah,07ah,0feh,0d0h,0efh,024h	; 8689  ..{Y....*.Zz...$
	defb 02fh,087h,023h,0ffh,0eeh,0eeh,09ch,09dh,0feh,00eh,0efh,015h,016h,0feh,0d4h,0eeh	; 8699  /.#.............
	defb 0a5h,0a6h,0feh,0f4h,0eeh,0a7h,0a8h,0feh,02fh,0efh,0a7h,034h,0feh,04fh,0efh,0ach	; 86a9  ......../..4.O..
	defb 0a5h,0feh,090h,0efh,08dh,07bh,059h,08fh,0feh,0b0h,0efh,02ah,088h,090h,079h,0feh	; 86b9  .....{Y....*..y.
	defb 0d0h,0efh,024h,02fh,093h,0a3h,0ffh,00ah,0efh,0b5h,0b6h,0b7h,0ffh,005h,0efh,0b1h	; 86c9  ..$/............
	defb 0b1h,0b1h,0b1h,0b1h,0b2h,0b3h,0b4h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h	; 86d9  ................
	defb 0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0feh,02ah,0efh,0b5h,0b6h,0b7h,0ffh,0cbh,0eeh,092h	; 86e9  .......*........
	defb 097h,09fh,09fh,09eh,095h,094h,0feh,0ebh,0eeh,091h,096h,044h,098h,099h,090h,093h	; 86f9  ...........D....
	defb 0feh,00bh,0efh,00ch,017h,002h,011h,012h,058h,007h,0feh,02ah,0efh,003h,00fh,018h	; 8709  ........X..*....
	defb 020h,020h,0ffh	; 8719

; ======================================================================
; CODIGO 0x871c..0x8741  (37 bytes)
; ======================================================================


L_871C:
	ld c,0ffh		;871c
L_871E:
	ex de,hl			;871e
	ld e,(hl)			;871f
	inc hl			;8720
	ld d,(hl)			;8721
	ex de,hl			;8722
	inc de			;8723
L_8724:
	ld a,(de)			;8724
	inc de			;8725
	ld b,a			;8726
	inc b			;8727
	ret z			;8728
	inc b			;8729
	jr z,L_871E		;872a
	and c			;872c
	ld (hl),a			;872d
	inc hl			;872e
	jr L_8724		;872f
L_8731:
	ld c,000h		;8731
	jr L_871E		;8733
L_8735:
	ld hl,03b00h		;8735
	ld de,0e200h		;8738
	ld bc,0002dh		;873b
	jp copia_a_vram		;873e

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8741..0x8905  (452 bytes)
DATA_8741:
	defb 0cbh,0eeh,092h,097h,09fh,09fh,09eh,095h,094h,000h,0a1h,0a0h,08dh,0a2h,0feh,0ebh	; 8741  ................
	defb 0eeh,091h,096h,044h,098h,099h,090h,093h,000h,0a3h,08eh,08fh,0a4h,0feh,00bh,0efh	; 8751  ...D............
	defb 00ch,017h,002h,011h,012h,058h,096h,06ah,037h,032h,031h,000h,0feh,02ah,0efh,003h	; 8761  .....X.j721..*..
	defb 00fh,018h,020h,020h,021h,0b0h,033h,05dh,069h,0feh,04ah,0efh,00bh,00dh,01ch,01dh	; 8771  ..  !.3]i.J.....
	defb 01fh,0abh,0afh,033h,05ch,05eh,036h,0feh,06bh,0efh,00eh,019h,01eh,01bh,0aeh,0aah	; 8781  ...3\^6.k.......
	defb 033h,05bh,05fh,068h,0feh,08ah,0efh,009h,005h,002h,000h,000h,083h,08dh,07bh,060h	; 8791  3[_h..........{`
	defb 08fh,082h,0feh,0abh,0efh,004h,005h,010h,000h,027h,08ah,089h,08eh,078h,026h,0feh	; 87a1  .........'...x&.
	defb 0cfh,0efh,025h,0a4h,095h,094h,023h,022h,0feh,0f0h,0efh,02bh,02ch,02dh,02eh,008h	; 87b1  ..%...#"...+,-..
	defb 00ah,0ffh,0d4h,0eeh,0a9h,0aah,0feh,0f4h,0eeh,0abh,0ach,0feh,010h,0efh,057h,097h	; 87c1  ..............W.
	defb 06bh,06ch,032h,031h,0feh,02fh,0efh,021h,038h,039h,03ah,06dh,06eh,0feh,04fh,0efh	; 87d1  kl21./.!89:mn.O.
	defb 0a9h,03bh,03ch,033h,03dh,06fh,0feh,06fh,0efh,0a8h,042h,041h,040h,03fh,066h,067h	; 87e1  .;<3=o.o..BA@?fg
	defb 03eh,0feh,08fh,0efh,084h,08bh,07ch,07dh,08ch,086h,035h,0feh,0afh,0efh,027h,02ah	; 87f1  >.....|}..5...'*
	defb 029h,028h,028h,026h,0feh,0cfh,0efh,025h,024h,02fh,030h,023h,022h,0ffh,02fh,0efh	; 8801  )((&...%$/0#"./.
	defb 021h,09fh,09ah,071h,063h,043h,0feh,04fh,0efh,0a1h,0a0h,061h,062h,070h,044h,0feh	; 8811  !..qcC.O...abpD.
	defb 06fh,0efh,09ch,045h,064h,065h,046h,047h,000h,000h,0feh,08fh,0efh,085h,091h,080h	; 8821  o..EdeFG........
	defb 081h,092h,0b8h,000h,000h,0feh,0afh,0efh,027h,02ah,029h,028h,028h,026h,0feh,0cfh	; 8831  ........'*)((&..
	defb 0efh,025h,024h,02fh,030h,023h,022h,0ffh,0cbh,0eeh,092h,097h,09fh,09fh,09eh,095h	; 8841  .%$/0#".........
	defb 094h,000h,0a1h,089h,08ah,0a2h,0feh,0ebh,0eeh,091h,096h,044h,09ah,09bh,090h,093h	; 8851  ...........D....
	defb 000h,0a3h,08bh,08ch,0a4h,0feh,00bh,0efh,00ch,017h,002h,013h,014h,056h,099h,072h	; 8861  .............V.r
	defb 048h,032h,031h,000h,0feh,02ah,0efh,003h,00fh,018h,020h,020h,09dh,049h,04ah,04bh	; 8871  H21..*....  .IJK
	defb 04ch,04dh,04eh,000h,0feh,04ah,0efh,00bh,00dh,01ch,01dh,01fh,09eh,033h,04fh,055h	; 8881  LMN..J.......3OU
	defb 033h,074h,073h,000h,0feh,06bh,0efh,00eh,019h,01eh,01bh,09bh,050h,051h,052h,053h	; 8891  3ts..k......PQRS
	defb 075h,054h,000h,0feh,08ah,0efh,009h,005h,002h,000h,000h,085h,091h,07eh,07fh,092h	; 88a1  uT...........~..
	defb 0b8h,000h,000h,0feh,0abh,0efh,004h,005h,010h,000h,027h,02ah,029h,028h,028h,026h	; 88b1  ..........'*)((&
	defb 000h,000h,0feh,0cfh,0efh,025h,024h,02fh,030h,023h,022h,000h,000h,0feh,0f0h,0efh	; 88c1  .....%$/0#".....
	defb 02bh,02ch,02dh,02eh,008h,00ah,0ffh,0e0h,000h,000h,007h,0e0h,000h,004h,005h,0e0h	; 88d1  +,-.............
	defb 000h,008h,007h,0e0h,000h,00ch,007h,0e0h,000h,010h,007h,0e0h,000h,014h,004h,0e0h	; 88e1  ................
	defb 000h,018h,005h,0e0h,000h,040h,00ah,0e0h,000h,044h,007h,0e0h,000h,048h,007h,0e0h	; 88f1  .....@...D...H..
	defb 000h,04ch,00ah,0d0h	; 8901

; ======================================================================
; CODIGO 0x8905..0x8b49  (580 bytes)
; ======================================================================


L_8905:
	xor a			;8905
	ld (0e358h),a		;8906
	call borra_la_pantalla		;8909
	call L_8C86		;890c
	call L_7E5A		;890f
	call L_8C7D		;8912
	call L_89A8		;8915
	ld de,08f83h		;8918
	call L_871C		;891b
	ld a,(0e32dh)		;891e
	or a			;8921
	jr nz,L_8980		;8922
	ld de,08f77h		;8924
	call L_871C		;8927
	ld hl,0e349h		;892a
	ld a,(hl)			;892d
	inc hl			;892e
	cp (hl)			;892f
	jr nz,L_8938		;8930
	ld de,08f83h		;8932
	xor a			;8935
	jr L_8943		;8936
L_8938:
	ld de,08f90h		;8938
	ld a,001h		;893b
	jr nc,L_8943		;893d
	ld de,08f9dh		;893f
	inc a			;8942
L_8943:
	ld (0e324h),a		;8943
	call L_871C		;8946
	call L_8CF4		;8949
	ld hl,0ee4ah		;894c
	ld (hl),03ah		;894f
	inc hl			;8951
	ld a,(0e34ah)		;8952
	call L_8D28		;8955
	ld hl,0ee56h		;8958
	ld (hl),03ah		;895b
	inc hl			;895d
	ld a,(0e349h)		;895e
	call L_8D28		;8961
	call vuelca_la_pantalla		;8964
	ld a,(0e324h)		;8967
	ld c,a			;896a
	or a			;896b
	jr z,L_8980		;896c
	ld a,008h		;896e
	ld (0e001h),a		;8970
	push bc			;8973
	call L_8CDC		;8974
	pop bc			;8977
	ld a,c			;8978
	dec a			;8979
	jp z,L_8AAF		;897a
	jp L_8AA7		;897d
L_8980:
	ld a,038h		;8980
	call toca_sonido		;8982
L_8985:
	ld hl,0e340h		;8985
	ld a,r		;8988
	call L_89A1		;898a
	inc hl			;898d
	ld a,(0e003h)		;898e
	call L_89A1		;8991
	ld a,006h		;8994
	ld (0e001h),a		;8996
	ld a,080h		;8999
	ld (0e004h),a		;899b
	jp vuelca_la_pantalla		;899e
L_89A1:
	and 003h		;89a1
	cp 003h		;89a3
	ret z			;89a5
	ld (hl),a			;89a6
	ret			;89a7
L_89A8:
	ld de,08c2ch		;89a8
	call L_871C		;89ab
	call L_8CDC		;89ae
	ld hl,0488bh		;89b1
	ld (0ec80h),hl		;89b4
	ld hl,0a88bh		;89b7
	ld (0ec84h),hl		;89ba
	ld hl,00001h		;89bd
	ld (0e359h),hl		;89c0
	jp L_8CE8		;89c3
L_89C6:
	ld hl,0e004h		;89c6
	ld a,(hl)			;89c9
	or a			;89ca
	jr z,L_89DE		;89cb
	dec (hl)			;89cd
	ret nz			;89ce
	ld hl,0e358h		;89cf
	bit 0,(hl)		;89d2
	ld a,026h		;89d4
	jr z,L_89DA		;89d6
	ld a,04ah		;89d8
L_89DA:
	inc (hl)			;89da
	call toca_sonido		;89db
L_89DE:
	call L_8C3A		;89de
	ld de,08c01h		;89e1
	call L_871C		;89e4
	ld de,08c16h		;89e7
	call L_871C		;89ea
	call L_8B8F		;89ed
	call vuelca_la_pantalla		;89f0
	call L_8CE8		;89f3
	ld hl,0e340h		;89f6
	ld a,(0e330h)		;89f9
	call L_8B2B		;89fc
	inc hl			;89ff
	ld a,(0e009h)		;8a00
	call L_8B2B		;8a03
	ld a,(0e012h)		;8a06
	or a			;8a09
	ret nz			;8a0a
	ld a,03bh		;8a0b
	call toca_sonido		;8a0d
	ld de,08d80h		;8a10
	call L_871C		;8a13
	ld de,08c21h		;8a16
	call L_871C		;8a19
	call L_8CDC		;8a1c
	ld hl,0488dh		;8a1f
	ld (0ec90h),hl		;8a22
	ld hl,0a88dh		;8a25
	ld (0ec94h),hl		;8a28
	call L_8CE8		;8a2b
	call vuelca_la_pantalla		;8a2e
	ld a,040h		;8a31
	jp espera_a_y_sigue		;8a33
L_8A36:
	ld a,(0e012h)		;8a36
	or a			;8a39
	ret nz			;8a3a
	ld a,03eh		;8a3b
	call toca_sonido		;8a3d
	ld de,08dc4h		;8a40
	call L_871C		;8a43
	call L_8CDC		;8a46
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
	call L_8B3C		;8a73
	ld a,(0e341h)		;8a76
	add a,003h		;8a79
	call L_8B3C		;8a7b
	call vuelca_la_pantalla		;8a7e
	call L_8CE8		;8a81
	ld a,080h		;8a84
	jp espera_a_y_sigue		;8a86
L_8A89:
	ld a,(0e012h)		;8a89
	or a			;8a8c
	ret nz			;8a8d
	call L_8CDC		;8a8e
	ld hl,0e340h		;8a91
	ld c,000h		;8a94
	ld a,(hl)			;8a96
	inc hl			;8a97
	ld b,(hl)			;8a98
	cp b			;8a99
	jr z,L_8AD2		;8a9a
	inc c			;8a9c
	inc a			;8a9d
	cp 003h		;8a9e
	jr nz,L_8AA3		;8aa0
	xor a			;8aa2
L_8AA3:
	cp b			;8aa3
	jr z,L_8AAF		;8aa4
	inc c			;8aa6
L_8AA7:
	ld hl,0908fh		;8aa7
	ld (0ecb0h),hl		;8aaa
	jr L_8AB5		;8aad
L_8AAF:
	ld hl,0608fh		;8aaf
	ld (0ecach),hl		;8ab2
L_8AB5:
	ld a,c			;8ab5
	ld (0e324h),a		;8ab6
	ld de,08dc4h		;8ab9
	call L_8731		;8abc
	ld de,08c2ch		;8abf
	call L_871C		;8ac2
	call L_8B5B		;8ac5
	ld a,029h		;8ac8
	call toca_sonido		;8aca
	ld a,000h		;8acd
	jp espera_a_y_sigue		;8acf
L_8AD2:
	ld de,08dc4h		;8ad2
	call L_8731		;8ad5
	call L_8C7D		;8ad8
	call L_89A8		;8adb
	jp L_8985		;8ade
L_8AE1:
	call L_8B55		;8ae1
	call vuelca_la_pantalla		;8ae4
	call L_8CE8		;8ae7
	ld a,(0e012h)		;8aea
	or a			;8aed
	ret nz			;8aee
	xor a			;8aef
	ld (0e32dh),a		;8af0
	ld a,(0e342h)		;8af3
	or a			;8af6
	jr z,L_8B03		;8af7
	ld a,(0e324h)		;8af9
	dec a			;8afc
	xor 001h		;8afd
	ld b,a			;8aff
	jp L_82B5		;8b00
L_8B03:
	ld a,(0e324h)		;8b03
	dec a			;8b06
	xor 001h		;8b07
	ld (0e332h),a		;8b09
	call borra_la_pantalla		;8b0c
	call monta_la_fuente		;8b0f
	call monta_los_graficos_de_la_fase		;8b12
	call dibuja_el_tablero		;8b15
	call L_7ABF		;8b18
	call vuelca_la_pantalla		;8b1b
	call L_824D		;8b1e
	ld a,017h		;8b21
	call toca_sonido		;8b23
	xor a			;8b26
	ld (0e001h),a		;8b27
	ret			;8b2a
L_8B2B:
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
L_8B3C:
	add a,a			;8b3c
	ld hl,08b49h		;8b3d
	call suma_a_a_hl		;8b40
	ld e,(hl)			;8b43
	inc hl			;8b44
	ld d,(hl)			;8b45
	jp L_871C		;8b46

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8b49..0x8b55  (12 bytes)
DATA_8B49:
	defb 02bh,08eh,035h,08eh,03fh,08eh,049h,08eh,053h,08eh,05dh,08eh	; 8b49  +.5.?.I.S.].

; ======================================================================
; CODIGO 0x8b55..0x8b7f  (42 bytes)
; ======================================================================


L_8B55:
	ld a,(0e003h)		;8b55
	and 00fh		;8b58
	ret nz			;8b5a
L_8B5B:
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
	call L_8B72		;8b6c
	pop af			;8b6f
	add a,004h		;8b70
L_8B72:
	ld hl,08b7fh		;8b72
	add a,a			;8b75
	call suma_a_a_hl		;8b76
	ld e,(hl)			;8b79
	inc hl			;8b7a
	ld d,(hl)			;8b7b
	jp L_871C		;8b7c

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8b7f..0x8b8f  (16 bytes)
DATA_8B7F:
	defb 067h,08eh,087h,08eh,0a7h,08eh,0cbh,08eh,0efh,08eh,013h,08fh,037h,08fh,057h,08fh	; 8b7f  g...........7.W.

; ======================================================================
; CODIGO 0x8b8f..0x8bbf  (48 bytes)
; ======================================================================


L_8B8F:
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
	call L_871C		;8ba0
	ld a,0e0h		;8ba3
	ld (0ec88h),a		;8ba5
	ld (0ec8ch),a		;8ba8
	ret			;8bab
L_8BAC:
	ld de,08be0h		;8bac
	call L_871C		;8baf
	ld hl,06897h		;8bb2
	ld (0ec88h),hl		;8bb5
	ld hl,08897h		;8bb8
	ld (0ec8ch),hl		;8bbb
	ret			;8bbe

; ----------------------------------------------------------------------
; DATOS sin identificar  0x8bbf..0x8c3a  (123 bytes)
DATA_8BBF:
	defb 04ch,0efh,059h,058h,000h,000h,000h,000h,022h,023h,0feh,06ch,0efh,05eh,05dh,000h	; 8bbf  L.YX...."#.l.^].
	defb 000h,000h,000h,027h,028h,0feh,08ch,0efh,062h,061h,000h,000h,000h,000h,02bh,02ch	; 8bcf  ...'(...ba....+,
	defb 0ffh,04ch,0efh,059h,066h,000h,000h,000h,000h,030h,023h,0feh,06ch,0efh,05eh,067h	; 8bdf  .L.Yf....0#.l.^g
	defb 000h,000h,000h,000h,031h,028h,0feh,08ch,0efh,069h,068h,000h,000h,000h,000h,032h	; 8bef  ....1(...ih....2
	defb 033h,0ffh,047h,0eeh,02ch,025h,034h,038h,033h,000h,030h,02ch,021h,039h,000h,02ah	; 8bff  3.G.,%483.0,!9.*
	defb 021h,02eh,020h,02bh,025h,02eh,0ffh,0adh,0eeh,02ah,021h,02eh,020h,02bh,025h,02eh	; 8c0f  !. +%....*!. +%.
	defb 04ah,0ffh,0adh,0eeh,000h,030h,02fh,02eh,04bh,000h,000h,000h,0ffh,0aeh,0efh,0ebh	; 8c1f  J....0/.K.......
	defb 0ebh,0ebh,0ebh,0feh,0ceh,0efh,0ebh,0ebh,0ebh,0ebh,0ffh	; 8c2f  ...........

; ======================================================================
; CODIGO 0x8c3a..0x8d16  (220 bytes)
; ======================================================================


L_8C3A:
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
L_8C4F:
	call 0004ah		;8c4f   ; BIOS RDVRM - Reads the content of VRAM
	ex de,hl			;8c52
	call 0004dh		;8c53   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;8c56
	inc hl			;8c57
	inc de			;8c58
	dec bc			;8c59
	ld a,b			;8c5a
	or c			;8c5b
	jr nz,L_8C4F		;8c5c
	ret			;8c5e
L_8C5F:
	call 0004ah		;8c5f   ; BIOS RDVRM - Reads the content of VRAM
	call L_8C72		;8c62
	ex de,hl			;8c65
	call 0004dh		;8c66   ; BIOS WRTVRM - Writes data in VRAM
	ex de,hl			;8c69
	inc hl			;8c6a
	inc de			;8c6b
	dec bc			;8c6c
	ld a,b			;8c6d
	or c			;8c6e
	jr nz,L_8C5F		;8c6f
	ret			;8c71
L_8C72:
	push bc			;8c72
	ld c,a			;8c73
	ld b,008h		;8c74
L_8C76:
	rr c		;8c76
	rla			;8c78
	djnz L_8C76		;8c79
	pop bc			;8c7b
	ret			;8c7c
L_8C7D:
	ld de,08d3dh		;8c7d
	call L_871C		;8c80
	jp vuelca_la_pantalla		;8c83
L_8C86:
	ld de,096bah		;8c86
	call guion_rle		;8c89
	ld hl,02218h		;8c8c
	ld de,090a7h		;8c8f
	call guion_rle_en_tres_bancos		;8c92
	ld hl,00218h		;8c95
	ld de,090deh		;8c98
	call guion_rle_en_tres_bancos		;8c9b
	ld hl,03000h		;8c9e
L_8CA1:
	push hl			;8ca1
	ld de,090e3h		;8ca2
	call vuelca_el_guion_con_destino_en_hl		;8ca5
	pop hl			;8ca8
	push hl			;8ca9
	ld de,0e000h		;8caa
	add hl,de			;8cad
	ld de,095ebh		;8cae
	call vuelca_el_guion_con_destino_en_hl		;8cb1
	pop hl			;8cb4
	ld de,00468h		;8cb5
	add hl,de			;8cb8
	push hl			;8cb9
	ld de,00168h		;8cba
	add hl,de			;8cbd
	ex de,hl			;8cbe
	pop hl			;8cbf
	push de			;8cc0
	push hl			;8cc1
	ld bc,00168h		;8cc2
	call L_8C5F		;8cc5
	pop hl			;8cc8
	ld de,0e000h		;8cc9
	add hl,de			;8ccc
	pop de			;8ccd
	push hl			;8cce
	ld hl,0e000h		;8ccf
	add hl,de			;8cd2
	ex de,hl			;8cd3
	pop hl			;8cd4
	ld bc,00168h		;8cd5
	call L_8C4F		;8cd8
	ret			;8cdb
L_8CDC:
	ld hl,08faah		;8cdc
	ld de,0ec80h		;8cdf
	ld bc,00035h		;8ce2
	ldir		;8ce5
	ret			;8ce7
L_8CE8:
	ld hl,03b00h		;8ce8
	ld de,0ec80h		;8ceb
	ld bc,00035h		;8cee
	jp copia_a_vram		;8cf1
L_8CF4:
	ld hl,0ee27h		;8cf4
	ld de,08d1fh		;8cf7
	call L_8D03		;8cfa
	ld hl,0ee33h		;8cfd
	ld de,08d16h		;8d00
L_8D03:
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
; DATOS sin identificar  0x8d16..0x8d28  (18 bytes)
DATA_8D16:
	defb 088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h	; 8d16  ................
	defb 0e8h,0e9h	; 8d26

; ======================================================================
; CODIGO 0x8d28..0x8d3d  (21 bytes)
; ======================================================================


L_8D28:
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
; DATOS sin identificar  0x8d3d..0x8fdf  (674 bytes)
DATA_8D3D:
	defb 02ah,0efh,083h,082h,057h,000h,000h,000h,000h,000h,000h,021h,04ch,04dh,000h,0feh	; 8d3d  *...W......!LM..
	defb 049h,0efh,05ch,05bh,05ah,059h,058h,000h,000h,000h,000h,022h,023h,024h,025h,026h	; 8d4d  I.\[ZYX...."#$%&
	defb 0feh,069h,0efh,060h,05fh,05eh,05eh,05dh,000h,000h,000h,000h,027h,028h,028h,029h	; 8d5d  .i.`_^^]....'(()
	defb 02ah,0feh,089h,0efh,065h,064h,063h,062h,061h,000h,000h,000h,000h,02bh,02ch,02dh	; 8d6d  *...edcba....+,-
	defb 02eh,02fh,0ffh,02ah,0efh,085h,084h,057h,000h,000h,000h,000h,000h,000h,021h,04eh	; 8d7d  ./.*...W......!N
	defb 04fh,0feh,049h,0efh,000h,06dh,06ch,06bh,06ah,000h,000h,000h,000h,034h,035h,036h	; 8d8d  O.I..mlkj....456
	defb 037h,000h,0feh,069h,0efh,086h,070h,06fh,05eh,06eh,000h,000h,000h,000h,038h,028h	; 8d9d  7..i..po^n....8(
	defb 039h,03ah,050h,0feh,088h,0efh,088h,087h,073h,072h,071h,000h,000h,000h,000h,000h	; 8dad  9:P.....srq.....
	defb 000h,03bh,03ch,03dh,051h,052h,0ffh,0b5h,0eeh,046h,047h,0feh,0d4h,0eeh,046h,048h	; 8dbd  .;<=QR...FG...FH
	defb 049h,0feh,0f3h,0eeh,043h,044h,045h,0feh,012h,0efh,001h,0feh,02ah,0efh,085h,084h	; 8dcd  I...CDE.....*...
	defb 057h,000h,006h,0bch,08fh,005h,076h,021h,04eh,04fh,0feh,049h,0efh,000h,06dh,06ch	; 8ddd  W.....v!NO.I..ml
	defb 074h,06ah,008h,00dh,00eh,007h,034h,03eh,036h,037h,000h,0feh,069h,0efh,086h,070h	; 8ded  tj....4>67..i..p
	defb 06fh,075h,06eh,000h,000h,000h,000h,040h,03fh,039h,03ah,050h,0feh,088h,0efh,088h	; 8dfd  oun....@?9:P....
	defb 087h,073h,072h,071h,009h,000h,000h,000h,000h,00ah,03bh,03ch,03dh,051h,052h,0feh	; 8e0d  .srq......;<=QR.
	defb 0aeh,0efh,0bdh,00bh,00ch,090h,0feh,0ceh,0efh,08dh,08eh,0bbh,0bah,0ffh,06eh,0efh	; 8e1d  ..............n.
	defb 014h,015h,0feh,08eh,0efh,016h,017h,0ffh,06eh,0efh,00fh,010h,0feh,08eh,0efh,011h	; 8e2d  ........n.......
	defb 012h,0ffh,06eh,0efh,00fh,010h,0feh,08eh,0efh,011h,013h,0ffh,070h,0efh,01eh,01dh	; 8e3d  ..n.........p...
	defb 0feh,090h,0efh,020h,01fh,0ffh,070h,0efh,019h,018h,0feh,090h,0efh,01bh,01ah,0ffh	; 8e4d  ... ..p.........
	defb 070h,0efh,019h,018h,0feh,090h,0efh,01ch,01ah,0ffh,02ah,0efh,077h,089h,0c0h,0feh	; 8e5d  p.........*.w...
	defb 049h,0efh,078h,05eh,08ah,079h,0feh,068h,0efh,0beh,07ah,07bh,05eh,07ch,07dh,0feh	; 8e6d  I.x^.y.h..z{^|}.
	defb 088h,0efh,000h,07eh,07fh,080h,081h,08bh,08ch,0ffh,02ah,0efh,077h,089h,0c0h,0feh	; 8e7d  ...~......*.w...
	defb 049h,0efh,078h,05eh,08ah,079h,0feh,068h,0efh,000h,07ah,07bh,05eh,07ch,07dh,0feh	; 8e8d  I.x^.y.h..z{^|}.
	defb 088h,0efh,0bfh,07eh,07fh,080h,081h,08bh,08ch,0ffh,028h,0efh,000h,000h,0d8h,0d7h	; 8e9d  ...~......(.....
	defb 0c2h,0c1h,0feh,048h,0efh,000h,0c7h,0c4h,0deh,0ddh,0c3h,0feh,068h,0efh,000h,0c8h	; 8ead  ...H........h...
	defb 0d9h,0c6h,05eh,0c5h,0feh,088h,0efh,0dch,0dbh,0dah,0cbh,0cah,0c9h,0ffh,028h,0efh	; 8ebd  ..^...........(.
	defb 094h,095h,0aah,0abh,000h,000h,0feh,048h,0efh,096h,0b0h,0b1h,097h,09ah,000h,0feh	; 8ecd  .......H........
	defb 068h,0efh,098h,05eh,099h,0ach,09bh,000h,0feh,088h,0efh,09ch,09dh,09eh,0adh,0aeh	; 8edd  h..^............
	defb 0afh,0ffh,032h,0efh,09fh,0a0h,0b2h,0b3h,000h,000h,0feh,052h,0efh,0a1h,0b8h,0b9h	; 8eed  ..2........R....
	defb 0a2h,0a5h,000h,0feh,072h,0efh,0a3h,028h,0a4h,0b4h,0a6h,000h,0feh,092h,0efh,0a7h	; 8efd  ....r..(........
	defb 0a8h,0a9h,0b5h,0b6h,0b7h,0ffh,032h,0efh,000h,000h,0e0h,0dfh,0cdh,0cch,0feh,052h	; 8f0d  ......2........R
	defb 0efh,000h,0d2h,0cfh,0e6h,0e5h,0ceh,0feh,072h,0efh,000h,0d3h,0e1h,0d1h,028h,0d0h	; 8f1d  ........r.....(.
	defb 0feh,092h,0efh,0e4h,0e3h,0e2h,0d6h,0d5h,0d4h,0ffh,033h,0efh,093h,053h,041h,0feh	; 8f2d  ..........3..SA.
	defb 053h,0efh,043h,054h,028h,042h,0feh,072h,0efh,047h,046h,028h,045h,044h,091h,0feh	; 8f3d  S.CT(B.r.GF(ED..
	defb 091h,0efh,056h,055h,04bh,04ah,049h,048h,000h,0ffh,033h,0efh,093h,053h,041h,0feh	; 8f4d  ..VUKJIH..3..SA.
	defb 053h,0efh,043h,054h,028h,042h,0feh,072h,0efh,047h,046h,028h,045h,044h,000h,0feh	; 8f5d  S.CT(B.r.GF(ED..
	defb 091h,0efh,056h,055h,04bh,04ah,049h,048h,092h,0ffh,08ch,0edh,034h,029h,02dh,025h	; 8f6d  ..VUKJIH....4)-%
	defb 000h,02fh,035h,034h,04bh,0ffh,0cbh,0edh,024h,032h,021h,037h,02eh,000h,027h,021h	; 8f7d  ./54K...$2!7..'!
	defb 02dh,025h,0ffh,0cbh,0edh,000h,000h,011h,030h,000h,037h,029h,02eh,04bh,000h,0ffh	; 8f8d  -%......0.7).K..
	defb 0cbh,0edh,000h,000h,012h,030h,000h,037h,029h,02eh,04bh,000h,0ffh,0e0h,000h,000h	; 8f9d  .....0.7).K.....
	defb 00ah,0e0h,000h,004h,00ah,0e0h,000h,008h,00ah,0e0h,000h,00ch,00ah,0e0h,000h,010h	; 8fad  ................
	defb 00ah,0e0h,000h,014h,00ah,0e0h,000h,018h,005h,0e0h,000h,01ch,007h,0e0h,000h,020h	; 8fbd  ............... 
	defb 007h,0e0h,000h,024h,007h,0e0h,000h,028h,007h,0e0h,000h,02ch,00ah,0e0h,000h,030h	; 8fcd  ...$...(...,...0
	defb 00ah,0d0h	; 8fdd

; ======================================================================
; CODIGO 0x8fdf..0x9019  (58 bytes)
; ======================================================================


L_8FDF:
	ld a,(0e002h)		;8fdf
	bit 5,a		;8fe2
	ret nz			;8fe4
	ld a,(0e34bh)		;8fe5
	dec a			;8fe8
	jr z,$+56		;8fe9
	dec a			;8feb
	ret z			;8fec
	ld a,(0e110h)		;8fed
	cp 008h		;8ff0
	ret nc			;8ff2
	ld hl,0e34dh		;8ff3
	ld b,003h		;8ff6
	ld a,001h		;8ff8
L_8FFA:
	cp (hl)			;8ffa
	ret nz			;8ffb
	inc hl			;8ffc
	djnz L_8FFA		;8ffd
	ld a,001h		;8fff
	ld (0e34bh),a		;9001
	ld hl,09019h		;9004
	ld de,0e350h		;9007
	ld bc,00008h		;900a
	ldir		;900d
	ld a,(0e204h)		;900f
	ld (0e350h),a		;9012
	ld (0e354h),a		;9015
	ret			;9018

; ----------------------------------------------------------------------
; DATOS sin identificar  0x9019..0x9021  (8 bytes)
DATA_9019:
	defb 000h,000h,0d0h,006h,000h,000h,0d4h,00fh	; 9019  ........

; ======================================================================
; CODIGO 0x9021..0x9032  (17 bytes)
; ======================================================================


L_9021:
	ld de,(0e204h)		;9021
	ld hl,0e350h		;9025
	call L_76CC		;9028
	jr nc,$+45		;902b
	ld hl,0e110h		;902d
	jr $+17		;9030

; ----------------------------------------------------------------------
; DATOS sin identificar  0x9032..0x9041  (15 bytes)
DATA_9032:
	defb 0edh,05bh,00ch,0e2h,021h,050h,0e3h,0cdh,0cch,076h,030h,01ah,021h,010h,0e1h	; 9032  .[..!P...v0.!..

; ======================================================================
; CODIGO 0x9041..0x90a7  (102 bytes)
; ======================================================================


L_9041:
	inc (hl)			;9041
	ld a,(0e002h)		;9042
	bit 5,a		;9045
	jr nz,L_904E		;9047
	call pinta_el_marcador		;9049
	jr L_9051		;904c
L_904E:
	call pinta_el_marcador_del_duelo		;904e
L_9051:
	ld a,011h		;9051
	call toca_sonido		;9053
	jr L_908A		;9056
L_9058:
	call L_907E		;9058
	ld hl,0e351h		;905b
	inc (hl)			;905e
	ld hl,0e355h		;905f
	inc (hl)			;9062
	ld a,(hl)			;9063
	cp 0feh		;9064
	ret c			;9066
	jr L_908A		;9067
L_9069:
	ld a,0e0h		;9069
	ld (0e350h),a		;906b
	ld (0e354h),a		;906e
	ld hl,0e34bh		;9071
	ld de,0e34ch		;9074
	ld bc,00004h		;9077
	ld (hl),000h		;907a
	ldir		;907c
L_907E:
	ld hl,03b4ch		;907e
	ld de,0e350h		;9081
	ld bc,00008h		;9084
	jp copia_a_vram		;9087
L_908A:
	call L_9069		;908a
	ld a,002h		;908d
	ld (0e34bh),a		;908f
	ret			;9092
L_9093:
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
; DATOS sin identificar  0x90a7..0xc000  (12121 bytes)
DATA_90A7:
	defb 005h,000h,08eh,001h,003h,007h,00fh,01fh,03fh,07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h	; 90a7  ........?.......
	defb 080h,00ah,000h,083h,001h,003h,007h,005h,000h,08eh,080h,0c0h,0e0h,00fh,01fh,03fh	; 90b7  ...............?
	defb 07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,008h,000h,002h,054h,004h,000h,087h,00ch	; 90c7  ...........T....
	defb 01ch,018h,010h,000h,060h,060h,000h,038h,050h,010h,0f0h,000h,008h,000h,005h,000h	; 90d7  ....``.8P.......
	defb 083h,001h,003h,007h,00ah,003h,006h,000h,002h,0ffh,00ch,000h,082h,0c3h,0f7h,006h	; 90e7  ................
	defb 000h,082h,003h,00fh,008h,0ffh,089h,001h,007h,00fh,01fh,03fh,07fh,07fh,0ffh,000h	; 90f7  ...........?....
	defb 003h,003h,003h,001h,081h,000h,004h,0c0h,003h,080h,005h,000h,083h,040h,038h,00fh	; 9107  .............@8.
	defb 005h,000h,089h,003h,006h,0e0h,000h,000h,007h,01fh,060h,080h,004h,000h,083h,080h	; 9117  ..........`.....
	defb 0f1h,001h,006h,000h,086h,080h,0dfh,0ffh,0fbh,0f7h,0f6h,004h,000h,002h,080h,095h	; 9127  ................
	defb 040h,0e0h,0f6h,0f9h,0f5h,04eh,036h,038h,000h,000h,0f8h,0bch,0cch,0f0h,038h,018h	; 9137  @....N68......8.
	defb 000h,000h,060h,080h,080h,007h,000h,08eh,080h,0dfh,0ffh,0ffh,0feh,0f1h,000h,000h	; 9147  ..`.............
	defb 060h,0e0h,0c0h,000h,0c0h,0e0h,003h,0ffh,096h,0feh,077h,03bh,01dh,00ch,0f8h,09ch	; 9157  `.........w;....
	defb 0ech,0f0h,038h,098h,0c0h,0c0h,000h,000h,001h,0fbh,0ffh,0dfh,0efh,06fh,0ffh,003h	; 9167  ..8..........o..
	defb 000h,002h,001h,095h,002h,007h,06fh,09fh,0afh,072h,06ch,01ch,000h,000h,01fh,03dh	; 9177  ......o..rl....=
	defb 033h,00fh,01ch,018h,000h,000h,006h,001h,001h,007h,000h,08eh,001h,0fbh,0ffh,0ffh	; 9187  3...............
	defb 07fh,08fh,000h,000h,006h,007h,003h,000h,003h,007h,003h,0ffh,097h,07fh,0eeh,0dch	; 9197  ................
	defb 0b8h,030h,01fh,039h,037h,00fh,01ch,019h,003h,003h,000h,003h,00fh,03fh,07fh,07fh	; 91a7  .0.97........?..
	defb 0ffh,0ffh,001h,001h,003h,003h,083h,00fh,03fh,07fh,004h,0fbh,084h,0ffh,0efh,0e7h	; 91b7  ........?.......
	defb 0f8h,004h,0bfh,084h,0ffh,0efh,08fh,07fh,003h,0e0h,082h,0f0h,0f8h,003h,0fch,002h	; 91c7  ................
	defb 000h,08bh,006h,00fh,01fh,01fh,03fh,03eh,07bh,073h,0f7h,0f7h,067h,003h,007h,008h	; 91d7  ......?>{s..g...
	defb 0ffh,098h,0feh,0beh,0deh,0bch,07bh,077h,0b7h,0cfh,07eh,0feh,0fch,0fch,0f8h,0f8h	; 91e7  ......{w..~.....
	defb 0f0h,0f0h,003h,003h,001h,001h,007h,03fh,059h,037h,004h,0ffh,084h,07fh,09fh,0e3h	; 91f7  .......?Y7......
	defb 0fch,005h,0ffh,08eh,0f3h,0efh,007h,0ffh,0ffh,0fbh,0fbh,0fch,0ffh,0edh,0f6h,0e0h	; 9207  ................
	defb 0c0h,080h,003h,000h,0a2h,080h,0c0h,001h,039h,03bh,07bh,073h,07bh,07fh,07fh,03bh	; 9217  ........9;{s{..;
	defb 01bh,007h,007h,003h,00bh,01dh,01dh,066h,09fh,0ffh,03fh,03fh,01fh,00fh,007h,0ffh	; 9227  .......f..??....
	defb 07fh,0bfh,0bfh,0dfh,0dfh,0c7h,080h,003h,001h,005h,003h,002h,0ffh,004h,0dfh,008h	; 9237  ................
	defb 0ffh,002h,0fdh,002h,0e0h,002h,0f0h,002h,0f8h,002h,0fch,003h,003h,08ah,00bh,03dh	; 9247  ...............=
	defb 07dh,071h,000h,0feh,0efh,0f7h,0f9h,0feh,003h,0ffh,085h,0feh,07fh,0bfh,0bfh,07fh	; 9257  }q..............
	defb 004h,0ffh,002h,07fh,085h,03fh,00fh,003h,014h,02fh,004h,0ffh,084h,0f8h,0e7h,019h	; 9267  .....?.../......
	defb 0d7h,003h,0ffh,083h,0fdh,03eh,0feh,004h,0ffh,004h,0bbh,002h,0ffh,002h,0dfh,082h	; 9277  .....>..........
	defb 0ffh,0dfh,004h,0ffh,088h,003h,083h,083h,08bh,0cdh,0cdh,0c1h,0c0h,005h,000h,086h	; 9287  ................
	defb 0c0h,0f8h,0feh,000h,080h,080h,003h,0c0h,002h,0e0h,002h,000h,086h,005h,007h,003h	; 9297  ................
	defb 003h,007h,00fh,003h,0e0h,002h,0c0h,083h,080h,000h,0c0h,003h,0ffh,081h,0f1h,003h	; 92a7  ................
	defb 0feh,086h,0deh,00fh,09fh,0ffh,07fh,07fh,003h,0ffh,002h,000h,081h,001h,003h,000h	; 92b7  ................
	defb 084h,001h,003h,0c0h,080h,006h,000h,002h,0efh,086h,0f7h,0f8h,0f8h,0e0h,018h,0fch	; 92c7  ................
	defb 006h,0ffh,081h,0f4h,003h,0ffh,089h,0efh,0dfh,03fh,007h,060h,0f3h,000h,0f8h,0feh	; 92d7  .........?.`....
	defb 005h,0ffh,002h,000h,003h,080h,003h,0c0h,084h,000h,0e0h,0f8h,0feh,004h,0ffh,002h	; 92e7  ................
	defb 000h,004h,080h,002h,0c0h,004h,000h,086h,080h,0c0h,0e0h,0f0h,0f8h,0fch,004h,0ffh	; 92f7  ................
	defb 089h,00fh,000h,080h,080h,0c0h,0c0h,0f8h,0fch,0f8h,006h,000h,084h,00fh,003h,00fh	; 9307  ................
	defb 07fh,007h,0ffh,09ah,01fh,00fh,01fh,07fh,0ffh,0fch,0e0h,0ffh,000h,001h,003h,007h	; 9317  ................
	defb 01fh,03fh,01fh,000h,000h,0c0h,0f0h,0fch,0feh,0feh,0ffh,0ffh,080h,080h,003h,0c0h	; 9327  .?..............
	defb 083h,0f0h,0fch,0feh,004h,0dfh,084h,0ffh,0f7h,0e7h,01fh,004h,0fdh,084h,0ffh,0f7h	; 9337  ................
	defb 0f1h,0feh,003h,007h,082h,00fh,01fh,003h,03fh,002h,000h,08bh,060h,0f0h,0f8h,0f8h	; 9347  ........?...`...
	defb 0fch,07ch,0deh,0ceh,0efh,0efh,0e6h,003h,0e0h,008h,0ffh,098h,07fh,07dh,07bh,03dh	; 9357  .|...........}{=
	defb 0deh,0eeh,0edh,0f3h,07eh,07fh,03fh,03fh,01fh,01fh,00fh,00fh,0c0h,0c0h,080h,080h	; 9367  ....~.??........
	defb 0e0h,0fch,09ah,0ech,004h,0ffh,084h,0feh,0f9h,0c7h,03fh,005h,0ffh,08eh,0cfh,0f7h	; 9377  ..........?.....
	defb 0e0h,0ffh,0ffh,0dfh,0dfh,03fh,0ffh,0b7h,06fh,007h,003h,001h,003h,000h,0a2h,001h	; 9387  .....?..o.......
	defb 003h,080h,09ch,0dch,0deh,0ceh,0deh,0feh,0feh,0dch,0d8h,0e0h,0e0h,0c0h,0d0h,0b8h	; 9397  ................
	defb 0b8h,066h,0f9h,0ffh,0fch,0fch,0f8h,0f0h,0e0h,0ffh,0feh,0fdh,0fdh,0fbh,0fbh,0e3h	; 93a7  .f..............
	defb 001h,003h,080h,005h,0c0h,002h,0ffh,004h,0fbh,008h,0ffh,002h,0bfh,002h,007h,002h	; 93b7  ................
	defb 00fh,002h,01fh,002h,03fh,003h,0c0h,08ah,0d0h,0bch,0beh,08eh,000h,07fh,0f7h,0efh	; 93c7  ....?...........
	defb 09fh,07fh,003h,0ffh,085h,07fh,0feh,0fdh,0fdh,0feh,004h,0ffh,002h,0feh,085h,0fch	; 93d7  ................
	defb 0f0h,0c0h,028h,0f4h,004h,0ffh,084h,01fh,0e7h,098h,0ebh,003h,0ffh,083h,0bfh,07ch	; 93e7  ..(............|
	defb 07fh,004h,0ffh,004h,0ddh,002h,0ffh,002h,0fbh,082h,0ffh,0fbh,004h,0ffh,088h,00fh	; 93f7  ................
	defb 007h,01bh,03dh,07ch,0f8h,0f0h,0e0h,005h,000h,086h,003h,01fh,07fh,000h,001h,001h	; 9407  ..=|............
	defb 003h,003h,002h,007h,002h,000h,086h,0a0h,0e0h,0c0h,0c0h,0e0h,0f0h,003h,007h,002h	; 9417  ................
	defb 003h,083h,001h,000h,003h,003h,0ffh,081h,08fh,003h,07fh,086h,07bh,0f0h,0f9h,0ffh	; 9427  ............{...
	defb 0feh,0feh,003h,0ffh,002h,000h,081h,080h,003h,000h,084h,080h,0c0h,003h,001h,006h	; 9437  ................
	defb 000h,002h,0f7h,086h,0efh,01fh,01fh,007h,018h,03fh,006h,0ffh,081h,02fh,003h,0ffh	; 9447  .........?.../..
	defb 089h,0f7h,0fbh,0fch,0e0h,006h,0cfh,000h,0e0h,080h,007h,000h,003h,001h,003h,003h	; 9457  ................
	defb 084h,000h,0f8h,0e0h,080h,004h,0ffh,002h,000h,004h,001h,002h,003h,004h,000h,086h	; 9467  ................
	defb 001h,003h,007h,0f0h,0e0h,0c0h,004h,0ffh,089h,0f0h,000h,001h,001h,003h,003h,01fh	; 9477  ................
	defb 03fh,01fh,006h,000h,084h,00fh,03fh,00fh,001h,007h,0ffh,092h,0f8h,00fh,007h,001h	; 9487  ?.....?.........
	defb 0ffh,03fh,007h,000h,000h,080h,0c0h,0e0h,0f8h,0fch,0f8h,000h,007h,001h,003h,0bfh	; 9497  .?..............
	defb 08bh,0ffh,0fbh,0fbh,080h,0f0h,0ffh,00fh,0bfh,000h,0fbh,0fbh,004h,000h,08ch,0f0h	; 94a7  ................
	defb 0feh,00fh,001h,0ffh,0feh,001h,003h,0ffh,0f0h,01fh,07fh,003h,000h,08dh,090h,004h	; 94b7  ................
	defb 062h,033h,030h,010h,000h,04ch,006h,026h,000h,030h,030h,006h,000h,002h,001h,004h	; 94c7  b30..L.&.00.....
	defb 000h,09ch,040h,0e0h,0f1h,0f3h,000h,000h,003h,01fh,07fh,0ffh,0ffh,0cfh,0fbh,077h	; 94d7  ..@............w
	defb 077h,06fh,02fh,02fh,01fh,01fh,0e7h,0efh,09fh,07eh,0fch,0f9h,0f7h,0cfh,005h,01fh	; 94e7  wo//.....~......
	defb 002h,00fh,085h,007h,0ffh,0ffh,0feh,0feh,004h,0fdh,006h,000h,002h,080h,090h,060h	; 94f7  ...............`
	defb 0e0h,010h,0b0h,0e0h,0c0h,0c0h,080h,007h,003h,001h,000h,007h,01fh,073h,0afh,004h	; 9507  .............s..
	defb 0ffh,085h,07fh,08fh,0f0h,0ffh,0feh,003h,0ffh,082h,0fch,083h,006h,000h,09ch,040h	; 9517  ...............@
	defb 0e0h,0f1h,0f3h,000h,000h,003h,01fh,07fh,0ffh,0ffh,0cfh,0fbh,077h,077h,06fh,02fh	; 9527  ............wwo/
	defb 02fh,01fh,01fh,0e7h,0efh,09fh,07eh,0fch,0f9h,0f7h,0cfh,005h,01fh,002h,00fh,085h	; 9537  /.....~.........
	defb 007h,0ffh,0ffh,0feh,0feh,004h,0fdh,006h,000h,002h,080h,090h,060h,0e0h,010h,0b0h	; 9547  ............`...
	defb 0e0h,0c0h,0c0h,080h,007h,003h,001h,000h,007h,01fh,073h,0afh,004h,0ffh,085h,07fh	; 9557  ..........s.....
	defb 08fh,0f0h,0ffh,0feh,003h,0ffh,082h,0fch,083h,004h,000h,086h,007h,001h,000h,0ffh	; 9567  ................
	defb 0ffh,09fh,003h,000h,003h,080h,002h,0c0h,094h,0bch,07eh,0ffh,0ffh,00eh,01fh,03fh	; 9577  ..........~....?
	defb 03eh,01ch,07ch,083h,03fh,0ffh,0ffh,07fh,007h,040h,0dch,03eh,007h,004h,0ffh,003h	; 9587  >.|.?....@.>....
	defb 000h,092h,080h,0f0h,0f0h,0e0h,080h,087h,0c0h,05fh,03fh,0bfh,0dch,0e3h,0ffh,00fh	; 9597  ........._?.....
	defb 07fh,078h,0dfh,00fh,003h,0ffh,002h,000h,082h,0f8h,0feh,003h,0ffh,081h,09fh,003h	; 95a7  .x..............
	defb 000h,003h,080h,002h,0c0h,094h,0bch,07eh,0ffh,0ffh,0f1h,0e0h,0c0h,0c1h,0e3h,07ch	; 95b7  .......~.......|
	defb 083h,03fh,0ffh,0ffh,07fh,007h,040h,0dch,0c0h,0f8h,004h,0ffh,003h,000h,092h,080h	; 95c7  .?....@.........
	defb 0f0h,0f0h,0e0h,080h,087h,037h,05fh,03fh,0bfh,0dch,0e3h,0ffh,00fh,07fh,087h,0dfh	; 95d7  .....7_?........
	defb 00fh,003h,0ffh,000h,008h,010h,008h,050h,018h,060h,010h,070h,018h,040h,081h,0d0h	; 95e7  .......P.`.p.@..
	defb 007h,040h,010h,0f4h,058h,074h,008h,0d4h,081h,044h,03fh,0d4h,07fh,0d0h,00bh,0d0h	; 95f7  .@..Xt...D?.....
	defb 081h,0ddh,07fh,0d0h,04fh,0d0h,007h,0dah,004h,0a0h,005h,0d0h,007h,0dah,005h,0a0h	; 9607  ....O...........
	defb 00ah,0d0h,004h,0dah,005h,0d0h,003h,0a0h,00ah,0d0h,00bh,0dah,081h,0d0h,003h,0dah	; 9617  ................
	defb 003h,0d0h,081h,000h,004h,0a0h,004h,0d0h,07fh,050h,07fh,050h,05bh,050h,007h,0a5h	; 9627  .........P.P[P..
	defb 004h,0a0h,005h,050h,003h,0a5h,004h,050h,005h,0a0h,00ah,050h,003h,0a5h,006h,050h	; 9637  ...P...P...P...P
	defb 003h,0a0h,00ah,050h,004h,0a5h,008h,050h,003h,0a5h,004h,050h,081h,080h,003h,0a0h	; 9647  ...P...P...P....
	defb 004h,050h,090h,074h,070h,070h,050h,040h,000h,070h,050h,074h,074h,070h,075h,040h	; 9657  .P.tppP@.pPttpu@
	defb 070h,070h,050h,006h,070h,002h,074h,002h,040h,086h,074h,054h,040h,040h,074h,054h	; 9667  ppP.p.t.@.tT@@tT
	defb 010h,070h,008h,0a0h,058h,050h,05ah,0d0h,003h,0a5h,006h,050h,002h,0a0h,007h,050h	; 9677  .p..XPZ....P...P
	defb 005h,0a5h,007h,050h,002h,0a0h,002h,0a5h,004h,050h,004h,0a0h,005h,050h,081h,085h	; 9687  ...P.....P...P..
	defb 008h,050h,081h,085h,007h,050h,005h,0dah,004h,0d0h,002h,0a0h,007h,0d0h,005h,0dah	; 9697  .P...P..........
	defb 007h,0d0h,002h,0a0h,006h,0dah,004h,0a0h,005h,0d0h,081h,0d8h,008h,0d0h,081h,0d8h	; 96a7  ................
	defb 005h,0d0h,000h,000h,018h,008h,000h,091h,038h,01ch,00ch,008h,003h,003h,001h,000h	; 96b7  ........8.......
	defb 000h,004h,00ch,00ch,008h,000h,018h,030h,020h,004h,000h,003h,080h,089h,000h,020h	; 96c7  .......0 ...... 
	defb 030h,030h,010h,000h,018h,00ch,004h,004h,000h,003h,001h,008h,000h,087h,01ch,038h	; 96d7  00.............8
	defb 030h,010h,0c0h,0c0h,080h,00ch,000h,084h,060h,0e0h,0e0h,0c0h,02ch,000h,084h,006h	; 96e7  0.......`...,...
	defb 007h,007h,003h,009h,000h,002h,001h,002h,000h,08fh,003h,007h,006h,004h,004h,01ch	; 96f7  ................
	defb 038h,038h,030h,010h,020h,0e0h,0c0h,0c0h,080h,005h,000h,08bh,020h,038h,01ch,01ch	; 9707  880. ....... 8..
	defb 00ch,008h,004h,007h,003h,003h,001h,00dh,000h,002h,080h,002h,000h,08fh,0c0h,0e0h	; 9717  ................
	defb 060h,020h,00fh,01fh,03fh,07fh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,005h,000h,083h	; 9727  ` ..?...........
	defb 0e0h,0c0h,080h,011h,000h,002h,001h,003h,003h,003h,007h,004h,00fh,087h,01eh,038h	; 9737  ...............8
	defb 070h,0e0h,0c0h,080h,080h,009h,000h,081h,00fh,003h,00ch,003h,006h,002h,003h,002h	; 9747  p...............
	defb 001h,00eh,000h,002h,080h,08ch,0c0h,0e0h,070h,038h,01eh,07bh,01bh,00eh,0c7h,063h	; 9757  ........p8.{...c
	defb 021h,001h,009h,000h,002h,0c0h,084h,080h,000h,080h,080h,003h,0c0h,003h,060h,004h	; 9767  !.............`.
	defb 030h,009h,000h,002h,001h,085h,003h,007h,00eh,01ch,078h,004h,030h,003h,060h,003h	; 9777  0.........x.0.`.
	defb 0c0h,002h,080h,004h,000h,002h,0c0h,08bh,040h,000h,030h,03ch,01eh,00eh,00eh,006h	; 9787  ........@.0<....
	defb 000h,001h,001h,00eh,000h,085h,0e0h,0f0h,0f0h,070h,030h,00bh,000h,092h,007h,00fh	; 9797  .........p0.....
	defb 00fh,00eh,00ch,003h,003h,002h,000h,00ch,03ch,078h,070h,070h,060h,000h,080h,080h	; 97a7  ........<xpp`...
	defb 003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h	; 97b7  ................
	defb 00fh,00fh,00eh,00ch,003h,003h,002h,000h,00ch,03ch,078h,070h,070h,060h,000h,080h	; 97c7  .........<xpp`..
	defb 080h,000h,000h,000h,000h,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 97d7  ................
	defb 011h,0ffh,013h,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,005h,0ffh,007h,0ffh,0ffh,0ffh	; 97e7  ................
	defb 007h,0ffh,008h,0ffh,009h,0ffh,00ah,0ffh,00bh,0ffh,006h,0ffh,005h,0ffh,006h,0ffh	; 97f7  ................
	defb 005h,0ffh,010h,0ffh,011h,0ffh,012h,0ffh,013h,0ffh,0ffh,0ffh,014h,0ffh,015h,0ffh	; 9807  ................
	defb 016h,0ffh,0ffh,0ffh,0ffh,0ffh,017h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9817  ................
	defb 009h,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9827  ................
	defb 0ffh,0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,006h,0ffh,013h,0ffh,0ffh,0ffh	; 9837  ................
	defb 002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh,002h,0ffh,007h,0ffh,008h,0ffh,003h,0ffh	; 9847  ................
	defb 002h,0ffh,002h,0ffh,012h,0ffh,013h,0ffh,014h,0ffh,015h,0ffh,002h,0ffh,003h,0ffh	; 9857  ................
	defb 002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh,002h,0ffh,003h,0ffh,006h,0ffh,0ffh,0ffh	; 9867  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,013h,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9877  ................
	defb 0ffh,0ffh,001h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,005h,0ffh	; 9887  ................
	defb 0ffh,0ffh,001h,0ffh,00ah,0ffh,002h,0ffh,00ah,0ffh,001h,0ffh,0ffh,0ffh,00ch,0ffh	; 9897  ................
	defb 0ffh,0ffh,00eh,0ffh,00ah,0ffh,001h,0ffh,011h,0ffh,001h,0ffh,0ffh,0ffh,000h,0ffh	; 98a7  ................
	defb 0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh	; 98b7  ................
	defb 0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 98c7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 98d7  ................
	defb 0ffh,0ffh,0ffh,0ffh,009h,0ffh,009h,0ffh,008h,0ffh,0ffh,0ffh,004h,0ffh,005h,0ffh	; 98e7  ................
	defb 006h,0ffh,007h,0ffh,008h,0ffh,009h,0ffh,00ah,0ffh,00bh,0ffh,008h,0ffh,009h,0ffh	; 98f7  ................
	defb 009h,0ffh,00bh,0ffh,010h,0ffh,0ffh,0ffh,011h,0ffh,012h,0ffh,013h,0ffh,0ffh,0ffh	; 9907  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9917  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9927  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah	; 9937  ................
	defb 0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,00bh,0ffh,00bh,0ffh,0ffh,0ffh,006h	; 9947  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,006h,0ffh,005h,0ffh,00bh,0ffh,004h,0ffh,005h	; 9957  ................
	defb 0ffh,00bh,0ffh,006h,0ffh,00ah,0ffh,00bh,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9967  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,011h,0ffh	; 9977  ................
	defb 004h,0ffh,005h,0ffh,0ffh,0ffh,006h,0ffh,007h,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9987  ................
	defb 009h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,015h,0ffh,005h,0ffh,0ffh,0ffh	; 9997  ................
	defb 016h,0ffh,005h,0ffh,010h,0ffh,011h,0ffh,012h,0ffh,013h,0ffh,014h,0ffh,015h,0ffh	; 99a7  ................
	defb 016h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh	; 99b7  ................
	defb 0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh	; 99c7  ................
	defb 0ffh,0ffh,010h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,009h,0ffh,0ffh,0ffh	; 99d7  ................
	defb 0ffh,0ffh,013h,0ffh,011h,0ffh,005h,0ffh,0ffh,0ffh,016h,0ffh,011h,0ffh,00ah,0ffh	; 99e7  ................
	defb 0ffh,0ffh,005h,0ffh,014h,0ffh,012h,0ffh,006h,0ffh,013h,0ffh,017h,0ffh,012h,0ffh	; 99f7  ................
	defb 00bh,0ffh,004h,0ffh,014h,0ffh,015h,0ffh,005h,0ffh,007h,003h,0ffh,0ffh,0ffh,0ffh	; 9a07  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9a17  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,009h,0ffh,011h,0ffh	; 9a27  ................
	defb 0ffh,0ffh,007h,0ffh,00ah,0ffh,010h,0ffh,0ffh,0ffh,006h,0ffh,00bh,0ffh,011h,0ffh	; 9a37  ................
	defb 0ffh,0ffh,005h,0ffh,006h,0ffh,012h,0ffh,0ffh,0ffh,004h,0ffh,004h,0ffh,013h,0ffh	; 9a47  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh	; 9a57  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h	; 9a67  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,014h,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,014h,0ffh,0ffh	; 9a77  ................
	defb 0ffh,007h,0ffh,00ch,0ffh,00fh,0ffh,015h,0ffh,0ffh,0ffh,008h,0ffh,00eh,0ffh,012h	; 9a87  ................
	defb 0ffh,0ffh,0ffh,006h,0ffh,00dh,0ffh,008h,0ffh,009h,0ffh,0ffh,0ffh,007h,0ffh,0ffh	; 9a97  ................
	defb 0ffh,013h,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,0ffh,0ffh,00dh,0ffh,005h,0ffh,0ffh	; 9aa7  ................
	defb 0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,008h,0ffh,0ffh,0ffh,0ffh	; 9ab7  ................
	defb 0ffh,009h,0ffh,007h,0ffh,008h,0ffh,0ffh,0ffh,00ch,0ffh,00dh,0ffh,00eh,0ffh,00fh	; 9ac7  ................
	defb 0ffh,00ch,0ffh,009h,0ffh,012h,0ffh,013h,0ffh,014h,0ffh,0ffh,0ffh,015h,0ffh,014h	; 9ad7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh,002h,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,006h	; 9ae7  ................
	defb 0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh	; 9af7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,004h,0ffh	; 9b07  ................
	defb 0ffh,0ffh,0ffh,0ffh,012h,0ffh,010h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh	; 9b17  ................
	defb 006h,0ffh,0ffh,0ffh,005h,0ffh,016h,0ffh,014h,0ffh,0ffh,0ffh,011h,0ffh,017h,0ffh	; 9b27  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,013h,0ffh,015h,0ffh,003h,0ffh,0ffh,0ffh,009h,0ffh	; 9b37  ................
	defb 007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h	; 9b47  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,007h,0ffh,00ch,0ffh	; 9b57  ................
	defb 002h,0ffh,0ffh,0ffh,004h,0ffh,012h,0ffh,010h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b67  ................
	defb 00eh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b77  ................
	defb 009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,00ch,0ffh,006h,0ffh,0ffh,0ffh	; 9b87  ................
	defb 005h,0ffh,011h,0ffh,008h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9b97  ................
	defb 004h,0ffh,0ffh,0ffh,008h,0ffh,000h,0ffh,00ch,0ffh,0ffh,0ffh,011h,0ffh,000h,0ffh	; 9ba7  ................
	defb 003h,0ffh,0ffh,0ffh,001h,0ffh,006h,0ffh,005h,0ffh,00fh,0ffh,002h,0ffh,003h,0ffh	; 9bb7  ................
	defb 006h,0ffh,00eh,0ffh,00dh,0ffh,013h,0ffh,009h,0ffh,001h,0ffh,00ah,0ffh,00dh,0ffh	; 9bc7  ................
	defb 006h,0ffh,009h,0ffh,002h,0ffh,015h,0ffh,009h,0ffh,000h,0ffh,012h,0ffh,007h,0ffh	; 9bd7  ................
	defb 008h,0ffh,014h,0ffh,007h,0ffh,003h,0ffh,00ah,0ffh,016h,0ffh,015h,0ffh,00ch,0ffh	; 9be7  ................
	defb 005h,005h,0ffh,0ffh,002h,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9bf7  ................
	defb 0ffh,0ffh,0ffh,0ffh,008h,0ffh,010h,0ffh,00eh,0ffh,006h,0ffh,00dh,0ffh,012h,0ffh	; 9c07  ................
	defb 001h,0ffh,0ffh,0ffh,00bh,0ffh,012h,0ffh,014h,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c17  ................
	defb 0ffh,0ffh,0ffh,0ffh,00fh,0ffh,013h,0ffh,017h,0ffh,014h,0ffh,0ffh,0ffh,003h,0ffh	; 9c27  ................
	defb 00ch,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh,009h,0ffh,007h,0ffh	; 9c37  ................
	defb 013h,0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c47  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh	; 9c57  ................
	defb 002h,0ffh,00ah,0ffh,004h,0ffh,005h,0ffh,009h,0ffh,00dh,0ffh,00ch,0ffh,001h,0ffh	; 9c67  ................
	defb 003h,0ffh,00bh,0ffh,010h,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c77  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9c87  ................
	defb 0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,006h,0ffh	; 9c97  ................
	defb 00dh,0ffh,001h,0ffh,006h,0ffh,0ffh,0ffh,003h,0ffh,011h,0ffh,00fh,0ffh,0ffh,0ffh	; 9ca7  ................
	defb 008h,0ffh,010h,0ffh,00bh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh	; 9cb7  ................
	defb 0ffh,0ffh,0ffh,0ffh,002h,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh	; 9cc7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,00eh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9cd7  ................
	defb 00ch,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9ce7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h	; 9cf7  ................
	defb 0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d07  ................
	defb 0ffh,00ah,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,013h,0ffh,009h	; 9d17  ................
	defb 0ffh,003h,0ffh,007h,0ffh,00fh,0ffh,00eh,0ffh,010h,0ffh,00eh,0ffh,002h,0ffh,001h	; 9d27  ................
	defb 0ffh,00ch,0ffh,005h,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d37  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d47  ................
	defb 0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,006h,0ffh,0ffh,0ffh	; 9d57  ................
	defb 003h,0ffh,005h,0ffh,000h,0ffh,008h,0ffh,001h,0ffh,004h,0ffh,00dh,0ffh,00eh,0ffh	; 9d67  ................
	defb 00ch,0ffh,00ah,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh	; 9d77  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9d87  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,00ch,0ffh,002h,0ffh,00dh	; 9d97  ................
	defb 0ffh,0ffh,0ffh,004h,0ffh,009h,0ffh,00eh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,010h	; 9da7  ................
	defb 0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9db7  ................
	defb 0ffh,00dh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh	; 9dc7  ................
	defb 0ffh,0ffh,0ffh,003h,0ffh,006h,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9dd7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h	; 9de7  ................
	defb 0ffh,0ffh,0ffh,008h,0ffh,005h,0ffh,0ffh,0ffh,001h,0ffh,000h,0ffh,002h,0ffh,009h	; 9df7  ................
	defb 0ffh,00ah,0ffh,007h,0ffh,006h,0ffh,000h,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh	; 9e07  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e17  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh	; 9e27  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,012h,0ffh	; 9e37  ................
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,00dh,0ffh,0ffh,0ffh,007h,0ffh	; 9e47  ................
	defb 0ffh,0ffh,001h,0ffh,005h,0ffh,000h,0ffh,017h,0ffh,0ffh,0ffh,007h,0ffh,00bh,0ffh	; 9e57  ................
	defb 002h,0ffh,014h,0ffh,0ffh,0ffh,013h,0ffh,00eh,0ffh,011h,0ffh,016h,0ffh,001h,0ffh	; 9e67  ................
	defb 015h,0ffh,004h,0ffh,009h,0ffh,010h,0ffh,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e77  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,001h,0ffh	; 9e87  ................
	defb 011h,0ffh,006h,0ffh,005h,0ffh,013h,0ffh,0ffh,0ffh,003h,0ffh,00bh,0ffh,00ah,0ffh	; 9e97  ................
	defb 0ffh,0ffh,0ffh,0ffh,00fh,0ffh,016h,0ffh,004h,0ffh,0ffh,0ffh,012h,0ffh,009h,0ffh	; 9ea7  ................
	defb 008h,0ffh,0ffh,0ffh,0ffh,0ffh,015h,0ffh,010h,0ffh,000h,0ffh,011h,0ffh,002h,0ffh	; 9eb7  ................
	defb 017h,0ffh,014h,0ffh,00ch,0ffh,012h,0ffh,007h,0ffh,00eh,0ffh,001h,0ffh,0ffh,0ffh	; 9ec7  ................
	defb 004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh	; 9ed7  ................
	defb 0ffh,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,011h,0ffh,0ffh,0ffh,00ch,0ffh	; 9ee7  ................
	defb 003h,0ffh,012h,0ffh,00bh,0ffh,006h,0ffh,0ffh,0ffh,013h,0ffh,00fh,0ffh,0ffh,0ffh	; 9ef7  ................
	defb 005h,0ffh,00ah,0ffh,0ffh,0ffh,008h,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f07  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh	; 9f17  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f27  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,006h	; 9f37  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,010h	; 9f47  ................
	defb 0ffh,00bh,0ffh,001h,0ffh,0ffh,0ffh,005h,0ffh,00ah,0ffh,011h,0ffh,00eh,0ffh,000h	; 9f57  ................
	defb 0ffh,012h,0ffh,009h,0ffh,007h,0ffh,013h,0ffh,003h,0ffh,00ch,010h,0ffh,0ffh,0ffh	; 9f67  ................
	defb 002h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f77  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh	; 9f87  ................
	defb 008h,0ffh,00dh,0ffh,0ffh,0ffh,001h,0ffh,00fh,0ffh,013h,0ffh,011h,0ffh,012h,0ffh	; 9f97  ................
	defb 00ch,0ffh,0ffh,0ffh,00ah,0ffh,014h,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh	; 9fa7  ................
	defb 003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh	; 9fb7  ................
	defb 0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,003h,0ffh,0ffh,0ffh,0ffh	; 9fc7  ................
	defb 0ffh,002h,0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh,006h,0ffh,013h,0ffh,010h,0ffh,005h	; 9fd7  ................
	defb 0ffh,00ah,0ffh,00fh,0ffh,0ffh,0ffh,001h,0ffh,009h,0ffh,004h,0ffh,0ffh,0ffh,0ffh	; 9fe7  ................
	defb 0ffh,007h,0ffh,00dh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh	; 9ff7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,012h,0ffh	; a007  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a017  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,00fh,0ffh,009h,0ffh	; a027  ................
	defb 0ffh,0ffh,00ah,0ffh,0ffh,0ffh,001h,0ffh,007h,0ffh,0ffh,0ffh,002h,0ffh,0ffh,0ffh	; a037  ................
	defb 0ffh,0ffh,003h,0ffh,00ch,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,008h,0ffh	; a047  ................
	defb 010h,0ffh,00dh,0ffh,0ffh,0ffh,006h,0ffh,00eh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,013h	; a057  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh	; a067  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,003h	; a077  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,00eh,0ffh,002h,0ffh,0ffh,0ffh,001h	; a087  ................
	defb 0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,006h,0ffh,0ffh	; a097  ................
	defb 0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh	; a0a7  ................
	defb 014h,0ffh,0ffh,0ffh,00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh	; a0b7  ................
	defb 0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh	; a0c7  ................
	defb 002h,0ffh,0ffh,0ffh,003h,0ffh,008h,0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,011h,0ffh	; a0d7  ................
	defb 001h,0ffh,0ffh,0ffh,00dh,0ffh,0ffh,0ffh,009h,0ffh,006h,0ffh,0ffh,0ffh,004h,0ffh	; a0e7  ................
	defb 0ffh,0ffh,00ch,0ffh,010h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,012h,0ffh,0ffh,0ffh	; a0f7  ................
	defb 0ffh,015h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh,006h	; a107  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh	; a117  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a127  ................
	defb 0ffh,001h,0ffh,0ffh,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh	; a137  ................
	defb 0ffh,007h,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh	; a147  ................
	defb 0ffh,0ffh,006h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a157  ................
	defb 0ffh,010h,0ffh,0ffh,0ffh,003h,0ffh,00dh,0ffh,002h,0ffh,00ch,0ffh,0ffh,0ffh,013h	; a167  ................
	defb 0ffh,007h,0ffh,005h,0ffh,00bh,0ffh,0ffh,0ffh,014h,0ffh,008h,0ffh,003h,0ffh,0ffh	; a177  ................
	defb 0ffh,004h,0ffh,00fh,0ffh,011h,0ffh,0ffh,0ffh,00eh,0ffh,009h,0ffh,015h,0ffh,009h	; a187  ................
	defb 0ffh,0ffh,0ffh,017h,0ffh,000h,0ffh,00ah,0ffh,016h,0ffh,0ffh,0ffh,005h,0ffh,0ffh	; a197  ................
	defb 0ffh,012h,0ffh,007h,002h,0ffh,0ffh,00dh,0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,00ch	; a1a7  ................
	defb 0ffh,00eh,0ffh,013h,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,011h	; a1b7  ................
	defb 0ffh,001h,0ffh,008h,0ffh,00ah,0ffh,0ffh,0ffh,012h,0ffh,010h,0ffh,005h,0ffh,0ffh	; a1c7  ................
	defb 0ffh,0ffh,0ffh,009h,0ffh,012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,0ffh	; a1d7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,006h,0ffh,014h,0ffh,0ffh,0ffh,00ah,0ffh,005h	; a1e7  ................
	defb 0ffh,00bh,0ffh,0ffh,008h,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a1f7  ................
	defb 0ffh,002h,0ffh,00ch,0ffh,0ffh,0ffh,009h,0ffh,016h,0ffh,00ah,0ffh,015h,0ffh,00eh	; a207  ................
	defb 0ffh,013h,0ffh,001h,0ffh,010h,0ffh,004h,0ffh,007h,0ffh,017h,0ffh,004h,0ffh,000h	; a217  ................
	defb 0ffh,0ffh,0ffh,001h,0ffh,00dh,0ffh,012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h	; a227  ................
	defb 0ffh,006h,0ffh,0ffh,0ffh,00fh,0ffh,005h,0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh,011h	; a237  ................
	defb 0ffh,00bh,0ffh,0ffh,0ffh,009h,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a247  ................
	defb 0ffh,0ffh,007h,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,00dh,0ffh,000h,0ffh	; a257  ................
	defb 0ffh,0ffh,014h,0ffh,010h,0ffh,00ah,0ffh,0ffh,0ffh,002h,0ffh,005h,0ffh,000h,0ffh	; a267  ................
	defb 00ch,0ffh,0ffh,0ffh,00bh,0ffh,001h,0ffh,012h,0ffh,0ffh,0ffh,00eh,0ffh,013h,0ffh	; a277  ................
	defb 008h,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a287  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh	; a297  ................
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,010h,0ffh,0ffh,0ffh,016h,0ffh,003h,0ffh,013h,0ffh	; a2a7  ................
	defb 015h,0ffh,0ffh,0ffh,001h,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,014h,0ffh,008h,0ffh	; a2b7  ................
	defb 007h,0ffh,001h,0ffh,0ffh,0ffh,012h,0ffh,002h,0ffh,002h,0ffh,0ffh,0ffh,006h,0ffh	; a2c7  ................
	defb 016h,0ffh,003h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh	; a2d7  ................
	defb 0ffh,0ffh,003h,0ffh,004h,0ffh,0ffh,00bh,006h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a2e7  ................
	defb 0ffh,0ffh,0ffh,001h,0ffh,002h,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,00fh	; a2f7  ................
	defb 0ffh,0ffh,0ffh,008h,0ffh,011h,0ffh,00ch,0ffh,00ah,0ffh,00eh,0ffh,000h,0ffh,013h	; a307  ................
	defb 0ffh,016h,0ffh,003h,0ffh,0ffh,0ffh,001h,0ffh,002h,0ffh,0ffh,0ffh,007h,0ffh,00dh	; a317  ................
	defb 0ffh,015h,0ffh,005h,0ffh,003h,0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,017h	; a327  ................
	defb 0ffh,002h,0ffh,012h,0ffh,009h,0ffh,004h,00ch,007h,0ffh,0ffh,001h,0ffh,0ffh,0ffh	; a337  ................
	defb 0ffh,0ffh,0ffh,0ffh,00eh,0ffh,00bh,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,015h,0ffh	; a347  ................
	defb 011h,0ffh,0ffh,0ffh,006h,0ffh,009h,0ffh,002h,0ffh,004h,0ffh,0ffh,0ffh,013h,0ffh	; a357  ................
	defb 005h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh,016h,0ffh,0ffh,0ffh,0ffh,0ffh	; a367  ................
	defb 017h,0ffh,000h,0ffh,003h,0ffh,0ffh,0ffh,00fh,0ffh,014h,0ffh,00dh,0ffh,008h,0ffh	; a377  ................
	defb 008h,0ffh,00ah,0ffh,002h,0ffh,010h,0ffh,012h,00dh,008h,0ffh,0ffh,003h,0ffh,0ffh	; a387  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,001h	; a397  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,013h,0ffh,0ffh,0ffh,0ffh,0ffh,014h	; a3a7  ................
	defb 0ffh,00bh,0ffh,004h,0ffh,0ffh,0ffh,005h,0ffh,002h,0ffh,000h,0ffh,009h,0ffh,007h	; a3b7  ................
	defb 0ffh,002h,0ffh,011h,0ffh,016h,0ffh,010h,0ffh,015h,0ffh,00fh,0ffh,017h,0ffh,003h	; a3c7  ................
	defb 0ffh,00ah,0ffh,0ffh,0ffh,006h,0ffh,0ffh,0ffh,012h,00eh,009h,0ffh,0ffh,0ffh,0ffh	; a3d7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,00dh	; a3e7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,013h,0ffh,0ffh,0ffh,0ffh,0ffh,00bh	; a3f7  ................
	defb 0ffh,006h,0ffh,00ch,0ffh,002h,0ffh,001h,0ffh,012h,0ffh,011h,0ffh,008h,0ffh,0ffh	; a407  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,010h	; a417  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,008h,0ffh,0ffh,0ffh,00fh,00ah,0ffh,0ffh,0ffh	; a427  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh	; a437  ................
	defb 00ch,0ffh,007h,0ffh,003h,0ffh,0ffh,0ffh,005h,0ffh,010h,0ffh,00eh,0ffh,0ffh,0ffh	; a447  ................
	defb 0ffh,0ffh,001h,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh	; a457  ................
	defb 0ffh,0ffh,0ffh,0ffh,00bh,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,006h,0ffh	; a467  ................
	defb 002h,0ffh,0ffh,0ffh,005h,0ffh,013h,0ffh,008h,0ffh,012h,0ffh,010h,00bh,0ffh,0ffh	; a477  ................
	defb 003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh	; a487  ................
	defb 0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,007h,0ffh,0ffh,0ffh	; a497  ................
	defb 0ffh,0ffh,00ah,0ffh,00dh,0ffh,003h,0ffh,0ffh,0ffh,005h,0ffh,004h,0ffh,00fh,0ffh	; a4a7  ................
	defb 009h,0ffh,005h,0ffh,00ch,0ffh,011h,0ffh,008h,0ffh,001h,0ffh,006h,0ffh,00eh,0ffh	; a4b7  ................
	defb 002h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh,011h,00ch,0ffh	; a4c7  ................
	defb 005h,0ffh,013h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,015h,0ffh,002h,0ffh,0ffh,0ffh	; a4d7  ................
	defb 017h,0ffh,010h,0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh,003h,0ffh,012h,0ffh,008h,0ffh	; a4e7  ................
	defb 0ffh,0ffh,007h,0ffh,013h,0ffh,002h,0ffh,016h,0ffh,0ffh,0ffh,001h,0ffh,006h,0ffh	; a4f7  ................
	defb 012h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,001h,0ffh,014h,0ffh,0ffh,0ffh,0ffh,0ffh	; a507  ................
	defb 0ffh,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,012h,00dh	; a517  ................
	defb 0ffh,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,002h,0ffh,009h,0ffh,003h,0ffh	; a527  ................
	defb 0ffh,0ffh,007h,0ffh,010h,0ffh,00eh,0ffh,0ffh,0ffh,002h,0ffh,013h,0ffh,000h,0ffh	; a537  ................
	defb 0ffh,0ffh,0ffh,0ffh,00fh,0ffh,003h,0ffh,001h,0ffh,00bh,0ffh,0ffh,0ffh,004h,0ffh	; a547  ................
	defb 00ch,0ffh,006h,0ffh,0ffh,0ffh,00ah,0ffh,002h,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh	; a557  ................
	defb 0ffh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,0ffh,013h	; a567  ................
	defb 00eh,0ffh,0ffh,010h,0ffh,0ffh,0ffh,016h,0ffh,0ffh,0ffh,00dh,0ffh,003h,0ffh,014h	; a577  ................
	defb 0ffh,001h,0ffh,00ah,0ffh,0ffh,0ffh,007h,0ffh,009h,0ffh,005h,0ffh,001h,0ffh,004h	; a587  ................
	defb 0ffh,0ffh,0ffh,012h,0ffh,0ffh,0ffh,006h,0ffh,012h,0ffh,002h,0ffh,011h,0ffh,003h	; a597  ................
	defb 0ffh,002h,0ffh,007h,0ffh,015h,0ffh,00bh,0ffh,00fh,0ffh,000h,0ffh,0ffh,0ffh,004h	; a5a7  ................
	defb 0ffh,000h,0ffh,0ffh,0ffh,008h,0ffh,005h,0ffh,0ffh,0ffh,00ch,0ffh,017h,0ffh,006h	; a5b7  ................
	defb 014h,00fh,0ffh,0ffh,010h,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,017h,0ffh	; a5c7  ................
	defb 007h,0ffh,0ffh,0ffh,003h,0ffh,007h,0ffh,011h,0ffh,00bh,0ffh,013h,0ffh,002h,0ffh	; a5d7  ................
	defb 000h,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,011h,0ffh,0ffh,0ffh,00eh,0ffh	; a5e7  ................
	defb 002h,0ffh,001h,0ffh,005h,0ffh,00ah,0ffh,012h,0ffh,008h,0ffh,016h,0ffh,004h,0ffh	; a5f7  ................
	defb 000h,0ffh,000h,0ffh,015h,0ffh,0ffh,0ffh,005h,0ffh,00ch,0ffh,011h,0ffh,008h,0ffh	; a607  ................
	defb 0ffh,015h,010h,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,002h	; a617  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,00ch,0ffh,0ffh,0ffh,00ah,0ffh,0ffh,0ffh,001h,0ffh,011h	; a627  ................
	defb 0ffh,0ffh,0ffh,00dh,0ffh,009h,0ffh,0ffh,0ffh,008h,0ffh,0ffh,0ffh,006h,0ffh,00bh	; a637  ................
	defb 0ffh,0ffh,0ffh,003h,0ffh,016h,0ffh,0ffh,0ffh,007h,0ffh,0ffh,0ffh,013h,0ffh,0ffh	; a647  ................
	defb 0ffh,0ffh,0ffh,012h,0ffh,000h,0ffh,00eh,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,0ffh	; a657  ................
	defb 0ffh,00fh,016h,011h,0ffh,0ffh,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,0ffh	; a667  ................
	defb 010h,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,0ffh,00dh,0ffh,004h,0ffh,0ffh,0ffh,00ah,0ffh	; a677  ................
	defb 006h,0ffh,013h,0ffh,00bh,0ffh,0ffh,0ffh,003h,0ffh,000h,0ffh,015h,0ffh,0ffh,0ffh	; a687  ................
	defb 0ffh,0ffh,012h,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,014h,0ffh,017h,0ffh,002h,0ffh	; a697  ................
	defb 0ffh,0ffh,007h,0ffh,0ffh,0ffh,0ffh,0ffh,00eh,0ffh,0ffh,0ffh,00ch,0ffh,005h,0ffh	; a6a7  ................
	defb 010h,0ffh,0ffh,017h,012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a6b7  ................
	defb 0ffh,0ffh,0ffh,013h,0ffh,0ffh,0ffh,001h,0ffh,005h,0ffh,008h,0ffh,000h,0ffh,0ffh	; a6c7  ................
	defb 0ffh,00ch,0ffh,003h,0ffh,009h,0ffh,009h,0ffh,007h,0ffh,00ah,0ffh,002h,0ffh,0ffh	; a6d7  ................
	defb 0ffh,008h,0ffh,004h,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,009h,0ffh,006h,0ffh,00bh	; a6e7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h	; a6f7  ................
	defb 0ffh,0ffh,0ffh,0ffh,001h,013h,0ffh,0ffh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a707  ................
	defb 004h,0ffh,00ch,0ffh,0ffh,0ffh,0ffh,0ffh,007h,0ffh,015h,0ffh,009h,0ffh,0ffh,0ffh	; a717  ................
	defb 00eh,0ffh,014h,0ffh,010h,0ffh,002h,0ffh,00ah,0ffh,0ffh,0ffh,005h,0ffh,0ffh,0ffh	; a727  ................
	defb 006h,0ffh,006h,0ffh,014h,0ffh,00dh,0ffh,00eh,0ffh,0ffh,0ffh,00bh,0ffh,003h,0ffh	; a737  ................
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,012h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a747  ................
	defb 008h,0ffh,0ffh,0ffh,0ffh,000h,014h,0ffh,0ffh,00dh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a757  ................
	defb 0ffh,00fh,0ffh,008h,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,0ffh,001h,0ffh,004h,0ffh,0ffh	; a767  ................
	defb 0ffh,0ffh,0ffh,006h,0ffh,00ah,0ffh,0ffh,0ffh,002h,0ffh,007h,0ffh,00eh,0ffh,00bh	; a777  ................
	defb 0ffh,006h,0ffh,0ffh,0ffh,004h,0ffh,009h,0ffh,0ffh,0ffh,0ffh,0ffh,005h,0ffh,00ch	; a787  ................
	defb 0ffh,003h,0ffh,0ffh,0ffh,0ffh,0ffh,010h,0ffh,011h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a797  ................
	defb 0ffh,009h,0ffh,0ffh,0ffh,0ffh,000h,0ffh,0ffh,0ffh,004h,0ffh,0ffh,0ffh,0ffh,0ffh	; a7a7  ................
	defb 0ffh,0ffh,007h,0ffh,00ah,0ffh,0ffh,0ffh,0ffh,0ffh,004h,0ffh,005h,0ffh,006h,0ffh	; a7b7  ................
	defb 0ffh,0ffh,007h,0ffh,008h,0ffh,009h,0ffh,00ah,0ffh,00bh,0ffh,005h,0ffh,012h,0ffh	; a7c7  ................
	defb 007h,0ffh,010h,0ffh,010h,0ffh,011h,0ffh,012h,0ffh,013h,0ffh,004h,0ffh,00bh,0ffh	; a7d7  ................
	defb 0ffh,0ffh,00ah,0ffh,004h,0ffh,005h,0ffh,0ffh,0ffh,0ffh,0ffh,006h,0ffh,007h,0ffh	; a7e7  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,008h,040h,007h,041h,007h,007h,006h,007h,007h,042h	; a7f7  .......@.A.....B
	defb 043h,007h,044h,007h,007h,006h,007h,007h,045h,046h,007h,047h,007h,007h,006h,007h	; a807  C.D.....EF.G....
	defb 007h,048h,049h,007h,04ah,007h,007h,006h,007h,007h,04bh,04ch,007h,04dh,006h,006h	; a817  .HI.J.....KL.M..
	defb 007h,006h,006h,04eh,04fh,007h,050h,006h,006h,007h,006h,006h,051h,052h,006h,053h	; a827  ...NO.P.....QR.S
	defb 007h,007h,007h,007h,007h,054h,055h,006h,056h,007h,007h,007h,007h,007h,057h,058h	; a837  .....TU.V.....WX
	defb 006h,059h,007h,007h,007h,007h,007h,05ah,05bh,006h,05ch,007h,007h,007h,007h,007h	; a847  .Y.....Z[.\.....
	defb 05dh,05eh,007h,05fh,006h,006h,007h,006h,006h,060h,061h,007h,062h,006h,006h,007h	; a857  ]^._.....`a.b...
	defb 006h,006h,063h,064h,007h,065h,007h,007h,006h,007h,007h,066h,067h,007h,068h,007h	; a867  ..cd.e.....fg.h.
	defb 007h,006h,007h,007h,069h,06ah,007h,06bh,007h,007h,006h,007h,007h,06ch,06dh,007h	; a877  ....ij.k.....lm.
	defb 06eh,007h,007h,006h,007h,007h,06fh,070h,007h,071h,006h,006h,007h,006h,006h,072h	; a887  n.....op.q.....r
	defb 073h,007h,074h,006h,006h,007h,006h,006h,075h,076h,006h,077h,007h,007h,007h,007h	; a897  s.t.....uv.w....
	defb 007h,078h,079h,006h,07ah,007h,007h,007h,007h,007h,07bh,07ch,006h,07dh,007h,007h	; a8a7  .xy.z.....{|.}..
	defb 007h,007h,007h,07eh,07fh,006h,080h,007h,007h,007h,007h,007h,081h,082h,007h,083h	; a8b7  ...~............
	defb 006h,006h,007h,006h,006h,084h,085h,007h,086h,006h,006h,007h,006h,006h,087h,088h	; a8c7  ................
	defb 089h,08ah,08bh,08ch,08dh,08eh,08fh,090h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h	; a8d7  ................
	defb 0e9h,040h,006h,041h,004h,004h,007h,004h,004h,042h,043h,004h,044h,006h,006h,007h	; a8e7  .@.A.....BC.D...
	defb 006h,006h,045h,046h,006h,047h,004h,004h,007h,004h,004h,048h,049h,004h,04ah,006h	; a8f7  ..EF.G.....HI.J.
	defb 006h,007h,006h,006h,04bh,04ch,006h,04dh,007h,007h,004h,007h,007h,04eh,04fh,004h	; a907  ....KL.M.....NO.
	defb 050h,007h,007h,006h,007h,007h,051h,052h,007h,053h,004h,004h,006h,004h,004h,054h	; a917  P.....QR.S.....T
	defb 055h,007h,056h,006h,006h,004h,006h,006h,057h,058h,007h,059h,004h,004h,006h,004h	; a927  U.V.....WX.Y....
	defb 004h,05ah,05bh,007h,05ch,006h,006h,004h,006h,006h,05dh,05eh,004h,05fh,007h,007h	; a937  .Z[.\.....]^._..
	defb 006h,007h,007h,060h,061h,006h,062h,007h,007h,004h,007h,007h,063h,064h,006h,065h	; a947  ...`a.b.....cd.e
	defb 004h,004h,007h,004h,004h,066h,067h,004h,068h,006h,006h,007h,006h,006h,069h,06ah	; a957  .....fg.h.....ij
	defb 006h,06bh,004h,004h,007h,004h,004h,06ch,06dh,004h,06eh,006h,006h,007h,006h,006h	; a967  .k.....lm.n.....
	defb 06fh,070h,006h,071h,007h,007h,004h,007h,007h,072h,073h,004h,074h,007h,007h,006h	; a977  op.q.....rs.t...
	defb 007h,007h,075h,076h,007h,077h,004h,004h,006h,004h,004h,078h,079h,007h,07ah,006h	; a987  ..uv.w.....xy.z.
	defb 006h,004h,006h,006h,07bh,07ch,007h,07dh,004h,004h,006h,004h,004h,07eh,07fh,007h	; a997  ....{|.}.....~..
	defb 080h,006h,006h,004h,006h,006h,081h,082h,004h,083h,007h,007h,006h,007h,007h,084h	; a9a7  ................
	defb 085h,006h,086h,007h,007h,004h,007h,007h,087h,088h,089h,08ah,08bh,08ch,08dh,08eh	; a9b7  ................
	defb 08fh,090h,0e1h,0e2h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h,0e9h,040h,006h,041h,004h,004h	; a9c7  ...........@.A..
	defb 00ch,004h,004h,042h,043h,007h,044h,006h,006h,00ch,006h,006h,045h,046h,009h,047h	; a9d7  ...BC.D.....EF.G
	defb 007h,007h,00ch,007h,007h,048h,049h,004h,04ah,009h,009h,00ch,009h,009h,04bh,04ch	; a9e7  .....HI.J.....KL
	defb 006h,04dh,00ah,00ah,004h,00ah,00ah,04eh,04fh,004h,050h,00ch,00ch,006h,00ch,00ch	; a9f7  .M.....NO.P.....
	defb 051h,052h,00ah,053h,004h,004h,006h,004h,004h,054h,055h,00ah,056h,006h,006h,007h	; aa07  QR.S.....TU.V...
	defb 006h,006h,057h,058h,00ah,059h,007h,007h,009h,007h,007h,05ah,05bh,00ah,05ch,009h	; aa17  ..WX.Y.....Z[.\.
	defb 009h,004h,009h,009h,05dh,05eh,007h,05fh,00ah,00ah,006h,00ah,00ah,060h,061h,009h	; aa27  ....]^._.....`a.
	defb 062h,00ch,00ch,004h,00ch,00ch,063h,064h,009h,065h,004h,004h,00ah,004h,004h,066h	; aa37  b.....cd.e.....f
	defb 067h,004h,068h,006h,006h,00ah,006h,006h,069h,06ah,006h,06bh,007h,007h,00ah,007h	; aa47  g.h.....ij.k....
	defb 007h,06ch,06dh,007h,06eh,009h,009h,00ah,009h,009h,06fh,070h,009h,071h,00ah,00ah	; aa57  .lm.n.....op.q..
	defb 007h,00ah,00ah,072h,073h,007h,074h,00ch,00ch,009h,00ch,00ch,075h,076h,00ch,077h	; aa67  ...rs.t.....uv.w
	defb 004h,004h,009h,004h,004h,078h,079h,00ch,07ah,006h,006h,004h,006h,006h,07bh,07ch	; aa77  .....xy.z.....{|
	defb 00ch,07dh,007h,007h,006h,007h,007h,07eh,07fh,00ch,080h,009h,009h,007h,009h,009h	; aa87  .}.....~........
	defb 081h,082h,004h,083h,00ah,00ah,009h,00ah,00ah,084h,085h,006h,086h,00ch,00ch,007h	; aa97  ................
	defb 00ch,00ch,087h,088h,089h,08ah,08bh,08ch,08dh,08eh,08fh,090h,0e1h,0e2h,0e3h,0e4h	; aaa7  ................
	defb 0e5h,0e6h,0e7h,0e8h,0e9h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h	; aab7  ................
	defb 01fh,073h,0fdh,0ffh,078h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0e0h	; aac7  .s..x...........
	defb 0f8h,0ceh,0bfh,0ffh,01eh,000h,000h,000h,000h,000h,000h,003h,00fh,01dh,01dh,03dh	; aad7  ...............=
	defb 03fh,03fh,03eh,03eh,01ch,000h,000h,000h,000h,000h,000h,0c0h,0f0h,0b8h,0b8h,0bch	; aae7  ??>>............
	defb 0fch,0fch,07ch,07ch,038h,000h,003h,00dh,00dh,00dh,077h,0f8h,0b7h,08ah,02fh,02ah	; aaf7  ..||8.....w.../*
	defb 02fh,017h,038h,03bh,07ch,000h,0c0h,0b0h,0b0h,0b0h,0eeh,01fh,0edh,051h,0f4h,054h	; ab07  /.8;|........Q.T
	defb 0f4h,0e8h,01ch,0dch,03eh,003h,00dh,08dh,0cdh,0e7h,078h,037h,00ah,02fh,022h,01dh	; ab17  ....>.....x7./".
	defb 03dh,03ah,01dh,00ch,003h,0c0h,0b0h,0b1h,0b3h,0e7h,01eh,0ech,050h,0f4h,044h,0b8h	; ab27  =:..........P.D.
	defb 0bch,05ch,0b8h,030h,0c0h,001h,003h,007h,00fh,00fh,01bh,01dh,01fh,03fh,07fh,07fh	; ab37  .\.0.........?..
	defb 0dfh,03fh,03fh,07fh,00fh,080h,0c0h,0e0h,0f0h,0f0h,0d8h,0b8h,0f8h,0fch,0feh,0feh	; ab47  .??.............
	defb 0fbh,0fch,0fch,0feh,0f0h,003h,007h,00fh,01bh,09dh,0dfh,0ffh,07fh,07fh,03fh,067h	; ab57  ..............?g
	defb 05bh,03dh,03dh,03bh,018h,0c0h,0e0h,0f0h,0d8h,0b9h,0fbh,0ffh,0feh,0feh,0fch,0e6h	; ab67  [==;............
	defb 0dah,0bch,0bch,0dch,018h,002h,007h,00fh,01fh,01fh,033h,03dh,07fh,0ffh,0ffh,0bfh	; ab77  ..........3=....
	defb 03fh,03fh,07fh,07fh,00fh,040h,0e0h,0f0h,0f8h,0f8h,0cch,0bch,0feh,0ffh,0ffh,0fdh	; ab87  ??...@..........
	defb 0fch,0fch,0feh,0feh,0f0h,002h,00fh,03fh,033h,09dh,0dfh,0ffh,0ffh,07fh,03fh,067h	; ab97  .......?3.....?g
	defb 05bh,03dh,03dh,038h,018h,040h,0f0h,0fch,0cch,0b9h,0fbh,0ffh,0ffh,0feh,0fch,0e6h	; aba7  [==8.@..........
	defb 0dah,0bch,0bch,0dch,018h,000h,000h,040h,060h,070h,06fh,01fh,07fh,0ffh,00fh,067h	; abb7  .......@`po....g
	defb 036h,036h,06fh,003h,000h,000h,000h,000h,000h,000h,000h,000h,080h,0c0h,0f1h,03fh	; abc7  66o............?
	defb 00fh,007h,006h,0c8h,000h,000h,000h,080h,080h,080h,080h,000h,000h,000h,000h,080h	; abd7  ................
	defb 0c0h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,070h,07ch,03eh,00eh,000h,000h	; abe7  ..........p|>...
	defb 0c0h,0f0h,030h,000h,000h,000h,001h,003h,003h,006h,006h,02fh,07fh,02fh,01fh,01fh	; abf7  ..0.......././..
	defb 01fh,03fh,03fh,067h,05ah,078h,0fch,0feh,03eh,0beh,064h,0d4h,0c8h,0f8h,0f4h,0feh	; ac07  .??gZx..>.d.....
	defb 0e4h,0f0h,0f0h,018h,0ech,01eh,03fh,07fh,07ch,07dh,026h,02bh,013h,01fh,02fh,07fh	; ac17  ......?.|}&+../.
	defb 027h,00fh,00fh,018h,037h,000h,080h,0c0h,0c0h,060h,060h,0f4h,0feh,0f4h,0f8h,0f8h	; ac27  '...7....``.....
	defb 0f8h,0fch,0fch,0e6h,05ah,007h,00fh,00fh,01fh,020h,00ch,00dh,01bh,01bh,037h,037h	; ac37  ....Z.... ....77
	defb 00fh,01fh,003h,01dh,03fh,0f0h,0f8h,0fch,0fch,038h,074h,0f4h,0f4h,0f4h,0f4h,0f4h	; ac47  ....?....8t.....
	defb 0f4h,0f4h,0f8h,0f0h,0e0h,007h,00fh,01fh,03fh,020h,00ch,019h,01bh,037h,077h,00fh	; ac57  ........? ...7w.
	defb 013h,011h,021h,023h,03fh,0f0h,0f8h,0fch,0fch,038h,074h,0f4h,0f4h,0f4h,0f4h,0f4h	; ac67  ..!#?....8t.....
	defb 0f4h,0f4h,0f8h,0f0h,0e0h,00fh,01fh,03fh,03fh,01ch,02eh,02fh,02fh,02fh,02fh,02fh	; ac77  .......??../////
	defb 02fh,02fh,01fh,00fh,007h,0e0h,0f0h,0f0h,0f8h,004h,030h,0b0h,0d8h,0d8h,0ech,0ech	; ac87  //........0.....
	defb 0f0h,0f8h,0c0h,0b8h,0fch,00fh,01fh,03fh,03fh,01ch,02eh,02fh,02fh,02fh,02fh,02fh	; ac97  .......??../////
	defb 02fh,02fh,01fh,00fh,007h,0e0h,0f0h,0f8h,0fch,004h,030h,098h,0d8h,0ech,0eeh,0f0h	; aca7  //........0.....
	defb 0c8h,088h,084h,0c4h,0fch,003h,00ch,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acb7  ................
	defb 000h,000h,000h,039h,0f7h,080h,040h,030h,010h,00ch,004h,000h,002h,002h,000h,000h	; acc7  ...9..@0........
	defb 000h,002h,002h,0c1h,0e0h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acd7  ................
	defb 000h,0eeh,077h,03bh,019h,080h,040h,030h,010h,00ch,008h,000h,000h,000h,000h,006h	; ace7  ..w;..@0........
	defb 004h,006h,002h,081h,080h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; acf7  ................
	defb 000h,000h,000h,010h,07eh,080h,0e0h,020h,030h,018h,018h,018h,008h,00ch,00ch,00ch	; ad07  ....~.. 0.......
	defb 006h,006h,003h,001h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad17  ................
	defb 080h,0c0h,0c0h,078h,019h,0c0h,040h,030h,030h,010h,018h,008h,008h,00ch,00ch,004h	; ad27  ...x..@00.......
	defb 006h,006h,002h,003h,081h,000h,003h,03fh,07fh,07fh,0ffh,0dbh,0dbh,0dbh,0ffh,0ffh	; ad37  .......?........
	defb 07fh,07fh,03fh,006h,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0f8h,0fch,0fch,0deh,0eeh	; ad47  ..?.............
	defb 0ech,0f0h,0fch,02eh,003h,000h,00fh,03fh,07fh,05bh,0dbh,0dbh,0ffh,0ffh,0ffh,0ffh	; ad57  .......?.[......
	defb 07fh,011h,008h,004h,000h,000h,080h,0c0h,0e0h,0f0h,0f7h,0efh,0ffh,0feh,0fch,0f0h	; ad67  ................
	defb 0f8h,0f8h,0f4h,04eh,003h,000h,00fh,01fh,03fh,03fh,03fh,07fh,07fh,0ffh,0efh,0efh	; ad77  ...N....???.....
	defb 05fh,03fh,03fh,00fh,000h,040h,000h,0d0h,0c8h,0e0h,0e4h,0e4h,0f4h,0f2h,0f2h,0f2h	; ad87  _??..@..........
	defb 0f8h,0d8h,0dch,0eeh,003h,003h,00fh,01fh,03fh,0bfh,0dfh,0efh,0ffh,07fh,03fh,04fh	; ad97  ........?.....?O
	defb 07fh,03fh,01fh,007h,000h,000h,0a0h,0c0h,0c8h,0e8h,0e4h,0f4h,0f4h,0f2h,0f2h,0fah	; ada7  .?..............
	defb 0f8h,0d8h,0dch,0ech,006h,001h,002h,00ch,008h,030h,020h,000h,040h,040h,000h,000h	; adb7  .........0 .@@..
	defb 000h,040h,040h,083h,007h,0c0h,030h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; adc7  .@@...0.........
	defb 000h,000h,000h,09ch,0efh,001h,002h,00ch,008h,030h,010h,000h,000h,000h,000h,060h	; add7  .........0.....`
	defb 020h,060h,040h,081h,001h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ade7   `@.............
	defb 000h,077h,0eeh,0dch,098h,001h,007h,004h,00ch,018h,018h,018h,010h,030h,030h,030h	; adf7  .w...........000
	defb 060h,060h,0c0h,080h,00fh,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae07  ``..............
	defb 000h,000h,000h,008h,07eh,003h,002h,00ch,00ch,008h,018h,010h,010h,030h,030h,020h	; ae17  ....~........00 
	defb 060h,060h,040h,0c0h,081h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae27  ``@.............
	defb 001h,003h,003h,01eh,098h,000h,001h,003h,007h,00fh,01fh,01fh,03fh,03fh,07bh,077h	; ae37  ............??{w
	defb 037h,00fh,03fh,074h,0c0h,000h,0c0h,0fch,0feh,0feh,0ffh,0dbh,0dbh,0dbh,0ffh,0ffh	; ae47  7.?t............
	defb 0feh,0feh,0fch,060h,000h,000h,001h,003h,007h,00fh,0efh,0f7h,0ffh,07fh,03fh,00fh	; ae57  ...`..........?.
	defb 01fh,01fh,02fh,072h,0c0h,000h,0f0h,0fch,0feh,0dah,0dbh,0dbh,0ffh,0ffh,0ffh,0ffh	; ae67  ../r............
	defb 0feh,088h,010h,020h,000h,002h,000h,00bh,013h,007h,027h,027h,02fh,04fh,04fh,04fh	; ae77  ... ......''/OOO
	defb 01fh,01bh,03bh,077h,0c0h,000h,0f0h,0f8h,0fch,0fch,0fch,0feh,0feh,0ffh,0f7h,0f7h	; ae87  ..;w............
	defb 0fah,0fch,0fch,0f0h,000h,000h,005h,003h,013h,017h,027h,02fh,02fh,04fh,04fh,05fh	; ae97  ..........'//OO_
	defb 01fh,01bh,03bh,037h,060h,0c0h,0f0h,0f8h,0fch,0fdh,0fbh,0f7h,0ffh,0feh,0fch,0f2h	; aea7  ..;7`...........
	defb 0feh,0fch,0f8h,0e0h,000h,001h,003h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aeb7  ................
	defb 000h,000h,000h,01ch,07eh,080h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aec7  ....~...........
	defb 000h,000h,000h,038h,07eh,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,030h	; aed7  ...8~..........0
	defb 078h,078h,078h,078h,030h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,00ch	; aee7  xxxx0...........
	defb 01eh,01eh,01eh,01eh,00ch,000h,000h,00fh,01fh,03fh,03dh,07dh,0fdh,0bfh,0ddh,0deh	; aef7  .........?=}....
	defb 03fh,03fh,01fh,003h,000h,000h,000h,0f0h,0f8h,0fch,0bch,0beh,0bfh,0fdh,0bbh,07bh	; af07  ??.............{
	defb 0fch,0fch,0f8h,0c0h,000h,000h,00fh,01fh,03dh,07dh,07fh,0b8h,0d8h,0dch,03fh,04fh	; af17  ........=}....?O
	defb 007h,007h,007h,003h,000h,000h,0f0h,0f8h,0bch,0beh,0feh,01dh,01bh,03bh,03bh,0fch	; af27  .............;;.
	defb 0f2h,0e0h,0e0h,0c0h,000h,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,060h	; af37  ...............`
	defb 0f0h,0f0h,0f8h,078h,030h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,006h	; af47  ...x0...........
	defb 00fh,00fh,01fh,01eh,00ch,001h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af57  ................
	defb 000h,000h,020h,078h,0f8h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af67  .. x............
	defb 000h,000h,004h,01eh,01fh,000h,007h,08dh,0ddh,0dfh,0fch,078h,070h,030h,033h,01fh	; af77  ...........xp03.
	defb 00fh,00fh,007h,003h,000h,000h,0e0h,0b1h,0bbh,0fbh,03fh,01eh,00eh,00ch,0cch,0f8h	; af87  ..........?.....
	defb 0f0h,0f0h,0e0h,0c0h,000h,000h,007h,00fh,01dh,01fh,03ch,078h,0f3h,0bfh,0bfh,0dfh	; af97  ..........<x....
	defb 05fh,03fh,01fh,003h,000h,000h,0e0h,0f0h,0b8h,0f8h,03ch,01eh,0cfh,0fdh,0fdh,0fbh	; afa7  _?........<.....
	defb 0fah,0fch,0f8h,0c0h,000h,0ffh,081h,081h,01fh,01fh,01fh,01fh,03fh,0ffh,081h,081h	; afb7  ............?...
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,081h,081h,0c0h,0e0h,0f0h,0f8h,0fch,03fh,03fh,03fh	; afc7  .............???
	defb 03fh,07fh,07fh,07fh,07fh,001h,001h,001h,001h,001h,003h,003h,003h,0feh,0ffh,0ffh	; afd7  ?...............
	defb 0feh,0feh,0feh,0feh,0fch,07fh,0ffh,0ffh,0ffh,0ffh,03fh,00fh,003h,003h,003h,007h	; afe7  ..........?.....
	defb 007h,0ffh,0ffh,0ffh,0ffh,0fch,0fch,0fch,0f8h,0f8h,0f8h,0f8h,0f0h,000h,001h,003h	; aff7  ................
	defb 003h,007h,007h,00fh,00fh,0ffh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,000h,000h,080h	; b007  .........?......
	defb 0c0h,0e0h,0f0h,0f8h,0fch,01fh,01fh,03fh,03fh,07fh,07fh,0ffh,0ffh,003h,001h,000h	; b017  .......??.......
	defb 0ffh,0ffh,0ffh,0feh,0feh,0feh,0ffh,0ffh,080h,000h,000h,0feh,0feh,07fh,03fh,01fh	; b027  ..............?.
	defb 00fh,007h,003h,001h,000h,0fch,0fch,0f8h,0f8h,0f0h,0f0h,0e0h,0e0h,0feh,0fch,0fch	; b037  ................
	defb 0f8h,0f8h,0f0h,0f0h,0e0h,000h,001h,003h,006h,00ch,018h,030h,060h,000h,0ffh,0ffh	; b047  ...........0`...
	defb 000h,000h,000h,000h,001h,000h,0feh,0feh,01eh,036h,066h,0c6h,086h,07fh,07fh,060h	; b057  .........6f....`
	defb 060h,060h,060h,060h,060h,0ffh,0ffh,003h,003h,003h,003h,003h,003h,006h,006h,006h	; b067  `````...........
	defb 006h,006h,006h,006h,006h,060h,060h,060h,060h,060h,060h,07fh,07fh,003h,003h,003h	; b077  .....``````.....
	defb 003h,003h,003h,0ffh,0ffh,006h,00ch,018h,030h,060h,0c0h,080h,000h,048h,0d0h,000h	; b087  ........0`...H..
	defb 048h,050h,000h,000h,022h,00bh,0ffh,087h,0fch,0f8h,0f8h,0fch,0feh,0f0h,080h,006h	; b097  HP.."...........
	defb 000h,008h,0feh,008h,000h,082h,0ffh,0c0h,004h,000h,08fh,060h,0f0h,0ffh,0ffh,03fh	; b0a7  ...........`...?
	defb 01fh,00fh,00fh,007h,006h,0feh,0f0h,0c0h,080h,080h,003h,001h,085h,01fh,003h,000h	; b0b7  ................
	defb 000h,0c0h,003h,0e0h,089h,0ffh,0feh,0f8h,070h,070h,038h,03ch,01ch,0e3h,003h,001h	; b0c7  ........pp8<....
	defb 002h,000h,002h,001h,082h,0e3h,080h,006h,000h,089h,0fch,0f0h,0e0h,060h,070h,07ch	; b0d7  .............`p|
	defb 07ch,0fch,001h,004h,000h,003h,001h,081h,0ffh,004h,00fh,003h,0ffh,081h,0f0h,006h	; b0e7  |...............
	defb 0f8h,081h,0f0h,007h,006h,081h,00eh,003h,000h,004h,001h,004h,000h,004h,0ffh,084h	; b0f7  ................
	defb 0feh,01ch,01ch,03ch,003h,0fch,082h,07ch,03ch,008h,001h,082h,080h,0e3h,006h,0ffh	; b107  ...<...|<.......
	defb 008h,0fch,084h,0feh,0fch,0fch,0f8h,004h,0ffh,003h,000h,087h,080h,0c0h,0f0h,0feh	; b117  ................
	defb 0ffh,0f0h,060h,004h,000h,087h,003h,0ffh,00fh,01fh,01fh,03fh,07fh,003h,0ffh,002h	; b127  ..`........?....
	defb 000h,002h,080h,085h,0c0h,0f0h,0fch,0ffh,038h,004h,000h,08ch,001h,007h,0ffh,03ch	; b137  ........8......<
	defb 038h,070h,060h,0e0h,0f0h,0fch,0ffh,001h,005h,000h,081h,001h,003h,0ffh,08ah,07fh	; b147  8p`.............
	defb 03fh,03fh,07fh,0ffh,0ffh,0fch,0fch,0feh,0feh,004h,0ffh,005h,000h,08dh,080h,0e0h	; b157  ??..............
	defb 0ffh,0c7h,007h,007h,00fh,00fh,01fh,07fh,0ffh,0fbh,000h,003h,0bfh,081h,000h,003h	; b167  ................
	defb 0fbh,092h,000h,0bfh,0c0h,0f0h,0f8h,0fch,0feh,0fbh,000h,0bfh,001h,007h,00fh,01fh	; b177  ................
	defb 03fh,0fbh,00fh,07fh,006h,0ffh,002h,03fh,002h,01fh,002h,00fh,084h,007h,0e0h,0e0h	; b187  ?......?........
	defb 0f8h,005h,0ffh,081h,0fbh,007h,0ffh,082h,0fbh,0f8h,006h,0ffh,082h,007h,01fh,005h	; b197  ................
	defb 0ffh,082h,0feh,003h,007h,000h,002h,0ffh,081h,03fh,005h,000h,083h,0fch,0f8h,0e0h	; b1a7  .........?......
	defb 005h,000h,00bh,0ffh,003h,0feh,002h,0fch,081h,080h,00bh,000h,002h,001h,002h,003h	; b1b7  ................
	defb 082h,01ch,07fh,006h,0ffh,002h,000h,002h,080h,002h,0c0h,002h,0e0h,083h,0ffh,07fh	; b1c7  ................
	defb 07fh,003h,03fh,002h,01fh,002h,0fch,006h,0f8h,081h,003h,004h,007h,003h,00fh,081h	; b1d7  ..?.............
	defb 0e0h,004h,0f0h,003h,0f8h,002h,01fh,006h,00fh,007h,0f8h,081h,0fch,004h,00fh,004h	; b1e7  ................
	defb 007h,005h,0f8h,003h,0f0h,007h,00fh,081h,01fh,003h,0fch,003h,0feh,002h,0ffh,003h	; b1f7  ................
	defb 003h,002h,001h,003h,000h,08ch,0ffh,0f3h,0e0h,0e0h,0f8h,0f8h,0fch,07ch,0f0h,0e0h	; b207  .............|..
	defb 0e0h,060h,004h,000h,003h,01fh,003h,03fh,002h,07fh,088h,080h,0c0h,0e0h,0f0h,0f8h	; b217  .`.....?........
	defb 0feh,0ffh,0ffh,006h,000h,083h,080h,0f0h,018h,009h,000h,08bh,001h,003h,007h,00fh	; b227  ................
	defb 03fh,03fh,02eh,0e4h,0eah,0eah,0eeh,003h,0ffh,081h,0f8h,004h,0feh,083h,0f1h,0c1h	; b237  ??..............
	defb 001h,080h,000h,002h,07fh,0f4h,07fh,0f4h,01ah,0f4h,002h,040h,098h,070h,050h,040h	; b247  ...........@.pP@
	defb 040h,070h,050h,040h,040h,070h,085h,084h,080h,087h,084h,040h,040h,070h,085h,084h	; b257  @pP@@p.....@@p..
	defb 080h,087h,085h,040h,080h,007h,087h,089h,080h,087h,085h,084h,080h,087h,085h,084h	; b267  ...@............
	defb 080h,006h,087h,081h,040h,007h,088h,081h,040h,007h,080h,081h,084h,027h,080h,07fh	; b277  ....@...@....'..
	defb 0f8h,046h,0f8h,003h,0f4h,080h,000h,02ah,00bh,0ffh,087h,0fch,0f8h,0f8h,0fch,0feh	; b287  .F.....*........
	defb 0f0h,080h,006h,000h,008h,0feh,008h,000h,082h,0ffh,0c0h,004h,000h,08fh,060h,0f0h	; b297  ..............`.
	defb 0ffh,0ffh,03fh,01fh,00fh,00fh,007h,006h,0feh,0f0h,0c0h,080h,080h,003h,001h,085h	; b2a7  ..?.............
	defb 01fh,003h,000h,000h,0c0h,003h,0e0h,089h,0ffh,0feh,0f8h,070h,070h,038h,03ch,01ch	; b2b7  ...........pp8<.
	defb 0e3h,003h,001h,002h,000h,002h,001h,082h,0e3h,080h,006h,000h,089h,0fch,0f0h,0e0h	; b2c7  ................
	defb 060h,070h,07ch,07ch,0fch,001h,004h,000h,003h,001h,081h,0ffh,004h,00fh,003h,0ffh	; b2d7  `p||............
	defb 081h,0f0h,006h,0f8h,081h,0f0h,007h,006h,081h,00eh,003h,000h,004h,001h,004h,000h	; b2e7  ................
	defb 004h,0ffh,084h,0feh,01ch,01ch,03ch,003h,0fch,082h,07ch,03ch,008h,001h,082h,080h	; b2f7  ......<...|<....
	defb 0e3h,006h,0ffh,008h,0fch,084h,0feh,0fch,0fch,0f8h,004h,0ffh,003h,000h,087h,080h	; b307  ................
	defb 0c0h,0f0h,0feh,0ffh,0f0h,060h,004h,000h,087h,003h,0ffh,00fh,01fh,01fh,03fh,07fh	; b317  .....`........?.
	defb 003h,0ffh,002h,000h,002h,080h,085h,0c0h,0f0h,0fch,0ffh,038h,004h,000h,08ch,001h	; b327  ...........8....
	defb 007h,0ffh,03ch,038h,070h,060h,0e0h,0f0h,0fch,0ffh,001h,005h,000h,081h,001h,003h	; b337  ..<8p`..........
	defb 0ffh,08ah,07fh,03fh,03fh,07fh,0ffh,0ffh,0fch,0fch,0feh,0feh,004h,0ffh,005h,000h	; b347  ...??...........
	defb 08dh,080h,0e0h,0ffh,0c7h,007h,007h,00fh,00fh,01fh,07fh,0ffh,0fbh,000h,003h,0bfh	; b357  ................
	defb 081h,000h,003h,0fbh,092h,000h,0bfh,0c0h,0f0h,0f8h,0fch,0feh,0fbh,000h,0bfh,001h	; b367  ................
	defb 007h,00fh,01fh,03fh,0fbh,00fh,07fh,006h,0ffh,002h,03fh,002h,01fh,002h,00fh,084h	; b377  ...?......?.....
	defb 007h,0e0h,0e0h,0f8h,005h,0ffh,081h,0fbh,007h,0ffh,082h,0fbh,0f8h,006h,0ffh,082h	; b387  ................
	defb 007h,01fh,005h,0ffh,082h,0feh,003h,007h,000h,002h,0ffh,081h,03fh,005h,000h,083h	; b397  ............?...
	defb 0fch,0f8h,0e0h,005h,000h,00bh,0ffh,003h,0feh,002h,0fch,081h,080h,00bh,000h,002h	; b3a7  ................
	defb 001h,002h,003h,082h,01ch,07fh,006h,0ffh,002h,000h,002h,080h,002h,0c0h,002h,0e0h	; b3b7  ................
	defb 083h,0ffh,07fh,07fh,003h,03fh,002h,01fh,002h,0fch,006h,0f8h,081h,003h,004h,007h	; b3c7  .....?..........
	defb 003h,00fh,081h,0e0h,004h,0f0h,003h,0f8h,002h,01fh,006h,00fh,007h,0f8h,081h,0fch	; b3d7  ................
	defb 004h,00fh,004h,007h,005h,0f8h,003h,0f0h,007h,00fh,081h,01fh,003h,0fch,003h,0feh	; b3e7  ................
	defb 002h,0ffh,003h,003h,002h,001h,003h,000h,08ch,0ffh,0f3h,0e0h,0e0h,0f8h,0f8h,0fch	; b3f7  ................
	defb 07ch,0f0h,0e0h,0e0h,060h,004h,000h,003h,01fh,003h,03fh,002h,07fh,088h,080h,0c0h	; b407  |...`.....?.....
	defb 0e0h,0f0h,0f8h,0feh,0ffh,0ffh,006h,000h,083h,080h,0f0h,018h,009h,000h,08bh,001h	; b417  ................
	defb 003h,007h,00fh,03fh,03fh,02eh,0e4h,0eah,0eah,0eeh,003h,0ffh,081h,0f8h,004h,0feh	; b427  ...??...........
	defb 0bah,0f1h,0c1h,001h,03fh,07fh,0fdh,0fch,0fch,0f8h,080h,0c0h,0fch,0feh,0ffh,0ffh	; b437  ....?...........
	defb 07fh,003h,007h,00fh,0f0h,0f8h,0f8h,0f9h,07fh,03fh,001h,003h,00fh,007h,0c3h,0ffh	; b447  .........?......
	defb 0feh,0fch,0c0h,000h,0fch,0feh,09fh,08fh,087h,0a3h,0b3h,0bbh,0f8h,0f0h,0f0h,0f8h	; b457  ................
	defb 07fh,03fh,001h,003h,0bfh,03fh,03fh,07fh,0feh,0fch,0c0h,005h,000h,004h,080h,008h	; b467  .?...??.........
	defb 0bfh,088h,000h,003h,00fh,01fh,03fh,03fh,0bfh,0bfh,008h,07ch,082h,0e0h,0f8h,006h	; b477  ......??...|....
	defb 0fch,002h,0ffh,086h,000h,003h,001h,001h,000h,000h,008h,0f0h,0bah,01fh,07fh,0ffh	; b487  ................
	defb 0fch,0f8h,0f8h,0f0h,0f0h,000h,001h,002h,004h,008h,010h,020h,041h,000h,080h,0e0h	; b497  ........... A...
	defb 050h,028h,054h,08ah,005h,000h,000h,07fh,060h,050h,048h,047h,044h,000h,000h,0f0h	; b4a7  P(T.....`PHGD...
	defb 018h,014h,014h,0fch,014h,000h,001h,007h,00ah,014h,02ah,051h,0a0h,000h,080h,040h	; b4b7  ..........*Q...@
	defb 020h,010h,008h,004h,082h,0ffh,0ffh,003h,000h,085h,053h,000h,04ch,0ffh,0ffh,003h	; b4c7   .........S.L...
	defb 000h,085h,053h,000h,04ch,03fh,07fh,006h,0ffh,003h,000h,081h,001h,004h,003h,003h	; b4d7  ..S.L?..........
	defb 000h,081h,080h,004h,0c0h,002h,003h,081h,001h,005h,000h,002h,0c0h,081h,080h,005h	; b4e7  ................
	defb 000h,0c2h,03fh,07fh,0ffh,0f8h,0fbh,0f8h,0fbh,0fbh,0fch,0feh,087h,077h,087h,077h	; b4f7  ..?..........w.w
	defb 0f7h,0f7h,0cbh,082h,082h,0c7h,07fh,03fh,001h,003h,017h,007h,007h,00fh,0feh,0fch	; b507  .......?........
	defb 0c0h,000h,03fh,07fh,0f0h,0e0h,0e3h,0e7h,0f7h,0fch,0fch,0feh,03fh,01fh,09fh,09fh	; b517  ..?.........?...
	defb 01fh,03fh,0fch,0ffh,0fch,0fch,07fh,03fh,001h,003h,07fh,0ffh,07fh,07fh,0feh,0fch	; b527  .?.....?........
	defb 0c0h,000h,0fch,0feh,006h,0bfh,090h,0f8h,0f0h,0f0h,0f8h,07fh,03fh,001h,003h,0bfh	; b537  ............?...
	defb 03fh,03fh,07fh,0feh,0fch,0c0h,000h,080h,000h,00ah,07fh,0f4h,07fh,0f4h,01ah,0f4h	; b547  ??..............
	defb 002h,040h,098h,070h,050h,040h,040h,070h,050h,040h,040h,070h,085h,084h,080h,087h	; b557  .@.pP@@pP@@p....
	defb 084h,040h,040h,070h,085h,084h,080h,087h,085h,040h,080h,007h,087h,089h,080h,087h	; b567  .@@p.....@......
	defb 085h,084h,080h,087h,085h,084h,080h,006h,087h,081h,040h,007h,088h,081h,040h,007h	; b577  ..........@...@.
	defb 080h,081h,084h,027h,080h,07fh,0f8h,046h,0f8h,003h,0f4h,002h,0f0h,006h,0f8h,004h	; b587  ...'...F........
	defb 0f0h,008h,0f8h,004h,0f0h,003h,0f8h,007h,0f0h,00ah,0f8h,004h,0f0h,004h,0f8h,004h	; b597  ................
	defb 0f0h,008h,040h,008h,054h,006h,050h,002h,054h,010h,050h,003h,075h,005h,050h,008h	; b5a7  ..@.T.P.T.P.u.P.
	defb 074h,002h,075h,005h,070h,081h,074h,030h,0a4h,003h,075h,005h,0a0h,003h,075h,004h	; b5b7  t.u.p.t0..u...u.
	defb 0a0h,081h,0a4h,02bh,0f0h,005h,0fch,002h,0f0h,00ah,0fch,004h,0f0h,004h,0fch,006h	; b5c7  ...+............
	defb 0f0h,006h,0fdh,002h,0f0h,00ah,0fdh,004h,0f0h,004h,0fdh,006h,0f0h,00ah,0f4h,004h	; b5d7  ................
	defb 0f0h,004h,0f4h,004h,0f0h,080h,000h,030h,010h,000h,008h,0ffh,006h,000h,08ah,01fh	; b5e7  .......0........
	defb 03fh,03fh,01fh,00fh,007h,003h,001h,000h,000h,007h,0ffh,081h,07fh,005h,080h,003h	; b5f7  ??..............
	defb 000h,002h,07ch,006h,0fch,006h,0ffh,006h,000h,08ch,003h,001h,000h,000h,0e0h,0feh	; b607  ..|.............
	defb 0ffh,0feh,0f8h,080h,000h,000h,003h,03fh,085h,01fh,00fh,007h,003h,000h,008h,0bfh	; b617  .......?........
	defb 084h,00fh,083h,0e0h,0fch,004h,0ffh,085h,07fh,01fh,00fh,003h,001h,003h,000h,003h	; b627  ................
	defb 0bfh,085h,03fh,01fh,007h,0f1h,07eh,005h,000h,093h,080h,0c0h,0e0h,0feh,041h,020h	; b637  ..?...~.......A 
	defb 010h,008h,004h,002h,001h,003h,005h,08ah,054h,028h,050h,0e0h,080h,004h,044h,084h	; b647  ........T(P...D.
	defb 07fh,024h,01fh,000h,004h,014h,094h,0f4h,00ch,0fch,000h,0c0h,0a0h,051h,02ah,014h	; b657  .$...........Q*.
	defb 00ah,007h,001h,07fh,082h,004h,008h,010h,020h,040h,080h,00ch,0f0h,099h,0f8h,0feh	; b667  ........ @......
	defb 07fh,03fh,0fch,07fh,01fh,007h,001h,03fh,01fh,007h,01fh,07fh,0ffh,0fch,0f8h,0f8h	; b677  .?.....?........
	defb 0f0h,0f0h,024h,0ffh,0ffh,000h,0ffh,003h,000h,002h,0f0h,088h,0f8h,07ch,01ch,0f0h	; b687  ..$..........|..
	defb 001h,001h,000h,0ffh,003h,0f8h,088h,0ffh,0c4h,0f8h,01fh,01fh,0e0h,0ffh,0ffh,004h	; b697  ................
	defb 000h,081h,0ffh,003h,0fch,090h,0ffh,025h,05bh,0e8h,000h,0b3h,000h,000h,0ffh,0b7h	; b6a7  .......%[.......
	defb 000h,0f8h,0feh,085h,000h,000h,003h,0ffh,002h,0e0h,005h,000h,085h,0c0h,000h,03fh	; b6b7  ...............?
	defb 0ffh,0c0h,003h,000h,002h,0ffh,083h,0fch,0ffh,003h,004h,000h,002h,007h,006h,000h	; b6c7  ................
	defb 002h,0feh,08eh,0c0h,003h,01fh,0feh,0fch,0f0h,07fh,07fh,000h,080h,0e0h,07fh,03fh	; b6d7  ...............?
	defb 00fh,00bh,0ffh,083h,001h,00fh,003h,003h,0ffh,082h,07fh,00fh,003h,000h,002h,0ffh	; b6e7  ................
	defb 088h,007h,07fh,080h,0f8h,007h,007h,000h,000h,004h,0ffh,098h,000h,0ffh,000h,000h	; b6f7  ................
	defb 080h,0e0h,0f0h,0fch,0ffh,0ffh,000h,000h,01fh,001h,001h,01fh,0e0h,0ffh,000h,000h	; b707  ................
	defb 0ffh,0ffh,000h,000h,003h,03fh,085h,0ffh,000h,000h,0ffh,0ffh,003h,0fch,083h,0ffh	; b717  .....?..........
	defb 0c0h,080h,006h,000h,084h,007h,001h,006h,008h,004h,000h,008h,0ffh,085h,003h,007h	; b727  ................
	defb 00fh,00fh,03fh,003h,0ffh,085h,0fch,0f8h,0f0h,0e0h,080h,004h,000h,007h,080h,004h	; b737  ..?.............
	defb 000h,096h,0c0h,0e0h,0f0h,0f8h,01fh,01fh,03fh,03fh,07fh,079h,079h,07bh,0ffh,0e7h	; b747  ........??.yy{..
	defb 0fbh,0ffh,0e7h,0e7h,0efh,0e7h,0feh,0feh,006h,0ffh,002h,0f9h,004h,0ffh,083h,0f9h	; b757  ................
	defb 0f6h,0e7h,007h,0ffh,081h,0f7h,007h,0ffh,003h,0c0h,002h,080h,003h,000h,006h,0ffh	; b767  ................
	defb 002h,0feh,003h,0ffh,08ch,07fh,0bfh,0bfh,0dfh,0efh,0ffh,08fh,070h,06fh,0b7h,0dbh	; b777  ............po..
	defb 0ffh,004h,07fh,088h,07eh,07dh,07dh,07eh,0bfh,000h,080h,080h,006h,0c0h,002h,080h	; b787  ....~}}~........
	defb 002h,000h,09bh,080h,0e0h,0fch,0bfh,0dfh,03fh,0dfh,0e7h,0fbh,0fdh,0feh,0fdh,0fbh	; b797  ........?.......
	defb 0fch,0fbh,0e7h,0dfh,0bfh,07fh,0ffh,0feh,000h,0e0h,0f0h,0cch,0b8h,0e6h,005h,000h	; b7a7  ................
	defb 088h,080h,0c0h,0e0h,00fh,01fh,09fh,0bfh,0bfh,003h,07fh,004h,0ffh,002h,0fdh,081h	; b7b7  ................
	defb 0feh,006h,0ffh,088h,07fh,08fh,0f7h,0f0h,0f8h,0f9h,0fdh,0fch,003h,0feh,002h,000h	; b7c7  ................
	defb 083h,0c0h,0e0h,0f0h,003h,0f8h,002h,000h,086h,0c0h,0f0h,078h,07ch,03ch,03eh,003h	; b7d7  ...........x|<>.
	defb 0f3h,082h,0fbh,0f3h,005h,0ffh,08bh,03fh,0dfh,0e7h,0fbh,0fdh,0feh,0c7h,083h,080h	; b7e7  .......?........
	defb 0c0h,0f0h,003h,0ffh,085h,0e3h,0c1h,001h,003h,00fh,005h,0ffh,08eh,0fch,0fbh,0e7h	; b7f7  ................
	defb 0dfh,0bfh,07fh,0feh,0feh,0fch,0fch,0f8h,0f0h,0e0h,080h,003h,0cfh,085h,0dfh,0cfh	; b807  ................
	defb 00eh,006h,000h,005h,080h,083h,001h,003h,007h,005h,080h,083h,003h,007h,00fh,005h	; b817  ................
	defb 080h,002h,000h,089h,001h,0feh,0feh,0ffh,0ffh,0fdh,0f9h,0f9h,0f1h,003h,0e1h,002h	; b827  ................
	defb 0f3h,081h,0f7h,003h,0ffh,002h,0feh,004h,0fch,007h,0feh,002h,0ffh,091h,0f1h,0f9h	; b837  ................
	defb 0f9h,0fbh,0ffh,0fch,0fch,0feh,01fh,01fh,03fh,03fh,07fh,07fh,0ffh,07fh,07fh,006h	; b847  ........??......
	defb 03fh,08ch,07fh,0feh,0feh,0ffh,0ffh,0f1h,083h,007h,00fh,0feh,0fch,0fch,004h,0f8h	; b857  ?...............
	defb 084h,0fch,07fh,03fh,03fh,004h,01fh,08bh,03fh,0c3h,0e1h,021h,010h,098h,0deh,0e3h	; b867  ...??...?..!....
	defb 0f3h,0fch,0feh,006h,0ffh,082h,03fh,07fh,006h,0ffh,002h,0e0h,098h,0c0h,098h,043h	; b877  ......?........C
	defb 081h,000h,0ffh,003h,00fh,003h,007h,00fh,03fh,0ffh,0feh,080h,080h,000h,0c0h,040h	; b887  ........?......@
	defb 060h,070h,078h,0fch,0fch,004h,0feh,0a7h,07fh,03fh,000h,000h,0fch,0cfh,0c0h,0e0h	; b897  `px......?......
	defb 0e0h,0f0h,000h,000h,0e0h,0fch,0ffh,0ffh,0feh,0feh,000h,000h,080h,0c0h,0c0h,0e0h	; b8a7  ................
	defb 0f0h,0fch,0feh,0ffh,07fh,0bfh,0dfh,0efh,0f7h,0f7h,080h,000h,080h,0c0h,0c0h,004h	; b8b7  ................
	defb 0e0h,002h,0c0h,002h,080h,083h,0c0h,0e0h,0e0h,003h,0fbh,005h,0fdh,083h,0f8h,071h	; b8c7  ...............q
	defb 0feh,003h,0ffh,002h,07fh,085h,0c0h,0e0h,0f0h,0f8h,0feh,003h,0ffh,0ach,03eh,00fh	; b8d7  ..............>.
	defb 01fh,01fh,03fh,07fh,0ffh,0feh,078h,0f0h,0f0h,0e0h,0e0h,0c1h,0c3h,081h,083h,007h	; b8e7  ..?...x.........
	defb 01fh,0efh,0f3h,0cdh,0b9h,0e6h,007h,007h,003h,001h,001h,000h,000h,070h,000h,0c0h	; b8f7  .............p..
	defb 0f0h,0f8h,0fch,0fch,0feh,0cfh,0e0h,0c0h,0c0h,080h,004h,000h,081h,0e0h,004h,0c0h	; b907  ................
	defb 084h,0e0h,0f0h,0f8h,0e0h,003h,0c0h,004h,080h,004h,0ffh,002h,0fbh,083h,039h,001h	; b917  ..............9.
	defb 07fh,004h,0bfh,002h,03fh,081h,01eh,005h,0ffh,086h,0efh,0dfh,000h,0ffh,07fh,07fh	; b927  ....?...........
	defb 003h,0bfh,085h,00fh,000h,0ffh,0feh,0feh,003h,0fdh,09dh,0f0h,000h,0ffh,03fh,04fh	; b937  ..............?O
	defb 0b0h,0bfh,0bfh,00fh,000h,0ffh,0fch,0f0h,001h,0fdh,0fdh,0f0h,000h,078h,0f0h,0e0h	; b947  .............x..
	defb 0c0h,080h,000h,0f0h,0fch,007h,003h,001h,003h,000h,092h,00fh,03fh,03fh,01fh,00fh	; b957  ............??..
	defb 003h,000h,000h,00fh,03fh,07fh,03fh,00fh,007h,003h,001h,00fh,03fh,005h,0ffh,083h	; b967  ....?.?.....?...
	defb 0feh,0f0h,0fch,004h,0ffh,084h,0feh,0fch,0fch,078h,004h,001h,089h,00fh,003h,000h	; b977  .........x......
	defb 000h,003h,007h,00fh,01fh,03fh,003h,0ffh,083h,000h,07fh,00fh,003h,000h,091h,001h	; b987  .....?..........
	defb 003h,0bfh,0dfh,0efh,0f7h,0f9h,0feh,07fh,03ch,0feh,0fdh,0fdh,0fbh,0fbh,0efh,080h	; b997  ........<.......
	defb 004h,0ffh,0b9h,0f7h,07bh,03ch,00fh,000h,01fh,03fh,07fh,0ffh,0ffh,0feh,0fch,0f0h	; b9a7  ....{<...?......
	defb 07fh,0feh,0feh,0fdh,0fbh,0f7h,0f6h,0e0h,0f0h,0f0h,0f8h,0fch,0feh,0ffh,07fh,07fh	; b9b7  ................
	defb 0feh,0ffh,01fh,00fh,087h,0c7h,0e7h,03ch,07fh,0ffh,0f8h,0f0h,0e1h,0e3h,0e7h,03ch	; b9c7  .......<.......<
	defb 03fh,01fh,0f0h,0f8h,003h,0fch,0fch,0ffh,0c0h,080h,0ffh,01fh,003h,0fch,081h,000h	; b9d7  ?...............
	defb 003h,0ffh,091h,003h,0e0h,03fh,03fh,0ffh,07ch,07ch,007h,01fh,03fh,07fh,0ffh,0ffh	; b9e7  .....??.||..?...
	defb 07ch,07ch,007h,07fh,004h,0ffh,08dh,003h,007h,00fh,00fh,01fh,03fh,0ffh,0ffh,003h	; b9f7  ||..........?...
	defb 007h,00fh,01fh,07fh,003h,0ffh,083h,0fch,01fh,07fh,003h,0ffh,002h,0feh,0a0h,001h	; ba07  ................
	defb 0ffh,000h,007h,00fh,033h,01dh,067h,07fh,0c0h,0ffh,007h,00fh,033h,01dh,067h,0ffh	; ba17  ....3.g.....3.g.
	defb 0fch,085h,003h,007h,00fh,0e0h,01fh,01eh,00fh,00fh,007h,0f8h,0fch,003h,001h,004h	; ba27  ................
	defb 000h,089h,001h,003h,007h,00fh,00fh,01fh,03fh,03fh,0c0h,003h,0bfh,093h,000h,0ffh	; ba37  ........??......
	defb 000h,000h,0ffh,0feh,007h,03fh,03fh,07fh,07fh,03eh,0ffh,001h,0ffh,0e7h,0fch,003h	; ba47  .....??..>......
	defb 001h,003h,0ffh,08ah,01eh,0ffh,007h,0f8h,0f0h,01fh,01fh,00eh,000h,000h,003h,0ffh	; ba57  ................
	defb 0a7h,07fh,0c0h,080h,07fh,07fh,0ffh,0ffh,0dfh,03fh,080h,080h,07fh,07fh,0f8h,0feh	; ba67  .........?......
	defb 085h,070h,0ffh,0ffh,080h,01fh,0ffh,080h,0ffh,007h,00fh,033h,01dh,067h,000h,0ffh	; ba77  .p.........3.g..
	defb 000h,000h,0ffh,0feh,003h,00fh,07fh,080h,003h,07fh,002h,0bfh,0a1h,0dfh,001h,003h	; ba87  ................
	defb 007h,007h,0f0h,0e0h,01eh,01ch,007h,003h,0ffh,0ffh,000h,0ffh,000h,0e7h,0f8h,0feh	; ba97  ................
	defb 085h,0c0h,000h,0ffh,0feh,00fh,092h,0ffh,0feh,003h,007h,007h,00fh,00fh,004h,0ffh	; baa7  ................
	defb 08eh,0dfh,0bfh,07fh,07fh,003h,007h,00fh,00fh,01fh,01fh,080h,0ffh,0fbh,000h,003h	; bab7  ................
	defb 0bfh,08eh,000h,0fbh,0fbh,0ffh,03fh,03fh,01fh,01fh,00fh,00fh,007h,0e0h,0e0h,0f8h	; bac7  ......??........
	defb 005h,0ffh,082h,007h,01fh,005h,0ffh,082h,0feh,003h,007h,000h,002h,0ffh,081h,03fh	; bad7  ...............?
	defb 005h,000h,083h,0fch,0f8h,0e0h,005h,000h,088h,0feh,0fch,0f0h,0e0h,0c0h,080h,0f0h	; bae7  ................
	defb 0fch,080h,000h,010h,038h,040h,028h,050h,01bh,054h,003h,050h,002h,054h,007h,040h	; baf7  ....8@(P.T.P.T.@
	defb 081h,050h,030h,0a4h,00dh,074h,002h,075h,002h,074h,004h,075h,003h,054h,002h,075h	; bb07  .P0..t.u.t.u.T.u
	defb 005h,070h,086h,074h,075h,0f5h,0e5h,074h,074h,003h,075h,002h,050h,003h,054h,088h	; bb17  .p.tu..tt.u.P.T.
	defb 074h,0e7h,0e7h,040h,040h,050h,050h,0f0h,003h,0f5h,082h,0feh,0e4h,003h,074h,003h	; bb27  t..@@PP.......t.
	defb 0e5h,002h,040h,086h,0a0h,090h,090h,0eeh,075h,075h,005h,0a4h,086h,055h,0f7h,0f7h	; bb37  ..@.....uu...U..
	defb 040h,040h,0a4h,003h,050h,082h,0f0h,075h,007h,0f0h,081h,050h,003h,0fch,004h,0f0h	; bb47  @@..P..u...P....
	defb 083h,050h,0c0h,0ech,00eh,0e0h,002h,020h,003h,0c2h,003h,0c0h,002h,020h,003h,0c2h	; bb57  .P..... ..... ..
	defb 003h,0c0h,018h,0c2h,002h,0c0h,002h,0ech,081h,0e5h,003h,050h,005h,0ceh,003h,050h	; bb67  ...........P...P
	defb 004h,0c2h,081h,0e5h,003h,050h,002h,052h,002h,0f2h,081h,0e5h,003h,050h,004h,0ceh	; bb77  .....P.R.....P..
	defb 004h,0c0h,002h,0fch,002h,0e0h,081h,0c0h,003h,020h,010h,0f0h,030h,0d0h,081h,0ddh	; bb87  ......... ..0...
	defb 07fh,0d0h,065h,0d0h,003h,0fdh,005h,040h,003h,0d0h,005h,040h,003h,0d0h,007h,040h	; bb97  ..e....@...@...@
	defb 081h,0d0h,068h,0dah,004h,0a0h,004h,0dah,002h,0d0h,005h,0dah,004h,0d0h,085h,0a0h	; bba7  ..h.............
	defb 0d0h,0a0h,0d0h,0a0h,006h,0d0h,002h,0dah,003h,0d0h,005h,0dah,002h,0d0h,004h,0dah	; bbb7  ................
	defb 004h,0d0h,004h,0a0h,083h,0d0h,0dah,0dah,007h,0d0h,081h,0a0h,00bh,0d0h,004h,0a0h	; bbc7  ................
	defb 081h,0dah,007h,0d0h,081h,0a0h,007h,0dah,003h,0a0h,006h,0d0h,005h,0dah,009h,0d0h	; bbd7  ................
	defb 003h,0dah,00bh,0d0h,004h,0a0h,006h,0d0h,081h,0dah,01ch,0dch,002h,0d0h,002h,0dch	; bbe7  ................
	defb 006h,0d0h,002h,0dch,007h,0d0h,081h,0dch,006h,0d0h,002h,0dch,006h,0d0h,002h,0dch	; bbf7  ................
	defb 006h,0d0h,002h,0dch,006h,0d0h,002h,0dch,006h,0d0h,002h,020h,006h,0d0h,002h,020h	; bc07  ........... ... 
	defb 006h,0d0h,002h,020h,006h,0d0h,002h,020h,006h,0d0h,002h,020h,007h,0d0h,081h,0d2h	; bc17  ... ... ... ....
	defb 003h,0dch,083h,0d2h,0c2h,0c2h,005h,0dch,002h,0d2h,004h,0dch,002h,0c2h,003h,0d2h	; bc27  ................
	defb 002h,0dch,006h,0d0h,082h,0d2h,0dch,006h,0d0h,082h,0d2h,0cch,006h,0d0h,082h,0d2h	; bc37  ................
	defb 0dch,005h,0dah,003h,0dch,081h,0dah,005h,0d0h,082h,0d2h,0dch,006h,0dah,002h,0dch	; bc47  ................
	defb 081h,0d0h,006h,0dah,083h,0dch,0d0h,0d0h,005h,0dah,003h,0dch,002h,0edh,081h,0dch	; bc57  ................
	defb 003h,020h,002h,0dch,08bh,0edh,0feh,0c0h,020h,020h,0c2h,0d0h,0d0h,0d5h,0edh,0dch	; bc67  . ......  ......
	defb 003h,0c0h,002h,050h,006h,0d5h,002h,050h,006h,0d5h,005h,0d0h,003h,0d5h,003h,0a5h	; bc77  ...P...P........
	defb 005h,0d5h,081h,050h,005h,0d5h,002h,0dah,085h,0d7h,0feh,0feh,0d4h,0d7h,003h,0d5h	; bc87  ...P............
	defb 085h,0d7h,0fdh,0eah,0d4h,0d7h,003h,0d5h,002h,040h,08eh,0a4h,0d0h,0d0h,0d5h,0fdh	; bc97  .........@......
	defb 0d7h,0d0h,0d4h,0d5h,0d5h,0fdh,0edh,0d7h,0d7h,005h,0d0h,088h,0d5h,0d7h,0d7h,0d0h	; bca7  ................
	defb 0d4h,0d5h,0d5h,0fdh,004h,0d0h,003h,045h,08fh,0ffh,0edh,0d7h,0d7h,0d0h,0d4h,0d5h	; bcb7  .......E........
	defb 0d5h,0feh,0feh,075h,075h,0dch,0fdh,0fdh,004h,0d0h,084h,050h,0dch,0edh,0edh,003h	; bcc7  ...uu......P....
	defb 0d0h,002h,070h,004h,0d5h,082h,0fdh,0edh,004h,0d7h,089h,0d0h,0d5h,0fdh,0edh,0d7h	; bcd7  ..p.............
	defb 0d7h,040h,040h,0a4h,003h,0d0h,087h,0fdh,0d7h,0d0h,0fdh,0eeh,0d4h,0d7h,003h,0d5h	; bce7  .@@.............
	defb 081h,000h,003h,045h,087h,0ffh,0edh,0d7h,0d7h,0d5h,0fdh,0dah,006h,0d0h,089h,0d4h	; bcf7  ...E............
	defb 0d5h,0d5h,0fdh,0edh,0d7h,0d7h,0d0h,0d4h,003h,05fh,002h,0e7h,090h,075h,040h,040h	; bd07  ........._...u@@
	defb 0a4h,040h,040h,055h,0fdh,0d7h,075h,0fdh,0eah,0d4h,0a7h,0d5h,0a5h,005h,0d5h,002h	; bd17  .@@U..u.........
	defb 0d0h,002h,0d7h,005h,0d0h,095h,0d5h,0fdh,0d5h,040h,040h,070h,050h,040h,040h,070h	; bd27  .........@@pP@@p
	defb 050h,080h,080h,087h,085h,084h,080h,087h,085h,084h,080h,006h,087h,081h,084h,00fh	; bd37  P...............
	defb 080h,002h,088h,00eh,080h,006h,0d0h,002h,020h,080h,000h,018h,084h,01fh,00fh,007h	; bd47  ........ .......
	defb 001h,00dh,000h,088h,080h,0e0h,0fch,07fh,03fh,00fh,003h,001h,00bh,000h,08ah,080h	; bd57  ........?.......
	defb 0c0h,0e0h,070h,038h,01ch,00eh,007h,003h,001h,003h,000h,082h,001h,003h,009h,007h	; bd67  ..p8............
	defb 088h,087h,0c7h,0e7h,07fh,0e0h,0f8h,07ch,03ch,00ch,01ch,020h,000h,002h,01ch,081h	; bd77  .......|<.. ....
	defb 018h,01eh,000h,087h,080h,060h,030h,018h,00ch,006h,003h,020h,000h,0a7h,001h,003h	; bd87  .....`0.... ....
	defb 006h,00ch,018h,030h,060h,080h,000h,001h,003h,007h,00fh,01fh,03fh,07fh,0ffh,07fh	; bd97  ...0`.......?...
	defb 03fh,01fh,00fh,007h,003h,001h,000h,000h,080h,0c0h,0e0h,0f0h,0f8h,0fch,0feh,0fch	; bda7  ?...............
	defb 0f8h,0f0h,0e0h,0c0h,080h,014h,000h,081h,008h,009h,00ch,081h,004h,00fh,000h,082h	; bdb7  ................
	defb 03fh,01fh,00eh,000h,082h,0f8h,0fch,003h,000h,00bh,07fh,005h,000h,00bh,0f0h,006h	; bdc7  ?...............
	defb 000h,08bh,001h,003h,007h,00fh,01fh,03fh,01fh,00fh,007h,003h,001h,004h,000h,08dh	; bdd7  .......?........
	defb 0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,0feh,0fch,0f8h,0f0h,0e0h,0c0h,009h,000h,087h	; bde7  ................
	defb 0c0h,0e0h,070h,038h,01ch,00eh,007h,012h,000h,087h,001h,007h,00eh,01ch,038h,070h	; bdf7  ..p8..........8p
	defb 0e0h,009h,000h,081h,080h,010h,000h,082h,00fh,01fh,00eh,000h,082h,0fch,0f8h,01eh	; be07  ................
	defb 000h,081h,002h,00ah,006h,081h,004h,006h,000h,00bh,03fh,005h,000h,00bh,0f8h,003h	; be17  ..........?.....
	defb 000h,084h,0c0h,0e0h,070h,030h,00bh,000h,081h,01ch,003h,00eh,081h,006h,01ah,000h	; be27  ....p0..........
	defb 009h,01ch,017h,000h,083h,01ch,018h,010h,00dh,000h,002h,001h,002h,003h,002h,007h	; be37  ................
	defb 083h,0ffh,07fh,03fh,003h,01fh,083h,03eh,038h,070h,003h,000h,002h,080h,002h,0c0h	; be47  ...?...>8p......
	defb 083h,0feh,0fch,0f8h,003h,0f0h,084h,0f8h,038h,00ch,000h,000h,000h,032h,090h,000h	; be57  ........8....2..
	defb 0c0h,0f0h,0fch,0feh,0feh,0ffh,0ffh,000h,000h,060h,0f0h,0f8h,0f8h,0fch,07ch,003h	; be67  .........`....|.
	defb 007h,082h,00fh,01fh,003h,03fh,004h,0fdh,084h,0ffh,0f7h,0f1h,0feh,004h,0dfh,09ch	; be77  .....?..........
	defb 0ffh,0f7h,0e7h,01fh,080h,080h,0c0h,0c0h,0e0h,0e0h,0f0h,0f8h,07eh,07fh,03fh,03fh	; be87  ............~.??
	defb 01fh,01fh,00fh,00fh,07fh,07dh,07bh,03dh,0deh,0eeh,0edh,0f3h,008h,0ffh,08bh,0d8h	; be97  .....}{=........
	defb 0dch,0ech,0ech,0e8h,0d0h,0b8h,0b8h,007h,003h,001h,003h,000h,08ah,001h,003h,0ffh	; bea7  ................
	defb 0ffh,0dfh,0dfh,03fh,0ffh,0b7h,06fh,005h,0ffh,0a3h,0cfh,0f7h,0e0h,0ffh,0feh,0fdh	; beb7  ...?..o.........
	defb 0fdh,0fbh,0fbh,0e3h,001h,066h,0f9h,0ffh,0fch,0fch,0f8h,0f0h,0e0h,0d8h,0dch,0ech	; bec7  .....f..........
	defb 0ech,0e8h,0f0h,0e0h,0e0h,0c0h,0c0h,080h,080h,0e0h,0fch,09ah,0ech,004h,0ffh,086h	; bed7  ................
	defb 0feh,0f9h,0c7h,03fh,000h,000h,003h,001h,003h,003h,083h,000h,0e0h,080h,005h,0ffh	; bee7  ...?............
	defb 090h,000h,003h,00fh,03fh,07fh,07fh,0ffh,0ffh,000h,000h,006h,00fh,01fh,01fh,03fh	; bef7  ....?..........?
	defb 03eh,003h,0e0h,082h,0f0h,0f8h,003h,0fch,004h,0bfh,084h,0ffh,0efh,08fh,07fh,004h	; bf07  >...............
	defb 0fbh,09ch,0ffh,0efh,0e7h,0f8h,001h,001h,003h,003h,007h,007h,00fh,01fh,07eh,0feh	; bf17  ..............~.
	defb 0fch,0fch,0f8h,0f8h,0f0h,0f0h,0feh,0beh,0deh,0bch,07bh,077h,0b7h,0cfh,008h,0ffh	; bf27  ..........{w....
	defb 08bh,01bh,03bh,037h,037h,017h,00bh,01dh,01dh,0e0h,0c0h,080h,003h,000h,08ah,080h	; bf37  ..;77...........
	defb 0c0h,0ffh,0ffh,0fbh,0fbh,0fch,0ffh,0edh,0f6h,005h,0ffh,0a3h,0f3h,0efh,007h,0ffh	; bf47  ................
	defb 07fh,0bfh,0bfh,0dfh,0dfh,0c7h,080h,066h,09fh,0ffh,03fh,03fh,01fh,00fh,007h,01bh	; bf57  .......f..??....
	defb 03bh,037h,037h,017h,00fh,007h,007h,003h,003h,001h,001h,007h,03fh,059h,037h,004h	; bf67  ;77.........?Y7.
	defb 0ffh,086h,07fh,09fh,0e3h,0fch,000h,000h,003h,080h,003h,0c0h,083h,000h,0f8h,0feh	; bf77  ................
	defb 005h,0ffh,080h,000h,012h,07fh,050h,011h,050h,004h,0a0h,005h,050h,002h,0a5h,005h	; bf87  ......P.P...P...
	defb 050h,07fh,0d0h,013h,0d0h,002h,0a0h,005h,0d0h,002h,0dah,005h,0d0h,000h,000h,018h	; bf97  P...............
	defb 008h,000h,091h,038h,01ch,00ch,008h,003h,003h,001h,000h,000h,004h,00ch,00ch,008h	; bfa7  ...8............
	defb 000h,018h,030h,020h,004h,000h,003h,080h,089h,000h,020h,030h,030h,010h,000h,018h	; bfb7  ..0 ...... 00...
	defb 00ch,004h,004h,000h,003h,001h,008h,000h,087h,01ch,038h,030h,010h,0c0h,0c0h,080h	; bfc7  ..........80....
	defb 00ch,000h,084h,060h,0e0h,0e0h,0c0h,02ch,000h,085h,006h,007h,007h,003h,000h,000h	; bfd7  ...`...,........
	defb 000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,093h	; bfe7  ................
	defb 0bah,0b7h,099h,0bah,0b2h,086h,007h,046h,0aah	; bff7  .......F.
