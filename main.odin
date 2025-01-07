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
	window_width: i32 = 1920
	window_height: i32 = 1080
	rl.InitWindow(window_width, window_height, "Test")
	rl.SetWindowState({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT})
	rl.SetTargetFPS(60)
	defer rl.CloseWindow()


	// Textures ----------------------------------------------------------------
	// Satellite
	image_checker := rl.GenImageChecked(2, 2, 1, 1, rl.GOLD, rl.SKYBLUE)
	texture_satellite := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)
	image_checker = rl.GenImageChecked(
		2,
		2,
		1,
		1,
		rl.Color({30, 102, 245, 255}),
		rl.BLUE,
	)
	texture_earth := rl.LoadTextureFromImage(image_checker)
	rl.UnloadImage(image_checker)


	// Earth -------------------------------------------------------------------
	// Physical Parameters
	earth: ast.CelestialBody = ast.wgs84()
	// Earth Mesh
	model_earth := rl.LoadModelFromMesh(
		rl.GenMeshSphere(f32(earth.semimajor_axis), 120, 120),
	)
	model_earth.materials[0].maps[rl.MaterialMapIndex.ALBEDO].texture =
		texture_earth

	// Satellite ---------------------------------------------------------------
	// Orbit
	alt: f64 = 1000
	pos0: [3]f64 = (alt + earth.semimajor_axis) * [3]f64{1., 0., 0.}
	v_mag0 := math.sqrt(earth.mu / la.vector_length(pos0))
	angle0: f64 = la.to_radians(25.)
	vel0: [3]f64 = v_mag0 * [3]f64{0., math.cos(angle0), math.sin(angle0)}
	ep0: [4]f64 = {0, 0, 0, 1}
	omega0: [3]f64 = {.05, .05, .1}
	// Physical Parameters
	satellite := ast.Satellite {
		pos   = pos0,
		vel   = vel0,
		ep    = ep0,
		omega = omega0,
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
	x_axis: [3]f32 : {1, 0, 0}
	y_axis: [3]f32 : {0, 1, 0}
	z_axis: [3]f32 : {0, 0, 1}

	// Time --------------------------------------------------------------------
	dt: f32
	cum_time: f32
	time_scale: f64 = 1
	fps: f64
	substeps: int = 1

	// 3D camera
	camera: rl.Camera3D
	// camera.position = 1.001 * la.array_cast(satellite.pos, f32) + {15, 15, 0}
	camera.position = {1., 1., 1.} * 8000
	camera.target = la.array_cast(satellite.pos, f32)
	camera.up = {0., 0., 1.}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE

	paused: bool = true
	draw_trails: bool = true
	wires: bool = true
	camera_type :: enum {
		origin = 0,
		satellite,
	}

	cam_frame := camera_type.satellite

	for !rl.WindowShouldClose() {

		if rl.IsKeyPressed(.W) && (f64(substeps) * time_scale < 100000) {
			substeps *= 2
		} else if rl.IsKeyPressed(.S) && substeps > 1 {
			substeps /= 2
		}
		if rl.IsKeyPressed(.D) && (f64(substeps) * time_scale < 100000) {
			time_scale *= 2
		} else if rl.IsKeyPressed(.A) {
			time_scale /= 2
		}
		if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
			substeps = 1
			time_scale = 1
		}

		dt = rl.GetFrameTime()

		if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
			paused = !paused
		}

		if rl.IsKeyPressed(rl.KeyboardKey.C) {
			if cam_frame == .origin {
				cam_frame = .satellite
			} else {
				cam_frame = .origin
			}
		}

		if rl.IsKeyPressed(.R) {
			reset_state(&satellite, pos0, vel0, omega0, ep0, draw_trails, &trail_pos)
		}

		// update satellite
		if dt != 0. && !paused {
			cum_time += dt * f32(time_scale)
			fps = 1 / f64(dt)
			for k := 0; k < substeps; k += 1 {
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
		}

		N_R_B_3x3 := GetRotation(model_satellite.transform)
		sat_pos_f32 := la.array_cast(satellite.pos, f32)

		// update camera
		switch cam_frame {
		case .origin:
			rlgl.SetClipPlanes(10, 1000000.)
			camera.position = {1., 1., 1.} * 8000
			camera.target = origin
		case .satellite:
			camera.position = 1.1 * sat_pos_f32 + {250, 250, 0}
			camera.target = sat_pos_f32
			rlgl.SetClipPlanes(1, 10000.)
		}

		// update trail buffer
		trail_pos[trail_ind] = la.array_cast(satellite.pos, f32)
		trail_ind = (trail_ind + 1) % N_trail

		rl.BeginDrawing()
		rl.BeginMode3D(camera)
		rl.ClearBackground(rl.GetColor(0x181818FF))

		// draw axes
		rl.DrawLine3D(origin, x_axis * 10000, rl.RED)
		rl.DrawLine3D(origin, y_axis * 10000, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 10000, rl.DARKBLUE)

		// draw line from center of earth to satellite
		rl.DrawLine3D(origin, sat_pos_f32, rl.GOLD)


		if rl.IsKeyPressed(rl.KeyboardKey.T) {
			draw_trails = !draw_trails
			if draw_trails {
				for i := 0; i < N_trail; i += 1 {
					trail_pos[i] = sat_pos_f32
				}
				trail_ind := 0
			}
		}
		// draw trail
		if draw_trails {
			for i := 0; i < N_trail - 1; i += 1 {
				current := (trail_ind + i) % N_trail
				next := (current + 1) % N_trail
				rl.DrawLine3D(trail_pos[current], trail_pos[next], rl.RAYWHITE)
			}
		}

		if rl.IsKeyPressed(.Q) {
			wires = !wires
		}
		if wires {
			// draw earth 
			rl.DrawModelWires(model_earth, origin, 1, rl.WHITE)
			// draw satellite
			rl.DrawModelWires(model_satellite, origin, 1, rl.WHITE)
		} else {
			// draw earth 
			rl.DrawModel(model_earth, origin, 1, rl.WHITE)
			// draw satellite
			rl.DrawModel(model_satellite, origin, 1, rl.WHITE)
		}

		// draw satellite axes
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (x_axis * cube_size * 10),
			rl.MAGENTA,
		)
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (y_axis * cube_size * 10),
			rl.YELLOW,
		)
		rl.DrawLine3D(
			sat_pos_f32,
			sat_pos_f32 + N_R_B_3x3 * (z_axis * cube_size * 10),
			rl.Color({0, 255, 255, 255}),
		)

		rl.EndMode3D()
		RenderSimulationInfo(fps, substeps, time_scale)
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
RenderSimulationInfo :: proc(fps: f64, substeps: int, time_scale: f64) {
	fontsize: i32 = 10
	// fps
	posy: i32 = fontsize
	fps_str := strings.builder_make()
	strings.write_string(&fps_str, "FPS: ")
	strings.write_float(&fps_str, fps, fmt = 'f', prec = 3, bit_size = 64)
	rl.DrawText(strings.to_cstring(&fps_str), 10, posy, fontsize, rl.WHITE)

	// time scale
	posy = fontsize * 2
	ts_str := strings.builder_make()
	strings.write_string(&ts_str, "Time Scale: ")
	strings.write_float(&ts_str, time_scale, fmt = 'f', prec = 4, bit_size = 64)
	rl.DrawText(strings.to_cstring(&ts_str), 10, posy, fontsize, rl.WHITE)
	// substeps
	posy = fontsize * 3
	sub_str := strings.builder_make()
	strings.write_string(&sub_str, "Substeps: ")
	strings.write_int(&sub_str, substeps, 10)
	rl.DrawText(strings.to_cstring(&sub_str), 10, posy, fontsize, rl.WHITE)

	// controls
	posy = fontsize * 5
	controls_str := `Controls:
				Adjust Time Scale: [UP, DOWN]
				Adjust Substeps: [LEFT, RIGHT]
				Reset Time/Steps: [ENTER]
				Pause: [SPACE]
				Trails: [T]
				Camera: [C]`


	rl.DrawText(strings.clone_to_cstring(controls_str), 10, posy, 10, rl.WHITE)
}

reset_state :: proc(
	satellite: ^ast.Satellite,
	pos0, vel0, omega0: [3]f64,
	ep0: [4]f64,
	draw_trails: bool,
	trail_pos: ^[$N][3]f32,
) {
	satellite.pos = pos0
	satellite.vel = vel0
	satellite.ep = ep0
	satellite.omega = omega0
	if draw_trails {
		for i := 0; i < N; i += 1 {
			trail_pos[i] = la.array_cast(pos0, f32)
		}
		trail_ind := 0
	}
}
