package astrolib

import am "../astromath"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

AstroSystem :: struct {
	satellites:       [dynamic]Satellite,
	satellite_models: [dynamic]SatelliteModel,
	bodies:           [dynamic]CelestialBody,
	body_models:      [dynamic]CelestialBodyModel,
	integrator:       am.IntegratorType,
}

update_system :: proc(system: ^AstroSystem, dt, cum_time: f64) {
	// TODO: finish this

	// update satellites first


	// update celestial bodies
	// store celestial body current positions
	// rk4 based on old positions

}
