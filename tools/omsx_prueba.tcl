# omsx_prueba.tcl - Experimentos con la partida: lee work/prueba.txt, una
# orden por linea, "<segundo> <orden> [args]":
#   w <dir> <valor>        escribe un byte en la RAM
#   k <fila> <mascara> [s] pulsa una tecla (s segundos, 0.15 por defecto)
#   d <nombre>             vuelca VRAM, RAM (0xE000-0xFFFF) y registros
#   x                      sale
# Los volcados van a work/prueba/<nombre>.*
file mkdir work/prueba
set throttle off
proc guarda {nom datos} {
    set f [open "work/prueba/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc vuelca {n} {
    guarda $n.vram [debug read_block VRAM 0 16384]
    guarda $n.ram [debug read_block memory 0xE000 0x2000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $n.regs $r
}
proc tecla {fila bit s} { keymatrixdown $fila $bit ; after time $s [list keymatrixup $fila $bit] }
set f [open work/prueba.txt r]
while {[gets $f l] >= 0} {
    if {[string trim $l] eq "" || [string index $l 0] eq "#"} continue
    set t [lindex $l 0]; set o [lindex $l 1]
    switch $o {
        w { after time $t [list debug write memory [lindex $l 2] [lindex $l 3]] }
        k { set s [expr {[llength $l] > 4 ? [lindex $l 4] : 0.15}]
            after time $t [list tecla [lindex $l 2] [lindex $l 3] $s] }
        d { after time $t [list vuelca [lindex $l 2]] }
        x { after time $t exit }
    }
}
close $f
