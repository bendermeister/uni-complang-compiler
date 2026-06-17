package generator

var_reuse :: proc(stmts: ^[dynamic]Stmt) {
	vars := get_all_vars(stmts[:])
	var_def := get_all_var_def_index(stmts[:])
	var_use := get_all_var_last_use(stmts[:])

	defer delete(vars)
	defer delete(var_def)
	defer delete(var_use)

	replace := make(map[Variable]Variable)
	defer delete(replace)

	var_reuse_find_replacements(vars[:], &var_def, &var_use, &replace, len(stmts) + 1)

	for &stmt in stmts {
		switch &stmt in stmt {
		case Label:
		case Write:
			stmt.base = var_reuse_replace_operand(stmt.base, &replace)
			stmt.offset = var_reuse_replace_operand(stmt.offset, &replace)
			stmt.value = var_reuse_replace_operand(stmt.value, &replace)
		case Expr:
			stmt.out = var_reuse_replace_var(stmt.out, &replace)
			switch &expr in stmt.expr {
			case Add:
				for &t in expr.terms {
					t = var_reuse_replace_operand(t, &replace)
				}
			case And:
				for &t in expr.terms {
					t = var_reuse_replace_operand(t, &replace)
				}
			case Sub:
				expr.left = var_reuse_replace_operand(expr.left, &replace)
				expr.right = var_reuse_replace_operand(expr.right, &replace)
			case Mul:
				for &t in expr.terms {
					t = var_reuse_replace_operand(t, &replace)
				}
			case Eq:
				expr.left = var_reuse_replace_operand(expr.left, &replace)
				expr.right = var_reuse_replace_operand(expr.right, &replace)
			case Gt:
				expr.left = var_reuse_replace_operand(expr.left, &replace)
				expr.right = var_reuse_replace_operand(expr.right, &replace)
			case Not:
				expr.operand = var_reuse_replace_operand(expr.operand, &replace)
			case Read:
				expr.base = var_reuse_replace_operand(expr.base, &replace)
				expr.offset = var_reuse_replace_operand(expr.offset, &replace)
			case Call:
				for &a in expr.arguments {
					a = var_reuse_replace_operand(a, &replace)
				}
			}
		case Jmp:
		case CJmp:
			stmt.on = var_reuse_replace_operand(stmt.on, &replace)
		case Return:
			stmt.operand = var_reuse_replace_operand(stmt.operand, &replace)
		case Mov:
			stmt.dest = var_reuse_replace_var(stmt.dest, &replace)
		case Par:
			stmt.var = var_reuse_replace_var(stmt.var, &replace)
		case Jz:
			stmt.on = var_reuse_replace_operand(stmt.on, &replace)
		case Jnz:
			stmt.on = var_reuse_replace_operand(stmt.on, &replace)
		case Je:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		case Jne:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		case Jg:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		case Jge:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		case Jl:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		case Jle:
			stmt.left = var_reuse_replace_operand(stmt.left, &replace)
			stmt.right = var_reuse_replace_operand(stmt.right, &replace)
		}
	}
}

var_reuse_find_replacements :: proc(
	vars: []Variable,
	defs: ^map[Variable]int,
	uses: ^map[Variable]int,
	replacement: ^map[Variable]Variable,
	max_diff: int,
) {
	a: Variable
	b: Variable
	ok := false
	min_diff := max_diff

	for c in vars {
		for d in vars {
			if c == d {continue}
			if c not_in defs {continue}
			if d not_in uses {continue}
			cdef := defs[c]
			duse := uses[d]
			if cdef < duse {continue}
			diff := cdef - duse

			if diff < min_diff {
				min_diff = diff
				a = c
				b = d
				ok = true
			}
		}
	}

	if !ok {return}

	// replace a with b
	replacement[a] = b
	if a in uses {
		uses[b] = uses[a]
	}
	delete_key(uses, a)
	delete_key(defs, a)

	var_reuse_find_replacements(vars, defs, uses, replacement, max_diff)
}

var_reuse_replace_var :: proc(v: Variable, replacement: ^map[Variable]Variable) -> Variable {
	w, ok := replacement[v]
	if !ok {
		return v
	}
	return var_reuse_replace_var(w, replacement)
}

var_reuse_replace_operand :: proc(o: Operand, replacement: ^map[Variable]Variable) -> Operand {
	if operand_is_number(o) {return o}
	return var_reuse_replace_var(o.(Variable), replacement)
}
