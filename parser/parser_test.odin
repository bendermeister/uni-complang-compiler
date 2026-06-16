package parser

import "core:fmt"
import "core:slice"
import "core:testing"

@(test)
parse_function_name_test_0000 :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)
	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}, Token{kind = .VAR}}

	function_name, tokens_tail := parse_function_name(tokens)
	testing.expect(t, function_name != nil)
	testing.expect(t, function_name^ == Function_Name{literal = "foo"})
	testing.expect(t, len(tokens_tail) == 1)
	testing.expect(t, tokens_tail[0] == Token{kind = .VAR})

	function_name, tokens_tail = parse_function_name(tokens_tail)

	testing.expect(t, function_name == nil)
}

@(test)
parse_number_test_0000 :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 64}, Token{kind = .COND}}

	number, tokens_tail := parse_number(tokens)
	testing.expect(t, number != nil)
	testing.expect(t, number^ == Number{literal = 64})
	testing.expect(t, len(tokens_tail) == 1)
	testing.expect(t, tokens_tail[0] == Token{kind = .COND})

	number, tokens_tail = parse_number(tokens_tail)
	testing.expect(t, number == nil)
}

@(test)
parse_label_test_0000 :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo_label"}, Token{kind = .VAR}}

	label, tokens_tail := parse_label(tokens)
	testing.expect(t, label != nil)
	testing.expect(t, label^ == Label{literal = "foo_label"})
	testing.expect(t, len(tokens_tail) == 1)
	testing.expect(t, tokens_tail[0] == Token{kind = .VAR})

	label, tokens_tail = parse_label(tokens_tail)
	testing.expect(t, label == nil)
}

@(test)
parse_variable_test_0000 :: proc(t: ^testing.T) {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}, Token{kind = .VAR}}

	variable, tokens_tail := parse_variable(tokens)
	testing.expect(t, variable != nil)
	testing.expectf(t, variable^ == Variable{literal = "foo"}, "actual: %v", variable)
	testing.expect(t, len(tokens_tail) == 1)
	testing.expect(t, tokens_tail[0] == Token{kind = .VAR})

	variable, tokens_tail = parse_variable(tokens_tail)
	testing.expect(t, variable == nil)
}

@(test)
variable_to_string_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := Variable {
		literal = "foo",
	}
	out := variable_to_string(&node)

	testing.expect(t, out == "(Variable 'foo')")
}

@(test)
label_to_string_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := Label {
		literal = "foo",
	}
	out := label_to_string(&node)
	testing.expect(t, out == "(Label 'foo')")
}

@(test)
number_to_string_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := Number {
		literal = 2,
	}
	out := number_to_string(&node)

	testing.expect(t, out == "(Number '2')")
}

@(test)
function_name_to_string_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	node := Function_Name {
		literal = "foo",
	}
	out := function_name_to_string(&node)
	testing.expect(t, out == "(FunctionName 'foo')")
}

@(test)
parse_program_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{}

	node, tail := parse_program(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := program_to_string(node)
	expected := "(Program)"

	testing.expect(t, out == expected)
}

@(test)
parse_program_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .PARENTHESES_CLOSE},
		Token{kind = .END},
		Token{kind = .SEMICOLON},
		Token{kind = .WORD, literal_word = "bar"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .PARENTHESES_CLOSE},
		Token{kind = .END},
		Token{kind = .SEMICOLON},
	}

	node, tail := parse_program(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := program_to_string(node)
	expected := "(Program (Function (FunctionName 'foo') (Parameter) (Stats)) (Function (FunctionName 'bar') (Parameter) (Stats)))"

	testing.expect(t, out == expected)
}

@(test)
parse_function_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .PARENTHESES_CLOSE},
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .SEMICOLON},
		Token{kind = .END},
	}

	node, tail := parse_function(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := function_to_string(node)
	expected := "(Function (FunctionName 'foo') (Parameter) (Stats (Stat (Term (Number '1')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_function_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .SEMICOLON},
		Token{kind = .END},
	}

	node, tail := parse_function(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_parameter_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{}

	node, tail := parse_parameter(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := parameter_to_string(node)
	expected := "(Parameter)"

	testing.expect(t, out == expected)
}

@(test)
parse_parameter_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}}

	node, tail := parse_parameter(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := parameter_to_string(node)
	expected := "(Parameter (Variable 'foo'))"

	testing.expect(t, out == expected)
}

@(test)
parse_parameter_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}, Token{kind = .COMMA}}

	node, tail := parse_parameter(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := parameter_to_string(node)
	expected := "(Parameter (Variable 'foo'))"

	testing.expect(t, out == expected)
}

@(test)
parse_parameter_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .COMMA},
		Token{kind = .WORD, literal_word = "bar"},
	}

	node, tail := parse_parameter(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := parameter_to_string(node)
	expected := "(Parameter (Variable 'foo') (Variable 'bar'))"

	testing.expect(t, out == expected)
}

@(test)
parse_stats_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token{}

	node, tail := parse_stats(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stats_to_string(node)
	expected := "(Stats)"

	testing.expect(t, out == expected)
}

@(test)
parse_stats_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token{Token{kind = .NUMBER, literal_number = 1}, Token{kind = .SEMICOLON}}

	node, tail := parse_stats(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stats_to_string(node)
	expected := "(Stats (Stat (Term (Number '1'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_stats_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .SEMICOLON},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
	}

	node, tail := parse_stats(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stats_to_string(node)
	expected := "(Stats (Stat (Term (Number '1'))) (Stat (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_stats_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
	}

	node, tail := parse_stats(tokens)

	testing.expect(t, node == nil)
}

@(test)
parse_stat_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .COND}, Token{kind = .END}}

	node, tail := parse_stat(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stat_to_string(node)
	expected := "(Stat (Conds))"

	testing.expect(t, out == expected)
}

@(test)
parse_stat_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .VAR},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .WALRUSS},
		Token{kind = .NUMBER, literal_number = 1},
	}

	node, tail := parse_stat(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stat_to_string(node)
	expected := "(Stat (VariableDefinition (Variable 'foo') (Expr (Term (Number '1')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_stat_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .WALRUSS},
		Token{kind = .NUMBER, literal_number = 1},
	}

	node, tail := parse_stat(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stat_to_string(node)
	expected := "(Stat (VariableAssignment (LExpr (Variable 'foo')) (Expr (Term (Number '1')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_stat_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 1}}

	node, tail := parse_stat(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stat_to_string(node)
	expected := "(Stat (Term (Number '1')))"

	testing.expect(t, out == expected)
}

@(test)
parse_stat_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .RETURN}, Token{kind = .NUMBER, literal_number = 1}}

	node, tail := parse_stat(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tail) == 0)

	out := stat_to_string(node)
	expected := "(Stat (Return (Expr (Term (Number '1')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_stat_test_0005 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .RETURN}}

	node, tail := parse_stat(tokens)

	testing.expect(t, node == nil)
}


@(test)
parse_conds_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "label"},
		Token{kind = .COLON},
		Token{kind = .COND},

		// guarded 0
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
		Token{kind = .SEMICOLON},

		// guarded 1
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
		Token{kind = .SEMICOLON},

		// end
		Token{kind = .END},
	}

	node, tokens_tail := parse_conds(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := conds_to_string(node)
	expected := "(Conds (Label 'label') (Guarded (Expr (Term (Number '1'))) (Stats (Stat (Term (Number '2')))) (ContinueOrBreak (Continue))) (Guarded (Expr (Term (Number '1'))) (Stats (Stat (Term (Number '2')))) (ContinueOrBreak (Continue))))"

	testing.expect(t, out == expected)
}

@(test)
parse_conds_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .COND},

		// guarded 0
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
		Token{kind = .SEMICOLON},

		// guarded 1
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
		Token{kind = .SEMICOLON},

		// end
		Token{kind = .END},
	}

	node, tokens_tail := parse_conds(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := conds_to_string(node)
	expected := "(Conds (Guarded (Expr (Term (Number '1'))) (Stats (Stat (Term (Number '2')))) (ContinueOrBreak (Continue))) (Guarded (Expr (Term (Number '1'))) (Stats (Stat (Term (Number '2')))) (ContinueOrBreak (Continue))))"

	testing.expect(t, out == expected)
}

@(test)
parse_conds_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .COND},

		// guarded 1
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
		Token{kind = .SEMICOLON},

		// end
		Token{kind = .END},
	}

	node, tokens_tail := parse_conds(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := conds_to_string(node)
	expected := "(Conds (Guarded (Expr (Term (Number '1'))) (Stats (Stat (Term (Number '2')))) (ContinueOrBreak (Continue))))"

	testing.expect(t, out == expected)
}

@(test)
parse_conds_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .COND},
		// end
		Token{kind = .END},
	}

	node, tokens_tail := parse_conds(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := conds_to_string(node)
	expected := "(Conds)"

	testing.expect(t, out == expected)
}

@(test)
parse_conds_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .COND}}

	node, tokens_tail := parse_conds(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_guarded_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 69},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 80},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
	}

	node, tokens_tail := parse_guarded(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := guarded_to_string(node)
	expected := "(Guarded (Expr (Term (Number '69'))) (Stats (Stat (Term (Number '80')))) (ContinueOrBreak (Continue)))"

	testing.expect(t, out == expected)
}

@(test)
parse_guarded_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 80},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
	}

	node, tokens_tail := parse_guarded(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := guarded_to_string(node)
	expected := "(Guarded (Stats (Stat (Term (Number '80')))) (ContinueOrBreak (Continue)))"

	testing.expect(t, out == expected)
}

@(test)
parse_guarded_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .LEFT_ARROW}, Token{kind = .BREAK}}

	node, tokens_tail := parse_guarded(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := guarded_to_string(node)
	expected := "(Guarded (Stats) (ContinueOrBreak (Break)))"

	testing.expect(t, out == expected)
}

@(test)
parse_guarded_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 69},
		Token{kind = .NUMBER, literal_number = 80},
		Token{kind = .SEMICOLON},
		Token{kind = .CONTINUE},
	}

	node, tokens_tail := parse_guarded(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_guarded_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 69},
		Token{kind = .LEFT_ARROW},
		Token{kind = .NUMBER, literal_number = 80},
		Token{kind = .SEMICOLON},
	}

	node, tokens_tail := parse_guarded(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_variable_assignment_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .WALRUSS},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_variable_assignment(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := variable_assignment_to_string(node)
	expected := "(VariableAssignment (LExpr (Variable 'foo')) (Expr (Term (Number '2'))))"

	testing.expect(t, out == expected)

}

@(test)
parse_variable_assignment_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_variable_assignment(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_variable_definition_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .VAR},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .WALRUSS},
		Token{kind = .NUMBER, literal_number = 69},
	}

	node, tokens_tail := parse_variable_definition(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := variable_definition_to_string(node)
	expected := "(VariableDefinition (Variable 'foo') (Expr (Term (Number '69'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_variable_definition_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .VAR},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .NUMBER, literal_number = 69},
	}

	node, tokens_tail := parse_variable_definition(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_lexpr_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}}

	node, tokens_tail := parse_lexpr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := lexpr_to_string(node)
	expected := "(LExpr (Variable 'foo'))"

	testing.expect(t, out == expected)
}

@(test)
parse_lexpr_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .BRACKET_OPEN},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .BRACKET_CLOSE},
	}

	node, tokens_tail := parse_lexpr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := lexpr_to_string(node)
	expected := "(LExpr (ArrayAccess (Term (Variable 'foo')) (Expr (Term (Number '2')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_lexpr_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, tokens_tail := parse_lexpr(tokens)
	testing.expect(t, node == nil)
}


@(test)
parse_continue_or_break_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .CONTINUE}}

	node, tokens_tail := parse_continue_or_break(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := continue_or_break_to_string(node)
	expected := "(ContinueOrBreak (Continue))"
}

@(test)
parse_continue_or_break_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .BREAK}}

	node, tokens_tail := parse_continue_or_break(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := continue_or_break_to_string(node)
	expected := "(ContinueOrBreak (Break))"
}

@(test)
parse_continue_or_break_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, tokens_tail := parse_continue_or_break(tokens)

	testing.expect(t, node == nil)
}

@(test)
parse_continue_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .CONTINUE}, Token{kind = .VAR}}
	node, tokens_tail := parse_continue(tokens)

	testing.expect(t, node != nil)

	format := continue_to_string(node)

	testing.expect(t, format == "(Continue)", "actual: ", format)

	testing.expect(t, len(tokens_tail) == 1)
	testing.expect(t, slice.equal(tokens[1:], tokens_tail))
}

@(test)
parse_continue_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, tokens_tail := parse_continue(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_continue_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .CONTINUE}, Token{kind = .WORD, literal_word = "foo"}}

	node, tokens_tail := parse_continue(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := continue_to_string(node)


	testing.expect(t, out == "(Continue (Label 'foo'))", "actual: ", out)
}

@(test)
parse_break_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .BREAK}, Token{kind = .VAR}}

	node, tokens_tail := parse_break(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 1)

	out := break_to_string(node)

	testing.expect(t, out == "(Break)", "actual: ", out)
}

@(test)
parse_break_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, tokens_tail := parse_break(tokens)

	testing.expect(t, node == nil)
}

@(test)
parse_break_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .BREAK},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .VAR},
	}

	node, tokens_tail := parse_break(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 1)

	out := break_to_string(node)

	testing.expect(t, out == "(Break (Label 'foo'))", "acutal: ", out)
}

@(test)
parse_expr_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NOT}, Token{kind = .NUMBER, literal_number = 1}}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (NotTerm (NotList 1) (Term (Number '1'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .BRACKET_OPEN},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .BRACKET_CLOSE},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (ArrayAccess (Term (Number '1')) (Expr (Term (Number '2')))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .PLUS},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Sum (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .STAR},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Product (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .AND},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Conjunction (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0005 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .GREATER},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Greater (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0006 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .EQUAL},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Equal (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0007 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .MINUS},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Minus (Term (Number '1')) (Term (Number '2'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0008 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 1}}

	node, tokens_tail := parse_expr(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := expr_to_string(node)
	expected := "(Expr (Term (Number '1')))"

	testing.expect(t, out == expected)
}

@(test)
parse_expr_test_0009 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{}

	node, tokens_tail := parse_expr(tokens)
	testing.expect(t, node == nil)
}


@(test)
parse_function_call_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .PARENTHESES_CLOSE},
	}

	node, tokens_tail := parse_function_call(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := function_call_to_string(node)

	testing.expect(t, out == "(FunctionCall (FunctionName 'foo') ())")
}

@(test)
parse_function_call_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foobar"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .COMMA},
		Token{kind = .WORD, literal_word = "bar"},
		Token{kind = .PARENTHESES_CLOSE},
	}

	node, tokens_tail := parse_function_call(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := function_call_to_string(node)

	fmt.println("out: ", out)

	expected := "(FunctionCall (FunctionName 'foobar') ((Expr (Term (Variable 'foo'))) (Expr (Term (Variable 'bar')))))"

	testing.expectf(t, out == expected, "acutal: %v expected: %v")
}

@(test)
parse_function_call_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foobar"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .COMMA},
		Token{kind = .PARENTHESES_CLOSE},
	}

	node, tokens_tail := parse_function_call(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := function_call_to_string(node)

	expected := "(FunctionCall (FunctionName 'foobar') ((Expr (Term (Variable 'foo')))))"

	testing.expectf(t, out == expected, "acutal: %v expected: %v")
}

@(test)
parse_term_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .PARENTHESES_CLOSE},
	}

	node, tokens_tail := parse_term(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := term_to_string(node)
	expected := "(Term (Expr (Term (Number '1'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_term_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 1}}

	node, tokens_tail := parse_term(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := term_to_string(node)
	expected := "(Term (Number '1'))"

	testing.expect(t, out == expected)
}

@(test)
parse_term_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .WORD, literal_word = "foo"}}

	node, tokens_tail := parse_term(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := term_to_string(node)
	expected := "(Term (Variable 'foo'))"

	testing.expect(t, out == expected)
}


@(test)
parse_term_test_0003 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PARENTHESES_OPEN},
		Token{kind = .PARENTHESES_CLOSE},
	}

	node, tokens_tail := parse_term(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := term_to_string(node)
	expected := "(Term (FunctionCall (FunctionName 'foo') ()))"

	testing.expect(t, out == expected)
}

@(test)
parse_term_test_0004 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, tokens_tail := parse_term(tokens)
	testing.expect(t, node == nil)
}


@(test)
parse_not_list_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NOT},
		Token{kind = .NOT},
		Token{kind = .NOT},
		Token{kind = .VAR},
	}

	node, token_tail := parse_not_list(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(token_tail) == 1)

	out := not_list_to_string(node)

	expected := "(NotList 3)"

	testing.expect(t, out == expected)
}

@(test)
parse_not_list_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .VAR}}

	node, token_tail := parse_not_list(tokens)

	testing.expect(t, node == nil)
}

@(test)
parse_not_term_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NOT},
		Token{kind = .NOT},
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .VAR},
	}

	node, tokens_tail := parse_not_term(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 1)

	out := not_term_to_string(node)
	expected := "(NotTerm (NotList 2) (Term (Variable 'foo')))"

	testing.expect(t, out == expected)
}

@(test)
parse_array_access_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .BRACKET_OPEN},
		Token{kind = .NUMBER, literal_number = 64},
		Token{kind = .BRACKET_CLOSE},
	}

	node, tokens_tail := parse_array_access(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := array_access_to_string(node)
	expected := "(ArrayAccess (Term (Variable 'foo')) (Expr (Term (Number '64'))))"

	testing.expect(t, out == expected)
}

@(test)
parse_array_access_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)
	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .BRACKET_OPEN},
		Token{kind = .NUMBER, literal_number = 64},
	}

	node, tokens_tail := parse_array_access(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_sum_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .PLUS},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .PLUS},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_sum(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := sum_to_string(node)
	expected := "(Sum (Term (Variable 'foo')) (Term (Number '2')) (Term (Number '3')))"

	testing.expect(t, out == expected)
}

@(test)
parse_sum_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .PLUS},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .PLUS},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_sum(tokens)
	testing.expect(t, node == nil)
}
@(test)
parse_sum_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_sum(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_product_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .STAR},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .STAR},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_product(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := product_to_string(node)

	expected := "(Product (Term (Number '1')) (Term (Number '2')) (Term (Number '3')))"
	testing.expect(t, out == expected)
}

@(test)
parse_product_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .STAR},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .STAR},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_product(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_product_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_product(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_conjunction_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .WORD, literal_word = "foo"},
		Token{kind = .AND},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .AND},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_conjunction(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := conjunction_to_string(node)
	expected := "(Conjunction (Term (Variable 'foo')) (Term (Number '2')) (Term (Number '3')))"

	testing.expect(t, out == expected)
}

@(test)
parse_conjunction_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .AND},
		Token{kind = .NUMBER, literal_number = 2},
		Token{kind = .AND},
		Token{kind = .NUMBER, literal_number = 3},
	}

	node, tokens_tail := parse_conjunction(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_conjunction_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_conjunction(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_greater_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .GREATER},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_greater(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := greater_to_string(node)
	expected := "(Greater (Term (Number '1')) (Term (Number '2')))"

	testing.expect(t, out == expected)
}

@(test)
parse_greater_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .GREATER}, Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_greater(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_greater_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_greater(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_equal_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .EQUAL},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_equal(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := equal_to_string(node)
	expected := "(Equal (Term (Number '1')) (Term (Number '2')))"

	testing.expect(t, out == expected)
}

@(test)
parse_equal_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .EQUAL}, Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_equal(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_equal_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_equal(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_minus_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token {
		Token{kind = .NUMBER, literal_number = 1},
		Token{kind = .MINUS},
		Token{kind = .NUMBER, literal_number = 2},
	}

	node, tokens_tail := parse_minus(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := minus_to_string(node)
	expected := "(Minus (Term (Number '1')) (Term (Number '2')))"

	testing.expect(t, out == expected)
}

@(test)
parse_minus_test_0001 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .MINUS}, Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_minus(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_minus_test_0002 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .NUMBER, literal_number = 2}}

	node, tokens_tail := parse_minus(tokens)
	testing.expect(t, node == nil)
}

@(test)
parse_return_test_0000 :: proc(t: ^testing.T) {
	defer free_all(context.allocator)

	tokens := []Token{Token{kind = .RETURN}, Token{kind = .NUMBER, literal_number = 69}}

	node, tokens_tail := parse_return(tokens)

	testing.expect(t, node != nil)
	testing.expect(t, len(tokens_tail) == 0)

	out := return_to_string(node)
	expected := "(Return (Expr (Term (Number '69'))))"

	testing.expect(t, out == expected)
}
