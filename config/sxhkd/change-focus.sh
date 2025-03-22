#!/bin/zsh

# Obtener el monitor correspondiente al nombre proporcionado y eliminar espacios al principio y al final
monDir=$(bspc query -D -n "$1")
# Obtener el monitor actual y eliminar espacios al principio y al final
actMon=$(bspc query -D -n)

# Verificar si el monitor actual está vacío o si el monitor actual es el mismo que el proporcionado
if [[ "$actMon" == *0x* && "$actMon" == "$monDir" ]]; then
    bspc node "$1" -f  # Cambiar al nodo en el monitor actual
else
    bspc monitor "$1" -f  # Cambiar al monitor especificado
fi
