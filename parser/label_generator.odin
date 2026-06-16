package parser

import "core:strings"
Label_Generator :: struct {
	labels: map[string]bool,
	num:    u64,
}

label_generator_generate :: proc(generator: ^Label_Generator) -> ^Label {
	builder := strings.builder_make()
	for {
		strings.builder_reset(&builder)
		strings.write_string(&builder, "_internal_label_")
		strings.write_u64(&builder, generator.num)
		generator.num += 1

		label := strings.to_string(builder)

		if label not_in generator.labels {
			generator.labels[label] = true
			return make_label(label)
		}
	}
}

label_generator_make :: proc() -> Label_Generator {
	return Label_Generator{num = 0, labels = make(map[string]bool)}
}

label_generator_delete :: proc(generator: Label_Generator) {
	delete(generator.labels)
}
