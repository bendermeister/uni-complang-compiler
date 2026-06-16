package parser

/* Program: { Funcdef ’;’ }
;

Funcdef: id ’(’ Pars ’)’ Stats end  /* Funktionsdefinition */ -- Function
;

Pars: { id ’,’ } [ id ]     /* Parameterdefinition */ -- Parameter
;

Stats: { Stat ’;’ }
;

Stat: return Expr
| Conds                                         -- struct Conds
| var id ’:=’ Expr /* Variablendefinition */    -- struct Variable_Definition
| Lexpr ’:=’ Expr  /* Zuweisung */              -- struct Variable_Assignment
| Term                                          -- union Term
;

Conds: [ id ’:’ ] /* Labeldefinition */
cond { Guarded ’;’ } end
;

Guarded:                                            -- struct Guarded
[ Expr ] ’->’ Stats   
( continue | break ) [ id ] /* Labelverwendung */
;

Lexpr:                                              -- union L_Expr
id        /* schreibender Variablenzugriff */       -- Variable
| Term ’[’ Expr ’]’ /* schreibender Arrayzugriff */ -- ArrayAccess
;

Expr:                                               -- union Expr
{ not } Term                                        -- { not } struct NotList, { not } Term NotTerm
| Term ’[’ Expr ’]’   /* lesender Arrayzugriff */   -- struct ArrayAccess
| Term { ’+’ Term }                                 -- struct Sum
| Term { ’*’ Term }                                 -- struct Product
| Term { and Term }                                 -- struct Conjunction
| Term '>' Term                                     -- struct Greater
| Term '=' Term                                     -- struct Equal
| Term '-' Term                                     -- struct Minus
| Term                                              -- struct Term
;


Term:                                                           -- union Term
’(’ Expr ’)’                                                    -- union Expr
| num                                                           -- struct Number
| id                               /* Variablenverwendung */    -- struct Variable
| id ’(’ { Expr ’,’ } [ Expr ] ’)’ /* Funktionsaufruf */        -- struct Function_Call
;

*/

Variable :: struct {
	literal: string,
}

make_variable :: proc(literal: string) -> ^Variable {
	n := new(Variable)
	n^ = Variable {
		literal = literal,
	}
	return n
}

Label :: struct {
	literal: string,
}

make_label :: proc(literal: string) -> ^Label {
	n := new(Label)
	n^ = Label {
		literal = literal,
	}
	return n
}

Number :: struct {
	literal: u64,
}

make_number :: proc(literal: u64) -> ^Number {
	n := new(Number)
	n^ = Number {
		literal = literal,
	}
	return n
}

Function_Name :: struct {
	literal: string,
}

make_function_name :: proc(literal: string) -> ^Function_Name {
	n := new(Function_Name)
	n^ = Function_Name {
		literal = literal,
	}
	return n
}

Program :: struct {
	functions: []^Function,
}

make_program :: proc(functions: []^Function) -> ^Program {
	n := new(Program)
	n^ = Program {
		functions = functions,
	}
	return n
}


Function :: struct {
	name:      ^Function_Name,
	parameter: ^Parameter,
	stats:     ^Stats,
}

make_function :: proc(name: ^Function_Name, parameter: ^Parameter, stats: ^Stats) -> ^Function {
	n := new(Function)
	n^ = Function {
		name      = name,
		parameter = parameter,
		stats     = stats,
	}
	return n
}

Parameter :: struct {
	parameter: []^Variable,
}

make_parameter :: proc(parameter: []^Variable) -> ^Parameter {
	n := new(Parameter)
	n^ = Parameter {
		parameter = parameter,
	}
	return n
}

Stats :: struct {
	stats: []^Stat,
}

make_stats :: proc(stats: []^Stat) -> ^Stats {
	n := new(Stats)
	n^ = Stats {
		stats = stats,
	}
	return n
}


Return :: struct {
	expr: ^Expr,
}

make_return :: proc(expr: ^Expr) -> ^Return {
	n := new(Return)
	n^ = Return {
		expr = expr,
	}

	return n
}

Stat :: union {
	^Return,
	^Conds,
	^Variable_Definition,
	^Variable_Assignment,
	^Term,
}

make_stat :: proc(inner: $T) -> ^Stat {
	n := new(Stat)
	n^ = inner
	return n
}

Variable_Definition :: struct {
	variable: ^Variable,
	expr:     ^Expr,
}

make_variable_definition :: proc(varialbe: ^Variable, expr: ^Expr) -> ^Variable_Definition {
	n := new(Variable_Definition)
	n^ = Variable_Definition {
		variable = varialbe,
		expr     = expr,
	}
	return n
}

Variable_Assignment :: struct {
	lexpr: ^L_Expr,
	expr:  ^Expr,
}

make_variable_assignment :: proc(lexpr: ^L_Expr, expr: ^Expr) -> ^Variable_Assignment {
	n := new(Variable_Assignment)
	n^ = Variable_Assignment {
		lexpr = lexpr,
		expr  = expr,
	}
	return n
}

L_Expr :: union {
	^Variable,
	^Array_Access,
}

make_lexpr :: proc(inner: $T) -> ^L_Expr {
	n := new(L_Expr)
	n^ = inner
	return n
}

Conds :: struct {
	label:     ^Label,
	guarded:   []^Guarded,
	end_label: ^Label,
}

make_conds :: proc(label: ^Label, guarded: []^Guarded) -> ^Conds {
	n := new(Conds)
	n^ = Conds {
		label   = label,
		guarded = guarded,
	}
	return n
}

Guarded :: struct {
	end_label:         ^Label,
	expr:              ^Expr,
	stats:             ^Stats,
	continue_or_break: ^Continue_Or_Break,
}

make_guarded :: proc(
	expr: ^Expr,
	stats: ^Stats,
	continue_or_break: ^Continue_Or_Break,
) -> ^Guarded {
	n := new(Guarded)
	n^ = Guarded {
		expr              = expr,
		stats             = stats,
		continue_or_break = continue_or_break,
	}
	return n
}

Continue_Or_Break :: union {
	^Continue,
	^Break,
}

make_continue_or_break :: proc(inner: $T) -> ^Continue_Or_Break {
	n := new(Continue_Or_Break)
	n^ = inner
	return n
}

Continue :: struct {
	label: ^Label,
}

make_continue :: proc(label: ^Label) -> ^Continue {
	n := new(Continue)
	n^ = Continue {
		label = label,
	}
	return n
}

Break :: struct {
	label: ^Label,
}

make_break :: proc(label: ^Label) -> ^Break {
	n := new(Break)
	n^ = Break {
		label = label,
	}
	return n
}

Expr :: union {
	^Not_Term,
	^Array_Access,
	^Sum,
	^Product,
	^Conjunction,
	^Greater,
	^Equal,
	^Minus,
	^Term,
}

make_expr :: proc(inner: $T) -> ^Expr {
	n := new(Expr)
	n^ = inner
	return n
}

Function_Call :: struct {
	name:      ^Function_Name,
	arguments: []^Expr,
}

make_function_call :: proc(name: ^Function_Name, arguments: []^Expr) -> ^Function_Call {
	n := new(Function_Call)
	n^ = Function_Call {
		name      = name,
		arguments = arguments,
	}
	return n
}

Term :: union {
	^Number,
	^Variable,
	^Expr,
	^Function_Call,
}

make_term :: proc(inner: $T) -> ^Term {
	n := new(Term)
	n^ = inner
	return n
}

Not_List :: struct {
	count: int,
}

make_not_list :: proc(count: int) -> ^Not_List {
	n := new(Not_List)
	n^ = Not_List {
		count = count,
	}
	return n
}


Not_Term :: struct {
	not_list: ^Not_List,
	term:     ^Term,
}

make_not_term :: proc(not_list: ^Not_List, term: ^Term) -> ^Not_Term {
	n := new(Not_Term)

	n^ = Not_Term {
		not_list = not_list,
		term     = term,
	}

	return n
}

Array_Access :: struct {
	term: ^Term,
	expr: ^Expr,
}

make_array_access :: proc(term: ^Term, expr: ^Expr) -> ^Array_Access {
	n := new(Array_Access)
	n^ = Array_Access {
		term = term,
		expr = expr,
	}
	return n
}

Sum :: struct {
	terms: []^Term,
}

make_sum :: proc(terms: []^Term) -> ^Sum {
	n := new(Sum)
	n^ = Sum {
		terms = terms,
	}
	return n
}

Product :: struct {
	terms: []^Term,
}

make_product :: proc(terms: []^Term) -> ^Product {
	n := new(Product)
	n^ = Product {
		terms = terms,
	}
	return n
}

Conjunction :: struct {
	terms: []^Term,
}

make_conjunction :: proc(terms: []^Term) -> ^Conjunction {
	n := new(Conjunction)
	n^ = Conjunction {
		terms = terms,
	}
	return n
}


Greater :: struct {
	left:  ^Term,
	right: ^Term,
}

make_greater :: proc(left: ^Term, right: ^Term) -> ^Greater {
	n := new(Greater)
	n^ = Greater {
		left  = left,
		right = right,
	}
	return n
}

Equal :: struct {
	left:  ^Term,
	right: ^Term,
}

make_equal :: proc(left: ^Term, right: ^Term) -> ^Equal {
	n := new(Equal)
	n^ = Equal {
		left  = left,
		right = right,
	}
	return n
}

Minus :: struct {
	left:  ^Term,
	right: ^Term,
}

make_minus :: proc(left: ^Term, right: ^Term) -> ^Minus {
	n := new(Minus)
	n^ = Minus {
		left  = left,
		right = right,
	}
	return n
}
