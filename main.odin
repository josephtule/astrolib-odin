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
import ode "ode"


main :: proc() {


	// raylib stuff

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
	earth: ast.CelestialBody(f64) = ast.wgs84(T = f64)
	// Earth Mesh
	model_earth := rl.LoadModelFromMesh(
		rl.GenMeshSphere(f32(earth.semimajor_axis), 30, 30),
	)
	model_earth.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture =
		texture_earth

	// Satellite ---------------------------------------------------------------
	// Orbit
	alt: f64 = 1000
	pos0: [3]f64 = (alt + earth.semimajor_axis) * [3]f64{1., 0., 0.}
	v_mag0 := math.sqrt(earth.mu / la.vector_length(pos0))
	angle0 := la.to_radians(30.)
	vel0: [3]f64 = v_mag0 * [3]f64{0., math.cos(angle0), math.sin(angle0)}

	// Physical Parameters
	satellite := ast.Satellite {
		pos = pos0,
		vel = vel0,
	}
	// Satellite Mesh
	model_satellite := rl.LoadModelFromMesh(rl.GenMeshCube(5., 5., 5.))
	SetTranslation(&model_satellite.transform, la.array_cast(satellite.pos, f32))
	model_satellite.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture =
		texture_satellite


	// ODE/Integrator ----------------------------------------------------------
	gravity_params := ode.Params_Gravity_Pointmass {
		mu = earth.mu,
	}
	xk: [6]f64

	// Inertial Frame
	origin: [3]f32 : {0, 0, 0}
	x_inertial: [3]f32 : {1, 0, 0}
	y_inertial: [3]f32 : {0, 1, 0}
	z_inertial: [3]f32 : {0, 0, 1}

	// Time --------------------------------------------------------------------
	dt: f32 = 0
	cum_time: f32 = 0
	time_scale: f64 = 100


	// 3D camera
	camera: rl.Camera3D
	// camera.position = 1.001 * la.array_cast(satellite.pos, f32) + {15, 15, 0}
	camera.position = {1., 1., 1.} * 10000.
	camera.target = origin // la.array_cast(satellite.pos, f32)
	camera.up = {0., 0., 1.}
	camera.fovy = 100
	camera.projection = .PERSPECTIVE
	rlgl.SetClipPlanes(0.001, 1000000.)


	for !rl.WindowShouldClose() {

		dt = rl.GetFrameTime()
		cum_time += dt * f32(time_scale)

		// update satellite
		if dt != 0. {
			ma.set_vector_slice(&xk, satellite.pos, satellite.vel)
			_, xk = integrate.rk4_step(
				ode.gravity_pointmass,
				f64(cum_time),
				xk,
				f64(dt) * time_scale,
				&gravity_params,
			)
			ma.set_vector_slice_1(&satellite.pos, xk, l1 = 3, s1 = 0)
			ma.set_vector_slice_1(&satellite.vel, xk, l1 = 3, s1 = 3)
			SetTranslation(
				&model_satellite.transform,
				la.array_cast(satellite.pos, f32),
			)
		}
		fmt.println(GetTranslation(model_satellite.transform))

		// update camera
		// camera.position = 1.5 * la.array_cast(satellite.pos / f64(KM_RL), f32) + {5,2,0}
		// camera.target = la.array_cast(satellite.pos / f64(KM_RL), f32)


		rl.BeginDrawing()
		rl.BeginMode3D(camera)
		rl.ClearBackground(rl.DARKGRAY)

		// draw axes
		// rl.DrawGrid(1000, 10)
		rl.DrawLine3D(origin, x_inertial * 10000, rl.RED)
		rl.DrawLine3D(origin, y_inertial * 10000, rl.GREEN)
		rl.DrawLine3D(origin, z_inertial * 10000, rl.BLUE)

		// draw line from center of earth to satellite
		rl.DrawLine3D(origin, GetTranslation(model_satellite.transform), rl.GOLD)

		// draw earth 
		rl.DrawModelWires(model_earth, origin, 1, rl.WHITE)

		// draw satellite
		rl.DrawModel(model_satellite, origin, 1, rl.WHITE)

		// draw satellite axes
		rl.DrawLine3D(
			GetTranslation(model_satellite.transform),
			GetTranslation(model_satellite.transform) + x_inertial * 100,
			rl.MAGENTA,
		)
		rl.DrawLine3D(
			GetTranslation(model_satellite.transform),
			GetTranslation(model_satellite.transform) + y_inertial * 100,
			rl.YELLOW,
		)
		rl.DrawLine3D(
			GetTranslation(model_satellite.transform),
			GetTranslation(model_satellite.transform) + z_inertial * 100,
			rl.PURPLE,
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

mat4row :: # row_major matrix[4, 4]f32
mat3row :: # row_major matrix[3, 3]f32
GetRotation :: proc(
	mat: # row_major matrix[4, 4]f32,
) -> # row_major matrix[3, 3]f32 {
	res: # row_major matrix[3, 3]f32
	res = mat3row(mat)
	return res
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
