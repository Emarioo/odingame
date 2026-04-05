/*
    This file handles logic for rendering and modifying terrain.

    Terrain is the 2D tilemap. The tilemap is chunk-based.
*/

package orbis

import "core:math/linalg/glsl"
import "vendor:glfw"
import stb_image "vendor:stb/image"
import gl "vendor:OpenGL"

import "../engine"

ivec3 :: [3]i32

TILES_PER_CHUNK_SIDE :: 32

TileType :: enum {
    GRASS,
}

Tile :: struct {
    front_type: TileType,
    back_type: TileType,
}

Chunk :: struct {
    chunk_pos: ivec3, // scaled by chunk position and not tile position
    tiles: [dynamic] Tile,
}

Terrain :: struct {
    chunks: [dynamic] Chunk,

    tile_shader: ^engine.Asset,
    cube_mesh: engine.Mesh,
}

update_terrain :: proc () {

}

create_chunk :: proc (pos: ivec3) -> (chunk: Chunk) {
    chunk.chunk_pos = pos
    chunk.tiles = make([dynamic]Tile, TILES_PER_CHUNK_SIDE*TILES_PER_CHUNK_SIDE)

    for i in 0..<len(chunk.tiles) {
        chunk.tiles[i].front_type = .GRASS
        chunk.tiles[i].back_type = .GRASS
    }
    return
}

terrain_init :: proc (state: ^engine.EngineState, terrain: ^Terrain) {
    terrain.tile_shader = engine.register_asset_from_store(state, "tile_shader", "shaders/tile.glsl")

    create_cube(terrain)

}


create_cube :: proc (terrain: ^Terrain) {

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

    mesh := &terrain.cube_mesh

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

render_terrain :: proc (render: ^engine.RenderState, terrain: ^Terrain) {

    for ci in 0..<len(terrain.chunks) {
        render_chunk(render, terrain, &terrain.chunks[ci])
    }

}

render_chunk :: proc (render: ^engine.RenderState, terrain: ^Terrain, chunk: ^Chunk) {

    for i in 0..<len(chunk.tiles) {
        ox := i % TILES_PER_CHUNK_SIDE
        oz := i / TILES_PER_CHUNK_SIDE
        tile_pos := chunk.chunk_pos * TILES_PER_CHUNK_SIDE + { cast(i32) ox, 0, cast(i32) oz }

        render_tile(render, terrain, &chunk.tiles[i], tile_pos)

    }

}

// vscode has color picker next to hex
hex_to_int :: proc(c: u8) -> u8 {
    if c >= '0' && c <= '9' {
        return cast(u8)c - '0'
    }
    if (c|32) >= 'a' && (c|32) <= 'f' {
        return cast(u8)c - 'a' + 10
    }
    return 0 // @TODO ASSERT
}
hex_color_to_vec3 :: proc (str: string) -> (result: vec3) {
    result.x = cast(f32)((hex_to_int(str[1]) << 4) | hex_to_int(str[2])) / 255.0
    result.y = cast(f32)((hex_to_int(str[3]) << 4) | hex_to_int(str[4])) / 255.0
    result.z = cast(f32)((hex_to_int(str[5]) << 4) | hex_to_int(str[6])) / 255.0
    return
}

render_tile :: proc (render: ^engine.RenderState, terrain: ^Terrain, tile: ^Tile, pos: ivec3) {

    gl.UseProgram(terrain.tile_shader.shader.program)

    transform := glsl.mat4Translate(vec3{cast(f32)pos.x, cast(f32)pos.y, cast(f32)pos.z})

    tile_shader := terrain.tile_shader.shader

    gl.UniformMatrix4fv(tile_shader.uniforms["uTransform"].location, 1, false, transmute([^]f32) &transform)
    gl.UniformMatrix4fv(tile_shader.uniforms["uProjection"].location, 1, false,  transmute([^]f32) &render.projection)
    // gl.Uniform3f(tile_shader.uniforms["uCameraPos"].location,
    //    render.camera_position.x, render.camera_position.y, render.camera_position.z)

    gl.BindVertexArray(terrain.cube_mesh.vao)

    color: vec3
    switch tile.front_type {
        case .GRASS: {
            color = hex_color_to_vec3("#0cc249ff")
        }
        case: {
            // @TODO ASSERT
        }
    }

    loc := tile_shader.uniforms["color"]
    if loc.location != 0 {
        gl.Uniform4f(loc.location, color.x, color.y, color.z, 1.0)
    }
    gl.DrawElements(gl.TRIANGLES, terrain.cube_mesh.index_count, gl.UNSIGNED_INT, nil)

}