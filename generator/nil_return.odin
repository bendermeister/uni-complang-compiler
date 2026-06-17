package generator

nil_return :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	for stmt, i in stmts {
		if stmt == nil {continue}
		#partial switch _ in stmt {
		case Return:
			for &a in stmts[i + 1:] {
				if stmt_is_label(a) {break}
				has_changed^ = true
				a = nil
			}
		}
	}
}
