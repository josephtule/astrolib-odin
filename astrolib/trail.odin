package astrolib

import "base:intrinsics"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import am "../astromath"


Trail :: struct {
	pos:       [dynamic][3]f32,
	index:     int,
	increment: int,
	draw:      bool,
}

N_trail_MAX :: 1000
N_trail_sat: int = 200
div_trail_sat: int = 4
mod_trail_sat: int = N_trail_sat / div_trail_sat

create_trail :: proc(
	trail: ^Trail,
	pos: [3]$T,
) where intrinsics.type_is_float(T) {
	for i := 0; i < N_trail_sat; i += 1 {
		append_elem(&trail.pos, am.cast_f32(pos) * u_to_rl)
	}
	trail.index = 0
}
resize_trail :: proc(
	trail: ^Trail,
	pos: [3]$T,
) where intrinsics.type_is_float(T) {
	// delete(model.trail)
	trail.pos = make([dynamic][3]f32, N_trail_sat)
	reset_trail(trail, pos)
}
reset_trail :: proc(
	trail: ^Trail,
	pos: [3]$T,
) where intrinsics.type_is_float(T) {
	for i := 0; i < N_trail_sat; i += 1 {
		trail.pos[i] = am.cast_f32(pos) * u_to_rl
	}
	trail.index = 0
	trail.increment = 0
}
update_trail :: proc(sat: ^Satellite, model: ^SatelliteModel) {
	using model.trail
	increment = (increment + 1)
	if increment == mod_trail_sat {
		increment = 0
		pos[index] = la.array_cast(sat.pos, f32) * u_to_rl
		index = (index + 1)
		if index == N_trail_sat {
			index = 0 // Wrap around without modulo
		}
	}
}
draw_trail :: proc(model: SatelliteModel) {
	using model.trail
	if draw {
		for i := 0; i < N_trail_sat - 1; i += 1 {
			current := (index + i) % N_trail_sat
			next := (current + 1) % N_trail_sat

			rl.DrawLine3D(pos[current], pos[next], model.tint)
		}
	}
}
