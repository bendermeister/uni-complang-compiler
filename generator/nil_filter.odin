package generator

nil_filter :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	for i := 0; i < len(stmts); i += 1 {
		if stmts[i] == nil {
			ordered_remove(stmts, i)
			has_changed^ = true
			i -= 1
		}
	}
}
