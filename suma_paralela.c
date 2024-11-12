#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define SIZE 100000000

// Kernel de CUDA para realizar la suma parcial en la GPU
__global__ void sumKernel(int *array, long long *partialSums, int n) {
    extern __shared__ int sharedData[];

    int tid = threadIdx.x;
    int index = blockIdx.x * blockDim.x + threadIdx.x;

    // Copiar los datos al espacio de memoria compartida
    sharedData[tid] = (index < n) ? array[index] : 0;
    __syncthreads();

    // Reducción en el espacio de memoria compartida
    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (tid < stride) {
            sharedData[tid] += sharedData[tid + stride];
        }
        __syncthreads();
    }

    // El primer hilo guarda el resultado de la suma parcial
    if (tid == 0) {
        partialSums[blockIdx.x] = sharedData[0];
    }
}

int main() {
    int *array;
    long long *partialSums;
    int *d_array;
    long long *d_partialSums;

    // Reservar memoria en el host
    array = (int *)malloc(SIZE * sizeof(int));
    partialSums = (long long *)malloc(1024 * sizeof(long long));

    // Llenar el array con el valor 1
    for (int i = 0; i < SIZE; i++) {
        array[i] = 1;
    }

    // Reservar memoria en el dispositivo
    cudaMalloc((void **)&d_array, SIZE * sizeof(int));
    cudaMalloc((void **)&d_partialSums, 1024 * sizeof(long long));

    // Copiar el array al dispositivo
    cudaMemcpy(d_array, array, SIZE * sizeof(int), cudaMemcpyHostToDevice);

    // Configuración del kernel
    int threadsPerBlock = 1024;
    int blocksPerGrid = (SIZE + threadsPerBlock - 1) / threadsPerBlock;
    size_t sharedMemorySize = threadsPerBlock * sizeof(int);

    // Medir el tiempo de ejecución
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start);

    // Ejecutar el kernel
    sumKernel<<<blocksPerGrid, threadsPerBlock, sharedMemorySize>>>(d_array, d_partialSums, SIZE);

    // Copiar las sumas parciales al host
    cudaMemcpy(partialSums, d_partialSums, blocksPerGrid * sizeof(long long), cudaMemcpyDeviceToHost);

    // Realizar la suma final en el host
    long long sum_gpu = 0;
    for (int i = 0; i < blocksPerGrid; i++) {
        sum_gpu += partialSums[i];
    }

    // Detener el temporizador
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);
    float milliseconds = 0;
    cudaEventElapsedTime(&milliseconds, start, stop);

    printf("Suma en GPU: %lld, Tiempo: %f segundos\n", sum_gpu, milliseconds / 1000);

    // Liberar la memoria
    cudaFree(d_array);
    cudaFree(d_partialSums);
    free(array);
    free(partialSums);

    return 0;
}
