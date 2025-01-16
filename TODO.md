# TODO

## Core

- [x] Implement adding multiple satellites
- [x] Implement adding multiple celestial bodies
- [ ] Need to figure out how to do floating origin for rendering (and simulations)
      (move origin point to currently viewed object (ie. earth or the any satellite)) to reduce jittering in motion
- [ ] Create add/remove sat/body to system not just array
- [ ] Add celestial body constuctor
  - [ ] compute mass/mu depending on input
  - [ ] compute radii (semimajor, semiminor, mean) based on input
- [x] Add flag to turn on/off attitude/rotational dynamics
- [ ] Separate body/sat update and drawing from system
  - [x] separate updates
  - [ ] separate drawing
- [ ] Profile and speed up simulation
  - [ ] add multi-threading (separate translational and rotational dynamics?)
  - [x] different integrators
- [ ] Add game states (paused, play, restart, etc.)
  - [x] paused
- [ ] Add skip to time function using simulation time (also add loading percentage) 

## Physics/Astrodynamics

- [ ] Add tle reader and parser
- [ ] Add collision detection and resolution
  - [ ] collision detection
    - [ ] add spatial partitioning
  - [ ] collision resolution
    - should the bodies slide/bounce/etc.
    - idk how to do this, so far they have been hitting, sliding, then shooting off
- [ ] Add rotation to celestial bodies?
  - [ ] Initial atittude -> set model rotation matrix, update using fixed rotation speed
  - [ ] Use angle-axis?
- [ ] Add orbit generating functions
  - [ ] classical orbital elements
  - [ ] n-body
- [ ] Add different controllers
- [ ] Add example scenarios
- [ ] Add orbit data monitors
- [x] Add n-body dynamics
  - [x] n-body for satellites
  - [x] n-body for celestial bodies
  - [x] add switch to control which model to use (lowest precision between two bodies, certain bodies may not have zonal spherical harmonic parameters)
- [ ] Add spherical harmonics
- [ ] Implement rotation vector for zonal (not negligible) and spherical harmonics
- [ ] Add Julian date and simulation current time (sim time = 0 at initial JD)

## Visual

- [ ] Add draw axes for celestial bodies
- [x] Add celestial body model color
- [ ] Add visual scaling to models
- [ ] Add ability to change position vector origin
  - [ ] Show available origin targets (bodies and other satellites)
- [x] Add different cameras (inertial/origin, satellite/body, fixed)
  - NOTE: currently only locks, cannot pan
  - [ ] adjust clipping planes dynamically depending on distance to target

## UI/Controls

- [ ] Add UI to be able to spawn new bodies (both celestial and satellite)
  - [ ] Adding new body should pause simulation
  - [ ] add support for rotating frames
  - [ ] add picker for example configurations
- [x] Implement multiple buttons for camera movement

## Misc

- [x] Organize TODO
