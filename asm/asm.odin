package assembly

Stack :: struct {
	offset: u64,
}

Constant :: struct {
	inner: u64,
}

Operand :: union {
	Register,
	Stack,
	Constant,
}

Variable :: union {
	Register,
	Stack,
}

Address :: struct {
	base:   Operand,
	offset: Operand,
}

Label :: struct {
	inner: string,
}

Global_Label :: struct {
	inner: string,
}
