package game

import "core:time"
// import "core:math"
// import "core:math/linalg"

MAX_ENTITIES :: 1024

FIXED_UPDATE_DELTA :: 1.0/60.0

GameState :: struct {

    entities:       [MAX_ENTITIES]Entity,
    entities_count: u32,

    lastTime:     time.Time,
    accDeltaTime: f64,
    delta:        f32,

    player_index: u32,

    current_tick: u32, // 60 ticks per second, unsigned 32-bit int can hold ~2.2 years of game time (2^32/60/60/60/24/365)

    render_state: RenderState,
    recording: Recording,

    running: bool,
}

Entity :: struct {
    pos: vec3,
    vel: vec3,
    force: vec3,
}

create_entity :: proc (state: ^GameState) -> (^Entity, u32) {
    index := state.entities_count
    state.entities_count += 1
    ent := &state.entities[index]

    ent.pos = {0,0,0}
    ent.vel = {0,0,0}
    ent.force = {0,0,0}

    return ent, index
}

get_entity :: proc (state: ^GameState, index: u32) -> ^Entity {
    return &state.entities[index]
}