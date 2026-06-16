#include <stdio.h>
#include <stdint.h>

uint64_t fib(uint64_t);



int main(void) {
    printf("Hello World\n");

    for (uint64_t i = 0; i < 8; i += 1) {
        printf("fib(%llu) = %llu\n", i, fib(i));
    }
    return 0;
}
