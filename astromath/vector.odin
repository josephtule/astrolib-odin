package astromath

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


posvel_to_state :: proc(pos, vel: [3]$T) -> (state: [6]T) {
	set_vector_slice(&state, pos, vel)
	return state
}
state_to_posvel :: proc(state: [6]$T) -> (pos, vel: [3]T) {
	set_vector_slice_1(&pos, state, l1 = 3, s1 = 0)
	set_vector_slice_1(&vel, state, l1 = 3, s1 = 3)
	return pos, vel
}

epomega_to_state :: proc(ep: [4]$T, omega: [3]T) -> (state: [7]T) {
	set_vector_slice(&state, ep, omega)
	return state
}
state_to_epomega :: proc(state: [7]$T) -> (ep: [4]T, omega: [3]T) {
	set_vector_slice_1(&ep, state, s1 = 0, l1 = 4)
	set_vector_slice_1(&omega, state, s1 = 4, l1 = 3)
	return ep, omega
}

is_diagonal :: proc(mat: matrix[$N, N]$T, tol := 1.0e-6) -> bool {
	for i := 0; i < N; i += 1 {
		for j := 0; j < N; j += 1 {
			if i != j && math.abs(mat[i, j]) > tol {
				return false
			}
		}
	}
	return true
}

set_vector_slice :: proc {
	set_vector_slice_1,
	set_vector_slice_2,
	set_vector_slice_3,
	set_vector_slice_4,
}

set_vector_slice_1 :: proc(
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

set_vector_slice_2 :: proc(
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


set_vector_slice_3 :: proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	v3: [$M3]T,
	#any_int offset: int = 0,
	#any_int s1: int = 0,
	#any_int s2: int = 0,
	#any_int s3: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
	#any_int l3: int = 0,
) {
	l1 := l1
	l2 := l2
	l3 := l3
	assert(N >= l1 + l2 + l3 + offset)
	if l1 == 0 {l1 = len(v1) - s1}
	if l2 == 0 {l2 = len(v2) - s2}
	if l3 == 0 {l3 = len(v3) - s3}
	for i := s1; i < s1 + l1; i += 1 {
		vout[i - s1 + offset] = v1[i]
	}
	for i := s2; i < s2 + l2; i += 1 {
		vout[i - s2 + offset + l1] = v2[i]
	}
	for i := s3; i < s3 + l3; i += 1 {
		vout[i - s3 + offset + l1 + l2] = v3[i]
	}
}

set_vector_slice_4 :: proc(
	vout: ^[$N]$T,
	v1: [$M1]T,
	v2: [$M2]T,
	v3: [$M3]T,
	v4: [$M4]T,
	#any_int offset: int = 0,
	#any_int s1: int = 0,
	#any_int s2: int = 0,
	#any_int s3: int = 0,
	#any_int s4: int = 0,
	#any_int l1: int = 0,
	#any_int l2: int = 0,
	#any_int l3: int = 0,
	#any_int l4: int = 0,
) {
	l1 := l1
	l2 := l2
	l3 := l3
	l4 := l4
	assert(N >= l1 + l2 + l3 + l4 + offset)
	if l1 == 0 {l1 = len(v1) - s1}
	if l2 == 0 {l2 = len(v2) - s2}
	if l3 == 0 {l3 = len(v3) - s3}
	if l4 == 0 {l4 = len(v4) - s4}
	for i := s1; i < s1 + l1; i += 1 {
		vout[i - s1 + offset] = v1[i]
	}
	for i := s2; i < s2 + l2; i += 1 {
		vout[i - s2 + offset + l1] = v2[i]
	}
	for i := s3; i < s3 + l3; i += 1 {
		vout[i - s3 + offset + l1 + l2] = v3[i]
	}
	for i := s4; i < s4 + l4; i += 1 {
		vout[i - s4 + offset + l1 + l2 + l3] = v4[i]
	}
}

cast_f32 :: proc(v: $T/[$N]$E) -> [N]f32 {
	out := la.array_cast(v, f32)
	return out
}

cast_f64 :: proc(v: $T/[$N]$E) -> [N]f64 {
	out := la.array_cast(v, f64)
	return out
}
