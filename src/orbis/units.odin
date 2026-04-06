/*

*/

package orbis

import "../engine"

import container_queue "core:container/queue"
import "core:math/linalg/glsl"
import "vendor:glfw"
import stb_image "vendor:stb/image"
import gl "vendor:OpenGL"


// EntityType :: enum u8 {
//     ENTITY_WORKER,
//     ENTITY_MARINE,
//     ENTITY_STORAGE,
//     ENTITY_MINERAL,
//     ENTITY_TYPE_MAX,
// }

// Entity :: struct {
//     pos: vec3,
//     vel: vec3,
//     force: vec3,
// }

CommandType :: enum u8 {
    MOVE,
    MINE,
}

Command :: struct {
    type: CommandType,
    data : union {
        struct {
            pos: ivec3,
        },
        struct {
            // @TODO Specify whether to mine wood or mineral
            mine_entity: u32,
            storage_entity: u32,
        },
    }
}

WorkerData :: struct {
    // entity: Entity,
    pos: vec3,
    vel: vec3,
    force: vec3,

    commands: container_queue.Queue(Command),
}

is_worker_idle :: proc (unit: ^WorkerData) -> bool {
    return len(unit.commands) == 0
}

MarineData :: struct {
    // entity: Entity,
    pos: vec3,
    vel: vec3,
    force: vec3,
    
}

StorageData :: struct {
    // entity: Entity,
    pos: vec3,
    vel: vec3,
    force: vec3,

    workers_mining_here: [dynamic]u32,
}

MineralData :: struct {
    // entity: Entity,
    pos: vec3,
    vel: vec3,
    force: vec3,

    value: u32,
}


render_units_init :: proc (state: ^GameState) {

    state.unit_shader = engine.register_asset_from_store(&state.engine, "unit_shader", "shaders/unit.glsl")
    
    create_unit_mesh(state)

}

add_command :: proc (state: ^GameState, unit: ^$T, command: Command) {
    push_back(&unit.commands, command)
}

update_unit_pos :: proc (state: ^GameState, units: $T, count: u32) {
    for wi in 0..<count {
        unit := &units[wi]

        unit.vel += unit.force
        unit.pos += unit.vel * state.engine.fixedDelta
        unit.force = {}
    }
}

update_units :: proc (state: ^GameState) {

    // update_unit_pos(state, &state.workers, state.worker_count)
    update_unit_pos(state, &state.marines, state.marine_count)
    update_unit_pos(state, &state.storages, state.storage_count)
    update_unit_pos(state, &state.minerals, state.mineral_count)

    for wi in 0..<state.worker_count {
        unit := &units[wi]


        if len(unit.commands) > 0 {
            command := front_ptr(&unit.commands)

            switch command.type {
                case .MOVE: {
                    int_pos := command.data.move.pos
                    target := vec3{int_pos.x,int_pos.y,int_pos.z}
                    diff := target - unit.pos
                    move_speed: f32 = 0.8

                    dist := glsl.length(diff)
                    if dist < move_speed {
                        unit.force = diff / state.engine.fixedDelta
                        pop_front(&unit.commands)
                        command = nil // prevent accidental access to invalid memory
                    } else {
                        diff = glsl.normalize(diff)
                        diff *= move_speed

                        unit.force = diff / state.engine.fixedDelta
                    }
                }
                case .MINE: {
                    // command.mine.mine_entity
                    // command.mine.storage_entity
                }
            }
        }

        unit.vel += unit.force
        unit.pos += unit.vel * state.engine.fixedDelta
        unit.force = {}
    }

}


render_units :: proc (state: ^GameState) {

    for wi in 0..<state.worker_count {
        unit := &state.workers[wi]
        render_worker(state, unit)
    }

    for wi in 0..<state.mineral_count {
        unit := &state.minerals[wi]
        render_mineral(state, unit)
    }
    for wi in 0..<state.storage_count {
        unit := &state.storages[wi]
        render_storage(state, unit)
    }
}


add_worker :: proc (state: ^GameState, pos: vec3) -> ^WorkerData {
    worker := &state.workers[state.worker_count]
    worker.pos = pos
    worker.idle = true
    state.worker_count += 1

    return worker

}
add_mineral :: proc (state: ^GameState, pos: vec3, value: u32) {
    unit := &state.minerals[state.mineral_count]
    unit.pos = pos
    unit.value = value
    state.mineral_count += 1
}
add_storage :: proc (state: ^GameState, pos: vec3) {
    unit := &state.storages[state.storage_count]
    unit.pos = pos
    state.storage_count += 1
}

render_worker :: proc (state: ^GameState, worker: ^WorkerData) {
    render := &state.engine.render_state
    shader := state.unit_shader.shader
    mesh   := &state.unit_mesh

    if !engine.can_be_used(state.unit_shader) {
        return
    }

    gl.UseProgram(shader.program)

    transform := glsl.mat4Translate(worker.pos) * glsl.mat4Scale({0.8,0.8,0.8})


    gl.UniformMatrix4fv(shader.uniforms["uTransform"].location, 1, false, transmute([^]f32) &transform)
    gl.UniformMatrix4fv(shader.uniforms["uProjection"].location, 1, false,  transmute([^]f32) &render.projection)
    // gl.Uniform3f(unit_shader.uniforms["uCameraPos"].location,
    //    render.camera_position.x, render.camera_position.y, render.camera_position.z)

    gl.BindVertexArray(mesh.vao)

    color := hex_color_to_vec3("#5a1370ff")

    loc := shader.uniforms["color"]
    if loc.location != 0 {
        gl.Uniform4f(loc.location, color.x, color.y, color.z, 1.0)
    }
    gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_INT, nil)

}


render_mineral :: proc (state: ^GameState, unit: ^MineralData) {
    render := &state.engine.render_state
    shader := state.unit_shader.shader
    mesh   := &state.unit_mesh

    if !engine.can_be_used(state.unit_shader) {
        return
    }

    gl.UseProgram(shader.program)

    transform := glsl.mat4Translate(unit.pos) * glsl.mat4Scale({0.4,0.9,0.1})


    gl.UniformMatrix4fv(shader.uniforms["uTransform"].location, 1, false, transmute([^]f32) &transform)
    gl.UniformMatrix4fv(shader.uniforms["uProjection"].location, 1, false,  transmute([^]f32) &render.projection)
    // gl.Uniform3f(unit_shader.uniforms["uCameraPos"].location,
    //    render.camera_position.x, render.camera_position.y, render.camera_position.z)

    gl.BindVertexArray(mesh.vao)

    color := hex_color_to_vec3("#87d4dfff")

    loc := shader.uniforms["color"]
    if loc.location != 0 {
        gl.Uniform4f(loc.location, color.x, color.y, color.z, 1.0)
    }
    gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_INT, nil)

}


render_storage :: proc (state: ^GameState, unit: ^StorageData) {
    render := &state.engine.render_state
    shader := state.unit_shader.shader
    mesh   := &state.unit_mesh

    if !engine.can_be_used(state.unit_shader) {
        return
    }

    gl.UseProgram(shader.program)

    transform := glsl.mat4Translate(unit.pos) * glsl.mat4Scale({3.0,2.0,3.0})


    gl.UniformMatrix4fv(shader.uniforms["uTransform"].location, 1, false, transmute([^]f32) &transform)
    gl.UniformMatrix4fv(shader.uniforms["uProjection"].location, 1, false,  transmute([^]f32) &render.projection)
    // gl.Uniform3f(unit_shader.uniforms["uCameraPos"].location,
    //    render.camera_position.x, render.camera_position.y, render.camera_position.z)

    gl.BindVertexArray(mesh.vao)

    color := hex_color_to_vec3("#f0ff9aff")

    loc := shader.uniforms["color"]
    if loc.location != 0 {
        gl.Uniform4f(loc.location, color.x, color.y, color.z, 1.0)
    }
    gl.DrawElements(gl.TRIANGLES, mesh.index_count, gl.UNSIGNED_INT, nil)

}



create_unit_mesh :: proc (state: ^GameState) {

    cube_vertices: []f32 = {
        // Front (+Z)
        -0.5, -0.5,  0.5,   0, 0, 1,   0, 0,
        0.5, -0.5,  0.5,   0, 0, 1,   1, 0,
        0.5,  0.5,  0.5,   0, 0, 1,   1, 1,
        -0.5,  0.5,  0.5,   0, 0, 1,   0, 1,

        // Back (-Z)
        0.5, -0.5, -0.5,   0, 0,-1,   0, 0,
        -0.5, -0.5, -0.5,   0, 0,-1,   1, 0,
        -0.5,  0.5, -0.5,   0, 0,-1,   1, 1,
        0.5,  0.5, -0.5,   0, 0,-1,   0, 1,

        // Left (-X)
        -0.5, -0.5, -0.5,  -1, 0, 0,   0, 0,
        -0.5, -0.5,  0.5,  -1, 0, 0,   1, 0,
        -0.5,  0.5,  0.5,  -1, 0, 0,   1, 1,
        -0.5,  0.5, -0.5,  -1, 0, 0,   0, 1,

        // Right (+X)
        0.5, -0.5,  0.5,   1, 0, 0,   0, 0,
        0.5, -0.5, -0.5,   1, 0, 0,   1, 0,
        0.5,  0.5, -0.5,   1, 0, 0,   1, 1,
        0.5,  0.5,  0.5,   1, 0, 0,   0, 1,

        // Top (+Y)
        -0.5,  0.5,  0.5,   0, 1, 0,   0, 0,
        0.5,  0.5,  0.5,   0, 1, 0,   1, 0,
        0.5,  0.5, -0.5,   0, 1, 0,   1, 1,
        -0.5,  0.5, -0.5,   0, 1, 0,   0, 1,

        // Bottom (-Y)
        -0.5, -0.5, -0.5,   0,-1, 0,   0, 0,
        0.5, -0.5, -0.5,   0,-1, 0,   1, 0,
        0.5, -0.5,  0.5,   0,-1, 0,   1, 1,
        -0.5, -0.5,  0.5,   0,-1, 0,   0, 1,
    };

    cube_indices: []u32 = {
        0, 1, 2,  2, 3, 0,       // front
        4, 5, 6,  6, 7, 4,       // back
        8, 9,10, 10,11, 8,       // left
        12,13,14, 14,15,12,       // right
        16,17,18, 18,19,16,       // top
        20,21,22, 22,23,20        // bottom
    };

    mesh := &state.unit_mesh

    // for i in 0..<len(cube_vertices) {
    //     cube_vertices[i]/=2.0
    // }

    gl.GenVertexArrays(1, &mesh.vao)
    gl.GenBuffers     (1, &mesh.vbo)
    gl.GenBuffers     (1, &mesh.ibo)

    gl.BindVertexArray(mesh.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(cube_vertices) * size_of(f32), raw_data(cube_vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, mesh.ibo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(cube_indices) * size_of(u32), raw_data(cube_indices), gl.STATIC_DRAW)

    // position attribute
	gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)0)
	gl.EnableVertexAttribArray(0)
    
    // normal attribute
	gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)12)
	gl.EnableVertexAttribArray(1)
    
    // tex coord attribute
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, size_of(f32) * 8, cast(uintptr)24)
	gl.EnableVertexAttribArray(2)

    mesh.index_count = cast(i32) len(cube_indices)

    gl.BindVertexArray(0)
}