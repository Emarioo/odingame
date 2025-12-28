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

  # nativeBuildInputs = [ pkgs.cmake ];

#    shellHook = ''
    # export LIBGL_DRIVERS_PATH=${pkgs.mesa}/lib/dri
    # export LD_LIBRARY_PATH=${pkgs.libGL}/lib:${pkgs.libglvnd}/lib:$LD_LIBRARY_PATH
#   '';
}