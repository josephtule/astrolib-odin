package main

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import "core:mem"
import "core:strconv"
import "core:strings"
import "core:sys/info"
import "core:time"
import "core:unicode/utf8"

import ast "astrolib"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"


u_to_rl :: ast.u_to_rl
rl_to_u :: ast.rl_to_u

print_fps: bool
print_dtsim: bool

dt_max: f64 : 1. / 30.

main :: proc() {
	// raylib init
	window_width: i32 = 1024 / 2
	window_height: i32 = 1024 / 2
	// rl.SetConfigFlags({.WINDOW_TRANSPARENT, .MSAA_4X_HINT})
	rl.InitWindow(window_width, window_height, "AstroLib")
	rl.SetWindowState({.WINDOW_RESIZABLE})
	rl.SetTraceLogLevel(.NONE)
	// rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
	// rl.SetTargetFPS(60)
	defer rl.CloseWindow()

	// generate celestial bodies
	celestialbodies: [dynamic]ast.CelestialBody
	celestialbody_models: [dynamic]ast.Model

	earth := ast.wgs84()
	earth.gravity_model = .pointmass
	earth.max_degree = 2
	earth.fixed = true
	q := la.quaternion_from_euler_angle_x(math.to_radians(f64(23.5)))
	earth.ep = ast.quaternion_to_euler_param(q)
	earth.update_attitude = true
	model_size :=
		[3]f32 {
			f32(earth.semimajor_axis),
			f32(earth.semiminor_axis),
			f32(earth.semiminor_axis),
		} *
		u_to_rl
	earth_model := ast.gen_celestialbody_model(
		earth,
		model_size = model_size,
		faces = 128,
	)
	earth_model.axes.draw = true
	ast.add_celestialbody(&celestialbodies, earth)
	ast.add_model_to_array(&celestialbody_models, earth_model)

	rp := 22500.
	ra := 34000.
	a := (rp + ra) / 2.
	ecc := (ra - rp) / (ra + rp)
	moon := ast.luna_params()
	moon.semimajor_axis = 500.
	moon.pos, moon.vel = ast.coe_to_rv(a, ecc, 14, 120., 0, 140., earth)
	model_size =
		[3]f32 {
			f32(moon.semimajor_axis),
			f32(moon.semiminor_axis),
			f32(moon.semiminor_axis),
		} *
		u_to_rl
	moon_model := ast.gen_celestialbody_model(moon, model_size, tint = rl.GOLD)
	ast.add_celestialbody(&celestialbodies, moon)
	ast.add_model_to_array(&celestialbody_models, moon_model)

	rp = 10000.
	ra = 15000.
	a = (rp + ra) / 2.
	ecc = (ra - rp) / (ra + rp)
	moon2 := ast.luna_params()
	moon2.semimajor_axis = 400.
	moon2.pos, moon2.vel = ast.coe_to_rv(a, ecc, 45, 35., 15., 45., earth)
	moon2_model := ast.gen_celestialbody_model(
		moon2,
		model_size = model_size,
		tint = rl.RAYWHITE,
	)
	ast.add_celestialbody(&celestialbodies, moon2)
	ast.add_model_to_array(&celestialbody_models, moon2_model)


	rp = 30000.
	ra = 40320
	a = (rp + ra) / 2.
	ecc = (ra - rp) / (ra + rp)
	moon3 := ast.luna_params()
	moon3.semimajor_axis = 700.
	moon3.pos, moon3.vel = ast.coe_to_rv(a, ecc, 0, 45., 60., 180., earth)
	moon3_model := ast.gen_celestialbody_model(moon3, model_size, tint = rl.GREEN)
	ast.add_celestialbody(&celestialbodies, moon3)
	ast.add_model_to_array(&celestialbody_models, moon3_model)

	// generate orbits/satellites
	num_sats := 2
	satellites: [dynamic]ast.Satellite
	satellite_models: [dynamic]ast.Model
	for i := 0; i < num_sats; i += 1 {
		ta := math.lerp(0., 90., f64(i) / f64(num_sats))
		pos0, vel0 := ast.coe_to_rv(
			3.612664283480516e+04,
			0.83285,
			87.87,
			227.89,
			53.38,
			ta,
			earth,
		)

		alt: f64 = 15000 //+ f64(i) * 100
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
		sat_model.axes.draw = true
		ast.set_inertia(&sat, matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		})
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_model_to_array(&satellite_models, sat_model)
	}

	// gen satellite orbiting green body
	{
		pos0, vel0 := ast.coe_to_rv(1000, 0.01, 15., 227.89, 53.38, 10., moon3)
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
		sat_model.axes.draw = true
		ast.set_inertia(&sat, matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		})
		sat_model.posvel.target_id = moon3.id
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_model_to_array(&satellite_models, sat_model)
	}
	{
		pos0, vel0 := ast.coe_to_rv(1000, 0.01, 15., 227.89, 53.38, 75., moon3)
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
		sat_model.axes.draw = true
		ast.set_inertia(&sat, matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		})
		sat_model.posvel.target_id = moon3.id
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_model_to_array(&satellite_models, sat_model)
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
	ast.tle_parse(filename, earth, asystem, start_sat = 0, num_to_read = 20)
	// ast.tle_read_extract(filename, earth.id, asystem)

	filename = "assets/ISS_TLE_HW7.txt"
	ast.tle_parse(filename, asystem.bodies[asystem.id[earth.id]], asystem)


	for &model, i in asystem.satellite_models {
		model.scale = 5
	}

	fmt.println("Loaded the following satellites:")
	for sat in asystem.satellites {
		fmt.println(sat.info.name)
	}

	// create system copy for resetting
	asystem0 := new(ast.AstroSystem)
	ast.copy_system(asystem0, asystem)

	// 3D camera
	target_sat := num_sats / 8
	camera: rl.Camera3D
	camera.target = ast.cast_f32(origin) * u_to_rl
	camera.position = ast.azel_to_cart(
		[3]f32{math.PI / 4, math.PI / 4, 15000 * u_to_rl},
		.RADIANS,
	)
	camera.up = {0., 0., 1.}
	camera.fovy = 90
	camera.projection = .PERSPECTIVE
	camera_params := CameraParams {
		azel       = ast.cart_to_azel(ast.cast_f64(camera.position), .RADIANS),
		target_sat = &asystem.satellites[target_sat],
		frame      = .origin,
	}

	for !rl.WindowShouldClose() {
		// dt = get_delta_time(time.tick_now(), &last_time)
		dt = f64(rl.GetFrameTime())
		dt = dt < dt_max ? dt : dt_max // set dt max

		// update
		update_simulation(asystem, asystem0, dt)
		fps = 1. / dt
		cum_time += dt
		sim_time += dt * asystem.time_scale

		if print_fps {
			fmt.println(fps)
		}
		if print_dtsim {
			fmt.println(dt * asystem.time_scale)
		}

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
		rl.DrawLine3D(origin, x_axis * 25, rl.RED)
		rl.DrawLine3D(origin, y_axis * 25, rl.GREEN)
		rl.DrawLine3D(origin, z_axis * 25, rl.DARKBLUE)

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
	if rl.IsKeyPressed(.UP) && (f64(substeps) * time_scale < 10000) {
		substeps *= 2
	} else if rl.IsKeyPressed(.DOWN) && substeps > 1 {
		substeps /= 2
	}
	if rl.IsKeyPressed(.RIGHT) && (f64(substeps) * time_scale < 10000) {
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
	// fmt.println(dt_in_range_prev, dt_in_range_prev)
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
			ast.resize_trail(&satellite_models[i].trail, satellites[i].pos)
		}
	}
	if rl.IsKeyPressed(.T) {
		for &model, i in satellite_models {
			model.trail.draw = !model.trail.draw
			ast.reset_trail(&satellite_models[i].trail, satellites[i].pos)
		}
	}
	if rl.IsKeyPressed(.P) {
		for &model, i in satellite_models {
			model.posvel.draw_pos = !model.posvel.draw_pos
			model.posvel.draw_vel = !model.posvel.draw_vel
		}
	}
	if rl.IsKeyPressed(.O) {
		for &model, i in satellite_models {
			model.axes.draw = !model.axes.draw
		}
	}
	if rl.IsKeyPressed(.I) {
		for &sat in satellites {
			sat.update_attitude = !sat.update_attitude
		}
	}

	N_trail_sat_inc := 50

	if rl.IsKeyPressed(.LEFT_BRACKET) &&
	   !rl.IsKeyDown(.LEFT_SHIFT) &&
	   (ast.N_trail_sat - N_trail_sat_inc >= 50) {
		ast.N_trail_sat -= N_trail_sat_inc

		ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		if ast.mod_trail_sat == 0 {
			ast.mod_trail_sat = 1
		}
		for &model, i in satellite_models {
			ast.resize_trail(&satellite_models[i].trail, satellites[i].pos)
		}
	}
	if rl.IsKeyPressed(.RIGHT_BRACKET) &&
	   !rl.IsKeyDown(.LEFT_SHIFT) &&
	   (ast.N_trail_sat + N_trail_sat_inc <= ast.N_trail_MAX) {
		ast.N_trail_sat += N_trail_sat_inc

		ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		for &model, i in satellite_models {
			ast.resize_trail(&satellite_models[i].trail, satellites[i].pos)
		}
	}
	if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.LEFT_BRACKET) {
		ast.div_trail_sat /= 2
		ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		if ast.mod_trail_sat >= ast.N_trail_sat {
			ast.div_trail_sat *= 2
			ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		}
		for &model, i in satellite_models {
			ast.resize_trail(&satellite_models[i].trail, satellites[i].pos)
		}
		fmt.println(ast.N_trail_sat, ast.mod_trail_sat)
	}
	if rl.IsKeyDown(.LEFT_SHIFT) && rl.IsKeyPressed(.RIGHT_BRACKET) {
		ast.div_trail_sat *= 2
		ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		if ast.mod_trail_sat == 0 {
			ast.div_trail_sat /= 2
			ast.mod_trail_sat = ast.N_trail_sat / ast.div_trail_sat
		}
		for &model, i in satellite_models {
			ast.resize_trail(&satellite_models[i].trail, satellites[i].pos)
		}
		fmt.println(ast.N_trail_sat, ast.mod_trail_sat)
	}

	if !rl.IsKeyDown(.RIGHT_SHIFT) && rl.IsKeyPressed(.PERIOD) {
		earth := bodies[0] // TODO: change this later
		orbittype := ast.OrbitType(rand.int_max(3))
		// pos0, vel0 := ast.gen_rand_coe_orientation(10000, 0.1, earth)
		pos0, vel0 := ast.gen_rand_coe_earth(earth, orbittype)
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
		sat_model.axes.draw = true
		ast.set_inertia(&sat, matrix[3, 3]f64{
			100., 0., 0., 
			0., 200., 0., 
			0., 0., 300., 
		})
		sat.update_attitude = true
		ast.add_satellite(&satellites, sat)
		ast.add_model_to_array(&satellite_models, sat_model)
		fmt.println("Added satellite (ID):", sat.id)
	}
	if rl.IsKeyDown(.RIGHT_SHIFT) && rl.IsKeyPressed(.PERIOD) {
		for i := 0; i < 25; i += 1 {
			earth := bodies[0] // TODO: change this later
			// add satellite to system here

			pos0, vel0 := ast.gen_rand_coe_orientation(10000, 0.1, earth)
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
			sat_model.axes.draw = true
			ast.set_inertia(&sat, matrix[3, 3]f64{
				100., 0., 0., 
				0., 200., 0., 
				0., 0., 300., 
			})
			sat.update_attitude = true
			ast.add_satellite(&satellites, sat)
			ast.add_model_to_array(&satellite_models, sat_model)
			fmt.println("Added satellite (ID):", sat.id)
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
			params.azel = ast.cart_to_azel([3]f64{1, 1, 1} * u_to_rl, .RADIANS)
			params.frame = .satellite
			fmt.println(params.azel)
		} else if params.frame == .satellite {
			params.azel = {math.PI / 4, math.PI / 4, 10000 * u_to_rl}
			params.frame = .body
		} else if params.frame == .body {
			params.azel = {math.PI / 4, math.PI / 4, 15000 * u_to_rl}
			params.frame = .origin
		} else  /* default to satellite camera*/{
			params.azel = ast.cart_to_azel([3]f64{1, 1, 1} * u_to_rl)
			params.frame = .satellite
		}
	} else if rl.IsKeyPressed(.C) && rl.IsKeyDown(.LEFT_SHIFT) {
		params.frame = .locked
	}
	// camera movement
	if rl.GetMouseWheelMove() < 0 {
		params.azel.z *= 1.1
	} else if rl.GetMouseWheelMove() > 0 {
		params.azel.z /= 1.1
	}
	if rl.IsKeyDown(.A) {
		params.azel.x -= math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.D) {
		params.azel.x += math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.S) {
		params.azel.y -= math.to_radians(f64(90.)) * dt
	}
	if rl.IsKeyDown(.W) {
		params.azel.y += math.to_radians(f64(90.)) * dt
	}

	#partial switch params.frame {
	case .origin:
		rlgl.SetClipPlanes(1.0e-1, 1.0e3)
		camera.position = ast.cast_f32(
			ast.azel_to_cart(ast.cast_f64(params.azel), .RADIANS),
		)
		camera.target = ast.origin_f32
	case .satellite:
		sat_pos_f32 := ast.cast_f32(params.target_sat.pos)
		camera.position =
			ast.cast_f32(ast.azel_to_cart(ast.cast_f64(params.azel), .RADIANS)) +
			sat_pos_f32 * u_to_rl
		camera.target = sat_pos_f32 * u_to_rl
		rlgl.SetClipPlanes(5.0e-5, 5e2)
	case .body:
		body_pos_f32 := ast.cast_f32(params.target_body.pos)
		camera.position =
			ast.cast_f32(ast.azel_to_cart(ast.cast_f64(params.azel), .RADIANS)) +
			body_pos_f32 * u_to_rl
		camera.target = body_pos_f32 * u_to_rl
		rlgl.SetClipPlanes(5.0e-3, 5e3)
	case .locked:
	}

	if rl.IsKeyPressed(.F) {
		print_fps = !print_fps
	}
	if rl.IsKeyPressed(.G) {
		print_dtsim = !print_dtsim
	}


}

CameraType :: enum {
	origin = 0,
	satellite,
	body,
	locked,
}


CameraParams :: struct {
	azel:           [3]f64, // TODO: change to degrees
	target_sat:     ^ast.Satellite,
	target_sat_id:  int,
	target_body:    ^ast.CelestialBody,
	target_body_id: int,
	frame:          CameraType,
}
