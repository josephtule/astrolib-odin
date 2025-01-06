package ode

import "core:math"
import la "core:math/linalg"

import am "../astromath"

Params_MSD :: struct {
	m, c, k: f64,
}
mass_spring_damper :: proc(t: f64, x: [2]f64, params: rawptr) -> [2]f64 {
	params := cast(^Params_MSD)(params)
	A := matrix[2, 2]f64{
		0., 1., 
		-params.k / params.m, -params.c / params.m, 
	}
	B := [2]f64{0., 1. / 2.5}
	F := proc(t: f64) -> f64 {return 5.0 * math.sin(2 * t)}
	dxdt := A * x + B * F(t)

	return dxdt
}


Params_Gravity_Pointmass :: struct {
	mu: f64,
}
gravity_pointmass :: proc(t: f64, x: [6]f64, params: rawptr) -> [6]f64 {
	dxdt: [6]f64

	params := cast(^Params_Gravity_Pointmass)(params)
	r: [3]f64
	am.set_vector_slice(&r, x, l1 = 3)
	v: [3]f64
	am.set_vector_slice_1(&v, x, s1 = 3, l1 = 3)


	r_mag := la.vector_length(r)
	a := accel_pointmass(r, params.mu)
	am.set_vector_slice_2(&dxdt, v, a)

	return dxdt
}
accel_pointmass :: #force_inline proc(r: [3]f64, mu: f64) -> (a: [3]f64) {
	r_mag := la.vector_length(r)
	a = -mu / (r_mag * r_mag * r_mag) * r
	return a
}


Params_Gravity_Zonal :: struct {
	mu:         f64, // gravitional parameter
	R_cb:       f64, // central body radius (SMA)
	J:          [7]f64,
	max_degree: int, // maxium zonal degree
}
gravity_zonal :: proc(t: f64, x: [6]f64, params: rawptr) -> [6]f64 {
	dxdt: [6]f64

	params := cast(^Params_Gravity_Zonal)(params)
	r: [3]f64
	am.set_vector_slice_1(&r, x, l1 = 3)
	v: [3]f64
	am.set_vector_slice_1(&v, x, s1 = 3, l1 = 3)

	a := accel_zonal(r, params.mu, params.R_cb, params.J, params.max_degree)
	am.set_vector_slice_2(&dxdt, v, a)

	return dxdt
}
accel_zonal :: #force_inline proc(
	r: [3]f64,
	mu, R_cb: f64,
	J: [7]f64,
	#any_int max_degree: int,
) -> (
	a: [3]f64,
) {
	r_mag := la.vector_length(r)
	r_mag2 := la.vector_length2(r)
	Rr := R_cb / r_mag
	mur2 := mu / r_mag2
	r0r := r[0] / r_mag
	r1r := r[1] / r_mag
	r2r := r[2] / r_mag
	
	switch max_degree {
	case 6:
		Rr6 := Rr * Rr * Rr * Rr * Rr * Rr
		zr2 := r2r * r2r
		zr4 := zr2 * zr2
		zr6 := zr4 * zr2
		coef := -7. / 16. * J[6] * mur2 * Rr6
		vec := [3]f64 {
			(5. - 135. * zr2 + 495. * zr4 - 429. * zr6) * r0r, //
			(5. - 135. * zr2 + 495. * zr4 - 429. * zr6) * r1r, //
			(35. - 315. * zr2 + 693. * zr4 - 429. * zr6) * r2r, //
		}
		a += coef * vec
		fallthrough
	case 5:
		Rr5 := Rr * Rr * Rr * Rr * Rr
		zr2 := r2r * r2r
		zr4 := zr2 * zr2
		zr5 := zr4 * r2r
		coef := 3. / 8. * J[5] * mur2 * Rr5
		vec := [3]f64 {
			7. * (5. * r2r - 30. * zr4 + 33. * zr5) * r0r,
			7. * (5. * r2r - 30. * zr4 + 33. * zr5) * r1r,
			-(5. - 105. * zr2 + 315. * zr4 - 231. * zr5),
		}
		a += coef * vec
		fallthrough
	case 4:
		Rr4 := Rr * Rr * Rr * Rr
		zr2 := r2r * r2r
		zr4 := zr2 * zr2
		coef := 5. / 8. * J[4] * mur2 * Rr4
		vec := [3]f64 {
			3. * (1. - 14. * zr2 + 21. * zr4) * r0r,
			3. * (1. - 14. * zr2 + 21. * zr4) * r1r,
			(15. - 70. * zr2 + 63. * zr4) * r2r,
		}
		a += coef * vec
		fallthrough
	case 3:
		Rr3 := Rr * Rr * Rr
		zr2 := r2r * r2r
		zr3 := zr2 * r2r
		coef := -1. / 2. * J[3] * mur2 * Rr3
		vec := [3]f64 {
			5. * (3. * r2r - 7. * zr3) * r0r,
			5. * (3. * r2r - 7. * zr3) * r1r,
			-(3. - 30. * zr2 + 35. * zr3 * r2r),
		}
		a += coef * vec
		fallthrough
	case 2:
		Rr2 := Rr * Rr
		zr2 := r2r * r2r
		coef := -3 / 2 * J[2] * mur2 * Rr2
		vec := [3]f64 {
			(1. - 5. * zr2) * r0r, //
			(1. - .5 * zr2) * r1r, //
			(3. - 5. * zr2) * r2r, //
		}
		a += coef * vec
	case:
		panic("ERROR: zonal harmonics degree must be within [2, 6]")
	}

	return a
}
