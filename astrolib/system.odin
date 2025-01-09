package astrolib

import am "../astromath"
import ode "../ode"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"
AstroSystem :: struct {
	// satellites
	satellites:          [dynamic]Satellite,
	satellite_models:    [dynamic]SatelliteModel,
	satellite_odeparams: [dynamic]rawptr,
	satellite_gravmodel: [dynamic]ode.GravityModel,
	// bodies
	bodies:              [dynamic]CelestialBody,
	body_models:         [dynamic]CelestialBodyModel,
	body_odeparams:      [dynamic]rawptr,
	body_gravmodel:      [dynamic]ode.GravityModel,
	// integrator
	integrator:          am.IntegratorType,
	time_scale:          f64,
}

update_system :: proc(system: ^AstroSystem, dt, time: f64) {
	using system
	// TODO: finish this
	N_sats := len(satellites)
	N_bodies := len(bodies)

	// update satellites first
	for i := 0; i < N_sats; i += 1 {

	}

	// update celestial bodies
	// store celestial body current positions
	// rk4 based on old positions
	state_new: [dynamic][6]f64
	for i := 0; i < N_bodies; i += 1 {
		// update body i
		body := bodies[i]
		for j := 0; j < N_bodies; j += 1 {
			if i != j {
				// get relative position
				other := bodies[j]
				rel_pos := body.pos - other.pos
				state_current := am.posvel_to_state(rel_pos, [3]f64{0., 0., 0.})

				switch body_gravmodel[i] {
				case .pointmass:
					// update params
					body_params := cast(^ode.Params_Gravity_Pointmass)body_odeparams[i]
					body_params.mu = other.mu

					_, state_new[i] = am.rk4_step(
						ode.gravity_pointmass,
						time,
						state_current,
						dt * time_scale,
						body_params,
					)
				case .zonal:
					// update params
					body_params := cast(^ode.Params_Gravity_Zonal)body_odeparams[i]
					body_params.mu = other.mu
					body_params.J = other.J
					body_params.max_degree = other.max_degree
					body_params.R_cb = other.semimajor_axis

					_, state_new[i] = am.rk4_step(
						ode.gravity_zonal,
						time,
						state_current,
						dt * time_scale,
						&body_odeparams[i],
					)
				case .spherical_harmonic:
				case:
					panic("ERROR: invalid gravity model for celestial body")
				}


			}
		}
	}

	for i := 0; i < N_bodies; i += 1 {
		// assign new states after computing
	}


}

// draw_system :: proc(system: ^Astrosystem) {}
