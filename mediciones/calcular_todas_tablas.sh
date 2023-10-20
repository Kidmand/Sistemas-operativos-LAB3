#!/bin/bash

# Puede ser "" o "q-10_" para cambiar el nombre de los archivos.
short_op=""

archivos=(
    "${short_op}medicion_1.txt"
    "${short_op}medicion_2.txt"
    "${short_op}medicion_3.txt"
    "${short_op}medicion_4.txt"
    "${short_op}medicion_5.txt"
)

crear_tabla() {
    archivo=$1

    # Inicializa dos arreglos vacíos
    numeros_iobench=()
    numeros_cpubench=()

    echo "| Parámetro                       |  Valor  |"
    echo "| :------------------------------ | :-----: |"

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
        echo "| Promedio de OPW100T (iobench-$numero) | $promedio |"

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
        echo "| Promedio de OPR100T (iobench-$numero) | $promedio |"

        cantselect=$(grep "Termino iobench $numero:" $archivo | awk '{print $13}' | sed 's/,//g')
        lastexect=$(grep "Termino iobench $numero:" $archivo | awk '{print $15}' | sed 's/,//g')

        echo "| Cant. select        (iobench-$numero) | $cantselect |"
        echo "| Last exect          (iobench-$numero) | $lastexect |"
    done

    for numero in "${numeros_cpubench[@]}"; do
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
        echo "| Promedio MFLOP100T (cpubench-$numero) | $promedio |"

        cantselect=$(grep "Termino cpubench $numero:" $archivo | awk '{print $13}' | sed 's/,//g')
        lastexect=$(grep "Termino cpubench $numero:" $archivo | awk '{print $15}' | sed 's/,//g')

        echo "| Cant. select       (cpubench-$numero) | $cantselect |"
        echo "| Last exect         (cpubench-$numero) | $lastexect |"
    done
}

for archivo_nombre in "${archivos[@]}"; do
    echo "Tabla de $archivo_nombre"
    crear_tabla "$archivo_nombre"
    echo ""
done
