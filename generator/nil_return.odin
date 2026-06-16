package generator

nil_return :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	for stmt, i in stmts {
		if stmt == nil {continue}
		switch _ in stmt {
		case Label:
		case Write:
		case Expr:
		case Jmp:
		case CJmp:
		case Return:
			for &a in stmts[i + 1:] {
				if stmt_is_label(a) {break}
				has_changed^ = true
				a = nil
			}
		case Mov:
		case Par:
		}
	}
}
