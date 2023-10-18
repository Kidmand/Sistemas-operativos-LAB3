#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Pasa como parametro un archivo generado por ejecutar_medicion.sh"
    exit 1
fi

archivo=$1

# Inicializa dos arreglos vacíos
numeros_iobench=()
numeros_cpubench=()

# Utiliza grep, awk y sed para extraer los números y guárdalos en los arreglos correspondientes
while read -r linea; do
    numero=$(echo "$linea" | awk '{print $3}' | sed 's/://')
    proceso=$(echo "$linea" | awk '{print $2}')

    if [ "$proceso" == "iobench" ]; then
        numeros_iobench+=("$numero")
    elif [ "$proceso" == "cpubench" ]; then
        numeros_cpubench+=("$numero")
    fi
done < <(grep -o 'Termino [^ ]* [0-9]\+:' $archivo)

# Imprime el contenido de los arreglos
for numero in "${numeros_iobench[@]}"; do
    echo "--------------------------------------------------------------------------------------------------------------"
    echo "Analzando el proceso IOBENCH con PID:$numero"
    cant=$(grep -c "$numero: [0-9]\+ OPW100T, [0-9]\+ OPR100T" $archivo)
    ALL_OPW=$(grep -o "$numero: [0-9]\+ OPW100T, [0-9]\+ OPR100T" $archivo | awk '{print $2}')

    split_opw=()
    while read -r linea; do
        split_opw+=("$linea")
    done <<<"$ALL_OPW"

    # Inicializa una variable para la suma
    suma=0

    # Suma todos los valores en el arreglo
    for valor in "${split_opw[@]}"; do
        suma=$((suma + valor))
    done

    # Calcula el promedio dividiendo la suma por la cantidad
    if [ "$cant" -gt 0 ]; then
        promedio=$(awk "BEGIN {print $suma / $cant}")
    else
        promedio=0
    fi

    # Imprime el promedio
    echo "Promedio de OPW100T: $promedio"

    ALL_OPR=$(grep -o "$numero: [0-9]\+ OPW100T, [0-9]\+ OPR100T" $archivo | awk '{print $4}')

    split_opr=()
    while read -r linea; do
        split_opr+=("$linea")
    done <<<"$ALL_OPR"

    # Inicializa una variable para la suma
    suma=0

    # Suma todos los valores en el arreglo
    for valor in "${split_opr[@]}"; do
        suma=$((suma + valor))
    done

    # Calcula el promedio dividiendo la suma por la cantidad
    if [ "$cant" -gt 0 ]; then
        promedio=$(awk "BEGIN {print $suma / $cant}")
    else
        promedio=0
    fi

    # Imprime el promedio
    echo "Promedio de OPR100T: $promedio"

    echo "Su ultima linea fue:"
    echo "    $(grep "Termino iobench $numero:" $archivo)"
    echo "--------------------------------------------------------------------------------------------------------------"
done

for numero in "${numeros_cpubench[@]}"; do
    echo "--------------------------------------------------------------------------------------------------------------"
    echo "Analzando el proceso CPUBENCH con PID:$numero"
    cant=$(grep -c "$numero: [0-9]\+ MFLOP100T" $archivo)
    ALL_OPR=$(grep -o "$numero: [0-9]\+ MFLOP100T" $archivo | awk '{print $2}')

    split_opr=()
    while read -r linea; do
        split_opr+=("$linea")
    done <<<"$ALL_OPR"

    # Inicializa una variable para la suma
    suma=0

    # Suma todos los valores en el arreglo
    for valor in "${split_opr[@]}"; do
        suma=$((suma + valor))
    done

    # Calcula el promedio dividiendo la suma por la cantidad
    if [ "$cant" -gt 0 ]; then
        promedio=$(awk "BEGIN {print $suma / $cant}")
    else
        promedio=0
    fi

    # Imprime el promedio
    echo "Promedio de MFLOP100T: $promedio"

    echo "Su ultima linea fue:"
    echo "    $(grep "Termino cpubench $numero:" $archivo)"
    echo "--------------------------------------------------------------------------------------------------------------"
done
