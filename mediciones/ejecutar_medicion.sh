#!/bin/bash

# Edita el nombre de los archivos de salida.
short_op=""

comandos=(
  "iobench"
  "cpubench"
  "iobench & ; cpubench &"
  "cpubench & ; cpubench &"
  "cpubench & ; cpubench & ; iobench &"
)

if [ $# -eq 1 ]; then
  numero_de_caso="$1"
else
  echo "Por favor, elige un caso de medicion:"
  echo "[0] Ejecutar todas las mediciones."
  for i in "${!comandos[@]}"; do
    echo "[$((i + 1))] ${comandos[i]}"
  done
  read -p "Número de caso: " numero_de_caso
fi

if [ "$numero_de_caso" -eq 0 ]; then

  echo "Vamos a ejecutar todas las mediciones de forma secuencial."
  # Ejecutar todas las mediciones con un bucle
  for i in {1..5}; do
    ./ejecutar_medicion.sh "$i"
  done

  echo "Se han terminado de ejecutar todas las mediciones!!!!!!!"
  exit 0
fi

if [ "$numero_de_caso" -lt 1 ] || [ "$numero_de_caso" -gt "${#comandos[@]}" ]; then
  echo "Número de caso fuera de rango."
  exit 1
fi

comando="${comandos[$numero_de_caso - 1]}"
archivo_salida="medicion_$numero_de_caso.txt"

echo "Ejecutando el comando: $comando"

cd ..
(
  sleep 1
  echo -e "$comando"
) | make qemu CPUS=1 >"./mediciones/${short_op}$archivo_salida" &

cantidad_puntos_y_comas=$(echo "$comando" | tr -cd ';' | wc -c)

cantidad_termino=$(expr $cantidad_puntos_y_comas + 1)
# Espera hasta que aparezca la palabra "DONE" dos veces en el archivo
while [ $(grep -c "Termino" "./mediciones/${short_op}$archivo_salida") -ne $cantidad_termino ]; do
  echo -ne "  \\r\\" # Imprime "\" y coloca el cursor al principio de la línea
  sleep 0.5
  echo -ne "  \\r/" # Imprime "-" y coloca el cursor al principio de la línea
  sleep 0.5
done

pkill -f "qemu"

echo "Se ha terminado de ejecutar, la salida se guardo en: ./mediciones/$archivo_salida"

exit 0
