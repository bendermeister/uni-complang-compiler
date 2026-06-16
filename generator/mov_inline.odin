package generator

mov_inline :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	opmap := make(map[Operand]Operand)

	for &stmt in stmts {
		switch &stmt in stmt {
		case Par:
		case Mov:
			mov_inline_mov(&stmt, &opmap, has_changed)
		case Label:
		case Write:
			mov_inline_write(&stmt, &opmap, has_changed)
		case Expr:
			mov_inline_expr(&stmt, &opmap, has_changed)
		case Jmp:
		case CJmp:
			mov_inline_cjmp(&stmt, &opmap, has_changed)
		case Return:
			mov_inline_return(&stmt, &opmap, has_changed)
		}
	}
}

mov_inline_op :: proc(op: Operand, opmap: ^map[Operand]Operand, has_changed: ^bool) -> Operand {
	other, ok := opmap[op]
	if ok {
		has_changed^ = true
		return other
	}
	return op
}

mov_inline_mov :: proc(stmt: ^Mov, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	has_changed^ = true
	opmap[stmt.dest] = stmt.src
}

mov_inline_write :: proc(stmt: ^Write, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.base = mov_inline_op(stmt.base, opmap, has_changed)
	stmt.offset = mov_inline_op(stmt.offset, opmap, has_changed)
	stmt.value = mov_inline_op(stmt.value, opmap, has_changed)
}

mov_inline_expr :: proc(stmt: ^Expr, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	switch &expr in stmt.expr {
	case Add:
		mov_inline_add(&expr, opmap, has_changed)
	case And:
		mov_inline_and(&expr, opmap, has_changed)
	case Sub:
		mov_inline_sub(&expr, opmap, has_changed)
	case Mul:
		mov_inline_mul(&expr, opmap, has_changed)
	case Eq:
		mov_inline_eq(&expr, opmap, has_changed)
	case Gt:
		mov_inline_gt(&expr, opmap, has_changed)
	case Not:
		mov_inline_not(&expr, opmap, has_changed)
	case Read:
		mov_inline_read(&expr, opmap, has_changed)
	case Call:
		mov_inline_call(&expr, opmap, has_changed)
	}
}

mov_inline_cjmp :: proc(stmt: ^CJmp, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.on = mov_inline_op(stmt.on, opmap, has_changed)
}

mov_inline_return :: proc(stmt: ^Return, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.operand = mov_inline_op(stmt.operand, opmap, has_changed)
}

mov_inline_add :: proc(stmt: ^Add, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_and :: proc(stmt: ^And, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_sub :: proc(stmt: ^Sub, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_mul :: proc(stmt: ^Mul, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_eq :: proc(stmt: ^Eq, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_gt :: proc(stmt: ^Gt, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.left = mov_inline_op(stmt.left, opmap, has_changed)
	stmt.right = mov_inline_op(stmt.right, opmap, has_changed)
}

mov_inline_not :: proc(stmt: ^Not, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.operand = mov_inline_op(stmt.operand, opmap, has_changed)
}

mov_inline_read :: proc(stmt: ^Read, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	stmt.offset = mov_inline_op(stmt.offset, opmap, has_changed)
	stmt.base = mov_inline_op(stmt.base, opmap, has_changed)
}

mov_inline_call :: proc(stmt: ^Call, opmap: ^map[Operand]Operand, has_changed: ^bool) {
	for &arg in stmt.arguments {
		arg = mov_inline_op(arg, opmap, has_changed)
	}
}
