package astrolib

import am "../astromath"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

g_sat_id_base : int : 10000
g_sat_id: int = g_sat_id_base

// -----------------------------------------------------------------------------
// Structs
// -----------------------------------------------------------------------------
Satellite :: struct {
	id:              int,
	pos, vel:        [3]f64,
	ep:              [4]f64,
	omega:           [3]f64,
	mass:            f64,
	inertia:         matrix[3, 3]f64,
	radius:          f64, // hardbody radius
	name:            string,
	linear_units:    am.UnitsLinear,
	angular_units:   am.UnitsAngle,
	gravity_model:   GravityModel,
	update_attitude: bool,
}

SatelliteModel :: struct {
	id:            int,
	model:         rl.Model,
	model_size:    [3]f32,
	local_axes:    [3][3]f32,
	tint:          rl.Color,
	target_origin: [3]f32,
	target_id:     int,
	trail:         [dynamic][3]f32,
	trail_ind:     int,
	trail_inc:     int,
	draw_model:    bool,
	draw_axes:     bool,
	draw_pos:      bool,
	draw_trail:    bool,

	// TODO: add trails
}

// -----------------------------------------------------------------------------
// Update Functions
// -----------------------------------------------------------------------------
update_satellite :: proc(
	sat: ^Satellite,
	model: ^SatelliteModel,
	dt, time, time_scale: f64,
	integrator: am.IntegratorType,
	params_translate, params_attitude: rawptr,
) {
	// attitude dynamics
	if sat.update_attitude {
		attitude_current := am.epomega_to_state(sat.ep, sat.omega)
		_, attitude_new := am.integrate(
			euler_param_dyanmics,
			time,
			attitude_current,
			dt * time_scale,
			params_attitude,
			integrator,
		)
		sat.ep, sat.omega = am.state_to_epomega(attitude_new)
	}

	// translational dynamics
	state_current := am.posvel_to_state(sat.pos, sat.vel)
	_, state_new := am.integrate(
		gravity_nbody,
		time,
		state_current,
		dt * time_scale,
		params_translate,
		integrator,
	)
	sat.pos, sat.vel = am.state_to_posvel(state_new)
	update_sat_trail(sat, model)
}

update_satellite_model :: proc(sat_model: ^SatelliteModel, sat: Satellite) {
	using sat_model
	// set rotation
	q := am.euler_param_to_quaternion(la.array_cast(sat.ep, f32))
	N_R_B := rl.QuaternionToMatrix(q)
	model.transform = N_R_B
	// set translation
	am.SetTranslation(&model.transform, la.array_cast(sat.pos, f32))
}

// -----------------------------------------------------------------------------
// Generate Satellite Functions
// -----------------------------------------------------------------------------
gen_satellite_and_mesh :: proc(
	pos, vel: [3]f64,
	ep: [4]f64,
	omega: [3]f64,
	model_size: [3]f32,
	mass: f64 = 100.,
	tint: rl.Color = rl.RED,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
	id: int = g_sat_id,
	u_to_rl: f64 = u_to_rl,
) -> (
	s: Satellite,
	m: SatelliteModel,
) {
	// defaults to kilometers and radians
	// default zero mass and radius
	s = Satellite {
		pos           = pos,
		vel           = vel,
		ep            = ep,
		omega         = omega,
		inertia       = la.MATRIX3F64_IDENTITY,
		linear_units  = .KILOMETER,
		angular_units = .RADIANS,
	}

	// default to rectangular prism
	m.draw_model = true
	m.draw_pos = true
	m.model = rl.LoadModelFromMesh(
		rl.GenMeshCube(model_size[0], model_size[1], model_size[2]),
	)
	m.model_size = model_size
	am.SetTranslation(&m.model.transform, la.array_cast(s.pos * u_to_rl, f32))
	m.tint = tint
	create_sat_trail(&s, &m)
	m.draw_trail = true

	s.radius = f64(min(model_size[0], min(model_size[1], model_size[2])))

	// checker pattern
	image_checker := rl.GenImageChecked(
		2,
		2,
		1,
		1,
		primary_color,
		secondary_color,
	)
	texture := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)
	m.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture
	s.id = id
	m.id = id
	g_sat_id += 1
	return s, m
}

// -----------------------------------------------------------------------------
// Trails
// -----------------------------------------------------------------------------
N_trail := 256
trail_mod := N_trail / 4

create_sat_trail :: proc(sat: ^Satellite, model: ^SatelliteModel) {
	for i := 0; i < N_trail; i += 1 {
		append_elem(&model.trail, la.array_cast(sat.pos, f32) * u_to_rl)
	}
	model.trail_ind = 0
}
reset_sat_trail :: proc(sat: ^Satellite, model: ^SatelliteModel) {
	for i := 0; i < N_trail; i += 1 {
		model.trail[i] = la.array_cast(sat.pos, f32) * u_to_rl
	}
	model.trail_ind = 0
}
update_sat_trail :: proc(sat: ^Satellite, model: ^SatelliteModel) {
	model.trail_inc = (model.trail_inc + 1)
	if model.trail_inc == trail_mod {
		model.trail_inc = 0
		model.trail[model.trail_ind] = la.array_cast(sat.pos, f32) * u_to_rl
		model.trail_ind = (model.trail_ind + 1)
		if model.trail_ind == N_trail {
			model.trail_ind = 0 // Wrap around without modulo
		}
	}
}
draw_sat_trail :: proc(model: SatelliteModel) {
	using model
	if draw_trail {
		for i := 0; i < N_trail - 1; i += 1 {
			current := (trail_ind + i) % N_trail
			next := (current + 1) % N_trail

			rl.DrawLine3D(trail[current], trail[next], tint)
		}
	}
}

/// -----------------------------------------------------------------------------
// Add/Remove Functions
// -----------------------------------------------------------------------------
add_satellite :: proc {
	add_satellite_ptr,
	add_satellite_copy,
}
add_satellite_ptr :: proc(sats: ^[dynamic]Satellite, sat: ^Satellite) {
	append_elem(sats, sat^)
	free(sat)
}
add_satellite_copy :: proc(sats: ^[dynamic]Satellite, sat: Satellite) {
	append_elem(sats, sat)
}

add_satellite_model :: proc {
	add_satellite_model_ptr,
	add_satellite_model_copy,
}
add_satellite_model_ptr :: proc(
	sat_models: ^[dynamic]SatelliteModel,
	model: ^SatelliteModel,
) {
	append_elem(sat_models, model^)
	free(model)
}
add_satellite_model_copy :: proc(
	sat_models: ^[dynamic]SatelliteModel,
	model: SatelliteModel,
) {
	append_elem(sat_models, model)
}
