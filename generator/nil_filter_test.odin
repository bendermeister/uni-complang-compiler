package generator

import "core:testing"

@(test)
nil_filter_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	stmts := make([dynamic]Stmt)
	append(&stmts, nil)
	append(&stmts, Mov{Variable{1}, Variable{2}})
	append(&stmts, nil)
	append(&stmts, Mov{Variable{3}, Variable{4}})
	append(&stmts, nil)
	append(&stmts, nil)
	append(&stmts, Mov{Variable{5}, Variable{6}})
	append(&stmts, nil)

	has_changed := false
	nil_filter(&stmts, &has_changed)
	testing.expect(t, has_changed)
	has_changed = false
	nil_filter(&stmts, &has_changed)
	testing.expect(t, !has_changed)

	out := make([]string, len(stmts))

	for _, i in out {
		out[i] = stmt_to_string(stmts[i])
	}

	expected := []string{"(Mov (Var 1) (Var 2))", "(Mov (Var 3) (Var 4))", "(Mov (Var 5) (Var 6))"}

	testing.expect(t, len(out) == len(expected))

	for _, i in out {
		testing.expectf(
			t,
			out[i] == expected[i],
			"i: %v, out: %v, expected: %v",
			i,
			out[i],
			expected[i],
		)
	}
}
