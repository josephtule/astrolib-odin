package astrolib

import "core:math"
import la "core:math/linalg"
import rl "vendor:raylib"

Matrix4Translate :: #force_inline proc "contextless" (
	pos: [3]f32,
) -> # row_major matrix[4, 4]f32 #no_bounds_check {
	mat: # row_major matrix[4, 4]f32
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
	return mat
}

SetTranslation :: #force_inline proc "contextless" (
	mat: ^# row_major matrix[4, 4]f32,
	pos: [3]f32,
) #no_bounds_check {
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
}

GetTranslation :: #force_inline proc "contextless" (
	mat: # row_major matrix[4, 4]f32,
) -> [3]f32 #no_bounds_check {
	return {mat[0, 3], mat[1, 3], mat[2, 3]}
}

SetScale :: #force_inline proc "contextless" (
	mat: ^# row_major matrix[4, 4]f32,
	scale: f32,
) #no_bounds_check {
	mat[0, 0] *= scale
	mat[0, 1] *= scale
	mat[0, 2] *= scale
	mat[1, 0] *= scale
	mat[1, 1] *= scale
	mat[1, 2] *= scale
	mat[2, 0] *= scale
	mat[2, 1] *= scale
	mat[2, 2] *= scale
}

SetRotation :: #force_inline proc "contextless" (
	mat: ^# row_major matrix[4, 4]f32,
	rot: # row_major matrix[3, 3]f32,
) #no_bounds_check {
	mat[0, 0] = rot[0, 0]
	mat[0, 1] = rot[0, 1]
	mat[0, 2] = rot[0, 2]
	mat[1, 0] = rot[1, 0]
	mat[1, 1] = rot[1, 1]
	mat[1, 2] = rot[1, 2]
	mat[2, 0] = rot[2, 0]
	mat[2, 1] = rot[2, 1]
	mat[2, 2] = rot[2, 2]
}


mat4row :: # row_major matrix[4, 4]f32
mat3row :: # row_major matrix[3, 3]f32
GetRotation :: #force_inline proc "contextless" (
	mat: # row_major matrix[4, 4]f32,
) -> # row_major matrix[3, 3]f32 #no_bounds_check {
	// submatrix casting
	res: # row_major matrix[3, 3]f32
	res = mat3row(mat)
	return res
}


euler_param_to_quaternion :: proc {
	euler_param_to_quaternion128,
	euler_param_to_quaternion256,
}
euler_param_to_quaternion256 :: #force_inline proc "contextless" (
	ep: [4]f64,
) -> (
	q: quaternion256,
) #no_bounds_check {
	q.x = ep.x
	q.y = ep.y
	q.z = ep.z
	q.w = ep.w
	return q
}
euler_param_to_quaternion128 :: #force_inline proc "contextless" (
	ep: [4]f32,
) -> (
	q: quaternion128,
) #no_bounds_check {
	q.x = ep.x
	q.y = ep.y
	q.z = ep.z
	q.w = ep.w
	return q
}

quaternion_to_euler_param :: #force_inline proc "contextless" (
	q: quaternion256,
) -> (
	ep: [4]f64,
) #no_bounds_check {
	ep.x = q.x
	ep.y = q.y
	ep.z = q.z
	ep.w = q.w
	return ep
}

// euler_param_to_dcm :: proc(ep: [4]f64) -> matrix[3,3]f64 {

// }

RotAxis :: enum int {
	x = 1,
	y = 2,
	z = 3,
}
rot :: #force_inline proc "contextless" (
	angle: $T,
	axis: RotAxis,
	units_in: UnitsAngle = .RADIANS,
) -> matrix[3, 3]T #no_bounds_check {
	R: matrix[3, 3]T
	angle := angle
	if units_in == .DEGREES {
		angle = math.to_radians(angle)
	}
	c := math.cos(angle)
	s := math.sin(angle)
	switch axis {
	case .x: R = {1, 0, 0, 0, c, s, 0, -s, c}
	case .y: R = {c, 0, -s, 0, 1, 0, s, 0, c}
	case .z: R = {c, s, 0, -s, c, 0, 0, 0, 1}
	}
	return R
}

ea_to_dcm :: #force_inline proc "contextless" (
	angles: [3]$T,
	sequence: [3]RotAxis,
	units_in: UnitsAngle = .RADIANS,
) -> matrix[3, 3]T #no_bounds_check {
	angles := angles
	if units_in == .DEGREES {
		angles *= deg_to_rad * angles
	}

	// R := la.identity_matrix(matrix[3, 3]T)
	// for i := 2; i >= 0; i -= 1 {
	// 	R = R * rot(angles[i], sequence[i])
	// }
	R :=
		rot(angles[2], sequence[2]) *
		rot(angles[1], sequence[1]) *
		rot(angles[0], sequence[0])

	return R
}
