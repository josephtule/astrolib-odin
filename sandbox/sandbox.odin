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
	filename := "assets/TLE_data_small.txt"
	earth := ast.wgs84()
	a = ast.create_system(ss, sm, bb, bm)
	ast.add_celestialbody(&a.bodies, earth)
	// ast.parse_tle_single(filename, &a)
	// fmt.println("Satellites added:", ast.tle_read_extract(filename, earth.id, &a))
	// for sat in a.satellites {
	// 	fmt.println(sat.name)
	// }

	cc: [dynamic]int
	ccc: [4]int
	append(&cc, 1)
	print_dynamic(ccc[:])


	s1: #soa[dynamic]person
	s2: #soa[dynamic]person
	append(&s1, person{age = 3, height = 2})
	append(&s1, person{age = 3, height = 2})
	append(&s1, person{age = 3, height = 2})
	append(&s1, person{age = 3, height = 2})
	s2 = am.copy_soa_array(s1)
	s1[0].age = 999
	fmt.println(s2[0].age)
}
person :: struct {
	age:    int,
	height: int,
}

print_dynamic :: proc(v: []int) {
	fmt.println(v)
}
