# astrolib-odin

## Library for orbital mechanics and attitude dynamics for spacecraft

## Controls


## TODO

- [x] Implement adding multiple satellites
- [x] Implement adding multiple celestial bodies
- [ ] Need to figure out how to do floating origin for rendering (and simulations)
  (move origin point to currently viewed object (ie. earth or the any satellite)) to reduce jittering in motion
- [x] Add n-body dynamics
  - [x] n-body for satellites
  - [x] n-body for celestial bodies
  - [x] add switch to control which model to use (lowest precision between two bodies, certain bodies may not have zonal spherical harmonic parameters)
- [ ] Add spherical harmonics
- [ ] Implement rotation vector for zonal (not negligible) and spherical harmonics
- [ ] Add UI to be able to spawn new bodies (both celestial and satellite)
  - [ ] Adding new body should pause simulation
  - [ ] add support for rotating frames
  - [ ] add picker for example configurations 
- [ ] Add different controllers
- [ ] Add different cameras (inertial/origin, satellite/body, fixed)
  - NOTE: currently only locks, cannot pan
  - [ ] adjust clipping planes dynamically depending on distance
- [ ] Implement multiple hold for camera movement
- Add orbit generating functions
  - [ ] classical orbital elements
  - [ ] n-body
- [ ] Add orbit data monitors
- [ ] Add example scenarios
- [ ] Add game states (paused, play, restart, etc.)
- [ ] Profile and speed up simulation
  - [ ] add multi-threading (separate translational and rotational dynamics?)
  - [ ] 

## How to Build

1. Install [Odin-lang](https://odin-lang.org/docs/install/)
2. Copy myrlgl.odin into ```<path_to_odin>/vendor/raylib/rlgl```
3. Create a `build` directory in the project root
4. Build and run with
   1. Mac/Linux: `<path_to_odin_binary> run . -out:build/out -o:speed`
   2. Windows: `<path_to_odin_binary> run . -out:build/out.exe -o:speed`