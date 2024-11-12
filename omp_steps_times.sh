#!/bin/bash
gcc -o actividad1_step_times.exe -fopenmp actividad1_step_times.c

if [ $? -eq 0 ]; then
    echo "Compilación exitosa. Ejecutando el programa..."

    echo "Hilos,Promedio Tiempo Inicialización (s),Error Inicialización (s),Promedio Tiempo Asignación (s),Error Asignación (s),Promedio Tiempo Suma (s),Error Suma (s)" > step_times.csv
    for threads in {1..20}; do
        echo "Ejecutando con $threads hilos..."

        total_init=0
        total_assign=0
        total_sum=0
        declare -a init_times
        declare -a assign_times
        declare -a sum_times
        
        for run in {1..15}; do
            echo "Iteración $run..."
            output=$(OMP_NUM_THREADS=$threads ./actividad1_step_times.exe)

            init_time=$(echo "$output" | grep "Tiempo para inicializar el vector" | awk '{print $NF}')
            assign_time=$(echo "$output" | grep "Tiempo para asignar valores al vector" | awk '{print $NF}')
            sum_time=$(echo "$output" | grep "Tiempo para la suma secuencial" | awk '{print $NF}')

            echo "Tiempos extraídos: Inicialización: $init_time, Asignación: $assign_time, Suma: $sum_time"

            # Verificar que no estén vacíos
            if [[ -z "$init_time" || -z "$assign_time" || -z "$sum_time" ]]; then
                echo "Error: Uno o más tiempos no fueron extraídos correctamente."
                continue
            fi

            total_init=$(echo "$total_init + $init_time" | bc)
            total_assign=$(echo "$total_assign + $assign_time" | bc)
            total_sum=$(echo "$total_sum + $sum_time" | bc)

            init_times+=($init_time)
            assign_times+=($assign_time)
            sum_times+=($sum_time)
        done

        avg_init=$(echo "scale=5; $total_init / 15" | bc)
        avg_assign=$(echo "scale=5; $total_assign / 15" | bc)
        avg_sum=$(echo "scale=5; $total_sum / 15" | bc)

        var_init=0
        var_assign=0
        var_sum=0

        for i in {0..14}; do
            init_diff=$(echo "${init_times[$i]} - $avg_init" | bc)
            assign_diff=$(echo "${assign_times[$i]} - $avg_assign" | bc)
            sum_diff=$(echo "${sum_times[$i]} - $avg_sum" | bc)

            var_init=$(echo "$var_init + ($init_diff * $init_diff)" | bc)
            var_assign=$(echo "$var_assign + ($assign_diff * $assign_diff)" | bc)
            var_sum=$(echo "$var_sum + ($sum_diff * $sum_diff)" | bc)
        done

        var_init=$(echo "scale=5; $var_init / 15" | bc)
        var_assign=$(echo "scale=5; $var_assign / 15" | bc)
        var_sum=$(echo "scale=5; $var_sum / 15" | bc)

        std_dev_init=$(echo "scale=5; sqrt($var_init)" | bc)
        std_dev_assign=$(echo "scale=5; sqrt($var_assign)" | bc)
        std_dev_sum=$(echo "scale=5; sqrt($var_sum)" | bc)

        echo "$threads,$avg_init,$std_dev_init,$avg_assign,$std_dev_assign,$avg_sum,$std_dev_sum" >> step_times.csv
    done
else
    echo "Error en la compilación."
fi
