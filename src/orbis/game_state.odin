package orbis

import "core:time"
// import "core:math"
// import "core:math/linalg"
import "core:math/linalg"

import "../engine"
import "../util"

GameState :: struct {
    engine: engine.EngineState,

    terrain: Terrain,

    player_index: u32,
}
