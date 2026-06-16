package generator

import "core:fmt"
import "core:strings"
Number :: struct {
	inner: u64,
}

number_to_string :: proc(n: Number) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Num %v)", n.inner)
	return strings.to_string(builder)
}

Variable :: struct {
	inner: u64,
}

variable_to_string :: proc(n: Variable) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Var %v)", n.inner)
	return strings.to_string(builder)
}

Label :: struct {
	inner: string,
}

label_to_string :: proc(n: Label) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Label '%v')", n.inner)
	return strings.to_string(builder)
}

number_make :: proc(inner: u64) -> Number {
	return Number{inner}
}

variable_make :: proc(inner: u64) -> Variable {
	return Variable{inner}
}

Operand :: union {
	Variable,
	Number,
}

operand_is_variable :: proc(n: Operand) -> bool {
	switch n in n {
	case Variable:
		return true
	case Number:
		return false
	}
	unreachable()
}

operand_is_number :: proc(n: Operand) -> bool {
	switch n in n {
	case Variable:
		return false
	case Number:
		return true
	}

	unreachable()
}

operand_to_string :: proc(n: Operand) -> string {
	switch n in n {
	case Variable:
		return variable_to_string(n)
	case Number:
		return number_to_string(n)
	}
	unreachable()
}

Add :: struct {
	left:  Operand,
	right: Operand,
}

add_to_string :: proc(n: Add) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(Add %v %v)", left, right)
	return strings.to_string(builder)
}

Not :: struct {
	operand: Operand,
}

not_to_string :: proc(n: Not) -> string {
	builder := strings.builder_make()
	operand := operand_to_string(n.operand)
	fmt.sbprintf(&builder, "(Not %v)", operand)
	return strings.to_string(builder)
}

Mul :: struct {
	left:  Operand,
	right: Operand,
}

Par :: struct {
	var: Variable,
}

par_to_string :: proc(n: Par) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Par %v)", variable_to_string(n.var))
	return strings.to_string(builder)
}

mul_to_string :: proc(n: Mul) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(Mul %v %v)", left, right)
	return strings.to_string(builder)
}

And :: struct {
	left:  Operand,
	right: Operand,
}

and_to_string :: proc(n: And) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(And %v %v)", left, right)
	return strings.to_string(builder)
}

Gt :: struct {
	left:  Operand,
	right: Operand,
}

gt_to_string :: proc(n: Gt) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(Gt %v %v)", left, right)
	return strings.to_string(builder)
}

Eq :: struct {
	left:  Operand,
	right: Operand,
}

eq_to_string :: proc(n: Eq) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(Eq %v %v)", left, right)
	return strings.to_string(builder)
}

Sub :: struct {
	left:  Operand,
	right: Operand,
}

sub_to_string :: proc(n: Sub) -> string {
	builder := strings.builder_make()
	left := operand_to_string(n.left)
	right := operand_to_string(n.right)
	fmt.sbprintf(&builder, "(Sub %v %v)", left, right)
	return strings.to_string(builder)
}

Call :: struct {
	name:      string,
	arguments: []Operand,
}

call_to_string :: proc(n: Call) -> string {
	builder := strings.builder_make()

	strings.write_string(&builder, "(Call '")
	strings.write_string(&builder, n.name)
	strings.write_string(&builder, "'")


	for a in n.arguments {
		strings.write_string(&builder, " ")
		strings.write_string(&builder, operand_to_string(a))
	}

	strings.write_string(&builder, ")")
	return strings.to_string(builder)
}

Read :: struct {
	base:   Operand,
	offset: Operand,
}

read_to_string :: proc(n: Read) -> string {
	builder := strings.builder_make()

	offset := operand_to_string(n.offset)
	base := operand_to_string(n.base)

	fmt.sbprintf(&builder, "(Read %v %v)", base, offset)

	return strings.to_string(builder)
}

Write :: struct {
	base:   Operand,
	offset: Operand,
	value:  Operand,
}

write_to_string :: proc(n: Write) -> string {
	builder := strings.builder_make()

	offset := operand_to_string(n.offset)
	base := operand_to_string(n.base)
	value := operand_to_string(n.value)

	fmt.sbprintf(&builder, "(Write %v %v %v)", base, offset, value)

	return strings.to_string(builder)
}

Expr :: struct {
	out:  Variable,
	expr: union {
		Add,
		And,
		Sub,
		Mul,
		Eq,
		Gt,
		Not,
		Read,
		Call,
	},
}

expr_to_string :: proc(n: Expr) -> string {
	inner: string
	switch expr in n.expr {
	case Add:
		inner = add_to_string(expr)
	case And:
		inner = and_to_string(expr)
	case Sub:
		inner = sub_to_string(expr)
	case Mul:
		inner = mul_to_string(expr)
	case Eq:
		inner = eq_to_string(expr)
	case Gt:
		inner = gt_to_string(expr)
	case Not:
		inner = not_to_string(expr)
	case Read:
		inner = read_to_string(expr)
	case Call:
		inner = call_to_string(expr)
	}

	out := variable_to_string(n.out)

	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Expr %v %v)", out, inner)

	return strings.to_string(builder)
}

Return :: struct {
	operand: Operand,
}

return_to_string :: proc(n: Return) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Return %v)", operand_to_string(n.operand))
	return strings.to_string(builder)
}

Jmp :: struct {
	label: Label,
}

jmp_to_string :: proc(n: Jmp) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Jmp %v)", label_to_string(n.label))
	return strings.to_string(builder)
}

CJmp :: struct {
	on:    Operand,
	label: Label,
}

cjmp_to_string :: proc(n: CJmp) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(CJmp %v %v)", operand_to_string(n.on), label_to_string(n.label))
	return strings.to_string(builder)
}

Mov :: struct {
	dest: Variable,
	src:  Operand,
}

mov_to_string :: proc(n: Mov) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "(Mov %v %v)", operand_to_string(n.dest), operand_to_string(n.src))
	return strings.to_string(builder)
}

Stmt :: union {
	Label,
	Write,
	Expr,
	Jmp,
	CJmp,
	Return,
	Mov,
	Par,
}

stmt_to_string :: proc(n: Stmt) -> string {
	if n == nil {
		return "(Nil)"
	}
	switch n in n {
	case Par:
		return par_to_string(n)
	case Label:
		return label_to_string(n)
	case Write:
		return write_to_string(n)
	case Expr:
		return expr_to_string(n)
	case Jmp:
		return jmp_to_string(n)
	case CJmp:
		return cjmp_to_string(n)
	case Return:
		return return_to_string(n)
	case Mov:
		return mov_to_string(n)
	}

	unreachable()
}

stmt_is_par :: proc(stmt: Stmt) -> bool {
	switch _ in stmt {
	case Label:
	case Write:
	case Expr:
	case Jmp:
	case CJmp:
	case Return:
	case Mov:
	case Par:
		return true
	}
	return false
}

Function :: struct {
	name:  string,
	stmts: [dynamic]Stmt,
}

Program :: struct {
	functions: []Function,
}

stmt_is_expr :: proc(stmt: Stmt) -> bool {
	switch _ in stmt {
	case Par:
	case Label:
	case Write:
	case Expr:
		return true
	case Jmp:
	case CJmp:
	case Return:
	case Mov:
	}
	return false
}

expr_is_add :: proc(expr: Expr) -> bool {
	switch _ in expr.expr {
	case Add:
		return true
	case And:
	case Sub:
	case Mul:
	case Eq:
	case Gt:
	case Not:
	case Read:
	case Call:
	}
	return false
}

stmt_is_label :: proc(stmt: Stmt) -> bool {
	switch _ in stmt {
	case Label:
		return true
	case Write:
	case Expr:
	case Jmp:
	case CJmp:
	case Return:
	case Mov:
	case Par:

	}
	return false
}
