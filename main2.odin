package main

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"

import ast "astrolib"
import am "astromath"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"


u_to_rl :: am.u_to_rl
rl_to_u :: am.rl_to_u

main :: proc() {

	// raylib init
	window_width: i32 = 1024
	window_height: i32 = 1024
	// rl.SetConfigFlags({.WINDOW_TRANSPARENT, .MSAA_4X_HINT})
	rl.InitWindow(window_width, window_height, "AstroLib")
	rl.SetWindowState({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
	defer rl.CloseWindow()

	// generate celestial bodies
	celestialbodies: [dynamic]ast.CelestialBody
	celestialbody_models: [dynamic]ast.CelestialBodyModel

	earth := ast.wgs84()
	earth_model := ast.gen_celestialbody_model(f32(earth.semimajor_axis))
	ast.add_celestialbody(&celestialbodies, earth)
	ast.add_celestialbody_model(&celestialbody_models, earth_model)

	// moon := ast.luna_params()
	// moon.pos = {100000., 1000, 1000}
	// moon_model := ast.gen_celestialbody_model(f32(moon.semimajor_axis))
	// ast.add_celestialbody(&celestialbodies, moon)
	// ast.add_celestialbody_model(&celestialbody_models, moon_model)


	// generate orbits/satellites
	num_sats := 1
	satellites: [dynamic]ast.Satellite
	satellite_models: [dynamic]ast.SatelliteModel
	for i := 0; i < num_sats; i += 1 {
		ta := math.lerp(0., 90., f64(i) / f64(num_sats))
		pos0, vel0 := ast.coe_to_rv(
			3.612664283480516e+04,
			0.83285,
			87.87,
			227.89,
			53.38,
			ta,
			earth.mu,
		)

		ep0: [4]f64 = {0, 0, 0, 1}
		omega0: [3]f64 = {0.0001, .05, 0.0001}

		cube_size: f32 = 50 / 1000. * u_to_rl
		sat, sat_model := ast.gen_satellite_and_mesh(
			pos0,
			vel0,
			ep0,
			omega0,
			cube_size,
		)

		ast.add_satellite(&satellites, sat)
		ast.add_satellite_model(&satellite_models, sat_model)
	}

	// misc --------------------------------------------------------------------
	// Inertial Frame
	origin: [3]f32 : {0, 0, 0}
	x_axis: [3]f32 : {1, 0, 0}
	y_axis: [3]f32 : {0, 1, 0}
	z_axis: [3]f32 : {0, 0, 1}

	// attitude dynamics params
	attitude_params := ast.Params_EulerParam {
		inertia = matrix[3, 3]f64{
			100, 0, 0, 
			0, 200, 0, 
			0, 0, 300, 
		},
		torque  = {0, 0, 0},
	}

	// Time --------------------------------------------------------------------
	dt: f64
	cum_time: f64
	real_time: f64
	time_scale: f64 = 1
	fps: f64
	substeps: int = 256
	last_time := time.tick_now()

	// 3D camera
	camera: rl.Camera3D
	// camera.position = 1.001 * la.array_cast(satellite.pos, f32) + {15, 15, 0}
	camera_azel := am.cart_to_azel([3]f64{10000, 10000, 10000} * u_to_rl)
	camera.target = la.array_cast(origin, f32) * u_to_rl
	camera.position =
		am.azel_to_cart(la.array_cast(camera_azel, f32)) + camera.target
	camera.up = {0., 0., 1.}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE

	asystem := ast.AstroSystem {
		// satellites
		satellites       = satellites,
		satellite_models = satellite_models,
		// satellite_odeparams: [dynamic]rawptr,
		// bodies
		bodies           = celestialbodies,
		body_models      = celestialbody_models,
		// body_odeparams:      [dynamic]rawptr,
		// integrator
		integrator       = .rk4,
		time_scale       = time_scale,
	}

	for !rl.WindowShouldClose() {
		// dt = get_delta_time(time.tick_now(), &last_time)
		// dt = f64(rl.GetFrameTime())
		dt = 1. / 60.
		fps = 1. / dt
		cum_time += dt

		// update
		for k := 0; k < substeps; k += 1 {
			ast.update_system(&asystem, dt, cum_time)
		}

		// draw
		rl.BeginDrawing()
		rl.BeginMode3D(camera)
		rlgl.SetClipPlanes(1.0e-3, 1.0e4)

		// rl.ClearBackground(rl.GetColor(0x181818ff))
		rl.ClearBackground(rl.Color({24, 24, 24, 255}))

		ast.draw_system(&asystem)

		// draw inertial axes
		rl.DrawLine3D(origin, x_axis * 100, rl.RED)
		rl.DrawLine3D(origin, y_axis * 100, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 100, rl.DARKBLUE)

		// line from origin to satellite
		for sat, i in asystem.satellites {
			rl.DrawLine3D(origin, la.array_cast(sat.pos, f32) * u_to_rl, rl.GOLD)
		}

		rl.EndMode3D()

		rl.EndDrawing()
	}
}


get_delta_time :: proc(current: time.Tick, last: ^time.Tick) -> (dt: f64) {
	dt = f64(current._nsec - last._nsec) * 1.0e-9
	last^ = current
	return dt
}
