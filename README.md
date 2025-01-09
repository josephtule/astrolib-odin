# astrolib-odin

## Library for orbital mechanics and attitude dynamics for spacecraft

## TODO

- [x] Implement adding multiple satellites
- [] Implement adding multiple celestial bodies
- [] Need to figure out how to do floating origin for rendering (and simulations)
  (move origin point to currently viewed object (ie. earth or the any satellite)) to reduce jittering in motion
- [] Add n-body dynamics
  - [] n-body for satellites
  - [x] n-body for celestial bodies
  - [x] add switch to control which model to use (lowest precision between two bodies, certain bodies may not have zonal spherical harmonic parameters)
- [] Add spherical harmonics
- [] Add UI to be able to spawn new bodies (both celestial and satellite)
  - [] Adding new body should pause simulation
  - [] add support for rotating frames
- [] Add different controllers
- [] Implement/fix locked camera view
  - NOTE: currently only locks, cannot pan

## How to Build

1. Install [Odin-lang](https://odin-lang.org/docs/install/)
2. Copy myrlgl.odin into <path_to_odin>/vendor/raylib/rlgl
3. Create a `build` directory in the project root
4. Build and run with
   1. Mac/Linux: `<path_to_odin_binary> run . -out:build/out -o:speed`
   2. Windows: `<path_to_odin_binary> run . -out:build/out.exe -o:speed`
