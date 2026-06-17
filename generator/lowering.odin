package generator

import "../parser"

program_lower :: proc(node: ^parser.Program) -> Program {
	program := Program{}
	functions := make([dynamic]Function, 0, len(node.functions))

	for f in node.functions {
		function := function_lower(f)
		append(&functions, function)
	}

	program.functions = functions[:]

	return program
}

function_lower :: proc(node: ^parser.Function) -> Function {
	var_counter: u64 = 0
	var_mapping := make(map[string]Variable)
	stmts := make([dynamic]Stmt)

	for par in node.parameter.parameter {
		v := var_next(&var_counter)
		var_mapping[par.literal] = v
		append(&stmts, Par{v})
	}

	stats_lower(node.stats, &stmts, &var_counter, &var_mapping)

	append(&stmts, Return{Number{0}})

	return Function{name = node.name.literal, stmts = stmts}
}

stats_lower :: proc(
	node: ^parser.Stats,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	for stat in node.stats {
		stat_lower(stat, stmts, var_counter, var_mapping)
	}
}

stat_lower :: proc(
	node: ^parser.Stat,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	switch node in node {
	case ^parser.Return:
		return_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Conds:
		conds_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Variable_Definition:
		variable_definition_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Variable_Assignment:
		variable_assignment_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Term:
		term_lower(node, stmts, var_counter, var_mapping)
	}
}

return_lower :: proc(
	node: ^parser.Return,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	expr := expr_lower(node.expr, stmts, var_counter, var_mapping)
	stmt: Stmt = Return{expr}
	append(stmts, stmt)
}

var_next :: proc(var_counter: ^u64) -> Variable {
	v := Variable{var_counter^}
	var_counter^ += 1
	return v
}

variable_definition_lower :: proc(
	node: ^parser.Variable_Definition,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	v := var_next(var_counter)
	var_mapping[node.variable.literal] = v
	expr := expr_lower(node.expr, stmts, var_counter, var_mapping)
	append(stmts, Mov{dest = v, src = expr})
}

variable_assignment_lower :: proc(
	node: ^parser.Variable_Assignment,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	expr := expr_lower(node.expr, stmts, var_counter, var_mapping)

	switch lexpr in node.lexpr {
	case ^parser.Variable:
		v := var_mapping[lexpr.literal]
		append(stmts, Mov{dest = v, src = expr})
	case ^parser.Array_Access:
		base := term_lower(lexpr.term, stmts, var_counter, var_mapping)
		offset := expr_lower(lexpr.expr, stmts, var_counter, var_mapping)
		stmt := Write {
			base   = base,
			offset = offset,
			value  = expr,
		}
		append(stmts, stmt)
	}
}

conds_lower :: proc(
	node: ^parser.Conds,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	append(stmts, Label{node.label.literal})

	for g in node.guarded {
		guarded_lower(g, stmts, var_counter, var_mapping)
	}

	append(stmts, Label{node.end_label.literal})
}

guarded_lower :: proc(
	node: ^parser.Guarded,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	expr := expr_lower(node.expr, stmts, var_counter, var_mapping)
	append(stmts, CJmp{on = expr, label = Label{node.end_label.literal}})

	inner_var_mapping := map_copy(var_mapping)
	defer delete(inner_var_mapping)

	stats_lower(node.stats, stmts, var_counter, &inner_var_mapping)
	continue_or_break_lower(node.continue_or_break, stmts, var_counter, var_mapping)

	append(stmts, Label{node.end_label.literal})
}

continue_or_break_lower :: proc(
	node: ^parser.Continue_Or_Break,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	switch node in node {
	case ^parser.Continue:
		continue_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Break:
		break_lower(node, stmts, var_counter, var_mapping)
	}
}

continue_lower :: proc(
	node: ^parser.Continue,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	append(stmts, Jmp{label = Label{node.label.literal}})
}

break_lower :: proc(
	node: ^parser.Break,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) {
	append(stmts, Jmp{label = Label{node.label.literal}})
}

variable_lower :: proc(
	node: ^parser.Variable,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	return var_mapping[node.literal]
}

expr_lower :: proc(
	node: ^parser.Expr,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	switch node in node {
	case ^parser.Not_Term:
		return not_term_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Array_Access:
		return array_read_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Sum:
		return sum_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Product:
		return product_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Conjunction:
		return conjunction_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Greater:
		return greater_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Equal:
		return equal_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Minus:
		return minus_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Term:
		return term_lower(node, stmts, var_counter, var_mapping)
	}

	unreachable()
}

array_read_lower :: proc(
	node: ^parser.Array_Access,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	offset := expr_lower(node.expr, stmts, var_counter, var_mapping)
	base := term_lower(node.term, stmts, var_counter, var_mapping)
	v := var_next(var_counter)
	append(stmts, Expr{out = v, expr = Read{base = base, offset = offset}})
	return v
}

not_term_lower :: proc(
	node: ^parser.Not_Term,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	term := term_lower(node.term, stmts, var_counter, var_mapping)
	if node.not_list.count % 2 == 0 {
		return term
	} else {
		v := var_next(var_counter)
		append(stmts, Expr{out = v, expr = Not{term}})
		return v
	}
}

sum_lower :: proc(
	node: ^parser.Sum,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {

	terms := make([dynamic]Operand)

	for t in node.terms {
		tt := term_lower(t, stmts, var_counter, var_mapping)
		append(&terms, tt)
	}

	dest := var_next(var_counter)

	append(stmts, Expr{out = dest, expr = Add{terms[:]}})
	return dest
}


product_lower :: proc(
	node: ^parser.Product,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	terms := make([dynamic]Operand)

	for t in node.terms {
		tt := term_lower(t, stmts, var_counter, var_mapping)
		append(&terms, tt)
	}

	dest := var_next(var_counter)

	append(stmts, Expr{out = dest, expr = Mul{terms[:]}})
	return dest
}

conjunction_lower :: proc(
	node: ^parser.Conjunction,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	terms := make([dynamic]Operand)

	for t in node.terms {
		tt := term_lower(t, stmts, var_counter, var_mapping)
		append(&terms, tt)
	}

	dest := var_next(var_counter)

	append(stmts, Expr{out = dest, expr = And{terms[:]}})
	return dest
}

greater_lower :: proc(
	node: ^parser.Greater,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	left := term_lower(node.left, stmts, var_counter, var_mapping)
	right := term_lower(node.right, stmts, var_counter, var_mapping)
	out := var_next(var_counter)

	append(stmts, Expr{out = out, expr = Gt{left = left, right = right}})
	return out
}


equal_lower :: proc(
	node: ^parser.Equal,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	left := term_lower(node.left, stmts, var_counter, var_mapping)
	right := term_lower(node.right, stmts, var_counter, var_mapping)
	out := var_next(var_counter)

	append(stmts, Expr{out = out, expr = Eq{left = left, right = right}})

	return out
}
minus_lower :: proc(
	node: ^parser.Minus,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	left := term_lower(node.left, stmts, var_counter, var_mapping)
	right := term_lower(node.right, stmts, var_counter, var_mapping)
	out := var_next(var_counter)

	append(stmts, Expr{out = out, expr = Sub{left = left, right = right}})

	return out
}

term_lower :: proc(
	node: ^parser.Term,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	switch node in node {
	case ^parser.Number:
		return number_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Variable:
		return variable_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Expr:
		return expr_lower(node, stmts, var_counter, var_mapping)
	case ^parser.Function_Call:
		return function_call_lower(node, stmts, var_counter, var_mapping)
	}

	unreachable()

}

number_lower :: proc(
	node: ^parser.Number,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	return Number{node.literal}
}

function_call_lower :: proc(
	node: ^parser.Function_Call,
	stmts: ^[dynamic]Stmt,
	var_counter: ^u64,
	var_mapping: ^map[string]Variable,
) -> Operand {
	arguments := make([]Operand, len(node.arguments))

	for _, i in node.arguments {
		arguments[i] = expr_lower(node.arguments[i], stmts, var_counter, var_mapping)
	}

	call := Call {
		name      = node.name.literal,
		arguments = arguments[:],
	}

	out := var_next(var_counter)

	append(stmts, Expr{out = out, expr = call})

	return out
}
