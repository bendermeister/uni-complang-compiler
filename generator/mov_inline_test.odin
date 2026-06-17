package generator

import "core:testing"

@(test)
mov_inline_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)

	var := Variable{0}
	num := Number{69}

	append(&stmts, Mov{dest = var, src = num})
	append(&stmts, Write{base = var, offset = var, value = var})
	append(&stmts, Expr{out = Variable{1}, expr = Add{{var, var}}})
	append(&stmts, Expr{out = Variable{1}, expr = And{{var, var}}})
	append(&stmts, Expr{out = Variable{1}, expr = Sub{var, var}})
	append(&stmts, Expr{out = Variable{1}, expr = Mul{{var, var}}})
	append(&stmts, Expr{out = Variable{1}, expr = Eq{var, var}})
	append(&stmts, Expr{out = Variable{1}, expr = Gt{var, var}})
	append(&stmts, Expr{out = Variable{1}, expr = Not{var}})
	append(&stmts, Expr{out = Variable{1}, expr = Read{var, var}})
	append(&stmts, Expr{out = Variable{1}, expr = Call{name = "foo", arguments = {var, var}}})
	append(&stmts, CJmp{on = var})
	append(&stmts, Return{operand = var})

	has_changed := false
	mov_inline(&stmts, &has_changed)

	testing.expect(t, has_changed)

	out := make([]string, len(stmts))
	for stmt, i in stmts {
		out[i] = stmt_to_string(stmt)
	}


	expected := []string {
		"(Mov (Var 0) (Num 69))",
		"(Write (Num 69) (Num 69) (Num 69))",
		"(Expr (Var 1) (Add (Num 69) (Num 69)))",
		"(Expr (Var 1) (And (Num 69) (Num 69)))",
		"(Expr (Var 1) (Sub (Num 69) (Num 69)))",
		"(Expr (Var 1) (Mul (Num 69) (Num 69)))",
		"(Expr (Var 1) (Eq (Num 69) (Num 69)))",
		"(Expr (Var 1) (Gt (Num 69) (Num 69)))",
		"(Expr (Var 1) (Not (Num 69)))",
		"(Expr (Var 1) (Read (Num 69) (Num 69)))",
		"(Expr (Var 1) (Call 'foo' (Num 69) (Num 69)))",
		"(CJmp (Num 69) (Label ''))",
		"(Return (Num 69))",
	}

	testing.expect(t, len(expected) == len(out))

	for _, i in expected {
		testing.expectf(
			t,
			expected[i] == out[i],
			"i: %v, out: %v, expected: %v",
			i,
			out[i],
			expected[i],
		)
	}
}
