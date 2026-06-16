package generator

mov_inline :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	writes := make(map[Variable]int)
	movs := make(map[Variable]Operand)

	for stmt in stmts {
		switch stmt in stmt {
		case Label:
		case Write:
		case Expr:
			writes[stmt.out] += 1
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
			writes[stmt.dest] += 1
			movs[stmt.dest] = stmt.src
		case Par:
		}
	}

	for k, v in writes {
		if v == 1 {continue}
		delete_key(&movs, k)
	}

	for &stmt in stmts {
		switch &stmt in stmt {
		case Label:
		case Write:
			stmt.value = mov_inline_replace_operand(stmt.value, &movs)
			stmt.base = mov_inline_replace_operand(stmt.base, &movs)
			stmt.offset = mov_inline_replace_operand(stmt.offset, &movs)
		case Expr:
			switch &expr in stmt.expr {
			case Add:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case And:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case Sub:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case Mul:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case Eq:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case Gt:
				expr.left = mov_inline_replace_operand(expr.left, &movs)
				expr.right = mov_inline_replace_operand(expr.right, &movs)
			case Not:
				expr.operand = mov_inline_replace_operand(expr.operand, &movs)
			case Read:
				expr.base = mov_inline_replace_operand(expr.base, &movs)
				expr.offset = mov_inline_replace_operand(expr.offset, &movs)
			case Call:
				for &a in expr.arguments {
					a = mov_inline_replace_operand(a, &movs)
				}
			}
		case Jmp:
		case CJmp:
			stmt.on = mov_inline_replace_operand(stmt.on, &movs)
		case Return:
			stmt.operand = mov_inline_replace_operand(stmt.operand, &movs)
		case Mov:
			stmt.src = mov_inline_replace_operand(stmt.src, &movs)
		case Par:
		}
	}
}

mov_inline_replace_operand :: proc(o: Operand, movs: ^map[Variable]Operand) -> Operand {
	if operand_is_number(o) {return o}
	v := o.(Variable)
	if v not_in movs {return o}
	return movs[v]
}
