package game

import "core:fmt"
import "../driver"
import "core:time"
import "core:strings"
import "../util"

@(export)
driver_event :: proc (event: driver.EventKind, data: ^driver.EventData) {
    if event != driver.EventKind.EVENT_TICK {
        fmt.println("EVENT ", event, data)
    }

    switch event {
        case .EVENT_START:
            data.user_data = new(GameState)
            game_state := cast(^GameState)data.user_data
            game_state.running = true
            
            game_state.startTime = time.now()
            init_render_state(game_state)
            update_init(game_state)
            
        case .EVENT_STOP:
            // TODO: cleanup
        case .EVENT_LOAD:
            // if game is initialized.
        case .EVENT_UNLOAD:

        case .EVENT_TICK:
            game_state := cast(^GameState)data.user_data
            tick(game_state)
            data.running = game_state.running
    }
}


tick :: proc (state: ^GameState) {
    if time.time_to_unix_nano(state.lastTime) == 0 {
        // last_time is zero first tick
        state.lastTime = time.now()
    }

    now := time.now()
    state.delta = cast(f32)(time.time_to_unix_nano(now) - time.time_to_unix_nano(state.lastTime)) / 1.0e9
    state.lastTime = now
    state.accDeltaTime += cast(f32)state.delta

    events := util.watcher_poll(&state.art_watcher)

    for e in events {
        fmt.printfln("%v", e)
        // @TODO Wait with reloading, blender modifies the file multiple times when exporting.
        rel_path := strings.concatenate({"art/", e.path}, context.temp_allocator)

        asset := find_asset_by_src(&state.storage, rel_path)
        if asset != nil {
            exists := false
            for a in state.scheduled_assets {
                if a == asset {
                    exists = true
                    break
                }
            }
            if !exists {
                fmt.printfln("Schedule asset %v", asset.path)
                asset.scheduled_time = time.now()
                append(&state.scheduled_assets, asset)
            }
        }
    }

    // @TODO Some way to trigger schedule reload manually?
    //   CLI command maybe? console in the game?

    ASSET_RELOAD_TIME :: 500 * time.Millisecond

    time_now := time.now()
    for i := len(state.scheduled_assets)-1; i >= 0; i -= 1 {
        asset := state.scheduled_assets[i]
        diff := time.diff(asset.scheduled_time, time_now)
        
        if diff > ASSET_RELOAD_TIME {
            pop(&state.scheduled_assets)
            // Reload with file io and model parsing should be done on a separate thread.
            // When we initialize opengl buffers we need to schedule that on the render thread
            // unless we use Vulkan.
            reload_asset(state, asset)
        }
    }

    state.fixedDelta = FIXED_UPDATE_DELTA
    for state.accDeltaTime > FIXED_UPDATE_DELTA {
        state.accDeltaTime -= FIXED_UPDATE_DELTA
        // state.fixedDelta = state.delta
        state.render_state.move = state.render_state.temp_move
        update_state(state)
        state.current_tick += 1
        state.render_state.prev_move = state.render_state.move
    }
    // state.render_state.camera_position += {5 * state.delta,0, 5 * state.delta}

    
    
    player := get_entity(state, state.player_index)
    // state.render_state.camera_position = player.pos
    state.render_state.camera_position = player.pos + player.vel * state.accDeltaTime
    render_state(state)

    // if state.current_tick % 60 == 0 {
    //     fmt.printfln("fps %v", 1/state.delta)
    // }

    // time.sleep(14 * 1000000)
}