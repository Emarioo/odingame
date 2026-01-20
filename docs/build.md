
Build system

```bash
./build.py
```

This will
1. Generate runtime assets from source assets (export from .kra, .blend files)
2. Compile game code


The driver can detect updated source assets and game code and automatically recompile.


# Repository structure
```
releases
    odingame-0.1.3-windows-x86_64
        ...
art                         - Raw art sources for the game
assets                      - Exported models, textures, for the game
docs 
lib/libs/extern             - Third-party code.
src                         - Source code
    driver
        main.odin           - entry point
    engine
        input
        rendering
    game
        magic
tools                       - Build-system scripts
    fetch_dependencies.py
build.py                    - Main build script, may call into tools
```

# Distributed structure

```
odingame-0.1.3-windows-x86_64
    odingame.exe
    glfw3.dll
    stb_image.dll
    cgltf.dll
    settings.txt
    assets
        models
            tree.glb
        shaders
            object.glsl
        textures
            splash.png
    mods
        minimap
            minimap.dll
            settings.txt
            assets
                textures
                    waypoint.png
    data
        world.data
```