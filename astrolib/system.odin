package astrolib

import ast "../astrolib"
import am "../astromath"

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:slice"
import "core:sync"
import "core:thread"
import rl "vendor:raylib"


AstroSystem :: struct {
	// entity ids 
	id:               map[int]int, // maps id to index 
	// satellites
	satellites:       [dynamic]Satellite,
	satellite_models: [dynamic]SatelliteModel,
	num_satellites:   int,
	// satellite_odeparams: [dynamic]rawptr,
	// bodies
	bodies:           [dynamic]CelestialBody,
	body_models:      [dynamic]CelestialBodyModel,
	num_bodies:       int,
	// body_odeparams:      [dynamic]rawptr,
	// integrator
	integrator:       am.IntegratorType,
	time_scale:       f64,
	substeps:         int,
	simulate:         bool,
	JD0:              f64,
}


update_system :: proc(system: ^AstroSystem, dt, time: f64) {
	using system
	N_sats := len(satellites)
	N_bodies := len(bodies)

	// update satellites first
	for &sat, i in satellites {
		// gen params
		params_attitude := Params_EulerParam {
			inertia = sat.inertia,
			torque  = {0, 0, 0}, // NOTE: no control for now
		}
		params_translate := Params_Gravity_Nbody {
			bodies        = &system.bodies,
			self_mass     = sat.mass,
			self_radius   = sat.radius,
			gravity_model = sat.gravity_model,
			idx           = -1,
		}
		update_satellite(
			&sat,
			&satellite_models[i],
			dt,
			time,
			time_scale,
			integrator,
			&params_translate,
			&params_attitude,
		)
	}

	// update celestial bodies
	// store celestial body current positions
	// rk4 based on old positions
	state_new_body := make([dynamic][6]f64, len(bodies))
	for &body, i in bodies {
		params_translate := Params_Gravity_Nbody {
			bodies        = &system.bodies,
			gravity_model = body.gravity_model,
			idx           = i,
			self_radius   = body.semimajor_axis,
			self_mass     = body.mass,
		}
		params_attitude := Params_BodyAttitude{}
		update_body(
			&body,
			&body_models[i],
			&state_new_body[i],
			dt,
			time,
			time_scale,
			integrator,
			&params_translate,
			&params_attitude,
		)
	}
	for i := 0; i < N_bodies; i += 1 {
		// assign new states after computing
		if !bodies[i].fixed {
			bodies[i].pos, bodies[i].vel = am.state_to_posvel(state_new_body[i])
		}
	}
}

// draw_posvec :: proc(system: AstroSystem, )

draw_system :: proc(system: ^AstroSystem, u_to_rl: f32 = u_to_rl) {
	using system
	// satellite models
	for &model, i in satellite_models {
		update_satellite_model(&model, satellites[i])
		sat_pos_f32 := la.array_cast(satellites[i].pos, f32) * u_to_rl

		rl.DrawModel(model.model, am.origin_f32, 1, model.tint)

		if model.draw_axes {
			if satellites[i].update_attitude {
				R := am.GetRotation(model.model.transform)
				model.local_axes[0] = R * (am.xaxis_f32 * f32(satellites[i].radius) * 10)
				model.local_axes[1] = R * (am.yaxis_f32 * f32(satellites[i].radius) * 10)
				model.local_axes[2] = R * (am.zaxis_f32 * f32(satellites[i].radius) * 10)
			}

			// cmy colors for axes
			rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + model.local_axes[0], rl.MAGENTA)
			rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + model.local_axes[1], rl.YELLOW)
			rl.DrawLine3D(
				sat_pos_f32,
				sat_pos_f32 + model.local_axes[2],
				rl.Color({0, 255, 255, 255}),
			)
		}
		if model.trail.draw{
			draw_trail(satellite_models[i])
		}

		// line from origin to satellite
		if model.draw_pos {
			ind: int
			if model.target_id >= g_body_id_base {
				// target is a body
				ind = system.id[model.target_id]
				model.target_origin = am.cast_f32(bodies[ind].pos) * u_to_rl
			} else {
				// target is satellite
				ind = system.id[model.target_id]
				model.target_origin = am.cast_f32(satellites[ind].pos) * u_to_rl
			}
			// model.target_origin = am.cast_f32()
			rl.DrawLine3D(
				model.target_origin,
				la.array_cast(satellites[i].pos, f32) * u_to_rl,
				rl.GOLD,
			)
		}
	}

	// celestial body models
	for body, i in bodies {
		am.SetTranslation(
			&body_models[i].model.transform,
			la.array_cast(body.pos, f32) * u_to_rl,
		)

		rl.DrawModel(body_models[i].model, am.origin_f32, 1, body_models[i].tint)

		if body_models[i].trail.draw {
			// update and draw trails
		}
	}
}

create_system :: proc(
	sats: [dynamic]Satellite,
	sat_models: [dynamic]SatelliteModel,
	bodies: [dynamic]CelestialBody,
	body_models: [dynamic]CelestialBodyModel,
	// defaults
	JD0: f64 = 2451545.0, // default to J2000 TT
	integrator: am.IntegratorType = .rk4,
	time_scale: f64 = 8,
	substeps: int = 8,
) -> AstroSystem {
	system: AstroSystem
	system0: AstroSystem

	system.satellites = slice.clone_to_dynamic(sats[:])
	system.satellite_models = slice.clone_to_dynamic(sat_models[:])
	system.num_satellites = len(system.satellites)

	system.bodies = slice.clone_to_dynamic(bodies[:])
	system.body_models = slice.clone_to_dynamic(body_models[:])
	system.num_bodies = len(system.bodies)

	system.integrator = integrator
	system.time_scale = time_scale
	system.substeps = substeps


	// create id map
	for sat, i in system.satellites {
		system.id[sat.id] = i
	}
	for body, i in system.bodies {
		system.id[body.id] = i
	}

	return system
}


copy_system :: proc(system_dst, system_src: ^AstroSystem) {

	system_dst.satellites = slice.clone_to_dynamic(system_src.satellites[:])
	system_dst.satellite_models = slice.clone_to_dynamic(
		system_src.satellite_models[:],
	)
	system_dst.num_satellites = len(system_src.satellites)

	system_dst.bodies = slice.clone_to_dynamic(system_src.bodies[:])
	system_dst.body_models = slice.clone_to_dynamic(system_src.body_models[:])
	system_dst.num_bodies = len(system_src.bodies)

	system_dst.integrator = system_src.integrator
	system_dst.time_scale = system_src.time_scale
	system_dst.substeps = system_src.substeps
	system_dst.simulate = system_src.simulate

}


add_to_system :: proc {
	add_satellite_to_system,
	add_satellites_to_system,
	add_satmodel_to_system,
	add_satmodels_to_system,
	add_body_to_system,
	add_bodies_to_system,
	add_bodymodel_to_system,
	add_bodymodels_to_system,
}
add_satellite_to_system :: proc(system: ^AstroSystem, sat: Satellite) {
	using system
	add_satellite(&satellites, sat)
	id[sat.id] = num_satellites
	num_satellites += 1
}
add_satellites_to_system :: proc(system: ^AstroSystem, sats: []Satellite) {
	using system
	for sat, i in sats {
		add_satellite(&satellites, sat)
		id[sat.id] = num_satellites + i
	}
	num_satellites += len(sats)
}
add_satmodel_to_system :: proc(system: ^AstroSystem, model: SatelliteModel) {
	using system
	add_satellite_model(&satellite_models, model)
}
add_satmodels_to_system :: proc(
	system: ^AstroSystem,
	models: []SatelliteModel,
) {
	using system
	for model in models {
		add_satellite_model(&satellite_models, model)
	}
}

add_body_to_system :: proc(system: ^AstroSystem, body: CelestialBody) {
	using system
	add_celestialbody(&bodies, body)
	id[body.id] = num_bodies
	num_bodies += 1
}
add_bodies_to_system :: proc(system: ^AstroSystem, bodies: []CelestialBody) {
	using system
	for body, i in bodies {
		add_celestialbody(&bodies, body)
		id[body.id] = num_bodies + i
	}
	num_satellites += len(bodies)
}
add_bodymodel_to_system :: proc(
	system: ^AstroSystem,
	model: CelestialBodyModel,
) {
	using system
	add_celestialbody_model(&body_models, model)
}
add_bodymodels_to_system :: proc(
	system: ^AstroSystem,
	models: []CelestialBodyModel,
) {
	using system
	for model in models {
		add_celestialbody_model(&body_models, model)
	}
}
