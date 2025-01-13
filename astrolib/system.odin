package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"
import "core:thread"
import "core:sync"

import ast "../astrolib"
import am "../astromath"



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
	for &sat, i in satellites {
		// attitude dynamics
		attitude_params := Params_EulerParam {
			inertia = sat.inertia,
			torque  = {0, 0, 0}, // NOTE: no control for now
		}
		attitude_current := am.epomega_to_state(sat.ep, sat.omega)
		_, attitude_new := am.integrate(
			euler_param_dyanmics,
			time,
			attitude_current,
			dt * time_scale,
			&attitude_params,
			integrator,
		)
		sat.ep, sat.omega = am.state_to_epomega(attitude_new)

		// translational dynamics
		sat_params := Params_Gravity_Nbody {
			bodies        = &system.bodies,
			gravity_model = sat.gravity_model,
			idx           = -1,
		}
		state_current := am.posvel_to_state(sat.pos, sat.vel)
		_, state_new := am.integrate(
			ast.gravity_nbody,
			time,
			state_current,
			dt * time_scale,
			&sat_params,
			integrator,
		)
		sat.pos, sat.vel = am.state_to_posvel(state_new)
	}

	// update celestial bodies
	// store celestial body current positions
	// rk4 based on old positions
	state_new_body := make([dynamic][6]f64, len(bodies))
	for body, i in bodies {
		sat_params := Params_Gravity_Nbody {
			bodies        = &system.bodies,
			gravity_model = body.gravity_model,
			idx           = i,
		}
		// FIXME: fix this, currently returning NaN
		state_current := am.posvel_to_state(body.pos, body.vel)
		_, state_new_body[i] = am.integrate(
			ast.gravity_nbody,
			time,
			state_current,
			dt * time_scale,
			&sat_params,
			integrator,
		)

	}

	for i := 0; i < N_bodies; i += 1 {
		// assign new states after computing
		bodies[i].pos, bodies[i].vel = am.state_to_posvel(state_new_body[i])
	}


}


draw_system :: proc(system: ^AstroSystem, u_to_rl: f32 = u_to_rl) {
	using system
	// satellite models
	for sat, i in satellites {
		q := am.euler_param_to_quaternion(la.array_cast(sat.ep, f32))
		rot := rl.QuaternionToMatrix(q)
		sat_pos_f32 := la.array_cast(sat.pos, f32) * u_to_rl
		satellite_models[i].model.transform = rot
		am.SetTranslation(&satellite_models[i].model.transform, sat_pos_f32)

		rl.DrawModel(satellite_models[i].model, am.origin_f32, 1, rl.WHITE)

		if satellite_models[i].draw_axes {
			R := am.GetRotation(satellite_models[i].model.transform)
			cube_size := min(
				satellite_models[i].model_size[0],
				min(satellite_models[i].model_size[1], satellite_models[i].model_size[2]),
			)
			x_axis := R * (am.xaxis_f32 * cube_size * 10)
			y_axis := R * (am.yaxis_f32 * cube_size * 10)
			z_axis := R * (am.zaxis_f32 * cube_size * 10)

			rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + x_axis, rl.MAGENTA)
			rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + y_axis, rl.YELLOW)
			rl.DrawLine3D(
				sat_pos_f32,
				sat_pos_f32 + z_axis,
				rl.Color({0, 255, 255, 255}),
			)
		}

		if satellite_models[i].draw_trail {
			// update and draw trails
		}
	}

	// celestial body models
	for body, i in bodies {
		am.SetTranslation(
			&body_models[i].model.transform,
			la.array_cast(body.pos, f32) * u_to_rl,
		)

		rl.DrawModel(body_models[i].model, am.origin_f32, 1, rl.WHITE)

		if body_models[i].draw_trail {
			// update and draw trails
		}
	}
}


update_trail :: proc() {}
