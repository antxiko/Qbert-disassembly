# Q*bert (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como qbert.rom, y
# `make comprueba` verifica su sha256.

ROM      = qbert.rom
SHA      = bd253f3285b3bf31501cd34f593f35ed3b9adfc6eb44c360c6fd59f8ab2c3684
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = Q*BERT - Konami - MSX1 - cartucho RC-746 de 32 KB en las paginas 1 y 2

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Q*bert (Konami, RC-746) para MSX, 32768 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/qbert.trace.json: $(ROM) $(SRC)/qbert.entries $(SRC)/qbert.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/qbert.entries \
	        $(WORK)/qbert $(SRC)/qbert.nocode

trace: $(WORK)/qbert.trace.json

listado: $(WORK)/qbert.trace.json $(SRC)/qbert.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/qbert.trace.json \
	        $(SRC)/qbert.notes work/msx.sym $(SRC)/qbert.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/qbert.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/qbert.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/qbert.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/qbert.trace.json $(SRC)/qbert.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/qbert.entries $(SRC)/qbert.notes \
	        $(SRC)/qbert.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/qbert.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

clean:
	rm -rf $(WORK)/qbert.trace.json $(WORK)/qbert.blocks

.PHONY: all comprueba trace listado verify sanity test densidad clean
