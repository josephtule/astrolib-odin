package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import am "../astromath"


Axes :: struct {
	x, y, z: [3]f32,
	draw:    bool,
}


draw_axes :: proc(
	attitude_flag: bool,
	axes: ^Axes,
	model: rl.Model,
	size: f32,
) {
	if attitude_flag {
		R := am.GetRotation(model.transform)
		axes.x = R * (am.xaxis_f32 * size * 10)
		axes.y = R * (am.yaxis_f32 * size * 10)
		axes.z = R * (am.zaxis_f32 * size * 10)
	}
	sat_pos_f32 := am.GetTranslation(model.transform)
	// cmy colors for axes
	rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + axes.x, rl.MAGENTA)
	rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + axes.y, rl.YELLOW)
	rl.DrawLine3D(sat_pos_f32, sat_pos_f32 + axes.z, rl.Color({0, 255, 255, 255}))
}
