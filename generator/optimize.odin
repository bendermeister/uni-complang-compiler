package generator

import "core:fmt"
optimize :: proc(stmts: ^[dynamic]Stmt) {
	has_changed := true
	foo :: proc(stmts: []Stmt) {
		for stmt in stmts {
			fmt.eprintln(stmt_to_string(stmt))
		}
	}

	// nil_filter is sadly needed after each optimization because the
	// optimizations can't deal with nil values
	for has_changed {
		has_changed = false
		mov_inline(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("mov_inline: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()

		expr_inline(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("expr_inline: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()

		nil_unused(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("nil_unused: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()

		nil_return(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("nil_return: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()

		label_merge(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("label_merge: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()

		nil_small_jump(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		fmt.eprintln("nil_small_jump: ")
		foo(stmts[:])
		fmt.eprintln()
		fmt.eprintln()
	}

	var_reuse(stmts)
}
