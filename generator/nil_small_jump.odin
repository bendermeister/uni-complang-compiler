package generator

nil_small_jump :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	labels := make(map[Label]int)
	defer delete(labels)

	for stmt, i in stmts {
		if !stmt_is_label(stmt) {continue}
		labels[stmt.(Label)] = i
	}

	for &stmt, i in stmts {
		#partial switch &label in stmt {
		case Jmp:
			j, ok := labels[label.label]
			if !ok {continue}
			if abs(j - i) == 1 {
				has_changed^ = true
				stmt = nil
			}
		case CJmp:
			j, ok := labels[label.label]
			if !ok {continue}
			if abs(j - i) == 1 {
				has_changed^ = true
				stmt = nil
			}
		}
	}
}
