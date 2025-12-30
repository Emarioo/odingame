package magic

import "core:os"
import "core:os/os2"
import "core:fmt"
import "core:strings"

/*
    Compiles spells
*/

Spell :: struct {
    text: string,

}

TranspileContext :: struct {
    head: int,
    tokens: [dynamic]Token,

    output: [dynamic]u8,
}

transpile_spell :: proc (text: string) {

    ctx: TranspileContext
    ctx.head = 0
    ctx.tokens = lex_text(text)

    parse_text(&ctx)

    os2.mkdir("spells", 0o777)
    

    write_file("spells/spell.odin", string(ctx.output[:]))

    // @TODO .dll on windows
    compile_odin("spells", "libspell.so")
}



parse_text :: proc (ctx: ^TranspileContext) {

    append(&ctx.output, `
    package spell;

    import "core:math/linalg/glsl"

    vec3 :: glsl.vec3

    Entity :: struct {
      pos: vec3,
      vel: vec3,
      rot: vec3,
      acc: vec3,
    }

    SpellContext :: struct {
      caster: ^Entity
    }`)

    for {

    }

    // ctx.output.append("export on_begin :: proc(ctx: ^SpellContext) {\n")

    // ctx.output.append("}\n")

    // ctx.output.append("export on_casting :: proc(ctx: ^SpellContext) {\n")
    // ctx.output.append("}\n")

    // ctx.output.append("export on_complete :: proc(ctx: ^SpellContext) {\n")
    // ctx.output.append("}\n")

}

compile_odin :: proc(src_path: string, dst_path: string) -> bool {

    out_arg: string = strings.concatenate([]string{"-out:",dst_path})
    args := []string{
        "odin",
        "build",
        src_path,
        "-collection:lib=lib",
        "-debug",
        "-o:none",
        "-build-mode:shared", // dynamic on Windows?
        out_arg,
    }
      

    proce, err := os2.process_start(
        os2.Process_Desc{
            working_dir = "",
            command = args,
            env =  []string{},
            stderr = os2.stderr,
            stdout = os2.stdout,
            stdin = os2.stdin,
        }
    )

    if err != os2.ERROR_NONE {
        fmt.println("Failed to start Odin compiler:", err)
        os2.exit(1)
    }

    result, err2 := os2.process_wait(proce)

    if result.exit_code != 0 {
        fmt.println("Odin compilation failed")
        os2.exit(1)
    }

    fmt.println("Spell compiled successfully")
    return true
}

write_file :: proc(path: string, text: string) -> bool {

    dst, ok := os.open(path, os.O_CREATE | os.O_TRUNC | os.O_WRONLY, 0o777)
    if ok != os.General_Error.None {
        fmt.println("Failed to create destination file")
        return false
    }
    defer os.close(dst)

    bytes_written, write_ok := os.write(dst, transmute([]u8) text)
    if write_ok != os.General_Error.None {
        fmt.println("Write failed")
        return false
    }

    return true
}
