package game

import "core:fmt"
import "core:strings"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"
import ai "lib:assimp"
import "core:path/filepath"
import "core:slice"
import "core:math/linalg/glsl"
import "core:math"
import "core:c"
import "base:runtime"

vec3 :: glsl.vec3
mat4 :: glsl.mat4

RenderState :: struct {
    window: glfw.WindowHandle,
    width, height: i32,

    ui_shader : Shader,
    object_shader : Shader,
    mesh_rect: Mesh,
    // mesh_: Mesh

    camera_position : vec3,
    camera_rotation : vec3,

    projection : mat4,

    block_model : Model,

    mx, my : i32,
    last_mx, last_my : i32,

    move: [6]bool,
    sprint: bool,

    cursor_locked : bool,

    cameraSensitivity : f32,
}

init_render_state :: proc (state: ^GameState) {

    
    glfw.Init()
    
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3);
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3);
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE);
    
    render := &state.render_state
    render.cameraSensitivity = 0.4
    
    render.width = 800
    render.height = 600
    render.window = glfw.CreateWindow(render.width, render.height, cstring("Game"), nil, nil)

    glfw.MakeContextCurrent(render.window)

    gl.load_up_to(4, 5, glfw.gl_set_proc_address);

    glfw.SwapInterval(0)

    ui_path := "asset/shader/ui.glsl"
    object_path := "asset/shader/object.glsl"

    render.ui_shader = load_shader(ui_path)
    render.object_shader = load_shader(object_path)

    fmt.println("(loaded shaders)")

    render.mesh_rect = create_rect()

    block_path := "asset/models/block.glb"
    render.block_model = load_model(block_path)

    fmt.println("(loaded models)")

    global_render_state = render

    glfw.SetKeyCallback(render.window, KeyProc)
    glfw.SetMouseButtonCallback(render.window, MouseButtonProc)
    glfw.SetCursorPosCallback(render.window, CursorPosProc)
    glfw.SetScrollCallback(render.window, ScrollProc)
    glfw.SetWindowSizeCallback(render.window, WindowSizeProc)
    
}

Shader :: struct {
    program: u32,
    uniforms: gl.Uniforms,
}

global_render_state : ^RenderState

KeyProc          :: proc "c" (window: glfw.WindowHandle, key, scancode, action, mods: c.int) {
    context = runtime.default_context()
    assert(global_render_state.window == window)
    
    if key == glfw.KEY_ESCAPE && action == glfw.PRESS {
        global_render_state.cursor_locked = !global_render_state.cursor_locked
        
        if global_render_state.cursor_locked {
            assert(cast(bool)glfw.RawMouseMotionSupported())
            glfw.SetInputMode(global_render_state.window, glfw.CURSOR, glfw.CURSOR_DISABLED);
            glfw.SetInputMode(global_render_state.window, glfw.RAW_MOUSE_MOTION, 1);
        } else {
            glfw.SetInputMode(global_render_state.window, glfw.CURSOR, glfw.CURSOR_NORMAL);
            glfw.SetInputMode(global_render_state.window, glfw.RAW_MOUSE_MOTION, 0);
        }
    }

    if key == glfw.KEY_W {
        global_render_state.move[0] = action != glfw.RELEASE
    }
    if key == glfw.KEY_A {
        global_render_state.move[1] = action != glfw.RELEASE
    }
    if key == glfw.KEY_S {
        global_render_state.move[2] = action != glfw.RELEASE
    }
    if key == glfw.KEY_D {
        global_render_state.move[3] = action != glfw.RELEASE
    }
    if key == glfw.KEY_SPACE {
        global_render_state.move[4] = action != glfw.RELEASE
    }
    if key == glfw.KEY_LEFT_CONTROL {
        global_render_state.move[5] = action != glfw.RELEASE
    }
    if key == glfw.KEY_LEFT_SHIFT {
        global_render_state.sprint = action != glfw.RELEASE
    }

    // fmt.println("key",key,scancode,action,mods)
}
MouseButtonProc  :: proc "c" (window: glfw.WindowHandle, button, action, mods: c.int) {
    context = runtime.default_context()
    assert(global_render_state.window == window)

    
}
CursorPosProc    :: proc "c" (window: glfw.WindowHandle, xpos,  ypos: f64) {
    context = runtime.default_context()
    assert(global_render_state.window == window)
    
    global_render_state.mx = cast(i32)xpos
    global_render_state.my = cast(i32)ypos
    // fmt.println(xpos, ypos)
    // fmt.println("diff",global_render_state.mx-global_render_state.last_mx, global_render_state.my-global_render_state.last_my)
}
ScrollProc       :: proc "c" (window: glfw.WindowHandle, xoffset, yoffset: f64) {
    context = runtime.default_context()
    assert(global_render_state.window == window)
}
WindowSizeProc   :: proc "c" (window: glfw.WindowHandle, width, height: c.int) {
    context = runtime.default_context()
    assert(global_render_state.window == window)
    global_render_state.width = cast(i32)width
    global_render_state.height = cast(i32)height
}

load_shader :: proc (path : string) -> (shader: Shader) {
    bytes: []byte
    ok: bool
    bytes, ok = os.read_entire_file(path)
    if !ok {
        fmt.eprintln("Could not open",path)
        os.exit(1)
    }

    text := string(bytes)
    vertex_index   := strings.index(text, "#vertex") // don't pattern match \n, on Windows we have \r\n while on linux just \n
    fragment_index := strings.index(text, "#fragment")

    vertex_text := text[vertex_index+8:fragment_index]
    fragment_text := text[fragment_index+10:]

    shader.program, ok = gl.load_shaders_source(vertex_text, fragment_text)
    if !ok {
        fmt.eprintln("Failed loading shaders from", path)
        os.exit(1)
    }
    shader.uniforms = gl.get_uniforms_from_program(shader.program)

    fmt.printf("Loaded shader '%s'\n", path)
    return
}

Model :: struct {
    scene : ^ai.aiScene,
    mesh : Mesh,
}

Material :: struct {
    diffuse : vec3,
    specular : vec3,
}

update_projection :: proc (render : ^RenderState) {
    projection := glsl.mat4Perspective( 90.0/(180/math.PI), cast(f32)render.width/cast(f32)render.height, 0.1, 400)
    model_view := glsl.inverse_mat4(
        glsl.mat4Translate(render.camera_position) * 
        glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y) * 
        glsl.mat4Rotate(vec3{1,0,0}, render.camera_rotation.x)
    )
    render.projection = projection * model_view
}

first_mx : bool = false
update_camera :: proc (render : ^RenderState) {
    if render.cursor_locked {
        if !first_mx {
            render.last_mx = render.mx
            render.last_my = render.my
            first_mx = true
        }
        dx := render.mx - render.last_mx
        dy := render.my - render.last_my
        // fmt.println(dx, dy)
        rawX := -cast(f32)(dx) * (math.PI / 360.0) * render.cameraSensitivity;
        rawY := -cast(f32)(dy) * (math.PI / 360.0) * render.cameraSensitivity;
        render.last_mx = render.mx
        render.last_my = render.my
        // e.window->m_tickRawMouseX += rawX;
        // e.window->m_frameRawMouseX += rawX;
        // e.window->m_tickRawMouseY += rawY;
        // e.window->m_frameRawMouseY += rawY;

        rot := render.camera_rotation
        rot.y += rawX;
        rot.x += rawY;
        // clamp up and down directions.
        if (rot.x > math.PI / 2) {
            rot.x = math.PI / 2;
        }
        if (rot.x < -math.PI / 2) {
            rot.x = -math.PI / 2;
        }
        rot.x = math.remainder_f32(rot.x, math.PI * 2);
        rot.y = math.remainder_f32(rot.y, math.PI * 2);
        render.camera_rotation = rot
    }

    speed: f32 = 0.05

    if render.sprint {
        speed *= 3.0
    }

    // look_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y) *
    //             glsl.mat4Rotate(vec3{1,0,0}, render.camera_rotation.x)
    // look_vector := glsl.normalize_vec3(look_mat[2].xyz)

    forward_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y)
    right_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y + math.PI/2)
    forward_vector := glsl.normalize_vec3(forward_mat[2].xyz)
    right_vector := glsl.normalize_vec3(right_mat[2].xyz)
    up_vector := vec3{0,1,0}
    if render.move[0] {
        // forward
        render.camera_position += -forward_vector * speed
    }
    if render.move[1] {
        // right
        render.camera_position += -right_vector * speed
    }
    if render.move[2] {
        // back
        render.camera_position += forward_vector * speed
    }
    if render.move[3] {
        // left
        render.camera_position += right_vector * speed
    }
    if render.move[4] {
        // up
        render.camera_position += up_vector * speed
    }
    if render.move[5] {
        // down
        render.camera_position += -up_vector * speed
    }
}

load_model :: proc (path : string) -> (model: Model) {
    
    model.scene = ai.aiImportFile(strings.unsafe_string_to_cstring(path), cast(u32)ai.aiPostProcessSteps.aiProcess_MakeLeftHanded |
        cast(u32)ai.aiPostProcessSteps.aiProcess_Triangulate
    )

    if model.scene == nil {
        fmt.eprintln("Could not load",path, ", error:",ai.aiGetErrorString());
        os.exit(1)
    }

    assert(1 <= model.scene.mRootNode.mNumMeshes)
    
    mesh_index := model.scene.mRootNode.mMeshes[0]

    assert(mesh_index < model.scene.mNumMeshes)
    mesh : ^ai.aiMesh = model.scene.mMeshes[mesh_index]

    Vertex :: struct {
        // See object.glsl shader
        pos : vec3,
        normal : vec3,
        texture : vec3,
    }   

    vertices := make([]Vertex, mesh.mNumVertices * size_of(Vertex) / size_of(f32))
    indices  := make([]u32, mesh.mNumFaces * 3)

    for i in 0..<mesh.mNumVertices {
        vertices[i].pos = mesh.mVertices[i]
    }
    if mesh.mNormals != nil {
        for i in 0..<mesh.mNumVertices {
            vertices[i].normal = mesh.mNormals[i]
        }
    }
    if mesh.mTextureCoords[0] != nil {
        assert(mesh.mNumUVComponents[0] == 2)
        for i in 0..<mesh.mNumVertices {
            vertices[i].texture.xy = mesh.mTextureCoords[0][i].xy
            vertices[i].texture.z = 0.0 // local material index (used in shader, uMaterials[0])
        }
    }

    for i in 0..<mesh.mNumFaces {
        indices[3*i + 0] = mesh.mFaces[i].mIndices[0]
        indices[3*i + 1] = mesh.mFaces[i].mIndices[1]
        indices[3*i + 2] = mesh.mFaces[i].mIndices[2]
    }

    f32_vertices := slice.from_ptr(cast(^f32) slice.first_ptr(vertices), len(vertices) * size_of(Vertex) / size_of(f32))
    model.mesh = create_mesh(f32_vertices, indices)

    fmt.printf("Loaded model '%s'\n", path)

    return
}

render_state :: proc (state: ^GameState) {
    render := &state.render_state

    if glfw.WindowShouldClose(render.window) {
        fmt.println("closing window")
        state.running = false
        return
    }

    // glfw.PollEvents()
    glfw.WaitEventsTimeout(1/144.0)
    
    update_camera(render)
    update_projection(render)

    gl.Viewport(0, 0, render.width, render.height)
    gl.ClearColor(0.2,0.3,0.3,1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT)


    

    // cull face
    // depth alpha
    // gl.Disable(gl.CULL_FACE)
    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.DEPTH_TEST)


    

    render_rect(state, 0, 0, 100, 100, {1, 0.2, 0.2, 1})

    // render_model(state, render.block_model, Vector3f32{ 3, 0, 0 })
    // render_model(state, render.block_model, Vector3f32{ -3, 0, 0 })
    // render_model(state, render.block_model, Vector3f32{ 0, 0, 3 })
    render_model(state, render.block_model, vec3{ 0, 0, -3 })
    // render_model(state, render.block_model, Vector3f32{ 0, 3, 0 })
    // render_model(state, render.block_model, Vector3f32{ 0, -3, 0 })

    // render entities
    for i in 0..<len(state.entities) {
        
    }

    
    glfw.SwapBuffers(render.window)
}

render_model :: proc (state: ^GameState, model: Model, pos: vec3) {
    render := &state.render_state
    gl.UseProgram(render.object_shader.program)

    transform := glsl.mat4Translate(pos)

    gl.UniformMatrix4fv(render.object_shader.uniforms["uTransform"].location, 1, false, transmute([^]f32) &transform)
    gl.UniformMatrix4fv(render.object_shader.uniforms["uProjection"].location, 1, false,  transmute([^]f32) &render.projection)
    gl.Uniform3f(render.object_shader.uniforms["uCameraPos"].location,
        render.camera_position.x, render.camera_position.y, render.camera_position.z)

    mesh := model.scene.mMeshes[0]
    material := model.scene.mMaterials[mesh.mMaterialIndex]
    // gl.UniformMatrix4fv(render.object_shader.uniforms["uMaterials"].location, )
    // gl.UniformMatrix4fv(render.object_shader.uniforms["uLightSpaceMatrix"].location, )

    max: u32 = 4
    color: ai.aiColor4D
    ai.aiGetMaterialFloatArray(material, ai.AI_MATKEY_COLOR_DIFFUSE, 0, 0, transmute([^]f32)&color, &max)
    if max != 4 {
        color.a = 1.0
    }
    gl.Uniform3fv(render.object_shader.uniforms["uMaterials[0].diffuse_color"].location, 1, transmute([^]f32)&color)

    max = 4
    ai.aiGetMaterialFloatArray(material, ai.AI_MATKEY_COLOR_SPECULAR, 0, 0, transmute([^]f32)&color, &max)
    if max != 4 {
        color.a = 1.0
    }
    gl.Uniform3fv(render.object_shader.uniforms["uMaterials[0].specular_color"].location, 1, transmute([^]f32)&color)

    max = 1
    shiny: f32
    ai.aiGetMaterialFloatArray(material, ai.AI_MATKEY_SHININESS, 0, 0, transmute([^]f32)&shiny, &max)
    gl.Uniform1f(render.object_shader.uniforms["uMaterials[0].shininess"].location, shiny)


    gl.Uniform3i(render.object_shader.uniforms["uLightCount"].location, 1, 0, 0)
    
    dir_light := glsl.normalize_vec3(vec3{0.1, -1, 0.2})
    dir_ambient := glsl.normalize_vec3(vec3{0.2, 0.2, 0.2})
    dir_diffuse := glsl.normalize_vec3(vec3{0.8, 0.8, 0.2})
    dir_specular := glsl.normalize_vec3(vec3{1.0, 1.0, 0.8})
    gl.Uniform3fv(render.object_shader.uniforms["uDirLight.direction"].location, 1, transmute([^]f32)&dir_light)
    gl.Uniform3fv(render.object_shader.uniforms["uDirLight.ambient"].location, 1, transmute([^]f32)&dir_ambient)
    gl.Uniform3fv(render.object_shader.uniforms["uDirLight.diffuse"].location, 1, transmute([^]f32)&dir_diffuse)
    gl.Uniform3fv(render.object_shader.uniforms["uDirLight.specular"].location, 1, transmute([^]f32)&dir_specular)

    // gl.UniformMatrix4fv(render.object_shader.uniforms["uSpotLights"].location, )
    // gl.UniformMatrix4fv(render.object_shader.uniforms["uPointLights"].location, )
    // gl.UniformMatrix4fv(render.object_shader.uniforms["shadow_map"].location, )

    gl.BindVertexArray(model.mesh.vao)
    gl.DrawElements(gl.TRIANGLES, model.mesh.index_count, gl.UNSIGNED_INT, nil)
}

Mesh :: struct {
    vao, vbo, ibo: u32,
    index_count: i32,
}


render_rect :: proc (state: ^GameState, x,y,w,h: f32, color: [4]f32) {
    render := &state.render_state
    gl.UseProgram(render.ui_shader.program)

    gl.Uniform2f(render.ui_shader.uniforms["uWindow"].location, cast(f32)render.width, cast(f32)render.height)
    gl.Uniform2f(render.ui_shader.uniforms["uPos"].location, x, y)
    gl.Uniform2f(render.ui_shader.uniforms["uSize"].location, w, h)
    gl.Uniform4f(render.ui_shader.uniforms["uColor"].location, color.r, color.g, color.b, color.a)

    gl.BindVertexArray(render.mesh_rect.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

create_mesh :: proc (vertex_data: []f32, index_data: []u32) -> (mesh: Mesh) {

    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers     (1, &mesh.vbo)
    gl.GenBuffers     (1, &mesh.ibo)

    gl.BindVertexArray(mesh.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(vertex_data) * size_of(f32), raw_data(vertex_data), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(index_data) * size_of(u32), raw_data(index_data), gl.STATIC_DRAW)

    // position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 9, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)

    // normal attribyte
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 9, cast(uintptr)(3*size_of(f32)))
	gl.EnableVertexAttribArray(1)
        
    // texture coordinate attribute
	gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 9, cast(uintptr)(6*size_of(f32)))
	gl.EnableVertexAttribArray(2)

    gl.BindVertexArray(0)

    mesh.index_count = cast(i32)len(index_data)

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