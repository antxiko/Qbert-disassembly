# omsx_fase.tcl - Arranca la partida en la fase que diga work/fase.txt y
# vuelca VRAM, RAM y registros unos segundos despues de montarla.
#
# work/fase.txt: "<fase BCD en hex> <bonus 0|1> <duelo 0|1> <segundos...>"
# Se pulsa ESPACIO en el titulo y en el menu. En el `call monta_la_fase`
# (0x4209) se escribe la fase en 0xE111 UNA vez; con bonus, ademas el bit 0
# de 0xE002 y, en 0x61E0, el tablero de bonificacion en 0xEC00.
set f [open work/fase.txt r]; set cfg [gets $f]; close $f
set FASE [lindex $cfg 0]; set BONUS [lindex $cfg 1]; set DUELO [lindex $cfg 2]
set TS [lrange $cfg 3 end]
set OUT work/fases/f$FASE[expr {$BONUS ? "b" : ""}][expr {$DUELO ? "d" : ""}]
file mkdir $OUT
set throttle off
set ::hecho 0
proc guarda {nom datos} {
    set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc vuelca {t} {
    set n [format t%02d $t]
    guarda $n.vram [debug read_block VRAM 0 16384]
    guarda $n.ram [debug read_block memory 0xE000 0x2000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $n.regs $r
}
proc tecla {fila bit} { keymatrixdown $fila $bit ; after time 0.15 [list keymatrixup $fila $bit] }
proc al_montar {} {
    if {$::hecho} return
    set ::hecho 1
    debug write memory 0xE111 [expr 0x$::FASE]
    if {$::BONUS} {
        debug write memory 0xE002 [expr {[debug read memory 0xE002] | 1}]
    }
    foreach t $::TS { after time $t [list vuelca $t] }
    after time [expr {[lindex [lsort -real $::TS] end] + 0.5}] exit
}
proc al_montar_tablero {} {
    if {!$::BONUS || $::hecho != 1} return
    set ::hecho 2
    debug write_block memory 0xEC00 [debug read_block memory 0xA7AD 81]
}
debug set_bp 0x4209 {} al_montar
debug set_bp 0x61E0 {} al_montar_tablero
# titulo y menu: con duelo, abajo antes del espacio para 2PLAYERS
after time 10 { tecla 8 0x01 }
if {$DUELO} { after time 12 { tecla 8 0x40 } }
after time 13 { tecla 8 0x01 }
after time 15.5 { tecla 8 0x01 }
after time 16 { tecla 8 0x01 }
after time 60 exit
