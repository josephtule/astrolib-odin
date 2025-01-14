# astrolib-odin

## Library for orbital mechanics and attitude dynamics for spacecraft

## Controls (subject to change)

Camera Switching (satellite target, body target, origin): c
Camera Lock: Ctrl+c
Cycle Target: n/Ctrl+n
Zoom into target: Mousewheel up/down
Camera Azimuth/Elevation: w/a/s/d
Toggle Wireframes: tbd
Toggle Axes: tbd

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
- [x] Add different cameras (inertial/origin, satellite/body, fixed)
  - NOTE: currently only locks, cannot pan
  - [ ] adjust clipping planes dynamically depending on distance to target
- [ ] Implement multiple hold for camera movement
- Add orbit generating functions
  - [ ] classical orbital elements
  - [ ] n-body
- [ ] Add orbit data monitors
- [ ] Add example scenarios
- [ ] Add game states (paused, play, restart, etc.)
  - [x] paused
- [ ] Profile and speed up simulation
  - [ ] add multi-threading (separate translational and rotational dynamics?)
  - [x] different integrators
- [ ] Add rotation to celestial bodies?
- [ ] Add flag to turn on/off attitude/rotational dynamics
- [ ] Add draw axes for celestial bodies
- [ ] Add celestial body constuctor
  - [ ] compute mass/mu depending on input
  - [ ] compute radii (semimajor, semiminor, mean) based on input
- [ ] Add tle reader and parser
- [x] Add celestial body model color
- [ ] Add visual scaling to models
- [ ] Add collision detection and resolution
  - [ ] collision detection
    - [ ] add spatial partitioning
  - [ ] collision resolution
    - should the bodies slide/bounce/etc.

## How to Build

1. Install [Odin-lang](https://odin-lang.org/docs/install/)
2. Copy myrlgl.odin into `<path_to_odin>/vendor/raylib/rlgl`
3. Create a `build` directory in the project root
4. Build and run with
   1. Mac/Linux: `<path_to_odin_binary> run . -out:build/out -o:speed`
   2. Windows: `<path_to_odin_binary> run . -out:build/out.exe -o:speed`
