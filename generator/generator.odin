package generator

import "core:fmt"
import "core:strings"

// function call:
// rdi, rsi, rdx, rcx, r8, r9, ...stack
// return: rax


Register :: enum {
	RAX,
	RBX,
	RCX,
	RDX,
	RSP,
	RSI,
	RDI,
	R8,
	R9,
	R10,
	R11,
	R12,
	R13,
	R14,
	R15,
}


reg_to_string :: proc(r: Register) -> string {
	switch r {
	case .RAX:
		return "%rax"
	case .RBX:
		return "%rbx"
	case .RCX:
		return "%rcx"
	case .RDX:
		return "%rdx"
	case .RSP:
		return "%rsp"
	case .RSI:
		return "%rsi"
	case .RDI:
		return "%rdi"
	case .R8:
		return "%r8"
	case .R9:
		return "%r9"
	case .R10:
		return "%r10"
	case .R11:
		return "%r11"
	case .R12:
		return "%r12"
	case .R13:
		return "%r13"
	case .R14:
		return "%r14"
	case .R15:
		return "%r15"
	}
	unreachable()
}

address_to_string :: proc(a: Address, r: Register) -> string {
	builder := strings.builder_make()
	fmt.sbprintf(&builder, "%v(%v)", a.offset * 8, reg_to_string(r))
	return strings.to_string(builder)
}

Address :: struct {
	offset: u64,
}

Location :: union {
	Address,
	Register,
}

loc_to_string :: proc(l: Location) -> string {
	switch l in l {
	case Address:
		return address_to_string(l, .RSP)
	case Register:
		return reg_to_string(l)
	}
	unreachable()
}

// addrop_to_string :: proc(o: Operand, var_map: ^map[Variable]Location) -> string {
// 	switch o in o {
// 	case Variable:
// 		return loc_to_string(var_map[o])
// 	case Number:
// 		builder := strings.builder_make()
// 		fmt.sbprintf(&builder, "%v", o.inner)
// 		return strings.to_string(builder)
// 	}
// 	unreachable()
// }

op_to_string :: proc(o: Operand, var_map: ^map[Variable]Location) -> string {
	switch o in o {
	case Variable:
		return loc_to_string(var_map[o])
	case Number:
		builder := strings.builder_make()
		fmt.sbprintf(&builder, "$%v", o.inner)
		return strings.to_string(builder)
	}
	unreachable()
}

function_generate :: proc(function: Function) -> string {
	builder := strings.builder_make()

	vars := get_all_vars(function.stmts[:])
	defer delete(vars)

	var_hist := make(map[Variable]int)
	defer delete(var_hist)

	op_hist := make(map[Operand]int)
	defer delete(op_hist)

	for var in vars {
		op_hist[var] = 0
	}

	for stmt in function.stmts {
		switch stmt in stmt {
		case Label:
		case Write:
			op_hist[stmt.base] += 1
			op_hist[stmt.offset] += 1
			op_hist[stmt.value] += 1
		case Expr:
			switch expr in stmt.expr {
			case Add:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case And:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case Sub:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case Mul:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case Eq:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case Gt:
				op_hist[expr.left] += 1
				op_hist[expr.right] += 1
			case Not:
				op_hist[expr.operand] += 1
			case Read:
				op_hist[expr.offset] += 1
				op_hist[expr.base] += 1
			case Call:
				for a in expr.arguments {
					op_hist[a] += 1
				}
			}
		case Jmp:
		case CJmp:
			op_hist[stmt.on] += 1
		case Return:
			op_hist[stmt.operand] += 1
		case Mov:
			op_hist[stmt.src] += 1
		case Par:
		}
	}

	for k, v in op_hist {
		if operand_is_number(k) {continue}
		var_hist[k.(Variable)] = v
	}

	pop_max :: proc(var_hist: ^map[Variable]int) -> (Variable, bool) {
		m := 0
		var: Variable
		ok := false
		for k, v in var_hist {
			if v > m {
				m = v
				var = k
				ok = true
			}
		}
		if ok {
			delete_key(var_hist, var)
		}
		return var, ok
	}

	parameter := make([dynamic]Variable)
	defer delete(parameter)

	for stmt in function.stmts {
		if !stmt_is_par(stmt) {continue}
		par := stmt.(Par)
		append(&parameter, par.var)
	}

	free_registers := []Register{.RBX, .R10, .R11, .R12, .R13, .R14, .R15}

	offset: u64 = 0

	assert(len(parameter) <= 6)


	var_map := make(map[Variable]Location)
	defer delete(var_map)

	callee_saved := make([dynamic]Register)
	caller_saved := make([dynamic]Register)
	defer delete(callee_saved)

	var: Variable
	ok: bool

	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .RBX
		append(&callee_saved, Register.RBX)
	}


	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R12
		append(&callee_saved, Register.R12)
	}


	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R13
		append(&callee_saved, Register.R13)
	}

	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R14
		append(&callee_saved, Register.R14)
	}

	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R15
		append(&callee_saved, Register.R15)
	}

	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R10
		append(&caller_saved, Register.R10)
	}

	var, ok = pop_max(&var_hist)
	if ok {
		var_map[var] = .R11
		append(&caller_saved, Register.R11)
	}

	var, ok = pop_max(&var_hist)

	for ok {
		var_map[var] = Address{offset}
		offset += 1
		var, ok = pop_max(&var_hist)
	}

	fmt.sbprintf(&builder, ".global %v\n", function.name)
	fmt.sbprintf(&builder, "%v:\n", function.name)

	for r in callee_saved {
		fmt.sbprintf(&builder, "\tpush %v\n", reg_to_string(r))
	}

	fmt.sbprintf(&builder, "\tsubq $%v, %%rsp\n", offset * 8)

	par_reg := []Register{.RDI, .RSI, .RDX, .RCX, .R8, .R9}

	for p, i in parameter {
		loc, ok := var_map[p]
		if !ok {continue}
		fmt.sbprintf(&builder, "\tmovq %v, %v\n", reg_to_string(par_reg[i]), loc_to_string(loc))
	}

	for stmt in function.stmts {
		switch stmt in stmt {
		case Label:
			fmt.sbprintf(&builder, "\t%v:\n", stmt.inner)
		case Write:
			fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(stmt.base, &var_map))
			fmt.sbprintf(&builder, "\tmovq %v, %%rsi\n", op_to_string(stmt.offset, &var_map))
			fmt.sbprintf(&builder, "\tmovq %v, %%rdi\n", op_to_string(stmt.value, &var_map))
			fmt.sbprintf(&builder, "\tmovq %%rdi, (%%rax, %%rsi, 8)\n")
		case Expr:
			switch expr in stmt.expr {
			case Add:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\taddq %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case And:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\tandq %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Sub:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\tsubq %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Mul:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\timul %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Eq:
				fmt.sbprintf(&builder, "\txorq %%rax, %%rax\n")
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\tcmpq %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tsete %%al\n")
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Gt:
				fmt.sbprintf(&builder, "\txorq %%rax, %%rax\n")
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.left, &var_map))
				fmt.sbprintf(&builder, "\tcmpq %v, %%rax\n", op_to_string(expr.right, &var_map))
				fmt.sbprintf(&builder, "\tsetle %%al\n")
				fmt.sbprintf(&builder, "\txorq $1, %%rax\n")
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Not:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.operand, &var_map))
				fmt.sbprintf(&builder, "\txorq $1, %%rax\n")
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Read:
				fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(expr.base, &var_map))
				fmt.sbprintf(&builder, "\tmovq %v, %%rsi\n", op_to_string(expr.offset, &var_map))
				fmt.sbprintf(&builder, "\tmovq (%%rax, %%rsi, 8), %%rax\n")
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			case Call:
				for v, i in expr.arguments {
					fmt.sbprintf(
						&builder,
						"\tmovq %v, %v\n",
						op_to_string(v, &var_map),
						reg_to_string(par_reg[i]),
					)
				}
				for r in caller_saved {
					fmt.sbprintf(&builder, "\tpushq %v\n", reg_to_string(r))
				}
				fmt.sbprintf(&builder, "\tcall %v\n", expr.name)
				#reverse for r in caller_saved {
					fmt.sbprintf(&builder, "\tpopq %v\n", reg_to_string(r))
				}
				fmt.sbprintf(&builder, "\tmovq %%rax, %v\n", loc_to_string(var_map[stmt.out]))
			}
		case Jmp:
			fmt.sbprintf(&builder, "\tjmp %v\n", stmt.label.inner)
		case CJmp:
			fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(stmt.on, &var_map))
			fmt.sbprintf(&builder, "\tandq $1, %%rax\n")
			fmt.sbprintf(&builder, "\ttestq %%rax, %%rax\n")
			fmt.sbprintf(&builder, "\tjz %v\n", stmt.label.inner)
		case Return:
			fmt.sbprintf(&builder, "\tmovq %v, %%rax\n", op_to_string(stmt.operand, &var_map))
			fmt.sbprintf(&builder, "\taddq $%v, %%rsp\n", offset * 8)
			#reverse for r in callee_saved {
				fmt.sbprintf(&builder, "\tpopq %v\n", reg_to_string(r))
			}
			fmt.sbprintf(&builder, "\tret\n")
		case Mov:
			fmt.sbprintf(
				&builder,
				"\tmovq %v, %v\n",
				op_to_string(stmt.src, &var_map),
				loc_to_string(var_map[stmt.dest]),
			)
		case Par:
		}
	}

	return strings.to_string(builder)
}
