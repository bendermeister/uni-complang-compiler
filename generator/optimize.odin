package generator

optimize :: proc(stmts: ^[dynamic]Stmt) {
	has_changed := true

	// nil_filter is sadly needed after each optimization because the
	// optimizations can't deal with nil values
	for has_changed {
		has_changed = false
		mov_inline(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		expr_inline(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		nil_unused(stmts, &has_changed)
		nil_filter(stmts, &has_changed)

		nil_return(stmts, &has_changed)
		nil_filter(stmts, &has_changed)
	}

	var_reuse(stmts)
}
