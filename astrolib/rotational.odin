package astrolib

import "core:fmt"
import "core:math"
import la "core:math/linalg"

import am "../astromath"

// NOTE: direction cosine matrix (DCM) notation: [BN]: from N->B, [NB]: B->N
// Odin/Raylib is N->B by default


Params_EulerParam :: struct {
	inertia: matrix[3, 3]f64, // in body frame
	torque:  [3]f64, // in body frame
}
euler_param_dyanmics :: proc(
	t: f64,
	x: [7]f64,
	params: rawptr,
) -> (
	dxdt: [7]f64,
) {
	params := cast(^Params_EulerParam)(params)
	ep: [4]f64
	am.set_vector_slice_1(&ep, x, s1 = 0, l1 = 4)
	ep = la.vector_normalize0(ep)
	omega: [3]f64
	am.set_vector_slice_1(&omega, x, s1 = 4, l1 = 3)
	depdt := euler_param_kinematics(ep, omega)
	dwdt := angular_velocty_dynamics(omega, params.torque, params.inertia)

	am.set_vector_slice_2(&dxdt, depdt, dwdt)
	return dxdt
}

euler_param_kinematics :: proc(ep: [4]f64, omega: [3]f64) -> (depdt: [4]f64) {
    // odinfmt: disable
    E_mat := matrix[4,4]f64{0., omega.z, -omega.y, omega.x,
                            -omega.z, 0., omega.x, omega.y,
                            omega.y, -omega.x, 0., omega.z,
                            -omega.x, -omega.y, -omega.z, 0.,}
    // odinfmt: enable
	depdt = 1. / 2. * E_mat * ep
	return depdt
}

angular_velocty_dynamics :: proc(
	omega, torque: [3]f64,
	I: matrix[3, 3]f64,
) -> (
	dwdt: [3]f64,
) {
	if am.is_diagonal(I) {
		I: [3]f64 = {I[0, 0], I[1, 1], I[2, 2]}
		dwdt = {
			(I.y - I.z) / I.x * omega.y * omega.z,
			(I.z - I.x) / I.y * omega.x * omega.z,
			(I.x - I.y) / I.z * omega.x * omega.y,
		}
		dwdt += torque / I
		return dwdt
	} else {
		angular_momentum := I * omega
		coriolis_term := la.cross(omega, angular_momentum)
		dwdt = la.inverse(I) * (torque - coriolis_term)
		return dwdt
	}
}



