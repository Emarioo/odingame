#!/usr/bin/env python3

import os, sys, subprocess, shlex


def main():
    hotreload = False

    if "hot" in sys.argv:
        hotreload = True

    os.makedirs("bin", exist_ok=True)
    run("odin build src/game -debug -define:GLFW_SHARED=true -build-mode:shared -out:bin/game.so")
    if not hotreload:
        run("odin run src/driver -debug -out:bin/driver")

def run(cmd):
    res = os.system(cmd) >> 8
    if res != 0:
        exit(1)

if __name__ == "__main__":
    main()