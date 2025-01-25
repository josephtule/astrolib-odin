package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

// -----------------------------------------------------------------------------
// Model
// -----------------------------------------------------------------------------

Model :: struct {
	id:         int,
	model:      rl.Model,
	model_size: [3]f32,
	scale:      f32,
	tint:       rl.Color,
	draw_model: bool,
	trail:      Trail,
	axes:       Axes,
	posvel:     PosVel,
}

add_model_to_array :: proc {
	add_model_to_array_ptr,
	add_model_to_array_copy,
}
add_model_to_array_ptr :: #force_inline proc(
	models: ^[dynamic]Model,
	model: ^Model,
) {
	append_elem(models, model^)
	free(model)
}
add_model_to_array_copy :: #force_inline proc(
	models: ^[dynamic]Model,
	model: Model,
) {
	append_elem(models, model)
}


// -----------------------------------------------------------------------------
// Axes
// -----------------------------------------------------------------------------

Axes :: struct {
	x, y, z: [3]f32,
	size:    f32,
	draw:    bool,
}


draw_axes :: #force_inline proc(
	attitude_flag: bool,
	axes: ^Axes,
	model: rl.Model,
) {
	// if attitude_flag {
	R := GetRotation(model.transform)
	axes.x = R * (xaxis_f32)
	axes.y = R * (yaxis_f32)
	axes.z = R * (zaxis_f32)
	// } 

	pos := GetTranslation(model.transform)
	// cmy colors for axes
	rl.DrawLine3D(pos, pos + axes.x * axes.size, rl.MAGENTA)
	rl.DrawLine3D(pos, pos + axes.y * axes.size, rl.YELLOW)
	rl.DrawLine3D(pos, pos + axes.z * axes.size, rl.Color({0, 255, 255, 255}))
}

// -----------------------------------------------------------------------------
// Trails
// -----------------------------------------------------------------------------

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

create_trail :: #force_inline proc(
	trail: ^Trail,
	pos: [3]$T,
) #no_bounds_check {
	for i := 0; i < N_trail_sat; i += 1 {
		// for i in 0..<N_trail_sat {
		append_elem(&trail.pos, cast_f32(pos) * u_to_rl)
	}
	trail.index = 0
}
resize_trail :: #force_inline proc(
	trail: ^Trail,
	pos: [3]$T,
) #no_bounds_check {
	// delete(model.trail)
	trail.pos = make([dynamic][3]f32, N_trail_sat)
	reset_trail(trail, pos)
}
reset_trail :: #force_inline proc(trail: ^Trail, pos: [3]$T) #no_bounds_check {
	for i := 0; i < N_trail_sat; i += 1 {
		trail.pos[i] = cast_f32(pos) * u_to_rl
	}
	trail.index = 0
	trail.increment = 0
}
update_trail :: #force_inline proc(new_pos: [3]f64, model: ^Model) {
	using model.trail
	increment = (increment + 1)
	if increment == mod_trail_sat {
		increment = 0
		pos[index] = cast_f32(new_pos) * u_to_rl
		index = (index + 1)
		if index == N_trail_sat {
			index = 0 // Wrap around without modulo
		}
	}
}
draw_trail :: #force_inline proc(model: Model) {
	using model.trail
	if draw {
		for i := 0; i < N_trail_sat - 1; i += 1 {
			current := (index + i) % N_trail_sat
			next := (current + 1) % N_trail_sat

			rl.DrawLine3D(pos[current], pos[next], model.tint)
		}
	}
}

// -----------------------------------------------------------------------------
// Position/Velocity Vectors
// -----------------------------------------------------------------------------
PosVel :: struct {
	pos, vel, pos_origin: [3]f32,
	vel_scale:            f32,
	target_id:            int,
	pos_tint, vel_tint:   rl.Color,
	draw_pos:             bool,
	draw_vel:             bool,
}

update_posvel :: #force_inline proc(pv: ^PosVel, pos, vel: [3]f64) {
	pv.pos = cast_f32(pos) * u_to_rl
	pv.vel = cast_f32(vel) * u_to_rl * pv.vel_scale
}

set_pos_origin :: #force_inline proc(pv: ^PosVel, system: AstroSystem) {
	// line from origin to satellite
	if pv.draw_pos {
		target_ind := system.id[pv.target_id]
		if pv.target_id >= g_body_id_base {
			// target is a body
			pv.pos_origin = cast_f32(system.bodies[target_ind].pos) * u_to_rl
		} else {
			// target is satellite
			pv.pos_origin = cast_f32(system.satellites[target_ind].pos) * u_to_rl
		}
	}
}

draw_vectors :: #force_inline proc(
	pv: ^PosVel,
	system: AstroSystem,
	pos, vel: [3]f64,
) {
	update_posvel(pv, pos, vel)
	set_pos_origin(pv, system)
	if pv.draw_pos {
		rl.DrawLine3D(pv.pos_origin, pv.pos, pv.pos_tint)
	}
	if pv.draw_vel {
		rl.DrawLine3D(pv.pos, pv.pos + pv.vel, pv.vel_tint)
	}
}


// -----------------------------------------------------------------------------
// Vector Field TODO:
// -----------------------------------------------------------------------------

VectorField :: struct {
	points: [dynamic][3]f64,
	length: f64,
	draw:   bool,
}
