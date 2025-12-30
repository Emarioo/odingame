package game

import "magic"


update_init :: proc (state: ^GameState) {

    text := `insipere
        incantator.acc += vec3(0,1,0)
    finis`

    magic.transpile_spell(text)
}

update_state :: proc (state: ^GameState) {
    
}