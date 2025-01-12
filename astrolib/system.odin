package astrolib

import am "../astromath"
import ode "../ode"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

AstroSystem :: struct {
	// satellites
	satellites:       [dynamic]Satellite,
	satellite_models: [dynamic]SatelliteModel,
	// satellite_odeparams: [dynamic]rawptr,
	// bodies
	bodies:           [dynamic]CelestialBody,
	body_models:      [dynamic]CelestialBodyModel,
	// body_odeparams:      [dynamic]rawptr,
	// integrator
	integrator:       am.IntegratorType,
	time_scale:       f64,
}

update_system :: proc(system: ^AstroSystem, dt, time: f64) {
	using system
	N_sats := len(satellites)
	N_bodies := len(bodies)

	// update satellites first
	state_new_sat: [dynamic][6]f64
	for sat, i in satellites {
		for body, j in bodies {
			rel_pos := sat.pos - body.pos
			rel_vel := sat.vel - body.vel
			state_current := am.posvel_to_state(rel_pos, rel_vel)

			// determine which gravity model to use
			lowest_model: ode.GravityModel = min(sat.gravity_model, body.gravity_model)

			switch lowest_model {
			case .pointmass:
				// update params
				// sat_params := cast(^ode.Params_Gravity_Pointmass)satellite_odeparams[i]
				// sat_params.mu = body.mu
				sat_params := ode.Params_Gravity_Pointmass {
					mu = body.mu,
				}

				_, state_new := am.integrate(
					ode.gravity_pointmass,
					time,
					state_current,
					dt * time_scale,
					&sat_params,
					integrator,
				)
			case .zonal:
				// update params
				// sat_params := cast(^ode.Params_Gravity_SphHarmon)satellite_odeparams[i]
				// sat_params.mu = body.mu
				// sat_params.J = body.J
				// sat_params.max_degree = body.max_degree
				// sat_params.R_cb = body.semimajor_axis
				sat_params := ode.Params_Gravity_SphHarmon {
					mu         = body.mu,
					J          = body.J,
					R_cb       = body.semimajor_axis,
					max_degree = body.max_degree,
				}

				_, state_new := am.integrate(
					ode.gravity_zonal,
					time,
					state_current,
					dt * time_scale,
					&sat_params,
					integrator,
				)
			case .spherical_harmonic:
				panic("ERROR: Spherical harmonics gravity has not been implemented yet")
			case:
				panic("ERROR: invalid gravity model for celestial body")
			}
		}
	}

	// update celestial bodies
	// store celestial body current positions
	// rk4 based on old positions
	state_new_body: [dynamic][6]f64
	for body, i in bodies {
		// update body i
		for other, j in bodies {
			if i != j {
				// get relative position
				rel_pos := body.pos - other.pos
				rel_vel := body.vel - other.vel
				state_current := am.posvel_to_state(rel_pos, rel_vel)

				lowest_model: ode.GravityModel = min(
					body.gravity_model,
					other.gravity_model,
				)

				switch lowest_model {
				case .pointmass:
					// update params
					// body_params := cast(^ode.Params_Gravity_Pointmass)body_odeparams[i]
					// body_params.mu = other.mu

					body_params := ode.Params_Gravity_Pointmass {
						mu = body.mu,
					}

					_, state_temp := am.integrate(
						ode.gravity_pointmass,
						time,
						state_current,
						dt * time_scale,
						&body_params,
						integrator,
					)
					append_elem(&state_new_body, state_temp)
				case .zonal:
					// update params
					// body_params := cast(^ode.Params_Gravity_SphHarmon)body_odeparams[i]
					// body_params.mu = other.mu
					// body_params.J = other.J
					// body_params.max_degree = other.max_degree
					// body_params.R_cb = other.semimajor_axis

					body_params := ode.Params_Gravity_SphHarmon {
						mu         = other.mu,
						J          = other.J,
						R_cb       = other.semimajor_axis,
						max_degree = other.max_degree,
					}

					_, state_temp := am.integrate(
						ode.gravity_zonal,
						time,
						state_current,
						dt * time_scale,
						&body_params,
						integrator,
					)
					append_elem(&state_new_body, state_temp)

				case .spherical_harmonic:
					panic("ERROR: Spherical harmonics gravity has not been implemented yet")
				case:
					panic("ERROR: invalid gravity model for celestial body")
				}


			}
		}
	}

	for i := 0; i < N_bodies; i += 1 {
		// assign new states after computing
		bodies[i].pos, bodies[i].vel = am.state_to_posvel(state_new_body[i])
	}


}

// draw_system :: proc(system: ^Astrosystem) {}
