#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

uint64_t fib(uint64_t);
void fib2(uint64_t*, uint64_t);
uint64_t fac(uint64_t);
uint64_t fac1(uint64_t);
uint64_t test0(uint64_t, uint64_t, uint64_t);
uint64_t test1(uint64_t, uint64_t);

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

    for (uint64_t i = 0; i < 8; i += 1) {
        printf("fac(%llu) = %llu\n", i, fac(i));
    }

    for (uint64_t i = 0; i < 8; i += 1) {
        printf("fac1(%llu) = %llu\n", i, fac1(i));
    }

    printf("test0(%d, %d, %d) = %llu = %d\n", 6, -1, 0, test0(6, -1, 0), 0);
    printf("test0(%d, %d, %d) = %llu = %d\n", -12, 5, 5, test0(-12, 5, 5), 0);
    printf("test0(%d, %d, %d) = %llu = %d\n", 0, 0, -1, test0(0, 0, -1), 1);

    printf("test1(%d, %d) = %lld = %d\n", 6, 3, test1(6, 3), 3);
    printf("test1(%d, %d) = %lld = %d\n", -12, 5, test1(-12, 5), -17);
    free(arr);

    return 0;
}
