all: example

compiler:
	odin build all -debug

example: compiler
	./all.bin < example/fib.fuck > fib.s
	./all.bin < example/fib2.fuck > fib2.s
	./all.bin < example/fac.fuck > fac.s
	./all.bin < example/fac1.fuck > fac1.s
	./all.bin < example/test0.fuck > test0.s
	./all.bin < example/test1.fuck > test1.s
	gcc -c -g example/main.c
	gcc -c -g fib.s
	gcc -c -g fac.s
	gcc -c -g test0.s
	gcc -c -g test1.s
	gcc -c -g fac1.s
	gcc -c -g fib2.s
	gcc -g fib.o fib2.o main.o fac.o fac1.o test0.o test1.o

clean:
	rm -f *.o *.s *.out *.bin


.PHONY: all.out example clean
