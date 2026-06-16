package generator

nil_unused :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	var_usage := make(map[Operand]bool)
	label_usage := make(map[Label]bool)
	defer delete(var_usage)

	for stmt in stmts {
		switch inner in stmt {
		case Par:
		case Label:
		case Write:
			nil_unused_write(inner, &var_usage)
		case Expr:
			nil_unused_expr(inner, &var_usage)
		case Jmp:
			nil_unused_jmp(inner, &label_usage)
		case CJmp:
			nil_unused_cjmp(inner, &var_usage, &label_usage)
		case Return:
			nil_unused_return(inner, &var_usage)
		case Mov:
			nil_unused_mov(inner, &var_usage)
		}
	}

	for &stmt in stmts {
		switch inner in stmt {
		case Par:
		case Label:
			if inner not_in label_usage {
				stmt = nil
				has_changed^ = true
			}
		case Write:
		case Expr:
			if inner.out not_in var_usage {
				stmt = nil
				has_changed^ = true
			}
		case Jmp:
		case CJmp:
		case Return:
		case Mov:
			if inner.dest not_in var_usage {
				stmt = nil
				has_changed^ = true
			}
		}
	}
}

nil_unused_write :: proc(stmt: Write, usage: ^map[Operand]bool) {
	usage[stmt.base] = true
	usage[stmt.offset] = true
	usage[stmt.value] = true
}

nil_unused_cjmp :: proc(stmt: CJmp, var_usage: ^map[Operand]bool, label_usage: ^map[Label]bool) {
	var_usage[stmt.on] = true
	label_usage[stmt.label] = true
}

nil_unused_jmp :: proc(stmt: Jmp, usage: ^map[Label]bool) {
	usage[stmt.label] = true
}

nil_unused_return :: proc(stmt: Return, usage: ^map[Operand]bool) {
	usage[stmt.operand] = true
}

nil_unused_mov :: proc(stmt: Mov, usage: ^map[Operand]bool) {
	usage[stmt.src] = true
}

nil_unused_expr :: proc(stmt: Expr, usage: ^map[Operand]bool) {
	switch expr in stmt.expr {
	case Add:
		nil_unused_add(expr, usage)
	case And:
		nil_unused_and(expr, usage)
	case Sub:
		nil_unused_sub(expr, usage)
	case Mul:
		nil_unused_mul(expr, usage)
	case Eq:
		nil_unused_eq(expr, usage)
	case Gt:
		nil_unused_gt(expr, usage)
	case Not:
		nil_unused_not(expr, usage)
	case Read:
		nil_unused_read(expr, usage)
	case Call:
		usage[stmt.out] = true
		nil_unused_call(expr, usage)
	}
}

nil_unused_add :: proc(n: Add, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_and :: proc(n: And, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_sub :: proc(n: Sub, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_mul :: proc(n: Mul, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_eq :: proc(n: Eq, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_gt :: proc(n: Gt, usage: ^map[Operand]bool) {
	usage[n.left] = true
	usage[n.right] = true
}

nil_unused_not :: proc(n: Not, usage: ^map[Operand]bool) {
	usage[n.operand] = true
}

nil_unused_read :: proc(n: Read, usage: ^map[Operand]bool) {
	usage[n.base] = true
	usage[n.offset] = true
}

nil_unused_call :: proc(n: Call, usage: ^map[Operand]bool) {
	for arg in n.arguments {
		usage[arg] = true
	}
}
