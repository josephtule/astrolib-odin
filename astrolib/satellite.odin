package astrolib

import "core:math"
import la "core:math/linalg"
import "core:strconv"
import str "core:strings"
import rl "vendor:raylib"


g_sat_id_base: int : 10000
g_sat_id: int = g_sat_id_base

// -----------------------------------------------------------------------------
// Structs
// -----------------------------------------------------------------------------
Satellite :: struct {
	id:                   int,
	pos, vel:             [3]f64,
	ep:                   [4]f64,
	omega:                [3]f64,
	mass:                 f64,
	inertia, inertia_inv: matrix[3, 3]f64,
	radius:               f64, // hardbody radius
	linear_units:         UnitsLinear,
	angular_units:        UnitsAngle,
	gravity_model:        GravityModel,
	update_attitude:      bool,
	info:                 SatelliteInfo,
}

SatelliteInfo :: struct {
	name:            string,
	intl_designator: string,
	tle_index:       int,
	catalog_number:  int,
}

// -----------------------------------------------------------------------------
// Draw Functions
// -----------------------------------------------------------------------------
draw_satellite :: #force_inline proc(model: ^Model, sat: Satellite) {
	update_satellite_model(model, sat)
	sat_pos_f32 := cast_f32(sat.pos) * u_to_rl
	if model.draw_model {
		rl.DrawModel(model.model, origin_f32, 1, model.tint)
	}
	if model.axes.draw {
		draw_axes(sat.update_attitude, &model.axes, model.model)
	}
	if model.trail.draw {
		draw_trail(model^)
	}
}

update_satellite_model :: #force_inline proc(
	sat_model: ^Model,
	sat: Satellite,
) {
	using sat_model
	// set rotation
	// model.transform = (# row_major matrix[4, 4]f32)(la.MATRIX4F32_IDENTITY)
	// if sat.update_attitude {
	q := euler_param_to_quaternion(cast_f32(sat.ep))
	N_R_B := rl.QuaternionToMatrix(q)
	model.transform = N_R_B
	// }

	// set scale 
	SetScale(&model.transform, scale)

	// set translation
	sat_pos_f32 := cast_f32(sat.pos) * u_to_rl
	SetTranslation(&model.transform, sat_pos_f32)
}


// -----------------------------------------------------------------------------
// Update Functions
// -----------------------------------------------------------------------------
update_satellite :: #force_inline proc(
	sat: ^Satellite,
	model: ^Model,
	dt, time, time_scale: f64,
	integrator: IntegratorType,
	params_translate, params_attitude: rawptr,
) {
	// attitude dynamics
	if sat.update_attitude {
		attitude_current := epomega_to_state(sat.ep, sat.omega)
		_, attitude_new := integrate_step(
			euler_param_dynamics,
			time,
			attitude_current,
			dt * time_scale,
			params_attitude,
			integrator,
		)
		sat.ep = la.normalize0(sat.ep)
		sat.ep, sat.omega = state_to_epomega(attitude_new)
	}

	// translational dynamics
	state_current := posvel_to_state(sat.pos, sat.vel)
	_, state_new := integrate_step(
		gravity_nbody,
		time,
		state_current,
		dt * time_scale,
		params_translate,
		integrator,
	)
	sat.pos, sat.vel = state_to_posvel(state_new)

	// if model.trail.draw {
	// TODO: not sure if i should have this conditional
	update_trail(sat.pos, model)
	// }
}


// -----------------------------------------------------------------------------
// Generate Satellite Functions
// -----------------------------------------------------------------------------
gen_sat :: #force_inline proc(
	pos, vel: [3]f64,
	ep: [4]f64,
	omega: [3]f64,
	mass: f64 = 100.,
	id: int = g_sat_id,
) -> (
	s: Satellite,
) {
	// defaults to kilometers and radians
	// default zero mass and radius
	info: SatelliteInfo
	name_str: string = "SAT"
	id_buf: [8]byte
	id_str: string = strconv.itoa(id_buf[:], id)
	name, err := str.join([]string{name_str, id_str}, " ")
	info.name = name
	inertia := la.MATRIX3F64_IDENTITY
	inertia_inv := la.inverse(inertia)
	s = Satellite {
		pos           = pos,
		vel           = vel,
		ep            = ep,
		omega         = omega,
		inertia       = inertia,
		inertia_inv   = inertia_inv,
		linear_units  = .KILOMETER,
		angular_units = .RADIANS,
		id            = id,
		info          = info,
	}
	if id == g_sat_id {
		g_sat_id += 1
	}
	return s
}

gen_sat_model :: #force_inline proc(
	sat: ^Satellite,
	model_size: [3]f32,
	scale: f32 = 1,
	tint: rl.Color = rl.RED,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
) -> (
	m: Model,
) {
	m.id = sat.id
	m.type = .satellite

	sat.radius =
		f64(max(model_size[0], min(model_size[1], model_size[2]))) / u_to_rl

	// default to rectangular prism
	m.draw_model = true
	mesh := rl.GenMeshCube(model_size[0], model_size[1], model_size[2])
	m.model = rl.LoadModelFromMesh(mesh)
	m.model.transform = (# row_major matrix[4, 4]f32)(la.MATRIX4F32_IDENTITY)
	m.model_size = model_size
	SetTranslation(&m.model.transform, cast_f32(sat.pos * u_to_rl))
	m.tint = tint

	// trail
	create_trail(&m.trail, sat.pos)
	m.trail.draw = true
	m.scale = scale

	// local axes
	m.axes.draw = true
	m.axes.size = 5 * f32(sat.radius) * u_to_rl
	m.axes.scale = 1
	m.axes.x = xaxis_f32 * m.axes.size
	m.axes.y = yaxis_f32 * m.axes.size
	m.axes.z = zaxis_f32 * m.axes.size

	// position/velocity vectors
	m.posvel.draw_pos = true
	m.posvel.draw_vel = true
	m.posvel.vel_scale = 1.
	m.posvel.pos_tint = rl.GOLD
	m.posvel.vel_tint = rl.ORANGE
	m.posvel.target_pos_id = -1
	m.posvel.target_vel_id = -1

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

	return m
}

gen_sat_and_model :: #force_inline proc(
	pos, vel: [3]f64,
	ep: [4]f64,
	omega: [3]f64,
	model_size: [3]f32,
	scale: f32 = 1,
	mass: f64 = 100.,
	tint: rl.Color = rl.RED,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
	id: int = g_sat_id,
) -> (
	s: Satellite,
	m: Model,
) {
	s = gen_sat(pos, vel, ep, omega, mass)
	m = gen_sat_model(&s, model_size, scale = scale)
	return s, m
}

set_inertia :: #force_inline proc(sat: ^Satellite, I: matrix[3, 3]f64) {
	sat.inertia = I
	sat.inertia_inv = la.inverse(I)
}

/// -----------------------------------------------------------------------------
// Add/Remove Functions
// -----------------------------------------------------------------------------
add_satellite :: proc {
	add_satellite_ptr,
	add_satellite_copy,
	add_satellite_soa,
}
add_satellite_ptr :: #force_inline proc(
	sats: ^[dynamic]Satellite,
	sat: ^Satellite,
) {
	append_elem(sats, sat^)
}
add_satellite_copy :: #force_inline proc(
	sats: ^[dynamic]Satellite,
	sat: Satellite,
) {
	append_elem(sats, sat)
}
add_satellite_soa :: #force_inline proc(
	sats: ^#soa[dynamic]Satellite,
	sat: Satellite,
) {
	append_soa(sats, sat)
}
