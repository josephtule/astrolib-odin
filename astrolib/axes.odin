package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import am "../astromath"


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
		R := am.GetRotation(model.transform)
		axes.x = R * (am.xaxis_f32)
		axes.y = R * (am.yaxis_f32)
		axes.z = R * (am.zaxis_f32)
	// } 

	pos := am.GetTranslation(model.transform)
	// cmy colors for axes
	rl.DrawLine3D(pos, pos + axes.x * axes.size, rl.MAGENTA)
	rl.DrawLine3D(pos, pos + axes.y * axes.size, rl.YELLOW)
	rl.DrawLine3D(pos, pos + axes.z * axes.size, rl.Color({0, 255, 255, 255}))
}
