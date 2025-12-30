package magic

import "core:fmt"
import "core:os"
import "core:strings"

TokenKind :: enum {
    END_OF_FILE,

    // Literals
    T_IDENTIFIER,
    T_NUMBER,

    // Keywords
    T_INCIPERE,
    T_PERMANERE,
    T_PERFICERE,
    T_FINIS,
    T_SI,
    T_PRO,
    T_IN,
}

Token :: struct {
    kind: TokenKind,
    lexeme: string,
    line: int,
    column: int,
}

lex_text :: proc(text: string) -> [dynamic]Token {
    tokens: [dynamic]Token

    line : int = 1
    column: int = 1
    head : int
    for head < len(text) {
        cur_line := line
        cur_column := column
        c := text[head]
        c1 :u8  = 0
        if head+1 < len(text) {
            c1 = text[head+1]
        }
        head+=1
        column+=1

        if c == '#' {
            for head < len(text) {
                if text[head] == '\n' {
                    head+=1
                    break
                }
                head+=1
            }
            line+=1
            column=1
            continue
        }
        if c == '\n' {
            line+=1
            column=1
            continue
        }
        if c == ' ' || c == '\r' || c == '\t' || c == '\f' {
            continue
        }

        if (c|32) >= 'a' && (c|32) <= 'z' {
            start := head - 1
            for head < len(text) {
                if text[head] == '_' || ((text[head]|32) >= 'a' && (text[head]|32) <= 'z') || ((text[head]) >= '0' && (text[head]) <= '9') {
                    head+=1
                    column+=1
                    continue
                }
                break
            }
            word : string = text[start:head]

            kind : TokenKind = .T_IDENTIFIER
            switch word {
                case "insipere": kind = .T_INCIPERE
                case "permanere": kind = .T_PERMANERE
                case "perficere": kind = .T_PERFICERE
                case "si": kind = .T_SI
                case "pro": kind = .T_PRO
                case "in": kind = .T_IN
                case "finis": kind = .T_FINIS
            }
            append(&tokens, Token{kind, word, cur_line, cur_column})
            continue
        }

        if c >= '0' && c <= '9' {
            start := head - 1
            has_dot := false
            for head < len(text) {
                c := text[head]
                head+=1
                if c == '.' {
                    if has_dot {
                        fmt.println("Bad stuff")
                        os.exit(1)
                    }
                    has_dot=true
                    continue
                }
                if c >= '0' && c <= '9' {
                    continue
                }
                break
            }
            num : string = text[start:head]
            append(&tokens, Token{.T_NUMBER, num, cur_line, cur_column})
            continue
        }
        append(&tokens, Token{cast(TokenKind) c, string([]u8{c}), cur_line, cur_column})
    }

    return tokens
}
