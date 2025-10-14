package game

import "core:fmt"
import "../driver"
import "core:time"

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
            
            init_render_state(game_state)
            
        case .EVENT_STOP:
            // TODO: cleanup
        case .EVENT_LOAD:
            
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
    state.delta = cast(f64)(time.time_to_unix_nano(now) - time.time_to_unix_nano(state.lastTime)) / 1.0e9
    state.lastTime = now
    state.accDeltaTime += state.delta

    for state.accDeltaTime > FIXED_UPDATE_DELTA {
        state.accDeltaTime -= FIXED_UPDATE_DELTA
        update_state(state)
    }
    
    render_state(state)

    time.sleep(16 * 1000000)
}