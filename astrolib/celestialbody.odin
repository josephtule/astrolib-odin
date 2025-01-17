package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import am "../astromath"

u_to_rl :: am.u_to_rl
g_body_id_base: int : 0
g_body_id: int = g_body_id_base

CelestialBody :: struct {
	id:              int,
	mu:              f64,
	mass:            f64,
	omega:           f64,
	semimajor_axis:  f64,
	semiminor_axis:  f64,
	eccentricity:    f64,
	flattening:      f64,
	mean_radius:     f64,
	pos, vel:        [3]f64,
	gravity_model:   GravityModel,
	max_degree:      int,
	max_order:       int,
	J:               [7]f64,
	C:               ^[dynamic]f64,
	S:               ^[dynamic]f64,
	base_unit:       am.UnitsLinear,
	name:            string,
	fixed:           bool,
	update_atittude: bool,
}

CelestialBodyModel :: struct {
	id:            int,
	model:         rl.Model,
	radius:        f32,
	local_axes:    [3][3]f32,
	target_origin: [3]f32,
	target_id:     int,
	trail:         Trail,
	draw_model:    bool,
	draw_axes:     bool,
	draw_pos:      bool,
	tint:          rl.Color,
}

gen_celestialbody :: proc(
	pos, vel: [3]f64,
	mass: f64,
	eccentricity: f64 = 0,
	semimajor_axis: f64,
	semiminor_axis: f64 = 0,
	mean_radius: f64 = 0,
	gravity_model: GravityModel = .pointmass,
	units: am.UnitsLinear = .KILOMETER,
) {
	body: CelestialBody

	// state
	body.pos = pos
	body.vel = vel

	// mass
	body.mass = mass
	#partial switch units {
	case .KILOMETER: body.mu = am.G_km * body.mass
	case .METER: body.mu = am.G_m * body.mass
	case:
		panic("ERROR: input units not yet supported")
	}

	// geometry
	body.eccentricity = eccentricity
	body.flattening = 1 - math.sqrt(1 - eccentricity * eccentricity)
	body.semimajor_axis = semimajor_axis
	if semiminor_axis == 0. && body.eccentricity == 0. {
		body.semiminor_axis = body.semimajor_axis
	} else {
		body.semiminor_axis =
			semimajor_axis * math.sqrt(1 - eccentricity * eccentricity)
	}

	if mean_radius == 0. {
		body.mean_radius = (2 * body.semimajor_axis + body.semiminor_axis) / 3.
	}
}


gen_celestialbody_model :: proc(
	radius: f32,
	faces: i32 = 64,
	tint: rl.Color = rl.BLUE,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
	u_to_rl: f32 = u_to_rl,
) -> CelestialBodyModel {
	c_model: CelestialBodyModel

	c_model.draw_model = true
	c_model.draw_axes = true
	c_model.trail.draw = false
	c_model.tint = tint

	for i := 0; i < 3; i += 1 {
		c_model.local_axes[i][i] = 1.
	}

	image_checker := rl.GenImageChecked(
		8,
		8,
		1,
		1,
		primary_color,
		secondary_color,
	)
	texture := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)

	c_model.model = rl.LoadModelFromMesh(
		rl.GenMeshSphere(radius * u_to_rl, faces, faces),
	)
	c_model.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture

	return c_model
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
	add_celestialbody_model_copy,
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
	id: int = g_body_id,
) -> CelestialBody {
	earth: CelestialBody
	#partial switch units {
	case .METER:
		earth = CelestialBody {
			mu             = 3.986004418000000e+14,
			omega          = 7.292115000000000e-05,
			semimajor_axis = 6378137.,
			semiminor_axis = 6.356752314245179e+06,
			eccentricity   = 0.081819190842621,
			flattening     = 0.003352810664747,
			// inverse_flattening = 2.982572235630000e+02,
			// third_flattening   = 0.001679220386384,
			mean_radius    = 6.371008771415059e+06,
			// surface_area   = 5.100656217240886e+14,
			// volume         = 1.083207319801408e+21,
			J              = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit      = units,
		}
		earth.mass = earth.mu / am.G_m
	case .KILOMETER:
		earth = CelestialBody {
			mu             = 3.986004418000000e+05,
			omega          = 7.292115000000000e-05,
			semimajor_axis = 6378.137,
			semiminor_axis = 6.356752314245179e+03,
			eccentricity   = 0.081819190842621,
			flattening     = 0.003352810664747,
			// inverse_flattening = 2.982572235630000e+02,
			// third_flattening   = 0.001679220386384,
			mean_radius    = 6.371008771415059e+03,
			// surface_area   = 5.100656217240886e+08,
			// volume         = 1.083207319801408e+12,
			J              = {
				0,
				0,
				0.001082626173852,
				-0.000002532410519,
				-0.000001619897600,
				-0.000000227753591,
				0.000000540666576,
			},
			base_unit      = units,
		}
		earth.mass = earth.mu / am.G_km
	case:
		panic("ERROR: units for wgs84 are incorrect")
	}
	earth.name = "Earth"
	earth.id = id
	g_body_id += 1
	return earth
}

luna_params :: proc(
	units: am.UnitsLinear = .KILOMETER,
	max_degree: int = 0,
	max_order: int = 0,
	id: int = g_body_id,
) -> CelestialBody {
	moon: CelestialBody
	#partial switch units {
	case .KILOMETER:
		moon = {
			mu             = 4902.800118,
			omega          = 2.6616995e-6,
			semimajor_axis = 1738.1,
			semiminor_axis = 1736.0,
			flattening     = 0.0012,
			mean_radius    = 1737.4,
			// volume         = 2.1958e10,
			// surface_area   = 3.793e7,
			J              = {0, 0, 202.7e-6, 0, 0, 0, 0},
			base_unit      = units,
		}
		moon.eccentricity = am.ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / am.G_km
	case .METER:
		moon = {
			mu             = 4902.800118 * 1000 * 1000 * 1000,
			omega          = 2.6616995e-6,
			semimajor_axis = 1738.1 * 1000,
			semiminor_axis = 1736.0 * 1000,
			flattening     = 0.0012,
			mean_radius    = 1737.4 * 1000,
			// volume         = 2.1958e10 * 1000 * 1000 * 1000,
			// surface_area   = 3.793e7 * 1000 * 1000,
			J              = {0, 0, 202.7e-6, 0, 0, 0, 0},
			base_unit      = units,
		}
		moon.eccentricity = am.ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / am.G_m
	case:
		panic("ERROR: incorrect units for the moon")
	}
	moon.name = "Luna"
	moon.id = id
	g_body_id += 1
	return moon
}


update_body :: proc(
	body: ^CelestialBody,
	model: ^CelestialBodyModel,
	state_new: ^[6]f64,
	dt, time, time_scale: f64,
	integrator: am.IntegratorType,
	params_translate, params_attitude: rawptr,
) {
	if body.update_atittude {
		// update body attitude
	}
	if !body.fixed {

		// update body translation
		state_current := am.posvel_to_state(body.pos, body.vel)
		_, state_new^ = am.integrate(
			gravity_nbody,
			time,
			state_current,
			dt * time_scale,
			params_translate,
			integrator,
		)
	}
}
