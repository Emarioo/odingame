package orbis

import "core:time"
// import "core:math"
// import "core:math/linalg"
import "core:math/linalg"

import eng "../engine"  


// @TODO Increase these limits
//   does each faction have their own array of workers?
MAX_ENTITY :: 1024

GameState :: struct {
    engine: eng.EngineState,

    terrain: Terrain,

    unit_mesh: eng.Mesh,
    unit_shader: ^eng.Asset,

    player_index: u32,

    workers: [MAX_ENTITY]WorkerData,
    worker_count: u32,
    marines: [MAX_ENTITY]MarineData,
    marine_count: u32,
    storages: [MAX_ENTITY]StorageData,
    storage_count: u32,
    minerals: [MAX_ENTITY]MineralData,
    mineral_count: u32,

    teamState: ^TeamState,

}
