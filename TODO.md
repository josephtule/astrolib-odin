# TODO

## Core

- [ ] Need to figure out how to do floating origin for rendering (and simulations)
      (move origin point to currently viewed object (ie. earth or the any satellite)) to reduce jittering in motion
- [ ] Add celestial body constuctor
  - [ ] compute mass/mu depending on input
  - [ ] compute radii (semimajor, semiminor, mean) based on input
  - [x] different integrators
- [ ] Add game states (paused, play, restart, etc.)
  - [x] paused
- [ ] Add skip to time function using simulation time (also add loading percentage)
- [ ] Orbits and control will be deterministic so precompute trajectories
  - [ ] precomute then check if system needs to continue computation
- [ ] Spinning/rotating frame (this one is gonna be hard)
  - [ ] set two targets (origin and target) for rotating frame (i.e. earth and moon or sun and earth)
    - [ ] generate rotation matrix for each update using relative position vector in inertial frame
      - [ ] new origin to target is xhat, yhat 90 degrees clockwise (in direction of orbit), zhat creates right hand frame
  - [ ] trails
    - [ ] use relative position for trail, rotate, then add to target body's postion to get inertial coordinates (or is it origin body)
    - [ ] in trail update, use rotation matrix of CURRENT frame to update ALL trail position
    - [x] make trails their own struct
- [ ] Separate the physics parameters (mass, inertia, pos, vel) to separate PhysicsObject struct and tie bodies and satellites (maybe maybe not idk yet)
- [ ] Resetting system should reset global ID?
- [x] Combine satellite and body models
- [ ] Separate translational and rotational physics (separate update frequencies)
- [ ] Implement adaptive step size integrator (for non-simulations)
- [x] Create add/remove sat/body to system not just array
- [x] Implement adding multiple satellites
- [x] Implement adding multiple celestial bodies
- [x] Add flag to turn on/off attitude/rotational dynamics
- [x] Separate body/sat update and drawing from system
  - [x] separate updates
  - [x] separate drawing

## Physics/Astrodynamics

- [x] Add tle reader and parser
  - [x] parse for time only option
  - [ ] simulate satellite back/forward from tle time to system initial time
  - [x] separate satellite generation for tle parsing
    - [x] tle parser returns dynamic array of satellites/models instead
  - [x] tle parser that only returns the date
  - [ ] tle parser that only returns pos/vel
- [ ] Add collision detection and resolution
  - [ ] collision detection
    - [ ] add spatial partitioning
  - [ ] collision resolution
    - should the bodies slide/bounce/etc.
    - idk how to do this, so far they have been hitting, sliding, then shooting off
- [x] Add rotation to celestial bodies? (yes)
  - [x] Initial atittude -> set model rotation matrix, update using fixed rotation speed (low fidelity)
  - [ ] initial attitude -> use model precession, nutation, polar motion (high fidelity, probably not needed with time scales for simulation)
  - [ ] Use angle-axis or dcm
- [ ] Add orbit generating functions
  - [x] classical orbital elements
  - [ ] n-body
- [ ] Add different controllers
- [ ] Add example scenarios
- [ ] Add orbit data monitors (show energy, coes, etc)
- [x] Add n-body dynamics
  - [x] n-body for satellites
  - [x] n-body for celestial bodies
  - [x] add switch to control which model to use (lowest precision between two bodies, certain bodies may not have zonal spherical harmonic parameters)
- [ ] Add spherical harmonics
- [ ] Implement rotation vector for zonal (not negligible) and spherical harmonics
- [ ] Add Julian date and simulation current time (sim time = 0 at initial JD)
  - [x] jd in system
  - [ ] simulation current time
- [x] orbital elements should be adjusted to equatorial plane
- [ ] Generate orbit from observations
  - [x] RA/Dec -> pos function
  - [x] Az/El -> pos function
  - [ ] observations based on observer long/lat/height (geoc and geod) -> equatorial cartesian (rotated to planet) -> inertial cartesian (rotated to inertial frame)
  - [ ] IOD methods
    - [ ] gibbs
    - [ ] herrick-gibbs
    - [ ] gauss
    - [ ] laplace
  - [ ] implement functions that transform from topocentric to equatorial to inertial
- [ ] add remove after collision flag for satellites/bodies
- [ ] Add flag and target id for single body dynamics for wrt target
  - [ ] if single body dynamics chosen, only require target id for gravity source
  - [ ] Add flag to bodies for body to determine if body is a gravity source, otherwise it will act as a satellite (only affected by other bodies but will not affect the other bodies)

## Visual

- [ ] Add draw axes for celestial bodies
- [x] Add celestial body model color
- [ ] Add visual scaling to models
- [ ] Add ability to change position vector origin
  - [ ] Show available origin targets (bodies and other satellites)
- [x] Add different cameras (inertial/origin, satellite/body, fixed)
  - NOTE: currently only locks, cannot pan
  - [ ] adjust clipping planes dynamically depending on distance to target
  - [ ] change azel to degrees
- [x] Move trail, axes, and position vector draws to update_satellite_model
- [ ] Optimize trail update and drawing
- [ ] Move trail length and update rates into satellite model
- [ ] Add change trail length
  - [ ] if trail length updated, dont reset, just append more to the end?
- [ ] add trails, axes, and position vector to celestial bodies
  - [ ] trails
  - [x] axes
  - [ ] position/velocity vector
- [ ] Update render/system info at lower frequencies (causing slowdown right now)
  - [ ] update controls displayed or remove

## Performance

- [ ] Profile and speed up simulation
  - [ ] add multi-threading (separate translational and rotational dynamics?)
    - [ ] satellite and body translation dynamics are decoupled (satellites only depend on bodies and bodies only update at the very end)
- [ ] Move to raw opengl for performance?
- [ ] z-axis jittery in close satellites (i think this might have to do with camera updates)
- [ ] random lag spikes every once in a while (from 2kfps to 300fps)

## UI/Controls

- [ ] Figure out how to do UI lol
  - [ ] use clay?
  - [ ] 3D camera as a viewport
- [ ] Add UI to be able to spawn new bodies (both celestial and satellite)
  - [ ] Adding new body should pause simulation
  - [ ] add support for rotating frames
  - [ ] add picker for example configurations
- [ ] Drop down list of spawned satellites and bodies, select target for camera
- [x] Implement multiple buttons for camera movement
- [ ] Display info of currently target
  - [x] create info struct for satellites
  - [ ] create info struct for celestial bodies
- [ ] Add warning and confirmation to turn off attitude if simulation delta time too high
- [ ] Add left and right shift keys
- [ ] Highlight currently selected entity (body, satellite, station)

## Misc

- [x] Organize TODO
