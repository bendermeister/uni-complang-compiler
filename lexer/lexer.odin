package lexer

import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:os"
import "core:testing"

read_input :: proc(buf: ^[dynamic]u8) -> ([]u8, Error) {
	buf := make([dynamic]u8, 8, 8)
	current_length := 0

	for {
		nread, err := os.read(os.stdin, buf[current_length:])
		if err == io.Error.EOF {break}
		if err != nil {
			delete(buf)
			return nil, .COULD_NOT_READ_INPUT
		}
		current_length += nread

		if current_length == len(buf) {
			resize(&buf, len(buf) * 2)
		}
	}

	return buf[:current_length], nil
}

to_lower :: proc(c: u8) -> u8 {
	if !('A' <= c && c <= 'Z') {return c}
	return c + 32
}

is_digit :: proc(c: u8) -> bool {
	return '0' <= c && c <= '9'
}

is_hex_digit :: proc(c: u8) -> bool {
	c := to_lower(c)
	return ('a' <= c && c <= 'f') || c == '_' || ('0' <= c && c <= '9')
}

is_alphabetic :: proc(c: u8) -> bool {
	c := to_lower(c)
	return 'a' <= c && c <= 'z'
}

is_word :: proc(c: u8) -> bool {
	return is_digit(c) || is_alphabetic(c) || c == '_'
}

Error :: enum {
	NONE = 0,
	COULD_NOT_READ_INPUT,
	COULD_NOT_PARSE_NUMBER,
	UNEXPECTED_TOKEN,
}

TokenKind :: enum {
	NONE,
	EOF,
	AND,
	END,
	RETURN,
	VAR,
	COND,
	CONTINUE,
	BREAK,
	NOT,
	SEMICOLON,
	PARENTHESES_OPEN,
	WORD,
	PARENTHESES_CLOSE,
	COMMA,
	WALRUSS,
	COLON,
	LEFT_ARROW,
	STAR,
	PLUS,
	GREATER,
	EQUAL,
	MINUS,
	NUMBER,
	BRACKET_OPEN,
	BRACKET_CLOSE,
}

Token :: struct {
	kind:           TokenKind,
	literal_word:   string,
	literal_number: u64,
	line:           int,
}

parse_hex_number :: proc(buf: []u8) -> (number: u64, err: Error) {
	buf := buf[2:]

	for x in buf {
		d := to_lower(x)
		if d == '_' {continue}
		number *= 16
		if is_digit(d) {
			number += u64(d - '0')
		} else if 'a' <= d && d <= 'f' {
			number += u64(d - 'a' + 10)
		} else {
			return number, .COULD_NOT_PARSE_NUMBER
		}
	}

	return number, nil
}

parse_dec_number :: proc(buf: []u8) -> (number: u64, err: Error) {
	for d in buf {
		if d == '_' {continue}
		if !is_digit(d) {return number, .COULD_NOT_PARSE_NUMBER}
		number *= 10
		number += u64(d - '0')
	}
	return number, nil
}

parse_number :: proc(buf: []u8) -> (u64, Error) {
	if len(buf) >= 2 && buf[0] == '0' && buf[1] == 'x' {
		return parse_hex_number(buf)
	} else {
		return parse_dec_number(buf)
	}
}

lexer :: proc(buf: []u8) -> ([dynamic]Token, Error) {
	tokens := make([dynamic]Token)
	line := 1
	buf := buf

	for len(buf) > 0 {
		switch buf[0] {
		case '\n':
			line += 1
			buf = buf[1:]

		case ';':
			token := Token{.SEMICOLON, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '(':
			token := Token{.PARENTHESES_OPEN, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case ')':
			token := Token{.PARENTHESES_CLOSE, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case ',':
			token := Token{.COMMA, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '*':
			token := Token{.STAR, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '+':
			token := Token{.PLUS, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '>':
			token := Token{.GREATER, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '=':
			token := Token{.EQUAL, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case '[':
			token := Token{.BRACKET_OPEN, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case ']':
			token := Token{.BRACKET_CLOSE, "", 0, line}
			append(&tokens, token)
			buf = buf[1:]

		case ':':
			if len(buf) > 2 && buf[1] == '=' {
				token := Token{.WALRUSS, "", 0, line}
				append(&tokens, token)
				buf = buf[2:]
			} else {
				token := Token{.COLON, "", 0, line}
				append(&tokens, token)
				buf = buf[1:]
			}

		case '-':
			if len(buf) > 2 && buf[1] == '>' {
				token := Token{.LEFT_ARROW, "", 0, line}
				append(&tokens, token)
				buf = buf[2:]
			} else if len(buf) > 2 && buf[1] == '-' {
				buf = buf[2:]
				for len(buf) > 0 && buf[0] != '\n' {buf = buf[1:]}
			} else {
				token := Token{.MINUS, "", 0, line}
				append(&tokens, token)
				buf = buf[1:]
			}
		case:
			if is_digit(buf[0]) {
				i := 0
				if len(buf) >= 2 && buf[0] == '0' && buf[1] == 'x' {
					i = 2
					for ; i < len(buf) && is_hex_digit(buf[i]); i += 1 {}
				} else {
					for ; i < len(buf) && (buf[i] == '_' || is_digit(buf[i])); i += 1 {}
				}
				word := buf[:i]
				buf = buf[i:]
				number, err := parse_number(word)
				if err != nil {
					fmt.eprintln(
						"ERROR (",
						line,
						") '",
						transmute(string)word,
						"' could not be parse as a number",
					)
					delete(tokens)
					return nil, err
				}
				token := Token{.NUMBER, transmute(string)word, number, line}
				append(&tokens, token)
			} else if is_alphabetic(buf[0]) {
				i := 0
				for ; i < len(buf) && is_word(buf[i]); i += 1 {}
				word := buf[:i]
				buf = buf[i:]
				token: Token
				switch string(word) {
				case "end":
					token = Token{.END, "", 0, line}
				case "return":
					token = Token{.RETURN, "", 0, line}
				case "var":
					token = Token{.VAR, "", 0, line}
				case "cond":
					token = Token{.COND, "", 0, line}
				case "continue":
					token = Token{.CONTINUE, "", 0, line}
				case "break":
					token = Token{.BREAK, "", 0, line}
				case "not":
					token = Token{.NOT, "", 0, line}
				case "and":
					token = Token{.AND, "", 0, line}
				case:
					token = Token{.WORD, transmute(string)word, 0, line}
				}
				append(&tokens, token)
			} else if buf[0] == ' ' || buf[0] == '\t' {
				buf = buf[1:]
			} else {
				delete(tokens)
				fmt.eprintln("ERROR (", line, ") unexpected token '", buf[0], "'")
				return nil, .UNEXPECTED_TOKEN
			}
		}
	}

	return tokens, nil
}

main :: proc() {
	input_buffer := make([dynamic]u8, 16, 16)
	buf, err := read_input(&input_buffer)
	defer delete(input_buffer)

	if err != nil {
		fmt.eprintln("could not read from stdin")
		os.exit(1)
	}

	tokens: [dynamic]Token
	tokens, err = lexer(buf)
	defer delete(tokens)

	fmt.println(tokens)
}

@(test)
lexer_00_test :: proc(t: ^testing.T) {
	input := "end return var cond continue break not ;(),:=:->*+>=-[] \n 39end word variable_name 1_0_0 0xFf_ 0x 0x__ and"
	tokens, err := lexer(transmute([]u8)input)
	defer delete(tokens)
	expected := []Token {
		Token{.END, "", 0, 1},
		Token{.RETURN, "", 0, 1},
		Token{.VAR, "", 0, 1},
		Token{.COND, "", 0, 1},
		Token{.CONTINUE, "", 0, 1},
		Token{.BREAK, "", 0, 1},
		Token{.NOT, "", 0, 1},
		Token{.SEMICOLON, "", 0, 1},
		Token{.PARENTHESES_OPEN, "", 0, 1},
		Token{.PARENTHESES_CLOSE, "", 0, 1},
		Token{.COMMA, "", 0, 1},
		Token{.WALRUSS, "", 0, 1},
		Token{.COLON, "", 0, 1},
		Token{.LEFT_ARROW, "", 0, 1},
		Token{.STAR, "", 0, 1},
		Token{.PLUS, "", 0, 1},
		Token{.GREATER, "", 0, 1},
		Token{.EQUAL, "", 0, 1},
		Token{.MINUS, "", 0, 1},
		Token{.BRACKET_OPEN, "", 0, 1},
		Token{.BRACKET_CLOSE, "", 0, 1},
		Token{.NUMBER, "39", 39, 2},
		Token{.END, "", 0, 2},
		Token{.WORD, "word", 0, 2},
		Token{.WORD, "variable_name", 0, 2},
		Token{.NUMBER, "1_0_0", 100, 2},
		Token{.NUMBER, "0xFf_", 255, 2},
		Token{.NUMBER, "0x", 0, 2},
		Token{.NUMBER, "0x__", 0, 2},
		Token{.AND, "", 0, 2},
	}

	for i := 0; i < min(len(expected), len(tokens)); i += 1 {
		testing.expectf(
			t,
			tokens[i] == expected[i],
			"expected: %v actual: %v",
			expected[i],
			tokens[i],
		)
	}

	testing.expectf(
		t,
		len(tokens) == len(expected),
		"expected: %v, actual: %v",
		len(expected),
		len(tokens),
	)

}
