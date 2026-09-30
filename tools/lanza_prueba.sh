#!/bin/sh
# lanza_prueba.sh <fichero de ordenes>: UN openMSX con tools/omsx_prueba.tcl
R=$(cd "$(dirname "$0")/.." && pwd)
cd $R && cp "$1" work/prueba.txt && mkdir -p work/prueba
timeout 300 "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart qbert.rom -script tools/omsx_prueba.tcl > work/prueba/log.txt 2>&1
echo hecho > work/prueba/fin_$(basename $1).txt
