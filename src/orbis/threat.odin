/*
    Enemy AI
*/

package orbis

TeamState :: struct {
    idle_workers: [dynamic]u32,

    unsaturated_storages: [dynamic]u32,
    // owned_storages: [dynamic]u32,
}

calculate_idle_workers :: proc (state: ^GameState, teamState: ^TeamState) {
    clear(&teamState.idle_workers)
    for i in 0..<state.worker_count {
        worker := &state.workers[i]
        // @NOCHECKIN Check team
        
        if is_worker_idle(worker) {
            append(&teamState.idle_workers, i)
        }
    }
}


calculate_storages :: proc (state: ^GameState, teamState: ^TeamState) {
    // clear(&teamState.owned_storages)
    clear(&teamState.unsaturated_storages)
    for i in 0..<state.storage_count {
        storage := &state.storages[i]
        // @NOCHECKIN Check team

        // append(&teamState.owned_storages, i)
        
        if len(storage.workers_mining_here) < 5 {
            // @TODO 5 workers does not satify a storage or mining area.
            append(&teamState.unsaturated_storages, i)
        }
    }
}


to_vec3 :: proc (v: ivec3) -> vec3 {
    return {cast(f32)v.x,cast(f32)v.y,cast(f32)v.z}
}
to_ivec3 :: proc (v: vec3) -> ivec3 {
    return {cast(i32)v.x,cast(i32)v.y,cast(i32)v.z}
}

// find_closest_mineral :: proc (state: ^GameState, pos: ivec3) -> u32 {
find_closest_mineral :: proc (state: ^GameState, pos: vec3) -> u32 {
    closest_index: u32 = INVALID_ENTITY_INDEX
    closest_dist: f32 = 99999999
    // fpos := to_vec3(pos)
    fpos := pos

    for i in 0..<state.mineral_count {
        unit := &state.minerals[i]
        dist := glsl.length(fpos - unit.pos)
        if dist < closest_dist {
            closest_dist = dist
            closest_index = i
        }
    }

    return closest_index
}
find_closest_storage :: proc (state: ^GameState, pos: vec3) -> u32 {
    closest_index: u32 = INVALID_ENTITY_INDEX
    closest_dist: f32 = 99999999
    // fpos := to_vec3(pos)
    fpos := pos

    for i in 0..<state.storage_count {
        unit := &state.storages[i]
        dist := glsl.length(fpos - unit.pos)
        if dist < closest_dist {
            closest_dist = dist
            closest_index = i
        }
    }

    return closest_index
}

update_threat :: proc (state: ^GameState, teamState: ^TeamState) {
    /*
        Code for basic enemy AI

        Currently based on training
        soldiers to defend all buildings.
    */

    calculate_idle_workers(state, teamState)
    calculate_storages(state, teamState)

    if len(teamState.idle_workers) > 0 {
        // tell worker to mine minerals at nearest site.
        // if site has many workers then move to
        // other area.
        for wi in 0..<len(teamState.idle_workers) {
            unit := &state.workers[teamState.idle_workers[wi]]
            close_mineral := find_closest_mineral(state, unit.pos)
            if close_mineral == INVALID_ENTITY_INDEX {
                break
            }
            close_storage := find_closest_storage(state, unit.pos)
            if close_storage == INVALID_ENTITY_INDEX {
                break
            }

            add_command_mine(unit, close_mineral, close_storage)
        }
    }

    if len(teamState.unsaturated_storages) > 0 {
        for si in 0..<len(teamState.unsaturated_storages) {
            storage := &state.storages[si]

            workers_to_train := min(0, 5 - len(storage.workers_mining_here))
            // @NOCHECKIN train workers
        }
    }

    // @NOCHECKIN Train soldiers
}