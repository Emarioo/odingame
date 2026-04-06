package game

import "core:time"
// import "core:math"
// import "core:math/linalg"
import "core:math/linalg"

import "../engine"
import "../engine/util"

GameState :: struct {
    engine: engine.EngineState,

    player_index: u32,
}
