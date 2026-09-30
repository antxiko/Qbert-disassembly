#!/bin/sh
# lanza_vuelca.sh <dir> "<instantes>" ["<espacios>"]: UN openMSX con
# tools/omsx_vuelca.tcl; deja <dir>/fin.txt al acabar.
R=$(cd "$(dirname "$0")/.." && pwd)
D=$R/$1
mkdir -p $D
cd $R && QB_OUT=$D QB_T="$2" QB_ESPACIO="$3" timeout 600 "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart qbert.rom -script tools/omsx_vuelca.tcl > $D/log.txt 2>&1
echo hecho > $D/fin.txt
