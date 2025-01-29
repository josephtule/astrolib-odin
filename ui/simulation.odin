package ui

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import ast "../astrolib"

update_simulation :: proc(
	system: ^ast.AstroSystem,
	systems, systems_reset: ^ast.Systems,
	dt: f64,
) {

    if rl.IsKeyPressed(.UP) && (f64(system.substeps) * system.time_scale < 25000) {
		system.substeps *= 2
	} else if rl.IsKeyPressed(.DOWN) && system.substeps > 1 {
		system.substeps /= 2
	}
	if rl.IsKeyPressed(.RIGHT) && (f64(system.substeps) * system.time_scale < 25000) {
		system.time_scale *= 2
	} else if rl.IsKeyPressed(.LEFT) {
		system.time_scale /= 2
	}

}
