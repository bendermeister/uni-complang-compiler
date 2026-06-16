package parser

unique_label_program :: proc(
	node: ^Program,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	for f in node.functions {
		mapping := make(map[string]string)
		defer delete(mapping)
		unique_label_function(f, generator, &mapping, end_mapping)
	}
}

unique_label_function :: proc(
	node: ^Function,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	unique_label_stats(node.stats, generator, mapping, end_mapping)
}

unique_label_stats :: proc(
	node: ^Stats,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	for stat in node.stats {
		unique_label_stat(stat, generator, mapping, end_mapping)
	}
}

unique_label_stat :: proc(
	node: ^Stat,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	switch inner in node {
	case ^Return:
	case ^Conds:
		unique_label_conds(inner, generator, mapping, end_mapping)
	case ^Variable_Definition:
	case ^Variable_Assignment:
	case ^Term:
	}
}

unique_label_conds :: proc(
	node: ^Conds,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	new_label := label_generator_generate(generator)
	mapping[node.label.literal] = new_label.literal
	node.label = new_label

	node.end_label = label_generator_generate(generator)
	end_mapping[node.label.literal] = node.end_label.literal

	for g in node.guarded {
		unique_label_guarded(g, generator, mapping, end_mapping)
	}
}

unique_label_guarded :: proc(
	node: ^Guarded,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	new_mapping := map_copy(mapping)
	defer delete(new_mapping)

	new_end_mapping := map_copy(end_mapping)
	defer delete(new_end_mapping)

	node.end_label = label_generator_generate(generator)

	unique_label_stats(node.stats, generator, &new_mapping, &new_end_mapping)
	unique_label_continue_or_break(node.continue_or_break, generator, mapping, end_mapping)
}

unique_label_continue_or_break :: proc(
	node: ^Continue_Or_Break,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	switch inner in node {
	case ^Continue:
		unique_label_continue(inner, generator, mapping, end_mapping)
	case ^Break:
		unique_label_break(inner, generator, mapping, end_mapping)
	}
}

unique_label_continue :: proc(
	node: ^Continue,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	assert(node.label.literal in mapping)
	node.label.literal = mapping[node.label.literal]
}

unique_label_break :: proc(
	node: ^Break,
	generator: ^Label_Generator,
	mapping: ^map[string]string,
	end_mapping: ^map[string]string,
) {
	assert(node.label.literal in mapping)
	node.label.literal = mapping[node.label.literal]
	assert(node.label.literal in end_mapping)
	node.label.literal = end_mapping[node.label.literal]
}
