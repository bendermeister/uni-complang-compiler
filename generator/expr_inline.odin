package generator

expr_inline :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	for &stmt in stmts {
		switch inner in stmt {
		case Par:
		case Label:
		case Write:
		case Expr:
			stmt = expr_inline_expr(inner, has_changed)
		case Jmp:
		case CJmp:
			stmt = expr_inline_cjmp(inner, has_changed)
		case Return:
		case Mov:
		}
	}
}

expr_inline_expr :: proc(n: Expr, has_changed: ^bool) -> Stmt {
	switch inner in n.expr {
	case Add:
		return expr_inline_add(inner, n.out, has_changed)
	case And:
		return expr_inline_and(inner, n.out, has_changed)
	case Sub:
		return expr_inline_sub(inner, n.out, has_changed)
	case Mul:
		return expr_inline_mul(inner, n.out, has_changed)
	case Eq:
		return expr_inline_eq(inner, n.out, has_changed)
	case Gt:
		return expr_inline_gt(inner, n.out, has_changed)
	case Not:
		return expr_inline_not(inner, n.out, has_changed)
	case Read:
		return n
	case Call:
		return n
	}

	unreachable()
}

expr_inline_add :: proc(n: Add, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		return Mov{dest = dest, src = Number{left.inner + right.inner}}
	}
	return Expr{out = dest, expr = n}
}

expr_inline_and :: proc(n: And, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		return Mov{dest = dest, src = Number{left.inner & right.inner}}
	}
	return Expr{out = dest, expr = n}
}

expr_inline_sub :: proc(n: Sub, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		return Mov{dest = dest, src = Number{left.inner - right.inner}}
	}
	return Expr{out = dest, expr = n}
}

expr_inline_mul :: proc(n: Mul, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		return Mov{dest = dest, src = Number{left.inner * right.inner}}
	}
	return Expr{out = dest, expr = n}
}

expr_inline_eq :: proc(n: Eq, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		src: u64 = 0
		if left.inner == right.inner {
			src = 1
		}
		return Mov{dest = dest, src = Number{src}}
	}
	return Expr{out = dest, expr = n}
}

expr_inline_gt :: proc(n: Gt, dest: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.left) && operand_is_number(n.right) {
		left := n.left.(Number)
		right := n.right.(Number)
		has_changed^ = true
		src: u64 = 0
		if left.inner > right.inner {
			src = 1
		}
		return Mov{dest = dest, src = Number{src}}
	}
	return Expr{out = dest, expr = n}

}

expr_inline_not :: proc(n: Not, out: Variable, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.operand) {
		operand := n.operand.(Number)
		operand = Number{(operand.inner & 1) ~ 1}
		has_changed^ = true
		return Mov{dest = out, src = operand}
	}
	return Expr{out = out, expr = n}
}

expr_inline_cjmp :: proc(n: CJmp, has_changed: ^bool) -> Stmt {
	if operand_is_number(n.on) {
		on := n.on.(Number)
		if on.inner & 1 == 1 {
			return Jmp{n.label}
		} else {
			return nil
		}
	}
	return n
}
