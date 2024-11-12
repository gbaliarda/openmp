#include<stdio.h>
#include<stdlib.h>
#include<omp.h>

#define SIZE   200000000

int main() {
   int *v = (int *)malloc( SIZE * sizeof(int) );

   int i;

   int suma = 0;

   double start_time = omp_get_wtime();

   #pragma omp parallel for shared(v), private(i)

   for ( i=0; i<SIZE; i++ ) v[i] = 0;

    double end_time = omp_get_wtime();
    printf("Tiempo para inicializar el vector: %f\n", end_time - start_time);

    // Medir el tiempo para asignar valores al vector
    start_time = omp_get_wtime();

   #pragma omp parallel for shared(v), private(i)

   for ( i=0; i<SIZE; i++ ) v[i] = i;

    end_time = omp_get_wtime();
    printf("Tiempo para asignar valores al vector: %f\n", end_time - start_time);

    // Medir el tiempo para la suma secuencial
    start_time = omp_get_wtime();

   /* Suma secuencial */

   for ( i=0; i<SIZE; i++ ) suma = ( suma + v[i] ) % 65535;

    end_time = omp_get_wtime();
    printf("Tiempo para la suma secuencial: %f\n", end_time - start_time);


   printf( "Resultado final: %d\n", suma );

   return 0;
}