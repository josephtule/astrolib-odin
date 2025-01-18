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
	window_width: i32 = 1024 / 2
	window_height: i32 = 1024 / 2
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
	earth_model := ast.gen_celestialbody_model(
		f32(earth.semimajor_axis),
		faces = 128,
	)
	ast.add_celestialbody(&celestialbodies, earth)
	ast.add_celestialbody_model(&celestialbody_models, earth_model)

	rp := 22500.
	ra := 34000.
	a := (rp + ra) / 2.
	ecc := (ra - rp) / (ra + rp)
	moon := ast.luna_params()
	moon.semimajor_axis = 500.
	moon.pos, moon.vel = ast.coe_to_rv(a, ecc, 14, 120., 0, 140., earth.mu)
	moon_model := ast.gen_celestialbody_model(
		f32(moon.semimajor_axis),
		tint = rl.GOLD,
	)
	ast.add_celestialbody(&celestialbodies, moon)
	ast.add_celestialbody_model(&celestialbody_models, moon_model)

	rp = 10000.
	ra = 15000.
	a = (rp + ra) / 2.
	ecc = (ra - rp) / (ra + rp)
	moon2 := ast.luna_params()
	moon2.semimajor_axis = 400.
	moon2.pos, moon2.vel = ast.coe_to_rv(a, ecc, 45, 35., 15., 45., earth.mu)
	moon2_model := ast.gen_celestialbody_model(
		f32(moon2.semimajor_axis),
		tint = rl.RAYWHITE,
	)
	ast.add_celestialbody(&celestialbodies, moon2)
	ast.add_celestialbody_model(&celestialbody_models, moon2_model)


	rp = 30000.
	ra = 40320
	a = (rp + ra) / 2.
	ecc = (ra - rp) / (ra + rp)
	moon3 := ast.luna_params()
	moon3.semimajor_axis = 700.
	moon3.pos, moon3.vel = ast.coe_to_rv(a, ecc, 0, 45., 60., 180., earth.mu)
	moon3_model := ast.gen_celestialbody_model(
		f32(moon3.semimajor_axis),
		tint = rl.GREEN,
	)
	ast.add_celestialbody(&celestialbodies, moon3)
	ast.add_celestialbody_model(&celestialbody_models, moon3_model)

	// generate orbits/satellites
	num_sats := 2
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

		alt: f64 = 25702 //+ f64(i) * 100
		pos0 = (alt + earth.semimajor_axis) * [3]f64{1., 0., 0.}
		v_mag0 := math.sqrt(earth.mu / la.vector_length(pos0))
		angle0: f64 = la.to_radians(0. + f64(i) / f64(num_sats) * 360.)
		vel0 = v_mag0 * [3]f64{0., math.cos(angle0), math.sin(angle0)}
		ep0: [4]f64 = {0, 0, 0, 1}
		omega0: [3]f64 = {0.0001, .05, 0.0001}

		cube_size: f32 = 50 / 1000. * u_to_rl
		sat, sat_model := ast.gen_sat_and_model(
			pos0,
			vel0,
			ep0,
			omega0,
			{cube_size, cube_size * 2, cube_size * 3},
		)
		sat.gravity_model = .pointmass
		sat_model.draw_axes = true
		sat.inertia = matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		}
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_satellite_model(&satellite_models, sat_model)
	}

	// gen satellite orbiting green body
	{
		pos0, vel0 := ast.coe_to_rv(1000, 0.01, 15., 227.89, 53.38, 10., moon3.mu)
		pos0 = pos0 + moon3.pos
		vel0 = vel0 + moon3.vel
		ep0: [4]f64 = {0, 0, 0, 1}
		omega0: [3]f64 = {0.0001, .05, 0.0001}
		cube_size: f32 = 50 / 1000. * u_to_rl
		sat, sat_model := ast.gen_sat_and_model(
			pos0,
			vel0,
			ep0,
			omega0,
			{cube_size, cube_size * 2, cube_size * 3},
		)
		sat.gravity_model = .pointmass
		sat_model.draw_axes = true
		sat.inertia = matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		}
		sat_model.target_id = moon3.id
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_satellite_model(&satellite_models, sat_model)
	}
	{
		pos0, vel0 := ast.coe_to_rv(1000, 0.01, 15., 227.89, 53.38, 75., moon3.mu)
		pos0 = pos0 + moon3.pos
		vel0 = vel0 + moon3.vel
		ep0: [4]f64 = {0, 0, 0, 1}
		omega0: [3]f64 = {0.0001, .05, 0.0001}
		cube_size: f32 = 50 / 1000. * u_to_rl
		sat, sat_model := ast.gen_sat_and_model(
			pos0,
			vel0,
			ep0,
			omega0,
			{cube_size, cube_size * 2, cube_size * 3},
		)
		sat.gravity_model = .pointmass
		sat_model.draw_axes = true
		sat.inertia = matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		}
		sat_model.target_id = moon3.id
		sat.update_attitude = true
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
		// integrator = .rk4,
	)

	// gen satellites from tle
	filename := "assets/TLE_data.txt"
	ast.tle_read_extract(
		filename,
		earth.id,
		asystem,
		start_sat = 2492,
		num_to_read = 24,
	)
	// ast.tle_read_extract(filename, earth.id, asystem)

	filename = "assets/ISS_TLE_HW7.txt"
	ast.tle_read_extract(filename, earth.id, asystem)

	fmt.println("Loaded the following satellites:")
	for sat in asystem.satellites {
		fmt.println(sat.name)
	}
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
		// fmt.println(fps)

		// update
		update_simulation(asystem, asystem0, dt)
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
		rl.DrawLine3D(origin, x_axis * 10, rl.RED)
		rl.DrawLine3D(origin, y_axis * 10, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 10, rl.DARKBLUE)

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

update_simulation :: proc(
	system: ^ast.AstroSystem,
	system0: ^ast.AstroSystem,
	dt: f64,
) {
	using system

	dt_max_attitude := 2.


	time_scale_prev := time_scale
	substeps_prev := substeps

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
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		simulate = !simulate
	}

	dt_in_range_prev := dt * time_scale_prev <= dt_max_attitude
	dt_in_range_new := dt * time_scale <= dt_max_attitude
	time_scale_changed := time_scale_prev != time_scale
	substeps_changed := substeps_prev != substeps
	// fmt.println("dt sim: ", dt * time_scale)
	fmt.println(dt_in_range_prev, dt_in_range_prev)
	// TODO: save state for attitude then update accordingly, currently turns all attitude on
	// NOTE: attitude switches only when time_scale changes for now
	if (dt_in_range_prev && !dt_in_range_new) &&
	   (time_scale_changed || substeps_changed) {
		// turn off attitude
		for &sat in satellites {
			sat.update_attitude = false
		}
	} else if (!dt_in_range_prev && dt_in_range_new) &&
	   (time_scale_changed || substeps_changed) {
		for &sat in satellites {
			sat.update_attitude = true
		}
	}

	if !rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.R) {
		// TODO: handle this later
		substeps = 8
		time_scale = 8
	}
	if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.R) {
		ast.copy_system(system, system0)
		for &model, i in satellite_models {
			ast.reset_sat_trail(&satellites[i], &model)
		}
	}
	if rl.IsKeyPressed(.T) {
		for &model, i in satellite_models {
			model.draw_trail = !model.draw_trail
			ast.reset_sat_trail(&satellites[i], &model)
		}
	}
	if rl.IsKeyPressed(.P) {
		for &model, i in satellite_models {
			model.draw_pos = !model.draw_pos
		}
	}
	if rl.IsKeyPressed(.O) {
		for &model, i in satellite_models {
			model.draw_axes = !model.draw_axes
		}
	}
	if rl.IsKeyPressed(.I) {
		for &sat in satellites {
			sat.update_attitude = !sat.update_attitude
		}
	}

}

update_camera :: proc(
	camera: ^rl.Camera,
	params: ^CameraParams,
	system: ^ast.AstroSystem,
	dt: f64,
) {
	// cycle through satellites/bodies
	if !rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.N) {
		#partial switch params.frame {
		case .satellite: params.target_sat_id = (params.target_sat_id + 1) % system.num_satellites
		case .body: params.target_body_id = (params.target_body_id + 1) % system.num_bodies
		}
	} else if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.N) {
		#partial switch params.frame {
		case .satellite: params.target_sat_id = (params.target_sat_id - 1 + system.num_satellites) % system.num_satellites
		case .body: params.target_body_id = (params.target_body_id - 1 + system.num_bodies) % system.num_bodies
		}
	}
	params.target_sat = &system.satellites[params.target_sat_id]
	params.target_body = &system.bodies[params.target_body_id]

	// switch camera type
	if rl.IsKeyPressed(rl.KeyboardKey.C) && !rl.IsKeyDown(.LEFT_SHIFT) {
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
	} else if rl.IsKeyPressed(.C) && rl.IsKeyDown(.LEFT_SHIFT) {
		params.frame = .locked
	}

	// camera movement
	if rl.GetMouseWheelMove() < 0 {
		params.azel.x *= 1.1
	} else if rl.GetMouseWheelMove() > 0 {
		params.azel.x /= 1.1
	}
	if rl.IsKeyDown(.A) {
		params.azel.y -= math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.D) {
		params.azel.y += math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.S) {
		params.azel.z -= math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.W) {
		params.azel.z += math.to_radians(f64(90.)) * dt
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
