#!/bin/sh
# lanza_fase.sh "<fase> <bonus> <duelo> <segundos...>": UN openMSX con
# tools/omsx_fase.tcl. Deja work/fases/fin_<fase>.txt al acabar.
R=$(cd "$(dirname "$0")/.." && pwd)
cd $R && mkdir -p work/fases && echo "$1" > work/fase.txt
timeout 300 "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart qbert.rom -script tools/omsx_fase.tcl > work/fases/log.txt 2>&1
echo hecho > work/fases/fin_$(echo $1 | tr ' ' '_').txt
