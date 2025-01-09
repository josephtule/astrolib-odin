package astromath

import rl "vendor:raylib"

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