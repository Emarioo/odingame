/*
    TODO: Hotreloading
    TODO: Rendering rectangles
    TODO: Record and store user input
*/

package driver

import "core:fmt"
import "core:dynlib"
import "core:os"
import "core:path/filepath"
import "core:time"

ENABLE_HOTRELOAD :: #config(ENABLE_HOTRELOAD, true)

main :: proc () {
    // fmt.println("Hello, sailor!")
    
    exe_path       := os.args[0]
    fresh_lib_path := filepath.join([]string{ filepath.dir(exe_path), "/game.so"  })
    temp_lib_path  := filepath.join([]string{ filepath.dir(exe_path), "/_game.so" })

    last_modification_time : time.Time
    last_timestamp_check   : time.Time
    func_event             : proc(event: EventKind, data: ^EventData)
    file_info              : os.File_Info
    library                : dynlib.Library
    address                : rawptr
    error                  : os.Errno
    ok                     : bool

    if ENABLE_HOTRELOAD {
        copy_file(fresh_lib_path, temp_lib_path)

        library, ok = dynlib.load_library(temp_lib_path)
        if !ok {
            fmt.eprintln(dynlib.last_error())
            fmt.println("Could not load library", temp_lib_path)
            os.exit(1)
        }
        
        address, ok = dynlib.symbol_address(library, "driver_event")
        if !ok {
            fmt.println("Could not find 'driver_event' in", temp_lib_path)
            os.exit(1)
        }
        func_event = cast(proc(event: EventKind, data: ^EventData)) address


        file_info, error = os.stat(fresh_lib_path)
        assert(error == os.General_Error.None)
        last_modification_time = file_info.modification_time
        last_timestamp_check   = time.now()
        os.file_info_delete(file_info)
    }

    data: EventData
    data.running = true

    func_event(EventKind.EVENT_LOAD, &data)
    func_event(EventKind.EVENT_START, &data)

    // TODO: What about multiple threads?
    for data.running {

        // Detect reload of dll
        if ENABLE_HOTRELOAD {
            now := time.now()
            reload_ms :: 500
            // Check if dynamic library was rebuilt every 500ms
            if time.time_to_unix_nano(now)/1000000 - reload_ms > time.time_to_unix_nano(last_timestamp_check)/1000000 {
                last_timestamp_check = now
                file_info, error = os.stat(fresh_lib_path)
                defer os.file_info_delete(file_info)

                if error == os.General_Error.None && time.time_to_unix_nano(file_info.modification_time) > time.time_to_unix_nano(last_modification_time) {
                    // If it has been rebuilt
                    // - Let game code know it's about to be unloaded
                    // - Unload old library
                    // - Load new library
                    // - Let game code know game code was loaded again

                    last_modification_time = file_info.modification_time
                    
                    func_event(EventKind.EVENT_UNLOAD, &data)

                    ok = dynlib.unload_library(library)
                    if !ok {
                        fmt.println("Could not unload library", temp_lib_path)
                        os.exit(1)
                    }

                    copy_file(fresh_lib_path, temp_lib_path)
                    
                    library, ok = dynlib.load_library(temp_lib_path)
                    if !ok {
                        fmt.println("Could not load library", temp_lib_path)
                        os.exit(1)
                    }
                    
                    address, ok = dynlib.symbol_address(library, "driver_event")
                    if !ok {
                        fmt.println("Could not find 'driver_event' in", temp_lib_path)
                        os.exit(1)
                    }
                    func_event := cast(proc(event: EventKind, data: ^EventData)) address

                    func_event(EventKind.EVENT_LOAD, &data)
                }
            }
        }
        
        // Tick update
        func_event(EventKind.EVENT_TICK, &data)
    }

    func_event(EventKind.EVENT_STOP, &data)
    func_event(EventKind.EVENT_UNLOAD, &data)
}

copy_file :: proc(src_path, dst_path: string) -> bool {
    src, ok := os.open(src_path, os.O_RDONLY)
    if ok != os.General_Error.None {
        fmt.println("Failed to open source file")
        return false
    }
    defer os.close(src)

    dst: os.Handle
    dst, ok = os.open(dst_path, os.O_CREATE | os.O_TRUNC | os.O_WRONLY, 0o777)
    if ok != os.General_Error.None {
        fmt.println("Failed to create destination file")
        return false
    }
    defer os.close(dst)

    buf: [4096]u8
    for {
        bytes_read, read_ok := os.read(src, buf[:])
        if bytes_read == 0 || read_ok != os.General_Error.None {
            break
        }

        bytes_written, write_ok := os.write(dst, buf[:bytes_read])
        if write_ok != os.General_Error.None {
            fmt.println("Write failed")
            return false
        }
    }

    return true
}