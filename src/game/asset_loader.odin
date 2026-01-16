package game

import "core:strings"
import "core:fmt"
import "core:time"

Asset :: struct {
    name: string,
    path: string,

    model: ^Model,
    // temp_model: ^Model, // background model being processed.

    scheduled_time: time.Time,
}

AssetStorage :: struct {
    assets_by_name: map[string]^Asset,
    assets_by_src: map[string]^Asset,
}

register_asset :: proc (state: ^GameState, name: string, path: string) -> ^Asset {
    asset := new(Asset)
    asset.name = strings.clone(name)
    asset.path = strings.clone(path)
    state.storage.assets_by_name[asset.name] = asset
    state.storage.assets_by_src[path] = asset

    reload_asset(state, asset)

    return asset
}


find_asset_by_name :: proc (storage: ^AssetStorage, name: string) -> ^Asset {
    return storage.assets_by_name[name]
    
}
find_asset_by_src :: proc (storage: ^AssetStorage, path: string) -> ^Asset {
    return storage.assets_by_src[path]
}

reload_asset :: proc (state: ^GameState, asset: ^Asset) {
    fmt.printfln("Reloading %v from %v", asset.name, asset.path)

    // call model loader to load into memory
    // call renderer to load model into GPU buffers
    if asset.model == nil {
        asset.model = new(Model)
    } else {
        cleanup_model(asset.model)
        // destroy previous model, reuse buffers?
        // at release we won't be reloading assets dynamically since they won't change.
        // we don't have to reuse buffers. (we will need to free them though)
    }
    load_model(asset.path, asset.model)
}

