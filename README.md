Game made in odin?

![](/docs/img/screenshot-2026-01-18.png)
**I DO NOT OWN THE MODEL IN THE IMAGE, it is Iuno from Wuthering Waves**

# Dev features
- Code, model, texture, shader hot-reloading

# Building
**Dependencies**
- Odin
- Clang (odin uses clang?)
- GLFW
- OpenGL
- cgltf
- stb_image

Odin provides **GLFW** and **OpenGL bindings** for Windows and Linux.
It also has cgltf and stb_image but on Linux you will need to build them yourself (binaries not provided automatically).

Build and run the game:
```bash
build.py run
```

The game folder can be found in: releases/odingame-0.0.1-windows-x86_64/odingame.exe

## IMPORTANT
Use the latest odin. There is a bug with global variable for environment variables that causes crash when using dlls which we are with hotreloading.