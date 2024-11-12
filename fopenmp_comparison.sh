#!/bin/bash
gcc -o actividad1_original.exe actividad1_original.c

if [ $? -eq 0 ]; then
    echo "Compilación exitosa. Ejecutando el programa..."

    echo "Hilos,Promedio Tiempo Real (s),Error Real (s),Promedio Tiempo Usuario (s),Error Usuario (s),Promedio Tiempo Sistema (s),Error Sistema (s)" > full_execution_times.csv
    