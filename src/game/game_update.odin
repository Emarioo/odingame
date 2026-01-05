package game

import "magic"
import "core:math"
import "core:math/linalg/glsl"

update_init :: proc (state: ^GameState) {

    player, player_index := create_entity(state)
    state.player_index = player_index

    text := `insipere
        incantator.acc += vec3({0,1,0})
    finis
    `

    magic.transpile_spell(text)
}

apply_force :: proc (state: ^GameState) {
    speed: f32 = 3
    render := &state.render_state

    if render.move[ActionEvent.MOVE_SPRINT] {
        speed *= 3.0
    }

    player := get_entity(state, state.player_index)

    // look_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y) *
    //             glsl.mat4Rotate(vec3{1,0,0}, render.camera_rotation.x)
    // look_vector := glsl.normalize_vec3(look_mat[2].xyz)

    forward_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y)
    right_mat := glsl.mat4Rotate(vec3{0,1,0}, render.camera_rotation.y + math.PI/2)
    forward_vector := glsl.normalize_vec3(forward_mat[2].xyz)
    right_vector := glsl.normalize_vec3(right_mat[2].xyz)
    up_vector := vec3{0,1,0}

    force : vec3

    if render.move[ActionEvent.MOVE_FORWARD] {
        // forward
        force += -forward_vector 
    }
    if render.move[ActionEvent.MOVE_RIGHT] {
        // right
        force += -right_vector 
    }
    if render.move[ActionEvent.MOVE_BACKWARD] {
        // back
        force += forward_vector 
    }
    if render.move[ActionEvent.MOVE_LEFT] {
        // left
        force += right_vector 
    }
    if render.move[ActionEvent.MOVE_UP] {
        // up
        force += up_vector
    }
    if render.move[ActionEvent.MOVE_DOWN] {
        // down
        force += -up_vector 
    }
    player.force += force * speed

    // Put events into recorder
    // only care about event changes. Key started or stopped being pressed.

    
    tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
    for i in 0..<len(render.move) {
        if render.prev_move[i] != render.move[i] {
            append(&tick_record.actions, Action{})
            action := &tick_record.actions[len(tick_record.actions)-1]
            action.kind = cast(i32)i
            action.state = cast(i32)render.move[i]
        }
    }
}

update_state :: proc (state: ^GameState) {
    if len(state.recording.tick_records) > 0 {
        // If previous tick had
        tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
        if len(tick_record.actions) > 0 {
            append(&state.recording.tick_records, TickRecord{})
        }
    } else {
        append(&state.recording.tick_records, TickRecord{})
    }
    tick_record: ^TickRecord = &state.recording.tick_records[len(state.recording.tick_records)-1]
    tick_record.frame = state.current_tick

    // apply player force
    apply_force(state)

    // update positions

    for i in 0..<len(state.entities) {
        ent := &state.entities[i]
        
        // @TODO SIMD
        ent.vel += ent.force
        ent.pos += ent.vel * state.delta
        ent.force = 0
    }

    player := get_entity(state, state.player_index)
    state.render_state.camera_position = player.pos
}