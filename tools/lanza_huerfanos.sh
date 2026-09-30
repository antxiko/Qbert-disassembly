#!/bin/sh
# lanza_huerfanos.sh: primero el visor sobre el titulo (y se cierra); luego
# la partida con los doce trozos, que se queda EN PAUSA en el visor.
R=$(cd "$(dirname "$0")/.." && pwd)
cd $R && mkdir -p work/huerfanos
QB_ESCENA=titulo timeout 120 "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart qbert.rom -script tools/omsx_huerfanos.tcl > work/huerfanos/log_titulo.txt 2>&1
QB_ESCENA=partida "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart qbert.rom -script tools/omsx_huerfanos.tcl > work/huerfanos/log_partida.txt 2>&1
