#!/bin/bash
use_openmp=false
if [ "$1" == '-fopenmp' ]; then
    use_openmp=true
    gcc_flags="-fopenmp"
    output_suffix="_openmp"
else
    gcc_flags=""
    output_suffix=""
fi
gcc -o actividad1_original.exe $gcc_flags actividad1_original.c

if [ $? -eq 0 ]; then
    echo "Compilación exitosa. Ejecutando el programa..."

    echo "Hilos,Promedio Tiempo Real (s),Error Real (s),Promedio Tiempo Usuario (s),Error Usuario (s),Promedio Tiempo Sistema (s),Error Sistema (s)" > full_execution_times.csv
    for threads in {1..8}; do
        echo "Ejecutando con $threads hilos..."

        total_real=0
        total_user=0
        total_sys=0
        declare -a real_times
        declare -a user_times
        declare -a sys_times
        
        for run in {1..15}; do
            echo "Iteración $run..."
            output=$( { time OMP_NUM_THREADS=$threads ./actividad1_original.exe; } 2>&1 )
            
            real=$(echo "$output" | grep real | awk '{print $2}' | sed 's/,/./; s/m/*60+/; s/s//; s/$/0/' | bc)
            user=$(echo "$output" | grep user | awk '{print $2}' | sed 's/,/./; s/m/*60+/; s/s//; s/$/0/' | bc)
            sys=$(echo "$output" | grep sys | awk '{print $2}' | sed 's/,/./; s/m/*60+/; s/s//; s/$/0/' | bc)


            echo "Tiempos extraídos: Real: $real, User: $user, Sys: $sys"
            
            if [[ -z "$real" || -z "$user" || -z "$sys" ]]; then
                echo "Error: Uno o más tiempos no fueron extraídos correctamente."
                continue
            fi

            total_real=$(echo "$total_real + $real" | bc)
            total_user=$(echo "$total_user + $user" | bc)
            total_sys=$(echo "$total_sys + $sys" | bc)

            real_times+=($real)
            user_times+=($user)
            sys_times+=($sys)
        done

        avg_real=$(echo "scale=5; $total_real / 15" | bc)
        avg_user=$(echo "scale=5; $total_user / 15" | bc)
        avg_sys=$(echo "scale=5; $total_sys / 15" | bc)


        var_real=0
        var_user=0
        var_sys=0


        for i in {0..14}; do
            real_diff=$(echo "${real_times[$i]} - $avg_real" | bc)
            user_diff=$(echo "${user_times[$i]} - $avg_user" | bc)
            sys_diff=$(echo "${sys_times[$i]} - $avg_sys" | bc)

            var_real=$(echo "$var_real + ($real_diff * $real_diff)" | bc)
            var_user=$(echo "$var_user + ($user_diff * $user_diff)" | bc)
            var_sys=$(echo "$var_sys + ($sys_diff * $sys_diff)" | bc)
        done

        var_real=$(echo "scale=5; $var_real / 15" | bc)
        var_user=$(echo "scale=5; $var_user / 15" | bc)
        var_sys=$(echo "scale=5; $var_sys / 15" | bc)

        std_dev_real=$(echo "scale=5; sqrt($var_real)" | bc)
        std_dev_user=$(echo "scale=5; sqrt($var_user)" | bc)
        std_dev_sys=$(echo "scale=5; sqrt($var_sys)" | bc)

        echo "$threads,$avg_real,$std_dev_real,$avg_user,$std_dev_user,$avg_sys,$std_dev_sys" >> "full_execution_times${output_suffix}.csv"
    done
else
    echo "Error en la compilación."
fi