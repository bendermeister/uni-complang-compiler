.global fib
fib:
	push %rbx
	push %r12
	subq $0, %rsp
	movq %rdi, %rbx
	xorq %rax, %rax
	movq $2, %rax
	cmpq %rbx, %rax
	setle %al
	xorq $1, %rax
	movq %rax, %r12
	movq %r12, %rax
	xorq $1, %rax
	movq %rax, %r12
	xorq %rax, %rax
	movq %r12, %rax
	andq $1, %rax
	cmpq $1, %rax
	je _internal_label_2
	movq $1, %rax
	addq $0, %rsp
	popq %r12
	popq %rbx
	ret
	_internal_label_2:
	movq %rbx, %rax
	subq $1, %rax
	movq %rax, %r12
	movq %r12, %rdi
	call fib
	movq %rax, %r12
	movq %rbx, %rax
	subq $2, %rax
	movq %rax, %rbx
	movq %rbx, %rdi
	call fib
	movq %rax, %rbx
	movq %r12, %rax
	addq %rbx, %rax
	movq %rax, %rbx
	movq %rbx, %rax
	addq $0, %rsp
	popq %r12
	popq %rbx
	ret

