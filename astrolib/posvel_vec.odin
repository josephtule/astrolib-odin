package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"


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
