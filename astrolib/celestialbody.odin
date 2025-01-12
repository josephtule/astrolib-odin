package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import am "../astromath"
import ode "../ode"

CelestialBody :: struct {
	mu:                 f64,
	omega:              f64,
	semimajor_axis:     f64,
	semiminor_axis:     f64,
	eccentricity:       f64,
	flattening:         f64,
	inverse_flattening: f64,
	third_flattening:   f64,
	mean_radius:        f64,
	surface_area:       f64,
	volume:             f64,
	pos, vel:           [3]f64,
	gravity_model:      ode.GravityModel,
	max_degree:         int,
	max_order:          int,
	J:                  [7]f64,
	C:                  ^[dynamic]f64,
	S:                  ^[dynamic]f64,
	base_unit:          am.UnitsLinear,
	name:               string,
}

CelestialBodyModel :: struct {
	model:      rl.Model,
	radius:     f32,
	local_axes: [3][3]f32,
	draw_axes:  bool,
	draw_model: bool,
	draw_trail: bool,
}
add_celestialbody :: proc {
	add_celestialbody_ptr,
	add_celestialbody_copy,
}
add_celestialbody_ptr :: proc(
	bodies: ^[dynamic]CelestialBody,
	body: ^CelestialBody,
) {
	append_elem(bodies, body^)
	free(body)
}
add_celestialbody_copy :: proc(
	bodies: ^[dynamic]CelestialBody,
	body: CelestialBody,
) {
	append_elem(bodies, body)
}

add_celestialbody_model :: proc {
	add_celestialbody_model_ptr,
	add_celestialbody_model_copy
}
add_celestialbody_model_ptr :: proc(
	bodies: ^[dynamic]CelestialBodyModel,
	body: ^CelestialBodyModel,
) {
	append_elem(bodies, body^)
	free(body)
}
add_celestialbody_model_copy :: proc(
	bodies: ^[dynamic]CelestialBodyModel,
	body: CelestialBodyModel,
) {
	append_elem(bodies, body)
}

wgs84 :: proc(
	units: am.UnitsLinear = .KILOMETER,
	max_degree: int = 0,
	max_order: int = 0,
) -> CelestialBody {
	earth: CelestialBody
	#partial switch units {
	case .METER: earth = CelestialBody {
			mu                 = 3.986004418000000e+14,
			omega              = 7.292115000000000e-05,
			semimajor_axis     = 6378137.,
			semiminor_axis     = 6.356752314245179e+06,
			eccentricity       = 0.081819190842621,
			flattening         = 0.003352810664747,
			inverse_flattening = 2.982572235630000e+02,
			third_flattening   = 0.001679220386384,
			mean_radius        = 6.371008771415059e+06,
			surface_area       = 5.100656217240886e+14,
			volume             = 1.083207319801408e+21,
			J                  = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit          = units,
		}
	case .KILOMETER: earth = CelestialBody {
			mu                 = 3.986004418000000e+05,
			omega              = 7.292115000000000e-05,
			semimajor_axis     = 6378.137,
			semiminor_axis     = 6.356752314245179e+03,
			eccentricity       = 0.081819190842621,
			flattening         = 0.003352810664747,
			inverse_flattening = 2.982572235630000e+02,
			third_flattening   = 0.001679220386384,
			mean_radius        = 6.371008771415059e+03,
			surface_area       = 5.100656217240886e+08,
			volume             = 1.083207319801408e+12,
			J                  = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit          = units,
		}
	case:
		panic("ERROR: units for wgs84 are incorrect")
	}
	earth.name = "Earth"
	return earth
}
