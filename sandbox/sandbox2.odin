package sandbox

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:math/rand"
import tt "core:time"
import rl "vendor:raylib"

import ast "../astrolib"
import am "../astromath"


u_to_rl :: am.u_to_rl


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

	// create the earth
	earth := ast.wgs84()
	earth.gravity_model = .pointmass
	earth.max_degree = 2
	earth.fixed = true
	q := la.quaternion_from_euler_angle_x(math.to_radians(f64(23.5)))
	earth.ep = am.quaternion_to_euler_param(q)
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


	system := new(ast.AstroSystem)
	system^ = ast.create_system()

	ast.add_to_system(system, earth)
	ast.add_to_system(system, earth_model)

	// create satellite and add
	filename := "assets/ISS_TLE_HW7.txt"
	ast.tle_parse(filename, system.bodies[system.id[earth.id]], system)

	time: f64 = 0.

	total_time: f64 = (10) * 86400.
	dt: f64 = total_time / 10000.

	if math.abs(dt) > 100. {
		// set max dt
		dt = math.sign(dt) * 100.
	} else if math.abs(dt) < 1.0e-6 {
		// set min dt
		dt = math.sign(dt) * 1.0e-6
	}

	params_pointmass := ast.Params_Gravity_Pointmass {
		mu = earth.mu,
	}

	sat := &system.satellites[0]
	state_new: [6]f64
	tstart := tt.now()
	i := 0
	N_itr: int = 5.e4
	for itr := 0; itr < N_itr; itr += 1 {
		rando1 := rand.float64_uniform(1, 10)
		rando2 := rand.float64_uniform(10, 100)
		rando3 := rand.float64_normal(0, 10)
		state_current := am.posvel_to_state(sat.pos, sat.vel)
		state_current[0] += rando1
		state_current[1] += rando2
		_, _ = am.integrate_single_fixed(
			ast.gravity_pointmass,
			0,
			total_time,
			state_current,
			dt,
			params = &params_pointmass,
		)

		// for time < total_time {
		// 	rando1 := rand.float64_uniform(1, 10)
		// 	rando2 := rand.float64_uniform(10, 100)
		// 	rando3 := rand.float64_normal(0, 10)
		// 	state_current := am.posvel_to_state(sat.pos, sat.vel)
		// 	state_current[0] += rando1
		// 	state_current[1] += rando2
		// 	time, state_new = am.integrate_step(
		// 		ast.gravity_pointmass,
		// 		time,
		// 		state_current,
		// 		dt,
		// 		&params_pointmass,
		// 		.rk4,
		// 	)
		// 	sat.pos, sat.vel = am.state_to_posvel(state_new)
		// 	i += 1
		// }
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
		i,
		"\nNumber of runs: ",
		N_itr,
		"\nTotal computations: ",
		N_itr * i,
		sep = "",
	)

	dtt := am.compute_dt_iterative(
		-total_time,
		N_max = 10,
		dt_max = 10,
		dt_min = 1,
	)
	steps := math.abs(int(math.ceil(total_time / dtt)))
	fmt.println(dtt, steps)
}

