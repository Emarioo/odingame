#!/usr/bin/env python3

import os, sys, subprocess, shlex, platform, shutil, glob


def main():
    hotreload = False

    if "hot" in sys.argv:
        hotreload = True

    if not has_assimp():
        build_assimp()

    # TODO: On Linux i think we might be hardcoding the glfw3.dll path?
    proc = subprocess.run(["odin", "root"], text=True, stdout=subprocess.PIPE)
    odin_path = proc.stdout
    # Use different path on linux

    ROOT = os.path.dirname(__file__)
    OS = platform.system().lower()
    LIB_DIR = f"{ROOT}/lib/assimp/{OS}"

    if platform.system() == "Windows":
        glfw_path = f"{odin_path}vendor\\glfw\\lib\\glfw3.dll"
        assimp_path_dll = glob.glob(f"{LIB_DIR}/shared/assimp*.dll")
        if len(assimp_path_dll) > 0:
            assimp_path = assimp_path_dll[0]
            assimp_path_pdb = glob.glob(f"{LIB_DIR}/shared/assimp*.pdb")[0]
            try:
                shutil.copy(assimp_path, f"bin/{os.path.basename(assimp_path)}")
                shutil.copy(assimp_path_pdb, f"bin/{os.path.basename(assimp_path_pdb)}")
            except:
                pass # we assume dll is in use
        try:
            shutil.copy(glfw_path, "bin/glfw3.dll")
        except:
                pass # we assume dll is in use
    else:
        # take glfw from system path?
        # glfw_path = f"{odin_path}vendor/glfw/lib/glfw3.so"
        assimp_path = f"{LIB_DIR}/libassimp.so"
        try:
            shutil.copy(assimp_path, f"bin/{os.path.basename(assimp_path)}.6")
        except:
            pass # we assume dll is in use
        # try:
        #     shutil.copy(glfw_path, "bin/libglfw3.so")
        # except:
        #         pass # we assume dll is in use

    odin_flags = f"-collection:lib=lib -debug -o:none"

    os.makedirs("bin", exist_ok=True)
    if platform.system() == "Windows":
        run(f"odin build src/game {odin_flags} -define:GLFW_SHARED=true -define:ASSIMP_SHARED=true -build-mode:dynamic -out:{os.path.join('bin','game.dll')}")
        if not hotreload:
            run(f"odin run src/driver -keep-executable {odin_flags} -out:{os.path.join('bin','driver.exe')}")
    else:
        run(f"odin build src/game {odin_flags} -define:GLFW_SHARED=true -define:ASSIMP_SHARED=true -build-mode:shared -out:{os.path.join('bin','game.so')}")
        if not hotreload:
            run(f"odin run src/driver {odin_flags} -out:{os.path.join('bin','driver')}")


def has_assimp():
    ROOT = os.path.dirname(__file__)
    OS = platform.system().lower()
    LIB_DIR = f"{ROOT}/lib/assimp/{OS}"
    if platform.system() == "Windows":
        return ( len(glob.glob(f"{LIB_DIR}/shared/assimp*.dll")) > 0 and
                 len(glob.glob(f"{LIB_DIR}/shared/assimp*dll.lib")) > 0 and 
                 len(glob.glob(f"{LIB_DIR}/static/assimp*.lib")) > 0 )
    else:
        return ( os.path.exists(f"{LIB_DIR}/libassimp.so") and
                 os.path.exists(f"{LIB_DIR}/libassimp.a") )


def build_assimp():
    ROOT = os.path.dirname(__file__)
    os.chdir(ROOT)

    os.makedirs("extern", exist_ok=True)
    os.chdir("extern")

    if not os.path.exists("assimp"):
        run("git clone --depth 1 --branch v6.0.2 https://github.com/assimp/assimp")
    else:
        # if we have the extern/assimp directory we assume it's been cloned properly
        pass

    os.chdir("assimp")
    OS = platform.system().lower()
    LIB_DIR = f"{ROOT}/lib/assimp/{OS}"
    os.makedirs(f"{LIB_DIR}", exist_ok=True)
    if platform.system() == "Windows":
        os.makedirs(f"{LIB_DIR}/static", exist_ok=True)
        os.makedirs(f"{LIB_DIR}/shared", exist_ok=True)

    os.makedirs("build", exist_ok=True)

    run("cmake CMakeLists.txt -DBUILD_SHARED_LIBS=ON -DASSIMP_BUILD_ZLIB=ON -DASSIMP_BUILD_TESTS=OFF")
    run("cmake --build . --parallel 16")

    # # Windows has shared and static sub dirs to keep the dll .pdb and lib .pdb separate (since we can't rename them)

    if platform.system() == "Windows":
        print(os.getcwd())
        for dll in glob.glob("bin/*/assimp*.dll"):
            shutil.copy(dll, f"{LIB_DIR}/shared/{os.path.basename(dll)}")
            break
        for dll in glob.glob("bin/*/assimp*.pdb"):
            shutil.copy(dll, f"{LIB_DIR}/shared/{os.path.basename(dll)}")
            break
        for dll in glob.glob("lib/*/assimp*.lib"):
            shutil.copy(dll, f"{LIB_DIR}/shared/{os.path.basename(dll)}".replace(".lib","dll.lib"))
            break
    else:
        for dll in glob.glob("bin/libassimp*.so"):
            shutil.copy(dll, f"{ROOT}/lib/assimp/{OS}/libassimp.so")
            break

    run("cmake CMakeLists.txt -DBUILD_SHARED_LIBS=OFF -DASSIMP_BUILD_ZLIB=ON -DASSIMP_BUILD_TESTS=OFF")
    run("cmake --build . --parallel 16")
    
    if platform.system() == "Windows":
        for dll in glob.glob("lib/*/assimp*.lib"):
            shutil.copy(dll, f"{LIB_DIR}/static/{os.path.basename(dll)}")
            break
        for dll in glob.glob("lib/*/assimp*.pdb"):
            shutil.copy(dll, f"{LIB_DIR}/static/{os.path.basename(dll)}")
            break
    else:
        for dll in glob.glob("lib/libassimp*.a"):
            shutil.copy(dll, f"{LIB_DIR}/libassimp.a")
            break

    os.chdir(ROOT)

def run(cmd):
    # print(cmd)
    if platform.system() == "Linux":
        res = os.system(cmd) >> 8
    else:
        res = os.system(cmd)
    if res != 0:
        print(f"failed: {cmd}")
        exit(1)

if __name__ == "__main__":
    main()