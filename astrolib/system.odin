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
	satellite_models: [dynamic]Model,
	num_satellites:   int,
	// satellite_odeparams: [dynamic]rawptr,
	// bodies
	bodies:           [dynamic]CelestialBody,
	body_models:      [dynamic]Model,
	num_bodies:       int,
	// body_odeparams:      [dynamic]rawptr,
	// integrator
	integrator:       am.IntegratorType,
	time_scale:       f64,
	substeps:         int,
	simulate:         bool,
	JD0:              f64,
}

Model :: struct {
	id:         int,
	model:      rl.Model,
	model_size: [3]f32,
	scale:      f32,
	tint:       rl.Color,
	draw_model: bool,
	trail:      Trail,
	axes:       Axes,
	posvel:     PosVel,
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
			inertia_inv = sat.inertia_inv,
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
		draw_satellite(&model, satellites[i])
		draw_vectors(&model.posvel, system^, satellites[i].pos, satellites[i].vel)
	}

	// celestial body models
	for &model, i in body_models {
		draw_body(&model, bodies[i])
	}
}

create_system :: proc(
	sats: [dynamic]Satellite,
	sat_models: [dynamic]Model,
	bodies: [dynamic]CelestialBody,
	body_models: [dynamic]Model,
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
	add_model_to_system,
	add_models_to_system,
	add_body_to_system,
	add_bodies_to_system,
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
add_model_to_system :: proc(system: ^AstroSystem, model: Model) {
	using system
	add_model_to_array(&satellite_models, model)
}
add_models_to_system :: proc(system: ^AstroSystem, models: []Model) {
	using system
	for model in models {
		add_model_to_array(&satellite_models, model)
	}
}

add_model_to_array :: proc {
	add_model_to_array_ptr,
	add_model_to_array_copy,
}
add_model_to_array_ptr :: proc(models: ^[dynamic]Model, model: ^Model) {
	append_elem(models, model^)
	free(model)
}
add_model_to_array_copy :: proc(models: ^[dynamic]Model, model: Model) {
	append_elem(models, model)
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
