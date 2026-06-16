all: example

compiler:
	odin build all -debug

example: compiler
	./all.bin < example/fib.fuck > fib.s
	./all.bin < example/fib2.fuck > fib2.s
	gcc -c -g example/main.c
	gcc -c -g fib.s
	gcc -c -g fib2.s
	gcc -g fib.o fib2.o main.o

clean:
	rm -f *.o *.s *.out *.bin


.PHONY: all.out example clean
