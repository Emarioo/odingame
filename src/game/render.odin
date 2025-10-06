package game

import "core:fmt"
import "core:strings"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"

RenderState :: struct {
    window: glfw.WindowHandle,
    width, height: i32,

    ui_program: u32,
    mesh_rect: Mesh,
    // mesh_: Mesh
}

init_render_state :: proc (state: ^GameState) {

    glfw.Init()
    
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    
    render := &state.render_state

    render.width = 800
    render.height = 600
    render.window = glfw.CreateWindow(render.width, render.height, cstring("Game"), nil, nil)

    glfw.MakeContextCurrent(render.window)

    gl.load_up_to(4, 5, glfw.gl_set_proc_address);

    glfw.SwapInterval(0)

    bytes: []byte
    ok: bool
    path := "asset/shader/ui.glsl"
    bytes, ok = os.read_entire_file(path)
    if !ok {
        fmt.eprintln("Could not open",path)
        os.exit(1)
    }

    text := string(bytes)
    vertex_index   := strings.index(text, "#vertex\n")
    fragment_index := strings.index(text, "#fragment\n")

    vertex_text := text[vertex_index+8:fragment_index]
    fragment_text := text[fragment_index+10:]

    render.ui_program, ok = gl.load_shaders_source(vertex_text, fragment_text)
    if !ok {
        fmt.eprintln("Failed loading shaders from", path)
        os.exit(1)
    }

    fmt.println("Loaded shaders")

    render.mesh_rect = create_rect()
}

render_state :: proc (state: ^GameState) {
    render := &state.render_state

    if glfw.WindowShouldClose(render.window) {
        fmt.println("closing window")
        state.running = false
        return
    }

    glfw.PollEvents()
    gl.Viewport(0, 0, render.width, render.height)
    gl.ClearColor(0.2,0.3,0.3,1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT)

    // cull face
    // depth alpha
    gl.Disable(gl.CULL_FACE)

    gl.UseProgram(render.ui_program)

    gl.BindVertexArray(render.mesh_rect.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)

    // gl.DrawElements(gl.TRIANGLES, 0, 3)
    

    // render entities
    for i in 0..<len(state.entities) {
        
    }

    
    glfw.SwapBuffers(render.window)
}



Mesh :: struct {
    vao, vbo, ibo: u32,
}

create_mesh :: proc (vertex_data: []f32, index_data: []u32) -> (mesh: Mesh) {

    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers     (1, &mesh.vbo)
    gl.GenBuffers     (1, &mesh.ibo)

    gl.BindVertexArray(mesh.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertex_data) * size_of(f32), raw_data(vertex_data), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(index_data) * size_of(f32), raw_data(index_data), gl.STATIC_DRAW)

    // position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

    // color attribyte
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)(3*size_of(f32)))
	gl.EnableVertexAttribArray(1)
        
    // texture coordinate attribute
	gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)(6*size_of(f32)))
	gl.EnableVertexAttribArray(2)

    gl.BindVertexArray(0)

    return
}


create_rect :: proc () -> (mesh: Mesh) {

    vertex_data: []f32 = {
    //   pos
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 0.0,
        1.0, 1.0,
        0.0, 1.0,
    }
    // index_data: []u32 = {
    //     1, 3, 2,
    // }

    for i in 0..<len(vertex_data) {
        vertex_data[i]/=2.0
    }

    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers     (1, &mesh.vbo)
    // gl.GenBuffers     (1, &mesh.ibo)

    gl.BindVertexArray(mesh.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertex_data) * size_of(f32), raw_data(vertex_data), gl.STATIC_DRAW)

    // gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    // gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(index_data) * size_of(u32), raw_data(index_data), gl.STATIC_DRAW)

    // position attribute
	gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(f32) * 2, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

    gl.BindVertexArray(0)

    return
}