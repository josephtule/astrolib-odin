package main

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:mem"
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
	rl.SetWindowState({.WINDOW_RESIZABLE})
	// rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
	defer rl.CloseWindow()

	// generate celestial bodies
	celestialbodies: [dynamic]ast.CelestialBody
	celestialbody_models: [dynamic]ast.CelestialBodyModel

	earth := ast.wgs84()
	earth.gravity_model = .pointmass
	earth.max_degree = 2
	earth.fixed = true
	earth_model := ast.gen_celestialbody_model(f32(earth.semimajor_axis))
	ast.add_celestialbody(&celestialbodies, earth)
	ast.add_celestialbody_model(&celestialbody_models, earth_model)

	moon := ast.luna_params()
	moon.pos, moon.vel = ast.coe_to_rv(1e4, 0, 5.145, 0, 0, 0, earth.mu)
	moon.fixed = true
	moon_model := ast.gen_celestialbody_model(f32(moon.semimajor_axis))
	ast.add_celestialbody(&celestialbodies, moon)
	ast.add_celestialbody_model(&celestialbody_models, moon_model)


	// generate orbits/satellites
	num_sats := 8
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

		alt: f64 = 1000 //+ f64(i) * 100
		pos0 = (alt + earth.semimajor_axis) * [3]f64{1., 0., 0.}
		v_mag0 := math.sqrt(earth.mu / la.vector_length(pos0))
		angle0: f64 = la.to_radians(0. + f64(i) / f64(num_sats) * 360.)
		vel0 = v_mag0 * [3]f64{0., math.cos(angle0), math.sin(angle0)}
		ep0: [4]f64 = {0, 0, 0, 1}
		omega0: [3]f64 = {0.0001, .05, 0.0001}

		cube_size: f32 = 50 / 1000. * u_to_rl
		sat, sat_model := ast.gen_satellite_and_mesh(
			pos0,
			vel0,
			ep0,
			omega0,
			{cube_size, cube_size * 2, cube_size * 3},
		)
		sat.gravity_model = .zonal
		sat_model.draw_axes = true
		sat.inertia = matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		}
		ast.add_satellite(&satellites, sat)
		ast.add_satellite_model(&satellite_models, sat_model)
	}

	// misc --------------------------------------------------------------------
	// Inertial Frame
	origin: [3]f32 : {0, 0, 0}
	x_axis: [3]f32 : {1, 0, 0}
	y_axis: [3]f32 : {0, 1, 0}
	z_axis: [3]f32 : {0, 0, 1}

	// Time --------------------------------------------------------------------
	dt: f64
	cum_time: f64
	sim_time: f64
	fps: f64
	last_time := time.tick_now()

	// set up system
	asystem := new(ast.AstroSystem)
	asystem^ = ast.create_system(
		sats = satellites, // satellites
		sat_models = satellite_models,
		// bodies
		bodies = celestialbodies,
		body_models = celestialbody_models,
		integrator = .ralston,
	)
	asystem0 := new(ast.AstroSystem)
	ast.copy_system(asystem0, asystem)

	// 3D camera
	target_sat := num_sats / 8
	camera: rl.Camera3D
	camera.target = la.array_cast(origin, f32) * u_to_rl
	camera.position = am.azel_to_cart(
		[3]f32{15000 * u_to_rl, math.PI / 4, math.PI / 4},
	)
	camera.up = {0., 0., 1.}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE
	camera_params := CameraParams {
		azel       = am.cart_to_azel(la.array_cast(camera.position, f64)),
		target_sat = &asystem.satellites[target_sat],
		frame      = .origin,
	}

	for !rl.WindowShouldClose() {
		// dt = get_delta_time(time.tick_now(), &last_time)
		dt = f64(rl.GetFrameTime())
		// dt = 1. / 60.
		fps = 1. / dt
		cum_time += dt
		fmt.println(fps)

		// update
		update_system(asystem, asystem0)
		if asystem.simulate {
			for k := 0; k < asystem.substeps; k += 1 {
				sim_time += dt
				ast.update_system(asystem, dt, sim_time)
			}
		}

		// update camera
		update_camera(&camera, &camera_params, asystem, dt)

		// draw
		rl.BeginDrawing()
		rl.BeginMode3D(camera)
		// rlgl.SetClipPlanes(1.0e-3, 1.0e4)

		// rl.ClearBackground(rl.GetColor(0x181818ff))
		rl.ClearBackground(rl.Color({24, 24, 24, 255}))

		ast.draw_system(asystem)

		// draw inertial axes
		rl.DrawLine3D(origin, x_axis * 100, rl.RED)
		rl.DrawLine3D(origin, y_axis * 100, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 100, rl.DARKBLUE)

		// line from origin to satellite
		for sat, i in asystem.satellites {
			rl.DrawLine3D(origin, la.array_cast(sat.pos, f32) * u_to_rl, rl.GOLD)
		}

		rl.EndMode3D()
		// draw 2D stuff here
		rl.EndDrawing()
	}
}


get_delta_time :: proc(current: time.Tick, last: ^time.Tick) -> (dt: f64) {
	dt = f64(current._nsec - last._nsec) * 1.0e-9
	last^ = current
	return dt
}

update_system :: proc(system: ^ast.AstroSystem, system0: ^ast.AstroSystem) {
	using system
	// handle adding / removing bodies and satellites
	if rl.IsKeyPressed(.UP) && (f64(substeps) * time_scale < 100000) {
		substeps *= 2
	} else if rl.IsKeyPressed(.DOWN) && substeps > 1 {
		substeps /= 2
	}
	if rl.IsKeyPressed(.RIGHT) && (f64(substeps) * time_scale < 100000) {
		time_scale *= 2
	} else if rl.IsKeyPressed(.LEFT) {
		time_scale /= 2
	}
	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		substeps = 1
		time_scale = 1
	}
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		simulate = !simulate
	}
	if !rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyPressed(.R) {
		substeps = 1
		time_scale = 1
	}
	if rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyPressed(.R) {
		ast.copy_system(system, system0)
	}

}

update_camera :: proc(
	camera: ^rl.Camera,
	params: ^CameraParams,
	system: ^ast.AstroSystem,
	dt: f64,
) {
	// cycle through satellites/bodies
	if !rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyPressed(.N) {
		#partial switch params.frame {
		case .satellite: params.target_sat_id = (params.target_sat_id + 1) % system.num_satellites
		case .body: params.target_body_id = (params.target_body_id + 1) % system.num_bodies
		}
	} else if rl.IsKeyDown(.LEFT_CONTROL) && rl.IsKeyPressed(.N) {
		#partial switch params.frame {
		case .satellite: params.target_sat_id = (params.target_sat_id - 1 + system.num_satellites) % system.num_satellites
		case .body: params.target_body_id = (params.target_body_id - 1 + system.num_bodies) % system.num_bodies
		}
	}
	params.target_sat = &system.satellites[params.target_sat_id]
	params.target_body = &system.bodies[params.target_body_id]

	// switch camera type
	if rl.IsKeyPressed(rl.KeyboardKey.C) && !rl.IsKeyDown(.LEFT_CONTROL) {
		if params.frame == .origin {
			// switch to satellite
			params.azel = am.cart_to_azel([3]f64{1, 1, 1} * u_to_rl)
			params.frame = .satellite
		} else if params.frame == .satellite {
			params.azel = {10000 * u_to_rl, math.PI / 4, math.PI / 4}
			params.frame = .body
		} else if params.frame == .body {
			params.azel = {15000 * u_to_rl, math.PI / 4, math.PI / 4}
			params.frame = .origin
		} else  /* default to satellite camera*/{
			params.azel = am.cart_to_azel([3]f64{1, 1, 1} * u_to_rl)
			params.frame = .satellite
		}
	} else if rl.IsKeyPressed(.C) && rl.IsKeyDown(.LEFT_CONTROL) {
		params.frame = .locked
	}

	// camera movement
	if rl.GetMouseWheelMove() < 0 {
		params.azel.x *= 1.1
	} else if rl.GetMouseWheelMove() > 0 {
		params.azel.x /= 1.1
	}
	if rl.IsKeyDown(.A) {
		params.azel.y -= math.to_radians(f64(45.)) * dt
	}
	if rl.IsKeyDown(.D) {
		params.azel.y += math.to_radians(f64(45.)) * dt
	}
	if rl.IsKeyDown(.S) {
		params.azel.z -= math.to_radians(f64(45.)) * dt
	}
	if rl.IsKeyDown(.W) {
		params.azel.z += math.to_radians(f64(45.)) * dt
	}

	#partial switch params.frame {
	case .origin:
		rlgl.SetClipPlanes(1.0e-1, 1.0e3)
		camera.position = la.array_cast(
			am.azel_to_cart(la.array_cast(params.azel, f64)),
			f32,
		)
		camera.target = am.origin_f32
	case .satellite:
		sat_pos_f32 := la.array_cast(params.target_sat.pos, f32)
		camera.position =
			la.array_cast(am.azel_to_cart(la.array_cast(params.azel, f64)), f32) +
			sat_pos_f32 * u_to_rl
		camera.target = sat_pos_f32 * u_to_rl
		rlgl.SetClipPlanes(5.0e-5, 5e2)
	case .body:
		body_pos_f32 := la.array_cast(params.target_body.pos, f32)
		camera.position =
			la.array_cast(am.azel_to_cart(la.array_cast(params.azel, f64)), f32) +
			body_pos_f32 * u_to_rl
		camera.target = body_pos_f32 * u_to_rl
		rlgl.SetClipPlanes(5.0e-3, 5e3)
	case .locked:
	}


}

CameraType :: enum {
	origin = 0,
	satellite,
	body,
	locked,
}


CameraParams :: struct {
	azel:           [3]f64,
	target_sat:     ^ast.Satellite,
	target_sat_id:  int,
	target_body:    ^ast.CelestialBody,
	target_body_id: int,
	frame:          CameraType,
}
