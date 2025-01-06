package ode

import "core:math"
import la "core:math/linalg"

import am "../astromath"

Params_MSD :: struct {
	m, c, k: f64,
}
mass_spring_damper_ode :: proc(t: f64, x: [2]f64, params: rawptr) -> [2]f64 {
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


Params_pointmass :: struct {
	mu: f64,
}
pointmass_ode :: proc(t: f64, x: [6]f64, params: rawptr) -> [6]f64 {
	dxdt: [6]f64

	params := cast(^Params_pointmass)(params)
	r: [3]f64;
    am.set_vector_slice(&r, x, l1 = 3)
	v: [3]f64;
    am.set_vector_slice_1(&v, x, l1 = 3)


	r_mag := la.vector_length(r)
	a := -params.mu / (r_mag * r_mag * r_mag) * r
	am.set_vector_slice_2(&dxdt, v, a)

	return dxdt
}
