package generator

import "core:testing"

nil_unused_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	stmts := make([dynamic]Stmt)

	append(&stmts, Mov{dest = Variable{1}, src = Number{2}})
	append(&stmts, Expr{out = Variable{2}, expr = Add{Number{1}, Number{1}}})
	append(&stmts, Expr{out = Variable{3}, expr = Call{"foo", {Variable{2}}}})
	append(&stmts, Label{"foo"})
	append(&stmts, Label{"bar"})
	append(&stmts, Jmp{Label{"bar"}})

	has_changed := false

	nil_unused(&stmts, &has_changed)
	testing.expect(t, has_changed)

	out := make([]string, len(stmts))
	for _, i in out {
		out[i] = stmt_to_string(stmts[i])
	}

	expected := []string {
		"(Nil)",
		"(Expr (Var 2) (Add (Num 1) (Num 1)))",
		"(Expr (Var 3) (Call 'foo' (Var 2))",
		"(Nil)",
		"(Label 'bar')",
		"(Jmp (Label 'bar'))",
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
