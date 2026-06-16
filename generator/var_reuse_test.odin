package generator

import "core:log"
import "core:testing"

@(test)
var_reuse_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)


	stmts := make([dynamic]Stmt)
	append(&stmts, Par{Variable{0}})
	append(&stmts, Par{Variable{1}})
	append(&stmts, Mov{Variable{3}, Number{1}})
	append(&stmts, Expr{Variable{4}, Add{{Variable{0}, Number{1}}}})

	var_reuse(&stmts)

	out := make([]string, len(stmts))

	for stmt, i in stmts {
		out[i] = stmt_to_string(stmt)
	}

	expected := []string {
		"(Par (Var 0))",
		"(Par (Var 1))",
		"(Mov (Var 1) (Num 1))",
		"(Expr (Var 0) (Add (Var 0) (Num 1)))",
	}

	testing.expect(t, len(expected) == len(out))

	for _, i in out {
		testing.expect(t, expected[i] == out[i])
	}
}

@(test)
var_reuse_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)
	append(&stmts, Label{"foo"})
	append(&stmts, Mov{Variable{1}, Number{2}})
	append(&stmts, Expr{Variable{3}, Call{"func", {Variable{1}}}})
	append(&stmts, Mov{Variable{4}, Number{3}})
	append(&stmts, Expr{Variable{5}, Call{"func", {Variable{4}}}})
	append(&stmts, Jmp{Label{"foo"}})

	var_reuse(&stmts)

	out := make([]string, len(stmts))


	for stmt, i in stmts {
		out[i] = stmt_to_string(stmt)
	}

	expected := []string {
		"(Label 'foo')",
		"(Mov (Var 1) (Num 2))",
		"(Expr (Var 3) (Call 'func' (Var 1)))",
		"(Mov (Var 4) (Num 3))",
		"(Expr (Var 5) (Call 'func' (Var 4)))",
		"(Jmp (Label 'foo'))",
	}

	for _, i in out {
		testing.expect(t, expected[i] == out[i])
	}
}

@(test)
var_reuse_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)
	append(&stmts, Par{Variable{0}})
	append(&stmts, Par{Variable{1}})
	append(&stmts, Expr{Variable{2}, Add{{Variable{1}, Number{0}}}})

	var_reuse(&stmts)

	out := make([]string, len(stmts))

	// TODO:

	// for stmt, i in stmts {
	// 	out[i] = stmt_to_string(stmt)
	// 	log.info(out[i])
	// }
}
