package parser

import "core:testing"

vl_make :: proc() -> (map[string]bool, map[string]bool) {
	return make(map[string]bool), make(map[string]bool)
}

@(test)
check_program_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_program(
		{
			make_function(
				make_function_name("foo"),
				make_parameter({make_variable("a")}),
				make_stats({}),
			),
			make_function(
				make_function_name("foo"),
				make_parameter({make_variable("a")}),
				make_stats({}),
			),
		},
	)

	ok := check_program(node)
	testing.expect(t, ok)
}

@(test)
check_function_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_function(make_function_name("foo"), make_parameter({}), make_stats({}))

	v, l := vl_make()

	ok := check_function(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_function_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_function(
		make_function_name("foo"),
		make_parameter({make_variable("a")}),
		make_stats({make_stat(make_term(make_variable("a")))}),
	)

	v, l := vl_make()

	ok := check_function(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_parameter_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_parameter({make_variable("a"), make_variable("b")})

	v, l := vl_make()

	ok := check_parameter(node, &v, &l)

	testing.expect(t, ok)
	testing.expect(t, "a" in v)
	testing.expect(t, "b" in v)
}

@(test)
check_parameter_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_parameter({make_variable("a"), make_variable("b")})

	v, l := vl_make()

	v["a"] = true

	ok := check_parameter(node, &v, &l)

	testing.expect(t, !ok)
}

@(test)
check_parameter_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_parameter({})

	v, l := vl_make()

	ok := check_parameter(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_stats_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stats({make_stat(make_term(make_variable("a")))})

	v, l := vl_make()

	ok := check_stats(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_stats(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_stats_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stats(
		{
			make_stat(
				make_variable_definition(make_variable("a"), make_expr(make_term(make_number(2)))),
			),
			make_stat(make_term(make_variable("a"))),
		},
	)

	v, l := vl_make()

	ok := check_stats(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_stat_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stat(make_conds(make_label("label"), {}))

	v, l := vl_make()

	ok := check_stat(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_stat_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stat(
		make_variable_definition(make_variable("a"), make_expr(make_term(make_number(2)))),
	)

	v, l := vl_make()

	ok := check_stat(node, &v, &l)
	testing.expect(t, ok)
	testing.expect(t, "a" in v)
}

@(test)
check_stat_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stat(
		make_variable_assignment(
			make_lexpr(make_variable("a")),
			make_expr(make_term(make_number(1))),
		),
	)

	v, l := vl_make()

	ok := check_stat(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_stat(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_stat_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_stat(make_term(make_variable("a")))

	v, l := vl_make()

	ok := check_stat(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_stat(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_variable_assignment_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_variable_assignment(
		make_lexpr(make_variable("a")),
		make_expr(make_term(make_number(1))),
	)

	v, l := vl_make()

	ok := check_variable_assignment(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_variable_assignment(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_variable_definition_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_variable_definition(make_variable("a"), make_expr(make_term(make_variable("b"))))

	v, l := vl_make()

	v["b"] = true

	ok := check_variable_definition(node, &v, &l)

	testing.expect(t, ok)
	testing.expect(t, "a" in v)
}

@(test)
check_variable_definition_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_variable_definition(make_variable("a"), make_expr(make_term(make_variable("b"))))

	v, l := vl_make()

	v["b"] = true
	v["a"] = true

	ok := check_variable_definition(node, &v, &l)

	testing.expect(t, !ok)
}

@(test)
check_return_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_return(make_expr(make_term(make_variable("a"))))

	v, l := vl_make()

	ok := check_return(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_return(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_conds_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_conds(
		make_label("label"),
		{
			make_guarded(
				make_expr(make_term(make_variable("a"))),
				make_stats({}),
				make_continue_or_break(make_continue(nil)),
			),
			make_guarded(
				make_expr(make_term(make_variable("a"))),
				make_stats({}),
				make_continue_or_break(make_break(make_label("label"))),
			),
		},
	)

	v, l := vl_make()

	ok := check_conds(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_conds(node, &v, &l)
	testing.expect(t, ok)

	testing.expect(t, "label" not_in l)

}

@(test)
check_guarded_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_guarded(
		nil,
		make_stats(
			{
				make_stat(
					make_variable_definition(
						make_variable("new"),
						make_expr(make_term(make_number(2))),
					),
				),
			},
		),
		make_continue_or_break(make_continue(make_label("label"))),
	)

	v, l := vl_make()

	ok := check_guarded(node, &v, &l)
	testing.expect(t, !ok)

	testing.expect(t, "new" not_in v)

	l["label"] = true

	ok = check_guarded(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_guarded_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_guarded(
		nil,
		make_stats({}),
		make_continue_or_break(make_continue(make_label("label"))),
	)

	v, l := vl_make()

	ok := check_guarded(node, &v, &l)
	testing.expect(t, !ok)

	l["label"] = true

	ok = check_guarded(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_guarded_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_guarded(
		make_expr(make_term(make_variable("a"))),
		make_stats({}),
		make_continue_or_break(make_continue(make_label("label"))),
	)

	v, l := vl_make()

	ok := check_guarded(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_guarded(node, &v, &l)
	testing.expect(t, !ok)

	l["label"] = true

	ok = check_guarded(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_break_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_break(nil)

	v, l := vl_make()

	ok := check_break(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_break_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_break(make_label("foo"))

	v, l := vl_make()

	ok := check_break(node, &v, &l)

	testing.expect(t, !ok)

	l["foo"] = true

	ok = check_break(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_continue_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_continue(nil)

	v, l := vl_make()

	ok := check_continue(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_continue_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_continue(make_label("foo"))

	v, l := vl_make()

	ok := check_continue(node, &v, &l)

	testing.expect(t, !ok)

	l["foo"] = true

	ok = check_continue(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_continue_or_break_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_continue_or_break(make_break(make_label("foo")))

	v, l := vl_make()

	ok := check_continue_or_break(node, &v, &l)
	testing.expect(t, !ok)

	l["foo"] = true

	ok = check_continue_or_break(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_continue_or_break_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_continue_or_break(make_continue(make_label("foo")))

	v, l := vl_make()

	ok := check_continue_or_break(node, &v, &l)
	testing.expect(t, !ok)

	l["foo"] = true

	ok = check_continue_or_break(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_lexpr_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_lexpr(make_variable("a"))

	v, l := vl_make()
	ok := check_lexpr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_lexpr(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_lexpr_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_lexpr(
		make_array_access(make_term(make_variable("a")), make_expr(make_term(make_number(1)))),
	)

	v, l := vl_make()
	ok := check_lexpr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_lexpr(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_array_access_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_array_access(make_term(make_number(1)), make_expr(make_term(make_variable("a"))))

	v, l := vl_make()

	ok := check_array_access(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true

	ok = check_array_access(node, &v, &l)
	testing.expect(t, ok)
}


@(test)
check_expr_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_not_term(make_not_list(2), make_term(make_variable("a"))))

	v, l := vl_make()
	v["a"] = true

	ok := check_expr(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_expr_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_not_term(make_not_list(2), make_term(make_variable("a"))))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)

	testing.expect(t, !ok)
}

@(test)
check_expr_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(
		make_array_access(make_term(make_variable("a")), make_expr(make_term(make_number(1)))),
	)

	v, l := vl_make()
	v["a"] = true

	ok := check_expr(node, &v, &l)

	testing.expect(t, ok)
}

@(test)
check_expr_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(
		make_array_access(make_term(make_variable("a")), make_expr(make_term(make_number(1)))),
	)

	v, l := vl_make()

	ok := check_expr(node, &v, &l)

	testing.expect(t, !ok)
}

@(test)
check_expr_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_sum({make_term(make_number(1)), make_term(make_variable("a"))}))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0005 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_product({make_term(make_number(1)), make_term(make_variable("a"))}))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0006 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_conjunction({make_term(make_number(1)), make_term(make_variable("a"))}))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0007 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_greater(make_term(make_variable("a")), make_term(make_number(1))))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0008 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_equal(make_term(make_variable("a")), make_term(make_number(1))))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0009 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_minus(make_term(make_variable("a")), make_term(make_number(1))))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_expr_test_0010 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_expr(make_term(make_variable("a")))

	v, l := vl_make()

	ok := check_expr(node, &v, &l)
	testing.expect(t, !ok)

	v["a"] = true
	ok = check_expr(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_conjunction_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_conjunction({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_conjunction(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_conjunction_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_conjunction({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["b"] = true

	ok := check_conjunction(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_conjunction_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_conjunction({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true

	ok := check_conjunction(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_conjunction_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_conjunction({})

	v, l := vl_make()

	v["a"] = true

	ok := check_conjunction(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_product_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_product({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_product(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_product_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_product({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["b"] = true

	ok := check_product(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_product_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_product({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true

	ok := check_product(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_product_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_product({})

	v, l := vl_make()

	v["a"] = true

	ok := check_product(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_sum_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_sum({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_sum(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_sum_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_sum({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["b"] = true

	ok := check_sum(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_sum_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_sum({make_term(make_variable("a")), make_term(make_variable("b"))})

	v, l := vl_make()

	v["a"] = true

	ok := check_sum(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_sum_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_sum({})

	v, l := vl_make()

	v["a"] = true

	ok := check_sum(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_minus_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_minus(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_minus(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_minus_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_minus(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["b"] = true

	ok := check_minus(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_minus_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_minus(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true

	ok := check_minus(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_greater_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_greater(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_greater(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_greater_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_greater(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["b"] = true

	ok := check_greater(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_greater_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_greater(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true

	ok := check_greater(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_equal_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_equal(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true
	v["b"] = true

	ok := check_equal(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_equal_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_equal(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["b"] = true

	ok := check_equal(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_equal_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	node := make_equal(make_term(make_variable("a")), make_term(make_variable("b")))

	v, l := vl_make()

	v["a"] = true

	ok := check_equal(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_term_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_term(make_number(1))
	v, l := vl_make()
	ok := check_term(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_term_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_term(make_variable("foo"))
	v, l := vl_make()
	v["foo"] = true
	ok := check_term(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_term_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_term(make_variable("foo"))
	v, l := vl_make()
	ok := check_term(node, &v, &l)
	testing.expect(t, !ok)
}

@(test)
check_term_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_term(make_function_call(make_function_name("foo"), {}))
	v, l := vl_make()
	ok := check_term(node, &v, &l)
	testing.expect(t, ok)
}

@(test)
check_term_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := make_term(make_expr(make_term(make_number(2))))
	v, l := vl_make()
	ok := check_term(node, &v, &l)
	testing.expect(t, ok)
}
