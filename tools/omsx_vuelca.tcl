# omsx_vuelca.tcl - Volcados para cotejar: VRAM (16 KB), RAM 0xE000-0xFFFF y
# registros del VDP en los instantes de QB_T (segundos emulados). Pulsa
# ESPACIO en los instantes de QB_ESPACIO. Cada volcado va a QB_OUT/tNNN.*
#
#   QB_OUT=<dir> QB_T="5 20" openmsx -machine C-BIOS_MSX1_JP -cart qbert.rom \
#       -script este.tcl
set OUT $::env(QB_OUT)
file mkdir $OUT
set TS $::env(QB_T)
set ESP [expr {[info exists ::env(QB_ESPACIO)] ? $::env(QB_ESPACIO) : ""}]
set throttle off
proc guarda {nom datos} {
    set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc vuelca {t} {
    set n [format t%03d $t]
    guarda $n.vram [debug read_block VRAM 0 16384]
    guarda $n.ram [debug read_block memory 0xE000 0x2000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $n.regs $r
}
proc espacio {} { keymatrixdown 8 0x01 ; after time 0.2 { keymatrixup 8 0x01 } }
foreach t $ESP { after time $t espacio }
foreach t $TS { after time $t [list vuelca $t] }
after time [expr {[lindex [lsort -real $TS] end] + 1}] exit
