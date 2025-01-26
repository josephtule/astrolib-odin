package sandbox

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import tt "core:time"
import rl "vendor:raylib"

import ast "../astrolib"


main3 :: proc() {
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

	// create the earth
	earth := ast.wgs84()
	earth.gravity_model = .zonal
	earth.max_degree = 4
	earth.max_order = 4
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
		ast.u_to_rl
	earth_model := ast.gen_celestialbody_model(
		earth,
		model_size = model_size,
		faces = 128,
	)
	earth_model.axes.draw = true


	system := new(ast.AstroSystem)
	system^ = ast.create_system()

	ast.add_to_system(system, earth)
	ast.add_to_system(system, earth_model)

	// create satellite and add
	filename := "assets/ISS_TLE_HW7.txt"
	ast.tle_parse(filename, system.bodies[system.id[earth.id]], system)

	time: f64 = 0.
	total_time: f64 = (10) * 86400.
	dt := ast.compute_dt_inrange(total_time, 2500, dt_max = 100)
	n_steps := math.abs(int(math.ceil(total_time / dt)))
	fmt.println("dt:", dt)

	sat := &system.satellites[0]
	sat.gravity_model = .zonal

	lowest_model: ast.GravityModel = min(sat.gravity_model, earth.gravity_model)

	params := &ast.Params_Gravity_Onebody {
		body = earth,
		self_mass = sat.mass,
		self_radius = sat.radius,
		gravity_model = sat.gravity_model,
	}

	state: [6]f64
	tstart := tt.now()
	N_itr: int : 1000

	for itr := 0; itr < N_itr; itr += 1 {
		state = ast.posvel_to_state(sat.pos, sat.vel)
		// rando1 := rand.float64_uniform(0, 10)
		// rando2 := rand.float64_uniform(0, 10)
		// rando3 := rand.float64_normal(0, 10)
		// state[0] += rando1
		// state[1] += rando2
		// state[2] += rando3
		_, _ =ast.integrate_single_fixed(
			ast.gravity_onebody,
			0,
			total_time,
			state,
			dt,
			params,
			integrator = .ralston,
		) // TODO: add adaptive later
	}
	telapsed := tt.duration_milliseconds(tt.diff(tstart, tt.now()))
	fmt.println(
		"Elapsed time: ",
		telapsed,
		"ms\n",
		"Average time: ",
		telapsed / f64(N_itr),
		"ms\n",
		"Number of iterations: ",
		n_steps,
		"\nNumber of runs: ",
		N_itr,
		"\nTotal computations: ",
		N_itr * n_steps,
		sep = "",
	)

	dtt := ast.compute_dt_iterative(
		-total_time,
		N_max = 10,
		dt_max = 10,
		dt_min = 1,
	)
	steps := math.abs(int(math.ceil(total_time / dtt)))

	// fmt.println(dtt, steps)
	// for state in states {
	// 	pos, vel := state_to_posvel(state)
	// 	fmt.println(mag(pos))
	// }
	radec := ast.cart_to_radec([3]f64{1., 2, 3})
	fmt.println(radec)
	val := ast.convert_linear(f64(10.), .METER, .FOOT)
	fmt.println(val)
}
