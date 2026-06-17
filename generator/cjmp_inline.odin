package generator

cjmp_inline :: proc(stmts: ^[dynamic]Stmt, has_changed: ^bool) {
	jmps := make(map[Label][dynamic]int)

	defer for _, v in jmps {
		delete(v)
	}

	defer delete(jmps)

	for &stmt, i in stmts {
		#partial switch inner in stmt {
		case CJmp:
			has_changed^ = true
			stmt = Jz {
				on    = inner.on,
				label = inner.label,
			}
		}

		label, ok := stmt_get_label_when_is_jmp(stmt)
		if ok {
			if label not_in jmps {
				jmps[label] = make([dynamic]int)
			}

			append(&jmps[label], i)
		}
	}

	for &stmt, i in stmts {
		#partial switch inner in stmt {
		case Jz:
			cjmp_inline_jz(stmts[:], i, &jmps, has_changed)
		case Jnz:
			cjmp_inline_jnz(stmts[:], i, &jmps, has_changed)
		}
	}
}

cjmp_inline_jnz :: proc(stmts: []Stmt, i: int, jmps: ^map[Label][dynamic]int, has_changed: ^bool) {
	stmt := stmts[i].(Jnz)
	if !operand_is_variable(stmt.on) {
		return
	}
	seen := make(map[int]bool)
	defer delete(seen)

	src, ok := cjmp_inline_find_source(stmts, i, stmt.on.(Variable), &seen, jmps)
	if !ok {return}

	src_stmt := stmts[src]

	#partial switch src_stmt in src_stmt {
	case Expr:
		switch expr in src_stmt.expr {
		case Add:
		case And:
		case Sub:
		case Mul:
		case Eq:
			stmts[i] = Je {
				left  = expr.left,
				right = expr.right,
				label = stmt.label,
			}
			has_changed^ = true
		case Gt:
			stmts[i] = Jg {
				left  = expr.left,
				right = expr.right,
				label = stmt.label,
			}
			has_changed^ = true
		case Not:
			stmts[i] = Jz {
				on    = expr.operand,
				label = stmt.label,
			}
			has_changed^ = true
		case Read:
		case Call:

		}
	case Mov:
		stmts[i] = Jnz {
			on    = src_stmt.src,
			label = stmt.label,
		}
		has_changed^ = true
	}
}

cjmp_inline_jz :: proc(stmts: []Stmt, i: int, jmps: ^map[Label][dynamic]int, has_changed: ^bool) {
	stmt := stmts[i].(Jz)
	if !operand_is_variable(stmt.on) {
		return
	}
	seen := make(map[int]bool)
	defer delete(seen)

	src, ok := cjmp_inline_find_source(stmts, i, stmt.on.(Variable), &seen, jmps)
	if !ok {return}

	src_stmt := stmts[src]

	#partial switch src_stmt in src_stmt {
	case Expr:
		switch expr in src_stmt.expr {
		case Add:
		case And:
		case Sub:
		case Mul:
		case Eq:
			stmts[i] = Jne {
				left  = expr.left,
				right = expr.right,
				label = stmt.label,
			}
			has_changed^ = true
		case Gt:
			stmts[i] = Jle {
				left  = expr.left,
				right = expr.right,
				label = stmt.label,
			}
			has_changed^ = true
		case Not:
			stmts[i] = Jnz {
				on    = expr.operand,
				label = stmt.label,
			}
			has_changed^ = true
		case Read:
		case Call:

		}
	case Mov:
		stmts[i] = Jz {
			on    = src_stmt.src,
			label = stmt.label,
		}
		has_changed^ = true
	}
}

cjmp_inline_find_source :: proc(
	stmts: []Stmt,
	i: int,
	dest: Variable,
	seen: ^map[int]bool,
	jmps: ^map[Label][dynamic]int,
) -> (
	int,
	bool,
) {
	if i < 0 {
		return 0, false
	}

	if i >= len(stmts) {
		return 0, false
	}

	if i in seen {
		return 0, false
	}

	seen[i] = true

	switch stmt in stmts[i] {
	case Label:
		src := 0
		rets := 0
		for jmp in jmps[stmt] {
			s, ok := cjmp_inline_find_source(stmts, jmp, dest, seen, jmps)
			if !ok {continue}
			src = s
			rets += 1
		}
		s, ok := cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
		if ok {
			src = s
			rets := 1
		}
		if rets == 1 {
			return src, true
		} else {
			return 0, false
		}
	case Write:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Expr:
		if stmt.out == dest {
			return i, true
		}
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jmp:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case CJmp:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Return:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Mov:
		if stmt.dest == dest {
			return i, true
		}
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Par:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jz:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jnz:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Je:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jne:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jg:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jge:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jl:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	case Jle:
		return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
	}
	return cjmp_inline_find_source(stmts, i - 1, dest, seen, jmps)
}
