package ui

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import ast "../astrolib"


update_camera :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ast.AstroSystem,
	dt: f64,
) {
	if rl.GetMouseWheelMove() < 0 {
		camera_params.azel.z *= 1.1
	} else if rl.GetMouseWheelMove() > 0 {
		camera_params.azel.z /= 1.1
	}
	camera.position = ast.cast_f32(
		ast.azel_to_cart(ast.cast_f64(camera_params.azel), .RADIANS),
	)
}
