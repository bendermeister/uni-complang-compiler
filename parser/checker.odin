package parser

map_copy :: proc(m: ^map[$T]$E) -> map[T]E {
	n := make(map[T]E)

	for k, v in m {
		n[k] = v
	}

	return n
}

check_program :: proc(node: ^Program) -> (ok: bool) {

	for f in node.functions {
		vars := make(map[string]bool)
		labels := make(map[string]bool)

		defer delete(vars)
		defer delete(labels)

		ok := check_function(f, &vars, &labels)

		if !ok {
			return false
		}
	}

	return true
}

check_function :: proc(
	node: ^Function,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {

	ok = check_parameter(node.parameter, variables, labels)
	if !ok {
		return false
	}

	ok = check_stats(node.stats, variables, labels)
	if !ok {
		return false
	}

	return true
}

check_parameter :: proc(
	node: ^Parameter,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {

	for v in node.parameter {
		_, contains := variables[v.literal]
		if contains {
			return false
		}
		variables[v.literal] = true
	}


	return true
}

check_stats :: proc(
	node: ^Stats,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {

	for stat in node.stats {
		ok := check_stat(stat, variables, labels)
		if !ok {
			return false
		}
	}

	return true
}

check_stat :: proc(
	node: ^Stat,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	switch stat in node {
	case ^Return:
		return check_return(stat, variables, labels)
	case ^Conds:
		return check_conds(stat, variables, labels)
	case ^Variable_Definition:
		return check_variable_definition(stat, variables, labels)
	case ^Variable_Assignment:
		return check_variable_assignment(stat, variables, labels)
	case ^Term:
		return check_term(stat, variables, labels)
	}

	unreachable()
}

check_variable_assignment :: proc(
	node: ^Variable_Assignment,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_lexpr(node.lexpr, variables, labels)
	if !ok {
		return false
	}

	ok = check_expr(node.expr, variables, labels)
	if !ok {
		return false
	}

	return true
}

check_variable_definition :: proc(
	node: ^Variable_Definition,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_expr(node.expr, variables, labels)
	if !ok {
		return false
	}

	_, contains := variables[node.variable.literal]
	if contains {
		return false
	}

	variables[node.variable.literal] = true

	return true
}

check_return :: proc(
	node: ^Return,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	return check_expr(node.expr, variables, labels)
}

check_conds :: proc(
	node: ^Conds,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	variables_new := map_copy(variables)
	defer delete(variables_new)

	labels_new := map_copy(labels)
	defer delete(labels_new)

	if node.label != nil {
		_, contains := labels[node.label.literal]
		if contains {
			return false
		}
		labels_new[node.label.literal] = true
	}

	for g in node.guarded {
		ok = check_guarded(g, &variables_new, &labels_new)
		if !ok {
			return false
		}
	}

	return true
}


check_guarded :: proc(
	node: ^Guarded,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	if node.expr != nil {
		ok = check_expr(node.expr, variables, labels)
		if !ok {
			return false
		}
	}

	variables_new := map_copy(variables)
	defer delete(variables_new)

	labels_new := map_copy(labels)
	defer delete(labels_new)

	ok = check_stats(node.stats, &variables_new, &labels_new)
	if !ok {
		return false
	}

	ok = check_continue_or_break(node.continue_or_break, variables, labels)
	if !ok {
		return false
	}

	return true
}

check_continue :: proc(
	node: ^Continue,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	if node.label != nil {
		_, contains := labels[node.label.literal]
		if !contains {
			return false
		}
	}
	return true
}

check_break :: proc(
	node: ^Break,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	if node.label != nil {
		_, contains := labels[node.label.literal]
		if !contains {
			return false
		}
	}
	return true
}

check_continue_or_break :: proc(
	node: ^Continue_Or_Break,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	switch n in node {
	case ^Continue:
		return check_continue(n, variables, labels)
	case ^Break:
		return check_break(n, variables, labels)
	}
	unreachable()
}

check_lexpr :: proc(
	node: ^L_Expr,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	switch n in node {
	case ^Variable:
		_, contains := variables[n.literal]
		return contains
	case ^Array_Access:
		return check_array_access(n, variables, labels)
	}

	unreachable()
}

check_array_access :: proc(
	node: ^Array_Access,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_term(node.term, variables, labels)
	if !ok {
		return false
	}

	ok = check_expr(node.expr, variables, labels)
	if !ok {
		return false
	}

	return true
}

check_expr :: proc(
	node: ^Expr,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	switch n in node {
	case ^Not_Term:
		return check_term(n.term, variables, labels)
	case ^Array_Access:
		return check_array_access(n, variables, labels)
	case ^Sum:
		return check_sum(n, variables, labels)
	case ^Product:
		return check_product(n, variables, labels)
	case ^Conjunction:
		return check_conjunction(n, variables, labels)
	case ^Greater:
		return check_greater(n, variables, labels)
	case ^Equal:
		return check_equal(n, variables, labels)
	case ^Minus:
		return check_minus(n, variables, labels)
	case ^Term:
		return check_term(n, variables, labels)
	}

	unreachable()
}

check_sum :: proc(
	node: ^Sum,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	for t in node.terms {
		ok = check_term(t, variables, labels)
		if !ok {
			return false
		}
	}
	return true
}

check_product :: proc(
	node: ^Product,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	for t in node.terms {
		ok = check_term(t, variables, labels)
		if !ok {
			return false
		}
	}
	return true
}

check_conjunction :: proc(
	node: ^Conjunction,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	for t in node.terms {
		ok = check_term(t, variables, labels)
		if !ok {
			return false
		}
	}
	return true
}

check_greater :: proc(
	node: ^Greater,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_term(node.left, variables, labels)
	if !ok {
		return false
	}

	ok = check_term(node.right, variables, labels)
	if !ok {
		return false
	}
	return true
}

check_equal :: proc(
	node: ^Equal,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_term(node.left, variables, labels)
	if !ok {
		return false
	}

	ok = check_term(node.right, variables, labels)
	if !ok {
		return false
	}
	return true
}

check_minus :: proc(
	node: ^Minus,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	ok = check_term(node.left, variables, labels)
	if !ok {
		return false
	}

	ok = check_term(node.right, variables, labels)
	if !ok {
		return false
	}
	return true
}

check_term :: proc(
	node: ^Term,
	variables: ^map[string]bool,
	labels: ^map[string]bool,
) -> (
	ok: bool,
) {
	switch n in node {
	case ^Number:
		return true
	case ^Variable:
		_, contains := variables[n.literal]
		return contains
	case ^Expr:
		return check_expr(n, variables, labels)
	case ^Function_Call:
		return true
	}
	unreachable()
}
