package generator

import "core:testing"

@(test)
nil_return_test :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)
	append(&stmts, Mov{Variable{1}, Number{1}})
	append(&stmts, Return{Number{2}})
	append(&stmts, Mov{Variable{1}, Number{1}})
	append(&stmts, Mov{Variable{1}, Number{1}})
	append(&stmts, Label{"hello"})
	append(&stmts, Mov{Variable{1}, Number{1}})

	has_changed := false
	nil_return(&stmts, &has_changed)

	testing.expect(t, has_changed)

	out := make([]string, len(stmts))
	for stmt, i in stmts {
		out[i] = stmt_to_string(stmt)
	}

	expected := []string {
		"(Mov (Var 1) (Num 1))",
		"(Return (Num 2))",
		"(Nil)",
		"(Nil)",
		"(Label 'hello')",
		"(Mov (Var 1) (Num 1))",
	}

	testing.expect(t, len(expected) == len(out))

	for _, i in out {
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
