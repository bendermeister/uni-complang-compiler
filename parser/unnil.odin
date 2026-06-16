package parser

Unnil_State :: struct {
	generator:   Label_Generator,
	used_labels: [dynamic]string,
}

make_unnil_state :: proc() -> ^Unnil_State {
	s := new(Unnil_State)
	s^ = Unnil_State {
		used_labels = make([dynamic]string),
		generator   = label_generator_make(),
	}
	return s
}

delete_unnil_state :: proc(state: ^Unnil_State) {
	label_generator_delete(state.generator)
	delete(state.used_labels)
	free(state)
}

unnil_variable :: proc(node: ^Variable, state: ^Unnil_State) {}
unnil_label :: proc(node: ^Label, state: ^Unnil_State) {
	state.generator.labels[node.literal] = true

}

unnil_number :: proc(node: ^Number, state: ^Unnil_State) {}
unnil_function_name :: proc(node: ^Function_Name, state: ^Unnil_State) {}
unnil_program :: proc(node: ^Program) {
	for f in node.functions {
		state := make_unnil_state()
		defer delete_unnil_state(state)
		unnil_function(f, state)
	}
}

unnil_function :: proc(node: ^Function, state: ^Unnil_State) {
	unnil_parameter(node.parameter, state)
	unnil_stats(node.stats, state)
}

unnil_parameter :: proc(node: ^Parameter, state: ^Unnil_State) {}

unnil_stats :: proc(node: ^Stats, state: ^Unnil_State) {
	for stat in node.stats {
		unnil_stat(stat, state)
	}
}

unnil_return :: proc(node: ^Return, state: ^Unnil_State) {
	if node.expr != nil {
		unnil_expr(node.expr, state)
	} else {
		node.expr = make_expr(make_term(make_number(0)))
	}
}

unnil_stat :: proc(node: ^Stat, state: ^Unnil_State) {
	switch inner in node {
	case ^Return:
		unnil_return(inner, state)
	case ^Conds:
		unnil_conds(inner, state)
	case ^Variable_Definition:
		unnil_variable_defintion(inner, state)
	case ^Variable_Assignment:
		unnil_variable_assignment(inner, state)
	case ^Term:
		unnil_term(inner, state)
	}
}

unnil_variable_defintion :: proc(node: ^Variable_Definition, state: ^Unnil_State) {
	unnil_variable(node.variable, state)
	unnil_expr(node.expr, state)
}

unnil_variable_assignment :: proc(node: ^Variable_Assignment, state: ^Unnil_State) {
	unnil_lexpr(node.lexpr, state)
	unnil_expr(node.expr, state)
}

unnil_lexpr :: proc(node: ^L_Expr, state: ^Unnil_State) {
	switch inner in node {
	case ^Variable:
		unnil_variable(inner, state)
	case ^Array_Access:
		unnil_array_access(inner, state)
	}
}

unnil_conds :: proc(node: ^Conds, state: ^Unnil_State) {
	if node.label == nil {
		node.label = label_generator_generate(&state.generator)
	}

	append(&state.used_labels, node.label.literal)

	for g in node.guarded {
		unnil_guarded(g, state)
	}

	pop(&state.used_labels)
}

unnil_guarded :: proc(node: ^Guarded, state: ^Unnil_State) {
	if node.expr == nil {
		node.expr = make_expr(make_term(make_number(1)))
	}

	unnil_stats(node.stats, state)

	unnil_continue_or_break(node.continue_or_break, state)
}

unnil_continue_or_break :: proc(node: ^Continue_Or_Break, state: ^Unnil_State) {
	switch inner in node {
	case ^Continue:
		unnil_continue(inner, state)
	case ^Break:
		unnil_break(inner, state)
	}
}

unnil_continue :: proc(node: ^Continue, state: ^Unnil_State) {
	if node.label == nil {
		if len(state.used_labels) == 0 {
			panic("this should be impossible to reach")
		}

		node.label = make_label(state.used_labels[len(state.used_labels) - 1])
	}
}

unnil_break :: proc(node: ^Break, state: ^Unnil_State) {
	if node.label == nil {
		if len(state.used_labels) == 0 {
			panic("this should be impossible to reach")
		}

		node.label = make_label(state.used_labels[len(state.used_labels) - 1])
	}
}

unnil_expr :: proc(node: ^Expr, state: ^Unnil_State) {
	switch inner in node {
	case ^Not_Term:
		unnil_not_term(inner, state)
	case ^Array_Access:
		unnil_array_access(inner, state)
	case ^Sum:
		unnil_sum(inner, state)
	case ^Product:
		unnil_product(inner, state)
	case ^Conjunction:
		unnil_conjunction(inner, state)
	case ^Greater:
		unnil_greater(inner, state)
	case ^Equal:
		unnil_equal(inner, state)
	case ^Minus:
		unnil_minus(inner, state)
	case ^Term:
		unnil_term(inner, state)
	}
}

unnil_function_call :: proc(node: ^Function_Call, state: ^Unnil_State) {
	for e in node.arguments {
		unnil_expr(e, state)
	}
}

unnil_term :: proc(node: ^Term, state: ^Unnil_State) {
	switch inner in node {
	case ^Number:
		unnil_number(inner, state)
	case ^Variable:
		unnil_variable(inner, state)
	case ^Expr:
		unnil_expr(inner, state)
	case ^Function_Call:
		unnil_function_call(inner, state)
	}
}

unnil_not_list :: proc(node: ^Not_List, state: ^Unnil_State) {}

unnil_not_term :: proc(node: ^Not_Term, state: ^Unnil_State) {
	unnil_not_list(node.not_list, state)
	unnil_term(node.term, state)
}

unnil_array_access :: proc(node: ^Array_Access, state: ^Unnil_State) {
	unnil_term(node.term, state)
	unnil_expr(node.expr, state)
}

unnil_sum :: proc(node: ^Sum, state: ^Unnil_State) {
	for t in node.terms {
		unnil_term(t, state)
	}
}

unnil_product :: proc(node: ^Product, state: ^Unnil_State) {
	for t in node.terms {
		unnil_term(t, state)
	}
}

unnil_conjunction :: proc(node: ^Conjunction, state: ^Unnil_State) {
	for t in node.terms {
		unnil_term(t, state)
	}
}

unnil_greater :: proc(node: ^Greater, state: ^Unnil_State) {
	unnil_term(node.left, state)
	unnil_term(node.right, state)
}

unnil_equal :: proc(node: ^Equal, state: ^Unnil_State) {
	unnil_term(node.left, state)
	unnil_term(node.right, state)
}

unnil_minus :: proc(node: ^Minus, state: ^Unnil_State) {
	unnil_term(node.left, state)
	unnil_term(node.right, state)
}
