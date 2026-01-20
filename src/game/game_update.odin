package game

import "core:fmt"
import "core:math"
import "core:sync"
import "core:math/linalg/glsl"
import "core:strings"
import "core:os/os2"

import "magic"
import "../util"
import "../engine"

vec2 :: glsl.vec2
vec3 :: glsl.vec3
vec4 :: glsl.vec4
mat4 :: glsl.mat4

update_init :: proc (state: ^GameState) {

    player, player_index := engine.create_entity(&state.engine)
    state.player_index = player_index

    text := `insipere
        incantator.acc += vec3({0,1,0})
    finis
    `

    magic.transpile_spell(text)

    assets_path := strings.concatenate({state.engine.game_directory, "/assets"})
    util.watcher_init(&state.engine.storage.art_watcher, assets_path)
}

apply_force :: proc (state: ^GameState) {
    speed: f32 = 0.5
    render := &state.engine.render_state

    if render.move[engine.ActionEvent.MOVE_SPRINT] {
        speed *= 4
    }

    player := engine.get_entity(&state.engine, state.player_index)


    // Apply friction
    player.vel *= 0.85

    // look_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y) *
    //             glsl.mat4Rotate(vec3{1,0,0}, render.camera_rotation.x)
    // look_vector := glsl.normalize_vec3(look_mat[2].xyz)

    forward_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y)
    right_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y + math.PI/2)
    forward_vector := glsl.normalize_vec3(forward_mat[2].xyz)
    right_vector := glsl.normalize_vec3(right_mat[2].xyz)
    up_vector := vec3{0,1,0}

    force : vec3

    if render.move[engine.ActionEvent.MOVE_FORWARD] {
        // forward
        force += -forward_vector 
    }
    if render.move[engine.ActionEvent.MOVE_RIGHT] {
        // right
        force += right_vector 
    }
    if render.move[engine.ActionEvent.MOVE_BACKWARD] {
        // back
        force += forward_vector 
    }
    if render.move[engine.ActionEvent.MOVE_LEFT] {
        // left
        force += -right_vector 
    }
    if render.move[engine.ActionEvent.MOVE_UP] {
        // up
        force += up_vector
    }
    if render.move[engine.ActionEvent.MOVE_DOWN] {
        // down
        force += -up_vector 
    }
    player.force += force * speed

    state.engine.render_state.camera_position += force * speed * state.engine.fixedDelta

    // Put events into recorder
    // only care about event changes. Key started or stopped being pressed.

    
    // tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
    // for i in 0..<len(render.move) {
    //     if render.prev_move[i] != render.move[i] {
    //         append(&tick_record.actions, Action{})
    //         action := &tick_record.actions[len(tick_record.actions)-1]
    //         action.kind = cast(i32)i
    //         action.state = cast(i32)render.move[i]
    //     }
    // }
}



update_state :: proc (state: ^GameState) {
    // if len(state.recording.tick_records) > 0 {
    //     // If previous tick had
    //     tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
    //     if len(tick_record.actions) > 0 {
    //         append(&state.recording.tick_records, TickRecord{})
    //     }
    // } else {
    //     append(&state.recording.tick_records, TickRecord{})
    // }
    // tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
    // tick_record.frame = state.current_tick

    // fmt.println("State")
    if state.engine.render_state.move[engine.ActionEvent.RELOAD_ASSETS] {
        state.engine.render_state.temp_move[engine.ActionEvent.RELOAD_ASSETS] = false

        // The engine should handle reloading game code and assets at the same time.
        // Good way to stress test it.

        when ODIN_OS == .Windows {
            args := []string{
                "python",
                "build.py",
                "hot",
            }
        } else {
            args := []string{
                "python3",
                "build.py",
                "hot",
            }
        }
        // fmt.println("RELOADING GAME CODE")

        handle, err := os2.process_start(
            os2.Process_Desc{
                working_dir = "",
                command = args,
                env =  []string{},
                stderr = os2.stderr,
                stdout = os2.stdout,
                stdin = os2.stdin,
            }
        )
        if err == os2.ERROR_NONE {
            err = os2.process_close(handle)
            if err != os2.ERROR_NONE {
                fmt.printfln("process_close: %v", err)
            }
        } else {
            fmt.printfln("process_start: %v", err)
        }

        sync.lock(&state.engine.storage.assets_mutex)
        for key, asset in state.engine.storage.assets_by_name {
            engine.reload_asset(&state.engine, asset)
        }
        sync.unlock(&state.engine.storage.assets_mutex)
    }

    // apply player force
    apply_force(state)

    // update positions

    // @TODO Move to engine?
    for i in 0..<state.engine.entities_count {
        ent := &state.engine.entities[i]
        
        // fmt.printfln("force %v %v %v", ent.force.x, ent.force.y, ent.force.z)

        // @TODO SIMD
        ent.vel += ent.force
        ent.pos += ent.vel * state.engine.fixedDelta
        ent.force = {0,0,0}

    }
}