#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint64_t fib(uint64_t);
void fib2(uint64_t*, uint64_t);



int main(void) {
    printf("Hello World\n");

    for (uint64_t i = 0; i < 8; i += 1) {
        printf("fib(%llu) = %llu\n", i, fib(i));
    }

    uint64_t* arr = calloc(8, sizeof(*arr));
    fib2(arr, 8);

    for (uint64_t i = 0; i < 8; i += 1) {
        printf("fib2(%llu) = %llu\n", i, arr[i]);
    }


    free(arr);

    return 0;
}
