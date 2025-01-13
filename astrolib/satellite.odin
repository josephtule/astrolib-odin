package astrolib

import am "../astromath"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

Satellite :: struct {
	pos, vel:      [3]f64,
	ep:            [4]f64,
	omega:         [3]f64,
	mass:          f64,
	inertia:       matrix[3, 3]f64,
	radius:        f64, // hardbody radius
	name:          string,
	linear_units:  am.UnitsLinear,
	angular_units: am.UnitsAngle,
	gravity_model: GravityModel,
}

SatelliteModel :: struct {
	model:      rl.Model,
	model_size: [3]f32,
	local_axes: [3][3]f32,
	trail:      [dynamic][3]f32,
	draw_model: bool,
	draw_axes:  bool,
	draw_trail: bool,
	// TODO: add trails
}

update_satellite :: proc(sat: ^Satellite, params: rawptr, dt: f64) {
}

gen_satellite_and_mesh :: proc(
	pos, vel: [3]f64,
	ep: [4]f64,
	omega: [3]f64,
	model_size: [3]f32,
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
	m.model = rl.LoadModelFromMesh(
		rl.GenMeshCube(model_size[0], model_size[1], model_size[2]),
	)
	m.model_size = model_size
	am.SetTranslation(&m.model.transform, la.array_cast(s.pos * u_to_rl, f32))

	// checker pattern
	image_checker := rl.GenImageChecked(2, 2, 1, 1, rl.GOLD, rl.SKYBLUE)
	texture := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)
	m.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture

	return s, m
}

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

update_satellite_model :: proc(sat_model: ^SatelliteModel, sat: Satellite) {
	using sat_model
	// set rotation
	q := am.euler_param_to_quaternion(la.array_cast(sat.ep, f32))
	N_R_B := rl.QuaternionToMatrix(q)
	model.transform = N_R_B
	// set translation
	am.SetTranslation(&model.transform, la.array_cast(sat.pos, f32))
}
