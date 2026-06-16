package parser

import "../lexer"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:unicode"

Token :: lexer.Token

variable_to_string :: proc(variable: ^Variable) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Variable '%v')", variable.literal)
	return strings.to_string(builder)
}

label_to_string :: proc(label: ^Label) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Label '%v')", label.literal)
	return strings.to_string(builder)
}

number_to_string :: proc(number: ^Number) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Number '%v')", number.literal)
	return strings.to_string(builder)
}

function_name_to_string :: proc(function_name: ^Function_Name) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(FunctionName '%v')", function_name.literal)
	return strings.to_string(builder)
}

sb_trim_right :: proc(builder: ^strings.Builder) {
	rune, width := strings.pop_rune(builder)

	if unicode.is_space(rune) {
		sb_trim_right(builder)
	} else {
		strings.write_rune(builder, rune)
	}
}

program_to_string :: proc(program: ^Program) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "(Program ")

	for f in program.functions {
		strings.write_string(&builder, function_to_string(f))
		strings.write_string(&builder, " ")
	}

	sb_trim_right(&builder)

	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_program :: proc(tokens: []Token) -> (^Program, []Token) {
	functions := make([dynamic]^Function)
	tokens := tokens

	for {
		function, new_tokens := parse_function(tokens)
		if function == nil {
			break
		}

		append(&functions, function)

		tokens = new_tokens

		if len(tokens) == 0 {
			return nil, nil
		}

		if tokens[0].kind != .SEMICOLON {
			return nil, nil
		}

		tokens = tokens[1:]
	}

	program := make_program(functions[:])
	return program, tokens
}

function_to_string :: proc(function: ^Function) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(
		&builder,
		"(Function %v %v %v)",
		function_name_to_string(function.name),
		parameter_to_string(function.parameter),
		stats_to_string(function.stats),
	)
	return strings.to_string(builder)
}

parse_function :: proc(tokens: []Token) -> (^Function, []Token) {
	tokens := tokens
	name: ^Function_Name

	name, tokens = parse_function_name(tokens)
	if name == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_OPEN {
		return nil, nil
	}

	tokens = tokens[1:]

	parameter: ^Parameter
	parameter, tokens = parse_parameter(tokens)

	if parameter == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_CLOSE {
		return nil, nil
	}

	tokens = tokens[1:]

	stats: ^Stats
	stats, tokens = parse_stats(tokens)

	if stats == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .END {
		return nil, nil
	}

	tokens = tokens[1:]

	function := make_function(name, parameter, stats)

	return function, tokens
}

parameter_to_string :: proc(parameter: ^Parameter) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "(Parameter ")

	for p in parameter.parameter {
		strings.write_string(&builder, variable_to_string(p))
		strings.write_string(&builder, " ")
	}

	sb_trim_right(&builder)
	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_parameter :: proc(tokens: []Token) -> (^Parameter, []Token) {
	parameters := make([dynamic]^Variable)
	tokens := tokens

	for {
		parameter, new_tokens := parse_variable(tokens)
		if parameter == nil {break}
		tokens = new_tokens

		append(&parameters, parameter)

		if len(tokens) > 0 && tokens[0].kind == .COMMA {
			tokens = tokens[1:]
		} else {
			break
		}
	}

	parameter := make_parameter(parameters[:])
	return parameter, tokens
}

stats_to_string :: proc(stats: ^Stats) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "(Stats ")

	for s in stats.stats {
		strings.write_string(&builder, stat_to_string(s))
		strings.write_string(&builder, " ")
	}
	sb_trim_right(&builder)
	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_stats :: proc(tokens: []Token) -> (^Stats, []Token) {
	tokens := tokens

	buf := make([dynamic]^Stat)

	for {
		stat, new_tokens := parse_stat(tokens)
		if stat == nil {
			break
		}
		tokens = new_tokens

		if len(tokens) == 0 {
			return nil, nil
		}

		if tokens[0].kind != .SEMICOLON {
			return nil, nil
		}

		tokens = tokens[1:]
		append(&buf, stat)
	}

	stats := make_stats(buf[:])

	return stats, tokens
}

parse_return :: proc(tokens: []Token) -> (^Return, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .RETURN {
		return nil, nil
	}

	tokens := tokens[1:]

	expr: ^Expr
	expr, tokens = parse_expr(tokens)

	if expr == nil {
		return nil, nil
	}

	return_ := make_return(expr)

	return return_, tokens
}

return_to_string :: proc(n: ^Return) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Return %v)", expr_to_string(n.expr))
	return strings.to_string(builder)
}

stat_to_string :: proc(stat: ^Stat) -> string {
	builder := strings.builder_make()

	inner: string
	switch s in stat {
	case ^Conds:
		inner = conds_to_string(s)
	case ^Variable_Definition:
		inner = variable_definition_to_string(s)
	case ^Variable_Assignment:
		inner = variable_assignment_to_string(s)
	case ^Term:
		inner = term_to_string(s)
	case ^Return:
		inner = return_to_string(s)
	}

	fmt.sbprintf(&builder, "(Stat %v)", inner)

	return strings.to_string(builder)
}

parse_stat :: proc(tokens: []Token) -> (^Stat, []Token) {

	new_tokens: []Token

	return_: ^Return
	return_, new_tokens = parse_return(tokens)
	if return_ != nil {
		return make_stat(return_), new_tokens
	}

	conds: ^Conds
	conds, new_tokens = parse_conds(tokens)
	if conds != nil {
		return make_stat(conds), new_tokens
	}

	variable_definition: ^Variable_Definition
	variable_definition, new_tokens = parse_variable_definition(tokens)
	if variable_definition != nil {
		return make_stat(variable_definition), new_tokens
	}

	variable_assignment: ^Variable_Assignment
	variable_assignment, new_tokens = parse_variable_assignment(tokens)
	if variable_assignment != nil {
		return make_stat(variable_assignment), new_tokens
	}

	term: ^Term
	term, new_tokens = parse_term(tokens)
	if term != nil {
		return make_stat(term), new_tokens
	}

	return nil, nil
}

variable_definition_to_string :: proc(variable_definition: ^Variable_Definition) -> string {
	varialbe := variable_to_string(variable_definition.variable)
	expr := expr_to_string(variable_definition.expr)

	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(VariableDefinition %v %v)", varialbe, expr)

	return strings.to_string(builder)
}

parse_variable_definition :: proc(tokens: []Token) -> (^Variable_Definition, []Token) {
	tokens := tokens

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .VAR {
		return nil, nil
	}

	tokens = tokens[1:]

	variable: ^Variable
	variable, tokens = parse_variable(tokens)

	if variable == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .WALRUSS {
		return nil, nil
	}

	tokens = tokens[1:]

	expr: ^Expr
	expr, tokens = parse_expr(tokens)

	if expr == nil {
		return nil, nil
	}

	node := make_variable_definition(variable, expr)

	return node, tokens
}

variable_assignment_to_string :: proc(v: ^Variable_Assignment) -> string {
	lexpr := lexpr_to_string(v.lexpr)
	expr := expr_to_string(v.expr)

	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(VariableAssignment %v %v)", lexpr, expr)

	return strings.to_string(builder)
}

parse_variable_assignment :: proc(tokens: []Token) -> (^Variable_Assignment, []Token) {
	tokens := tokens
	lexpr: ^L_Expr
	expr: ^Expr

	lexpr, tokens = parse_lexpr(tokens)
	if lexpr == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .WALRUSS {
		return nil, nil
	}

	tokens = tokens[1:]

	expr, tokens = parse_expr(tokens)
	if expr == nil {
		return nil, nil
	}

	node := make_variable_assignment(lexpr, expr)

	return node, tokens
}

lexpr_to_string :: proc(lexpr: ^L_Expr) -> string {
	inner: string

	switch x in lexpr {
	case ^Variable:
		inner = variable_to_string(x)
	case ^Array_Access:
		inner = array_access_to_string(x)
	}

	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(LExpr %v)", inner)

	return strings.to_string(builder)
}

parse_lexpr :: proc(tokens: []Token) -> (^L_Expr, []Token) {

	tokens := tokens
	new_tokens: []Token

	array_access: ^Array_Access
	array_access, new_tokens = parse_array_access(tokens)
	if array_access != nil {
		return make_lexpr(array_access), new_tokens
	}

	variable: ^Variable
	variable, new_tokens = parse_variable(tokens)
	if variable != nil {
		return make_lexpr(variable), new_tokens
	}

	return nil, nil
}

conds_to_string :: proc(conds: ^Conds) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "(Conds ")

	if conds.label != nil {
		strings.write_string(&builder, label_to_string(conds.label))
		strings.write_string(&builder, " ")
	}

	for g in conds.guarded {
		strings.write_string(&builder, guarded_to_string(g))
		strings.write_string(&builder, " ")
	}

	sb_trim_right(&builder)
	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}


parse_conds :: proc(tokens: []Token) -> (^Conds, []Token) {
	tokens := tokens
	label: ^Label
	new_tokens: []Token

	label, new_tokens = parse_label(tokens)
	if label != nil {
		tokens = new_tokens
		if len(tokens) == 0 {
			return nil, nil
		}
		if tokens[0].kind != .COLON {
			return nil, nil
		}
		tokens = tokens[1:]
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .COND {
		return nil, nil
	}

	tokens = tokens[1:]

	guarded_list := make([dynamic]^Guarded)

	for {
		guarded, new_tokens := parse_guarded(tokens)
		if guarded == nil {
			break
		}
		append(&guarded_list, guarded)
		tokens = new_tokens
		if len(tokens) == 0 {
			return nil, nil
		}
		if tokens[0].kind != .SEMICOLON {
			return nil, nil
		}
		tokens = tokens[1:]
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .END {
		return nil, nil
	}

	tokens = tokens[1:]

	node := make_conds(label, guarded_list[:])

	return node, tokens
}

guarded_to_string :: proc(guarded: ^Guarded) -> string {
	builder := strings.builder_make()

	strings.write_string(&builder, "(Guarded ")

	if guarded.expr != nil {
		strings.write_string(&builder, expr_to_string(guarded.expr))
		strings.write_string(&builder, " ")
	}

	strings.write_string(&builder, stats_to_string(guarded.stats))
	strings.write_string(&builder, " ")

	strings.write_string(&builder, continue_or_break_to_string(guarded.continue_or_break))
	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_guarded :: proc(tokens: []Token) -> (^Guarded, []Token) {
	tokens := tokens

	expr, new_tokens := parse_expr(tokens)

	if expr != nil {
		tokens = new_tokens
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .LEFT_ARROW {
		return nil, nil
	}

	tokens = tokens[1:]

	stats: ^Stats
	stats, tokens = parse_stats(tokens)
	if stats == nil {
		return nil, nil
	}

	continue_or_break: ^Continue_Or_Break
	continue_or_break, tokens = parse_continue_or_break(tokens)

	if continue_or_break == nil {
		return nil, nil
	}

	node := make_guarded(expr, stats, continue_or_break)

	return node, tokens
}

continue_or_break_to_string :: proc(n: ^Continue_Or_Break) -> string {
	inner: string

	switch m in n {
	case ^Continue:
		inner = continue_to_string(m)
	case ^Break:
		inner = break_to_string(m)
	}

	builder := strings.builder_make()

	fmt.sbprintf(&builder, "(ContinueOrBreak %v)", inner)

	return strings.to_string(builder)
}

parse_continue_or_break :: proc(tokens: []Token) -> (^Continue_Or_Break, []Token) {
	continue_: ^Continue
	break_: ^Break
	new_tokens: []Token

	continue_, new_tokens = parse_continue(tokens)
	if continue_ != nil {
		return make_continue_or_break(continue_), new_tokens
	}

	break_, new_tokens = parse_break(tokens)
	if break_ != nil {
		return make_continue_or_break(break_), new_tokens
	}

	return nil, nil
}

continue_to_string :: proc(n: ^Continue) -> string {
	label: string

	builder := strings.builder_make()
	strings.write_string(&builder, "(Continue")

	if n.label != nil {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, label_to_string(n.label))
	}
	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_continue :: proc(tokens: []Token) -> (^Continue, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .CONTINUE {
		return nil, nil
	}

	tokens := tokens[1:]

	label: ^Label = nil

	if len(tokens) > 0 && tokens[0].kind == .WORD {
		label = new(Label)
		label^ = Label {
			literal = tokens[0].literal_word,
		}
		tokens = tokens[1:]
	}

	node := make_continue(label)

	return node, tokens
}

break_to_string :: proc(n: ^Break) -> string {
	builder := strings.builder_make()

	strings.write_string(&builder, "(Break")

	if n.label != nil {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, label_to_string(n.label))
	}

	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_break :: proc(tokens: []Token) -> (^Break, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .BREAK {
		return nil, nil
	}

	tokens := tokens[1:]

	label: ^Label = nil

	if len(tokens) > 0 && tokens[0].kind == .WORD {
		label = new(Label)
		label^ = Label {
			literal = tokens[0].literal_word,
		}
		tokens = tokens[1:]
	}

	node := make_break(label)

	return node, tokens
}

expr_to_string :: proc(n: ^Expr) -> string {
	inner: string

	switch m in n {
	case ^Not_Term:
		inner = not_term_to_string(m)
	case ^Array_Access:
		inner = array_access_to_string(m)
	case ^Sum:
		inner = sum_to_string(m)
	case ^Product:
		inner = product_to_string(m)
	case ^Conjunction:
		inner = conjunction_to_string(m)
	case ^Greater:
		inner = greater_to_string(m)
	case ^Equal:
		inner = equal_to_string(m)
	case ^Minus:
		inner = minus_to_string(m)
	case ^Term:
		inner = term_to_string(m)
	}

	builder := strings.builder_make()

	fmt.sbprintf(&builder, "(Expr %v)", inner)

	return strings.to_string(builder)
}

parse_expr :: proc(tokens: []Token) -> (^Expr, []Token) {
	tokens := tokens
	new_tokens := tokens

	not_term: ^Not_Term
	not_term, new_tokens = parse_not_term(tokens)
	if not_term != nil {
		return make_expr(not_term), new_tokens
	}

	array_access: ^Array_Access
	array_access, new_tokens = parse_array_access(tokens)
	if array_access != nil {
		return make_expr(array_access), new_tokens
	}

	sum: ^Sum
	sum, new_tokens = parse_sum(tokens)
	if sum != nil {
		return make_expr(sum), new_tokens
	}

	product: ^Product
	product, new_tokens = parse_product(tokens)
	if product != nil {
		return make_expr(product), new_tokens
	}

	conjunction: ^Conjunction
	conjunction, new_tokens = parse_conjunction(tokens)
	if conjunction != nil {
		return make_expr(conjunction), new_tokens
	}

	greater: ^Greater
	greater, new_tokens = parse_greater(tokens)
	if greater != nil {
		return make_expr(greater), new_tokens
	}

	equal: ^Equal
	equal, new_tokens = parse_equal(tokens)
	if equal != nil {
		return make_expr(equal), new_tokens
	}

	minus: ^Minus
	minus, new_tokens = parse_minus(tokens)
	if minus != nil {
		return make_expr(minus), new_tokens
	}

	term: ^Term
	term, new_tokens = parse_term(tokens)
	if term != nil {
		return make_expr(term), new_tokens
	}

	return nil, nil
}

function_call_to_string :: proc(n: ^Function_Call) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(FunctionCall %v (", function_name_to_string(n.name))

	for a in n.arguments {
		strings.write_string(&builder, expr_to_string(a))
		strings.write_string(&builder, " ")
	}

	sb_trim_right(&builder)

	strings.write_string(&builder, "))")

	return strings.to_string(builder)
}

parse_function_call :: proc(tokens: []Token) -> (^Function_Call, []Token) {
	tokens := tokens
	function_name: ^Function_Name

	function_name, tokens = parse_function_name(tokens)

	if function_name == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_OPEN {
		return nil, nil
	}

	tokens = tokens[1:]

	arguments := make([dynamic]^Expr)
	expr: ^Expr

	// new_tokens variable is need because last parse_expr call in loop will
	// return butchered tokens, this way we only 'save' the updated tokens in
	// new_tokens into tokens when we know they are correct

	new_tokens := tokens
	expr, new_tokens = parse_expr(new_tokens)

	for expr != nil && len(new_tokens) > 0 && new_tokens[0].kind == .COMMA {
		new_tokens = new_tokens[1:]
		tokens = new_tokens
		append(&arguments, expr)
		expr, new_tokens = parse_expr(new_tokens)
	}

	if expr != nil {
		append(&arguments, expr)
		tokens = new_tokens
	}


	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_CLOSE {
		return nil, nil
	}

	tokens = tokens[1:]


	node := make_function_call(function_name, arguments[:])

	return node, tokens
}

term_to_string :: proc(n: ^Term) -> string {
	builder := strings.builder_make()
	inner: string

	switch m in n {
	case ^Number:
		inner = number_to_string(m)
	case ^Variable:
		inner = variable_to_string(m)
	case ^Expr:
		inner = expr_to_string(m)
	case ^Function_Call:
		inner = function_call_to_string(m)
	}

	fmt.sbprintf(&builder, "(Term %v)", inner)

	return strings.to_string(builder)
}

parse_term :: proc(tokens: []Token) -> (^Term, []Token) {
	tokens := tokens

	new_tokens: []Token

	function_call: ^Function_Call
	function_call, new_tokens = parse_function_call(tokens)
	if function_call != nil {
		return make_term(function_call), new_tokens
	}

	number: ^Number
	number, new_tokens = parse_number(tokens)
	if number != nil {
		return make_term(number), new_tokens
	}

	variable: ^Variable
	variable, new_tokens = parse_variable(tokens)
	if variable != nil {
		return make_term(variable), new_tokens
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_OPEN {
		return nil, nil
	}

	tokens = tokens[1:]

	expr: ^Expr

	expr, tokens = parse_expr(tokens)

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .PARENTHESES_CLOSE {
		return nil, nil
	}

	tokens = tokens[1:]

	return make_term(expr), tokens
}

not_list_to_string :: proc(n: ^Not_List) -> string {
	builder := strings.builder_make()

	fmt.sbprintf(&builder, "(NotList %v)", n.count)

	return strings.to_string(builder)
}

parse_not_list :: proc(tokens: []Token) -> (^Not_List, []Token) {
	count := 0
	tokens := tokens

	for ; len(tokens) > 0 && tokens[count].kind == .NOT; count += 1 {}

	tokens = tokens[count:]

	if count == 0 {
		return nil, nil
	}

	node := make_not_list(count)

	return node, tokens
}

not_term_to_string :: proc(n: ^Not_Term) -> string {
	term := term_to_string(n.term)
	not_list := not_list_to_string(n.not_list)

	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(NotTerm %v %v)", not_list, term)

	return strings.to_string(builder)
}

parse_not_term :: proc(tokens: []Token) -> (^Not_Term, []Token) {
	tokens := tokens
	not_list: ^Not_List
	term: ^Term

	not_list, tokens = parse_not_list(tokens)

	if not_list == nil {
		return nil, nil
	}

	term, tokens = parse_term(tokens)

	if term == nil {
		return nil, nil
	}

	node := make_not_term(not_list, term)

	return node, tokens
}

array_access_to_string :: proc(n: ^Array_Access) -> string {
	term := term_to_string(n.term)
	expr := expr_to_string(n.expr)

	builder := strings.builder_make()

	fmt.sbprintf(&builder, "(ArrayAccess %v %v)", term, expr)

	return strings.to_string(builder)
}

parse_array_access :: proc(tokens: []Token) -> (^Array_Access, []Token) {
	tokens := tokens
	term: ^Term
	expr: ^Expr

	term, tokens = parse_term(tokens)

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .BRACKET_OPEN {
		return nil, nil
	}

	tokens = tokens[1:]

	expr, tokens = parse_expr(tokens)

	if len(tokens) == 0 {
		return nil, nil
	}

	if tokens[0].kind != .BRACKET_CLOSE {
		return nil, nil
	}

	tokens = tokens[1:]

	node := make_array_access(term, expr)

	return node, tokens
}

sum_to_string :: proc(n: ^Sum) -> string {
	builder := strings.builder_make()

	strings.write_string(&builder, "(Sum")

	for t in n.terms {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, term_to_string(t))
	}

	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_sum :: proc(tokens: []Token) -> (^Sum, []Token) {
	terms := make([dynamic]^Term)

	count := 0


	term: ^Term
	tokens := tokens

	term, tokens = parse_term(tokens)

	if term == nil {
		return nil, nil
	}

	append(&terms, term)

	for len(tokens) > 0 && tokens[0].kind == .PLUS {
		count += 1
		tokens = tokens[1:]
		term, tokens = parse_term(tokens)
		if term == nil {
			return nil, nil
		}
		append(&terms, term)
	}

	if count == 0 {
		return nil, nil
	}

	return make_sum(terms[:]), tokens
}

product_to_string :: proc(n: ^Product) -> string {
	builder := strings.builder_make()
	strings.write_string(&builder, "(Product")

	for t in n.terms {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, term_to_string(t))
	}

	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_product :: proc(tokens: []Token) -> (^Product, []Token) {
	terms := make([dynamic]^Term)

	count := 0


	term: ^Term
	tokens := tokens

	term, tokens = parse_term(tokens)

	if term == nil {
		return nil, nil
	}

	append(&terms, term)

	for len(tokens) > 0 && tokens[0].kind == .STAR {
		count += 1
		tokens = tokens[1:]
		term, tokens = parse_term(tokens)
		if term == nil {
			return nil, nil
		}
		append(&terms, term)
	}

	if count == 0 {
		return nil, nil
	}

	return make_product(terms[:]), tokens
}

conjunction_to_string :: proc(n: ^Conjunction) -> string {
	builder := strings.builder_make()

	strings.write_string(&builder, "(Conjunction")

	for t in n.terms {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, term_to_string(t))
	}

	strings.write_string(&builder, ")")

	return strings.to_string(builder)
}

parse_conjunction :: proc(tokens: []Token) -> (^Conjunction, []Token) {
	terms := make([dynamic]^Term)

	count := 0


	term: ^Term
	tokens := tokens

	term, tokens = parse_term(tokens)

	if term == nil {
		return nil, nil
	}

	append(&terms, term)

	for len(tokens) > 0 && tokens[0].kind == .AND {
		count += 1
		tokens = tokens[1:]
		term, tokens = parse_term(tokens)
		if term == nil {
			return nil, nil
		}
		append(&terms, term)
	}

	if count == 0 {
		return nil, nil
	}

	return make_conjunction(terms[:]), tokens
}

greater_to_string :: proc(n: ^Greater) -> string {
	builder := strings.builder_make()

	left := term_to_string(n.left)
	right := term_to_string(n.right)

	fmt.sbprintf(&builder, "(Greater %v %v)", left, right)

	return strings.to_string(builder)
}

parse_greater :: proc(tokens: []Token) -> (^Greater, []Token) {
	tokens := tokens
	left: ^Term
	right: ^Term

	left, tokens = parse_term(tokens)

	if left == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	op := tokens[0]

	if op.kind != .GREATER {
		return nil, nil
	}

	tokens = tokens[1:]

	right, tokens = parse_term(tokens)

	if right == nil {
		return nil, nil
	}

	return make_greater(left, right), tokens
}

equal_to_string :: proc(n: ^Equal) -> string {
	builder := strings.builder_make()

	left := term_to_string(n.left)
	right := term_to_string(n.right)

	fmt.sbprintf(&builder, "(Equal %v %v)", left, right)

	return strings.to_string(builder)
}

parse_equal :: proc(tokens: []Token) -> (^Equal, []Token) {
	tokens := tokens
	left: ^Term
	right: ^Term

	left, tokens = parse_term(tokens)

	if left == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	op := tokens[0]

	if op.kind != .EQUAL {
		return nil, nil
	}

	tokens = tokens[1:]

	right, tokens = parse_term(tokens)

	if right == nil {
		return nil, nil
	}

	return make_equal(left, right), tokens
}

minus_to_string :: proc(n: ^Minus) -> string {
	builder := strings.builder_make()

	left := term_to_string(n.left)
	right := term_to_string(n.right)

	fmt.sbprintf(&builder, "(Minus %v %v)", left, right)

	return strings.to_string(builder)
}

parse_minus :: proc(tokens: []Token) -> (^Minus, []Token) {
	tokens := tokens
	left: ^Term
	right: ^Term

	left, tokens = parse_term(tokens)

	if left == nil {
		return nil, nil
	}

	if len(tokens) == 0 {
		return nil, nil
	}

	op := tokens[0]

	if op.kind != .MINUS {
		return nil, nil
	}

	tokens = tokens[1:]

	right, tokens = parse_term(tokens)

	if right == nil {
		return nil, nil
	}

	return make_minus(left, right), tokens
}

parse_variable :: proc(tokens: []Token) -> (^Variable, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}
	token := tokens[0]

	if token.kind != .WORD {
		return nil, nil
	}

	return make_variable(token.literal_word), tokens[1:]
}

parse_label :: proc(tokens: []Token) -> (^Label, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	token := tokens[0]

	if token.kind != .WORD {
		return nil, nil
	}

	return make_label(token.literal_word), tokens[1:]
}

parse_number :: proc(tokens: []Token) -> (^Number, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	token := tokens[0]

	if token.kind != .NUMBER {
		return nil, nil
	}

	return make_number(token.literal_number), tokens[1:]
}

parse_function_name :: proc(tokens: []Token) -> (^Function_Name, []Token) {
	if len(tokens) == 0 {
		return nil, nil
	}

	token := tokens[0]

	if token.kind != .WORD {
		return nil, nil
	}

	return make_function_name(token.literal_word), tokens[1:]
}

main :: proc() {
	input := make([dynamic]u8, 16, 16)
	buf, err := lexer.read_input(&input)
	if err != nil {
		fmt.eprintln("could not read input")
		os.exit(1)
	}

	tokens: [dynamic]Token
	tokens, err = lexer.lexer(buf)
	defer delete(tokens)

	if err != nil {
		fmt.eprintln("could not lex input")
		os.exit(1)
	}

	fmt.println("Hello World")
}
