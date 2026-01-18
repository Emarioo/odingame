package engine

import "core:strings"
import "core:fmt"
import "core:time"
import "core:sync"
import "core:path/filepath"
import "../util"

AssetStatus :: enum {
    NEEDS_MAIN_PROCESSING,
    NEEDS_RENDER_PROCESSING,
    CAN_BE_RENDERED,
}

AssetType :: enum {
    MODEL,
    SHADER,
}

Asset :: struct {
    name: string,
    path: string,

    type: AssetType,
    status: AssetStatus,
    scheduled_time: time.Time,

    model: ^Model,
    wip_model: ^Model, // background model being processed.

    shader: ^Shader,
    wip_shader: ^Shader,

}

AssetStorage :: struct {
    assets_by_name: map[string]^Asset,
    assets_by_src:  map[string]^Asset,
    game_directory: string,
    
    scheduled_main:         [dynamic]^Asset,
    scheduled_main_mutex:   sync.Mutex,
    scheduled_render:       [dynamic]^Asset,
    scheduled_render_mutex: sync.Mutex,

    art_watcher: util.Watcher,
}

register_asset_from_store :: proc (state: ^EngineState, name: string, rel_path: string) -> ^Asset {
    strings.concatenate({state.storage.game_directory, "/assets/", rel_path})
    return register_asset(state, name, rel_path)
}
register_asset :: proc (state: ^EngineState, name: string, path: string) -> ^Asset {
    fmt.printfln("Register %v", path)
    asset := new(Asset)
    asset.name = strings.clone(name)
    asset.path = strings.clone(path)
    // @TODO Check that the asset doesn't exist (path and name?)
    state.storage.assets_by_name[asset.name] = asset
    state.storage.assets_by_src[path] = asset

    switch filepath.ext(path) {
        case ".glsl":
            asset.type   = .SHADER
            asset.status = .NEEDS_RENDER_PROCESSING
            sync.lock(&state.storage.scheduled_render_mutex)
            append(&state.storage.scheduled_render, asset)
            sync.unlock(&state.storage.scheduled_render_mutex)
        case ".glb":
            asset.type   = .MODEL
            asset.status = .NEEDS_MAIN_PROCESSING
            sync.lock(&state.storage.scheduled_main_mutex)
            append(&state.storage.scheduled_main, asset)
            sync.unlock(&state.storage.scheduled_main_mutex)
    }


    return asset
}

can_be_reloaded :: proc (asset: ^Asset) -> bool {
    return asset.status == .CAN_BE_RENDERED
}


find_asset_by_name :: proc (storage: ^AssetStorage, name: string) -> ^Asset {
    return storage.assets_by_name[name]
    
}
find_asset_by_src :: proc (storage: ^AssetStorage, path: string) -> ^Asset {
    return storage.assets_by_src[path]
}

reload_asset :: proc (state: ^EngineState, asset: ^Asset) {
    // Here we assume two threads can't reload an asset at the same time.
    // Race condition if this happens.
    if asset.status != .CAN_BE_RENDERED {
        fmt.printfln("Submit reload (already reloading) %v from %v", asset.name, asset.path)
        return
    }
    fmt.printfln("Submit reload %v from %v", asset.name, asset.path)

    switch asset.type {
        case .MODEL:
            asset.status = .NEEDS_MAIN_PROCESSING
            sync.lock(&state.storage.scheduled_main_mutex)
            append(&state.storage.scheduled_main, asset)
            sync.unlock(&state.storage.scheduled_main_mutex)
        case .SHADER:
            asset.status = .NEEDS_RENDER_PROCESSING
            sync.lock(&state.storage.scheduled_render_mutex)
            append(&state.storage.scheduled_render, asset)
            sync.unlock(&state.storage.scheduled_render_mutex)

    }
}


process_asset_main :: proc (state: ^EngineState, asset: ^Asset) {
    // caller needs to change state and lock asset schedule arrays
    fmt.printfln("Process (main) %v", asset.path)
    

    switch asset.type {
        case .MODEL:
            if asset.wip_model == nil {
                asset.wip_model = new(Model)
            }
            load_model(asset.path, asset.wip_model)
        case .SHADER:
            fmt.printfln("ASSET SHADER WAS ADDED TO MAIN PROCESSING! %v", asset.name, asset.path)
    }
}


process_asset_render :: proc (state: ^EngineState, asset: ^Asset) {
    fmt.printfln("Process (render) %v", asset.path)

    switch asset.type {
        case .MODEL:
            load_model_render(asset.wip_model)
            tmp := asset.model
            asset.model = asset.wip_model
            asset.wip_model = tmp
        case .SHADER:
            if asset.wip_shader == nil {
                asset.wip_shader = new(Shader)
            }
            load_shader(asset.path, asset.wip_shader)
            tmp := asset.shader
            asset.shader = asset.wip_shader
            asset.wip_shader = tmp
    }

}

