package generator

import "core:testing"
@(test)
expr_inline_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)
	append(&stmts, Label{"label"})
	append(&stmts, Write{base = Variable{1}, offset = Number{2}, value = Number{3}})
	append(&stmts, Expr{out = Variable{1}, expr = Add{Number{34}, Number{35}}})
	append(&stmts, Expr{out = Variable{1}, expr = Sub{Number{35}, Number{34}}})
	append(&stmts, Expr{out = Variable{1}, expr = Mul{Number{3}, Number{4}}})
	append(&stmts, Expr{out = Variable{1}, expr = And{Number{1}, Number{0}}})
	append(&stmts, Expr{out = Variable{1}, expr = Eq{Number{34}, Number{35}}})
	append(&stmts, Expr{out = Variable{1}, expr = Gt{Number{34}, Number{35}}})
	append(&stmts, Expr{out = Variable{1}, expr = Not{Number{1}}})
	append(&stmts, Expr{out = Variable{1}, expr = Not{Number{0}}})
	append(&stmts, Expr{out = Variable{1}, expr = Read{base = Variable{1}, offset = Number{2}}})
	append(&stmts, Expr{out = Variable{1}, expr = Call{name = "foo", arguments = {}}})
	append(&stmts, CJmp{on = Number{0}, label = Label{"label"}})
	append(&stmts, CJmp{on = Number{1}, label = Label{"label"}})

	has_changed := false
	expr_inline(&stmts, &has_changed)
	testing.expect(t, has_changed)
	has_changed = false
	expr_inline(&stmts, &has_changed)
	testing.expect(t, !has_changed)

	out := make([]string, len(stmts))
	for stmt, i in stmts {
		out[i] = stmt_to_string(stmt)
	}

	expected := []string {
		"(Label 'label')",
		"(Write (Var 1) (Num 2) (Num 3))",
		"(Mov (Var 1) (Num 69))",
		"(Mov (Var 1) (Num 1))",
		"(Mov (Var 1) (Num 12))",
		"(Mov (Var 1) (Num 0))",
		"(Mov (Var 1) (Num 0))",
		"(Mov (Var 1) (Num 0))",
		"(Mov (Var 1) (Num 0))",
		"(Mov (Var 1) (Num 1))",
		"(Expr (Var 1) (Read (Var 1) (Num 2)))",
		"(Expr (Var 1) (Call 'foo'))",
		"(Nil)",
		"(Jmp (Label 'label'))",
	}

	testing.expect(t, len(stmts) == len(expected))

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
