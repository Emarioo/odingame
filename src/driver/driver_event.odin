package driver

EventKind :: enum {
    EVENT_START,  // called after the first load
    EVENT_LOAD,
    EVENT_TICK,
    EVENT_UNLOAD,
    EVENT_STOP    // called before the final unload
}


EventData :: struct {
    running: bool,
    user_data: rawptr
}