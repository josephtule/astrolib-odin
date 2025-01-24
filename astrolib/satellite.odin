package astrolib

import am "../astromath"

import "core:fmt"
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
	linear_units:         am.UnitsLinear,
	angular_units:        am.UnitsAngle,
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
	sat_pos_f32 := am.cast_f32(sat.pos) * u_to_rl
	rl.DrawModel(model.model, am.origin_f32, 1, model.tint)

	if model.axes.draw {
		draw_axes(sat.update_attitude, &model.axes, model.model, f32(sat.radius) * 5)
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
	q := am.euler_param_to_quaternion(am.cast_f32(sat.ep))
	N_R_B := rl.QuaternionToMatrix(q)
	model.transform = N_R_B
	// }

	// set scale 
	am.SetScale(&model.transform, scale)

	// set translation
	sat_pos_f32 := am.cast_f32(sat.pos) * u_to_rl
	am.SetTranslation(&model.transform, sat_pos_f32)
}


// -----------------------------------------------------------------------------
// Update Functions
// -----------------------------------------------------------------------------
update_satellite :: #force_inline proc(
	sat: ^Satellite,
	model: ^Model,
	dt, time, time_scale: f64,
	integrator: am.IntegratorType,
	params_translate, params_attitude: rawptr,
) {
	// attitude dynamics
	if sat.update_attitude {
		attitude_current := am.epomega_to_state(sat.ep, sat.omega)
		_, attitude_new := am.integrate_step(
			euler_param_dynamics,
			time,
			attitude_current,
			dt * time_scale,
			params_attitude,
			integrator,
		)
		sat.ep = la.normalize0(sat.ep)
		sat.ep, sat.omega = am.state_to_epomega(attitude_new)
	}

	// translational dynamics
	state_current := am.posvel_to_state(sat.pos, sat.vel)
	_, state_new := am.integrate_step(
		gravity_nbody,
		time,
		state_current,
		dt * time_scale,
		params_translate,
		integrator,
	)
	sat.pos, sat.vel = am.state_to_posvel(state_new)
	update_trail(sat.pos, model)
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
	name_str: string = "SATID"
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

gen_satmodel :: #force_inline proc(
	sat: ^Satellite,
	model_size: [3]f32,
	scale: f32 = 1,
	tint: rl.Color = rl.RED,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
) -> (
	m: Model,
) {
	sat.radius = f64(min(model_size[0], min(model_size[1], model_size[2])))

	// default to rectangular prism
	m.draw_model = true
	mesh := rl.GenMeshCube(model_size[0], model_size[1], model_size[2])
	m.model = rl.LoadModelFromMesh(mesh)
	m.model.transform = (# row_major matrix[4, 4]f32)(la.MATRIX4F32_IDENTITY)
	m.model_size = model_size
	am.SetTranslation(&m.model.transform, am.cast_f32(sat.pos * u_to_rl))
	m.tint = tint

	// trail
	create_trail(&m.trail, sat.pos)
	m.trail.draw = true
	m.scale = scale

	// local axes
	m.axes.draw = true

	// position/velocity vectors
	m.posvel.draw_pos = true
	m.posvel.draw_vel = true
	m.posvel.vel_scale = 1.
	m.posvel.pos_tint = rl.GOLD
	m.posvel.vel_tint = rl.ORANGE

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
	m.id = sat.id
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
	m = gen_satmodel(&s, model_size, scale = scale)
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
	free(sat)
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
