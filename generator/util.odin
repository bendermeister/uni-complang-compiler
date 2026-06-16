package generator

map_copy :: proc(m: ^map[$T]$E) -> map[T]E {
	n := make(map[T]E)

	for k, v in m {
		n[k] = v
	}

	return n
}

get_all_vars :: proc(stmts: []Stmt) -> [dynamic]Variable {
	vars := make([dynamic]Variable)

	for stmt in stmts {
		switch stmt in stmt {
		case Label:
		case Write:
		case Expr:
			append(&vars, stmt.out)
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
			append(&vars, stmt.dest)
		case Par:
			append(&vars, stmt.var)
		}
	}

	return vars
}

get_all_var_def_index :: proc(stmts: []Stmt) -> map[Variable]int {
	var_def := make(map[Variable]int)

	for stmt, i in stmts {
		switch stmt in stmt {
		case Label:
		case Write:
		case Expr:
			var_def[stmt.out] = i
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
			var_def[stmt.dest] = i
		case Par:
			var_def[stmt.var] = i
		}
	}

	return var_def
}

get_all_label_index :: proc(stmts: []Stmt) -> map[Label]int {
	labels := make(map[Label]int)

	for stmt, i in stmts {
		switch stmt in stmt {
		case Label:
			labels[stmt] = i
		case Write:
		case Expr:
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
		case Par:

		}
	}

	return labels
}

get_all_var_last_use :: proc(stmts: []Stmt) -> map[Variable]int {
	op_use := make(map[Operand]int)
	defer delete(op_use)
	labels := make(map[Label]int)
	defer delete(labels)

	for stmt, i in stmts {
		switch stmt in stmt {
		case Label:
			labels[stmt] = i
		case Write:
			op_use[stmt.offset] = i
			op_use[stmt.value] = i
			op_use[stmt.base] = i
		case Expr:
			op_use[stmt.out] = i
			switch expr in stmt.expr {
			case Add:
				for t in expr.terms {
					op_use[t] = i
				}
			case And:
				for t in expr.terms {
					op_use[t] = i
				}
			case Sub:
				op_use[expr.left] = i
				op_use[expr.right] = i
			case Mul:
				for t in expr.terms {
					op_use[t] = i
				}
			case Eq:
				op_use[expr.left] = i
				op_use[expr.right] = i
			case Gt:
				op_use[expr.left] = i
				op_use[expr.right] = i
			case Not:
				op_use[expr.operand] = i
			case Read:
				op_use[expr.base] = i
				op_use[expr.offset] = i
			case Call:
				for a in expr.arguments {
					op_use[a] = i
				}
			}
		case Jmp:
			if stmt.label not_in labels {continue}
			label := labels[stmt.label]
			for k, &v in op_use {
				if v > label {
					v = i
				}
			}
		case CJmp:
			op_use[stmt.on] = i
			if stmt.label not_in labels {continue}
			label := labels[stmt.label]
			for k, &v in op_use {
				if v > label {
					v = i
				}
			}
		case Return:
			op_use[stmt.operand] = i
		case Mov:
			op_use[stmt.dest] = i
			op_use[stmt.src] = i
		case Par:
			op_use[stmt.var] = i
		}
	}

	var_use := make(map[Variable]int)

	for k, v in op_use {
		if operand_is_number(k) {continue}
		var_use[k.(Variable)] = v
	}

	return var_use
}
