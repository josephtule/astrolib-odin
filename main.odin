package main

import "base:intrinsics"
import "core:fmt"

import "core:math"
import la "core:math/linalg"

import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import rl "vendor:raylib"
import "vendor:raylib/rlgl"

import ast "astrolib"
import ma "astromath"
import integrate "integrator"
import "ode"


main :: proc() {
	// Raylib window
	window_width: i32 = 1024
	window_height: i32 = 1024
	rl.InitWindow(window_width, window_height, "Test")
	rl.SetWindowState({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()


	// Textures ----------------------------------------------------------------
	// Satellite
	image_checker := rl.GenImageChecked(2, 2, 1, 1, rl.GOLD, rl.SKYBLUE)
	texture_satellite := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)
	image_checker = rl.GenImageChecked(2, 2, 1, 1, rl.BLUE, rl.BLUE)
	texture_earth := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)


	// Earth -------------------------------------------------------------------
	// Physical Parameters
	earth: ast.CelestialBody = ast.wgs84()
	// Earth Mesh
	model_earth := rl.LoadModelFromMesh(
		rl.GenMeshSphere(f32(earth.semimajor_axis), 60, 60),
	)
	model_earth.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture =
		texture_earth

	// Satellite ---------------------------------------------------------------
	// Orbit
	alt: f64 = 1000
	pos0: [3]f64 = (alt + earth.semimajor_axis) * [3]f64{1., 0., 0.}
	v_mag0 := math.sqrt(earth.mu / la.vector_length(pos0))
	angle0: f64 = la.to_radians(75.)
	vel0: [3]f64 = v_mag0 * [3]f64{0., math.cos(angle0), math.sin(angle0)}

	// Physical Parameters
	satellite := ast.Satellite {
		pos   = pos0,
		vel   = vel0,
		ep    = {0, 0, 0, 1},
		omega = {.05, .05, .1},
	}
	// Satellite Mesh
	cube_size: f32 = 50.
	model_satellite := rl.LoadModelFromMesh(
		rl.GenMeshCube(cube_size, cube_size, cube_size),
	)
	SetTranslation(&model_satellite.transform, la.array_cast(satellite.pos, f32))
	model_satellite.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture =
		texture_satellite

	// Trajectory Trail
	N_trail: int : 20000
	trail_pos: [N_trail][3]f32
	x0 := la.array_cast(GetTranslation(model_satellite.transform), f32)
	for i := 0; i < N_trail; i += 1 {
		trail_pos[i] = x0
	}
	trail_ind := 0

	// ODE/Integrator ----------------------------------------------------------
	gravity_params := ode.Params_Gravity_Pointmass {
		mu = earth.mu,
	}
	attitude_params := ode.Params_EulerParam {
		inertia = la.MATRIX3F64_IDENTITY,
		torque  = {0, 0, 0},
	}
	zonal_params := ode.Params_Gravity_Zonal {
		J          = earth.J,
		max_degree = 2,
		mu         = earth.mu,
		R_cb       = earth.semimajor_axis,
	}
	xlk: [6]f64
	xrk: [7]f64

	// Inertial Frame
	origin: [3]f32 : {0, 0, 0}
	x_inertial: [3]f32 : {1, 0, 0}
	y_inertial: [3]f32 : {0, 1, 0}
	z_inertial: [3]f32 : {0, 0, 1}

	// Time --------------------------------------------------------------------
	dt: f32
	cum_time: f32
	time_scale: f64 = 3000
	fps: f64

	// 3D camera
	camera: rl.Camera3D
	// camera.position = 1.001 * la.array_cast(satellite.pos, f32) + {15, 15, 0}
	camera.position = {1., 1., 1.} * 8000
	camera.target = la.array_cast(satellite.pos, f32)
	camera.up = {0., 0., 1.}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE
	rlgl.SetClipPlanes(0.001, 10000000.)

	for !rl.WindowShouldClose() {

		dt = rl.GetFrameTime()
		cum_time += dt * f32(time_scale)

		// update satellite
		if dt != 0. {
			fps = 1 / f64(dt)
			ma.set_vector_slice(&xlk, satellite.pos, satellite.vel)
			ma.set_vector_slice(&xrk, satellite.ep, satellite.omega)
			// _, xlk = integrate.rk4_step(
			// 	ode.gravity_pointmass,
			// 	f64(cum_time),
			// 	xlk,
			// 	f64(dt) * time_scale,
			// 	&gravity_params,
			// )
			_, xlk = integrate.rk4_step(
				ode.gravity_zonal,
				f64(cum_time),
				xlk,
				f64(dt) * time_scale,
				&zonal_params,
			)
			_, xrk = integrate.rk4_step(
				ode.euler_param_dyanmics,
				f64(cum_time),
				xrk,
				f64(dt) * time_scale,
				&attitude_params,
			)

			// set rotation
			ma.set_vector_slice_1(&satellite.ep, xrk, s1 = 0, l1 = 4)
			satellite.ep = la.vector_normalize0(satellite.ep)
			q := ode.euler_param_to_quaternion(la.array_cast(satellite.ep, f32))
			N_R_B := rl.QuaternionToMatrix(q)
			model_satellite.transform = N_R_B
			// SetRotation(&model_satellite.transform, N_R_B)

			// set translation
			ma.set_vector_slice_1(&satellite.pos, xlk, l1 = 3, s1 = 0)
			ma.set_vector_slice_1(&satellite.vel, xlk, l1 = 3, s1 = 3)
			SetTranslation(
				&model_satellite.transform,
				la.array_cast(satellite.pos, f32),
			)
		}
		N_R_B_3x3 := GetRotation(model_satellite.transform)
		sat_pos_f32 := la.array_cast(satellite.pos, f32)

		// update camera
		camera.position = 1.1 * sat_pos_f32 + {250, 250, 0}
		camera.target = sat_pos_f32
		// camera.target = origin

		// update trail buffer
		trail_pos[trail_ind] = la.array_cast(satellite.pos, f32)
		trail_ind = (trail_ind + 1) % N_trail

		rl.BeginDrawing()
		rl.BeginMode3D(camera)
		rl.ClearBackground(rl.GetColor(0x181818FF))

		// draw axes
		rl.DrawLine3D(origin, x_inertial * 10000, rl.RED)
		rl.DrawLine3D(origin, y_inertial * 10000, rl.GREEN)
		rl.DrawLine3D(origin, z_inertial * 10000, rl.BLUE)

		// draw line from center of earth to satellite
		rl.DrawLine3D(origin, sat_pos_f32, rl.GOLD)

		// draw earth 
		rl.DrawModelWires(model_earth, origin, 1, rl.WHITE)

		// draw trail
		for i := 0; i < N_trail - 1; i += 1 {
			current := (trail_ind + i) % N_trail
			next := (current + 1) % N_trail
			rl.DrawLine3D(trail_pos[current], trail_pos[next], rl.Color({136, 57, 239,255}))
		}


		// draw satellite
		rl.DrawModel(model_satellite, origin, 1, rl.WHITE)

		// draw satellite axes
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (x_inertial * cube_size * 10),
			rl.MAGENTA,
		)
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (y_inertial * cube_size * 10),
			rl.YELLOW,
		)
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (z_inertial * cube_size * 10),
			rl.Color({0, 255, 255, 255}),
		)

		rl.EndMode3D()
		rl.EndDrawing()
	}
}


MatrixTranslateAdditive :: proc(pos: [3]f32) -> # row_major matrix[4, 4]f32 {
	mat: # row_major matrix[4, 4]f32
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
	return mat
}

SetTranslation :: proc(mat: ^# row_major matrix[4, 4]f32, pos: [3]f32) {
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
}

GetTranslation :: proc(mat: # row_major matrix[4, 4]f32) -> [3]f32 {
	return {mat[0, 3], mat[1, 3], mat[2, 3]}
}

SetRotation :: proc(
	mat: ^# row_major matrix[4, 4]f32,
	rot: # row_major matrix[3, 3]f32,
) {
	mat[0, 0] = rot[0, 0]
	mat[0, 1] = rot[0, 1]
	mat[0, 2] = rot[0, 2]
	mat[1, 0] = rot[1, 0]
	mat[1, 1] = rot[1, 1]
	mat[1, 2] = rot[1, 2]
	mat[2, 0] = rot[2, 0]
	mat[2, 1] = rot[2, 1]
	mat[2, 2] = rot[2, 2]
}


mat4row :: # row_major matrix[4, 4]f32
mat3row :: # row_major matrix[3, 3]f32
GetRotation :: proc(
	mat: # row_major matrix[4, 4]f32,
) -> # row_major matrix[3, 3]f32 {
	// submatrix casting
	res: # row_major matrix[3, 3]f32
	res = mat3row(mat)
	return res
}


quaternion256_to_quaternion128 :: proc(q: quaternion256) -> quaternion128 {
	qout: quaternion128
	qout.x = f32(q.x)
	qout.y = f32(q.y)
	qout.z = f32(q.z)
	qout.w = f32(q.w)
	return qout
}

// Asteroid :: struct {}


// old stuff 

// dt := 0.1
// x0 := [2]f64{0., 0.}
// N := 100
// x: [dynamic][2]f64
// t: [dynamic]f64


// xk := x0
// tk := 0.


// params := ode.Params_MSD {
// 	m = 2.5,
// 	c = 0.8,
// 	k = 10.,
// }

// append(&x, xk)
// append(&t, tk)
// for i := 0; i < N; i += 1 {
// 	tk, xk = integrate.rk4_step(ode.mass_spring_damper, tk, xk, dt, &params)
// 	append(&x, xk)
// 	append(&t, tk)
// }

// fmt.println(x)
// #unroll for i in 0 ..< 2 {
// 	x[i] = f64(i)
// }

// r: [3]f64
// ma.set_vector_slice_3(
// 	&r,
// 	[1]f64{0.1},
// 	[6]f64{0.2, .3, .4, .5, .6, .7},
// 	[1]f64{0.67},
// 	l2 = 1,
// )
// v: [3]f64
// ma.set_vector_slice_2(&v, [2]f64{0.1, 0.2}, [1]f64{0.1})

// fmt.println("vector slice test")
// fmt.println(r, v)

// ode.accel_zonal(r, 1., 1., [7]f64{0.1, .1, .1, .1, .1, .1, .1}, 3)
