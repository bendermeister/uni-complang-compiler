package generator

label_merge :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	label_map := make(map[Label]Label)
	defer delete(label_map)

	for stmt, i in stmts {
		if stmt == nil {continue}
		switch stmt in stmt {
		case Label:
			for &nstmt in stmts[i + 1:] {
				if !stmt_is_label(nstmt) {break}
				has_changed^ = true
				label := nstmt.(Label)
				label_map[label] = stmt
				nstmt = nil
			}
		case Write:
		case Expr:
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
		case Par:
		}
	}

	for &stmt in stmts {
		switch &stmt in stmt {
		case Label:
		case Write:
		case Expr:
		case Jmp:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case CJmp:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Return:
		case Mov:
		case Par:

		}
	}
}
