package generator

label_merge :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	label_map := make(map[Label]Label)
	defer delete(label_map)

	for stmt, i in stmts {
		if stmt == nil {continue}
		#partial switch stmt in stmt {
		case Label:
			for &nstmt in stmts[i + 1:] {
				if !stmt_is_label(nstmt) {break}
				has_changed^ = true
				label := nstmt.(Label)
				label_map[label] = stmt
				nstmt = nil
			}
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
		case Jz:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jnz:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Je:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jne:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jg:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jge:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jl:
			stmt.label = label_map[stmt.label] or_else stmt.label
		case Jle:
			stmt.label = label_map[stmt.label] or_else stmt.label

		}
	}
}
