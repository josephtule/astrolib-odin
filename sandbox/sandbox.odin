package sandbox

import ast "../astrolib"
import am "../astromath"


import "core:fmt"
import "core:math"
import la "core:math/linalg"
import "core:os"
import "core:strconv"
import str "core:strings"
import "core:time"
import rl "vendor:raylib"


main :: proc() {
	// raylib init
	window_width: i32 = 1024
	window_height: i32 = 1024
	// rl.SetConfigFlags({.WINDOW_TRANSPARENT, .MSAA_4X_HINT})
	rl.InitWindow(window_width, window_height, "AstroLib")
	rl.SetWindowState({.WINDOW_RESIZABLE})
	// rl.SetTargetFPS(rl.GetMonitorRefreshRate(0))
	defer rl.CloseWindow()
	
	a: ast.AstroSystem
	ss: [dynamic]ast.Satellite
	sm: [dynamic]ast.SatelliteModel
	bb: [dynamic]ast.CelestialBody
	bm: [dynamic]ast.CelestialBodyModel
	a = ast.create_system(ss, sm, bb, bm)
	parse_tle_single("assets/ISS_TLE_HW7.txt", &a)
}

Millenium :: enum (int) {
	one_thousand = 1000,
	two_thousand = 2000,
}

parse_tle_single :: proc(
	file: string,
	system: ^ast.AstroSystem,
	millenium: Millenium = .two_thousand,
	time_only: bool = false,
) {

	earth := ast.wgs84()
	f, err := os.open(file)
	if err != os.ERROR_NONE {
		panic("ERROR: TLE file does not exist or could not be found")
	}
	data, ok := os.read_entire_file(f)
	if !ok {
		panic("ERROR: TLE data could not be read")
	}
	defer os.close(f)
	defer delete(data, context.allocator)

	it := string(data)
	lines := str.split_lines(it)

	// parse line 0
	name: string
	line0, line1, line2: string
	if len(lines) == 3 {
		line0 = lines[0]
		line1 = lines[1]
		line2 = lines[2]
		name = line0[2:]
	} else if len(lines) == 2 {
		line1 = lines[0]
		line2 = lines[1]
		name = line1[2:8]
	} else {
		panic(
			"ERROR: TLE file contains multiple satellites, use parse_tle_multiple instead",
		)
	}

	// parse line 1
	date: ast.Date
	date.year = int(millenium) + strconv.atoi(line1[18:20])
	date.month, date.day, date.hour = ast.dayofyear_to_monthdayhr(
		date.year,
		strconv.atof(line1[20:32]),
	)
	if time_only {
		system.JD0 = ast.date_to_jd(date)
		return
	}

	// parse line 2
	inc: f64 = strconv.atof(line2[9:16])
	raan: f64 = strconv.atof(line2[17:25])
	eccen_str, _ := str.replace(line2[26:33], " ", "", -1)
	ecc: f64 = strconv.atof(eccen_str) * 1.0e-7
	aop: f64 = strconv.atof(line2[34:42])
	mean_anom_str, _ := str.replace(line2[43:51], " ", "", -1)
	mean_anom: f64 = strconv.atof(mean_anom_str)
	mean_motion: f64 = strconv.atof(line2[52:63])
	eccen_anom := math.to_degrees(
		ast.meananom_to_eccenanom(math.to_radians(mean_anom), ecc),
	)
	true_anom: f64 = math.to_degrees(
		2. *
		math.atan(
			math.sqrt((1. + ecc) / (1. - ecc)) *
			math.tan(math.to_radians(eccen_anom) / 2.),
		),
	)
	semimajor_axis: f64 = math.pow(
		earth.mu * math.pow(86400 / mean_motion / (2 * math.PI), 2),
		1. / 3.,
	)


	pos, vel := ast.coe_to_rv(
		semimajor_axis,
		ecc,
		inc,
		raan,
		aop,
		true_anom,
		earth.mu,
	)
	ep: [4]f64 = {0., 0., 0., 1.}
	omega: [3]f64 = {0., 0., 0.}
	// TODO: change this later
	cube_size: f32 = 500 / 1000. * am.u_to_rl
	sat, model := ast.gen_satellite_and_mesh(
		pos,
		vel,
		ep,
		omega,
		[3]f32{cube_size, cube_size * 2, cube_size * 3},
	)
	sat.name = name

	// propagate to target time
	JD := ast.date_to_jd(date)
	if JD != system.JD0 {
		// if time does not align, propagate
		// TODO: finish this part
	}

	ast.add_satellite(&system.satellites, sat)
	ast.add_satellite_model(&system.satellite_models, model)
}


parse_tle_multiple :: proc(file: string, sats: ^[dynamic]ast.Satellite) {
	// open/read file
	// parse line 1
	// parse line 2
	// propagate to target time
}
