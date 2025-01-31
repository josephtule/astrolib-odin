package ui

import "core:fmt"
import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

import ast "../astrolib"

CameraType :: enum {
	origin = 0,
	satellite,
	body,
	locked,
}

CameraParams :: struct {
	azel:           [3]f64, // TODO: change to degrees
	target_sat:     ^ast.Satellite,
	target_sat_id:  int,
	target_body:    ^ast.CelestialBody,
	target_body_id: int,
	frame:          CameraType,
}

update_camera :: proc(
	camera: ^rl.Camera,
	camera_params: ^CameraParams,
	system: ast.AstroSystem,
	dt: f64,
) {
	if pointer_in("viewport") {
		if rl.GetMouseWheelMove() < 0 {
			camera_params.azel.z *= 1.1
		} else if rl.GetMouseWheelMove() > 0 {
			camera_params.azel.z /= 1.1
		}
		if camera_params.azel.y >= 90 {
			camera.up = {0, 0, -1}
		} else {
			camera.up = {0, 0, 1}
		}
		if rl.IsMouseButtonDown(.LEFT) {
			mouse_delta := rl.GetMouseDelta()
			camera_params.azel.x -= f64(mouse_delta.x) * dt
			camera_params.azel.y += f64(mouse_delta.y) * dt
		}
	}


	camera.position = ast.cast_f32(
		ast.azel_to_cart(ast.cast_f64(camera_params.azel), .RADIANS),
	)
}
