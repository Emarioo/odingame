package driver

import "core:sync"
import "core:thread"
import "core:dynlib"
import "core:fmt"

EventKind :: enum {
    EVENT_START,  // called after the first load
    EVENT_LOAD,
    EVENT_TICK,
    EVENT_UNLOAD,
    EVENT_STOP    // called before the final unload
}


DriverData :: struct {
    running: bool,
    driver_event: proc(event: EventKind, event_data: ^EventData, data: ^DriverData),
    threads: [dynamic]^thread.Thread,
    thread_main: thread.Thread_Proc,

    user_data:        rawptr,

    thread_semaphore: sync.Sema,

    game_directory:   string,

    mutex:            sync.Mutex,
    cond:             sync.Cond,
    reload_requested: bool,
    active_threads:   i32,
    parked_threads:   i32,
}


EventData :: struct {
    user_index: int,
    user_data: rawptr,
}

permanent_library_load :: proc (path: string) {
    templib, ok := dynlib.load_library(path)
    if !ok {
        fmt.printfln("Failed loading %v", path)
    }
}

