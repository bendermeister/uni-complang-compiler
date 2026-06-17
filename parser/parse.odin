package parser

import "core:os"
parse :: proc(tokens: []Token) -> ^Program {
	program, tokens := parse_program(tokens)
	if program == nil {
		return nil
	}
	if len(tokens) != 0 {
		return nil
	}

	ok := check_program(program)
	if !ok {
		os.exit(3)
	}

	unnil_program(program)

	label_generator := label_generator_make()
	defer label_generator_delete(label_generator)

	mapping := make(map[string]string)
	defer delete(mapping)

	end_mapping := make(map[string]string)
	defer delete(mapping)

	unique_label_program(program, &label_generator, &mapping, &end_mapping)

	return program
}
