package generator

var_rename :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	for &stmt, i in stmts {
		if stmt == nil {continue}
		if !stmt_is_expr(stmt) {continue}
		if !(i + 1 < len(stmts)) {continue}
		if !stmt_is_mov(stmts[i + 1]) {continue}
		expr := &stmt.(Expr)
		mov := stmts[i + 1].(Mov)
		if operand_is_number(mov.src) {continue}
		src := mov.src.(Variable)
		if expr.out != src {continue}
		expr.out = mov.dest
		stmts[i + 1] = nil
	}
}
