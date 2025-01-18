package astromath

import rl "vendor:raylib"
import "core:math"
import la "core:math/linalg"

MatrixTranslateAdditive :: proc(pos: [3]f32) -> # row_major matrix[4, 4]f32 {
	mat: # row_major matrix[4, 4]f32
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
	return mat
}

SetTranslation :: proc(mat: ^# row_major matrix[4, 4]f32, pos: [3]f32) {
	mat[0, 3] = pos.x
	mat[1, 3] = pos.y
	mat[2, 3] = pos.z
}

GetTranslation :: proc(mat: # row_major matrix[4, 4]f32) -> [3]f32 {
	return {mat[0, 3], mat[1, 3], mat[2, 3]}
}

SetRotation :: proc(
	mat: ^# row_major matrix[4, 4]f32,
	rot: # row_major matrix[3, 3]f32,
) {
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
GetRotation :: proc(
	mat: # row_major matrix[4, 4]f32,
) -> # row_major matrix[3, 3]f32 {
	// submatrix casting
	res: # row_major matrix[3, 3]f32
	res = mat3row(mat)
	return res
}


euler_param_to_quaternion :: proc {
	euler_param_to_quaternion128,
	euler_param_to_quaternion256,
}
euler_param_to_quaternion256 :: proc(ep: [4]f64) -> (q: quaternion256) {
	q.x = ep.x
	q.y = ep.y
	q.z = ep.z
	q.w = ep.w
	return q
}
euler_param_to_quaternion128 :: proc(ep: [4]f32) -> (q: quaternion128) {
	q.x = ep.x
	q.y = ep.y
	q.z = ep.z
	q.w = ep.w
	return q
}

quaternion_to_euler_param :: proc(q: quaternion256) -> (ep: [4]f64) {
	ep.x = q.x
	ep.y = q.y
	ep.z = q.z
	ep.w = q.w
	return ep
}

// euler_param_to_dcm :: proc(ep: [4]f64) -> matrix[3,3]f64 {

// }

rot :: proc(
	angle: $T,
	axis: int,
	units_in: UnitsAngle = .RADIANS,
) -> matrix[3, 3]T {
	R: matrix[3, 3]T
	angle := angle
	if units_in == .DEGREES {
		angle = math.to_radians(angle)
	}
	c := math.cos(angle)
	s := math.sin(angle)
	switch axis {
	case 1: R = {1, 0, 0, 0, c, s, 0, -s, c}
	case 2: R = {c, 0, -s, 0, 1, 0, s, 0, c}
	case 3: R = {c, s, 0, -s, c, 0, 0, 0, 1}
	case:
		panic("ERROR: invalid rotation axis")
	}
	return R
}

ea_to_dcm :: proc(
	angles: [3]$T,
	sequence: [3]int,
	units_in: UnitsAngle = .RADIANS,
) -> matrix[3, 3]T {
	angles := angles
	if units_in == .DEGREES {
		for &angle in angles {
			angle = math.to_radians(angle)
		}
	}

	R := la.identity_matrix(matrix[3, 3]T)

	for i := 2; i >= 0; i -= 1 {
		R = R * rot(angles[i], sequence[i])
	}

	return R
}
