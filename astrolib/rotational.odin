package astrolib

import "core:math"

// NOTE: direction cosine matrix (DCM) notation: [BN]: from N->B, [NB]: B->N
// Odin/Raylib is N->B by default

Params_EulerParam :: struct {
	inertia, inertia_inv: matrix[3, 3]f64, // in body frame
	torque:               [3]f64, // in body frame
}
Params_BodyAttitude :: struct {}
euler_param_dynamics :: #force_inline proc(
	t: f64,
	x: [7]f64,
	params: rawptr,
) -> (
	dxdt: [7]f64,
) {
	params := cast(^Params_EulerParam)(params)
	ep: [4]f64 = {x[0], x[1], x[2], x[3]}
	// set_vector_slice_1(&ep, x, s1 = 0, l1 = 4)
	omega: [3]f64 = {x[4], x[5], x[6]}
	// set_vector_slice_1(&omega, x, s1 = 4, l1 = 3)
	depdt := euler_param_kinematics(ep, omega)
	dwdt := angular_velocty_dynamics(
		omega,
		params.torque,
		params.inertia,
		params.inertia_inv,
	)

	// set_vector_slice_2(&dxdt, depdt, dwdt)
	dxdt = {depdt[0], depdt[1], depdt[2], depdt[3], dwdt[0], dwdt[1], dwdt[2]}
	return dxdt
}

euler_param_kinematics :: #force_inline proc(
	ep: [4]f64,
	omega: [3]f64,
) -> (
	depdt: [4]f64,
) {
	// // odinfmt: disable
	// E_mat := matrix[4,4]f64{0., omega.z, -omega.y, omega.x,
	//                         -omega.z, 0., omega.x, omega.y,
	//                         omega.y, -omega.x, 0., omega.z,
	//                         -omega.x, -omega.y, -omega.z, 0.,}
	// depdt = 0.5 * E_mat * ep
	// // odinfmt: enable

	depdt =
		0.5 *
		{
				omega.z * ep[1] - omega.y * ep[2] + omega.x * ep[3],
				-omega.z * ep[0] + omega.x * ep[2] + omega.y * ep[3],
				omega.y * ep[0] - omega.x * ep[1] + omega.z * ep[3],
				-omega.x * ep[0] - omega.y * ep[1] - omega.z * ep[2],
			}
	return depdt
}

angular_velocty_dynamics :: #force_inline proc(
	omega, torque: [3]f64,
	I, I_inv: matrix[3, 3]f64,
) -> (
	dwdt: [3]f64,
) {
	// NOTE: assuming inertia matrix is diagonal for now
	// if is_diagonal(I) {
	dwdt = {
		(I[1, 1] - I[2, 2]) / I[0, 0] * omega.y * omega.z,
		(I[2, 2] - I[0, 0]) / I[1, 1] * omega.x * omega.z,
		(I[0, 0] - I[1, 1]) / I[2, 2] * omega.x * omega.y,
	}
	dwdt += {
		torque.x * I_inv[0, 0],
		torque.y * I_inv[1, 1],
		torque.z * I_inv[2, 2],
	}
	return dwdt
	// } else {
	// 	h := [3]f64 {
	// 		I[0, 0] * omega.x + I[0, 1] * omega.y + I[0, 2] * omega.z,
	// 		I[1, 0] * omega.x + I[1, 1] * omega.y + I[1, 2] * omega.z,
	// 		I[2, 0] * omega.x + I[2, 1] * omega.y + I[2, 2] * omega.z,
	// 	}
	// 	dhdt_tf := [3]f64 {
	// 		h.z * omega.y - h.y * omega.z,
	// 		h.x * omega.z - h.z * omega.x,
	// 		h.y * omega.x - h.x * omega.y,
	// 	}
	// 	dhdt := torque - dhdt_tf
	// 	// dwdt = I_inv * (torque - dhdt_tf)
	// 	dwdt = {
	// 		I_inv[0, 0] * dhdt.x + I_inv[0, 1] * dhdt.y + I_inv[0, 2] * dhdt.z,
	// 		I_inv[1, 0] * dhdt.x + I_inv[1, 1] * dhdt.y + I_inv[1, 2] * dhdt.z,
	// 		I_inv[2, 0] * dhdt.x + I_inv[2, 1] * dhdt.y + I_inv[2, 2] * dhdt.z,
	// 	}
	// 	return dwdt
	// }
}
