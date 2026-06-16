package all

import "../generator"
import "../lexer"
import "../parser"
import "core:fmt"
import "core:os"

main :: proc() {
	context.allocator = context.temp_allocator
	defer free_all(context.allocator)
	input_buf := make([dynamic]u8, 16, 16)
	input, input_err := lexer.read_input(&input_buf)
	if input_err != nil {
		fmt.eprintln("input error: ", input_err)
		os.exit(1)
	}
	tokens, lexer_err := lexer.lexer(input)
	if lexer_err != nil {
		fmt.eprintln("lexer error: ", lexer_err)
		os.exit(1)
	}


	ast := parser.parse(tokens[:])
	if ast == nil {
		fmt.eprintln("parser error")
		os.exit(2)
	}

	for f in ast.functions {
		l := generator.function_lower(f)
		generator.optimize(&l.stmts)
		out := generator.function_generate(l)
		fmt.println(out)
	}
}
