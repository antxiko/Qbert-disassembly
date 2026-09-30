# omsx_huerfanos.tcl - Ejecuta en una partida de verdad los trozos de codigo
# que no llama nadie, uno por cuadro.
#
# En el `haz_el_cuadro` de 0x40C5 (lo llama la interrupcion) se apila 0x40C5
# como vuelta y se salta al trozo con los registros que necesita; su `ret`
# vuelve a 0x40C5 y el cuadro sigue normal. En la vuelta se apuntan los
# registros y la memoria que toca. El ultimo es el visor de 0x6757: tras el,
# el emulador se queda EN PAUSA para verlo.
#
# QB_ESCENA: "partida" (fase 1, a los 24 s) o "titulo" (a los 12 s, solo el
# visor). Salida en work/huerfanos/.
file mkdir work/huerfanos
set ESC [expr {[info exists ::env(QB_ESCENA)] ? $::env(QB_ESCENA) : "partida"}]
set LOG [open work/huerfanos/$ESC.txt w]
proc apunta {t} { puts $::LOG $t; flush $::LOG }
proc h2 {v} { format %02X $v }
proc h4 {v} { format %04X $v }
proc rd {a} { debug read memory $a }
proc bloque {a n} {
    set s ""
    for {set i 0} {$i < $n} {incr i} { append s [format "%02X " [rd [expr {$a + $i}]]] }
    return $s
}
proc regs {} {
    return "A=[h2 [expr {[reg af] >> 8}]] F=[h2 [expr {[reg af] & 255}]] BC=[h4 [reg bc]] DE=[h4 [reg de]] HL=[h4 [reg hl]] BC'=[h4 [reg bc2]]"
}
proc vuelca {n} {
    set f [open "work/huerfanos/$n.vram" wb]
    puts -nonewline $f [debug read_block VRAM 0 16384]; close $f
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    set f [open "work/huerfanos/$n.regs" wb]; puts -nonewline $f $r; close $f
}
# salta a una direccion con 0x40C5 apilado como vuelta
proc salta {dir} {
    set sp [expr {[reg sp] - 2}]
    debug write memory $sp 0xC5
    debug write memory [expr {$sp + 1}] 0x40
    reg sp $sp
    reg pc $dir
}

# Cada paso: {nombre direccion preparacion(tcl) comprobacion(tcl)}
set PASOS {
    {640D "min(fase-1, 9) con la fase 0x23"
        {debug write memory 0xE111 0x23}
        {apunta "  devuelve [regs]  (0x23 - 1 = 0x22, mas de 9: A=09)"; debug write memory 0xE111 0x01}}
    {45FD "intercambia 4 bytes de 0xE700 y 0xE708"
        {foreach {a v} {0xE700 0x11 0xE701 0x22 0xE702 0x33 0xE703 0x44 0xE708 0xAA 0xE709 0xBB 0xE70A 0xCC 0xE70B 0xDD} {debug write memory $a $v}
         apunta "  antes: E700: [bloque 0xE700 4] E708: [bloque 0xE708 4]"
         reg hl 0xE700; reg de 0xE708; reg bc 0x0400}
        {apunta "  despues: E700: [bloque 0xE700 4] E708: [bloque 0xE708 4]  [regs]"}}
    {4643 "prepara la lectura de VRAM en HL=0x3800"
        {reg hl 0x3800}
        {apunta "  [regs]  (C' = el puerto de lectura del VDP que dice la BIOS en 0x0006: [h2 [rd 6]])"}}
    {705E "guarda el mando 2 con A=0x05"
        {apunta "  antes: E32F=[h2 [rd 0xE32F]] E330=[h2 [rd 0xE330]]"; reg af 0x0500}
        {apunta "  despues: E32F=[h2 [rd 0xE32F]] E330=[h2 [rd 0xE330]]"}}
    {7068 "lee E, S, F y C con la E pulsada"
        {keymatrixdown 3 0x04}
        {keymatrixup 3 0x04; apunta "  [regs]  (bit 0 = arriba)"}}
    {722C "el cubo bajo Q*bert y el modelo"
        {reg de [expr {[rd 0xE204] | ([rd 0xE205] << 8)}]
         apunta "  Q*bert en Y=[h2 [rd 0xE204]] X=[h2 [rd 0xE205]]"}
        {apunta "  [regs]  (Z = bit 6 de F: el cubo es como el modelo)"}}
    {77CC "C=0x5A en catorce objetos desde 0xE700"
        {reg hl 0xE700; reg bc 0x005A}
        {apunta "  despues: [bloque 0xE700 16] ... [bloque 0xE768 1]"}}
    {833C "el otro jugador esta cayendo?"
        {}
        {apunta "  [regs]  (Z si si) E333=[h2 [rd 0xE333]]"}}
    {9032 "el objeto de la vida contra el segundo sprite"
        {apunta "  antes: E34B=[h2 [rd 0xE34B]] E351=[h2 [rd 0xE351]] vidas=[h2 [rd 0xE110]]"}
        {apunta "  despues: E34B=[h2 [rd 0xE34B]] E351=[h2 [rd 0xE351]] vidas=[h2 [rd 0xE110]]"}}
    {821A "restos del duelo: quita una vida y pinta el marcador del duelo"
        {apunta "  antes: vidas=[h2 [rd 0xE110]]"}
        {apunta "  despues: vidas=[h2 [rd 0xE110]]"; vuelca t_821A}}
    {8275 "pone al Q*bert de (0xE332) a caer muerto"
        {apunta "  antes: estado=[h2 [rd 0xE202]] E338=[h2 [rd 0xE338]]"}
        {apunta "  despues: estado=[h2 [rd 0xE202]] arco=[h2 [rd 0xE203]] patron=[h2 [rd 0xE206]]"}}
    {6757 "el visor de patrones"
        {}
        {vuelca t_6757_$::ESC; apunta "  hecho"; close $::LOG; set ::activo 0; if {$::ESC eq "titulo"} { exit } else { debug break }}}
}
if {$ESC eq "titulo"} { set PASOS [list [lindex $PASOS end]] }

set ::i -1
set ::activo 0
proc cuadro {} {
    if {!$::activo} return
    # la vuelta del paso anterior
    if {$::i >= 0} {
        eval [lindex [lindex $::PASOS $::i] 3]
    }
    incr ::i
    if {$::i >= [llength $::PASOS]} { set ::activo 0; return }
    set p [lindex $::PASOS $::i]
    apunta "0x[lindex $p 0]  [lindex $p 1]"
    eval [lindex $p 2]
    salta 0x[lindex $p 0]
}
debug set_bp 0x40C5 {} cuadro

proc tecla {fila bit} { keymatrixdown $fila $bit ; after time 0.15 [list keymatrixup $fila $bit] }
if {$ESC eq "partida"} {
    after time 10 { tecla 8 0x01 }
    after time 13 { tecla 8 0x01 }
    after time 15.5 { tecla 8 0x01 }
    after time 16 { tecla 8 0x01 }
    after time 24 { set ::activo 1 }
} else {
    after time 12 { set ::activo 1 }
}
