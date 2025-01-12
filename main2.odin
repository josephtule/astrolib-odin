package main

import "base:intrinsics"
import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

import ast "astrolib"
import am "astromath"
import ode "ode"
import rl "vendor:raylib"
import "vendor:raylib/rlgl"

u_to_rl :: am.u_to_rl
rl_to_u :: am.rl_to_u

main :: proc() {

	// raylib init
	window_width: i32 = 1024
	window_height: i32 = 1024
	rl.SetConfigFlags({.WINDOW_TRANSPARENT, .MSAA_4X_HINT})
	rl.InitWindow(window_width, window_height, "AstroLib")
	rl.SetWindowState({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
	defer rl.CloseWindow()

	// generate celestial bodies
	earth := ast.wgs84()
	celestialbodies: [dynamic]ast.CelestialBody
	celestialbody_models: [dynamic]ast.CelestialBodyModel

	ast.add_celestialbody(&celestialbodies, earth)

	// generate orbits/satellites
	num_sats := 10
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


}
