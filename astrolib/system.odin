package astrolib

import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

g_sys_id_base: int : 0
g_sys_id: int = g_sys_id_base

AstroSystem :: struct {
	// entity ids 
	id:               int,
	entity:           map[int]int, // maps id to index in relevant array
	// satellites
	satellites:       [dynamic]Satellite,
	satellite_models: [dynamic]Model,
	num_satellites:   int,
	// bodies
	bodies:           [dynamic]CelestialBody,
	body_models:      [dynamic]Model,
	num_bodies:       int,
	// stations
	stations:         [dynamic]Station,
	station_models:   [dynamic]Model,
	num_stations:     int,
	// integrator
	integrator:       IntegratorType,
	time_scale:       f64,
	substeps:         int,
	simulate:         bool,
	JD0:              f64,
	// info 
	name:             string,
}

Systems :: struct {
	systems:     [dynamic]AstroSystem,
	num_systems: int,
}

add_system :: proc(
	systems: ^Systems,
	systems_reset: ^Systems,
	system: ^AstroSystem,
) {
	append(&systems.systems, system^)
	append(&systems_reset.systems, system^)
	systems.num_systems += 1
	systems_reset.num_systems += 1
}

create_systems :: proc() -> (systems: Systems, systems_reset: Systems) {
	systems.systems = make([dynamic]AstroSystem)
	systems.num_systems = 0

	systems_reset.systems = make([dynamic]AstroSystem)
	systems_reset.num_systems = 0

	return systems, systems_reset
}

update_system :: #force_inline proc(system: ^AstroSystem, dt, time: f64) {
	using system
	N_sats := len(satellites)
	N_bodies := len(bodies)
	params_translate := Params_Gravity_Nbody {
		bodies = &system.bodies,
		idx    = -1,
	}
	// update satellites first
	for &sat, i in satellites {
		// gen params
		params_attitude := Params_EulerParam {
			inertia     = sat.inertia,
			inertia_inv = sat.inertia_inv,
			torque      = {0, 0, 0}, // NOTE: no control for now
		}
		params_translate.self_mass = sat.mass
		params_translate.self_radius = sat.radius
		params_translate.gravity_model = sat.gravity_model

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
	state_new_body := make([dynamic][6]f64, len(bodies)) // TODO: remove allocation, add to sys to prevent having to make this every time
	for &body, i in bodies {
		params_translate.self_mass = body.mass
		params_translate.self_radius = body.semimajor_axis
		params_translate.gravity_model = body.gravity_model
		params_translate.idx = i

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
			bodies[i].pos, bodies[i].vel = state_to_posvel(state_new_body[i])
		}
	}

	for &station in stations {
		update_station(&station, system^)
	}
}

// draw_posvec :: proc(system: AstroSystem, )

draw_system :: #force_inline proc(
	system: ^AstroSystem,
	u_to_rl: f32 = u_to_rl,
) {
	using system
	// satellite models
	for &model, i in satellite_models {
		draw_satellite(&model, satellites[i])
		draw_vectors(&model.posvel, system^, satellites[i].pos, satellites[i].vel)
	}

	// celestial body models
	for &model, i in body_models {
		draw_body(&model, bodies[i])
		draw_vectors(&model.posvel, system^, bodies[i].pos, bodies[i].vel)
	}

	// station models 
	for &model, i in station_models {
		draw_station(&model, stations[i])
	}
}

create_system :: proc {
	create_system_full,
	create_system_empty,
}

create_system_empty :: #force_inline proc(
	JD0: f64 = 2451545.0, // defaults// default to J2000 TT
	integrator: IntegratorType = .rk4,
	time_scale: f64 = 8,
	substeps: int = 8,
	name: string = "",
) -> AstroSystem {
	system: AstroSystem

	system.satellites = make([dynamic]Satellite)
	system.satellite_models = make([dynamic]Model)
	system.num_satellites = len(system.satellites)

	system.bodies = make([dynamic]CelestialBody)
	system.body_models = make([dynamic]Model)
	system.num_bodies = len(system.bodies)

	system.stations = make([dynamic]Station)
	system.station_models = make([dynamic]Model)
	system.num_stations = len(system.stations)

	system.JD0 = JD0
	system.integrator = integrator
	system.time_scale = time_scale
	system.substeps = substeps

	system.entity = make(map[int]int)
	system.id = g_sys_id
	g_sys_id += 1

	if len(name) == 0 {
		name_builder := strings.builder_make()
		strings.write_string(&name_builder, "SYS: ")
		strings.write_int(&name_builder, system.id)
		system.name = strings.to_string(name_builder)
	} else {
		system.name = name
	}

	return system
}

create_system_full :: #force_inline proc(
	sats: [dynamic]Satellite,
	sat_models: [dynamic]Model,
	bodies: [dynamic]CelestialBody,
	body_models: [dynamic]Model,
	stations: [dynamic]Station,
	station_models: [dynamic]Model,
	// defaults
	JD0: f64 = 2451545.0, // default to J2000 TT
	integrator: IntegratorType = .rk4,
	time_scale: f64 = 8,
	substeps: int = 8,
	name: string = "",
) -> AstroSystem {
	system: AstroSystem
	// system0: AstroSystem

	system.satellites = slice.clone_to_dynamic(sats[:])
	system.satellite_models = slice.clone_to_dynamic(sat_models[:])
	system.num_satellites = len(system.satellites)

	system.bodies = slice.clone_to_dynamic(bodies[:])
	system.body_models = slice.clone_to_dynamic(body_models[:])
	system.num_bodies = len(system.bodies)

	system.stations = slice.clone_to_dynamic(stations[:])
	system.station_models = slice.clone_to_dynamic(station_models[:])
	system.num_stations = len(system.stations)

	system.JD0 = JD0
	system.integrator = integrator
	system.time_scale = time_scale
	system.substeps = substeps


	// create id map
	for sat, i in system.satellites {
		system.entity[sat.id] = i
	}
	for body, i in system.bodies {
		system.entity[body.id] = i
	}

	system.entity = make(map[int]int)
	system.id = g_sys_id
	g_sys_id += 1

	if len(name) == 0 {
		name_builder := strings.builder_make()
		strings.write_string(&name_builder, "SYS: ")
		strings.write_int(&name_builder, system.id)
		system.name = strings.to_string(name_builder)
	} else {
		system.name = name
	}

	return system
}


copy_system :: #force_inline proc(
	system_dst: ^AstroSystem,
	system_src: ^AstroSystem,
) {

	system_dst.satellites = slice.clone_to_dynamic(system_src.satellites[:])
	system_dst.satellite_models = slice.clone_to_dynamic(
		system_src.satellite_models[:],
	)
	system_dst.num_satellites = len(system_src.satellites)

	system_dst.bodies = slice.clone_to_dynamic(system_src.bodies[:])
	system_dst.body_models = slice.clone_to_dynamic(system_src.body_models[:])
	system_dst.num_bodies = len(system_src.bodies)

	system_dst.stations = slice.clone_to_dynamic(system_src.stations[:])
	system_dst.station_models = slice.clone_to_dynamic(
		system_src.station_models[:],
	)
	system_dst.num_stations = len(system_src.stations)

	system_dst.integrator = system_src.integrator
	system_dst.time_scale = system_src.time_scale
	system_dst.substeps = system_src.substeps
	system_dst.simulate = system_src.simulate

	system_dst.id = system_src.id
	system_dst.name = strings.clone(system_src.name)
	system_dst.JD0 = system_src.JD0
	system_dst.entity = map_clone(system_src.entity)

}


add_to_system :: proc {
	add_sat_to_system,
	add_sats_to_system,
	add_model_to_system,
	add_models_to_system,
	add_body_to_system,
	add_bodies_to_system,
	add_station_to_system,
	add_stations_to_system,
}
add_sat_to_system :: #force_inline proc(system: ^AstroSystem, sat: Satellite) {
	using system
	add_satellite(&system.satellites, sat)
	system.entity[sat.id] = num_satellites
	num_satellites += 1
}
add_sats_to_system :: #force_inline proc(
	system: ^AstroSystem,
	sats: []Satellite,
) {
	using system
	for sat, i in sats {
		add_satellite(&satellites, sat)
		entity[sat.id] = num_satellites + i
	}
	num_satellites += len(sats)
}
add_body_to_system :: #force_inline proc(
	system: ^AstroSystem,
	body: CelestialBody,
) {
	using system
	add_celestialbody(&bodies, body)
	entity[body.id] = num_bodies
	num_bodies += 1
}
add_bodies_to_system :: #force_inline proc(
	system: ^AstroSystem,
	bodies: []CelestialBody,
) {
	using system
	for body, i in bodies {
		add_celestialbody(&bodies, body)
		entity[body.id] = num_bodies + i
	}
	num_satellites += len(bodies)
}
add_station_to_system :: #force_inline proc(
	system: ^AstroSystem,
	station: Station,
) {
	using system
	add_station(&stations, station)
	entity[station.id] = num_bodies
	num_stations += 1
}
add_stations_to_system :: #force_inline proc(
	system: ^AstroSystem,
	stations: [dynamic]Station,
) {
	using system
	for station, i in stations {
		add_station(&stations, station)
		entity[station.id] = num_stations + i
	}
	num_stations += len(stations)
}
add_model_to_system :: #force_inline proc(system: ^AstroSystem, model: Model) {
	using system
	switch model.type {
	case .satellite:
		add_model_to_array(&satellite_models, model)
	case .celestialbody:
		add_model_to_array(&body_models, model)
	case .station:
		add_model_to_array(&station_models, model)
	}
}
add_models_to_system :: #force_inline proc(
	system: ^AstroSystem,
	models: []Model,
) {
	using system
	for model in models {
		switch model.type {
		case .satellite:
			add_model_to_array(&satellite_models, model)
		case .celestialbody:
			add_model_to_array(&body_models, model)
		case .station:
			add_model_to_array(&station_models, model)
		}
	}
}
