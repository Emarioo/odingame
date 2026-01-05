{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell rec {
  buildInputs = [
    pkgs.glfw
    pkgs.mesa
    pkgs.libGL
    pkgs.libglvnd
    pkgs.libdecor
    pkgs.gtk3
    pkgs.clang
    # pkgs.assimp
  ];

  # @TODO DO NOT HARDCODE PATH LIKE THIS!
  shellHook = "export PATH=$PATH:/home/emarioo/dev/vendor/odin";
  # nativeBuildInputs = [ pkgs.cmake ];

#    shellHook = ''
    # export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri
    # export LD_LIBRARY_PATH=${pkgs.libGL}/lib:${pkgs.libglvnd}/lib:$LD_LIBRARY_PATH
#   '';
}