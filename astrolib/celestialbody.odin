package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

g_body_id_base: int : 0
g_body_id: int = g_body_id_base

CelestialBody :: struct {
	id:              int,
	mu:              f64,
	semimajor_axis:  f64,
	eccentricity:    f64,
	pos, vel:        [3]f64,
	ep:              [4]f64,
	gravity_model:   GravityModel,
	omega:           f64,
	mass:            f64,
	semiminor_axis:  f64,
	mean_radius:     f64,
	flattening:      f64,
	max_degree:      int,
	max_order:       int,
	J:               [7]f64,
	C:               ^[dynamic]f64,
	S:               ^[dynamic]f64,
	base_unit:       UnitsLinear,
	name:            string,
	fixed:           bool,
	update_attitude: bool,
}

// CelestialBodyParameters :: struct {
// 	mass:           f64,
// 	omega:          f64,
// 	semiminor_axis: f64,
// 	mean_radius:    f64,
// 	flattening:     f64,
// 	max_degree:     int,
// 	max_order:      int,
// 	J:              [7]f64,
// 	C:              ^[dynamic]f64,
// 	S:              ^[dynamic]f64,
// }


update_body :: #force_inline proc(
	body: ^CelestialBody,
	model: ^Model,
	state_new: ^[6]f64,
	dt, time, time_scale: f64,
	integrator: IntegratorType,
	params_translate, params_attitude: rawptr,
) {
	if body.update_attitude {
		// update body attitude
		// always rotate about z axis (will probably not be implementing precession, nutation, and polar motion)
		// TODO: figure out how to optimize this
		angle := body.omega * dt * time_scale
		rotz := la.matrix4_from_euler_angle_z(-angle)
		attitude := la.matrix4_from_quaternion(euler_param_to_quaternion(body.ep))
		q := la.normalize0(la.quaternion_from_matrix4(attitude * rotz))
		body.ep = quaternion_to_euler_param(q)
	}

	if !body.fixed {
		// update body translation
		state_current := posvel_to_state(body.pos, body.vel)
		_, state_new^ = integrate_step(
			gravity_nbody,
			time,
			state_current,
			dt * time_scale,
			params_translate,
			integrator,
		)
	}
}

draw_body :: #force_inline proc(model: ^Model, body: CelestialBody) {
	update_body_model(model, body)

	rl.DrawModel(model.model, origin_f32, 1, model.tint)

	if model.axes.draw {
		draw_axes(body.update_attitude, &model.axes, model.model)
	}
	if model.trail.draw {
		// draw_trail(model^)
	}

}

update_body_model :: #force_inline proc(
	body_model: ^Model,
	body: CelestialBody,
) {
	using body_model

	// set rotation
	// if body.update_attitude {
	q := euler_param_to_quaternion(cast_f32(body.ep))
	model.transform = rl.QuaternionToMatrix(q)
	// } else {
	// 	model.transform = (# row_major matrix[4, 4]f32)(la.MATRIX4F32_IDENTITY)
	// }

	// set scale 
	SetScale(&model.transform, scale)

	// set translation
	body_pos_f32 := cast_f32(body.pos) * u_to_rl
	SetTranslation(&model.transform, body_pos_f32)

}

gen_celestialbody :: #force_inline proc(
	pos, vel: [3]f64,
	ep: [4]f64,
	mass: f64,
	eccentricity: f64 = 0,
	semimajor_axis: f64,
	semiminor_axis: f64 = 0,
	mean_radius: f64 = 0,
	gravity_model: GravityModel = .pointmass,
	units: UnitsLinear = .KILOMETER,
) -> (
	body: CelestialBody,
) {

	// state
	body.pos = pos
	body.vel = vel

	// orientation
	body.ep = ep

	// compute parameters
	body.mass = mass // mass
	#partial switch units {
	case .KILOMETER: body.mu = G_km * body.mass
	case .METER: body.mu = G_m * body.mass
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

	return body
}


gen_celestialbody_model :: #force_inline proc(
	body: CelestialBody,
	model_size: [3]f32,
	faces: i32 = 64,
	scale: f32 = 1,
	tint: rl.Color = rl.BLUE,
	primary_color: rl.Color = rl.Color({200, 200, 200, 255}),
	secondary_color: rl.Color = rl.Color({150, 150, 150, 255}),
) -> Model {
	model: Model

	model.draw_model = true
	model.trail.draw = false
	model.tint = tint
	model.scale = scale
	model.model_size = model_size

	// trail
	// create_trail(&model.trail, body.pos)
	// model.trail.draw = true

	// local axes
	model.axes.draw = true
	model.axes.size = 2 * f32(body.semimajor_axis) * u_to_rl
	model.axes.x = xaxis_f32 
	model.axes.y = yaxis_f32 
	model.axes.z = zaxis_f32 

	// // position/velocity vectors
	// model.posvel.draw_pos = true
	// model.posvel.draw_vel = true
	// model.posvel.vel_scale = 1
	// model.posvel.pos_tint = rl.GOLD
	// model.posvel.vel_tint = rl.PURPLE

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

	// TODO: figure out how to create ellipsoid with model_size = [a,b,c]
	// a = semimajor axis, b = semiminor axis, c = secondary semiminor axis (usually b = c)
	model.model = rl.LoadModelFromMesh(
		rl.GenMeshSphere(model_size[0], faces, faces),
	)
	model.model.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture = texture

	return model
}


add_celestialbody :: proc {
	add_celestialbody_ptr,
	add_celestialbody_copy,
}
add_celestialbody_ptr :: #force_inline proc(
	bodies: ^[dynamic]CelestialBody,
	body: ^CelestialBody,
) {
	append_elem(bodies, body^)
	free(body)
}
add_celestialbody_copy :: #force_inline proc(
	bodies: ^[dynamic]CelestialBody,
	body: CelestialBody,
) {
	append_elem(bodies, body)
}


wgs84 :: #force_inline proc(
	units: UnitsLinear = .KILOMETER,
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
		earth.mass = earth.mu / G_m
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
		earth.mass = earth.mu / G_km
	case:
		panic("ERROR: units for wgs84 are incorrect")
	}
	earth.name = "Earth"
	earth.id = id
	g_body_id += 1
	return earth
}

luna_params :: #force_inline proc(
	units: UnitsLinear = .KILOMETER,
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
		moon.eccentricity = ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / G_km
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
		moon.eccentricity = ecc_from_flat(moon.flattening)
		moon.mass = moon.mu / G_m
	case:
		panic("ERROR: incorrect units for the moon")
	}
	moon.name = "Luna"
	moon.id = id
	g_body_id += 1
	return moon
}
