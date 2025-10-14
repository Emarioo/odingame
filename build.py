#!/usr/bin/env python3

import os, sys, subprocess, shlex, platform, shutil


def main():
    hotreload = False

    if "hot" in sys.argv:
        hotreload = True

    # TODO: On Linux i think we might be hardcoding the glfw3.dll path?
    proc = subprocess.run(["odin", "root"], text=True, stdout=subprocess.PIPE)
    odin_path = proc.stdout
    # Use different path on linux
    glfw_path = f"{odin_path}vendor\\glfw\\lib\\glfw3.dll"
    assimp_path = f"lib\\assimp\\windows\\assimp-vc143-mtd.dll"
    shutil.copy(glfw_path, "bin/glfw3.dll")
    shutil.copy(assimp_path, "bin/assimp-vc143-mtd.dll")

    odin_flags = f"-collection:lib=lib -debug -o:none"

    os.makedirs("bin", exist_ok=True)
    if platform.system() == "Windows":
        run(f"odin build src/game {odin_flags} -define:GLFW_SHARED=true -build-mode:dynamic -out:{os.path.join('bin','game.dll')}")
        if not hotreload:
            run(f"odin run src/driver -keep-executable {odin_flags} -out:{os.path.join('bin','driver.exe')}")
    else:
        run(f"odin build src/game {odin_flags} -define:GLFW_SHARED=true -build-mode:shared -out:{os.path.join('bin','game.so')}")
        if not hotreload:
            run(f"odin run src/driver -keep-executable {odin_flags} -out:{os.path.join('bin','driver')}")

def run(cmd):
    if platform.system() == "Linux":
        res = os.system(cmd) >> 8
    else:
        res = os.system(cmd)
    if res != 0:
        exit(1)

if __name__ == "__main__":
    main()