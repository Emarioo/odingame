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