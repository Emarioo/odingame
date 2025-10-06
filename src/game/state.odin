package game

import "core:time"
import "core:math"

MAX_ENTITIES :: 1024

FIXED_UPDATE_DELTA :: 1.0/60.0

vec3 :: [3]f32

GameState :: struct {

    entities:       [MAX_ENTITIES]Entity,
    entities_count: int,

    lastTime:     time.Time,
    accDeltaTime: f64,
    delta:        f64,

    render_state: RenderState,

    running: bool,
}

Entity :: struct {
    pos: vec3,
}