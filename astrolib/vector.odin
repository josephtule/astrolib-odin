package astrolib

import "core:math"
import la "core:math/linalg"

origin_f64: [3]f64 : {0., 0., 0.}
xaxis_f64: [3]f64 : {1., 0., 0.}
yaxis_f64: [3]f64 : {0., 1., 0.}
zaxis_f64: [3]f64 : {0., 0., 1.}

origin_f32: [3]f32 : {0., 0., 0.}
xaxis_f32: [3]f32 : {1., 0., 0.}
yaxis_f32: [3]f32 : {0., 1., 0.}
zaxis_f32: [3]f32 : {0., 0., 1.}


magnitude :: la.length
magnitude2 :: la.length2
mag :: la.length
mag2 :: la.length2

vector_angle :: #force_inline proc "contextless" (
	v1, v2: [$N]$T,
	units: UnitsAngle = .DEGREES,
) -> (
	angle: T,
) #no_bounds_check {
	angle = math.acos(la.dot(v1, v2) / (mag(v2) * mag(v2)))

	return angle
}


posvel_to_state :: #force_inline proc "contextless" (
	pos, vel: [3]$T,
) -> (
	state: [6]T,
) #no_bounds_check {
	// set_vector_slice(&state, pos, vel)
	state = {pos[0], pos[1], pos[2], vel[0], vel[1], vel[2]}
	return state
}
state_to_posvel :: #force_inline proc "contextless" (
	state: [6]$T,
) -> (
	pos, vel: [3]T,
) #no_bounds_check {
	// set_vector_slice_1(&pos, state, l1 = 3, s1 = 0)
	// set_vector_slice_1(&vel, state, l1 = 3, s1 = 3)
	pos = {state[0], state[1], state[2]}
	vel = {state[3], state[4], state[5]}
	return pos, vel
}

epomega_to_state :: #force_inline proc "contextless" (
	ep: [4]$T,
	omega: [3]T,
) -> (
	state: [7]T,
) #no_bounds_check {
	// set_vector_slice(&state, ep, omega)
	state = {ep.x, ep.y, ep.z, ep.w, omega.x, omega.y, omega.z}
	return state
}
state_to_epomega :: #force_inline proc "contextless" (
	state: [7]$T,
) -> (
	ep: [4]T,
	omega: [3]T,
) #no_bounds_check {
	// set_vector_slice_1(&ep, state, s1 = 0, l1 = 4)
	// set_vector_slice_1(&omega, state, s1 = 4, l1 = 3)
	ep = {state[0], state[1], state[2], state[3]}
	omega = {state[4], state[5], state[6]}
	return ep, omega
}

// is_diagonal :: #force_inline proc "contextless" (
// 	mat: matrix[$N, N]$T,
// 	tol := 1.0e-12,
// ) -> bool #no_bounds_check {
// 	// for i := 0; i < N; i += 1 {
// 	#unroll for i in 0 ..< N {
// 		// for j := i + 1; j < N; j += 1 {
// 		#unroll for j in i + 1 ..< N {
// 			if math.abs(mat[i, j]) > tol || math.abs(mat[j, i]) > tol {
// 				return false
// 			}
// 		}
// 	}
// 	return true
// }

set_vector_slice :: proc {
	set_vector_slice_1,
	set_vector_slice_2,
// set_vector_slice_3,
// set_vector_slice_4,
}

set_vector_slice_1 :: #force_inline proc(
	vout: ^[$N]$T,
	v1: [$M]T,
	#any_int offset: int = 0, // starting offset
	#any_int s1: int = 0, // copy size
	#any_int l1: int = 0, // copy offset
) {
	l1 := l1
	assert(N >= l1 + offset) // Ensure vout has enough space for vin
	if l1 == 0 {l1 = len(v1)}
	for i := s1; i < s1 + l1; i += 1 {
		vout[i + offset - s1] = v1[i]
	}
}

set_vector_slice_2 :: #force_inline proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	#any_int offset: int = 0,
	#any_int s1: int = 0,
	#any_int s2: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
) {
	l1 := l1
	l2 := l2
	assert(N >= l1 + l2 + offset)
	if l1 == 0 {l1 = len(v1) - s1}
	if l2 == 0 {l2 = len(v2) - s2}
	for i := s1; i < s1 + l1; i += 1 {
		vout[i - s1 + offset] = v1[i]
	}
	for i := s2; i < s2 + l2; i += 1 {
		vout[i - s2 + offset + l1] = v2[i]
	}
}


// set_vector_slice_3 :: #force_inline proc(
// 	vout: ^[$N]$T,
// 	v1: [$M1]T,
// 	v2: [$M2]T,
// 	v3: [$M3]T,
// 	#any_int offset: int = 0,
// 	#any_int s1: int = 0,
// 	#any_int s2: int = 0,
// 	#any_int s3: int = 0,
// 	#any_int l1: int = 0,
// 	#any_int l2: int = 0,
// 	#any_int l3: int = 0,
// ) {
// 	l1 := l1
// 	l2 := l2
// 	l3 := l3
// 	assert(N >= l1 + l2 + l3 + offset)
// 	if l1 == 0 {l1 = len(v1) - s1}
// 	if l2 == 0 {l2 = len(v2) - s2}
// 	if l3 == 0 {l3 = len(v3) - s3}
// 	for i := s1; i < s1 + l1; i += 1 {
// 		vout[i - s1 + offset] = v1[i]
// 	}
// 	for i := s2; i < s2 + l2; i += 1 {
// 		vout[i - s2 + offset + l1] = v2[i]
// 	}
// 	for i := s3; i < s3 + l3; i += 1 {
// 		vout[i - s3 + offset + l1 + l2] = v3[i]
// 	}
// }

// set_vector_slice_4 :: #force_inline proc(
// 	vout: ^[$N]$T,
// 	v1: [$M1]T,
// 	v2: [$M2]T,
// 	v3: [$M3]T,
// 	v4: [$M4]T,
// 	#any_int offset: int = 0,
// 	#any_int s1: int = 0,
// 	#any_int s2: int = 0,
// 	#any_int s3: int = 0,
// 	#any_int s4: int = 0,
// 	#any_int l1: int = 0,
// 	#any_int l2: int = 0,
// 	#any_int l3: int = 0,
// 	#any_int l4: int = 0,
// ) {
// 	l1 := l1
// 	l2 := l2
// 	l3 := l3
// 	l4 := l4
// 	assert(N >= l1 + l2 + l3 + l4 + offset)
// 	if l1 == 0 {l1 = len(v1) - s1}
// 	if l2 == 0 {l2 = len(v2) - s2}
// 	if l3 == 0 {l3 = len(v3) - s3}
// 	if l4 == 0 {l4 = len(v4) - s4}
// 	for i := s1; i < s1 + l1; i += 1 {
// 		vout[i - s1 + offset] = v1[i]
// 	}
// 	for i := s2; i < s2 + l2; i += 1 {
// 		vout[i - s2 + offset + l1] = v2[i]
// 	}
// 	for i := s3; i < s3 + l3; i += 1 {
// 		vout[i - s3 + offset + l1 + l2] = v3[i]
// 	}
// 	for i := s4; i < s4 + l4; i += 1 {
// 		vout[i - s4 + offset + l1 + l2 + l3] = v4[i]
// 	}
// }

cast_f32 :: #force_inline proc(v: $T/[$N]$E) -> [N]f32 {
	return la.array_cast(v, f32)
}

cast_f64 :: #force_inline proc(v: $T/[$N]$E) -> [N]f64 {
	return la.array_cast(v, f64)
}

// diag :: proc {
// 	diag_to_vec,
// 	diag_to_mat,
// }

// diag_to_vec :: proc(mat: matrix[$N, N]$T) -> (vec: [N]T) {
// 	for i := 0; i < N; i += 1 {
// 		vec[i] = mat[i, i]
// 	}
// }

// diag_to_mat :: proc(vec: [$N]$T) -> (mat: matrix[N, N]T) {
// 	for i := 0; i < N; i += 1 {
// 		mat[i, i] = vec[i]
// 	}
// }


vector_contains :: proc {
	vector_contains_fixed,
}
vector_contains_fixed :: proc(val: $T, vec: [$N]T) -> bool {
	for elem in vec {
		if val == elem {
			return true
		}
	}
	return false
}
