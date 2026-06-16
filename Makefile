all.out:
	odin build all -o all.out

example.out: all.out
	cat ./example/fib.fuck | ./all.out
	
