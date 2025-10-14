Game made in odin?

# Code features
- Hotreloading

# Building
**Dependencies**
- Odin
- GLFW
- OpenGL
- Assimp

Odin provides **GLFW** and **OpenGL** for Windows and Linux.
You will have to build Assimp yourself though.
Put Assimp binaries (.so,.dll,.lib,.a) in `lib/assimp/windows` or `lib/assimp/linux`.
You may need to change the names, tweak some scripts, fix assimp build problems.


Build game with
```bash
./build.py
bin/driver
```
